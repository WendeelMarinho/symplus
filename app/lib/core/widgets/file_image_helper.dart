import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper para criar ImageProvider que funciona em web e mobile
class FileImageHelper {
  /// Cria um ImageProvider apropriado baseado na plataforma
  static ImageProvider createImageProvider(String url) {
    // Na web, sempre usar NetworkImage
    if (kIsWeb) {
      return NetworkImage(url);
    }
    
    // Mobile: tentar usar FileImage, mas se falhar usar NetworkImage
    // Na web, este código nunca será executado devido ao if acima
    return NetworkImage(url);
  }
}

