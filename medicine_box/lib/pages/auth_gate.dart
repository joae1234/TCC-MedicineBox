import 'package:flutter/material.dart';
import 'package:medicine_box/models/medication_alarm_details.dart';
import 'package:medicine_box/pages/alarm_ring_page.dart';
import 'package:medicine_box/services/log_service.dart';
import 'package:medicine_box/services/medication_schedule_service.dart';
import 'package:medicine_box/services/medication_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'welcome_page.dart';
import 'medication_list_page.dart';
import 'caregiver_dashboard_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;
  final _profileSvc = ProfileService();
  final _medScheduleSvc = MedicationScheduleService();
  final _medSvc = MedicationService();
  final _log = LogService().logger;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _safeNavigate(Widget page) {
    if (_navigated || !mounted) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page));
    });
  }

  Future<void> _bootstrap() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session != null) {
        final profile = await _profileSvc.getOwnProfile();
        if (!mounted) return;

        if (profile.role == 'caregiver') {
          // fluxo de caregiver
          _safeNavigate(const CaregiverDashboardPage());
        } else {
          // fluxo de paciente -> verifica alarmes ativos
          final activeAlarms = await getAnyActiveAlarms(session.user.id);

          _log.d(
            "[AG] - Alarmes ativos encontrados para o usuário ${session.user.id}: $activeAlarms",
          );

          if (activeAlarms.isNotEmpty) {
            _log.d(
              "[AG] - Navegando para AlarmRingPage com alarmes ativos: $activeAlarms",
            );
            _safeNavigate(AlarmRingPage(alarm: activeAlarms));
            return;
          }

          _safeNavigate(const MedicationListPage());
        }
        return;
      }

      if (!mounted) return;
      _safeNavigate(const WelcomePage());
    } catch (_) {
      if (!mounted) return;
      _safeNavigate(const WelcomePage());
    }
  }

  Future<List<MedicationAlarmDetails>> getAnyActiveAlarms(String userId) async {
    final nextMedication = await _medScheduleSvc.getUserNextMedication(null);

    if (nextMedication == null || nextMedication.isEmpty) {
      _log.i("[AG] - Não foi encontrado alarmes ativos para o usuário $userId");
      return [];
    }

    _log.d(
      "[AG] - Próximo alarme do usuário $userId encontrado: $nextMedication",
    );

    final now = DateTime.now();
    final scheduledAt = nextMedication[0].scheduledAt;

    _log.d(
      "[AG] - Verificando se o alarme agendado para $scheduledAt está ativo (agora é $now)",
    );

    if (now.isAfter(scheduledAt.add(Duration(minutes: 10))) ||
        now.isBefore(scheduledAt)) {
      _log.d("[AG] - Não há alarmes ativos para o usuário $userId no momento");
      return [];
    }

    final medicationDetails = await _medSvc.getById(
      nextMedication.map((e) => e.medicationId).toList(),
    );

    if (medicationDetails == null || medicationDetails.isEmpty) {
      _log.e(
        "[AG] - Não foi possível obter detalhes da medicação para o próximo alarme do usuário $userId",
      );
      throw Exception(
        'Não foi possível obter detalhes da medicação para o próximo alarme',
      );
    }

    final listMedNames =
        nextMedication.map((e) {
          final med = medicationDetails.firstWhere(
            (m) => m.id == e.medicationId,
            orElse:
                () =>
                    throw Exception(
                      "Medicação não encontrada para ID ${e.medicationId}",
                    ),
          );
          return med.name;
        }).toList();

    final nextMedAlarm =
        nextMedication.asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          return MedicationAlarmDetails(
            id: e.id,
            medicationId: e.medicationId,
            name: listMedNames[idx],
            dosage: e.dosage,
          );
        }).toList();

    return nextMedAlarm;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
