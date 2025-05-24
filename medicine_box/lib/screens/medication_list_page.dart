import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication_model.dart';
import '../services/mqtt_service.dart';
import 'medication_form_page.dart';
import 'medication_history_page.dart';

class MedicationListPage extends StatefulWidget {
  @override
  _MedicationListPageState createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  final List<Medication> _medications = [];
  final List<MedicationRecord> _history = [];
  late MqttService _mqttService;
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    _mqttService = MqttService();
    _initMqtt();
    _startReminderCheck();
  }

  Future<void> _initMqtt() async {
    await _mqttService.connect();
    setState(() {});
  }

  void _startReminderCheck() {
    _reminderTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkMedicationTimes();
    });
  }

  void _checkMedicationTimes() {
    final now = TimeOfDay.now();
    final today = DateTime.now();
    
    for (final med in _medications) {
      for (final time in med.times) {
        if (time.hour == now.hour && time.minute == now.minute) {
          _triggerReminder(med.name);
          _addHistoryRecord(med.name, time, true);
          break;
        }
      }
    }
  }

  void _triggerReminder(String medName) {
    if (_mqttService.isConnected) {
      _mqttService.sendCommand('on');
      Future.delayed(Duration(seconds: 3), () {
        _mqttService.sendCommand('off');
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hora de tomar $medName!')),
    );
  }

  void _addHistoryRecord(String name, TimeOfDay time, bool isAuto) {
    setState(() {
      _history.add(MedicationRecord(
        medicationName: name,
        date: DateTime.now(),
        time: time,
        taken: true,
        isAuto: isAuto,
      ));
    });
  }

  void _addOrEditMedication(Medication medication, int? index) {
    setState(() {
      index != null 
          ? _medications[index] = medication
          : _medications.add(medication);
    });
  }

  void _deleteMedication(int index) {
    setState(() => _medications.removeAt(index));
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lembretes de Medicamentos'),
        actions: [
          IconButton(
            icon: Icon(
              _mqttService.isConnected ? Icons.wifi : Icons.wifi_off,
              color: _mqttService.isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _initMqtt,
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicationHistoryPage(records: _history),
              ),
            ),
          ),
        ],
      ),
      body: _medications.isEmpty
          ? Center(child: Text('Nenhum medicamento adicionado'))
          : ListView.builder(
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final med = _medications[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(med.name),
                    subtitle: Text('Dias: ${med.days.join(', ')}'),
                    children: [
                      ...med.times.map((time) => ListTile(
                        title: Text('Horário: ${time.format(context)}'),
                        trailing: IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            _addHistoryRecord(med.name, time, false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${med.name} marcado como tomado!')),
                            );
                          },
                        ),
                      )).toList(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicationFormPage(
                                  medication: med,
                                  index: index,
                                  onSave: _addOrEditMedication,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteMedication(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicationFormPage(
              onSave: _addOrEditMedication,
            ),
          ),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}