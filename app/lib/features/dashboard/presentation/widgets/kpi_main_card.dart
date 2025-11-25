import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/dashboard_layout.dart';

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
  final DashboardInsight? insight;

  const KpiMainCard({
    super.key,
    required this.type,
    required this.value,
    this.previousValue,
    this.label,
    this.onDetailsTap,
    this.insight,
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

  String _getWidgetId() {
    switch (type) {
      case KpiType.income:
        return 'kpi_income';
      case KpiType.expense:
        return 'kpi_expense';
      case KpiType.net:
        return 'kpi_net';
      case KpiType.percentage:
        return 'kpi_percentage';
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getInsightIcon(String? iconName) {
    if (iconName == null) return Icons.info_outline;
    switch (iconName) {
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'warning':
        return Icons.warning;
      case 'check_circle':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info_outline;
    }
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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: config.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleDetailsTap(context),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabeçalho com ícone e título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: config.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              config.icon,
                              color: config.color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Removido Flexible - usar Text diretamente com overflow
                          Text(
                            label ?? config.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Valor principal
                  Text(
                    formattedValue,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: config.color,
                          fontSize: isMobile ? 20 : 22,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // Linha com mês anterior e variação - usar Wrap em vez de Row com Expanded
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Mês anterior
                      if (previousValue != null)
                        Text(
                          previousLabel!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      // Variação percentual
                      if (variation != null)
                        Tooltip(
                          message: variationLabel ?? '',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive ? Icons.trending_up : Icons.trending_down,
                                  size: 12,
                                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${variation!.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Insight (se disponível)
                  if (insight != null && insight!.widgetId == _getWidgetId()) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getInsightColor(insight!.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getInsightColor(insight!.type).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getInsightIcon(insight!.icon),
                            size: 14,
                            color: _getInsightColor(insight!.type),
                          ),
                          const SizedBox(width: 6),
                          // Removido Expanded - usar Flexible com fit loose ou Text diretamente
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              insight!.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getInsightColor(insight!.type),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Botão [Detalhes] mais compacto
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _handleDetailsTap(context),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        context.t('common.details'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: config.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
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
