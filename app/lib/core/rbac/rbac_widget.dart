import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../widgets/toast_service.dart';
import 'rbac_helper.dart';

/// Widget que oculta seu filho se o usuário não tiver permissão
class RbacGuard extends ConsumerWidget {
  final String action;
  final Widget child;
  final Widget? fallback;

  const RbacGuard({
    super.key,
    required this.action,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final canExecute = RbacHelper.canExecuteAction(authState, action);

    if (canExecute) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Botão que verifica permissão antes de executar ação
class RbacButton extends ConsumerWidget {
  final String action;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showToastOnDenied;

  const RbacButton({
    super.key,
    required this.action,
    required this.onPressed,
    required this.child,
    this.style,
    this.showToastOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final canExecute = RbacHelper.canExecuteAction(authState, action);

    return ElevatedButton(
      style: style,
      onPressed: canExecute
          ? onPressed
          : showToastOnDenied
              ? () {
                  ToastService.showWarning(
                    context,
                    RbacHelper.getDeniedMessage(action),
                  );
                }
              : null,
      child: child,
    );
  }
}

/// Ícone de ação que verifica permissão
class RbacIconButton extends ConsumerWidget {
  final String action;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool showToastOnDenied;

  const RbacIconButton({
    super.key,
    required this.action,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.showToastOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final canExecute = RbacHelper.canExecuteAction(authState, action);

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: canExecute
          ? onPressed
          : showToastOnDenied
              ? () {
                  ToastService.showWarning(
                    context,
                    RbacHelper.getDeniedMessage(action),
                  );
                }
              : null,
    );
  }
}

/// FilledButton com verificação RBAC
class RbacFilledButton extends ConsumerWidget {
  final String action;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showToastOnDenied;

  const RbacFilledButton({
    super.key,
    required this.action,
    required this.onPressed,
    required this.child,
    this.style,
    this.showToastOnDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final canExecute = RbacHelper.canExecuteAction(authState, action);

    return FilledButton(
      style: style,
      onPressed: canExecute
          ? onPressed
          : showToastOnDenied
              ? () {
                  ToastService.showWarning(
                    context,
                    RbacHelper.getDeniedMessage(action),
                  );
                }
              : null,
      child: child,
    );
  }
}

