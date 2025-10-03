import 'package:medicine_box/models/medication_alarm_details.dart';

class NextUserAlarm {
  final String userId;
  final List<MedicationAlarmDetails> medicationAlarmDetails;
  final DateTime scheduled_at;

  NextUserAlarm({
    required this.userId,
    required this.medicationAlarmDetails,
    required this.scheduled_at,
  });

  static DateTime _toDate(dynamic v) =>
      v is DateTime ? v : DateTime.parse(v as String).toLocal();

  factory NextUserAlarm.fromMap(Map<String, dynamic> map) => NextUserAlarm(
    userId: map['user_id'],
    medicationAlarmDetails:
        (map['medication_alarm_details'] as List)
            .map((item) => MedicationAlarmDetails.fromMap(item))
            .toList(),
    scheduled_at: _toDate(map['scheduled_at']),
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId.toString(),
    'medication_alarm_details':
        medicationAlarmDetails.map((item) => item.toMap()).toList(),
    'scheduled_at': scheduled_at.toUtc().toIso8601String(),
  };
}
