import 'package:flutter/foundation.dart';

/// Serviço de telemetria para logs de ações do usuário
class TelemetryService {
  static bool _enabled = kDebugMode;

  /// Habilita/desabilita telemetria
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Registra uma ação do usuário
  static void logAction(String action, {Map<String, dynamic>? metadata}) {
    if (!_enabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final log = {
      'timestamp': timestamp,
      'action': action,
      if (metadata != null) ...metadata,
    };

    if (kDebugMode) {
      debugPrint('[Telemetry] $log');
    }

    // Em produção, aqui você enviaria para um serviço de analytics
    // Ex: Firebase Analytics, Sentry, etc.
  }

  /// Registra navegação
  static void logNavigation(String route, {String? fromRoute}) {
    logAction('navigation', metadata: {
      'route': route,
      if (fromRoute != null) 'from_route': fromRoute,
    });
  }

  /// Registra criação de item
  static void logCreate(String itemType, {String? itemId}) {
    logAction('create', metadata: {
      'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
    });
  }

  /// Registra edição de item
  static void logEdit(String itemType, String itemId) {
    logAction('edit', metadata: {
      'item_type': itemType,
      'item_id': itemId,
    });
  }

  /// Registra exclusão de item
  static void logDelete(String itemType, String itemId) {
    logAction('delete', metadata: {
      'item_type': itemType,
      'item_id': itemId,
    });
  }

  /// Registra erro
  static void logError(String error, {String? context, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    logAction('error', metadata: {
      'error': error,
      if (context != null) 'context': context,
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      if (metadata != null) ...metadata,
    });
  }

  /// Registra acesso negado
  static void logAccessDenied(String action, String userRole) {
    logAction('access_denied', metadata: {
      'action': action,
      'user_role': userRole,
    });
  }
}

