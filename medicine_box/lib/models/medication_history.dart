class MedicationHistory {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime? lastStatusUpdate;
  final String status;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final int? dosage;
  final String timezone;

  MedicationHistory({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.lastStatusUpdate,
    required this.status,
    required this.scheduledAt,
    required this.createdAt,
    required this.dosage,
    required this.timezone,
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
        scheduledAt: _toDate(map['scheduled_at']),
        createdAt: _toDate(map['created_at']),
        dosage: map['dosage'],
        timezone: map['timezone'] ?? 'UTC',
      );

  Map<String, dynamic> toMap() => {
    'id': id.toString(),
    'user_id': userId.toString(),
    'medication_id': medicationId.toString(),
    'last_status_update': lastStatusUpdate?.toIso8601String(),
    'status': status.toString(),
    'scheduled_at': scheduledAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'dosage': dosage,
    'timezone': timezone,
  };
}
