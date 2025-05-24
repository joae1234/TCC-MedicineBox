import 'package:flutter/material.dart';
class Medication {
  final String name;
  final List<String> days;
  final List<TimeOfDay> times;
  
  Medication({required this.name, required this.days, required this.times});
}

class MedicationRecord {
  final String medicationName;
  final DateTime date;
  final TimeOfDay time;
  final bool taken;
  final bool isAuto;
  
  MedicationRecord({
    required this.medicationName,
    required this.date,
    required this.time,
    this.taken = true,
    this.isAuto = false,
  });
}