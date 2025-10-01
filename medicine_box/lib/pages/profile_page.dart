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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _profileSvc.getOwnProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
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
                      ListTile(
                        leading: const Icon(Icons.diversity_3),
                        title: const Text('Cuidador vinculado'),
                        subtitle: Text(
                          (_profile!.caregiverId ?? '').isEmpty
                              ? 'Nenhum'
                              : _profile!.caregiverId!,
                        ),
                      ),
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
