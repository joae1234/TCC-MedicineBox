import 'package:flutter/material.dart';
import '../models/medication_history.dart';

class MedicationHistoryPage extends StatelessWidget {
  final List<MedicationHistory> history;
  final Map<String, String> medNames;

  const MedicationHistoryPage({
    super.key,
    required this.history,
    required this.medNames,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Medicações')),
      body:
          history.isEmpty
              ? const Center(child: Text('Nenhum histórico disponível.'))
              : ListView.builder(
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final h = history[i];
                  final nome = medNames[h.medicationId] ?? 'Desconhecido';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // subtitle: Text(
                      //   'Horário: ${_formatDate(h.takenAt)}\nTomado após: ${h.delaySecs} segundos',
                      // ),
                      leading: const Icon(Icons.history),
                    ),
                  );
                },
              ),
    );
  }
}
