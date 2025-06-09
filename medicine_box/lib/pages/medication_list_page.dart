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
        // considera qualquer payload nesse tópico como retirada de remédio
        debugPrint('🔔 MQTT recebi em remedio/estado → msg="$msg", '
               'lastHist=$_lastHistId, lastAlarm=$_lastAlarmTime');
        final now = DateTime.now();
        final delay = now.difference(_lastAlarmTime!).inSeconds;
        debugPrint('⌛ Delay calculado: $delay s');
        try {
          await _medSvc.updateStatus(_lastHistId!, delay);
          debugPrint('✅ Supabase update OK');
        } catch (e) {
          debugPrint('❌ Erro no Supabase update: $e');
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
      debugPrint("⏲️ Loop de alarme executado");
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    debugPrint("⏰ Verificando alarmes em: ${now.toIso8601String()}");

    for (final med in _meds) {
      for (final sched in med.schedules) {
        final parts = sched.split(":");
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour == null || minute == null) continue;

        final alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

        if (now.year == alarmTime.year &&
            now.month == alarmTime.month &&
            now.day == alarmTime.day &&
            now.hour == alarmTime.hour &&
            now.minute == alarmTime.minute) {
          
          if (_lastAlarmTime != null &&
              now.difference(_lastAlarmTime!).inMinutes < 1) {
            return;
          }

          debugPrint("🚨 Alarme acionado para ${med.name} às $sched");

          final newId = const Uuid().v4();
          _lastMedId = med.id;
          _lastHistId = newId;
          _lastAlarmTime = now;

          _medSvc.savePreAlarm(
            id: newId,
            medId: med.id!,
            timestamp: now,
          );

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
        title: Row(
          children: const [
            Icon(Icons.local_pharmacy, color: Colors.green),
            SizedBox(width: 10),
            Text('Alarme de Medicação'),
          ],
        ),
        content: Text('Nome do Medicamento: ${med.name}\nHorário: ${TimeOfDay.fromDateTime(now).format(context)}'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Parar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    _meds = await _medSvc.getAll();
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InviteCaregiverPage()),
            ),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: const Icon(Icons.medication, size: 36),
                        title: Text(
                          m.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          'Dias: ${m.days.join(', ')}\nHorários: ${m.schedules.join(', ')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        isThreeLine: true,
                        onTap: () async {
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
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Confirmar exclusão'),
                                content: const Text('Deseja realmente excluir esta medicação?'),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancelar'),
                                    onPressed: () => Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    child: const Text('Excluir'),
                                    onPressed: () => Navigator.pop(context, true),
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
