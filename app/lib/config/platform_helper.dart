import 'package:flutter/foundation.dart';

// Importação condicional: dart:io em mobile, stub em web
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' if (dart.library.html) 'platform_helper_stub.dart' show Platform;

/// Helper para detectar se está rodando no Android
/// 
/// IMPORTANTE: Para dispositivos físicos Android, configure via:
/// flutter build apk --dart-define=API_BASE_URL=http://SEU_IP:8000
bool isAndroidPlatform() {
  // Se estiver em web, não é Android
  if (kIsWeb) return false;
  
  // Para mobile, verifica se é Android
  // ignore: avoid_web_libraries_in_flutter
  try {
    return Platform.isAndroid;
  } catch (_) {
    // Se não conseguir acessar, não é Android
    return false;
  }
}
