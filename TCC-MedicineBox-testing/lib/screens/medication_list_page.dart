import 'package:flutter/material.dart';
import 'medication_form_page.dart';

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
      ),
      body: ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final medication = _medications[index];
          return ListTile(
            title: Text(medication['name']),
            subtitle: Text(
              medication['type'] == 'pill'
                  ? 'Comprimidos: ${medication['quantity']}'
                  : 'Dosagem: ${medication['dosage']} ml',
            ),
            onTap: () => _addOrEditMedication(medication),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteMedication(medication),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditMedication(null),
        child: Icon(Icons.add),
      ),
    );
  }
}
