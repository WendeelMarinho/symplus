import 'package:flutter/material.dart';
import '../rbac/permissions_catalog.dart';

/// Catálogo centralizado de menu com controle de permissões (RBAC)
/// 
/// Define todas as rotas e seus controles de acesso por permissão.
enum UserRole {
  owner,
  admin,
  user,
}

class MenuItem {
  final String id;
  final String label;
  final String route;
  final IconData icon;
  final Permission? requiredPermission; // Permissão necessária para ver o item
  final List<UserRole> allowedRoles; // Mantido para compatibilidade

  const MenuItem({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
    this.requiredPermission,
    this.allowedRoles = const [], // Deprecated, usar requiredPermission
  });
}

class MenuCatalog {
  static const String basePath = '/app';

  // Todas as rotas principais
  static const String overview = '$basePath/overview';
  static const String dashboard = '$basePath/dashboard';
  static const String accounts = '$basePath/accounts';
  static const String transactions = '$basePath/transactions';
  static const String categories = '$basePath/categories';
  static const String dueItems = '$basePath/due-items';
  static const String documents = '$basePath/documents';
  static const String requests = '$basePath/requests';
  static const String notifications = '$basePath/notifications';
  static const String subscription = '$basePath/subscription';
  static const String reportsPl = '$basePath/reports/pl';
  static const String profile = '$basePath/profile';
  static const String settings = '$basePath/settings';

  // Catálogo completo de itens do menu
  static final List<MenuItem> allItems = [
    MenuItem(
      id: 'overview',
      label: 'Visão Geral',
      route: overview,
      icon: Icons.apps,
      requiredPermission: Permission.viewDashboard, // Overview usa mesma permissão do dashboard
    ),
    MenuItem(
      id: 'dashboard',
      label: 'Dashboard',
      route: dashboard,
      icon: Icons.dashboard,
      requiredPermission: Permission.viewDashboard,
    ),
    MenuItem(
      id: 'accounts',
      label: 'Contas',
      route: accounts,
      icon: Icons.account_balance_wallet,
      requiredPermission: Permission.viewAccounts,
    ),
    MenuItem(
      id: 'transactions',
      label: 'Transações',
      route: transactions,
      icon: Icons.swap_horiz,
      requiredPermission: Permission.viewTransactions,
    ),
    MenuItem(
      id: 'categories',
      label: 'Categorias',
      route: categories,
      icon: Icons.category,
      requiredPermission: Permission.viewCategories,
    ),
    MenuItem(
      id: 'due-items',
      label: 'Vencimentos',
      route: dueItems,
      icon: Icons.calendar_today,
      requiredPermission: Permission.viewDueItems,
    ),
    MenuItem(
      id: 'documents',
      label: 'Documentos',
      route: documents,
      icon: Icons.folder,
      requiredPermission: Permission.viewDocuments,
    ),
    MenuItem(
      id: 'requests',
      label: 'Tickets',
      route: requests,
      icon: Icons.support_agent,
      requiredPermission: Permission.viewRequests,
    ),
    MenuItem(
      id: 'notifications',
      label: 'Notificações',
      route: notifications,
      icon: Icons.notifications,
      requiredPermission: Permission.viewNotifications,
    ),
    MenuItem(
      id: 'subscription',
      label: 'Assinatura',
      route: subscription,
      icon: Icons.card_membership,
      requiredPermission: Permission.viewSubscription,
    ),
    MenuItem(
      id: 'reports',
      label: 'Relatórios (P&L)',
      route: reportsPl,
      icon: Icons.bar_chart,
      requiredPermission: Permission.viewReportsPl,
    ),
    MenuItem(
      id: 'profile',
      label: 'Perfil',
      route: profile,
      icon: Icons.person,
      requiredPermission: Permission.viewProfile,
    ),
    MenuItem(
      id: 'settings',
      label: 'Configurações',
      route: settings,
      icon: Icons.settings,
      requiredPermission: Permission.viewSettings,
    ),
  ];

  /// Filtra itens do menu baseado nas permissões do usuário
  static List<MenuItem> getItemsForRole(UserRole role) {
    final permissions = PermissionsCatalog.getPermissionsForRole(role);
    return allItems.where((item) {
      // Se tem requiredPermission, verifica se o papel tem essa permissão
      if (item.requiredPermission != null) {
        return permissions.contains(item.requiredPermission);
      }
      // Fallback para allowedRoles (compatibilidade)
      return item.allowedRoles.isEmpty || item.allowedRoles.contains(role);
    }).toList();
  }

  /// Verifica se uma rota é permitida para o papel
  static bool isRouteAllowed(String route, UserRole role) {
    final item = allItems.firstWhere(
      (item) => item.route == route,
      orElse: () => MenuItem(
        id: 'unknown',
        label: 'Unknown',
        route: route,
        icon: Icons.help,
      ),
    );
    
    // Verifica por permissão primeiro
    if (item.requiredPermission != null) {
      return PermissionsCatalog.hasPermission(role, item.requiredPermission!);
    }
    
    // Fallback para allowedRoles
    return item.allowedRoles.isEmpty || item.allowedRoles.contains(role);
  }

  /// Verifica se uma rota é permitida baseado em permissão
  static bool isRouteAllowedByPermission(String route, Permission permission) {
    final item = allItems.firstWhere(
      (item) => item.route == route,
      orElse: () => MenuItem(
        id: 'unknown',
        label: 'Unknown',
        route: route,
        icon: Icons.help,
      ),
    );
    return item.requiredPermission == permission;
  }

  /// Busca um item pelo ID
  static MenuItem? getItemById(String id) {
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca um item pela rota
  static MenuItem? getItemByRoute(String route) {
    try {
      return allItems.firstWhere((item) => item.route == route);
    } catch (e) {
      return null;
    }
  }
}

