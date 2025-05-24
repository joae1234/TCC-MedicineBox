import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication_model.dart';

class MedicationHistoryPage extends StatefulWidget {
  final List<MedicationRecord> records;

  const MedicationHistoryPage({Key? key, required this.records}) : super(key: key);

  @override
  _MedicationHistoryPageState createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Medicamentos'),
      ),
      body: widget.records.isEmpty
          ? Center(child: Text('Nenhum registro encontrado'))
          : ListView.builder(
              itemCount: widget.records.length,
              itemBuilder: (context, index) {
                final record = widget.records[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      record.taken ? Icons.check_circle : Icons.warning,
                      color: record.taken ? Colors.green : Colors.orange,
                    ),
                    title: Text(record.medicationName),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(record.date)} '
                      'às ${record.time.format(context)}',
                    ),
                    trailing: record.isAuto 
                        ? Icon(Icons.autorenew, color: Colors.grey)
                        : null,
                  ),
                );
              },
            ),
    );
  }
}