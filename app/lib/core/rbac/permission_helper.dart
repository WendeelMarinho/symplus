import '../auth/auth_provider.dart';
import '../navigation/menu_catalog.dart';
import '../accessibility/telemetry_service.dart';
import 'permissions_catalog.dart';

/// Helper centralizado para verificações de permissão RBAC
class PermissionHelper {
  /// Verifica se o usuário tem uma permissão específica
  static bool hasPermission(AuthState authState, Permission permission) {
    return PermissionsCatalog.hasPermission(authState.role, permission);
  }

  /// Verifica se o usuário tem qualquer uma das permissões
  static bool hasAnyPermission(AuthState authState, Set<Permission> permissions) {
    return PermissionsCatalog.hasAnyPermission(authState.role, permissions);
  }

  /// Verifica se o usuário tem todas as permissões
  static bool hasAllPermissions(AuthState authState, Set<Permission> permissions) {
    return PermissionsCatalog.hasAllPermissions(authState.role, permissions);
  }

  /// Retorna mensagem de erro para permissão negada
  static String getDeniedMessage(Permission permission) {
    return 'Acesso negado. Você não tem permissão para: ${permission.description}';
  }

  /// Registra telemetria de negação de acesso
  static void logAccessDenied(AuthState authState, Permission permission, {String? context}) {
    TelemetryService.logAction('rbac.denied', metadata: {
      'permission': permission.id,
      'role': authState.role.toString(),
      if (context != null) 'context': context,
    });
  }

  /// Registra telemetria de item oculto
  static void logHidden(AuthState authState, String itemId, Permission? permission) {
    TelemetryService.logAction('rbac.menu.hidden', metadata: {
      'item_id': itemId,
      'role': authState.role.toString(),
      if (permission != null) 'missing_permission': permission.id,
    });
  }

  /// Registra telemetria de ação ocultada
  static void logActionHidden(AuthState authState, String actionId, Permission permission) {
    TelemetryService.logAction('rbac.action.hidden', metadata: {
      'action_id': actionId,
      'missing_permission': permission.id,
      'role': authState.role.toString(),
    });
  }

  /// Registra telemetria de ação desabilitada
  static void logActionDisabled(AuthState authState, String actionId, Permission permission) {
    TelemetryService.logAction('rbac.action.disabled', metadata: {
      'action_id': actionId,
      'missing_permission': permission.id,
      'role': authState.role.toString(),
    });
  }

  /// Registra telemetria de redirect por negação
  static void logRedirect(AuthState authState, String route, Permission? permission) {
    TelemetryService.logAction('rbac.denied.redirect', metadata: {
      'route': route,
      'role': authState.role.toString(),
      if (permission != null) 'missing_permission': permission.id,
    });
  }

  /// Registra telemetria de atalho negado
  static void logShortcutDenied(AuthState authState, String shortcut, Permission permission) {
    TelemetryService.logAction('rbac.shortcut.denied', metadata: {
      'shortcut': shortcut,
      'missing_permission': permission.id,
      'role': authState.role.toString(),
    });
  }
}

