import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'package:logger/logger.dart';

class ProfileService {
  final SupabaseClient _db = Supabase.instance.client;
  final log = Logger();

  /// Retorna o perfil do usuário logado.
  Future<Profile> getOwnProfile() async {
    try {
      final user = _db.auth.currentUser!.id;

      log.t('[PS] - Buscando perfil do usuário logado: $user');
      final data =
          await _db
              .from('profiles')
              .select<Map<String, dynamic>>()
              .eq('id', user)
              .single();

      log.t('[PS] - Perfil retornado: $data');
      return Profile.fromMap(data);
    } catch (e) {
      log.e('[PS] - Erro ao buscar perfil do usuário logado', error: e);
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Retorna o perfil de um cuidador específico.
  Future<Profile> getCaregiverProfile(String id) async {
    try {
      log.t('[PS] - Buscando perfil do cuidador: $id');
      final data =
          await _db
              .from('profiles')
              .select<Map<String, dynamic>>()
              .eq('id', id)
              .eq('role', 'caregiver')
              .single();

      log.t('[PS] - Perfil do cuidador retornado: $data');
      return Profile.fromMap(data);
    } catch (e) {
      log.e('[PS] - Erro ao buscar perfil do cuidador', error: e);
      throw Exception('Erro ao buscar perfil do cuidador: $e');
    }
  }

  /// Insere ou atualiza o perfil [p].
  Future<void> upsertProfile(Profile p) async {
    try {
      log.t('[PS] - Salvando perfil: ${p.toMap()}');
      await _db.from('profiles').upsert(p.toMap());
    } catch (e) {
      log.e('[PS] - Erro ao salvar perfil', error: e);
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
    try {
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
    } catch (e) {
      log.e('[PS] - Erro ao buscar pacientes do cuidador', error: e);
      throw Exception('Erro ao buscar pacientes do cuidador: $e');
    }
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
      log.e('[PS] - Erro ao buscar cuidadores do paciente', error: e);
      throw Exception('Erro ao buscar cuidadores do paciente: $e');
    }
  }
}
