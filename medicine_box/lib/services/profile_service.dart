import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'package:logger/logger.dart';

class ProfileService {
  final SupabaseClient _db = Supabase.instance.client;
  final log = Logger();

  /// Retorna o perfil do usuário logado.
  Future<Profile> getOwnProfile() async {
    Stopwatch stopWatch = Stopwatch();
    stopWatch.start();
    try {
      final user = _db.auth.currentUser!.id;

      log.i('[PS] - Buscando perfil do usuário logado: $user');
      final data =
          await _db
              .from('profiles')
              .select<Map<String, dynamic>>()
              .eq('id', user)
              .single();

      stopWatch.stop();
      log.i(
        '[PS] - Busca pelo usuário finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      return Profile.fromMap(data);
    } catch (e) {
      stopWatch.stop();
      log.i(
        '[PS] - Busca pelo usuário finalizada em ${stopWatch.elapsedMilliseconds} ms',
      );
      log.e('[PS] - Erro ao buscar perfil do usuário logado', error: e);
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Retorna o perfil de um cuidador específico.
  Future<Profile> getCaregiverProfile(String id) async {
    try {
      log.i('[PS] - Buscando perfil do cuidador: $id');
      final data =
          await _db
              .from('profiles')
              .select<Map<String, dynamic>>()
              .eq('id', id)
              .eq('role', 'caregiver')
              .single();

      return Profile.fromMap(data);
    } catch (e) {
      log.e('[PS] - Erro ao buscar perfil do cuidador', error: e);
      throw Exception('Erro ao buscar perfil do cuidador: $e');
    }
  }

  /// Insere ou atualiza o perfil [p].
  Future<void> upsertProfile(Profile p) async {
    try {
      log.d('[PS] - Salvando perfil: ${p.toMap()}');
      await _db.from('profiles').upsert(p.toMap());
    } catch (e) {
      log.e('[PS] - Erro ao salvar perfil', error: e);
      throw Exception('Erro ao salvar perfil: $e');
    }
  }

  /// Pacientes do cuidador logado (via tabela de junção patient_caregivers).
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

  /// Cuidadores de um paciente específico.
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

  // Função para remover o vínculo de paciente de um cuidador
  Future<void> removePatientRelation(String caregiverId, String patientId) async {
    try {
      // Remove o vínculo entre o cuidador e o paciente na tabela patient_caregivers
      await _db
          .from('patient_caregivers')
          .delete()
          .eq('caregiver_id', caregiverId)
          .eq('patient_id', patientId);
      log.i('[PS] - Vínculo entre paciente e cuidador removido com sucesso.');
    } catch (e) {
      log.e('[PS] - Erro ao remover vínculo do paciente', error: e);
      throw Exception('Erro ao remover vínculo do paciente: $e');
    }
  }

  // Função para remover o vínculo de cuidador de um paciente
  Future<void> removeCaregiverRelation(String patientId, String caregiverId) async {
    try {
      // Remove o vínculo entre o paciente e o cuidador na tabela patient_caregivers
      await _db
          .from('patient_caregivers')
          .delete()
          .eq('patient_id', patientId)
          .eq('caregiver_id', caregiverId);
      log.i('[PS] - Vínculo entre cuidador e paciente removido com sucesso.');
    } catch (e) {
      log.e('[PS] - Erro ao remover vínculo do cuidador', error: e);
      throw Exception('Erro ao remover vínculo do cuidador: $e');
    }
  }
}
