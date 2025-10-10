import 'package:medicine_box/models/base_request_result.dart';
import 'package:medicine_box/services/log_service.dart';
import 'package:medicine_box/services/medication_schedule_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';

class MedicationService {
  final SupabaseClient _db = Supabase.instance.client;
  final MedicationScheduleService _medScheduleService =
      MedicationScheduleService();
  final _log = LogService().logger;

  Future<List<Medication>?> getById(List<String> id) async {
    Stopwatch stopWatch = Stopwatch();
    stopWatch.start();
    try {
      _log.i("[MS] - Iniciando busca por medicações por uma lista de IDs $id");
      final user = _db.auth.currentUser;
      if (user == null) {
        _log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
        throw Exception('Usuário não autenticado');
      }

      final response = await _db
          .from('medications')
          .select()
          .is_('deleted_at', null)
          .in_('id', id);

      // _log.d('[MS] - Resultado da busca por medicações: $response');
      if (response == null) {
        _log.w(
          "[MS] - Nenhuma medicação foi encontrada para os IDs fornecidos",
        );
        stopWatch.stop();
        _log.i(
          '[MS] - Busca por medicações por ID finalizada em ${stopWatch.elapsedMilliseconds} ms',
        );
        return null;
      }

      final result =
          (response as List)
              .map((item) => Medication.fromMap(item as Map<String, dynamic>))
              .toList();

      // _log.d('[MS] - Medicações retornadas para o usuário ${user.id}: $result');
      stopWatch.stop();
      _log.i(
        '[MS] - Busca por medicações por ID finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      return result;
    } catch (e) {
      _log.e('[MS] - Erro ao buscar medicações por ID', error: e);
      stopWatch.stop();
      _log.i(
        '[MS] - Busca por medicações por ID finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      throw Exception('Erro ao buscar medicações por ID');
    }
  }

  /// Carrega todas as medicações do usuário autenticado
  Future<List<Medication>> getAll() async {
    Stopwatch stopWatch = Stopwatch();
    stopWatch.start();
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        _log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
        throw Exception('Usuário não autenticado');
      }

      _log.i('[MS] - Buscando todas as medicações para o usuário: ${user.id}');
      final rows = await _db
          .from('medications')
          .select<List<Map<String, dynamic>>>()
          .eq('user_id', user.id)
          .is_('deleted_at', null)
          .order('created_at');

      _log.d('[MS] - Medicações retornadas para o usuário ${user.id}: $rows');

      stopWatch.stop();
      _log.i(
        '[MS] - Busca por todas as medicações finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      return rows.map(Medication.fromMap).toList();
    } catch (e) {
      stopWatch.stop();
      _log.i(
        '[MS] - Busca por todas as medicações finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      _log.e('[MS] - Erro ao buscar todas as medicações', error: e);
      throw Exception('Erro ao buscar todas as medicações: $e');
    }
  }

  /// Carrega todas as medicações ativas do usuário autenticado
  Future<List<Medication>> getActiveMeds() async {
    Stopwatch stopWatch = Stopwatch();
    stopWatch.start();
    try {
      _log.i('[MS] - Iniciando busca por medicações ativas para o usuário');
      final user = _db.auth.currentUser;
      if (user == null) {
        _log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
        throw Exception('Usuário não autenticado');
      }

      final now = DateTime.now().toUtc();

      final rows = await _db
          .from('medications')
          .select<List<Map<String, dynamic>>>()
          .eq('user_id', user.id)
          .is_('deleted_at', null)
          .lte('start_date', now.toIso8601String())
          .or('end_date.gte.${now.toIso8601String()},end_date.is.null')
          .order('created_at');

      // _log.d(
      //   '[MS] - Medicações ativas retornadas para o usuário ${user.id}: $rows',
      // );

      stopWatch.stop();
      _log.i(
        '[MS] - Busca por medicações ativas finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      return rows.map(Medication.fromMap).toList();
    } catch (e) {
      stopWatch.stop();
      _log.i(
        '[MS] - Busca por medicações ativas finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      _log.e('[MS] - Erro ao buscar medicações ativas', error: e);
      throw Exception('Erro ao buscar medicações ativas: $e');
    }
  }

  /// Cria ou atualiza uma medicação (upsert)
  Future<BaseRequestResult<Medication>> upsert(Medication med) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        _log.e('[MS] - Usuário não autenticado ao buscar todas as medicações');
        throw Exception('Usuário não autenticado');
      }
      _log.i(
        '[MS] - Criando ou atualizando medicação ${med.toMap()} para o usuário: ${user.id}',
      );

      final payload = med.toMap()..['user_id'] = user.id;

      final result =
          await _db.from('medications').upsert(payload).select().single();

      _log.d('[MS] - Resultado da operação de atualização: $result');
      return BaseRequestResult.success(Medication.fromMap(result));
    } catch (e) {
      _log.e('[MS] - Erro ao criar ou atualizar medicação', error: e);
      throw Exception('Erro ao criar ou atualizar medicação: $e');
    }
  }

  /// Realiza uma exclusão lógica (soft delete) da medicação
  Future<void> delete(String id) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        _log.e('[MS] - Usuário não autenticado ao apagar medicação');
        throw Exception('Usuário não autenticado');
      }

      _log.i(
        '[MS] - Apagando a medicação $id do banco de dados - user: ${user.id}',
      );

      final deletedAt = DateTime.now().toUtc().toIso8601String();

      final result = await _db
          .from('medications')
          .update({'deleted_at': deletedAt})
          .eq('user_id', user.id)
          .eq('id', id);

      _log.d(
        '[MS] - Resultado da operação da soft delete da medicação: $result',
      );

      await _medScheduleService.cancelAllMedicationSchedules(id);
    } catch (e) {
      _log.e('[MS] - Erro ao apagar medicação', error: e);
      throw Exception('Erro ao apagar medicação: $e');
    }
  }
}
