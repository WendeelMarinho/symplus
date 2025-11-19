import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/period_filter.dart';
import '../../../../core/providers/period_filter_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/custom_indicator.dart';
import '../../data/services/custom_indicator_service.dart';

/// Página de detalhes de um indicador personalizado
/// Mostra todas as transações das categorias vinculadas
class CustomIndicatorDetailsPage extends ConsumerStatefulWidget {
  final int indicatorId;

  const CustomIndicatorDetailsPage({
    super.key,
    required this.indicatorId,
  });

  @override
  ConsumerState<CustomIndicatorDetailsPage> createState() =>
      _CustomIndicatorDetailsPageState();
}

class _CustomIndicatorDetailsPageState
    extends ConsumerState<CustomIndicatorDetailsPage> {
  CustomIndicator? _indicator;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final indicator = await CustomIndicatorService.get(widget.indicatorId);
      if (indicator == null) {
        setState(() {
          _error = 'Indicador não encontrado';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _indicator = indicator;
      });

      await _loadTransactions();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    if (_indicator == null) return;

    try {
      final periodState = ref.read(periodFilterProvider);
      final dates = periodState.dates;

      // Buscar todas as transações do período
      final response = await TransactionService.list(
        from: dates.from.toIso8601String().split('T')[0],
        to: dates.to.toIso8601String().split('T')[0],
        type: 'expense', // Apenas despesas
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final transactionsData = data['data'] as List<dynamic>;
        final allTransactions = transactionsData
            .map((json) => Transaction.fromJson(json))
            .toList();

        // Filtrar transações das categorias do indicador
        setState(() {
          _transactions = allTransactions.where((t) {
            return t.categoryId != null &&
                _indicator!.categoryIds.contains(t.categoryId);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final periodState = ref.watch(periodFilterProvider);

    // Observar mudanças no período
    ref.listen<PeriodFilterState>(
      periodFilterProvider,
      (previous, next) {
        if (previous != next && mounted) {
          _loadTransactions();
        }
      },
    );

    if (_isLoading) {
      return const Scaffold(
        body: LoadingState(),
      );
    }

    if (_error != null || _indicator == null) {
      return Scaffold(
        body: ErrorState(
          error: _error ?? 'Indicador não encontrado',
          onRetry: () => _loadData(),
        ),
      );
    }

    final totalValue = _transactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: _indicator!.name,
            subtitle: 'Período: ${periodState.displayLabel}',
            breadcrumbs: const ['Dashboard', 'Indicadores Personalizados'],
            actions: [
              const PeriodFilter(showLabel: false),
            ],
          ),
          // Resumo
          Container(
            padding: ResponsiveUtils.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final currencyState = ref.watch(currencyProvider);
                      return _buildSummaryItem(
                        context,
                        'Total',
                        _formatCurrency(totalValue, currencyState),
                        Icons.attach_money,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Transações',
                    '${_transactions.length}',
                    Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Categorias',
                    '${_indicator!.categoryIds.length}',
                    Icons.category,
                  ),
                ),
              ],
            ),
          ),
          // Lista de transações
          Expanded(
            child: _transactions.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Nenhuma transação encontrada',
                    message:
                        'Não há transações das categorias selecionadas no período.',
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadTransactions(),
                    child: ListView.builder(
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ListItemCard(
                            title: transaction.description,
                            subtitle: _formatDate(transaction.occurredAt.toIso8601String()),
                            trailing: Consumer(
                              builder: (context, ref, child) {
                                final currencyState = ref.watch(currencyProvider);
                                return Text(
                                  _formatCurrency(transaction.amount, currencyState),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            ),
                            leadingIcon: Icons.arrow_upward,
                            onTap: () {
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

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

