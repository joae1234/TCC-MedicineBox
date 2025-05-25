import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';

class MedicationService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Retorna todas as medicações do usuário logado, em ordem de criação.
  Future<List<Medication>> getAll() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    // Faz um SELECT tipado que retorna List<Map<String, dynamic>>
    final rows = await _db
      .from('medications')
      .select<List<Map<String, dynamic>>>()
      .eq('user_id', user.id)
      .order('created_at');

    // Converte cada Map num objeto Medication
    return rows.map(Medication.fromMap).toList();
  }

  /// Insere ou atualiza a medicação [med], injetando o user_id do usuário logado.
  Future<void> upsert(Medication med) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Monta o payload e garante que o banco vai gerar o UUID se for novo
    final payload = med.toMap()
      ..['user_id'] = user.id;

    await _db
      .from('medications')
      .upsert(payload);
    // Se quiser receber de volta as linhas atualizadas, basta acrescentar `.select()`
  }

  /// Remove a medicação de id [id].
  Future<void> delete(String id) async {
    await _db
      .from('medications')
      .delete()
      .eq('id', id);
  }

  /// Registra no histórico que o usuário tomou a medicação [medicationId] neste instante.
  Future<void> logTaken(String medicationId) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    await _db
      .from('medication_history')
      .insert({
        'user_id':        user.id,
        'medication_id':  medicationId,
        'taken_at':       DateTime.now().toUtc().toIso8601String(),
      });
  }

  /// Busca todo o histórico de doses do usuário logado, ordenado por data mais recente.
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
}
