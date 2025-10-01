// lib/widgets/medication_tile.dart
import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationTile extends StatelessWidget {
  final Medication medication;
  final void Function(Medication) onEdit;
  final VoidCallback onDelete;

  const MedicationTile({
    super.key,
    required this.medication,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext ctx) {
    final days = medication.days.join(', ');
    final times = medication.schedules.join(', ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(medication.name),
        subtitle: Text('$days • $times'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () => onEdit(medication),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Remover',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
