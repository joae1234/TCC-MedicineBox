class MedicationAlarmDetails {
  final String id;
  final String medicationId;
  final String name;
  final int? dosage;

  MedicationAlarmDetails({
    required this.id,
    required this.medicationId,
    required this.name,
    required this.dosage,
  });

  factory MedicationAlarmDetails.fromMap(Map<String, dynamic> map) =>
      MedicationAlarmDetails(
        id: map['id'],
        medicationId: map['medication_id'],
        name: map['name'],
        dosage: map['dosage'],
      );

  Map<String, dynamic> toMap() => {
    'id': id.toString(),
    'medication_id': medicationId.toString(),
    'name': name.toString(),
    'dosage': dosage,
  };
}
