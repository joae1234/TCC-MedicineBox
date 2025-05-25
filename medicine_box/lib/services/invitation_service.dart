import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Envia um convite de cuidado para o paciente identificado por [patientEmail].
  Future<void> sendInvitation(String patientEmail) async {
    try {
      // 1) Procura o paciente pelo email: retorna um Map<String,dynamic>? ou null
      final record = await _db
        .from('profiles')
        .select<Map<String, dynamic>>('id')
        .eq('email', patientEmail)
        .maybeSingle();

      final String patientId = record['id'] as String;

      // 2) Insere o convite (lança se falhar)
      await _db.from('caregiver_invitations').insert({
        'caregiver_id': _db.auth.currentUser!.id,
        'patient_id': patientId,
      });

    } catch (e) {
      // relança a exceção para o caller tratar
      throw Exception('Falha ao enviar convite: $e');
    }
  }

  /// Responde a um convite existente: aceita (true) ou recusa (false).
  Future<void> respondInvitation(String invitationId, bool accepted) async {
    try {
      final status = accepted ? 'accepted' : 'rejected';

      // 1) Atualiza o status do convite
      await _db
        .from('caregiver_invitations')
        .update({
          'status': status,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', invitationId);

      if (accepted) {
        // 2) Se aceitou, busca o caregiver_id e cria o vínculo
        final rec = await _db
          .from('caregiver_invitations')
          .select<Map<String, dynamic>>('caregiver_id')
          .eq('id', invitationId)
          .single();

        final String caregiverId = rec['caregiver_id'] as String;
        await _db.from('patient_caregivers').insert({
          'patient_id': _db.auth.currentUser!.id,
          'caregiver_id': caregiverId,
        });
      }

    } catch (e) {
      throw Exception('Falha ao responder convite: $e');
    }
  }
}
