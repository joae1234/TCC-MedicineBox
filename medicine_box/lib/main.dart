import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/welcome_page.dart';
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Reminder',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      // Mostra WelcomePage como primeira tela
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
