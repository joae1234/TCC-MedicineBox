enum MqttTopicsEnum { alarmCommmand, alarmStatus }

extension MqttTopicsEnumExtension on MqttTopicsEnum {
  String get name {
    switch (this) {
      case MqttTopicsEnum.alarmCommmand:
        return 'medicine_box/alarm/command';
      case MqttTopicsEnum.alarmStatus:
        return 'medicine_box/alarm/status';
    }
  }
}
