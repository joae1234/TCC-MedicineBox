enum MqttActionTypeEnum { unknown, activateAlarm, alarmStatus }

extension MqttActionTypeEnumExtension on MqttActionTypeEnum {
  String get name {
    switch (this) {
      case MqttActionTypeEnum.unknown:
        return 'unknown';
      case MqttActionTypeEnum.activateAlarm:
        return 'activate_alarm';
      case MqttActionTypeEnum.alarmStatus:
        return 'alarm_status';
    }
  }
}
