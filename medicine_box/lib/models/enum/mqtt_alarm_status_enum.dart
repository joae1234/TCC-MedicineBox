enum MqttAlarmStatusEnum { taken, missed, scheduled, cancelled, unknown }

extension MqttActionTypeEnumExtension on MqttAlarmStatusEnum {
  String get action {
    switch (this) {
      case MqttAlarmStatusEnum.taken:
        return 'medication_taken';
      case MqttAlarmStatusEnum.missed:
        return 'medication_missed';
      default:
        return 'unknown_status';
    }
  }

  String get value {
    switch (this) {
      case MqttAlarmStatusEnum.taken:
        return 'Taken';
      case MqttAlarmStatusEnum.missed:
        return 'Missed';
      case MqttAlarmStatusEnum.scheduled:
        return 'Scheduled';
      case MqttAlarmStatusEnum.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
