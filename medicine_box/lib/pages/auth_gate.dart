import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'welcome_page.dart';
import 'medication_list_page.dart';
import 'caregiver_dashboard_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;
  final _profileSvc = ProfileService();

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _safeNavigate(Widget page) {
    if (_navigated || !mounted) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page));
    });
  }

  Future<void> _bootstrap() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session != null) {
        final profile = await _profileSvc.getOwnProfile();
        if (!mounted) return;

        if (profile.role == 'caregiver') {
          _safeNavigate(const CaregiverDashboardPage());
        } else {
          _safeNavigate(const MedicationListPage());
        }
        return;
      }

      if (!mounted) return;
      _safeNavigate(const WelcomePage());
    } catch (_) {
      if (!mounted) return;
      _safeNavigate(const WelcomePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
