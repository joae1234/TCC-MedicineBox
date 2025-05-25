import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/sign_in_page.dart';
import 'pages/medication_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://uyvfssoonvrbvrulqlob.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5dmZzc29vbnZyYnZydWxxbG9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMTUzNDMsImV4cCI6MjA2MzY5MTM0M30.yYJjgDL1tUd1u15RooOZVoWZRd1hdwL0OX48jtdyEAg',
    authFlowType: AuthFlowType.pkce,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();
  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
      title: 'Medication Reminder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<AuthChangeEvent>(
        stream: Supabase.instance.client.auth.onAuthStateChange.map((e) => e.event),
        builder: (ctx, snap) {
          final session = Supabase.instance.client.auth.currentSession;
          return session == null
            ? const SignInPage()
            : const MedicationListPage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}