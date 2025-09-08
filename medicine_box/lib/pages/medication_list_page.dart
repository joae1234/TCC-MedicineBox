import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medicine_box/models/profile_model.dart';
import 'package:medicine_box/services/medication_schedule_service.dart';
import 'package:medicine_box/services/profile_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import '../services/mqtt_service.dart';
import 'medication_form_page.dart';
import 'invite_caregiver_page.dart';
import 'medication_history_page.dart';

class MedicationListPage extends StatefulWidget {
  const MedicationListPage({super.key});
  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  final _medSvc = MedicationService();
  final _profileSvc = ProfileService();
  final _medScheduleSvc = MedicationScheduleService();
  final _mqtt = MqttService();
  List<Medication> _meds = [];
  Profile? _userProfile;
  bool _loadingMqtt = true;
  bool _loading = true;
  bool _isConnectionSuccessful = false;
  Timer? _checkTimer;

  String? _lastMedId;
  String? _lastHistId;
  DateTime? _lastAlarmTime;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print("testando inicio");
    setState(() => _loadingMqtt = true);
    _mqtt.connect().then((result) {
      if (mounted) {
        setState(() => _loadingMqtt = false);
        setState(() => _isConnectionSuccessful = result);
      }
      _listenMqtt();
    }).catchError((e) {
      if (mounted) {
        setState(() => _loadingMqtt = false);
        setState(() => _isConnectionSuccessful = false);
      }
    });

    await _reload();
    _startAlarmLoop();
  }

  void _listenMqtt() {
    _mqtt.client.updates!.listen((events) async {
      final recMess = events[0].payload as MqttPublishMessage;
      final topic = events[0].topic;
      final payloadBytes = recMess.payload.message;
      final msg = MqttPublishPayload.bytesToStringAsString(payloadBytes);

      if (topic == 'remedio/estado') {
        final now = DateTime.now();
        final delay = now.difference(_lastAlarmTime!).inSeconds;

        try {
          await _medSvc.updateStatus(_lastHistId!, delay);
        } catch (e) {
          debugPrint("❌ Erro no update status: $e");
        }

        _lastMedId = null;
        _lastHistId = null;
        _lastAlarmTime = null;
      }
    });
  }

  void _startAlarmLoop() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();

    for (final med in _meds) {
      if (med.startDate != null && now.isBefore(med.startDate!)) continue;
      if (med.endDate != null && now.isAfter(med.endDate!)) continue;

      for (final sched in med.schedules) {
        final parts = sched.split(":");
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final alarmTime = DateTime(now.year, now.month, now.day, hour, minute);
        if (now.difference(alarmTime).inMinutes.abs() < 1) {
          if (_lastAlarmTime != null &&
              now.difference(_lastAlarmTime!).inMinutes < 1) return;

          final newId = const Uuid().v4();
          _lastMedId = med.id;
          _lastHistId = newId;
          _lastAlarmTime = now;

          _medSvc.savePreAlarm(id: newId, medId: med.id!, timestamp: now);
          if (_isConnectionSuccessful) {
            _mqtt.sendCommand("on");
          }
          _showAlarmPopup(med);
          return;
        }
      }
    }
  }

  void _showAlarmPopup(Medication med) {
    final now = DateTime.now();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Alarme de Medicação'),
        content: Text('Remédio: ${med.name}\nHorário: ${TimeOfDay.fromDateTime(now).format(context)}'),
        actions: [
          ElevatedButton(
            child: const Text('Parar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    _userProfile = await _profileSvc.getOwnProfile();

    final now = DateTime.now();
    final meds = await _medSvc.getAll();

    final ativos = <Medication>[];
    for (final m in meds) {
      if (m.endDate != null && now.isAfter(m.endDate!)) {
        await _medSvc.delete(m.id!);
      } else {
        ativos.add(m);
      }
    }

    _meds = ativos;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveNewMedication(Medication newMed) async {
    final med = await _medSvc.upsert(newMed);
    await _medScheduleSvc.upsertMedicationSchedule(
      med.id ?? '',
      newMed.startDate ?? DateTime.now(),
      newMed.endDate ?? DateTime.now().add(const Duration(days: 30)),
      newMed.days,
      newMed.schedules,
    );
    await _reload();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _mqtt.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Medicações'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _loadingMqtt
                    ? const Icon(Icons.sync, color: Colors.orange)
                    : _isConnectionSuccessful 
                      ? const Icon(Icons.check_circle, color: Colors.green) 
                      : const Icon(Icons.close, color: Colors.red),
                const SizedBox(width: 6),
                _loadingMqtt
                    ? const Text("Conectando...",
                      style: TextStyle(fontSize: 12, color: Colors.orange))
                    : _isConnectionSuccessful
                      ? const Text("Conectado",
                        style: TextStyle(fontSize: 12, color: Colors.green))
                      : const Text("Falha na conexão",
                        style: TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ),
          _userProfile?.caregiverId == null || _userProfile!.caregiverId!.isEmpty
            ? TextButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("ADICIONAR CUIDADOR"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InviteCaregiverPage()),
                  );
                },
              )
            : TextButton.icon(
                icon: const Icon(Icons.person),
                label: const Text("CUIDADOR: João da Silva"), 
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InviteCaregiverPage()),
                  );
                },
              ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de doses',
            onPressed: () async {
              final history = await _medSvc.getHistory();
              final nameMap = {for (var m in _meds) m.id!: m.name};
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicationHistoryPage(
                      history: history,
                      medNames: nameMap,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _meds.isEmpty
              ? const Center(
                child: Text('Nenhuma medicação cadastrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _meds.length,
                  itemBuilder: (_, i) {
                    final m = _meds[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: m.days.map((d) => Chip(label: Text(d))).toList(),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: m.schedules.map((s) => Chip(label: Text(s))).toList(),
                            ),
                            if (m.startDate != null || m.endDate != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Período: ' +
                                    (m.startDate != null
                                        ? "${m.startDate!.day}/${m.startDate!.month}"
                                        : "...") +
                                    ' até ' +
                                    (m.endDate != null
                                        ? "${m.endDate!.day}/${m.endDate!.month}"
                                        : "..."),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MedicationFormPage(
                                          medication: m,
                                          onSave: (updated) async {
                                            await _medSvc.upsert(updated);
                                            await _reload();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Confirmar exclusão'),
                                        content: const Text('Deseja realmente excluir esta medicação?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Excluir'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _medSvc.delete(m.id!);
                                      await _reload();
                                    }
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Adicionar Medicação',
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicationFormPage(
                onSave: (newMed) async {
                  await _saveNewMedication(newMed);
                  await _reload();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
