import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Retorna o perfil do usuário logado.
  Future<Profile> getOwnProfile() async {
    try {
      final data = await _db
        .from('profiles')
        .select<Map<String, dynamic>>()     // já tipa como Map
        .eq('id', _db.auth.currentUser!.id)
        .single();                          // dispara a query e retorna o Map

      return Profile.fromMap(data);
    } catch (e) {
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Insere ou atualiza o perfil [p].
  Future<void> upsertProfile(Profile p) async {
    try {
      await _db
        .from('profiles')
        .upsert(p.toMap());                // dispara o upsert imediatamente
    } catch (e) {
      throw Exception('Erro ao salvar perfil: $e');
    }
  }
}
