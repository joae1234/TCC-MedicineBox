import 'package:flutter/material.dart';
import 'medication_form_page.dart';

class MedicationListPage extends StatefulWidget {
  @override
  _MedicationListPageState createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  List<Map<String, dynamic>> medications = [];

  void addOrEditMedication(Map<String, dynamic>? medication, int? index) {
    if (index != null) {
      setState(() {
        medications[index] = medication!;
      });
    } else {
      setState(() {
        medications.add(medication!);
      });
    }
  }

  void deleteMedication(int index) {
    setState(() {
      medications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medication List'),
      ),
      body: medications.isEmpty
          ? Center(child: Text('No medications added.'))
          : ListView.builder(
        itemCount: medications.length,
        itemBuilder: (context, index) {
          final medication = medications[index];
          return ListTile(
            title: Text(medication['name']),
            subtitle: Text(
                '${medication['days']}, ${medication['time'].format(context)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationFormPage(
                          medication: medication,
                          index: index,
                          onSave: addOrEditMedication,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteMedication(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationFormPage(
                onSave: addOrEditMedication,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
