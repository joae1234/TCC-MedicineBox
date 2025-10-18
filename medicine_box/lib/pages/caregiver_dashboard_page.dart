import 'package:flutter/material.dart';
import 'package:medicine_box/pages/last_login_store.dart';

import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/invitation_service.dart';
import '../services/auth_service.dart';

import 'patient_history_loader_page.dart';
import 'profile_page.dart';
import 'sign_in_page.dart';

class CaregiverDashboardPage extends StatefulWidget {
  const CaregiverDashboardPage({super.key});

  @override
  State<CaregiverDashboardPage> createState() => _CaregiverDashboardPageState();
}

enum _CaregiverMenu { profile, logout }

class _CaregiverDashboardPageState extends State<CaregiverDashboardPage> {
  final _profileSvc = ProfileService();
  final _invSvc = InvitationService();

  bool _loading = true;
  bool _responding = false;
  String? _error;

  List<Profile> _patients = [];
  List<CaregiverInvitationView> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patients = await _profileSvc.getMyPatients();
      final invites = await _invSvc.getMyPendingInvitationsForCaregiver();

      if (!mounted) return;
      setState(() {
        _patients = patients;
        _pendingInvites = invites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar dados: $e';
        _loading = false;
      });
    }
  }

  Future<void> _respondInvite(String invitationId, bool accepted) async {
    if (_responding) return;
    setState(() => _responding = true);
    try {
      await _invSvc.respondInvitation(invitationId, accepted);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Convite aceito.' : 'Convite recusado.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao responder convite: $e')));
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  Future<void> _handleMenu(_CaregiverMenu action) async {
    switch (action) {
      case _CaregiverMenu.profile:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      case _CaregiverMenu.logout:
        try {
          await AuthService().signOut();
          await LastLoginStore.clear();
        } catch (_) {}
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInPage()),
          (_) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Cuidador'),
        actions: [
          PopupMenuButton<_CaregiverMenu>(
            onSelected: _handleMenu,
            itemBuilder:
                (ctx) => const [
                  PopupMenuItem(
                    value: _CaregiverMenu.profile,
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Perfil'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _CaregiverMenu.logout,
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sair'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadAll,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (_pendingInvites.isNotEmpty) ...[
                      const Text(
                        'Convites Pendentes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._pendingInvites.map((inv) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.mark_email_unread),
                            title: Text(
                              inv.patientName ?? inv.patientEmail ?? 'Paciente',
                            ),
                            subtitle: Text('Status: ${inv.status}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed:
                                      _responding
                                          ? null
                                          : () => _respondInvite(
                                            inv.invitationId,
                                            false,
                                          ),
                                  child: const Text('Recusar'),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      _responding
                                          ? null
                                          : () => _respondInvite(
                                            inv.invitationId,
                                            true,
                                          ),
                                  child: const Text('Aceitar'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Meus Pacientes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_patients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Você ainda não cuida de nenhum paciente.',
                          ),
                        ),
                      )
                    else
                      ..._patients.map((p) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(p.fullName),
                            subtitle: Text(p.email),
                            trailing: const Icon(Icons.history),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PatientHistoryLoaderPage(
                                        userId: p.id,
                                        patientName: p.fullName,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
    );
  }
}
