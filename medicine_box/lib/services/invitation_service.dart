import 'package:medicine_box/services/log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationService {
  final SupabaseClient _db = Supabase.instance.client;
  final log = LogService().logger;

  /// Paciente convida um cuidador pelo NOME (full_name == caregiverName)
  Future<void> sendInvitation(String caregiverName) async {
    try {
      // TO DO: melhorar busca, usar endpoint no service de profile
      log.i('[IS] - Procurando cuidador com o nome: $caregiverName');
      final response =
          await _db
              .from('profiles')
              .select('id')
              .eq('full_name', caregiverName)
              .eq('role', 'caregiver')
              .maybeSingle();
      // log.d('[IS] - Resultado da busca pelo cuidador: $response');

      if (response == null) {
        log.w(
          '[IS] - Não foi encontrado nenhum cuidador para esse nome: $caregiverName',
        );
        throw Exception('Cuidador não encontrado.');
      }

      final String caregiverId = response['id'] as String;

      final hasPending = await hasPendingInvitation(caregiverId);

      if (hasPending) {
        log.w(
          '[IS] - Já existe um convite pendente para esse cuidador: $caregiverId',
        );
        throw Exception('Já existe um convite pendente para este cuidador.');
      }

      log.i('[IS] - Enviando convite para o cuidador: $caregiverId');
      await _db.from('caregiver_invitations').insert({
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'caregiver_id': caregiverId,
        'patient_id': _db.auth.currentUser!.id, // quem envia é o paciente
        'status': 'Pending',
        'responded_at': null,
      });
    } catch (e) {
      log.e('[IS] - Erro ao enviar convite para o cuidador', error: e);
      throw Exception('Falha ao enviar convite: $e');
    }
  }

  /// Cuidador aceita/recusa um convite.
  /// IMPORTANTE: o vínculo na tabela patient_caregivers é criado por TRIGGER no banco.
  Future<void> respondInvitation(String invitationId, bool accepted) async {
    try {
      log.i('[IS] - Respondendo convite de id$invitationId');
      final status = accepted ? 'Accepted' : 'Rejected';
      log.i('[IS] - Resposta do convite escolhida pelo cuidador: $status');

      log.i('[IS] - Atualizando status do convite no banco de dados');
      await _db
          .from('caregiver_invitations')
          .update({
            'status': status,
            'responded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', invitationId);
    } catch (e) {
      log.e('[IS] - Erro ao responder convite', error: e);
      throw Exception('Falha ao responder convite: $e');
    }
  }

  Future<bool> hasPendingInvitation(String caregiverId) async {
    try {
      log.i(
        '[IS] - Verificando convites pendentes para o cuidador: $caregiverId',
      );
      final record =
          await _db
              .from('caregiver_invitations')
              .select('id')
              .eq('caregiver_id', caregiverId)
              .eq('status', 'Pending')
              .maybeSingle();

      // log.d('[IS] - Resultado da busca hasPendingInvitation: $record');
      return record != null;
    } catch (e) {
      log.e('[IS] - Erro ao verificar convites pendentes', error: e);
      throw Exception('Erro ao verificar convites pendentes: $e');
    }
  }

  /// Convites PENDENTES recebidos pelo CUIDADOR logado (lista com nome/email do paciente).
  Future<List<CaregiverInvitationView>>
  getMyPendingInvitationsForCaregiver() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      log.e('[IS] - Usuário não autenticado ao buscar convites pendentes');
      throw Exception('Usuário não autenticado');
    }

    log.i('[IS] - Buscando convites pendentes para o cuidador logado: $uid');
    // 1) convites pendentes destinados ao cuidador logado
    final invRes = await _db
        .from('caregiver_invitations')
        .select('id, patient_id, status')
        .eq('caregiver_id', uid)
        .eq('status', 'Pending')
        .order('created_at', ascending: false);

    final invRows = invRes as List;
    if (invRows.isEmpty) return [];

    final patientIds =
        invRows.map((e) => (e as Map)['patient_id'] as String).toSet().toList();

    // 2) perfis dos pacientes
    final profRes = await _db
        .from('profiles')
        .select('id, full_name, email')
        .in_('id', patientIds);

    final profRows = profRes as List;
    final Map<String, Map<String, dynamic>> patientsById = {
      for (final p in profRows)
        (p as Map)['id'] as String: Map<String, dynamic>.from(p as Map),
    };

    return invRows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final pid = map['patient_id'] as String;
      final p = patientsById[pid];

      return CaregiverInvitationView(
        invitationId: map['id'] as String,
        patientId: pid,
        status: map['status'] as String,
        patientName: p?['full_name'] as String?,
        patientEmail: p?['email'] as String?,
      );
    }).toList();
  }
}

/// View-model para exibir convites no dashboard do cuidador.
class CaregiverInvitationView {
  final String invitationId;
  final String patientId;
  final String status;
  final String? patientName;
  final String? patientEmail;

  CaregiverInvitationView({
    required this.invitationId,
    required this.patientId,
    required this.status,
    this.patientName,
    this.patientEmail,
  });
}
