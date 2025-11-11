import '../auth/auth_provider.dart';
import '../navigation/menu_catalog.dart';

/// Permissões granulares do sistema
class Permission {
  final String id;
  final String description;

  const Permission(this.id, this.description);

  // Visão (View)
  static const viewAccounts = Permission('accounts.view', 'Visualizar contas');
  static const viewTransactions = Permission('transactions.view', 'Visualizar transações');
  static const viewCategories = Permission('categories.view', 'Visualizar categorias');
  static const viewDueItems = Permission('due_items.view', 'Visualizar vencimentos');
  static const viewDocuments = Permission('documents.view', 'Visualizar documentos');
  static const viewRequests = Permission('requests.view', 'Visualizar tickets');
  static const viewNotifications = Permission('notifications.view', 'Visualizar notificações');
  static const viewReports = Permission('reports.view', 'Visualizar relatórios');
  static const viewReportsPl = Permission('reports.pl.view', 'Visualizar relatório P&L');
  static const viewDashboard = Permission('dashboard.view', 'Visualizar dashboard');
  static const viewSubscription = Permission('subscription.view', 'Visualizar assinatura');
  static const viewSettings = Permission('settings.view', 'Visualizar configurações');
  static const viewExports = Permission('exports.view', 'Visualizar exportações');
  static const viewProfile = Permission('profile.view', 'Visualizar perfil');

  // Ações - Transações
  static const transactionsCreate = Permission('transactions.create', 'Criar transação');
  static const transactionsEdit = Permission('transactions.edit', 'Editar transação');
  static const transactionsDelete = Permission('transactions.delete', 'Excluir transação');

  // Ações - Categorias
  static const categoriesCreate = Permission('categories.create', 'Criar categoria');
  static const categoriesEdit = Permission('categories.edit', 'Editar categoria');
  static const categoriesDelete = Permission('categories.delete', 'Excluir categoria');

  // Ações - Documentos
  static const documentsUpload = Permission('documents.upload', 'Fazer upload de documento');
  static const documentsDelete = Permission('documents.delete', 'Excluir documento');

  // Ações - Vencimentos
  static const dueItemsCreate = Permission('due_items.create', 'Criar vencimento');
  static const dueItemsMarkPaid = Permission('due_items.mark_paid', 'Marcar vencimento como pago');
  static const dueItemsDelete = Permission('due_items.delete', 'Excluir vencimento');

  // Ações - Tickets
  static const requestsCreate = Permission('requests.create', 'Criar ticket');
  static const requestsComment = Permission('requests.comment', 'Comentar em ticket');
  static const requestsAssign = Permission('requests.assign', 'Atribuir ticket');
  static const requestsTransition = Permission('requests.transition', 'Alterar status de ticket');

  // Ações - Exportação
  static const exportsCreate = Permission('exports.create', 'Criar exportação');

  // Ações - Assinatura
  static const subscriptionManage = Permission('subscription.manage', 'Gerenciar assinatura');

  // Ações - Configurações
  static const settingsManage = Permission('settings.manage', 'Gerenciar configurações');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Permission && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Catálogo de permissões por papel
class PermissionsCatalog {
  /// Mapeia papel para lista de permissões
  static Set<Permission> getPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return _ownerPermissions;
      case UserRole.admin:
        return _adminPermissions;
      case UserRole.user:
        return _userPermissions;
    }
  }

  /// Permissões do Owner (todas)
  static final _ownerPermissions = {
    // Todas as visões
    Permission.viewAccounts,
    Permission.viewTransactions,
    Permission.viewCategories,
    Permission.viewDueItems,
    Permission.viewDocuments,
    Permission.viewRequests,
    Permission.viewNotifications,
    Permission.viewReports,
    Permission.viewReportsPl,
    Permission.viewDashboard,
    Permission.viewSubscription,
    Permission.viewSettings,
    Permission.viewExports,
    Permission.viewProfile,
    // Todas as ações
    Permission.transactionsCreate,
    Permission.transactionsEdit,
    Permission.transactionsDelete,
    Permission.categoriesCreate,
    Permission.categoriesEdit,
    Permission.categoriesDelete,
    Permission.documentsUpload,
    Permission.documentsDelete,
    Permission.dueItemsCreate,
    Permission.dueItemsMarkPaid,
    Permission.dueItemsDelete,
    Permission.requestsCreate,
    Permission.requestsComment,
    Permission.requestsAssign,
    Permission.requestsTransition,
    Permission.exportsCreate,
    Permission.subscriptionManage,
    Permission.settingsManage,
  };

  /// Permissões do Admin (todas view + ações exceto subscription.manage)
  static final _adminPermissions = {
    // Todas as visões
    Permission.viewAccounts,
    Permission.viewTransactions,
    Permission.viewCategories,
    Permission.viewDueItems,
    Permission.viewDocuments,
    Permission.viewRequests,
    Permission.viewNotifications,
    Permission.viewReports,
    Permission.viewReportsPl,
    Permission.viewDashboard,
    Permission.viewSubscription,
    Permission.viewSettings,
    Permission.viewExports,
    Permission.viewProfile,
    // Todas as ações exceto subscription.manage e settings.manage
    Permission.transactionsCreate,
    Permission.transactionsEdit,
    Permission.transactionsDelete,
    Permission.categoriesCreate,
    Permission.categoriesEdit,
    Permission.categoriesDelete,
    Permission.documentsUpload,
    Permission.documentsDelete,
    Permission.dueItemsCreate,
    Permission.dueItemsMarkPaid,
    Permission.dueItemsDelete,
    Permission.requestsCreate,
    Permission.requestsComment,
    Permission.requestsAssign,
    Permission.requestsTransition,
    Permission.exportsCreate,
    // Não tem: subscription.manage, settings.manage
  };

  /// Permissões do User (somente view + requests.comment)
  static final _userPermissions = {
    // Todas as visões
    Permission.viewAccounts,
    Permission.viewTransactions,
    Permission.viewCategories,
    Permission.viewDueItems,
    Permission.viewDocuments,
    Permission.viewRequests,
    Permission.viewNotifications,
    Permission.viewReports,
    Permission.viewReportsPl,
    Permission.viewDashboard,
    Permission.viewProfile,
    // Não tem: viewSubscription, viewSettings, viewExports
    // Apenas comentar em tickets
    Permission.requestsComment,
    // Não tem: nenhuma outra ação
  };

  /// Verifica se um papel tem uma permissão específica
  static bool hasPermission(UserRole role, Permission permission) {
    return getPermissionsForRole(role).contains(permission);
  }

  /// Verifica se um papel tem qualquer uma das permissões
  static bool hasAnyPermission(UserRole role, Set<Permission> permissions) {
    final rolePermissions = getPermissionsForRole(role);
    return permissions.any((p) => rolePermissions.contains(p));
  }

  /// Verifica se um papel tem todas as permissões
  static bool hasAllPermissions(UserRole role, Set<Permission> permissions) {
    final rolePermissions = getPermissionsForRole(role);
    return permissions.every((p) => rolePermissions.contains(p));
  }
}

