import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../widgets/toast_service.dart';
import 'permission_helper.dart';
import 'permissions_catalog.dart';

/// Widget que oculta seu filho se o usuário não tiver permissão
class PermissionGuard extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;
  final bool hideOnDenied; // Se true, oculta; se false, apenas desabilita

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.hideOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hasPermission = PermissionHelper.hasPermission(authState, permission);

    if (hasPermission) {
      return child;
    }

    if (hideOnDenied) {
      PermissionHelper.logHidden(authState, 'permission_guard', permission);
      return fallback ?? const SizedBox.shrink();
    }

    // Se não deve ocultar, desabilita o widget
    return Opacity(
      opacity: 0.5,
      child: IgnorePointer(
        child: child,
      ),
    );
  }
}

/// Botão que verifica permissão antes de executar ação
class PermissionButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool hideOnDenied; // Se true, oculta; se false, desabilita com tooltip

  const PermissionButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.style,
    this.hideOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hasPermission = PermissionHelper.hasPermission(authState, permission);

    if (hasPermission) {
      return ElevatedButton(
        style: style,
        onPressed: onPressed,
        child: child,
      );
    }

    if (hideOnDenied) {
      PermissionHelper.logActionHidden(authState, 'permission_button', permission);
      return const SizedBox.shrink();
    }

    // Desabilitado com tooltip
    PermissionHelper.logActionDisabled(authState, 'permission_button', permission);
    return Tooltip(
      message: PermissionHelper.getDeniedMessage(permission),
      waitDuration: const Duration(milliseconds: 500),
      child: ElevatedButton(
        style: style,
        onPressed: null, // Desabilitado
        child: child,
      ),
    );
  }
}

/// FilledButton com verificação de permissão
class PermissionFilledButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool hideOnDenied;

  const PermissionFilledButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.style,
    this.hideOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hasPermission = PermissionHelper.hasPermission(authState, permission);

    if (hasPermission) {
      return FilledButton(
        style: style,
        onPressed: onPressed,
        child: child,
      );
    }

    if (hideOnDenied) {
      PermissionHelper.logActionHidden(authState, 'permission_filled_button', permission);
      return const SizedBox.shrink();
    }

    PermissionHelper.logActionDisabled(authState, 'permission_filled_button', permission);
    return Tooltip(
      message: PermissionHelper.getDeniedMessage(permission),
      waitDuration: const Duration(milliseconds: 500),
      child: FilledButton(
        style: style,
        onPressed: null,
        child: child,
      ),
    );
  }
}

/// IconButton com verificação de permissão
class PermissionIconButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool hideOnDenied;

  const PermissionIconButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.hideOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hasPermission = PermissionHelper.hasPermission(authState, permission);

    if (hasPermission) {
      return IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }

    if (hideOnDenied) {
      PermissionHelper.logActionHidden(authState, 'permission_icon_button', permission);
      return const SizedBox.shrink();
    }

    PermissionHelper.logActionDisabled(authState, 'permission_icon_button', permission);
    return Tooltip(
      message: tooltip ?? PermissionHelper.getDeniedMessage(permission),
      waitDuration: const Duration(milliseconds: 500),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip ?? PermissionHelper.getDeniedMessage(permission),
        onPressed: null,
      ),
    );
  }
}

/// OutlinedButton com verificação de permissão
class PermissionOutlinedButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool hideOnDenied;

  const PermissionOutlinedButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.style,
    this.hideOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hasPermission = PermissionHelper.hasPermission(authState, permission);

    if (hasPermission) {
      return OutlinedButton(
        style: style,
        onPressed: onPressed,
        child: child,
      );
    }

    if (hideOnDenied) {
      PermissionHelper.logActionHidden(authState, 'permission_outlined_button', permission);
      return const SizedBox.shrink();
    }

    PermissionHelper.logActionDisabled(authState, 'permission_outlined_button', permission);
    return Tooltip(
      message: PermissionHelper.getDeniedMessage(permission),
      waitDuration: const Duration(milliseconds: 500),
      child: OutlinedButton(
        style: style,
        onPressed: null,
        child: child,
      ),
    );
  }
}

