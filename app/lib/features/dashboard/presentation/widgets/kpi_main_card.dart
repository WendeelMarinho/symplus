import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../data/models/dashboard_layout.dart';

/// Tipo de KPI principal
enum KpiType {
  income, // Entrada (verde)
  expense, // Saída (vermelho)
  net, // Resultado (azul)
  percentage, // Percentual (amarelo)
}

/// Configuração visual do KPI
class _KpiConfig {
  final Color color;
  final IconData icon;
  final String title;
  
  const _KpiConfig({
    required this.color,
    required this.icon,
    required this.title,
  });
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
  _KpiConfig _getConfig(BuildContext context) {
    switch (type) {
      case KpiType.income:
        return _KpiConfig(
          color: AppColors.income,
          icon: Icons.trending_up,
          title: context.t('dashboard.kpi.income'),
        );
      case KpiType.expense:
        return _KpiConfig(
          color: AppColors.expense,
          icon: Icons.trending_down,
          title: context.t('dashboard.kpi.expense'),
        );
      case KpiType.net:
        return _KpiConfig(
          color: AppColors.info,
          icon: Icons.account_balance,
          title: context.t('dashboard.kpi.net'),
        );
      case KpiType.percentage:
        return _KpiConfig(
          color: AppColors.warning,
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
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.info;
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          border: Border.all(
            color: config.color.withOpacity(0.2),
            width: AppBorders.borderWidth,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppBorders.cardRadius),
            onTap: () => _handleDetailsTap(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 220,
                minHeight: 180,
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho: ícone + título
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: config.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                          ),
                          child: Icon(
                            config.icon,
                            color: config.color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            label ?? config.title,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Valor principal (compacto)
                    Text(
                      formattedValue,
                      style: AppTypography.kpiValue.copyWith(
                        fontSize: isMobile ? 20 : 22,
                        color: config.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Mês anterior + variação
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Mês anterior
                        if (previousValue != null)
                          Text(
                            previousLabel!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        // Variação percentual
                        if (variation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive ? Icons.trending_up : Icons.trending_down,
                                  size: 12,
                                  color: isPositive ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${variation!.abs().toStringAsFixed(1)}%',
                                  style: AppTypography.caption.copyWith(
                                    color: isPositive ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Insight (se disponível)
                    if (insight != null && insight!.widgetId == _getWidgetId()) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getInsightColor(insight!.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                          border: Border.all(
                            color: _getInsightColor(insight!.type).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getInsightIcon(insight!.icon),
                              size: 14,
                              color: _getInsightColor(insight!.type),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                insight!.message,
                                style: AppTypography.caption.copyWith(
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
                    const SizedBox(height: AppSpacing.md),
                    // Botão [Detalhes] compacto
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _handleDetailsTap(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: config.color,
                          side: BorderSide(color: config.color, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.t('common.details'),
                              style: AppTypography.label,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: config.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
