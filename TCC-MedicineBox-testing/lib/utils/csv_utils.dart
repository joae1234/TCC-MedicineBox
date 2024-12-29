import 'dart:convert'; // Para usar utf8
import 'package:flutter/services.dart'; // Para rootBundle
import 'package:csv/csv.dart'; // Para processar o CSV

/// Função para carregar os nomes de medicamentos de um CSV.
Future<List<String>> loadMedicationNames(String assetPath) async {
  try {
    // Carregar o CSV do bundle
    final input = await rootBundle.loadString(assetPath);

    // Converter o conteúdo do CSV para uma lista de listas
    final rows = const CsvToListConverter(eol: '\n').convert(input);

    return rows.skip(1).map((row) => row[0].toString()).toList();
  } catch (e) {
    print('Erro ao carregar o arquivo CSV: $e');
    return [];
  }
}
