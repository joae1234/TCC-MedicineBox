import 'package:flutter/material.dart';
import 'medication_form_page.dart';
import 'package:intl/intl.dart'; // Para formatação de datas e horários

class MedicationListPage extends StatefulWidget {
  @override
  _MedicationListPageState createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  List<Map<String, dynamic>> _medications = [];

  void _addOrEditMedication(Map<String, dynamic>? medication) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicationFormPage(medication: medication),
      ),
    );

    if (result != null) {
      setState(() {
        if (medication != null) {
          // Editar medicamento existente
          final index = _medications.indexOf(medication);
          _medications[index] = result;
        } else {
          // Adicionar novo medicamento
          _medications.add(result);
        }
      });
    }
  }

  void _deleteMedication(Map<String, dynamic> medication) {
    setState(() {
      _medications.remove(medication);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Medicamentos'),
        backgroundColor: Colors.red,
      ),
      body: _medications.isEmpty
          ? Center(
              child: Text(
                'Nenhum medicamento adicionado.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
      : ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final medication = _medications[index];
          return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      medication['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication['type'] == 'pill'
                              ? 'Comprimidos: ${medication['quantity']}'
                              : 'Dosagem: ${medication['dosage']} ml',
                        ),
                        const SizedBox(height: 8),
                        Text('Dias: ${medication['daysOfWeek']}'),
                        const SizedBox(height: 8),
                        Text(
                          'Horários: ${medication['times'].map((t) {
                            final parts = t.split(':');
                            final formattedHour = parts[0].padLeft(2, '0');
                            final formattedMinute = parts[1].padLeft(2, '0');
                            return '$formattedHour:$formattedMinute';
                          }).join(', ')}',
                        ),
                        if (medication['startDate'] != null &&
                            medication['endDate'] != null)
                          Text(
                            'Período: ${DateFormat('dd/MM/yyyy').format(medication['startDate'])} - ${DateFormat('dd/MM/yyyy').format(medication['endDate'])}',
                          ),
                      ],
                    ),
                    onTap: () => _addOrEditMedication(medication),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMedication(medication),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditMedication(null),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}