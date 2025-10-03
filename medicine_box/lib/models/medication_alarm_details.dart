class MedicationAlarmDetails {
  final String id;
  final String medicationId;
  final String name;

  MedicationAlarmDetails({
    required this.id,
    required this.medicationId,
    required this.name,
  });

  factory MedicationAlarmDetails.fromMap(Map<String, dynamic> map) =>
      MedicationAlarmDetails(
        id: map['id'],
        medicationId: map['medication_id'],
        name: map['name'],
      );

  Map<String, dynamic> toMap() => {
    'id': id.toString(),
    'medication_id': medicationId.toString(),
    'name': name.toString(),
  };
}
