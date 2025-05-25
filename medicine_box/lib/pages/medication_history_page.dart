import 'package:flutter/material.dart';
import '../models/medication_history.dart';

class MedicationHistoryPage extends StatelessWidget {
  final List<MedicationHistory> history;
  const MedicationHistoryPage({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (_, i) {
          final h = history[i];
          return ListTile(
            title: Text('Medicamento ID: ${h.medicationId}'),
            subtitle: Text('Tomado em ${h.takenAt.toLocal()}'),
          );
        },
      ),
    );
  }
}
