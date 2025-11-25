import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../dev/dev_tools.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast_service.dart';
import '../widgets/user_avatar.dart';
import '../providers/avatar_provider.dart';
import '../rbac/permission_helper.dart';
import '../rbac/permissions_catalog.dart';
import '../accessibility/telemetry_service.dart';
import 'menu_catalog.dart';

/// Shell adaptativo que alterna entre NavigationRail/Drawer (desktop) e BottomNavigation (mobile)
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final authState = ref.read(authProvider);
    final menuItems = authState.allowedMenuItems;
    final index = menuItems.indexWhere((item) => item.route == widget.currentRoute);
    if (index != -1 && _selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemSelected(int index, BuildContext context) {
    final authState = ref.read(authProvider);
    final menuItems = authState.allowedMenuItems;
    if (index < menuItems.length) {
      setState(() {
        _selectedIndex = index;
      });
      context.go(menuItems[index].route);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Logout',
      message: 'Deseja realmente sair?',
      confirmLabel: 'Sair',
      cancelLabel: 'Cancelar',
      icon: Icons.logout,
    );

    if (confirmed && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        ToastService.showInfo(context, 'Logout realizado com sucesso');
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final menuItems = authState.allowedMenuItems;
    final currentItem = MenuCatalog.getItemByRoute(widget.currentRoute);
    final isWideScreen = MediaQuery.of(context).size.width >= 1000;

    if (isWideScreen) {
      return _buildDesktopLayout(context, authState, menuItems, currentItem, isWide: true);
    } else {
      return _buildMobileLayout(context, authState, menuItems, currentItem, isWide: false);
    }
  }

  /// Layout para desktop (NavigationRail + Drawer)
  Widget _buildDesktopLayout(
    BuildContext context,
    AuthState authState,
    List<MenuItem> menuItems,
    MenuItem? currentItem, {
    required bool isWide,
  }) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex >= menuItems.length ? 0 : _selectedIndex,
            onDestinationSelected: (index) => _onItemSelected(index, context),
            labelType: NavigationRailLabelType.all,
            extended: false,
            minExtendedWidth: 200,
            destinations: menuItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon, semanticLabel: item.label),
                selectedIcon: Icon(
                  item.icon,
                  color: Theme.of(context).colorScheme.primary,
                  semanticLabel: '${item.label} (selecionado)',
                ),
                label: Text(item.label),
              );
            }).toList(),
            // Removido trailing para evitar overflow - avatar e logout estão no AppBar
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(context, authState, menuItems, currentItem, isWide: true),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Layout para mobile (BottomNavigation + FAB central)
  Widget _buildMobileLayout(
    BuildContext context,
    AuthState authState,
    List<MenuItem> menuItems,
    MenuItem? currentItem, {
    required bool isWide,
  }) {
    // Limitar a 5 itens no bottom nav (mais do que isso fica ruim em mobile)
    final bottomNavItems = menuItems.take(5).toList();
    final otherItems = menuItems.skip(5).toList();
    final bottomNavIndex = bottomNavItems.indexWhere(
      (item) => item.route == widget.currentRoute,
    );

    return Scaffold(
      appBar: _buildAppBar(context, authState, menuItems, currentItem, isWide: false),
      drawer: otherItems.isEmpty
          ? null
          : Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Consumer(
                          builder: (context, ref, child) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: UserAvatar(
                                radius: 32,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.go('/app/profile');
                                },
                              ),
                            );
                          },
                        ),
                        Text(
                          authState.organizationName ?? 'Symplus',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState.userName ?? 'Usuário',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(authState.role.name.toUpperCase()),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                  ...otherItems.map((item) => ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.label),
                        selected: item.route == widget.currentRoute,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.route);
                        },
                      )),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleLogout(context);
                    },
                  ),
                ],
              ),
            ),
      body: SafeArea(
        bottom: false, // BottomNavigationBar já tem sua própria área segura
        child: widget.child,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: bottomNavIndex >= 0 ? bottomNavIndex : 0,
        onTap: (index) {
          if (index < bottomNavItems.length) {
            _onItemSelected(menuItems.indexOf(bottomNavItems[index]), context);
          }
        },
        items: bottomNavItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon, semanticLabel: item.label),
            activeIcon: Icon(
              item.icon,
              semanticLabel: '${item.label} (selecionado)',
            ),
            label: item.label,
          );
        }).toList(),
      ),
      floatingActionButton: _buildFAB(context, authState),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// AppBar contextual com Quick Switch
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthState authState,
    List<MenuItem> menuItems,
    MenuItem? currentItem, {
    required bool isWide,
  }) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentItem?.label ?? 'Symplus Finance'),
          if (!isWide && authState.organizationName != null)
            Text(
              authState.organizationName!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      actions: [
        // Seletor rápido de seções (sempre disponível)
        _buildQuickSwitch(context, menuItems, currentItem),
        
        // Dev Tools (apenas em debug mode)
        const DevToolsButton(),
        
        // Avatar do usuário/empresa
        Consumer(
          builder: (context, ref, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: UserAvatar(
                radius: 20,
                onTap: () => context.go('/app/profile'),
              ),
            );
          },
        ),
        
        // Info da organização (desktop)
        if (isWide)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Tooltip(
              message: 'Organização atual',
              child: Chip(
                avatar: const Icon(Icons.business, size: 18),
                label: Text(authState.organizationName ?? 'Org'),
              ),
            ),
          ),
        
        // Papel (desktop)
        if (isWide)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Tooltip(
              message: 'Papel do usuário',
              child: Chip(
                label: Text(_getRoleLabel(authState.role)),
              ),
            ),
          ),
        
        // Botão de logout
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _handleLogout(context),
          tooltip: 'Sair',
        ),
      ],
    );
  }

  /// Seletor rápido de seções (Quick Switch)
  Widget _buildQuickSwitch(
    BuildContext context,
    List<MenuItem> menuItems,
    MenuItem? currentItem,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    
    if (isWide) {
      // Desktop: Dropdown
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: PopupMenuButton<String>(
          tooltip: 'Navegar rapidamente',
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                currentItem?.icon ?? Icons.menu,
                size: 20,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          onSelected: (route) {
            context.go(route);
          },
          itemBuilder: (context) {
            return menuItems.map((item) {
              final isSelected = item.route == widget.currentRoute;
              return PopupMenuItem(
                value: item.route,
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      );
    } else {
      // Mobile: Menu no AppBar
      return IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Menu rápido',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildQuickSwitchSheet(context, menuItems, currentItem),
          );
        },
      );
    }
  }

  /// Bottom Sheet para Quick Switch no mobile
  Widget _buildQuickSwitchSheet(
    BuildContext context,
    List<MenuItem> menuItems,
    MenuItem? currentItem,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Navegação Rápida',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...menuItems.map((item) {
            final isSelected = item.route == widget.currentRoute;
            return ListTile(
              leading: Icon(
                item.icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                context.go(item.route);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'PROPRIETÁRIO';
      case UserRole.admin:
        return 'ADMINISTRADOR';
      case UserRole.user:
        return 'USUÁRIO';
    }
  }

  /// FAB central com action sheet
  Widget? _buildFAB(BuildContext context, AuthState authState) {
    // Verificar se há pelo menos uma ação permitida
    final canCreateTransaction = PermissionHelper.hasPermission(authState, Permission.transactionsCreate);
    final canCreateAccount = authState.role == UserRole.owner || authState.role == UserRole.admin;
    final canCreateCategory = PermissionHelper.hasPermission(authState, Permission.categoriesCreate);
    final canUploadDocument = PermissionHelper.hasPermission(authState, Permission.documentsUpload);
    final canCreateRequest = PermissionHelper.hasPermission(authState, Permission.requestsCreate);

    // Se não tem nenhuma permissão, não mostra o FAB
    if (!canCreateTransaction && !canCreateAccount && !canCreateCategory && !canUploadDocument && !canCreateRequest) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () => _showAddActionSheet(context, authState),
      tooltip: 'Adicionar',
      child: const Icon(Icons.add),
    );
  }

  /// Action sheet para adicionar itens
  void _showAddActionSheet(BuildContext context, AuthState authState) {
    final canCreateTransaction = PermissionHelper.hasPermission(authState, Permission.transactionsCreate);
    final canCreateAccount = authState.role == UserRole.owner || authState.role == UserRole.admin;
    final canCreateCategory = PermissionHelper.hasPermission(authState, Permission.categoriesCreate);
    final canUploadDocument = PermissionHelper.hasPermission(authState, Permission.documentsUpload);
    final canCreateRequest = PermissionHelper.hasPermission(authState, Permission.requestsCreate);

    TelemetryService.logAction('ui_quick_action_click', metadata: {'source': 'fab'});

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Adicionar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (canCreateTransaction)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.green),
                title: const Text('Transação'),
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_transaction_clicked', metadata: {'source': 'fab'});
                  context.go('/app/transactions?action=create');
                },
              ),
            if (canCreateAccount)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.indigo),
                title: const Text('Conta'),
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_account_clicked', metadata: {'source': 'fab'});
                  context.go('/app/accounts?action=create');
                },
              ),
            if (canCreateCategory)
              ListTile(
                leading: const Icon(Icons.category, color: Colors.purple),
                title: const Text('Categoria'),
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_category_clicked', metadata: {'source': 'fab'});
                  context.go('/app/categories?action=create');
                },
              ),
            if (canUploadDocument)
              ListTile(
                leading: const Icon(Icons.folder, color: Colors.blue),
                title: const Text('Documento'),
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_document_clicked', metadata: {'source': 'fab'});
                  context.go('/app/documents?action=upload');
                },
              ),
            if (canCreateRequest)
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.orange),
                title: const Text('Solicitação'),
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_request_clicked', metadata: {'source': 'fab'});
                  context.go('/app/requests?action=create');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
