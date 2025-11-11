import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/dashboard_data.dart';

class DueItemsCalendar extends StatelessWidget {
  final List<DueItemSummary> dueItems;
  final Function(DateTime date)? onDateTap;

  const DueItemsCalendar({
    super.key,
    required this.dueItems,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday;

    // Agrupar due items por data
    final itemsByDate = <DateTime, int>{};
    for (final item in dueItems) {
      final date = DateTime.parse(item.dueDate);
      final key = DateTime(date.year, date.month, date.day);
      itemsByDate[key] = (itemsByDate[key] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              () {
                try {
                  return DateFormat('MMMM yyyy', 'pt_BR').format(now);
                } catch (e) {
                  return DateFormat('MMMM yyyy').format(now);
                }
              }(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                final date = DateTime(now.year, now.month, day);
                final hasItems = itemsByDate.containsKey(date);
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

                return InkWell(
                  onTap: hasItems ? () => onDateTap?.call(date) : null,
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
                        if (hasItems)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isToday ? Colors.white : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
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

