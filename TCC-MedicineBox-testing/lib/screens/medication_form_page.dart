import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import para formatação de datas
import 'package:intl/date_symbol_data_local.dart'; // Import para inicializar dados de localização

class MedicationFormPage extends StatefulWidget {
  final Map<String, dynamic>? medication;

  const MedicationFormPage({Key? key, this.medication}) : super(key: key);

  @override
  _MedicationFormPageState createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Variáveis para armazenar os dados do formulário
  late String _name;
  late String _type;
  int? _quantity;
  double? _dosage;
  late List<String> _selectedDaysOfWeek; // Lista de dias selecionados
  DateTime? _startDate; // Data de início
  DateTime? _endDate; // Data de fim
  late List<TimeOfDay> _selectedTimes; // Lista de horários

  @override
  void initState() {
    super.initState();
    // Inicializa os dados de localidade para formatação de datas
    initializeDateFormatting('pt_BR', null).then((_) {
      setState(() {}); // Recarrega a interface após inicialização
    });

    // Inicializa as variáveis com dados ou valores padrão
    _name = widget.medication?['name'] ?? '';
    _type = widget.medication?['type'] ?? 'pill'; // Valor padrão: comprimido
    _quantity = widget.medication?['quantity'];
    _dosage = widget.medication?['dosage'];
    _selectedDaysOfWeek = widget.medication?['daysOfWeek']?.split(', ') ?? [];
    _startDate = widget.medication?['startDate'];
    _endDate = widget.medication?['endDate'];
    _selectedTimes = widget.medication?['times'] != null
        ? (widget.medication!['times'] as List<dynamic>)
            .map((time) {
              final parts = time.split(':');
              return TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            })
            .toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null ? 'Adicionar Medicamento' : 'Editar Medicamento',
        ),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        color: Colors.purple.shade50,
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo para o nome do medicamento
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(
                    labelText: 'Nome do Medicamento',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o nome do medicamento';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 16),

                // Dropdown para selecionar o tipo do medicamento
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Medicamento',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'pill', child: Text('Comprimido')),
                    DropdownMenuItem(value: 'liquid', child: Text('Líquido')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _type = value!;
                      _quantity = null;
                      _dosage = null;
                    });
                  },
                  onSaved: (value) => _type = value!,
                ),
                const SizedBox(height: 16),

                // Campo para quantidade (se comprimido)
                if (_type == 'pill')
                  TextFormField(
                    initialValue: _quantity?.toString(),
                    decoration: InputDecoration(
                      labelText: 'Quantidade de Comprimidos',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_type == 'pill' && (value == null || int.tryParse(value) == null)) {
                        return 'Informe uma quantidade válida';
                      }
                      return null;
                    },
                    onSaved: (value) => _quantity = int.tryParse(value!),
                  ),

                // Campo para dosagem (se líquido)
                if (_type == 'liquid')
                  TextFormField(
                    initialValue: _dosage?.toString(),
                    decoration: InputDecoration(
                      labelText: 'Dosagem em ml',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_type == 'liquid' && (value == null || double.tryParse(value) == null)) {
                        return 'Informe uma dosagem válida';
                      }
                      return null;
                    },
                    onSaved: (value) => _dosage = double.tryParse(value!),
                  ),
                const SizedBox(height: 16),

                // Seleção de dias da semana
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dias da Semana', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo']
                          .map((day) => FilterChip(
                                label: Text(day),
                                selected: _selectedDaysOfWeek.contains(day),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedDaysOfWeek.add(day);
                                    } else {
                                      _selectedDaysOfWeek.remove(day);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seleção de intervalo de datas
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data Início',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: _startDate != null
                              ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_startDate!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data Fim',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: _endDate != null
                              ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_endDate!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seleção de horários
                Text('Horários', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: _selectedTimes
                      .map((time) => ListTile(
                            title: Text(time.format(context)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedTimes.remove(time);
                                });
                              },
                            ),
                          ))
                      .toList(),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTimes.add(time);
                      });
                    }
                  },
                  icon: Icon(Icons.add, color: Colors.purple),
                  label: Text(
                    'Adicionar Horário',
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão para salvar
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        final medicationData = {
                          'name': _name,
                          'type': _type,
                          'quantity': _quantity,
                          'dosage': _dosage,
                          'daysOfWeek': _selectedDaysOfWeek.join(', '),
                          'startDate': _startDate,
                          'endDate': _endDate,
                          'times': _selectedTimes
                              .map((time) => '${time.hour}:${time.minute}')
                              .toList(),
                        };
                        Navigator.of(context).pop(medicationData);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
