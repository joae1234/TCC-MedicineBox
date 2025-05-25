import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import 'medication_list_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _nameCtrl     = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSignUp() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    final fullName = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Senhas não conferem')));
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService().signUp(email, pass);
      final user = AuthService().currentUser!;
      // grava o perfil como 'patient'
      await ProfileService().upsertProfile(
        Profile(id: user.id, email: user.email!, fullName: fullName, role: 'patient'),
      );
      // navega para lista de meds
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MedicationListPage()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Erro ao cadastrar: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastre-se')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo')),
            TextField(controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress),
            TextField(controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true),
            TextField(controller: _confirmCtrl,
              decoration: const InputDecoration(labelText: 'Confirme a senha'),
              obscureText: true),
            const SizedBox(height: 24),
            _loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _doSignUp,
                  child: const Text('Cadastrar'),
                ),
          ],
        ),
      ),
    );
  }
}
