import 'dart:async';
import 'package:flutter/material.dart';
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
  final _mqtt = MqttService();
  List<Medication> _meds = [];
  bool _loading = true;
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
    await _mqtt.connect();
    _listenMqtt();
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
          _mqtt.sendCommand("on");
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
    setState(() => _loading = true);
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

  @override
  void dispose() {
    _checkTimer?.cancel();
    _mqtt.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Medicações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Convidar cuidador',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meds.isEmpty
              ? const Center(child: Text('Nenhuma medicação cadastrada.'))
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
        tooltip: 'Adicionar Medicação',
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicationFormPage(
                onSave: (newMed) async {
                  await _medSvc.upsert(newMed);
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
