import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/rbac/permission_helper.dart';
import '../../../../core/rbac/permissions_catalog.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/accessibility/accessible_widgets.dart';
import '../../data/services/report_service.dart';
import '../../data/models/pl_report.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
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

  Future<void> _exportToCSV() async {
    if (_report == null) {
      ToastService.showError(context, 'Nenhum relatório disponível para exportar');
      return;
    }

    try {
      final buffer = StringBuffer();
      
      // Cabeçalho
      buffer.writeln('Relatório P&L - ${DateFormat('dd/MM/yyyy').format(_fromDate)} a ${DateFormat('dd/MM/yyyy').format(_toDate)}');
      buffer.writeln('');
      buffer.writeln('Resumo');
      buffer.writeln('Receitas,${_formatCurrency(_report!.totalIncome).replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.')}');
      buffer.writeln('Despesas,${_formatCurrency(_report!.totalExpense).replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.')}');
      buffer.writeln('Lucro Líquido,${_formatCurrency(_report!.netProfit).replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.')}');
      buffer.writeln('');
      
      // Detalhamento
      buffer.writeln('Detalhamento');
      buffer.writeln(_groupBy == 'month' ? 'Mês' : 'Categoria,Receitas,Despesas,Lucro Líquido');
      
      for (var item in _report!.series) {
        final label = _groupBy == 'month' ? item['month'] as String : item['category_name'] as String;
        final income = (item['income'] as num).toDouble();
        final expense = (item['expense'] as num).toDouble();
        final net = (item['net'] as num).toDouble();
        
        buffer.writeln('$label,${income.toStringAsFixed(2)},${expense.toStringAsFixed(2)},${net.toStringAsFixed(2)}');
      }

      // Copiar para clipboard (para web, seria ideal fazer download)
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      ToastService.showSuccess(context, 'Relatório copiado para a área de transferência!');
    } catch (e) {
      ToastService.showError(context, 'Erro ao exportar: ${e.toString()}');
    }
  }

  Future<void> _exportToPDF() async {
    // Placeholder - em produção, usar um pacote como pdf ou printing
    ToastService.showInfo(context, 'Exportação para PDF em breve');
  }

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canViewReports = PermissionHelper.hasPermission(authState, Permission.viewReportsPl);

    if (!canViewReports) {
      return const Center(
        child: Text('Acesso não permitido'),
      );
    }

    return Column(
      children: [
        PageHeader(
          title: 'Relatórios (P&L)',
          subtitle: 'Visualize relatórios financeiros e análises',
          actions: [
            if (_report != null) ...[
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'Exportar CSV',
                onPressed: _exportToCSV,
                color: AppColors.textSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exportar PDF',
                onPressed: _exportToPDF,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
        // Filtros
        Padding(
          padding: AppSpacing.pagePadding(context),
          child: AccessibleCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ResponsiveUtils.isMobile(context)
                  ? Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                            style: AppTypography.label,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _groupBy,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                ),
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
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              icon: Icon(_showChart ? Icons.table_chart : Icons.bar_chart),
                              onPressed: () {
                                setState(() {
                                  _showChart = !_showChart;
                                });
                              },
                              tooltip: _showChart ? 'Mostrar Tabela' : 'Mostrar Gráfico',
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AccessibleFilledButton.icon(
                              onPressed: _generateReport,
                              icon: Icons.refresh,
                              label: 'Atualizar',
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                              style: AppTypography.label,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            value: _groupBy,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
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
                        ),
                        const SizedBox(width: AppSpacing.md),
                        IconButton(
                          icon: Icon(_showChart ? Icons.table_chart : Icons.bar_chart),
                          onPressed: () {
                            setState(() {
                              _showChart = !_showChart;
                            });
                          },
                          tooltip: _showChart ? 'Mostrar Tabela' : 'Mostrar Gráfico',
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        AccessibleFilledButton.icon(
                          onPressed: _generateReport,
                          icon: Icons.refresh,
                          label: 'Atualizar',
                        ),
                      ],
                    ),
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
                          padding: AppSpacing.pagePadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Resumo
                              AccessibleCard(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Resumo do Período',
                                        style: AppTypography.sectionTitle,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      ResponsiveUtils.isMobile(context)
                                          ? Column(
                                              children: [
                                                _SummaryCard(
                                                  title: 'Receitas',
                                                  value: _report!.totalIncome,
                                                  color: AppColors.income,
                                                  icon: Icons.trending_up,
                                                ),
                                                const SizedBox(height: AppSpacing.sm),
                                                _SummaryCard(
                                                  title: 'Despesas',
                                                  value: _report!.totalExpense,
                                                  color: AppColors.expense,
                                                  icon: Icons.trending_down,
                                                ),
                                                const SizedBox(height: AppSpacing.sm),
                                                _SummaryCard(
                                                  title: 'Lucro Líquido',
                                                  value: _report!.netProfit,
                                                  color: _report!.netProfit >= 0
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                  icon: Icons.account_balance,
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  child: _SummaryCard(
                                                    title: 'Receitas',
                                                    value: _report!.totalIncome,
                                                    color: AppColors.income,
                                                    icon: Icons.trending_up,
                                                  ),
                                                ),
                                                const SizedBox(width: AppSpacing.md),
                                                Expanded(
                                                  child: _SummaryCard(
                                                    title: 'Despesas',
                                                    value: _report!.totalExpense,
                                                    color: AppColors.expense,
                                                    icon: Icons.trending_down,
                                                  ),
                                                ),
                                                const SizedBox(width: AppSpacing.md),
                                                Expanded(
                                                  child: _SummaryCard(
                                                    title: 'Lucro Líquido',
                                                    value: _report!.netProfit,
                                                    color: _report!.netProfit >= 0
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                    icon: Icons.account_balance,
                                                  ),
                                                ),
                                              ],
                                            ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Despesas representam ${_report!.expenseOverIncomePercent.toStringAsFixed(1)}% das receitas',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Gráfico de barras empilhadas
                              AccessibleCard(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ResponsiveUtils.isMobile(context)
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _groupBy == 'month'
                                                      ? 'Receitas x Despesas por Mês'
                                                      : 'Receitas x Despesas por Categoria',
                                                  style: AppTypography.sectionTitle,
                                                ),
                                                const SizedBox(height: AppSpacing.sm),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.income,
                                                        borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                                                      ),
                                                    ),
                                                    const SizedBox(width: AppSpacing.xs),
                                                    Text('Receitas', style: AppTypography.caption),
                                                    const SizedBox(width: AppSpacing.md),
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.expense,
                                                        borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                                                      ),
                                                    ),
                                                    const SizedBox(width: AppSpacing.xs),
                                                    Text('Despesas', style: AppTypography.caption),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    _groupBy == 'month'
                                                        ? 'Receitas x Despesas por Mês'
                                                        : 'Receitas x Despesas por Categoria',
                                                    style: AppTypography.sectionTitle,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.income,
                                                        borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                                                      ),
                                                    ),
                                                    const SizedBox(width: AppSpacing.xs),
                                                    Text('Receitas', style: AppTypography.caption),
                                                    const SizedBox(width: AppSpacing.md),
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.expense,
                                                        borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                                                      ),
                                                    ),
                                                    const SizedBox(width: AppSpacing.xs),
                                                    Text('Despesas', style: AppTypography.caption),
                                                  ],
                                                ),
                                              ],
                                            ),
                                      const SizedBox(height: AppSpacing.md),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 300,
                                          maxHeight: 400,
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final chartWidth = constraints.maxWidth > 0 && constraints.maxWidth.isFinite
                                                ? constraints.maxWidth
                                                : 800.0;
                                            final chartHeight = constraints.maxHeight > 0 && constraints.maxHeight.isFinite
                                                ? constraints.maxHeight
                                                : 400.0;
                                            return SizedBox(
                                              height: chartHeight,
                                              width: chartWidth,
                                              child: _buildStackedBarChart(),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // Tabela de resumo
                              AccessibleCard(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _groupBy == 'month'
                                            ? 'Detalhamento Mensal'
                                            : 'Detalhamento por Categoria',
                                        style: AppTypography.sectionTitle,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildTable(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // Card de regras de alerta (placeholder)
                              AccessibleCard(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.notifications_active, color: Colors.amber.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Regras de Alerta',
                                            style: AppTypography.sectionTitle,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Configure alertas para receber notificações quando despesas ultrapassarem limites definidos.',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.settings),
                                        label: const Text('Configurar alertas'),
                                        onPressed: () {
                                          ToastService.showInfo(context, 'Configuração de alertas em breve');
                                        },
                                      ),
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

  Widget _buildStackedBarChart() {
    if (_report == null || _report!.series.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    final series = _report!.series;
    final maxValue = series.fold<double>(
      0.0,
      (max, item) {
        final income = (item['income'] as num).toDouble();
        final expense = (item['expense'] as num).toDouble();
        return [income + expense, max].reduce((a, b) => a > b ? a : b);
      },
    );

    return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxValue * 1.2,
          groupsSpace: 16,
          barGroups: series.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final income = (item['income'] as num).toDouble();
            final expense = (item['expense'] as num).toDouble();
            
            return BarChartGroupData(
              x: index,
              barRods: [
                // Receitas (verde) - parte inferior
                BarChartRodData(
                  fromY: 0,
                  toY: income,
                  color: Colors.green,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                // Despesas (vermelho) - empilhado sobre receitas
                BarChartRodData(
                  fromY: income,
                  toY: income + expense,
                  color: Colors.red,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatCurrency(value),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= series.length) return const Text('');
                  final label = _groupBy == 'month'
                      ? series[value.toInt()]['month'] as String
                      : (series[value.toInt()]['category_name'] as String).length > 10
                          ? '${(series[value.toInt()]['category_name'] as String).substring(0, 10)}...'
                          : series[value.toInt()]['category_name'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 5,
          ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = (constraints.maxWidth > 0 && constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : 600.0) as double;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: 400,
            minWidth: maxWidth,
            maxWidth: maxWidth,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: maxWidth,
                ),
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
              ),
            ),
          ),
        );
      },
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
    return AccessibleCard(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorders.smallRadius),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    _formatCurrency(value),
                    style: AppTypography.kpiValue.copyWith(
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
