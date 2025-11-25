import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
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
                color: AppColors.income,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: item.expenses,
                color: AppColors.expense,
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
                  style: AppTypography.caption,
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
                    style: AppTypography.caption,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
            left: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipBgColor: AppColors.onBackground,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[groupIndex];
              final isIncome = rodIndex == 0;
              final value = isIncome ? item.income : item.expenses;
              final net = item.net;
              return BarTooltipItem(
                '${isIncome ? "Receita" : "Despesa"}: ${_formatCurrency(value, currencyState)}\n'
                'Resultado: ${_formatCurrency(net, currencyState)}',
                AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.5,
                ),
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
    final colors = AppColors.chartColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 250,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular tamanho do gráfico baseado no espaço disponível
          final availableWidth = constraints.maxWidth > 0 && constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 400.0;
          final isNarrow = availableWidth < 450;
          
          // Em telas estreitas, empilhar verticalmente
          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
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
              const SizedBox(height: 16),
              ...categories.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.category.name,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatCurrency(item.total, currencyState),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            );
          }
          
          // Em telas largas, layout horizontal
          final chartSize = 160.0;
          final legendWidth = (availableWidth - chartSize - 16).clamp(100.0, double.infinity);
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            SizedBox(
              width: chartSize,
              height: chartSize,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final percentage = (item.total / total) * 100;
                    return PieChartSectionData(
                      value: item.total,
                      title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
                      color: colors[index % colors.length],
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 11,
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
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: legendWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.category.name,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatCurrency(item.total, currencyState),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          );
        },
      ),
    );
  }
}

