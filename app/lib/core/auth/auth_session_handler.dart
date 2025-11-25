import '../storage/storage_service.dart';

/// Callback global para tratar expiração de token
/// Será configurado no app.dart
typedef TokenExpiredCallback = Future<void> Function();

/// Handler global para gerenciar sessão e expiração de token
class AuthSessionHandler {
  static TokenExpiredCallback? _onTokenExpired;

  /// Configura o callback para quando o token expirar
  static void configure({
    TokenExpiredCallback? onTokenExpired,
  }) {
    _onTokenExpired = onTokenExpired;
  }

  /// Trata expiração de token (401)
  /// Deve ser chamado quando uma requisição retorna 401
  static Future<void> handleTokenExpired() async {
    // Limpar storage
    await StorageService.clearAll();

    // Chamar callback se configurado
    if (_onTokenExpired != null) {
      await _onTokenExpired!();
    }
  }

  /// Verifica se há uma sessão válida
  static Future<bool> hasValidSession() async {
    final token = await StorageService.getToken();
    final userId = await StorageService.getUserId();
    final orgId = await StorageService.getOrganizationId();
    return token != null && userId != null && orgId != null;
  }
}

