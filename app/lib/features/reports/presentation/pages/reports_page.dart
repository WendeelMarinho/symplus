import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../data/services/report_service.dart';
import '../../data/models/pl_report.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  PlReport? _report;
  bool _isLoading = false;
  String? _error;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _groupBy = 'month'; // 'month' ou 'category'
  bool _showChart = true;

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ReportService.generatePl(
        from: _fromDate,
        to: _toDate,
        groupBy: _groupBy,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _report = PlReport.fromJson(data);
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['message'] ?? 'Erro ao gerar relatório';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao gerar relatório: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      helpText: 'Selecione o período',
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _generateReport();
    }
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Relatórios (P&L)',
          subtitle: 'Visualize relatórios financeiros e análises',
          breadcrumbs: const ['Financeiro', 'Relatórios'],
        ),
        // Filtros
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _groupBy,
                  items: const [
                    DropdownMenuItem(value: 'month', child: Text('Por Mês')),
                    DropdownMenuItem(value: 'category', child: Text('Por Categoria')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _groupBy = value;
                      });
                      _generateReport();
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(_showChart ? Icons.table_chart : Icons.bar_chart),
                  onPressed: () {
                    setState(() {
                      _showChart = !_showChart;
                    });
                  },
                  tooltip: _showChart ? 'Mostrar Tabela' : 'Mostrar Gráfico',
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Gerando relatório...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _generateReport,
                    )
                  : _report == null
                      ? const Center(child: Text('Nenhum dado disponível'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Resumo
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Resumo do Período',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _SummaryCard(
                                              title: 'Receitas',
                                              value: _report!.totalIncome,
                                              color: Colors.green,
                                              icon: Icons.trending_up,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _SummaryCard(
                                              title: 'Despesas',
                                              value: _report!.totalExpense,
                                              color: Colors.red,
                                              icon: Icons.trending_down,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _SummaryCard(
                                              title: 'Lucro Líquido',
                                              value: _report!.netProfit,
                                              color: _report!.netProfit >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                              icon: Icons.account_balance,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Despesas representam ${_report!.expenseOverIncomePercent.toStringAsFixed(1)}% das receitas',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              const SizedBox(height: 16),

                              // Gráfico ou Tabela
                              if (_showChart)
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _groupBy == 'month'
                                              ? 'Evolução Mensal'
                                              : 'Por Categoria',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 300,
                                          child: _buildChart(),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _groupBy == 'month'
                                              ? 'Detalhamento Mensal'
                                              : 'Detalhamento por Categoria',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTable(),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_report == null || _report!.series.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    if (_groupBy == 'month') {
      return _buildMonthChart();
    } else {
      return _buildCategoryChart();
    }
  }

  Widget _buildMonthChart() {
    final series = _report!.series;
    final maxValue = series.fold<double>(
      0.0,
      (max, item) => [
        (item['income'] as num).toDouble(),
        (item['expense'] as num).toDouble(),
        max,
      ].reduce((a, b) => a > b ? a : b),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxValue * 1.2,
        groupsSpace: 12,
        barGroups: series.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            groupVertically: true,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: (item['income'] as num).toDouble(),
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: (item['expense'] as num).toDouble(),
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
                  _formatCurrency(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= series.length) return const Text('');
                final month = series[value.toInt()]['month'] as String;
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipBgColor: Colors.grey[800]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = series[groupIndex];
              final isIncome = rodIndex == 0;
              final value = isIncome
                  ? (item['income'] as num).toDouble()
                  : (item['expense'] as num).toDouble();
              return BarTooltipItem(
                '${isIncome ? "Receita" : "Despesa"}: ${_formatCurrency(value)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    final series = _report!.series;
    final maxValue = series.fold<double>(
      0.0,
      (max, item) => [
        (item['income'] as num).toDouble(),
        (item['expense'] as num).toDouble(),
        max,
      ].reduce((a, b) => a > b ? a : b),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxValue * 1.2,
        groupsSpace: 12,
        barGroups: series.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            groupVertically: true,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: (item['income'] as num).toDouble(),
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: (item['expense'] as num).toDouble(),
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
                  _formatCurrency(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= series.length) return const Text('');
                final categoryName = series[value.toInt()]['category_name'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    categoryName.length > 10
                        ? '${categoryName.substring(0, 10)}...'
                        : categoryName,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipBgColor: Colors.grey[800]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = series[groupIndex];
              final isIncome = rodIndex == 0;
              final value = isIncome
                  ? (item['income'] as num).toDouble()
                  : (item['expense'] as num).toDouble();
              return BarTooltipItem(
                '${isIncome ? "Receita" : "Despesa"}: ${_formatCurrency(value)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (_report == null || _report!.series.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(_groupBy == 'month' ? 'Mês' : 'Categoria'),
          ),
          const DataColumn(
            label: Text('Receitas'),
            numeric: true,
          ),
          const DataColumn(
            label: Text('Despesas'),
            numeric: true,
          ),
          const DataColumn(
            label: Text('Lucro Líquido'),
            numeric: true,
          ),
        ],
        rows: _report!.series.map((item) {
          final label = _groupBy == 'month'
              ? item['month'] as String
              : item['category_name'] as String;
          final income = (item['income'] as num).toDouble();
          final expense = (item['expense'] as num).toDouble();
          final net = (item['net'] as num).toDouble();

          return DataRow(
            cells: [
              DataCell(Text(label)),
              DataCell(Text(
                _formatCurrency(income),
                style: const TextStyle(color: Colors.green),
              )),
              DataCell(Text(
                _formatCurrency(expense),
                style: const TextStyle(color: Colors.red),
              )),
              DataCell(Text(
                _formatCurrency(net),
                style: TextStyle(
                  color: net >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
