import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/menu_catalog.dart';
import '../storage/storage_service.dart';

/// Estado de autenticação com controle de papel (RBAC)
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? organizationId;
  final UserRole role;
  final String? organizationName;
  final String? userName;
  final String? name;
  final String? email;

  const AuthState({
    required this.isAuthenticated,
    this.userId,
    this.organizationId,
    this.role = UserRole.owner,
    this.organizationName,
    this.userName,
    this.name,
    this.email,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? organizationId,
    UserRole? role,
    String? organizationName,
    String? userName,
    String? name,
    String? email,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      role: role ?? this.role,
      organizationName: organizationName ?? this.organizationName,
      userName: userName ?? this.userName,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  /// Lista de itens de menu permitidos para o papel atual
  List<MenuItem> get allowedMenuItems => MenuCatalog.getItemsForRole(role);

  /// Verifica se uma rota é permitida
  bool isRouteAllowed(String route) {
    return MenuCatalog.isRouteAllowed(route, role);
  }
}

/// Provider de autenticação (mock - sem integração com backend ainda)
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isAuthenticated: false));

  /// Login (mockado por enquanto - depois integrar com API)
  /// Recebe dados já do login real, apenas atualiza o estado
  Future<void> login({
    required String email,
    required String password,
    String? userId,
    String? organizationId,
    String? organizationName,
    UserRole? role,
    String? name,
  }) async {
    // Determinar papel baseado no email se não fornecido (temporário para testes)
    UserRole userRole = role ?? UserRole.owner;
    if (email.contains('admin') || email.contains('@symplus.dev')) {
      userRole = UserRole.owner;
    } else if (email.contains('team')) {
      userRole = UserRole.admin;
    } else if (email.contains('user')) {
      userRole = UserRole.user;
    }

    state = AuthState(
      isAuthenticated: true,
      userId: userId ?? '1',
      organizationId: organizationId ?? '1',
      role: userRole,
      organizationName: organizationName ?? 'Symplus Dev',
      userName: email.split('@').first,
      name: name,
      email: email,
    );

    if (userId != null) {
      await StorageService.saveUserId(userId);
    }
    if (organizationId != null) {
      await StorageService.saveOrganizationId(organizationId);
    }
  }

  /// Logout
  Future<void> logout() async {
    await StorageService.clearAll();
    state = const AuthState(isAuthenticated: false);
  }

  /// Carregar estado salvo
  Future<void> loadSavedState() async {
    final token = await StorageService.getToken();
    final userId = await StorageService.getUserId();
    final orgId = await StorageService.getOrganizationId();

    if (token != null && userId != null && orgId != null) {
      // Por enquanto, assume Owner. Depois virá da API
      state = AuthState(
        isAuthenticated: true,
        userId: userId,
        organizationId: orgId,
        role: UserRole.owner, // TODO: Buscar da API
        organizationName: 'Symplus Dev',
        userName: 'User',
      );
    }
  }

  /// Trocar papel (apenas para testes de desenvolvimento)
  void switchRole(UserRole newRole) {
    if (state.isAuthenticated) {
      state = state.copyWith(role: newRole);
    }
  }
}

/// Provider para acesso ao estado de autenticação
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

