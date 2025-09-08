import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  late MqttBrowserClient client;
  bool isConnected = false;
  final String brokerUrl = 'wss://mqtt.eclipseprojects.io/mqtt';
  final int brokerPort = 443;
  final String topicStatus = 'remedio/estado';
  final String topicCommand = 'comando/led';

  Future<bool> connect() async {
    client = MqttBrowserClient(
      brokerUrl,
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
    )
      ..port = brokerPort
      ..keepAlivePeriod = 30
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..logging(on: false);

    client.onSubscribed = (topic) => print('✅ Inscrito em $topic');

    print('🔄 Tentando conectar ao MQTT...');
    try {
      await client.connect();
    } catch (e) {
      print('❌ Erro ao conectar: $e');
      isConnected = false;
      return isConnected;
    }

    return isConnected;
  }

  void _onConnected() {
    print('✅ Conectado ao broker MQTT');
    isConnected = true;
    // só agora inscrevo no tópico de status
    client.subscribe(topicStatus, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('⚠️ Desconectado do broker');
    isConnected = false;
    _tryReconnect();
  }

  Future<void> _tryReconnect() async {
    const retryDelay = Duration(seconds: 5);
    while (!isConnected) {
      print('🔁 Tentando reconectar...');
      await Future.delayed(retryDelay);
      try {
        await connect();
      } catch (_) {
        print('⚠️ Reconexão falhou. Tentando novamente...');
      }
    }
  }

  void publishCommand(String cmd, String topic) {
    if (!isConnected) {
      print('❌ Não conectado. Comando não enviado.');
      return;
    }

    final builder = MqttClientPayloadBuilder()..addString(cmd);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print('📤 Publicado: "$cmd" em "$topic"');
  }

    void sendCommand(String command) => publishCommand(command, topicCommand);

  void disconnect() {
    if (isConnected) {
      client.disconnect();
      print('🔌 Desconectado manualmente');
    }
  }
}
