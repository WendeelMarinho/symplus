import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

/// Estado do avatar/logo do usuário
class AvatarState {
  final String? avatarUrl; // URL da foto/logo
  final bool isLoading;

  const AvatarState({
    this.avatarUrl,
    this.isLoading = false,
  });

  AvatarState copyWith({
    String? Function()? avatarUrl,
    bool? isLoading,
    bool clearAvatarUrl = false,
  }) {
    return AvatarState(
      avatarUrl: clearAvatarUrl 
          ? null 
          : (avatarUrl != null ? avatarUrl() : this.avatarUrl),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider do avatar/logo
class AvatarNotifier extends StateNotifier<AvatarState> {
  static const String _storageKeyUser = 'user_avatar_url';
  static const String _storageKeyCompany = 'company_logo_url';
  final Ref _ref;

  AvatarNotifier(this._ref) : super(const AvatarState()) {
    _loadAvatar();
    // Observar mudanças no auth para recarregar avatar quando necessário
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && (!previous.isAuthenticated || 
          previous.organizationId != next.organizationId)) {
        _loadAvatar();
      }
    });
  }

  /// Carrega o avatar salvo do storage
  Future<void> _loadAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authState = _ref.read(authProvider);
      
      // Determinar se é empresa ou PF
      final isCompany = authState.organizationName != null && 
                        authState.organizationName!.isNotEmpty;
      
      final storageKey = isCompany ? _storageKeyCompany : _storageKeyUser;
      final avatarUrl = prefs.getString(storageKey);
      
      if (avatarUrl != null) {
        state = AvatarState(avatarUrl: avatarUrl);
      }
    } catch (e) {
      // Se houver erro, manter estado vazio
    }
  }

  /// Define o avatar/logo
  Future<void> setAvatar(String? avatarUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authState = _ref.read(authProvider);
      
      // Determinar se é empresa ou PF
      final isCompany = authState.organizationName != null && 
                        authState.organizationName!.isNotEmpty;
      
      final storageKey = isCompany ? _storageKeyCompany : _storageKeyUser;
      
      if (avatarUrl != null) {
        await prefs.setString(storageKey, avatarUrl);
      } else {
        await prefs.remove(storageKey);
      }
      
      state = state.copyWith(avatarUrl: () => avatarUrl, isLoading: false);
    } catch (e) {
      // Se houver erro ao salvar, ainda atualiza o estado
      state = state.copyWith(avatarUrl: () => avatarUrl, isLoading: false);
    }
  }

  /// Define o estado de loading
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Limpa o avatar/logo
  Future<void> clearAvatar() async {
    await setAvatar(null);
  }

  /// Recarrega o avatar (útil após mudanças)
  Future<void> reload() async {
    await _loadAvatar();
  }
}

/// Provider global do avatar
final avatarProvider =
    StateNotifierProvider<AvatarNotifier, AvatarState>((ref) {
  return AvatarNotifier(ref);
});

