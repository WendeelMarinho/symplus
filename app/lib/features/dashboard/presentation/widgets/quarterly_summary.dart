import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/period_filter_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction.dart';

/// Dados do resumo trimestral
class QuarterlySummaryData {
  final double income;
  final double expenses;
  final double net;
  final double percentage;
  final DateTime quarterStart;
  final DateTime quarterEnd;

  QuarterlySummaryData({
    required this.income,
    required this.expenses,
    required this.net,
    required this.percentage,
    required this.quarterStart,
    required this.quarterEnd,
  });
}

/// Widget de Resumo Trimestral
/// 
/// Calcula e exibe dados do trimestre relativo ao mês atual
class QuarterlySummary extends ConsumerStatefulWidget {
  const QuarterlySummary({super.key});

  @override
  ConsumerState<QuarterlySummary> createState() => _QuarterlySummaryState();
}

class _QuarterlySummaryState extends ConsumerState<QuarterlySummary> {
  QuarterlySummaryData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuarterlyData();
  }


  /// Calcula o trimestre baseado na data inicial do período global
  /// Se o período não for trimestral, calcula o trimestre que contém a data inicial
  ({DateTime start, DateTime end}) _calculateQuarterFromPeriod(DateTime referenceDate) {
    // Calcular trimestre que contém a data de referência (Q1: Jan-Mar, Q2: Apr-Jun, Q3: Jul-Sep, Q4: Oct-Dec)
    final quarter = ((referenceDate.month - 1) / 3).floor();
    final firstMonth = quarter * 3 + 1;
    final lastMonth = (quarter + 1) * 3;
    
    final start = DateTime(referenceDate.year, firstMonth, 1);
    final end = DateTime(referenceDate.year, lastMonth + 1, 0); // Último dia do último mês do trimestre
    
    return (start: start, end: end);
  }

  Future<void> _loadQuarterlyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obter período global atual
      final periodState = ref.read(periodFilterProvider);
      final periodDates = periodState.dates;
      
      // Calcular trimestre baseado na data inicial do período
      final quarter = _calculateQuarterFromPeriod(periodDates.from);
      
      // Buscar transações do trimestre
      final response = await TransactionService.list(
        from: quarter.start.toIso8601String().split('T')[0],
        to: quarter.end.toIso8601String().split('T')[0],
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final transactionsData = data['data'] as List<dynamic>;
        final transactions = transactionsData
            .map((json) => Transaction.fromJson(json))
            .toList();

        // Calcular totais
        final income = transactions
            .where((t) => t.type == 'income')
            .fold<double>(0.0, (sum, t) => sum + t.amount);
        
        final expenses = transactions
            .where((t) => t.type == 'expense')
            .fold<double>(0.0, (sum, t) => sum + t.amount);
        
        final net = income - expenses;
        
        // Calcular percentual (margem de lucro)
        final percentage = income > 0 ? (net / income * 100) : 0.0;

        setState(() {
          _data = QuarterlySummaryData(
            income: income,
            expenses: expenses,
            net: net,
            percentage: percentage,
            quarterStart: quarter.start,
            quarterEnd: quarter.end,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar dados trimestrais';
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

  String _formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  String _getQuarterLabel() {
    if (_data == null) return '';
    
    final month = _data!.quarterStart.month;
    String quarterName;
    if (month <= 3) {
      quarterName = 'Q1';
    } else if (month <= 6) {
      quarterName = 'Q2';
    } else if (month <= 9) {
      quarterName = 'Q3';
    } else {
      quarterName = 'Q4';
    }
    
    return '$quarterName ${_data!.quarterStart.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final periodState = ref.watch(periodFilterProvider);
    final currencyState = ref.watch(currencyProvider);

    // Observar mudanças no período global
    ref.listen<PeriodFilterState>(
      periodFilterProvider,
      (previous, next) {
        if (previous != next) {
          _loadQuarterlyData();
        }
      },
    );

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || _data == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Erro ao carregar dados',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadQuarterlyData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

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
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_view_month,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('dashboard.quarterly_summary.title'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _getQuarterLabel(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Cards ou tabela
            if (isMobile)
              // Mobile: lista vertical
              Column(
                children: [
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.income'),
                    _data!.income,
                    Colors.green,
                    Icons.trending_up,
                    currencyState: currencyState,
                  ),
                  const SizedBox(height: 12),
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.expense'),
                    _data!.expenses,
                    Colors.red,
                    Icons.trending_down,
                    currencyState: currencyState,
                  ),
                  const SizedBox(height: 12),
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.net'),
                    _data!.net,
                    _data!.net >= 0 ? Colors.blue : Colors.red,
                    Icons.account_balance,
                    currencyState: currencyState,
                  ),
                  const SizedBox(height: 12),
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.percentage'),
                    _data!.percentage,
                    Colors.amber,
                    Icons.percent,
                    isPercentage: true,
                    currencyState: currencyState,
                  ),
                ],
              )
            else
              // Desktop/Tablet: grid 2x2 ou tabela
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.income'),
                    _data!.income,
                    Colors.green,
                    Icons.trending_up,
                    currencyState: currencyState,
                  ),
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.expense'),
                    _data!.expenses,
                    Colors.red,
                    Icons.trending_down,
                    currencyState: currencyState,
                  ),
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.net'),
                    _data!.net,
                    _data!.net >= 0 ? Colors.blue : Colors.red,
                    Icons.account_balance,
                    currencyState: currencyState,
                  ),
                  _buildQuarterlyCard(
                    context,
                    context.t('dashboard.quarterly_summary.percentage'),
                    _data!.percentage,
                    Colors.amber,
                    Icons.percent,
                    isPercentage: true,
                    currencyState: currencyState,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterlyCard(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon, {
    bool isPercentage = false,
    required CurrencyState currencyState,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPercentage
                      ? _formatPercentage(value)
                      : _formatCurrency(value, currencyState),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

