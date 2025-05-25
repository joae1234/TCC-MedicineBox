import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import 'medication_form_page.dart';
import 'invite_caregiver_page.dart';
import 'medication_history_page.dart';

class MedicationListPage extends StatefulWidget {
  const MedicationListPage();
  @override
  _MedicationListPageState createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  final _medSvc = MedicationService();
  List<Medication> _meds = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _meds = await _medSvc.getAll();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Minhas Medicações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Convidar cuidador',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InviteCaregiverPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de doses',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicationHistoryPage(history: []),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _meds.length,
        itemBuilder: (_, i) {
          final m = _meds[i];
          return ListTile(
            title: Text(m.name),
            subtitle: Text(
              '${m.days.join(', ')} • ${m.schedules.join(', ')}'
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                await _medSvc.delete(m.id!);
                await _reload();
              },
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MedicationFormPage(
                medication: m,
                onSave: (upd) async {
                  await _medSvc.upsert(upd);
                  await _reload();
                },
              )),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicationFormPage(
            onSave: (med) async {
              await _medSvc.upsert(med);
              await _reload();
            },
          )),
        ),
      ),
    );
  }
}