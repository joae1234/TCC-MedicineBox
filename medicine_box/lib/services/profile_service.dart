import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Retorna o perfil do usuário logado.
  Future<Profile> getOwnProfile() async {
    try {
      final data = await _db
          .from('profiles')
          .select<Map<String, dynamic>>()
          .eq('id', _db.auth.currentUser!.id)
          .single();

      return Profile.fromMap(data);
    } catch (e) {
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Retorna o perfil de um cuidador específico.
  Future<Profile> getCaregiverProfile(String id) async {
    try {
      final data = await _db
          .from('profiles')
          .select<Map<String, dynamic>>()
          .eq('id', id)
          .eq('role', 'caregiver')
          .single();

      return Profile.fromMap(data);
    } catch (e) {
      throw Exception('Erro ao buscar perfil do cuidador: $e');
    }
  }

  /// Insere ou atualiza o perfil [p].
  Future<void> upsertProfile(Profile p) async {
    try {
      await _db.from('profiles').upsert(p.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar perfil: $e');
    }
  }

  /// Pacientes do cuidador logado (via tabela de junção patient_caregivers).
  ///
  /// IMPORTANTE: como patient_caregivers possui DUAS FKs para profiles
  /// (patient_id e caregiver_id), precisamos indicar explicitamente
  /// a FK usada para embutir o perfil do paciente, senão dá ambiguidade:
  ///   profiles!patient_caregivers_patient_id_fkey(*)
  Future<List<Profile>> getMyPatients() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Usuário não autenticado');

    final res = await _db
        .from('patient_caregivers')
        .select('patient:profiles!patient_caregivers_patient_id_fkey(*)')
        .eq('caregiver_id', uid);

    final rows = res as List;

    return rows
        .map((r) => (r as Map)['patient'])
        .where((p) => p != null)
        .map((p) => Profile.fromMap(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  /// (Opcional) Cuidadores de um paciente específico, caso você use em alguma tela.
  /// Exemplifica o join pela outra FK:
  ///   profiles!patient_caregivers_caregiver_id_fkey(*)
  Future<List<Profile>> getCaregiversOfPatient(String patientId) async {
    try {
      final res = await _db
          .from('patient_caregivers')
          .select('caregiver:profiles!patient_caregivers_caregiver_id_fkey(*)')
          .eq('patient_id', patientId);

      final rows = res as List;

      return rows
          .map((r) => (r as Map)['caregiver'])
          .where((c) => c != null)
          .map((c) => Profile.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar cuidadores do paciente: $e');
    }
  }
}
