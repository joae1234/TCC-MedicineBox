import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationService {
  final SupabaseClient _db = Supabase.instance.client;

  // TO DO TRANSFORMAR ISSO AQUI EM POPUP
  Future<void> sendInvitation(String caregiverName) async {
    try {
      final response =
          await _db
              .from('profiles')
              .select('id')
              .eq('full_name', caregiverName)
              .eq('role', 'caregiver')
              .maybeSingle();

      print("Response: ${response}");

      if (response == null) {
        throw Exception('Cuidador não encontrado.');
      }

      final String caregiverId = response['id'] as String;

      final hasPending = await hasPendingInvitation(caregiverId);

      if (hasPending) {
        throw Exception('Já existe um convite pendente para este cuidador.');
      }

      await _db.from('caregiver_invitations').insert({
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'caregiver_id': caregiverId,
        'patient_id': _db.auth.currentUser!.id,
        'status': 'Pending',
        'responded_at': null,
      });
    } catch (e) {
      throw Exception('Falha ao enviar convite: $e');
    }
  }

  Future<void> respondInvitation(String invitationId, bool accepted) async {
    try {
      final status = accepted ? 'Accepted' : 'Rejected';

      await _db
          .from('caregiver_invitations')
          .update({
            'status': status,
            'responded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', invitationId);

      if (accepted) {
        final rec =
            await _db
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

  Future<bool> hasPendingInvitation(String caregiverId) async {
    try {
      final record =
          await _db
              .from('caregiver_invitations')
              .select<Map<String, dynamic>?>('id')
              .eq('caregiver_id', caregiverId)
              .eq('status', 'Pending')
              .maybeSingle();

      return record != null;
    } catch (e) {
      throw Exception('Erro ao verificar convites pendentes: $e');
    }
  }
}
