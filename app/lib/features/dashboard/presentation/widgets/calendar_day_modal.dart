import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/dashboard_data.dart';

/// Modal/Bottom Sheet para exibir transações e vencimentos de um dia específico
class CalendarDayModal extends ConsumerWidget {
  final DateTime date;
  final List<TransactionSummary> transactions;
  final List<DueItemSummary> dueItems;

  const CalendarDayModal({
    super.key,
    required this.date,
    required this.transactions,
    required this.dueItems,
  });

  /// Mostra o modal/bottom sheet
  static void show(
    BuildContext context, {
    required DateTime date,
    required List<TransactionSummary> transactions,
    required List<DueItemSummary> dueItems,
  }) {
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      // Mobile: Bottom Sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => CalendarDayModal(
            date: date,
            transactions: transactions,
            dueItems: dueItems,
          ),
        ),
      );
    } else {
      // Desktop: Modal centralizado
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 700,
            ),
            child: CalendarDayModal(
              date: date,
              transactions: transactions,
              dueItems: dueItems,
            ),
          ),
        ),
      );
    }
  }

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final isMobile = ResponsiveUtils.isMobile(context);
    final dateStr = date.toIso8601String().split('T')[0];

    // Filtrar transações e due items do dia
    final dayTransactions = transactions.where((t) {
      final tDate = DateTime.parse(t.occurredAt).toIso8601String().split('T')[0];
      return tDate == dateStr;
    }).toList();

    final dayDueItems = dueItems.where((d) {
      return d.dueDate == dateStr;
    }).toList();

    // Calcular totais
    final totalIncome = dayTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = dayTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final totalDueItems = dayDueItems.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final netResult = totalIncome - totalExpenses;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      () {
                        final transLabel = dayTransactions.length == 1
                            ? context.t('dashboard.calendar.transactions')
                            : context.t('dashboard.calendar.transactions_plural');
                        final dueLabel = dayDueItems.length == 1
                            ? context.t('dashboard.calendar.due_items')
                            : context.t('dashboard.calendar.due_items_plural');
                        return '${dayTransactions.length} $transLabel • ${dayDueItems.length} $dueLabel';
                      }(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: context.t('common.close'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Totais
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.t('dashboard.kpi.income')}:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        _formatCurrency(totalIncome, currencyState),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.t('dashboard.kpi.expense')}:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        _formatCurrency(totalExpenses, currencyState),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                  if (dayDueItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${context.t('dashboard.calendar.due_items_plural')}:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _formatCurrency(totalDueItems, currencyState),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.t('dashboard.kpi.net')}:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _formatCurrency(netResult, currencyState),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: netResult >= 0 ? Colors.green : Colors.red,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de transações
          if (dayTransactions.isNotEmpty) ...[
            Text(
              context.t('transactions.title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dayTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = dayTransactions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListItemCard(
                      title: transaction.description,
                      subtitle: DateFormat('HH:mm').format(
                        DateTime.parse(transaction.occurredAt),
                      ),
                      amount: transaction.amount,
                      amountColor: transaction.type == 'income'
                          ? Colors.green
                          : Colors.red,
                      leadingIcon: transaction.type == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      onTap: () {
                        // TODO: Navegar para detalhe da transação quando implementado
                        Navigator.of(context).pop();
                        context.go('/app/transactions?date=$dateStr');
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Lista de vencimentos
          if (dayDueItems.isNotEmpty) ...[
            Text(
              context.t('dashboard.calendar.due_items_plural'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dayDueItems.length,
                itemBuilder: (context, index) {
                  final dueItem = dayDueItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListItemCard(
                      title: dueItem.title,
                      subtitle: 'Status: ${dueItem.status}',
                      amount: dueItem.amount,
                      amountColor: dueItem.status == 'overdue'
                          ? Colors.red
                          : Colors.orange,
                      leadingIcon: Icons.calendar_today,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/app/due-items?date=$dateStr');
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Empty state
          if (dayTransactions.isEmpty && dayDueItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t('dashboard.calendar.no_events'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          // Botão "Ver todas as transações"
          if (dayTransactions.isNotEmpty || dayDueItems.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/app/transactions?from=$dateStr&to=$dateStr');
                },
                icon: const Icon(Icons.list),
                label: Text(context.t('common.view_all')),
              ),
            ),
        ],
      ),
    );
  }
}

