import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';
import 'sign_in_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileSvc = ProfileService();
  Profile? _profile;
  bool _loading = true;
  List<Profile> _relatedProfiles = []; // Lista de pacientes ou cuidadores associados

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _profileSvc.getOwnProfile(); // Carrega o perfil do usuário logado
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });

      if (p.role == 'caregiver') {
        // Se for um "caregiver", buscar os pacientes associados
        final patients = await _profileSvc.getMyPatients();
        setState(() {
          _relatedProfiles = patients;
        });
      } else if (p.role == 'patient') {
        // Se for um "patient", buscar os cuidadores associados
        final caregivers = await _profileSvc.getCaregiversOfPatient(p.id);
        setState(() {
          _relatedProfiles = caregivers;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut(); // ou Supabase.instance.client.auth.signOut()
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair: $e')),
      );
    } finally {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (_) => false,
      );
    }
  }

  // Função para excluir o vínculo entre paciente e cuidador
  Future<void> _removeRelation(String relatedId) async {
    try {
      // Verifica o tipo de usuário e chama o método de exclusão correto
      if (_profile!.role == 'caregiver') {
        await _profileSvc.removePatientRelation(_profile!.id, relatedId);
      } else if (_profile!.role == 'patient') {
        await _profileSvc.removeCaregiverRelation(_profile!.id, relatedId);
      }

      // Recarrega os dados após a exclusão
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vínculo excluído com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir vínculo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Perfil não encontrado.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('Nome completo'),
                        subtitle: Text(_profile!.fullName),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(_profile!.email),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Tipo de usuário'),
                        subtitle: Text(_profile!.role.isEmpty ? '-' : _profile!.role),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Telefone'),
                        subtitle: Text(
                          (_profile!.phoneNumber ?? '').isEmpty
                              ? '-'
                              : _profile!.phoneNumber!,
                        ),
                      ),
                      const Divider(),

                      // Exibição de pacientes ou cuidadores associados
                      if (_profile!.role == 'caregiver') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Pacientes Atrelados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._relatedProfiles.map((patient) {
                          return Card(
                            child: ListTile(
                              title: Text(patient.fullName),
                              subtitle: Text(patient.email),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Confirma a exclusão antes de remover
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: Text(
                                          'Tem certeza que deseja remover ${patient.fullName}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _removeRelation(patient.id); // Remove o vínculo
                                          },
                                          child: const Text('Confirmar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ] else if (_profile!.role == 'patient') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Cuidadores Atrelados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._relatedProfiles.map((caregiver) {
                          return Card(
                            child: ListTile(
                              title: Text(caregiver.fullName),
                              subtitle: Text(caregiver.email),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Confirma a exclusão antes de remover
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: Text(
                                          'Tem certeza que deseja remover ${caregiver.fullName}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _removeRelation(caregiver.id); // Remove o vínculo
                                          },
                                          child: const Text('Confirmar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],

                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Sair'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
    );
  }
}
