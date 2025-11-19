import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../auth/auth_provider.dart';
import '../providers/avatar_provider.dart';

import 'file_image_helper.dart';

/// Widget reutilizável para exibir avatar/logo do usuário
/// 
/// Diferenciado por tipo:
/// - PF (Pessoa Física): foto do usuário
/// - Empresa: logo da empresa
class UserAvatar extends ConsumerWidget {
  final double radius;
  final bool showEditButton;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  const UserAvatar({
    super.key,
    this.radius = 24,
    this.showEditButton = false,
    this.onTap,
    this.onEditTap,
  });

  /// Determina se é empresa ou PF
  bool _isCompany(AuthState authState) {
    return authState.organizationName != null && 
           authState.organizationName!.isNotEmpty;
  }

  /// Obtém a inicial para exibir quando não há avatar
  String _getInitial(AuthState authState, bool isCompany) {
    if (isCompany) {
      // Para empresa, usar primeira letra do nome da organização
      final orgName = authState.organizationName ?? '';
      if (orgName.isNotEmpty) {
        return orgName[0].toUpperCase();
      }
      return 'C'; // Company
    } else {
      // Para PF, usar primeira letra do nome do usuário
      final name = authState.name ?? authState.userName ?? '';
      if (name.isNotEmpty) {
        return name[0].toUpperCase();
      }
      return 'U'; // User
    }
  }

  /// Obtém o ícone padrão quando não há avatar
  IconData _getDefaultIcon(bool isCompany) {
    return isCompany ? Icons.business : Icons.person;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final avatarState = ref.watch(avatarProvider);
    final isCompany = _isCompany(authState);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: avatarState.avatarUrl != null
                ? _getImageProvider(avatarState.avatarUrl!)
                : null,
            child: avatarState.avatarUrl == null
                ? Text(
                    _getInitial(authState, isCompany),
                    style: TextStyle(
                      fontSize: radius * 0.6,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          if (showEditButton && onEditTap != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  onPressed: onEditTap,
                  tooltip: isCompany ? 'Alterar logo' : 'Alterar foto',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: radius * 0.6,
                    minHeight: radius * 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Obtém o ImageProvider apropriado baseado na URL
  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    } else if (kIsWeb) {
      // Na web, tentar como NetworkImage se for um caminho relativo
      if (url.startsWith('/')) {
        return NetworkImage(url);
      }
      // Se não começar com /, assumir que é um caminho de arquivo local
      // Na web, isso pode não funcionar, então retornar NetworkImage
      return NetworkImage(url);
    } else {
      // Usar helper que funciona em web e mobile
      return FileImageHelper.createImageProvider(url);
    }
  }
}

/// Widget de avatar com loading state
class UserAvatarWithLoading extends ConsumerWidget {
  final double radius;
  final bool isLoading;

  const UserAvatarWithLoading({
    super.key,
    this.radius = 24,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        UserAvatar(radius: radius),
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: radius * 0.6,
                  height: radius * 0.6,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

