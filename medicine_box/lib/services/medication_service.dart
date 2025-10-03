import 'package:medicine_box/models/base_request_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';
import 'package:logger/logger.dart';

class MedicationService {
  final SupabaseClient _db = Supabase.instance.client;
  final log = Logger();

  Future<List<Medication>?> getById(List<String> id) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
        throw Exception('Usuário não autenticado');
      }

      log.t('[MS] - Buscando medicações por ID: $id');
      final response = await _db.from('medications').select().in_('id', id);

      log.t('[MS] - Resultado da busca por medicações: $response');
      if (response == null) return null;

      final result =
          (response as List)
              .map((item) => Medication.fromMap(item as Map<String, dynamic>))
              .toList();

      log.t('[MS] - Medicações retornadas para o usuário ${user.id}: $result');
      return result;
    } catch (e) {
      log.e('[MS] - Erro ao buscar medicações por ID', error: e);
      throw Exception('Erro ao buscar medicações por ID: $e');
    }
  }

  /// Carrega todas as medicações do usuário autenticado
  Future<List<Medication>> getAll() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
      throw Exception('Usuário não autenticado');
    }

    log.t('[MS] - Buscando todas as medicações para o usuário: ${user.id}');
    final rows = await _db
        .from('medications')
        .select<List<Map<String, dynamic>>>()
        .eq('user_id', user.id)
        .order('created_at');

    log.t('[MS] - Medicações retornadas para o usuário ${user.id}: $rows');
    return rows.map(Medication.fromMap).toList();
  }

  /// Carrega todas as medicações ativas do usuário autenticado
  Future<List<Medication>> getActiveMeds() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
        throw Exception('Usuário não autenticado');
      }
      log.t('[MS] - Buscando medicações ativas para o usuário: ${user.id}');

      final now = DateTime.now().toUtc();

      final rows = await _db
          .from('medications')
          .select<List<Map<String, dynamic>>>()
          .eq('user_id', user.id)
          .lte('start_date', now.toIso8601String())
          .or('end_date.gte.${now.toIso8601String()},end_date.is.null')
          .order('created_at');

      log.t(
        '[MS] - Medicações ativas retornadas para o usuário ${user.id}: $rows',
      );
      return rows.map(Medication.fromMap).toList();
    } catch (e) {
      log.e('[MS] - Erro ao buscar medicações ativas', error: e);
      throw Exception('Erro ao buscar medicações ativas: $e');
    }
  }

  /// Cria ou atualiza uma medicação (upsert)
  Future<BaseRequestResult<Medication>> upsert(Medication med) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
        throw Exception('Usuário não autenticado');
      }
      log.t(
        '[MS] - Criando ou atualizando medicação $med para o usuário: ${user.id}',
      );

      final payload = med.toMap()..['user_id'] = user.id;

      final result =
          await _db.from('medications').upsert(payload).select().single();
      // print("remedio criado: $result");
      log.t('[MS] - Resultado da operação de atualização: $result');
      return BaseRequestResult.success(Medication.fromMap(result));
    } catch (e) {
      log.e('[MS] - Erro ao criar ou atualizar medicação', error: e);
      throw Exception('Erro ao criar ou atualizar medicação: $e');
    }
  }

  /// Remove uma medicação do banco.
  /// - Se a FK de `medication_history.medication_id` tiver `ON DELETE CASCADE`,
  ///   apenas o delete em `medications` já apaga o histórico.
  /// - Se NÃO tiver CASCADE, tentamos apagar o histórico do usuário primeiro
  ///   (para evitar erro de chave estrangeira) e depois a medicação.
  Future<void> delete(String id) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      // Tenta apagar diretamente (ideal com ON DELETE CASCADE)
      await _db
          .from('medications')
          .delete()
          .eq('user_id', user.id)
          .eq('id', id);
    } on PostgrestException catch (e) {
      // 23503 = foreign_key_violation
      if (e.code == '23503') {
        // Sem CASCADE: apaga histórico do usuário dessa medicação e tenta de novo
        await _db
            .from('medication_history')
            .delete()
            .eq('user_id', user.id)
            .eq('medication_id', id);

        await _db
            .from('medications')
            .delete()
            .eq('user_id', user.id)
            .eq('id', id);
      } else {
        rethrow;
      }
    }
  }

  /// Salva evento antes da tomada do remédio (pré-alarme)
  Future<void> savePreAlarm({
    required String id,
    required String medId,
    required DateTime timestamp,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    // Se quiser usar, descomente:
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
    final existing = await _db.from('medication_history').select().eq('id', id);
    if (existing.isEmpty) return;

    await _db
        .from('medication_history')
        .update({'status': 'Tomado', 'delay_secs': delaySecs})
        .eq('id', id)
        .select();
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
