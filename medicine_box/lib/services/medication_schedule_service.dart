import 'package:medicine_box/models/base_request_result.dart';
import 'package:medicine_box/models/medication_history.dart';
import 'package:medicine_box/services/medication_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_history.dart';

class MedicationScheduleService {
  final SupabaseClient _db = Supabase.instance.client;
  final MedicationService _medSvc = MedicationService();

  Future<BaseRequestResult<void>> upsertMedicationSchedule(
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
          }
        }
      }

      if (inserts.isNotEmpty) {
        await _db.from('medication_history').upsert(inserts);
      }

      return BaseRequestResult.success(null);
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
}

class UserHistoryResult {
  final List<MedicationHistory> history;
  final Map<String, String> medNames;
  UserHistoryResult(this.history, this.medNames);
}

extension MedicationScheduleServiceHistory on MedicationScheduleService {
  Future<UserHistoryResult> getUserHistoryWithMedNames(String userId) async {
    final supa = Supabase.instance.client;

    // 1) Busca histórico (usa * para não quebrar por coluna inexistente)
    final histRes = await supa
        .from('medication_history')
        .select<List<Map<String, dynamic>>>('*')
        .eq('user_id', userId)
        .order('scheduled_at', ascending: false);

    final history = <MedicationHistory>[];

    for (final raw in histRes) {
      final m = Map<String, dynamic>.from(raw);

      // Campos mínimos
      final id = (m['id'] as String?) ?? '';
      final uid = (m['user_id'] as String?) ?? '';
      final sched = m['scheduled_at'];
      if (id.isEmpty || uid.isEmpty || sched == null) {
        continue; // pula linha inválida
      }

      // Converte datas se vierem como string
      if (m['scheduled_at'] is String) {
        m['scheduled_at'] = DateTime.parse(m['scheduled_at'] as String);
      }
      if (m['taken_at'] is String) {
        m['taken_at'] = DateTime.tryParse(m['taken_at'] as String);
      }

      // Status default
      m['status'] = (m['status'] as String?) ?? 'Scheduled';

      // medication_id pode ser nulo — mantenha vazio
      m['medication_id'] = (m['medication_id'] as String?) ?? '';

      // === FLEX: detecta nome real do campo de atraso e normaliza para delay_secs ===
      final dynamic delayDyn =
          m.containsKey('delay_secs') ? m['delay_secs']
        : m.containsKey('delay') ? m['delay']
        : m.containsKey('delay_seconds') ? m['delay_seconds']
        : 0;

      int delaySecs;
      if (delayDyn is int) {
        delaySecs = delayDyn;
      } else if (delayDyn is num) {
        delaySecs = delayDyn.toInt();
      } else if (delayDyn is String) {
        delaySecs = int.tryParse(delayDyn) ?? 0;
      } else {
        delaySecs = 0;
      }
      // Normaliza para a chave que o seu fromMap espera
      m['delay_secs'] = delaySecs;
      // ===========================================================================

      try {
        history.add(MedicationHistory.fromMap(m));
      } catch (_) {
        // Se ainda assim não bater com o seu model, pula a linha
        continue;
      }
    }

    // 2) Mapa de nomes das meds
    final medIds = history
        .map((h) => h.medicationId)
        .where((id) => id != null && (id as String).isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final medNames = <String, String>{};
    if (medIds.isNotEmpty) {
      final medsRes = await supa
          .from('medications')
          .select<List<Map<String, dynamic>>>('id, name')
          .in_('id', medIds);

      for (final r in medsRes) {
        final map = Map<String, dynamic>.from(r);
        final mid = (map['id'] as String?) ?? '';
        if (mid.isEmpty) continue;
        medNames[mid] = (map['name'] as String?) ?? 'Desconhecido';
      }
    }

    return UserHistoryResult(history, medNames);
  }
}