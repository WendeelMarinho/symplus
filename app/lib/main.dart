import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar formatação de datas para pt_BR
  try {
    await initializeDateFormatting('pt_BR', null);
  } catch (e) {
    // Se falhar, tenta inicializar sem locale específico
    debugPrint('Erro ao inicializar locale pt_BR: $e');
  }
  
  runApp(
    const ProviderScope(
      child: SymplusApp(),
    ),
  );
}

