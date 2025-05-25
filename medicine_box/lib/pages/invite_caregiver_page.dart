import 'package:flutter/material.dart';
import '../services/invitation_service.dart';

class InviteCaregiverPage extends StatefulWidget {
  const InviteCaregiverPage({Key? key}) : super(key: key);
  @override
  _InviteCaregiverPageState createState() => _InviteCaregiverPageState();
}

class _InviteCaregiverPageState extends State<InviteCaregiverPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Digite o email do paciente')));
      return;
    }
    setState(() => _loading = true);
    try {
      await InvitationService().sendInvitation(email);
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Convite enviado')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convidar cuidador')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email do paciente'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _sendInvite,
                  child: const Text('Enviar Convite'),
                ),
          ],
        ),
      ),
    );
  }
}
