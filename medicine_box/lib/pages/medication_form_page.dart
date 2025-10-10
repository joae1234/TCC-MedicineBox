import 'package:flutter/material.dart';
import 'package:medicine_box/services/log_service.dart';
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
  final _log = LogService().logger;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  int _dosage = 1; // Definindo um valor inicial para a dosagem

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
      _dosage = med.dosage ?? 1;
    }
  }

  void _addTime() async {
    // Lista de horas de 1 a 12
    final hours = List.generate(12, (i) => i + 1);

    // Lista de minutos: 00, 15, 30, 45
    final minutes = [0, 15, 30, 45];

    // Exibindo o diálogo para selecionar hora, minuto e AM/PM
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        int selectedHour = hours[0];
        int selectedMinute = minutes[0];
        bool isAM = true;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Dialog(
              child: SizedBox(
                width: MediaQuery.of(ctx).size.width * 0.8,
                height: MediaQuery.of(ctx).size.height * 0.4,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Seletor de hora
                        DropdownButton<int>(
                          value: selectedHour,
                          items:
                              hours.map((h) {
                                return DropdownMenuItem<int>(
                                  value: h,
                                  child: Text(h.toString().padLeft(2, '0')),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedHour = value!;
                            });
                          },
                        ),
                        const Text(":", style: TextStyle(fontSize: 18)),
                        // Seletor de minuto
                        DropdownButton<int>(
                          value: selectedMinute,
                          items:
                              minutes.map((m) {
                                return DropdownMenuItem<int>(
                                  value: m,
                                  child: Text(m.toString().padLeft(2, '0')),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedMinute = value!;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        // Seletor de AM/PM
                        DropdownButton<bool>(
                          value: isAM,
                          items: [
                            DropdownMenuItem<bool>(
                              value: true,
                              child: Text("AM"),
                            ),
                            DropdownMenuItem<bool>(
                              value: false,
                              child: Text("PM"),
                            ),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              isAM = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    SimpleDialogOption(
                      onPressed:
                          () => Navigator.pop(ctx, {
                            'hour': selectedHour,
                            'minute': selectedMinute,
                            'isAM': isAM,
                          }),
                      child: const Center(
                        child: Text(
                          'Confirmar',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      // Converte hora de 12 horas para 24 horas
      int hourIn24 = selected['hour'];
      if (!selected['isAM']) {
        hourIn24 = (hourIn24 % 12) + 12;
      }

      setState(() {
        _times.add(TimeOfDay(hour: hourIn24, minute: selected['minute']));
      });
    }
  }

  void _removeTime(TimeOfDay t) {
    setState(() => _times.remove(t));
  }

  String _formatTime(TimeOfDay t) => t.format(context);

  Future<void> _submit() async {
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedDays.isEmpty || _times.isEmpty) return;

    _startDate ??= DateTime.now().toUtc();
    _endDate ??= _startDate!.add(const Duration(days: 30));

    _log.d(
      '[MFP] - Salvando medicação: $name, Dosagem: $_dosage, Dias: $_selectedDays, Horários: $_times, Início: $_startDate, Término: $_endDate',
    );

    final med = Medication(
      id: widget.medication?.id,
      name: name,
      dosage: _dosage.toInt(),
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

    _log.d('[MFP] - Medicação a ser salva: $med');

    await widget.onSave(med);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                Row(
                  children: [
                    const Text("Dosagem: ", style: TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (_dosage > 1) _dosage--;
                        });
                      },
                    ),
                    Text("$_dosage", style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _dosage++;
                        });
                      },
                    ),
                  ],
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
                      lastDate: DateTime.now().add(Duration(days: 365)),
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
        ),

        if (_saving)
          Container(
            color: Colors.blue,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Salvando medicação...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
