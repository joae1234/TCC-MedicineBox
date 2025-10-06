import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:medicine_box/models/enum/mqtt_topics_enum.dart';
import 'package:medicine_box/models/mqtt_action_message.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  bool isConnected = false;
  // execução no localhost (dev environment) no emulador Android
  final String brokerUrl = '192.168.0.26';
  final int brokerPort = 1883;
  // final String brokerUrl = 'wss://<PROD_BROKER_URL>'; -> VALORES PARA PROD
  // final int brokerPort = <PROD_BROKER_PORT>; -> VALORES PARA PROD
  final String topicAlarmCommand = MqttTopicsEnum.alarmCommmand.name;
  final String topicAlarmStatus = MqttTopicsEnum.alarmStatus.name;
  final _log = Logger();
  final _messageStreamController =
      StreamController<MqttActionMessage>.broadcast();

  Stream<MqttActionMessage> get alarmMessagesStream => _messageStreamController
      .stream
      .where((msg) => msg.metadata['mqtt_topic'] == topicAlarmStatus);

  Future<bool> connect() async {
    client =
        MqttServerClient(
            brokerUrl,
            'flutter_${DateTime.now().millisecondsSinceEpoch}',
          )
          ..port = brokerPort
          ..keepAlivePeriod = 30
          ..onConnected = _onConnected
          ..onDisconnected = _onDisconnected
          ..secure =
              false // no TLS
          ..logging(on: false);

    _log.i('[MQTT] - Iniciando conexão com o broker MQTT');
    try {
      await client.connect();
      isConnected = true;
      client.updates?.listen(_onMessage);
    } catch (e) {
      _log.w('[MQTT] - Falha na conexão com o broker');
      // _log.d('[MQTT] - Falha na conexão: $e');
      isConnected = false;
      return isConnected;
    }

    return isConnected;
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    _log.i('[MQTT] - Mensagem recebida do broker MQTT');
    final recMess = event[0].payload as MqttPublishMessage;
    final topic = event[0].topic;
    final payload = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );

    _log.d('[MQTT] - Mensagem recebida no tópico $topic: $payload');

    try {
      final json = jsonDecode(payload);
      final action = MqttActionMessage.fromJson(topic, json)
        ..metadata['mqtt_topic'] = topic;

      _log.d('[MQTT] - Decodificado: ${action.toJsonString()}');
      _messageStreamController.add(action);
    } catch (e) {
      _log.e(
        '[MQTT] - Erro ao decodificar payload da mensagem vinda do MQTT',
        error: e,
      );
    }
  }

  void _onConnected() {
    _log.i('[MQTT] - Conexão com o broker MQTT realizada com sucesso');
    isConnected = true;
    // só agora inscrevo no tópico de status
    _log.i('[MQTT] - Subscribe no tópico de comunicação');
    // _log.d('[MQTT] - Inscrevendo no tópico: $topicStatus');

    // client.subscribe(topicAlarmCommand, MqttQos.atLeastOnce);
    client.subscribe(topicAlarmStatus, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    _log.w('[MQTT] - Desconectado do broker');
    isConnected = false;
    _tryReconnect();
  }

  Future<void> _tryReconnect() async {
    const retryDelay = Duration(seconds: 5);
    while (!isConnected) {
      _log.i('[MQTT] - Tentando reconexão com o broker MQTT');
      await Future.delayed(retryDelay);
      try {
        await connect();
      } catch (_) {
        _log.w('[MQTT] - Falha na reconexão. Tentando novamente...');
      }
    }
  }

  void publishCommand(String cmd, String topic, String userId) {
    try {
      if (!isConnected) {
        _log.w('[MQTT] - Broker não conectado. Comando não enviado.');
        return;
      }

      final builder = MqttClientPayloadBuilder()..addString(cmd);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      _log.i("[MQTT] - Comando foi publicado com sucesso");

      _log.d('[MQTT] - Publicado: "$cmd" em "$topic" para o user $userId');
    } catch (e) {
      _log.e('[MQTT] - Erro ao publicar comando no broker MQTT');
      _log.d('[MQTT] - Erro ao publicar comando: $e');
      throw Exception('Erro ao publicar comando no broker MQTT');
    }
  }

  void sendAlarmCommand(String command, String userId) =>
      publishCommand(command, topicAlarmCommand, userId);

  void disconnect() {
    _log.i('[MQTT] - Desconectando do broker MQTT');
    if (isConnected) {
      client.disconnect();
    }
  }
}
