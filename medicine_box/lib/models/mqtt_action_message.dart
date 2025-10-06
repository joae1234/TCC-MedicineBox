import 'dart:convert';
import 'package:medicine_box/models/enum/mqtt_type_action_enum.dart';

class MqttActionMessage {
  final MqttActionTypeEnum type;
  final String source;
  final String target;
  final DateTime sent_at;
  final Map<String, dynamic> metadata;

  MqttActionMessage({
    required this.type,
    required this.source,
    required this.target,
    required this.metadata,
    DateTime? sent_at,
  }) : sent_at = sent_at ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'version': 1,
    'command': type.name,
    'source': source,
    'target': target,
    'sent_at': sent_at.toIso8601String(),
    'metadata': metadata.isNotEmpty ? metadata : {},
  };

  String toJsonString() => jsonEncode(toJson());

  factory MqttActionMessage.fromJson(String topic, Map<String, dynamic> json) {
    return MqttActionMessage(
      type: MqttActionTypeEnum.values.firstWhere(
        (e) => e.name == (json['command'] ?? 'unknown'),
        orElse: () => MqttActionTypeEnum.unknown,
      ),
      source: json['source'] ?? '',
      target: json['target'] ?? '',
      sent_at:
          DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now().toUtc(),
      metadata:
          json['metadata'] != null
              ? Map<String, dynamic>.from(json['metadata'])
              : {},
    );
  }
}
