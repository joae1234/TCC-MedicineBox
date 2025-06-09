import 'package:flutter/material.dart';
import '../models/medication_history.dart';

class MedicationHistoryPage extends StatelessWidget {
  final List<MedicationHistory> history;
  final Map<String, String> medNames;

  const MedicationHistoryPage({
    Key? key,
    required this.history,
    required this.medNames,
  }) : super(key: key);

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Medicações')),
      body: history.isEmpty
          ? const Center(child: Text('Nenhum histórico disponível.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, i) {
                final h = history[i];
                final nome = medNames[h.medicationId] ?? 'Desconhecido';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Horário: ${_formatDate(h.takenAt)}\nTomado após: ${h.delaySecs} segundos',
                    ),
                    leading: const Icon(Icons.history),
                  ),
                );
              },
            ),
    );
  }
}
