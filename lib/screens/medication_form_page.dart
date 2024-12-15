import 'package:flutter/material.dart';

class MedicationFormPage extends StatefulWidget {
  final Map<String, dynamic>? medication;

  const MedicationFormPage({Key? key, this.medication}) : super(key: key);

  @override
  _MedicationFormPageState createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _type;
  int? _quantity;
  double? _dosage;
  late String _daysOfWeek;
  late String _time;

  @override
  void initState() {
    super.initState();
    _name = widget.medication?['name'] ?? '';
    _type = widget.medication?['type'] ?? 'pill'; // Default: comprimido
    _quantity = widget.medication?['quantity'];
    _dosage = widget.medication?['dosage'];
    _daysOfWeek = widget.medication?['daysOfWeek'] ?? '';
    _time = widget.medication?['time'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication == null ? 'Adicionar Medicamento' : 'Editar Medicamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(labelText: 'Nome do Medicamento'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o nome do medicamento';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(labelText: 'Tipo de Medicamento'),
                  items: [
                    DropdownMenuItem(value: 'pill', child: Text('Comprimido')),
                    DropdownMenuItem(value: 'liquid', child: Text('Líquido')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _type = value!;
                      // Reset dos campos ao trocar de tipo
                      _quantity = null;
                      _dosage = null;
                    });
                  },
                  onSaved: (value) => _type = value!,
                ),
                SizedBox(height: 16),
                if (_type == 'pill')
                  TextFormField(
                    initialValue: _quantity?.toString(),
                    decoration: InputDecoration(labelText: 'Quantidade de Comprimidos'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_type == 'pill' && (value == null || int.tryParse(value) == null)) {
                        return 'Informe uma quantidade válida';
                      }
                      return null;
                    },
                    onSaved: (value) => _quantity = int.tryParse(value!),
                  ),
                if (_type == 'liquid')
                  TextFormField(
                    initialValue: _dosage?.toString(),
                    decoration: InputDecoration(labelText: 'Dosagem em ml'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_type == 'liquid' && (value == null || double.tryParse(value) == null)) {
                        return 'Informe uma dosagem válida';
                      }
                      return null;
                    },
                    onSaved: (value) => _dosage = double.tryParse(value!),
                  ),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: _daysOfWeek,
                  decoration: InputDecoration(labelText: 'Dias da Semana'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe os dias da semana';
                    }
                    return null;
                  },
                  onSaved: (value) => _daysOfWeek = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: _time,
                  decoration: InputDecoration(labelText: 'Horário'),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o horário';
                    }
                    return null;
                  },
                  onSaved: (value) => _time = value!,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final newMedication = {
                        'name': _name,
                        'type': _type,
                        'quantity': _quantity,
                        'dosage': _dosage,
                        'daysOfWeek': _daysOfWeek,
                        'time': _time,
                      };
                      Navigator.of(context).pop(newMedication);
                    }
                  },
                  child: Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
