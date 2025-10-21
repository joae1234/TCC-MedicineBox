import 'package:flutter/material.dart';
import '../services/invitation_service.dart';

class InviteCaregiverPage extends StatefulWidget {
  const InviteCaregiverPage({super.key});
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome completo do cuidador')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await InvitationService().sendInvitation(email);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Convite enviado')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 224, 207),
      appBar: AppBar(
        title: const Text(
          'Adicionar cuidador responsável',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFFFFA60E),
        foregroundColor: Colors.white,
        toolbarHeight: 100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Convite do cuidador',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator(color: Color(0xFFFFA60E))
                : ElevatedButton(
                  onPressed: _sendInvite,
                  child: const Text(
                    'Enviar Convite',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA60E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
