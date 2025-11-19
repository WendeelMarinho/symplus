import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/dashboard_data.dart';
import 'calendar_day_modal.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Tipo de item no calendário
enum CalendarItemType {
  dueItem,
  transaction,
}

/// Item do calendário (due item ou transação)
class CalendarItem {
  final CalendarItemType type;
  final DateTime date;
  final double? amount;
  final String? description;
  final String? status; // Para due items: 'pending', 'paid', 'overdue'

  CalendarItem({
    required this.type,
    required this.date,
    this.amount,
    this.description,
    this.status,
  });
}

class DueItemsCalendar extends ConsumerStatefulWidget {
  final List<DueItemSummary> dueItems;
  final List<TransactionSummary>? transactions; // Transações opcionais
  final Function(DateTime date)? onDateTap;
  final DateTime? initialMonth; // Mês inicial (padrão: mês atual)

  const DueItemsCalendar({
    super.key,
    required this.dueItems,
    this.transactions,
    this.onDateTap,
    this.initialMonth,
  });

  @override
  ConsumerState<DueItemsCalendar> createState() => _DueItemsCalendarState();
}

class _DueItemsCalendarState extends ConsumerState<DueItemsCalendar> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.initialMonth ?? DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _displayMonth = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayMonth = _displayMonth;
    final now = DateTime.now();
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastDay = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday;

    // Agrupar due items por data
    final itemsByDate = <DateTime, List<CalendarItem>>{};
    
    // Adicionar due items
    for (final item in widget.dueItems) {
      final date = DateTime.parse(item.dueDate);
      final key = DateTime(date.year, date.month, date.day);
      if (!itemsByDate.containsKey(key)) {
        itemsByDate[key] = [];
      }
      itemsByDate[key]!.add(CalendarItem(
        type: CalendarItemType.dueItem,
        date: key,
        amount: item.amount,
        description: item.title,
        status: item.status,
      ));
    }
    
    // Adicionar transações se disponíveis
    if (widget.transactions != null) {
      for (final transaction in widget.transactions!) {
        final date = DateTime.parse(transaction.occurredAt);
        final key = DateTime(date.year, date.month, date.day);
        if (!itemsByDate.containsKey(key)) {
          itemsByDate[key] = [];
        }
        itemsByDate[key]!.add(CalendarItem(
          type: CalendarItemType.transaction,
          date: key,
          amount: transaction.amount,
          description: transaction.description,
        ));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botão mês anterior
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                  tooltip: context.t('dashboard.calendar.previous_month'),
                ),
                // Mês e ano
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        () {
                          try {
                            return DateFormat('MMMM yyyy', 'pt_BR').format(displayMonth);
                          } catch (e) {
                            return DateFormat('MMMM yyyy').format(displayMonth);
                          }
                        }(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      // Indicador de período atual
                      if (displayMonth.year == now.year && displayMonth.month == now.month)
                        Chip(
                          label: Text(context.t('common.current')),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      // Botão "Hoje" se não estiver no mês atual
                      if (displayMonth.year != now.year || displayMonth.month != now.month)
                        TextButton(
                          onPressed: _goToToday,
                          child: Text(context.t('common.today')),
                        ),
                    ],
                  ),
                ),
                // Botão mês seguinte
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                  tooltip: context.t('dashboard.calendar.next_month'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dias da semana
            Row(
              children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Grid de dias
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: startWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startWeekday - 1) {
                  return const SizedBox.shrink();
                }

                final day = index - (startWeekday - 1) + 1;
                final date = DateTime(displayMonth.year, displayMonth.month, day);
                final dayItems = itemsByDate[date] ?? [];
                final hasItems = dayItems.isNotEmpty;
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
                
                // Contar tipos de itens
                final dueItemsCount = dayItems.where((i) => i.type == CalendarItemType.dueItem).length;
                final transactionsCount = dayItems.where((i) => i.type == CalendarItemType.transaction).length;
                
                // Calcular total do dia
                final dayTotal = dayItems.fold<double>(
                  0.0,
                  (sum, item) => sum + (item.amount ?? 0.0),
                );

                final currencyState = ref.watch(currencyProvider);
                final formattedTotal = CurrencyFormatter.format(dayTotal, currencyState);
                
                return Tooltip(
                  message: hasItems
                      ? '${dayItems.length} ${dayItems.length == 1 ? context.t('dashboard.calendar.items') : context.t('dashboard.calendar.items_plural')}\n'
                          '${dueItemsCount > 0 ? '$dueItemsCount ${dueItemsCount == 1 ? context.t('dashboard.calendar.due_items') : context.t('dashboard.calendar.due_items_plural')}\n' : ''}'
                          '${transactionsCount > 0 ? '$transactionsCount ${transactionsCount == 1 ? context.t('dashboard.calendar.transactions') : context.t('dashboard.calendar.transactions_plural')}\n' : ''}'
                          '${context.t('dashboard.calendar.total')}: $formattedTotal'
                      : context.t('dashboard.calendar.no_events'),
                  child: InkWell(
                    onTap: hasItems
                        ? () {
                            // Se há callback customizado, usar ele; senão, abrir modal
                            if (widget.onDateTap != null) {
                              widget.onDateTap!(date);
                            } else {
                              // Abrir modal com transações e vencimentos do dia
                              CalendarDayModal.show(
                                context,
                                date: date,
                                transactions: widget.transactions ?? [],
                                dueItems: widget.dueItems,
                              );
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : isPast
                                ? Colors.grey.withOpacity(0.1)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? Colors.white
                                  : isPast
                                      ? Colors.grey
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (hasItems) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              alignment: WrapAlignment.center,
                              children: [
                                // Indicador de due items
                                if (dueItemsCount > 0)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isToday ? Colors.white : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                // Indicador de transações
                                if (transactionsCount > 0)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isToday ? Colors.white70 : Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

