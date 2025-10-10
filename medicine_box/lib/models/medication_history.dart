class MedicationHistory {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime? lastStatusUpdate;
  final String status;
  final DateTime scheduled_at;
  final DateTime created_at;
  final int? dosage;

  MedicationHistory({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.lastStatusUpdate,
    required this.scheduled_at,
    required this.created_at,
    required this.dosage,
    this.status = 'Scheduled',
  });

  static DateTime _toDate(dynamic v) =>
      v is DateTime ? v : DateTime.parse(v as String);

  static DateTime? _toDateOrNull(dynamic v) => v == null ? null : _toDate(v);

  factory MedicationHistory.fromMap(Map<String, dynamic> map) =>
      MedicationHistory(
        id: map['id'],
        userId: map['user_id'],
        medicationId: map['medication_id'],
        lastStatusUpdate: _toDateOrNull(map['last_status_update']),
        status: map['status'],
        scheduled_at: _toDate(map['scheduled_at']),
        created_at: _toDate(map['created_at']),
        dosage: map['dosage'],
      );

  Map<String, dynamic> toMap() => {
    'id': id.toString(),
    'user_id': userId.toString(),
    'medication_id': medicationId.toString(),
    'last_status_update': lastStatusUpdate?.toIso8601String(),
    'status': status.toString(),
    'scheduled_at': scheduled_at.toIso8601String(),
    'created_at': created_at.toIso8601String(),
    'dosage': dosage,
  };
}
