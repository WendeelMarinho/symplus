import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/period_filter.dart';
import '../../../../core/providers/period_filter_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../accounts/data/services/account_service.dart';
import '../../../accounts/data/models/account.dart';
import '../../../categories/data/services/category_service.dart';
import '../../../categories/data/models/category.dart';
import '../widgets/kpi_main_card.dart';

/// Página de detalhes de transações filtradas por tipo de KPI
class DashboardDetailsPage extends ConsumerStatefulWidget {
  final String type; // income, expense, net, percentage

  const DashboardDetailsPage({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<DashboardDetailsPage> createState() =>
      _DashboardDetailsPageState();
}

class _DashboardDetailsPageState
    extends ConsumerState<DashboardDetailsPage> {
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  int? _filterAccountId;
  int? _filterCategoryId;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  KpiType get _kpiType {
    switch (widget.type) {
      case 'income':
        return KpiType.income;
      case 'expense':
        return KpiType.expense;
      case 'net':
        return KpiType.net;
      case 'percentage':
        return KpiType.percentage;
      default:
        return KpiType.income;
    }
  }

  String get _title {
    switch (_kpiType) {
      case KpiType.income:
        return 'Detalhes - Entrada';
      case KpiType.expense:
        return 'Detalhes - Saída';
      case KpiType.net:
        return 'Detalhes - Resultado';
      case KpiType.percentage:
        return 'Detalhes - Percentual';
    }
  }

  String? get _transactionTypeFilter {
    switch (_kpiType) {
      case KpiType.income:
        return 'income';
      case KpiType.expense:
        return 'expense';
      case KpiType.net:
      case KpiType.percentage:
        return null; // Mostrar todas para net e percentage
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTransactions(),
      _loadAccounts(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadAccounts() async {
    try {
      final response = await AccountService.list();
      if (response.statusCode == 200) {
        final data = response.data;
        final accountsData = data['data'] as List<dynamic>;
        setState(() {
          _accounts = accountsData.map((json) => Account.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await CategoryService.list();
      if (response.statusCode == 200) {
        final data = response.data;
        final categoriesData = data['data'] as List<dynamic>;
        setState(() {
          _categories =
              categoriesData.map((json) => Category.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadTransactions({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final periodState = ref.read(periodFilterProvider);
      final dates = periodState.dates;

      final response = await TransactionService.list(
        type: _transactionTypeFilter,
        accountId: _filterAccountId,
        categoryId: _filterCategoryId,
        from: dates.from.toIso8601String().split('T')[0],
        to: dates.to.toIso8601String().split('T')[0],
        page: _currentPage,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final transactionsData = data['data'] as List<dynamic>;
        final meta = data['meta'] as Map<String, dynamic>;

        setState(() {
          if (_currentPage == 1) {
            _transactions =
                transactionsData.map((json) => Transaction.fromJson(json)).toList();
          } else {
            _transactions.addAll(
                transactionsData.map((json) => Transaction.fromJson(json)).toList());
          }
          _totalPages = meta['last_page'] as int;
          _hasMore = _currentPage < _totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      TelemetryService.logError(e.toString(), context: 'dashboard_details.load');
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadTransactions();
  }

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getAmountColor(Transaction transaction) {
    if (transaction.type == 'income') {
      return Colors.green;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final periodState = ref.watch(periodFilterProvider);
    final isMobile = ResponsiveUtils.isMobile(context);

    // Observar mudanças no período e recarregar
    ref.listen<PeriodFilterState>(
      periodFilterProvider,
      (previous, next) {
        if (previous != next && mounted) {
          setState(() {
            _currentPage = 1;
          });
          _loadTransactions();
        }
      },
    );

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: _title,
            subtitle: 'Período: ${periodState.displayLabel}',
            breadcrumbs: const ['Dashboard', 'Detalhes'],
            actions: [
              const PeriodFilter(showLabel: false),
            ],
          ),
          // Filtros
          Container(
            padding: ResponsiveUtils.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Filtro de Conta
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: DropdownButtonFormField<int?>(
                    value: _filterAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Conta',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas as contas'),
                      ),
                      ..._accounts.map((account) => DropdownMenuItem<int?>(
                            value: account.id,
                            child: Text(account.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterAccountId = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                // Filtro de Categoria
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: DropdownButtonFormField<int?>(
                    value: _filterCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas as categorias'),
                      ),
                      ..._categories.map((category) => DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterCategoryId = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Lista de transações
          Expanded(
            child: _isLoading
                ? const LoadingState()
                : _error != null
                    ? ErrorState(
                        error: _error!,
                        onRetry: () => _loadTransactions(),
                      )
                    : _transactions.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long,
                            title: 'Nenhuma transação encontrada',
                            message:
                                'Não há transações do tipo selecionado no período.',
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadTransactions(),
                            child: ListView.builder(
                              padding: ResponsiveUtils.getResponsivePadding(context),
                              itemCount: _transactions.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _transactions.length) {
                                  // Botão carregar mais
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                          _loadTransactions(showLoading: false);
                                        },
                                        child: const Text('Carregar mais'),
                                      ),
                                    ),
                                  );
                                }

                                final transaction = _transactions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ListItemCard(
                                    title: transaction.description,
                                    subtitle: _formatDate(transaction.occurredAt),
                                    trailing: Consumer(
                                      builder: (context, ref, child) {
                                        final currencyState = ref.watch(currencyProvider);
                                        return Text(
                                          _formatCurrency(transaction.amount.abs(), currencyState),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getAmountColor(transaction),
                                          ),
                                        );
                                      },
                                    ),
                                    leadingIcon: transaction.type == 'income'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    onTap: () {
                                      // Navegar para detalhes da transação se necessário
                                      context.go('/app/transactions');
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

