import 'package:flutter/material.dart';
import '/screens/medication_list_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Medicamentos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MedicationListPage(),
    );
  }
}
