import 'package:medicine_box/models/medication_history.dart';
import 'package:medicine_box/services/medication_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicationScheduleService {
  final SupabaseClient _db = Supabase.instance.client;
  final MedicationService _medSvc = MedicationService();

  Future<void> upsertMedicationSchedule(
    String medicationId,
    DateTime startDate,
    DateTime endDate,
    List<String> days,
    List<String> schedules,
  ) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      final dayMapping = {
        "Seg": DateTime.monday,
        "Ter": DateTime.tuesday,
        "Qua": DateTime.wednesday,
        "Qui": DateTime.thursday,
        "Sex": DateTime.friday,
        "Sab": DateTime.saturday,
        "Dom": DateTime.sunday,
      };

      final selectedWeekDays =
          days
              .map((d) => dayMapping[d])
              .where((d) => d != null)
              .cast<int>()
              .toSet();

      final inserts = <Map<String, dynamic>>[];

      for (
        var date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))
      ) {
        if (selectedWeekDays.contains(date.weekday)) {
          for (final sched in schedules) {
            final parts = sched.split(":");
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour == null || minute == null) continue;

            final scheduledAt = DateTime(
              date.year,
              date.month,
              date.day,
              hour,
              minute,
            );

            inserts.add({
              'medication_id': medicationId,
              'user_id': user.id,
              'taken_at': null,
              'status': 'Scheduled',
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'scheduled_at': scheduledAt.toUtc().toIso8601String(),
            });

            final scheduleAvailable = await isScheduleAvaiable(scheduledAt);
            if (scheduleAvailable != null) {
              print(
                "Já existe uma medicação agendada para este período do dia: $scheduleAvailable",
              );
              return;
            }
          }
        }
      }

      if (inserts.isNotEmpty) {
        await _db.from('medication_history').upsert(inserts);
      }
    } catch (e) {
      throw Exception('Erro ao gerar os alertas para este medicamento: $e');
    }
  }

  Future<MedicationHistory?> getUserNextMedication(DateTime? time) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      var query = _db
          .from('medication_history')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Scheduled');

      final response =
          await query
              .order('scheduled_at', ascending: true)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      return MedicationHistory.fromMap({
        'id': response['id'],
        'user_id': response['user_id'],
        'medication_id': response['medication_id'],
        'scheduled_at': response['scheduled_at'],
        'taken_at': response['taken_at'],
        'status': response['status'],
        'created_at': response['created_at'],
      });
    } catch (e) {
      throw Exception('Erro buscar a próxima medicação do usuário: $e');
    }
  }

  Future<void>? updateMedicationStatus(
    String id,
    String status,
    DateTime? takenAt,
  ) async {
    try {
      await _db
          .from('medication_history')
          .update({
            'status': status,
            'taken_at': takenAt?.toUtc().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao atualizar o status da medicação: $e');
    }
  }

  Future<DateTime?> isScheduleAvaiable(DateTime scheduleTime) async {
    try {
      final isAm = scheduleTime.hour < 12;

      final activeMeds = await _medSvc.getActiveMeds();

      for (var med in activeMeds) {
        for (var sched in med.schedules) {
          final schedDateTime = DateTime.tryParse(sched);

          final isSchedTimeAm =
              schedDateTime != null && schedDateTime.hour < 12;

          if (isAm == isSchedTimeAm) {
            return schedDateTime;
          }
        }
      }

      return null;
    } catch (e) {
      throw Exception('Erro buscar a próxima medicação do usuário: $e');
    }
  }
}
