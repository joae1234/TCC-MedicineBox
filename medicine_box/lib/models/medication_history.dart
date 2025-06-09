class MedicationHistory {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime takenAt;
  final int delaySecs;
  final String status;

  MedicationHistory({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.takenAt,
    required this.delaySecs,
    this.status = 'Aguardando', // default status
  });

  factory MedicationHistory.fromMap(Map<String, dynamic> map) => MedicationHistory(
    id: map['id'],
    userId: map['user_id'],
    medicationId: map['medication_id'],
    takenAt: DateTime.parse(map['taken_at']).toLocal(),  // 👈 adiciona .toLocal() se quiser mostrar local
    delaySecs: map['delay_secs'],
    status: map['status'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'medication_id': medicationId,
    'taken_at': takenAt.toUtc().toIso8601String(),  // 👈 armazena sempre em UTC
    'delay_secs': delaySecs,
    'status': status,
  };
}
