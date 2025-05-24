import 'package:flutter/material.dart';
import '../models/medication_model.dart';

class MedicationFormPage extends StatefulWidget {
  final Medication? medication;
  final int? index;
  final Function(Medication, int?) onSave;

  const MedicationFormPage({
    Key? key,
    this.medication,
    this.index,
    required this.onSave,
  }) : super(key: key);

  @override
  _MedicationFormPageState createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _daysOfWeek = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  final List<String> _selectedDays = [];
  final List<TimeOfDay> _selectedTimes = [];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _selectedDays.addAll(widget.medication!.days);
      _selectedTimes.addAll(widget.medication!.times);
    } else {
      _selectedTimes.add(TimeOfDay.now());
    }
  }

  Future<void> _selectTime(int index) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (pickedTime != null) {
      setState(() => _selectedTimes[index] = pickedTime);
    }
  }

  void _addTime() => setState(() => _selectedTimes.add(TimeOfDay.now()));
  void _removeTime(int index) => setState(() => _selectedTimes.removeAt(index));

  void _toggleDay(String day) {
    setState(() {
      _selectedDays.contains(day) 
          ? _selectedDays.remove(day) 
          : _selectedDays.add(day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication == null ? 'Novo Medicamento' : 'Editar Medicamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nome do Medicamento'),
                validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              Text('Dias da semana:', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 8.0,
                children: _daysOfWeek.map((day) => FilterChip(
                  label: Text(day),
                  selected: _selectedDays.contains(day),
                  onSelected: (_) => _toggleDay(day),
                )).toList(),
              ),
              const SizedBox(height: 20),
              Text('Horários:', style: TextStyle(fontSize: 16)),
              ..._selectedTimes.asMap().entries.map((entry) => ListTile(
                title: Text('Horário ${entry.key + 1}: ${entry.value.format(context)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: () => _selectTime(entry.key),
                    ),
                    if (_selectedTimes.length > 1) IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeTime(entry.key),
                    ),
                  ],
                ),
              )).toList(),
              TextButton(
                onPressed: _addTime,
                child: Text('Adicionar horário'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveMedication,
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate() && 
        _selectedDays.isNotEmpty && 
        _selectedTimes.isNotEmpty) {
      
      final medication = Medication(
        name: _nameController.text,
        days: _selectedDays,
        times: _selectedTimes,
      );
      
      widget.onSave(medication, widget.index);
      Navigator.pop(context);
    }
  }
}