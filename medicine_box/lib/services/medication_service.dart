import 'package:medicine_box/models/base_request_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';

class MedicationService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Medication>?> getById(List<String> id) async {
    try {
      final response = await _db.from('medications').select().in_('id', id);

      if (response == null) return null;

      final result =
          (response as List)
              .map((item) => Medication.fromMap(item as Map<String, dynamic>))
              .toList();

      print('Medicações carregadas por ID: $result');
      return result;
    } catch (e) {
      print('Erro ao buscar medicações por ID: $e');
      return null;
    }
  }

  /// Carrega todas as medicações do usuário autenticado
  Future<List<Medication>> getAll() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final rows = await _db
        .from('medications')
        .select<List<Map<String, dynamic>>>()
        .eq('user_id', user.id)
        .order('created_at');

    return rows.map(Medication.fromMap).toList();
  }

  /// Carrega todas as medicações ativas do usuário autenticado
  Future<List<Medication>> getActiveMeds() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now().toUtc();

    final rows = await _db
        .from('medications')
        .select<List<Map<String, dynamic>>>()
        .eq('user_id', user.id)
        .lte('start_date', now.toIso8601String())
        .or('end_date.gte.${now.toIso8601String()},end_date.is.null')
        .order('created_at');

    return rows.map(Medication.fromMap).toList();
  }

  /// Cria ou atualiza uma medicação (upsert)
  Future<BaseRequestResult<Medication>> upsert(Medication med) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final payload = med.toMap()..['user_id'] = user.id;

    // for (final sched in med.schedules) {
    //   final scheduleAvailable = await isScheduleAvaiable(sched);

    //   if (scheduleAvailable != null) {
    //     return BaseRequestResult.failure(
    //       "Horário indisponível. Gostaria de alterar o horário  $sched para $scheduleAvailable?",
    //     );
    //   }
    // }

    final result =
        await _db.from('medications').upsert(payload).select().single();
    print("remedio criado: $result");

    return BaseRequestResult.success(Medication.fromMap(result));
  }

  /// Remove uma medicação
  Future<void> delete(String id) async {
    //TO DO: adicionar soft delete
    // await _db.from('medications').delete().eq('id', id);
  }

  /// Salva evento antes da tomada do remédio (pré-alarme)
  Future<void> savePreAlarm({
    required String id,
    required String medId,
    required DateTime timestamp,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    // await _db.from('medication_history').insert({
    //   'id': id,
    //   'user_id': user.id,
    //   'medication_id': medId,
    //   'taken_at': timestamp.toUtc().toIso8601String(),
    //   'delay_secs': 0,
    //   'status': 'Aguardando',
    // });
  }

  /// Atualiza o status de um histórico (chamado quando a medicação é detectada via sensor)
  Future<void> updateStatus(String id, int delaySecs) async {
    print('🔄 Tentando atualizar o histórico com ID: $id');

    final existing = await _db.from('medication_history').select().eq('id', id);

    if (existing.isEmpty) {
      print('❌ Nenhum histórico encontrado com ID: $id');
      return;
    }

    final updated =
        await _db
            .from('medication_history')
            .update({'status': 'Tomado', 'delay_secs': delaySecs})
            .eq('id', id)
            .select();

    print('✅ Histórico atualizado: $updated');
  }

  /// Busca o histórico completo das medicações
  Future<List<MedicationHistory>> getHistory() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final rows = await _db
        .from('medication_history')
        .select<List<Map<String, dynamic>>>()
        .eq('user_id', user.id)
        .order('taken_at', ascending: false);

    return rows.map(MedicationHistory.fromMap).toList();
  }

  /// (Opcional) Insere evento de dose tomada manualmente com delay
  Future<void> logTakenWithDelay(String medicationId, int delaySecs) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _db.from('medication_history').insert({
      'id': '${user.id}_$medicationId${DateTime.now().toIso8601String()}',
      'user_id': user.id,
      'medication_id': medicationId,
      'taken_at': DateTime.now().toUtc().toIso8601String(),
      'delay_secs': delaySecs,
      'status': 'Tomado',
    });
  }
}
