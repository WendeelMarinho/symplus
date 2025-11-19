import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/dashboard_data.dart';

/// Gráfico de barras Receitas x Despesas (6 meses)
class IncomeExpenseBarChart extends ConsumerWidget {
  final List<MonthlyIncomeExpense> data;
  final Function(String month)? onBarTap;

  const IncomeExpenseBarChart({
    super.key,
    required this.data,
    this.onBarTap,
  });

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    if (data.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    final maxValue = data.fold<double>(
      0.0,
      (max, item) => [item.income, item.expenses, max].reduce((a, b) => a > b ? a : b),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxValue * 1.2,
        groupsSpace: 12,
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            groupVertically: true,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: item.income,
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: item.expenses,
                color: Colors.red,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value, currencyState),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const Text('');
                final month = data[value.toInt()].month;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    month,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipBgColor: Colors.grey[800]!,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[groupIndex];
              final isIncome = rodIndex == 0;
              final value = isIncome ? item.income : item.expenses;
              final net = item.net;
              return BarTooltipItem(
                '${isIncome ? "Receita" : "Despesa"}: ${_formatCurrency(value, currencyState)}\n'
                'Resultado: ${_formatCurrency(net, currencyState)}',
                const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
              );
            },
          ),
          enabled: true,
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent && barTouchResponse?.spot != null) {
              final groupIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
              if (groupIndex >= 0 && groupIndex < data.length) {
                onBarTap?.call(data[groupIndex].month);
              }
            }
          },
        ),
      ),
    );
  }
}

/// Gráfico Donut - Top 5 Categorias de Despesa
class TopCategoriesDonutChart extends ConsumerWidget {
  final List<CategoryTotal> categories;
  final Function(int categoryId)? onSliceTap;

  const TopCategoriesDonutChart({
    super.key,
    required this.categories,
    this.onSliceTap,
  });

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    if (categories.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    final total = categories.fold<double>(0.0, (sum, item) => sum + item.total);
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.deepOrange,
      Colors.pink,
      Colors.redAccent,
    ];

    return Row(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percentage = (item.total / total) * 100;
                return PieChartSectionData(
                  value: item.total,
                  title: '${percentage.toStringAsFixed(1)}%',
                  color: colors[index % colors.length],
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                    final sectionIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    if (sectionIndex >= 0 && sectionIndex < categories.length) {
                      onSliceTap?.call(categories[sectionIndex].category.id);
                    }
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final percentage = (item.total / total) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.category.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCurrency(item.total, currencyState),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

