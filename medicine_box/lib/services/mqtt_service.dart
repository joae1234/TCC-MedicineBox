import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  late MqttBrowserClient client;
  bool isConnected = false;

  Future<void> connect() async {
    client = MqttBrowserClient(
      'wss://mqtt.eclipseprojects.io/mqtt',
      'client_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    client.port = 443;
    client.keepAlivePeriod = 30;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;

    try {
      await client.connect();
    } catch (e) {
      print('Erro na conexão: $e');
      isConnected = false;
    }
  }

  void _onConnected() {
    print('Conectado ao broker MQTT');
    isConnected = true;
  }

  void _onDisconnected() {
    print('Desconectado do broker');
    isConnected = false;
  }

  void sendCommand(String command) {
    if (!isConnected) return;
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(command);
    
    client.publishMessage(
      'medication/reminder',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    client.disconnect();
  }
}