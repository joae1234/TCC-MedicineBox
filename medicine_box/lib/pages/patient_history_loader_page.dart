import 'package:flutter/material.dart';
import '../models/medication_history.dart';
import '../services/medication_schedule_service.dart';
import 'medication_history_page.dart';

class PatientHistoryLoaderPage extends StatefulWidget {
  final String userId;
  final String patientName;

  const PatientHistoryLoaderPage({
    super.key,
    required this.userId,
    required this.patientName,
  });

  @override
  State<PatientHistoryLoaderPage> createState() => _PatientHistoryLoaderPageState();
}

class _PatientHistoryLoaderPageState extends State<PatientHistoryLoaderPage> {
  final _svc = MedicationScheduleService();

  bool _loading = true;
  String? _error;
  List<MedicationHistory> _history = [];
  Map<String, String> _medNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _svc.getUserHistoryWithMedNames(widget.userId);
      if (!mounted) return;
      setState(() {
        _history = res.history;
        _medNames = res.medNames;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar histórico: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Histórico • ${widget.patientName}';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!),
          ),
        ),
      );
    }

    // Reaproveita sua página simples de histórico
    return MedicationHistoryPage(
      history: _history,
      medNames: _medNames,
    );
  }
}
