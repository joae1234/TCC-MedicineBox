class MedicationHistory {
  final String id;
  final String medicationId;
  final DateTime takenAt;

  MedicationHistory({
    required this.id,
    required this.medicationId,
    required this.takenAt,
  });

  factory MedicationHistory.fromMap(Map<String, dynamic> m) => MedicationHistory(
    id: m['id'] as String,
    medicationId: m['medication_id'] as String,
    takenAt: DateTime.parse(m['taken_at'] as String),
  );
}