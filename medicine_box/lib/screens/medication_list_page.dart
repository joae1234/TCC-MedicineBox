import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'medication_form_page.dart';
import 'dart:async';
class MedicationListPage extends StatefulWidget {
  @override
  _MedicationListPageState createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  List<Map<String, dynamic>> medications = [];
  late MqttBrowserClient client;
  bool conectado = false;
  bool ledLigado = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    conectarMQTT();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    client.disconnect();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkMedicationTimes();
    });
  }



  void _triggerLED() {
    if (conectado) {
      enviarComando("on");
      Future.delayed(Duration(seconds: 3), () {
        enviarComando("off");
      });
    }
  }

  Future<void> conectarMQTT() async {
    client = MqttBrowserClient(
        'wss://mqtt.eclipseprojects.io/mqtt',
        'med_reminder_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 443;
    client.websocketProtocols = ['mqtt'];
    client.setProtocolV311();
    client.keepAlivePeriod = 30;
    client.logging(on: true);

    client.onConnected = () {
      print("✅ Conectado ao broker");
      if (mounted) {
        setState(() => conectado = true);
      }
    };

    client.onDisconnected = () {
      print("❌ Desconectado do broker");
      if (mounted) {
        setState(() => conectado = false);
      }
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean();

    client.connectionMessage = connMessage;

    try {
      print("ℹ Tentando conectar...");
      await client.connect();
    } catch (e) {
      print("Erro ao conectar: $e");
      client.disconnect();
      if (mounted) {
        setState(() => conectado = false);
      }
    }
  }

  void enviarComando(String comando) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(comando);
    client.publishMessage(
      'comando/led',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print("Comando enviado: $comando");

    setState(() {
      ledLigado = comando == "on";
    });
  }

  void addOrEditMedication(Map<String, dynamic>? medication, int? index) {
    if (index != null) {
      setState(() {
        medications[index] = medication!;
      });
    } else {
      setState(() {
        medications.add(medication!);
      });
    }
  }

  void deleteMedication(int index) {
    setState(() {
      medications.removeAt(index);
    });
  }

void _checkMedicationTimes() {
    final now = TimeOfDay.now();
    for (var med in medications) {
      final medTimes = med['times'] as List<TimeOfDay>; // Agora verifica lista de horários
      for (var medTime in medTimes) {
        if (medTime.hour == now.hour && medTime.minute == now.minute) {
          _triggerLED();
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Medicamentos'),
        actions: [
          IconButton(
            icon: Icon(conectado ? Icons.wifi : Icons.wifi_off,
                color: conectado ? Colors.green : Colors.red),
            onPressed: () {
              if (!conectado) {
                conectarMQTT();
              }
            },
          ),
          if (ledLigado)
            Icon(Icons.lightbulb, color: Colors.yellow, size: 30),
        ],
      ),
      body: medications.isEmpty
          ? Center(child: Text('Nenhum medicamento adicionado.'))
          : ListView.builder(
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return ListTile(
                  title: Text(medication['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dias: ${medication['days'].join(', ')}'),
                      Text('Horários: ${medication['times'].map((t) => t.format(context)).join(', ')}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicationFormPage(
                                medication: medication,
                                index: index,
                                onSave: addOrEditMedication,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteMedication(index),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationFormPage(
                onSave: addOrEditMedication,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}