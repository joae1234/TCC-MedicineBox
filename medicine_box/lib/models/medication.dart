class Medication {
  final String? id;
  final String name;
  final List<String> days;
  final List<String> schedules;
  final DateTime? startDate;
  final DateTime? endDate;

  Medication({
    this.id,
    required this.name,
    required this.days,
    required this.schedules,
    this.startDate,
    this.endDate,
  });

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
        id: map['id'] as String?,
        name: map['name'] as String,
        days: List<String>.from(map['days'] as List<dynamic>),
        schedules: List<String>.from(map['schedules'] as List<dynamic>),
        startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
        endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      );

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'days': days,
      'schedules': schedules,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
    if (id != null && id!.isNotEmpty) {
      m['id'] = id;
    }
    return m;
  }
}
