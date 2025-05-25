// lib/models/medication.dart
class Medication {
  final String? id;
  final String name;
  final List<String> days;       // ex: ['Seg','Qua','Sex']
  final List<String> schedules;  // ex: ['08:00','20:30']

  Medication({
    this.id,
    required this.name,
    required this.days,
    required this.schedules,
  });

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
    id: map['id'] as String,
    name: map['name'] as String,
    days: List<String>.from(map['days'] as List<dynamic>),
    schedules: List<String>.from(map['schedules'] as List<dynamic>),
  );

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'days': days,
      'schedules': schedules,
    };
    // só inclua o id se já existir (no update)
    if (id != null && id!.isNotEmpty) {
      m['id'] = id;
    }
    return m;
  }
}
