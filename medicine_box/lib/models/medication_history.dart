class MedicationHistory {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime? takenAt;
  final String status;
  final DateTime scheduled_at;
  final DateTime created_at;

  MedicationHistory({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.takenAt,
    required this.scheduled_at,
    required this.created_at,
    this.status = 'Scheduled',
  });

  static DateTime _toDate(dynamic v) =>
    v is DateTime ? v : DateTime.parse(v as String);

  static DateTime? _toDateOrNull(dynamic v) =>
      v == null ? null : _toDate(v);

  factory MedicationHistory.fromMap(Map<String, dynamic> map) => MedicationHistory(
    id: map['id'],
    userId: map['user_id'],
    medicationId: map['medication_id'],
    takenAt: _toDateOrNull(map['taken_at']),
    status: map['status'],
    scheduled_at: _toDate(map['scheduled_at']),
    created_at: _toDate(map['created_at']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'medication_id': medicationId,
    'taken_at': takenAt?.toUtc().toIso8601String(),
    'status': status,
    'scheduled_at': scheduled_at.toUtc().toIso8601String(),
    'created_at': created_at.toUtc().toIso8601String(),
  };
}
