import 'package:supabase_flutter/supabase_flutter.dart';

class MedicationScheduleService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> upsertMedicationSchedule(
    String medicationId,
    DateTime startDate,
    DateTime endDate,
    List<String> days,
    List<String> schedules,
  ) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return;

      final dayMapping = {
        "Seg": DateTime.monday,
        "Ter": DateTime.tuesday,
        "Qua": DateTime.wednesday,
        "Qui": DateTime.thursday,
        "Sex": DateTime.friday,
        "Sab": DateTime.saturday,
        "Dom": DateTime.sunday,
      };  

      final selectedWeekDays = days
        .map((d) => dayMapping[d])
        .where((d) => d != null)
        .cast<int>()
        .toSet();

      final inserts = <Map<String, dynamic>>[];

      for (var date = startDate;
          !date.isAfter(endDate);
          date = date.add(const Duration(days: 1))) {
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
          }
        }
      }

      if (inserts.isNotEmpty) {
        await _db.from('medication_history').upsert(inserts);
      }
    } catch (e) {
      print('❌ Erro ao limpar agendamentos antigos: $e');
    }
  }
}