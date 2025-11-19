import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/period_filter_provider.dart';
import '../accessibility/responsive_utils.dart';
import '../accessibility/telemetry_service.dart';
import '../l10n/app_localizations.dart';

/// Widget reutilizável para filtro de período
/// 
/// Exibe um PopupMenuButton com opções de período e integra com o provider
/// global para compartilhar o estado em todo o dashboard.
class PeriodFilter extends ConsumerWidget {
  final bool showLabel;
  final EdgeInsets? padding;

  const PeriodFilter({
    super.key,
    this.showLabel = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodState = ref.watch(periodFilterProvider);
    final isMobile = ResponsiveUtils.isMobile(context);

    return PopupMenuButton<PeriodType>(
      tooltip: context.t('period_filter.title'),
      padding: padding ?? EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            if (showLabel && !isMobile) ...[
              const SizedBox(width: 8),
              Text(
                periodState.displayLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
      onSelected: (type) {
        if (type == PeriodType.custom) {
          _showCustomPeriodDialog(context, ref);
        } else {
          ref.read(periodFilterProvider.notifier).setPeriod(type);
          TelemetryService.logAction(
            'period_filter.changed',
            metadata: {'type': type.name},
          );
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          PeriodType.thisWeek,
          Icons.view_week,
          context.t('period_filter.this_week'),
          periodState.type == PeriodType.thisWeek,
        ),
        _buildMenuItem(
          context,
          PeriodType.thisMonth,
          Icons.calendar_month,
          context.t('period_filter.this_month'),
          periodState.type == PeriodType.thisMonth,
        ),
        _buildMenuItem(
          context,
          PeriodType.lastMonth,
          Icons.calendar_view_month,
          context.t('period_filter.last_month'),
          periodState.type == PeriodType.lastMonth,
        ),
        _buildMenuItem(
          context,
          PeriodType.quarter,
          Icons.view_quilt,
          context.t('period_filter.quarter'),
          periodState.type == PeriodType.quarter,
        ),
        _buildMenuItem(
          context,
          PeriodType.semester,
          Icons.view_module,
          context.t('period_filter.semester'),
          periodState.type == PeriodType.semester,
        ),
        _buildMenuItem(
          context,
          PeriodType.year,
          Icons.calendar_view_year,
          context.t('period_filter.year'),
          periodState.type == PeriodType.year,
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          context,
          PeriodType.custom,
          Icons.date_range,
          context.t('period_filter.custom'),
          periodState.type == PeriodType.custom,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    PeriodType type,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return PopupMenuItem<PeriodType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  /// Diálogo para selecionar período customizado
  Future<void> _showCustomPeriodDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentState = ref.read(periodFilterProvider);
    DateTime from = currentState.from ??
        DateTime.now().subtract(const Duration(days: 30));
    DateTime to = currentState.to ?? DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Período Personalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Data inicial'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy', 'pt_BR').format(from),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: from,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  locale: const Locale('pt', 'BR'),
                );
                if (date != null && context.mounted) {
                  from = date;
                  // Atualizar o diálogo
                  Navigator.of(context).pop();
                  _showCustomPeriodDialog(context, ref);
                }
              },
            ),
            ListTile(
              title: const Text('Data final'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy', 'pt_BR').format(to),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: to,
                  firstDate: from,
                  lastDate: DateTime.now(),
                  locale: const Locale('pt', 'BR'),
                );
                if (date != null && context.mounted) {
                  to = date;
                  // Atualizar o diálogo
                  Navigator.of(context).pop();
                  _showCustomPeriodDialog(context, ref);
                }
              },
            ),
            if (from.isAfter(to))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'A data inicial não pode ser posterior à data final',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: from.isAfter(to)
                ? null
                : () => Navigator.of(context).pop(true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      ref.read(periodFilterProvider.notifier).setCustomPeriod(from, to);
      TelemetryService.logAction(
        'period_filter.custom_set',
        metadata: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
      );
    }
  }
}

