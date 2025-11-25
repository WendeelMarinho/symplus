import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../navigation/menu_catalog.dart';
import '../storage/storage_service.dart';
import '../network/dio_client.dart';
import '../../config/api_config.dart';

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

    // Salvar todos os dados de sessão
    if (userId != null) {
      await StorageService.saveUserId(userId);
    }
    if (organizationId != null) {
      await StorageService.saveOrganizationId(organizationId);
    }
    await StorageService.saveRole(userRole.name);
    await StorageService.saveEmail(email);
    if (name != null) {
      await StorageService.saveName(name);
    }
    if (organizationName != null) {
      await StorageService.saveOrganizationName(organizationName);
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
      // Tentar restaurar dados salvos
      final roleStr = await StorageService.getRole();
      final email = await StorageService.getEmail();
      final name = await StorageService.getName();
      final orgName = await StorageService.getOrganizationName();

      UserRole userRole = UserRole.owner;
      if (roleStr != null) {
        switch (roleStr) {
          case 'owner':
            userRole = UserRole.owner;
            break;
          case 'admin':
            userRole = UserRole.admin;
            break;
          case 'user':
            userRole = UserRole.user;
            break;
        }
      }

      // Restaurar estado básico
      state = AuthState(
        isAuthenticated: true,
        userId: userId,
        organizationId: orgId,
        role: userRole,
        organizationName: orgName ?? 'Symplus Dev',
        userName: email?.split('@').first ?? 'User',
        name: name,
        email: email,
      );

      // Tentar buscar dados atualizados da API para garantir que está tudo correto
      try {
        await _refreshUserData();
      } catch (e) {
        // Se falhar (ex: token inválido), manter dados salvos temporariamente
        // O DioClient vai tratar o 401 na próxima requisição
        // Se o erro for 401, o estado será limpo automaticamente
        if (e is DioException && e.response?.statusCode == 401) {
          // Token inválido, limpar estado
          await logout();
        }
      }
    }
  }

  /// Atualiza dados do usuário da API
  Future<void> _refreshUserData() async {
    try {
      final response = await DioClient.get(ApiConfig.me);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final user = data['user'] as Map<String, dynamic>;
        
        // Obter primeira organização
        final organizations = user['organizations'] as List<dynamic>?;
        if (organizations != null && organizations.isNotEmpty) {
          final org = organizations[0] as Map<String, dynamic>;
          final orgId = org['id'].toString();
          final orgRole = (org['role'] as String?) ?? 
                         (org['pivot']?['org_role'] as String?) ?? 
                         'user';
          
          UserRole userRole = UserRole.user;
          if (orgRole == 'owner') {
            userRole = UserRole.owner;
          } else if (orgRole == 'admin') {
            userRole = UserRole.admin;
          }

          // Atualizar estado com dados da API
          state = AuthState(
            isAuthenticated: true,
            userId: user['id'].toString(),
            organizationId: orgId,
            role: userRole,
            organizationName: org['name'] as String?,
            userName: user['email']?.toString().split('@').first,
            name: user['name'] as String?,
            email: user['email'] as String?,
          );

          // Atualizar storage com dados atualizados
          await StorageService.saveRole(userRole.name);
          await StorageService.saveEmail(user['email']?.toString() ?? '');
          if (user['name'] != null) {
            await StorageService.saveName(user['name'].toString());
          }
          if (org['name'] != null) {
            await StorageService.saveOrganizationName(org['name'].toString());
          }
        }
      }
    } catch (e) {
      // Se falhar, re-lançar para ser tratado no loadSavedState
      rethrow;
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

