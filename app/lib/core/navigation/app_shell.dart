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
import '../design/app_colors.dart';
import '../design/app_typography.dart';
import '../design/app_spacing.dart';
import '../design/app_borders.dart';
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
      backgroundColor: AppColors.scaffoldBackground,
      body: Row(
        children: [
          // Sidebar moderna e clean
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex >= menuItems.length ? 0 : _selectedIndex,
              onDestinationSelected: (index) => _onItemSelected(index, context),
              labelType: NavigationRailLabelType.none, // Apenas ícones
              extended: false,
              backgroundColor: Colors.transparent,
              elevation: null,
              selectedIconTheme: IconThemeData(
                color: AppColors.primary,
                size: 24,
              ),
              unselectedIconTheme: IconThemeData(
                color: AppColors.textSecondary,
                size: 24,
              ),
              selectedLabelTextStyle: AppTypography.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
              destinations: menuItems.map((item) {
                final isSelected = menuItems.indexOf(item) == _selectedIndex;
                return NavigationRailDestination(
                  icon: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                    ),
                    child: Icon(
                      item.icon,
                      semanticLabel: item.label,
                      size: 22,
                    ),
                  ),
                  selectedIcon: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                    ),
                    child: Icon(
                      item.icon,
                      color: AppColors.primary,
                      semanticLabel: '${item.label} (selecionado)',
                      size: 22,
                    ),
                  ),
                  label: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      item.label,
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
              backgroundColor: AppColors.surface,
              child: ListView(
                children: [
                  // Header do drawer moderno
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.secondary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Consumer(
                          builder: (context, ref, child) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          style: AppTypography.sectionTitle.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          authState.userName ?? 'Usuário',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                          ),
                          child: Text(
                            _getRoleLabel(authState.role),
                            style: AppTypography.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Itens do menu
                  ...otherItems.map((item) {
                    final isSelected = item.route == widget.currentRoute;
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      title: Text(
                        item.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.route);
                      },
                    );
                  }),
                  const Divider(height: 1),
                  // Logout
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.error,
                    ),
                    title: Text(
                      'Sair',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: bottomNavIndex >= 0 ? bottomNavIndex : 0,
          onTap: (index) {
            if (index < bottomNavItems.length) {
              _onItemSelected(menuItems.indexOf(bottomNavItems[index]), context);
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTypography.label.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.label,
          items: bottomNavItems.map((item) {
            final isSelected = bottomNavItems.indexOf(item) == bottomNavIndex;
            return BottomNavigationBarItem(
              icon: Icon(
                item.icon,
                semanticLabel: item.label,
                size: 24,
              ),
              activeIcon: Icon(
                item.icon,
                color: AppColors.primary,
                semanticLabel: '${item.label} (selecionado)',
                size: 24,
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
      floatingActionButton: _buildFAB(context, authState),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// AppBar moderno: Breadcrumb + Título | Ações à direita
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthState authState,
    List<MenuItem> menuItems,
    MenuItem? currentItem, {
    required bool isWide,
  }) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Breadcrumb (se houver contexto)
          if (isWide && currentItem != null) ...[
            Text(
              'Symplus',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentItem?.label ?? 'Symplus Finance',
                  style: AppTypography.display.copyWith(
                    fontSize: isWide ? 24 : 20,
                  ),
                ),
                if (isWide && authState.organizationName != null) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    authState.organizationName!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Seletor rápido de seções
        _buildQuickSwitch(context, menuItems, currentItem),
        
        // Dev Tools (apenas em debug mode)
        const DevToolsButton(),
        
        // Avatar do usuário/empresa
        Consumer(
          builder: (context, ref, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: UserAvatar(
                radius: isWide ? 24 : 20,
                onTap: () => context.go('/app/profile'),
              ),
            );
          },
        ),
        
        // Info da organização (desktop)
        if (isWide && authState.organizationName != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Tooltip(
              message: 'Organização atual',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      authState.organizationName!,
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Papel (desktop)
        if (isWide)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Tooltip(
              message: 'Papel do usuário',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRoleLabel(authState.role),
                  style: AppTypography.label.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        
        // Botão de logout
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Sair',
            color: AppColors.textSecondary,
          ),
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

  /// FAB central moderno com action sheet
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

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddActionSheet(context, authState),
          borderRadius: BorderRadius.circular(32),
          child: const Icon(
            Icons.add,
            color: AppColors.onBackground,
            size: 28,
          ),
        ),
      ),
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorders.cardRadius)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Adicionar',
                style: AppTypography.sectionTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (canCreateTransaction)
              _buildActionSheetItem(
                context,
                icon: Icons.swap_horiz,
                label: 'Transação',
                color: AppColors.income,
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_transaction_clicked', metadata: {'source': 'fab'});
                  context.go('/app/transactions?action=create');
                },
              ),
            if (canCreateAccount)
              _buildActionSheetItem(
                context,
                icon: Icons.account_balance_wallet,
                label: 'Conta',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_account_clicked', metadata: {'source': 'fab'});
                  context.go('/app/accounts?action=create');
                },
              ),
            if (canCreateCategory)
              _buildActionSheetItem(
                context,
                icon: Icons.category,
                label: 'Categoria',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_category_clicked', metadata: {'source': 'fab'});
                  context.go('/app/categories?action=create');
                },
              ),
            if (canUploadDocument)
              _buildActionSheetItem(
                context,
                icon: Icons.folder,
                label: 'Documento',
                color: AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_document_clicked', metadata: {'source': 'fab'});
                  context.go('/app/documents?action=upload');
                },
              ),
            if (canCreateRequest)
              _buildActionSheetItem(
                context,
                icon: Icons.support_agent,
                label: 'Solicitação',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  TelemetryService.logAction('ui_add_request_clicked', metadata: {'source': 'fab'});
                  context.go('/app/requests?action=create');
                },
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Item do action sheet moderno
  Widget _buildActionSheetItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTypography.bodyLarge,
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
