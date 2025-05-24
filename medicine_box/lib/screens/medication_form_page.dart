import 'package:flutter/material.dart';

class MedicationFormPage extends StatefulWidget {
  final Map<String, dynamic>? medication;
  final int? index;
  final void Function(Map<String, dynamic>? medication, int? index) onSave;

  MedicationFormPage({this.medication, this.index, required this.onSave});

  @override
  _MedicationFormPageState createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  List<String> _selectedDays = [];
  List<TimeOfDay> _selectedTimes = []; // Alterado para lista de horários
  final List<String> _daysOfWeek = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!['name'];
      _selectedDays = List.from(widget.medication!['days']);
      _selectedTimes = List.from(widget.medication!['times']); // Carrega múltiplos horários
    } else {
      _selectedTimes.add(TimeOfDay.now()); // Horário padrão inicial
    }
  }

  void _selectTime(int index) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index] ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTimes[index] = pickedTime;
      });
    }
  }

  void _addNewTime() {
    setState(() {
      _selectedTimes.add(TimeOfDay.now());
    });
  }

  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.index == null ? 'Adicionar Medicamento' : 'Editar Medicamento'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nome do Medicamento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Selecione os dias:', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _daysOfWeek.map((day) {
                  return FilterChip(
                    label: Text(day),
                    selected: _selectedDays.contains(day),
                    onSelected: (selected) => _toggleDay(day),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Text('Horários:', style: TextStyle(fontSize: 16)),
              ..._selectedTimes.asMap().entries.map((entry) {
                int index = entry.key;
                TimeOfDay time = entry.value;
                return ListTile(
                  title: Text('Horário ${index + 1}: ${time.format(context)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () => _selectTime(index),
                      ),
                      if (_selectedTimes.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeTime(index),
                        ),
                    ],
                  ),
                );
              }).toList(),
              TextButton(
                onPressed: _addNewTime,
                child: Text('Adicionar horário'),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _selectedTimes.isNotEmpty &&
                      _selectedDays.isNotEmpty) {
                    widget.onSave(
                      {
                        'name': _nameController.text,
                        'days': _selectedDays,
                        'times': _selectedTimes, // Agora envia lista de horários
                      },
                      widget.index,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}