import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Tipo de KPI principal
enum KpiType {
  income, // Entrada (verde)
  expense, // Saída (vermelho)
  net, // Resultado (azul)
  percentage, // Percentual (amarelo)
}

/// Widget de card principal de KPI
/// 
/// Exibe um card grande com valor, comparativo com mês anterior,
/// ícone e botão [Detalhes] que navega para página filtrada.
class KpiMainCard extends ConsumerWidget {
  final KpiType type;
  final double value;
  final double? previousValue;
  final String? label;
  final VoidCallback? onDetailsTap;

  const KpiMainCard({
    super.key,
    required this.type,
    required this.value,
    this.previousValue,
    this.label,
    this.onDetailsTap,
  });

  /// Retorna a configuração visual baseada no tipo
  ({Color color, IconData icon, String title}) _getConfig(BuildContext context) {
    switch (type) {
      case KpiType.income:
        return (
          color: Colors.green.shade600,
          icon: Icons.trending_up,
          title: context.t('dashboard.kpi.income'),
        );
      case KpiType.expense:
        return (
          color: Colors.red.shade600,
          icon: Icons.trending_down,
          title: context.t('dashboard.kpi.expense'),
        );
      case KpiType.net:
        return (
          color: Colors.blue.shade600,
          icon: Icons.account_balance,
          title: context.t('dashboard.kpi.net'),
        );
      case KpiType.percentage:
        return (
          color: Colors.amber.shade600,
          icon: Icons.percent,
          title: context.t('dashboard.kpi.percentage'),
        );
    }
  }

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  String _formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  double? _getVariation() {
    if (previousValue == null || previousValue == 0) return null;
    return ((value - previousValue!) / previousValue!) * 100;
  }

  String _getPreviousPeriodLabel(BuildContext context, CurrencyState currencyState) {
    if (previousValue == null) return '';
    final previousLabel = context.t('dashboard.kpi.previous_month');
    if (type == KpiType.percentage) {
      return '$previousLabel: ${_formatPercentage(previousValue!)}';
    }
    return '$previousLabel: ${_formatCurrency(previousValue!, currencyState)}';
  }

  void _handleDetailsTap(BuildContext context) {
    if (onDetailsTap != null) {
      onDetailsTap!();
      return;
    }

    // Navegação padrão para página de detalhes
    final typeString = type.name; // income, expense, net, percentage
    TelemetryService.logAction(
      'kpi_main_card.details_clicked',
      metadata: {'type': typeString},
    );
    context.go('/app/dashboard/details/$typeString');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final config = _getConfig(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final variation = _getVariation();
    final isPositive = variation != null && variation! >= 0;
    final formattedValue = type == KpiType.percentage
        ? _formatPercentage(value)
        : _formatCurrency(value, currencyState);
    final previousLabel = previousValue != null ? _getPreviousPeriodLabel(context, currencyState) : null;
    final increaseLabel = context.t('dashboard.kpi.increase');
    final reductionLabel = context.t('dashboard.kpi.decrease');
    final inRelationLabel = context.t('dashboard.kpi.in_relation_to_previous');
    final variationLabel = variation != null
        ? '${isPositive ? increaseLabel : reductionLabel} de ${variation!.abs().toStringAsFixed(1)}% $inRelationLabel'
        : null;

    return Semantics(
      label: '${config.title}: $formattedValue. ${previousLabel ?? ""} ${variationLabel ?? ""}',
      button: true,
      onTap: () => _handleDetailsTap(context),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: config.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleDetailsTap(context),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cabeçalho com ícone e título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: config.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              config.icon,
                              color: config.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label ?? config.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      if (variation != null)
                        Tooltip(
                          message: variationLabel ?? '',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive ? Icons.trending_up : Icons.trending_down,
                                  size: 14,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${variation!.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Valor principal
                  Text(
                    formattedValue,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: config.color,
                          fontSize: isMobile ? 28 : 32,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Comparativo com mês anterior
                  if (previousValue != null)
                    Text(
                      previousLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  const Spacer(),
                  // Botão [Detalhes]
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _handleDetailsTap(context),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(context.t('common.details')),
                      style: FilledButton.styleFrom(
                        backgroundColor: config.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

