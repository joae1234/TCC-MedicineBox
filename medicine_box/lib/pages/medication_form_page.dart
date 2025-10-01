import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationFormPage extends StatefulWidget {
  final Medication? medication;
  final Future<void> Function(Medication) onSave;

  const MedicationFormPage({super.key, this.medication, required this.onSave});

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _nameCtrl = TextEditingController();
  final _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  final Set<String> _selectedDays = {};
  final List<TimeOfDay> _times = [];

  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    if (med != null) {
      _nameCtrl.text = med.name;
      _selectedDays.addAll(med.days);
      _times.addAll(
        med.schedules.map((h) {
          final parts = h.split(':');
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }),
      );
      _startDate = med.startDate;
      _endDate = med.endDate;
    }
  }

  void _addTime() async {
    final hours = List.generate(24, (i) => i);

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(ctx).size.width * 0.5,
            height: MediaQuery.of(ctx).size.height * 0.3,
            child: SimpleDialog(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                width: double.infinity,
                color: Colors.blue,
                padding: const EdgeInsets.all(8),
                child: const Center(
                  child: Text(
                    "Selecione o horário",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              children:
                  hours
                      .map(
                        (h) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, h),
                          child: Center(
                            child: Text(
                              '${h.toString().padLeft(2, '0')}:00:00',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _times.add(TimeOfDay(hour: selected, minute: 0));
      });
    }

    // final now = TimeOfDay.now();
    // final picked = await showTimePicker(
    //   context: context,
    //   initialTime: now,
    //   builder: (context, child) {
    //     return MediaQuery(
    //       data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
    //       child: child!,
    //     );
    //   },
    // );

    // if (picked != null) {
    //   // força para múltiplos de 30
    //   final normalizedMinute = (picked.minute < 30) ? 0 : 30;
    //   final adjusted = TimeOfDay(hour: picked.hour, minute: normalizedMinute);

    //   setState(() {
    //     _times.add(adjusted);
    //   });
    // }
  }

  void _removeTime(TimeOfDay t) {
    setState(() => _times.remove(t));
  }

  String _formatTime(TimeOfDay t) => t.format(context);

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedDays.isEmpty || _times.isEmpty) return;

    _startDate ??= DateTime.now().toUtc();
    _endDate ??= _startDate!.add(const Duration(days: 30));

    setState(() => _saving = true);

    final med = Medication(
      id: widget.medication?.id,
      name: name,
      days: _selectedDays.toList(),
      schedules:
          _times
              .map(
                (t) =>
                    "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
              )
              .toList(),
      startDate: _startDate,
      endDate: _endDate,
    );

    await widget.onSave(med);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Medicação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Medicamento',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children:
                  _weekdays.map((dia) {
                    final selected = _selectedDays.contains(dia);
                    return FilterChip(
                      label: Text(dia),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedDays.add(dia);
                          } else {
                            _selectedDays.remove(dia);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            ..._times.map(
              (t) => ListTile(
                title: Text(_formatTime(t)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeTime(t),
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              label: const Text('Adicionar horário'),
              onPressed: _addTime,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Data de início"),
              subtitle: Text(
                _startDate != null
                    ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"
                    : "Selecione a data inicial",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().toUtc().add(Duration(days: 365)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            ListTile(
              title: const Text("Data de término"),
              subtitle: Text(
                _endDate != null
                    ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"
                    : "Selecione a data final",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(Duration(days: 1)),
                  firstDate: DateTime.now().add(Duration(days: 1)),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
