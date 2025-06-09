import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';

class MedicationService {
  final SupabaseClient _db = Supabase.instance.client;

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

  Future<void> upsert(Medication med) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final payload = med.toMap()..['user_id'] = user.id;

    await _db.from('medications').upsert(payload);
  }

  Future<void> delete(String id) async {
    await _db.from('medications').delete().eq('id', id);
  }

  /// Novo: registra evento de medicação tomada com delay em segundos
  Future<void> logTakenWithDelay(String medicationId, int delaySecs) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _db.from('medication_history').insert({
      'id': _db.auth.currentUser!.id + medicationId + DateTime.now().toIso8601String(),
      'user_id': user.id,
      'medication_id': medicationId,
      'taken_at': DateTime.now().toUtc().toIso8601String(),
      'delay_secs': delaySecs,
    });
  }

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

  Future<void> updateStatus(String id, int delaySecs) async {
    print('🔄 Tentando atualizar o histórico com ID: $id');
    
    final existing = await _db
        .from('medication_history')
        .select()
        .eq('id', id);

    if (existing.isEmpty) {
      print('❌ Nenhum histórico encontrado com ID: $id');
      return;
    }

    final updated = await _db
        .from('medication_history')
        .update({
          'status': 'Tomado',
          'delay_secs': delaySecs,
        })
        .eq('id', id)
        .select();

    print('✅ Histórico atualizado: $updated');
  }

  Future<void> savePreAlarm({
    required String id,
    required String medId,
    required DateTime timestamp,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _db.from('medication_history').insert({
      'id': id,
      'user_id': user.id,
      'medication_id': medId,
      'taken_at': timestamp.toUtc().toIso8601String(),
      'delay_secs': 0,
      'status': 'Aguardando',
    });
  }
}
