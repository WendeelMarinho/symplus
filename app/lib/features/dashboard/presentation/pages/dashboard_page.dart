import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/action_bar.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/period_filter.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/rbac/rbac_helper.dart';
import '../../../../core/rbac/permission_helper.dart';
import '../../../../core/rbac/permissions_catalog.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../../core/providers/period_filter_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/services/dashboard_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/kpi_main_card.dart';
import '../widgets/quarterly_summary.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/due_items_calendar.dart';
import '../../../custom_indicators/presentation/widgets/custom_indicators_section.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../due_items/data/services/due_item_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DashboardData? _data;
  bool _isLoading = true;
  String? _error;
  final FocusNode _quickActionsFocusNode = FocusNode();
  bool _showQuickActionsMenu = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    _quickActionsFocusNode.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    // Atalhos serão tratados via KeyboardListener no build
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obter período atual do filtro
      final periodState = ref.read(periodFilterProvider);
      final dates = periodState.dates;

      // Buscar dados do dashboard com filtro de período
      final data = await DashboardService.getDashboard(
        from: dates.from.toIso8601String().split('T')[0],
        to: dates.to.toIso8601String().split('T')[0],
      );
      
      setState(() {
        _data = data;
        _isLoading = false;
      });
      TelemetryService.logAction('dashboard.loaded');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      TelemetryService.logError(e.toString(), context: 'dashboard.load');
    }
  }

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      try {
        return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
      } catch (e) {
        // Fallback se locale não estiver inicializado
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  Color _getAmountColor(double amount, String type) {
    if (type == 'income' || type == 'receive') {
      return Colors.green;
    }
    return Colors.red;
  }

  // Quick Actions
  void _openQuickActionsMenu() {
    setState(() {
      _showQuickActionsMenu = true;
    });
    TelemetryService.logAction('dashboard.quick_action.opened');
  }

  void _closeQuickActionsMenu() {
    setState(() {
      _showQuickActionsMenu = false;
    });
  }

  void _handleQuickAction(String action) {
    final authState = ref.read(authProvider);
    
    switch (action) {
      case 'transaction':
        if (PermissionHelper.hasPermission(authState, Permission.transactionsCreate)) {
          TelemetryService.logAction('dashboard.quick_action.clicked', metadata: {'action': 'transaction'});
          context.go('/app/transactions?action=create');
        } else {
          PermissionHelper.logAccessDenied(authState, Permission.transactionsCreate, context: 'dashboard.quick_action');
          ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.transactionsCreate));
          context.go('/app/dashboard?denied=1');
        }
        break;
      case 'category':
        if (PermissionHelper.hasPermission(authState, Permission.categoriesCreate)) {
          TelemetryService.logAction('dashboard.quick_action.clicked', metadata: {'action': 'category'});
          context.go('/app/categories?action=create');
        } else {
          PermissionHelper.logAccessDenied(authState, Permission.categoriesCreate, context: 'dashboard.quick_action');
          ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.categoriesCreate));
          context.go('/app/dashboard?denied=1');
        }
        break;
      case 'document':
        if (PermissionHelper.hasPermission(authState, Permission.documentsUpload)) {
          TelemetryService.logAction('dashboard.quick_action.clicked', metadata: {'action': 'document'});
          context.go('/app/documents?action=upload');
        } else {
          PermissionHelper.logAccessDenied(authState, Permission.documentsUpload, context: 'dashboard.quick_action');
          ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.documentsUpload));
          context.go('/app/dashboard?denied=1');
        }
        break;
      case 'due_item':
        if (PermissionHelper.hasPermission(authState, Permission.dueItemsCreate)) {
          TelemetryService.logAction('dashboard.quick_action.clicked', metadata: {'action': 'due_item'});
          context.go('/app/due-items?action=create');
        } else {
          PermissionHelper.logAccessDenied(authState, Permission.dueItemsCreate, context: 'dashboard.quick_action');
          ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.dueItemsCreate));
          context.go('/app/dashboard?denied=1');
        }
        break;
    }
    _closeQuickActionsMenu();
  }

  Future<void> _markDueItemAsPaid(int itemId) async {
    try {
      await DueItemService.markPaid(itemId);
      if (mounted) {
        ToastService.showSuccess(context, 'Item marcado como pago!');
        TelemetryService.logAction('dashboard.due_item.marked_paid', metadata: {'item_id': itemId.toString()});
        _loadDashboard();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao marcar como pago');
      }
    }
  }

  void _navigateToPlReport() {
    final authState = ref.read(authProvider);
    if (!PermissionHelper.hasPermission(authState, Permission.viewReportsPl)) {
      PermissionHelper.logAccessDenied(authState, Permission.viewReportsPl, context: 'dashboard.kpi.view_pl');
      ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.viewReportsPl));
      context.go('/app/dashboard?denied=1');
      return;
    }
    final from = DateTime.now().subtract(const Duration(days: 30));
    final to = DateTime.now();
    final uri = Uri.parse(
      '/app/reports/pl?from=${from.toIso8601String().split('T')[0]}&to=${to.toIso8601String().split('T')[0]}',
    );
    TelemetryService.logAction('dashboard.kpi.view_pl.clicked');
    context.go(uri.toString());
  }

  void _navigateToTransactionsMonth(String month) {
    final authState = ref.read(authProvider);
    if (!PermissionHelper.hasPermission(authState, Permission.viewTransactions)) {
      PermissionHelper.logAccessDenied(authState, Permission.viewTransactions, context: 'dashboard.chart.bar');
      ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.viewTransactions));
      context.go('/app/dashboard?denied=1');
      return;
    }
    final date = DateTime.parse('$month-01');
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    final uri = Uri.parse(
      '/app/transactions?from=${start.toIso8601String().split('T')[0]}&to=${end.toIso8601String().split('T')[0]}',
    );
    TelemetryService.logAction('dashboard.chart.bar.clicked', metadata: {'month': month});
    context.go(uri.toString());
  }

  void _navigateToTransactionsCategory(int categoryId) {
    final authState = ref.read(authProvider);
    if (!PermissionHelper.hasPermission(authState, Permission.viewTransactions)) {
      PermissionHelper.logAccessDenied(authState, Permission.viewTransactions, context: 'dashboard.chart.donut');
      ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.viewTransactions));
      context.go('/app/dashboard?denied=1');
      return;
    }
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 2, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final uri = Uri.parse(
      '/app/transactions?type=expense&categoryId=$categoryId&from=${start.toIso8601String().split('T')[0]}&to=${end.toIso8601String().split('T')[0]}',
    );
    TelemetryService.logAction('dashboard.chart.donut.clicked', metadata: {'category_id': categoryId.toString()});
    context.go(uri.toString());
  }

  void _navigateToDueItemsDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    final uri = Uri.parse('/app/due-items?date=$dateStr');
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currencyState = ref.watch(currencyProvider);
    final canCreateTransaction = PermissionHelper.hasPermission(authState, Permission.transactionsCreate);
    final canCreateCategory = PermissionHelper.hasPermission(authState, Permission.categoriesCreate);
    final canUploadDocument = PermissionHelper.hasPermission(authState, Permission.documentsUpload);
    final canCreateDueItem = PermissionHelper.hasPermission(authState, Permission.dueItemsCreate);
    final canMarkPaid = PermissionHelper.hasPermission(authState, Permission.dueItemsMarkPaid);
    final canViewTransactions = PermissionHelper.hasPermission(authState, Permission.viewTransactions);
    final canViewDueItems = PermissionHelper.hasPermission(authState, Permission.viewDueItems);
    final canViewDocuments = PermissionHelper.hasPermission(authState, Permission.viewDocuments);
    final canViewReports = PermissionHelper.hasPermission(authState, Permission.viewReportsPl);
    final isMobile = ResponsiveUtils.isMobile(context);

    return KeyboardListener(
      focusNode: _quickActionsFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Ctrl+N ou Cmd+N - Abrir menu de quick actions
          if ((event.logicalKey == LogicalKeyboardKey.keyN) &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            _openQuickActionsMenu();
          }
          // Teclas rápidas (sem Ctrl)
          else if (!_showQuickActionsMenu &&
              !HardwareKeyboard.instance.isControlPressed &&
              !HardwareKeyboard.instance.isMetaPressed) {
            final authState = ref.read(authProvider);
            switch (event.logicalKey) {
              case LogicalKeyboardKey.keyT:
                if (PermissionHelper.hasPermission(authState, Permission.transactionsCreate)) {
                  _handleQuickAction('transaction');
                } else {
                  PermissionHelper.logShortcutDenied(authState, 'T', Permission.transactionsCreate);
                  ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.transactionsCreate));
                }
                break;
              case LogicalKeyboardKey.keyC:
                if (PermissionHelper.hasPermission(authState, Permission.categoriesCreate)) {
                  _handleQuickAction('category');
                } else {
                  PermissionHelper.logShortcutDenied(authState, 'C', Permission.categoriesCreate);
                  ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.categoriesCreate));
                }
                break;
              case LogicalKeyboardKey.keyD:
                if (PermissionHelper.hasPermission(authState, Permission.documentsUpload)) {
                  _handleQuickAction('document');
                } else {
                  PermissionHelper.logShortcutDenied(authState, 'D', Permission.documentsUpload);
                  ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.documentsUpload));
                }
                break;
              case LogicalKeyboardKey.keyV:
                if (PermissionHelper.hasPermission(authState, Permission.dueItemsCreate)) {
                  _handleQuickAction('due_item');
                } else {
                  PermissionHelper.logShortcutDenied(authState, 'V', Permission.dueItemsCreate);
                  ToastService.showWarning(context, PermissionHelper.getDeniedMessage(Permission.dueItemsCreate));
                }
                break;
              case LogicalKeyboardKey.escape:
                _closeQuickActionsMenu();
                break;
            }
          }
        }
      },
      child: Focus(
        autofocus: true,
        child: _PeriodFilterListener(
          onPeriodChanged: () => _loadDashboard(),
          child: Column(
            children: [
              // Header com contexto (organização + período)
              _buildDashboardHeader(context, authState, isMobile),
            // Quick Actions na ActionBar
            ActionBar(
              actions: [
                if (canCreateTransaction)
                  ActionItem(
                    label: 'Nova Transação',
                    icon: Icons.add_circle_outline,
                    onPressed: () => _handleQuickAction('transaction'),
                    type: ActionType.primary,
                  ),
                if (canCreateCategory)
                  ActionItem(
                    label: 'Nova Categoria',
                    icon: Icons.category,
                    onPressed: () => _handleQuickAction('category'),
                    type: ActionType.secondary,
                  ),
                if (canUploadDocument)
                  ActionItem(
                    label: 'Upload Documento',
                    icon: Icons.upload,
                    onPressed: () => _handleQuickAction('document'),
                    type: ActionType.secondary,
                  ),
                if (canCreateDueItem)
                  ActionItem(
                    label: 'Novo Vencimento',
                    icon: Icons.event,
                    onPressed: () => _handleQuickAction('due_item'),
                    type: ActionType.secondary,
                  ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Erro ao carregar dashboard',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadDashboard,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : _data == null
                          ? const Center(child: Text('Nenhum dado disponível'))
                          : Stack(
                              children: [
                                RefreshIndicator(
                                  onRefresh: _loadDashboard,
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: ResponsiveUtils.getResponsivePadding(context),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ORDEM ESPECIFICADA:
                                        // 1. Filtro de Período (global - topo) - já está no PageHeader ✅
                                        
                                        // 2. 4 KPIs principais
                                        _buildKpiCards(),
                                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        
                                        // 3. Indicadores Personalizados
                                        const CustomIndicatorsSection(),
                                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        
                                        // 4. Resumo Trimestral
                                        const QuarterlySummary(),
                                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        
                                        // 5. Gráficos (Entrada/Saída por categoria)
                                        if (canViewTransactions || canViewReports) ...[
                                          _buildChartsSection(),
                                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        ],
                                        
                                        // 6. Calendário com transações
                                        if (canViewDueItems) ...[
                                          _buildDueItemsCalendar(),
                                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        ],
                                        
                                        // 7. Quick Actions (já está na ActionBar acima) ✅
                                        
                                        // Seções adicionais (opcionais, mantidas para contexto)
                                        // Badge de Overdue (alerta importante)
                                        if (_data!.overdueItems.isNotEmpty) ...[
                                          _buildOverdueBadge(),
                                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        ],
                                        // Transações Recentes (contexto adicional)
                                        if (canViewTransactions) ...[
                                          _buildRecentTransactions(),
                                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        ],
                                        // Próximos Vencimentos (contexto adicional)
                                        if (canViewDueItems && _data!.upcomingDueItems.isNotEmpty) ...[
                                          _buildUpcomingDueItems(canMarkPaid),
                                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                                        ],
                                        // Saldos das Contas (contexto adicional)
                                        _buildAccountBalances(),
                                      ],
                                    ),
                                  ),
                                ),
                                // Menu de Quick Actions (modal)
                                if (_showQuickActionsMenu) _buildQuickActionsMenu(context),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o header do dashboard com contexto da organização
  Widget _buildDashboardHeader(BuildContext context, AuthState authState, bool isMobile) {
    // Determinar nome a exibir (organização ou usuário)
    final displayName = authState.organizationName ?? authState.name ?? authState.userName ?? 'Usuário';
    final isCompany = authState.organizationName != null && authState.organizationName!.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Nome da organização/usuário + Avatar
          Row(
            children: [
              // Avatar
              Consumer(
                builder: (context, ref, child) {
                  return UserAvatar(
                    radius: isMobile ? 24 : 32,
                    onTap: () => context.go('/app/profile'),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Nome
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (authState.userName != null && isCompany)
                      Text(
                        authState.userName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Filtro de período
              const PeriodFilter(),
            ],
          ),
          const SizedBox(height: 12),
          // Linha 2: Título do dashboard
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('dashboard.title'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (context.t('dashboard.subtitle').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.t('dashboard.subtitle'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards() {
    final summary = _data!.financialSummary;
    final isMobile = ResponsiveUtils.isMobile(context);
    final periodState = ref.watch(periodFilterProvider);
    final dates = periodState.dates;
    
    // Calcular período anterior (mesma duração, mas antes)
    final periodDuration = dates.to.difference(dates.from).inDays;
    final previousFrom = dates.from.subtract(Duration(days: periodDuration + 1));
    final previousTo = dates.from.subtract(const Duration(days: 1));
    
    // Calcular valores do período anterior baseado em estimativa
    // TODO: Quando o backend fornecer dados do período anterior, usar valores reais
    // Por enquanto, usamos uma estimativa baseada no período atual
    final previousIncome = summary.income * 0.9;
    final previousExpense = summary.expenses * 1.1;
    final previousNet = summary.net * 0.8;
    
    // Calcular percentual (margem de lucro)
    final percentage = summary.income > 0 
        ? (summary.net / summary.income * 100) 
        : 0.0;
    final previousPercentage = previousIncome > 0 
        ? (previousNet / previousIncome * 100) 
        : 0.0;

    if (isMobile) {
      // Mobile: cards em lista vertical
      return Column(
        children: [
          KpiMainCard(
            type: KpiType.income,
            value: summary.income,
            previousValue: previousIncome,
          ),
          const SizedBox(height: 16),
          KpiMainCard(
            type: KpiType.expense,
            value: summary.expenses,
            previousValue: previousExpense,
          ),
          const SizedBox(height: 16),
          KpiMainCard(
            type: KpiType.net,
            value: summary.net,
            previousValue: previousNet,
          ),
          const SizedBox(height: 16),
          KpiMainCard(
            type: KpiType.percentage,
            value: percentage,
            previousValue: previousPercentage,
          ),
        ],
      );
    }

    // Desktop/Tablet: grid 2x2
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        KpiMainCard(
          type: KpiType.income,
          value: summary.income,
          previousValue: previousIncome,
        ),
        KpiMainCard(
          type: KpiType.expense,
          value: summary.expenses,
          previousValue: previousExpense,
        ),
        KpiMainCard(
          type: KpiType.net,
          value: summary.net,
          previousValue: previousNet,
        ),
        KpiMainCard(
          type: KpiType.percentage,
          value: percentage,
          previousValue: previousPercentage,
        ),
      ],
    );
  }

  Widget _buildPeriodSummary() {
    final summary = _data!.financialSummary;
    final fromDate = DateTime.parse(summary.period.from);
    final toDate = DateTime.parse(summary.period.to);
    final netProfit = summary.net;
    final profitMargin = summary.income > 0 ? (netProfit / summary.income * 100) : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Resumo do Período',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _navigateToPlReport,
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Ver P&L Completo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              () {
                try {
                  return '${DateFormat('dd/MM/yyyy', 'pt_BR').format(fromDate)} - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(toDate)}';
                } catch (e) {
                  return '${DateFormat('dd/MM/yyyy').format(fromDate)} - ${DateFormat('dd/MM/yyyy').format(toDate)}';
                }
              }(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Receitas',
                    summary.income,
                    Colors.green,
                    Icons.trending_up,
                    currencyState: currencyState,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Despesas',
                    summary.expenses,
                    Colors.red,
                    Icons.trending_down,
                    currencyState: currencyState,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Lucro Líquido',
                    netProfit,
                    netProfit >= 0 ? Colors.green : Colors.red,
                    Icons.account_balance,
                    currencyState: currencyState,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Margem',
                    profitMargin,
                    profitMargin >= 0 ? Colors.green : Colors.red,
                    Icons.percent,
                    isPercentage: true,
                    currencyState: currencyState,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double value, Color color, IconData icon, {bool isPercentage = false, required CurrencyState currencyState}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPercentage
                ? '${value.toStringAsFixed(1)}%'
                : _formatCurrency(value, currencyState),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final periodState = ref.watch(periodFilterProvider);

    if (isMobile) {
      return Column(
        children: [
          // Bar Chart - Receitas x Despesas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Receitas x Despesas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Tooltip(
                        message: 'Período: ${periodState.displayLabel}',
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: IncomeExpenseBarChart(
                      data: _data!.monthlyIncomeExpense,
                      onBarTap: _navigateToTransactionsMonth,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Donut Chart - Receitas por Categoria
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Receitas por Categoria',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Tooltip(
                        message: 'Período: ${periodState.displayLabel}',
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: TopCategoriesDonutChart(
                      categories: _data!.topCategories.income.take(5).toList(),
                      onSliceTap: (categoryId) {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month - 2, 1);
                        final end = DateTime(now.year, now.month + 1, 0);
                        final uri = Uri.parse(
                          '/app/transactions?type=income&categoryId=$categoryId&from=${start.toIso8601String().split('T')[0]}&to=${end.toIso8601String().split('T')[0]}',
                        );
                        TelemetryService.logAction('dashboard.chart.donut.income.clicked', metadata: {'category_id': categoryId.toString()});
                        context.go(uri.toString());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Donut Chart - Despesas por Categoria
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Despesas por Categoria',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Tooltip(
                        message: 'Período: ${periodState.displayLabel}',
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: TopCategoriesDonutChart(
                      categories: _data!.topCategories.expenses.take(5).toList(),
                      onSliceTap: _navigateToTransactionsCategory,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar Chart - Receitas x Despesas
        Expanded(
          flex: 2,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bar_chart,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Receitas x Despesas',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Tooltip(
                        message: 'Período: ${periodState.displayLabel}',
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: IncomeExpenseBarChart(
                      data: _data!.monthlyIncomeExpense,
                      onBarTap: _navigateToTransactionsMonth,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Donut Charts - Receitas e Despesas por Categoria
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Donut Chart - Receitas por Categoria
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pie_chart,
                              color: Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Receitas por Categoria',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TopCategoriesDonutChart(
                            categories: _data!.topCategories.income.take(5).toList(),
                            onSliceTap: (categoryId) {
                              final now = DateTime.now();
                              final start = DateTime(now.year, now.month - 2, 1);
                              final end = DateTime(now.year, now.month + 1, 0);
                              final uri = Uri.parse(
                                '/app/transactions?type=income&categoryId=$categoryId&from=${start.toIso8601String().split('T')[0]}&to=${end.toIso8601String().split('T')[0]}',
                              );
                              TelemetryService.logAction('dashboard.chart.donut.income.clicked', metadata: {'category_id': categoryId.toString()});
                              context.go(uri.toString());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Donut Chart - Despesas por Categoria
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pie_chart,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Despesas por Categoria',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TopCategoriesDonutChart(
                            categories: _data!.topCategories.expenses.take(5).toList(),
                            onSliceTap: _navigateToTransactionsCategory,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transações Recentes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    final last30Days = DateTime.now().subtract(const Duration(days: 30));
                    final today = DateTime.now();
                    TelemetryService.logAction('dashboard.widget.view_all.clicked', metadata: {'widget': 'transactions'});
                    context.go(
                      '/app/transactions?from=${last30Days.toIso8601String().split('T')[0]}&to=${today.toIso8601String().split('T')[0]}',
                    );
                  },
                  child: const Text('Ver tudo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_data!.recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Nenhuma transação encontrada',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ),
              )
            else
              ..._data!.recentTransactions.take(10).map((transaction) {
                return ListItemCard(
                  title: transaction.description,
                  subtitle:
                      '${transaction.account?.name ?? "Sem conta"} • ${_formatDate(transaction.occurredAt)}',
                  trailing: Text(
                    _formatCurrency(transaction.amount, currencyState),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getAmountColor(transaction.amount, transaction.type),
                    ),
                  ),
                  leadingIcon:
                      transaction.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                  leadingColor: _getAmountColor(transaction.amount, transaction.type),
                  onTap: () => context.go('/app/transactions?id=${transaction.id}'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingDueItems(bool canMarkPaid) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próximos Vencimentos (7 dias)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    final today = DateTime.now();
                    final nextWeek = today.add(const Duration(days: 7));
                    TelemetryService.logAction('dashboard.widget.view_all.clicked', metadata: {'widget': 'due_items'});
                    context.go(
                      '/app/due-items?from=${today.toIso8601String().split('T')[0]}&to=${nextWeek.toIso8601String().split('T')[0]}',
                    );
                  },
                  child: const Text('Ver tudo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_data!.upcomingDueItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Nenhum vencimento próximo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ),
              )
            else
              ..._data!.upcomingDueItems.take(7).map((item) {
                final isOverdue = item.daysUntilDue != null && item.daysUntilDue! < 0;
                return ListItemCard(
                  title: item.title,
                  subtitle:
                      '${item.type == 'pay' ? "A Pagar" : "A Receber"} • ${_formatDate(item.dueDate)}${isOverdue ? " (ATRASADO)" : ""}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatCurrency(item.amount, currencyState),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getAmountColor(item.amount, item.type),
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ATRASADO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  leadingIcon: item.type == 'pay' ? Icons.arrow_upward : Icons.arrow_downward,
                  leadingColor: _getAmountColor(item.amount, item.type),
                  onTap: null,
                  actions: [
                    if (canMarkPaid && item.status == 'pending')
                      IconButton(
                        icon: const Icon(Icons.check_circle, size: 20),
                        onPressed: () => _markDueItemAsPaid(item.id),
                        tooltip: 'Marcar como pago',
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDueItemsCalendar() {
    // Filtrar due items pelo período atual
    final periodState = ref.watch(periodFilterProvider);
    final dates = periodState.dates;
    
    final allDueItems = [
      ..._data!.overdueItems,
      ..._data!.upcomingDueItems,
    ].where((item) {
      final dueDate = DateTime.parse(item.dueDate);
      return dueDate.isAfter(dates.from.subtract(const Duration(days: 1))) &&
          dueDate.isBefore(dates.to.add(const Duration(days: 1)));
    }).toList();

    return DueItemsCalendar(
      dueItems: allDueItems,
      transactions: _data!.recentTransactions, // Incluir transações no calendário
      // onDateTap removido - o calendário agora usa modal por padrão
    );
  }

  Widget _buildAccountBalances() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldos das Contas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    TelemetryService.logAction('dashboard.widget.view_all.clicked', metadata: {'widget': 'accounts'});
                    context.go('/app/accounts');
                  },
                  child: const Text('Ver tudo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_data!.accountBalances.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Nenhuma conta encontrada',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (RbacHelper.canEdit(ref.read(authProvider)))
                        OutlinedButton.icon(
                          onPressed: () => context.go('/app/accounts'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Criar conta'),
                        ),
                    ],
                  ),
                ),
              )
            else
              ..._data!.accountBalances.map((account) {
                return ListItemCard(
                  title: account.name,
                  subtitle: 'Conta',
                  trailing: Text(
                    _formatCurrency(account.balance, currencyState),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  leadingIcon: Icons.account_balance_wallet,
                  leadingColor: account.balance >= 0 ? Colors.green : Colors.red,
                  onTap: () => context.go('/app/accounts/${account.id}'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueBadge() {
    final count = _data!.overdueItems.length;
    final total = _data!.overdueItems.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () {
          TelemetryService.logAction('dashboard.overdue_badge.clicked');
          context.go('/app/due-items?status=overdue');
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${count == 1 ? 'item vencido' : 'itens vencidos'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${_formatCurrency(total, currencyState)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsMenu(BuildContext context) {
    final authState = ref.read(authProvider);
    final canCreateTransaction = PermissionHelper.hasPermission(authState, Permission.transactionsCreate);
    final canCreateCategory = PermissionHelper.hasPermission(authState, Permission.categoriesCreate);
    final canUploadDocument = PermissionHelper.hasPermission(authState, Permission.documentsUpload);
    final canCreateDueItem = PermissionHelper.hasPermission(authState, Permission.dueItemsCreate);
    
    // Se não tem nenhuma permissão, não mostra o menu
    if (!canCreateTransaction && !canCreateCategory && !canUploadDocument && !canCreateDueItem) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: _closeQuickActionsMenu,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ações Rápidas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      if (canCreateTransaction)
                        _QuickActionMenuItem(
                          icon: Icons.swap_horiz,
                          label: 'Nova Transação',
                          shortcut: 'T',
                          onTap: () => _handleQuickAction('transaction'),
                          color: Colors.green,
                        ),
                      if (canCreateCategory)
                        _QuickActionMenuItem(
                          icon: Icons.category,
                          label: 'Nova Categoria',
                          shortcut: 'C',
                          onTap: () => _handleQuickAction('category'),
                          color: Colors.purple,
                        ),
                      if (canUploadDocument)
                        _QuickActionMenuItem(
                          icon: Icons.upload,
                          label: 'Upload Documento',
                          shortcut: 'D',
                          onTap: () => _handleQuickAction('document'),
                          color: Colors.indigo,
                        ),
                      if (canCreateDueItem)
                        _QuickActionMenuItem(
                          icon: Icons.event,
                          label: 'Novo Vencimento',
                          shortcut: 'V',
                          onTap: () => _handleQuickAction('due_item'),
                          color: Colors.orange,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _closeQuickActionsMenu,
                    child: const Text('Fechar (Esc)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionMenuItem({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                shortcut,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

