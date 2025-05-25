import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationFormPage extends StatefulWidget {
  final Medication? medication;
  final Future<void> Function(Medication) onSave;

  const MedicationFormPage({ this.medication, required this.onSave });

  @override
  _MedicationFormPageState createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _nameCtrl = TextEditingController();
  final _weekdays = ['Seg','Ter','Qua','Qui','Sex','Sab','Dom'];
  final _selectedDays = <String>{};
  final _times = <TimeOfDay>[];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameCtrl.text = widget.medication!.name;
      _selectedDays.addAll(widget.medication!.days);
      _times.addAll(widget.medication!.schedules.map((h) {
        final parts = h.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }));
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.medication==null ? 'Nova Medicação' : 'Editar Medicação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _weekdays.map((d) {
                return ChoiceChip(
                  label: Text(d),
                  selected: _selectedDays.contains(d),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) _selectedDays.add(d);
                      else _selectedDays.remove(d);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Horários', style: Theme.of(ctx).textTheme.titleMedium),
            ..._times.map((t) => ListTile(
              title: Text(t.format(ctx)),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() => _times.remove(t));
                },
              ),
            )),
            TextButton.icon(
              icon: const Icon(Icons.add_alarm),
              label: const Text('Adicionar horário'),
              onPressed: () async {
                final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                if (t != null) setState(() => _times.add(t));
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('Salvar'),
                onPressed: () async {
                  final nome = _nameCtrl.text.trim();
                  if (nome.isEmpty || _selectedDays.isEmpty || _times.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Preencha nome, dias e horários'))
                    );
                    return;
                  }
                  final med = Medication(
                    id: widget.medication?.id,
                    name: nome,
                    days: _selectedDays.toList(),
                    schedules: _times.map((t) {
                      final h = t.hour.toString().padLeft(2,'0');
                      final m = t.minute.toString().padLeft(2,'0');
                      return '$h:$m';
                    }).toList(),
                  );
                  await widget.onSave(med);
                  Navigator.pop(ctx);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}