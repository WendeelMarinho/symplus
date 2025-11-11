import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../navigation/menu_catalog.dart';
import '../widgets/info_dialog.dart';

/// Ferramentas de desenvolvimento para facilitar testes de QA
/// 
/// Apenas disponível em modo debug
class DevTools {
  /// Mostra um dialog para trocar o papel do usuário (apenas para testes)
  static Future<void> showRoleSwitcher(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    
    if (!authState.isAuthenticated) {
      await InfoDialog.show(
        context,
        title: 'Erro',
        message: 'Você precisa estar autenticado para trocar de papel.',
      );
      return;
    }

    final newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trocar Papel (Dev Mode)'),
        content: const Text('Selecione o papel para testar RBAC:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(UserRole.owner),
            child: const Text('Owner'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(UserRole.admin),
            child: const Text('Admin'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(UserRole.user),
            child: const Text('User'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (newRole != null) {
      ref.read(authProvider.notifier).switchRole(newRole);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Papel alterado para: ${newRole.name.toUpperCase()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Mostra informações de debug
  static Future<void> showDebugInfo(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final screenSize = MediaQuery.of(context).size;
    final menuItems = authState.allowedMenuItems;

    await InfoDialog.show(
      context,
      title: 'Informações de Debug',
      icon: Icons.bug_report,
      message: '''
Autenticado: ${authState.isAuthenticated}
Papel: ${authState.role.name.toUpperCase()}
Organização: ${authState.organizationName ?? 'N/A'}
Usuário: ${authState.userName ?? 'N/A'}

Tela: ${screenSize.width.toInt()}x${screenSize.height.toInt()}px
Tipo: ${_getScreenType(screenSize.width)}

Itens no menu: ${menuItems.length}
Itens permitidos:
${menuItems.map((e) => '  • ${e.label}').join('\n')}
''',
    );
  }

  static String _getScreenType(double width) {
    if (width < 600) return 'Mobile';
    if (width < 1000) return 'Tablet';
    return 'Desktop';
  }
}

/// Widget que adiciona botões de dev tools no AppBar (apenas em debug)
class DevToolsButton extends ConsumerWidget {
  const DevToolsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Só mostrar em modo debug
    const isDebug = bool.fromEnvironment('dart.vm.product') == false;
    if (!isDebug) return const SizedBox.shrink();

    return PopupMenuButton(
      icon: const Icon(Icons.developer_mode),
      tooltip: 'Ferramentas de Desenvolvimento',
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.swap_horiz, size: 20),
              SizedBox(width: 8),
              Text('Trocar Papel'),
            ],
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              DevTools.showRoleSwitcher(context, ref);
            });
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.bug_report, size: 20),
              SizedBox(width: 8),
              Text('Info de Debug'),
            ],
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              DevTools.showDebugInfo(context, ref);
            });
          },
        ),
      ],
    );
  }
}

