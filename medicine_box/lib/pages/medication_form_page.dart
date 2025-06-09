import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationFormPage extends StatefulWidget {
  final Medication? medication;
  final Future<void> Function(Medication) onSave;

  const MedicationFormPage({Key? key, this.medication, required this.onSave}) : super(key: key);

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _nameCtrl = TextEditingController();
  final _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  final Set<String> _selectedDays = {};
  final List<TimeOfDay> _times = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    if (med != null) {
      _nameCtrl.text = med.name;
      _selectedDays.addAll(med.days);
      _times.addAll(med.schedules.map((h) {
        final parts = h.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }));
    }
  }

  void _addTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && !_times.contains(picked)) {
      setState(() => _times.add(picked));
    }
  }

  void _removeTime(TimeOfDay t) {
    setState(() => _times.remove(t));
  }

  String _formatTime(TimeOfDay t) => t.format(context);

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedDays.isEmpty || _times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _saving = true);
    final schedules = _times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList();

    final med = Medication(
      id: widget.medication?.id,
      name: name,
      days: _selectedDays.toList(),
      schedules: schedules,
    );

    await widget.onSave(med);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication == null ? 'Nova Medicação' : 'Editar Medicação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do medicamento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Dias da semana', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _weekdays.map((day) {
                final selected = _selectedDays.contains(day);
                return ChoiceChip(
                  label: Text(day),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Horários', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: _addTime, icon: const Icon(Icons.add)),
              ],
            ),
            ..._times.map((t) => ListTile(
                  title: Text(_formatTime(t)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTime(t),
                  ),
                )),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Salvar'),
                      onPressed: _submit,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
