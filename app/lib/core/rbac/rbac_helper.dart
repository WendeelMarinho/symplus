import '../auth/auth_provider.dart';

/// Helper para verificações de permissão RBAC
class RbacHelper {
  /// Verifica se o usuário pode executar uma ação específica
  static bool canExecuteAction(AuthState authState, String action) {
    final role = authState.role;

    switch (action) {
      // Criar/Editar/Excluir recursos
      case 'create_account':
      case 'edit_account':
      case 'delete_account':
      case 'create_category':
      case 'edit_category':
      case 'delete_category':
      case 'create_due_item':
      case 'edit_due_item':
      case 'delete_due_item':
      case 'upload_document':
      case 'delete_document':
      case 'create_ticket':
      case 'edit_ticket':
      case 'delete_ticket':
      case 'change_ticket_status':
        return role == 'owner' || role == 'admin';

      // Ações de transação
      case 'create_transaction':
      case 'edit_transaction':
      case 'delete_transaction':
        return role == 'owner' || role == 'admin';

      // Visualizar (todos podem)
      case 'view_accounts':
      case 'view_transactions':
      case 'view_categories':
      case 'view_due_items':
      case 'view_documents':
      case 'view_tickets':
      case 'view_notifications':
      case 'view_reports':
      case 'view_profile':
        return true;

      // Configurações apenas Owner
      case 'view_settings':
      case 'edit_settings':
        return role == 'owner';

      // Assinatura Owner/Admin
      case 'view_subscription':
      case 'manage_subscription':
        return role == 'owner' || role == 'admin';

      default:
        return false;
    }
  }

  /// Retorna mensagem de erro para ação negada
  static String getDeniedMessage(String action) {
    switch (action) {
      case 'create_account':
      case 'edit_account':
      case 'delete_account':
        return 'Apenas Owner e Admin podem gerenciar contas';
      case 'create_category':
      case 'edit_category':
      case 'delete_category':
        return 'Apenas Owner e Admin podem gerenciar categorias';
      case 'create_transaction':
      case 'edit_transaction':
      case 'delete_transaction':
        return 'Apenas Owner e Admin podem gerenciar transações';
      case 'create_due_item':
      case 'edit_due_item':
      case 'delete_due_item':
        return 'Apenas Owner e Admin podem gerenciar vencimentos';
      case 'upload_document':
      case 'delete_document':
        return 'Apenas Owner e Admin podem gerenciar documentos';
      case 'create_ticket':
      case 'edit_ticket':
      case 'delete_ticket':
      case 'change_ticket_status':
        return 'Apenas Owner e Admin podem gerenciar tickets';
      case 'view_settings':
      case 'edit_settings':
        return 'Apenas Owner pode acessar configurações';
      case 'view_subscription':
      case 'manage_subscription':
        return 'Apenas Owner e Admin podem acessar assinatura';
      default:
        return 'Acesso negado. Você não tem permissão para esta ação.';
    }
  }

  /// Verifica se pode editar (Owner/Admin)
  static bool canEdit(AuthState authState) {
    return authState.role == 'owner' || authState.role == 'admin';
  }

  /// Verifica se é Owner
  static bool isOwner(AuthState authState) {
    return authState.role == 'owner';
  }

  /// Verifica se é Admin ou Owner
  static bool isAdminOrOwner(AuthState authState) {
    return authState.role == 'owner' || authState.role == 'admin';
  }
}

