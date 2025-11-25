import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_widget.dart';
import '../providers/dashboard_view_provider.dart';
import '../../../../core/accessibility/telemetry_service.dart';

/// Widget para selecionar a visão do dashboard (Caixa/Resultado/Cobrança)
class DashboardViewSelector extends ConsumerWidget {
  final bool isMobile;

  const DashboardViewSelector({
    super.key,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(dashboardViewProvider);
    final viewNotifier = ref.read(dashboardViewProvider.notifier);

    if (isMobile) {
      // Mobile: dropdown
      return DropdownButton<DashboardView>(
        value: viewState.selectedView,
        isDense: true,
        underline: const SizedBox.shrink(),
        items: DashboardView.values.map((view) {
          return DropdownMenuItem<DashboardView>(
            value: view,
            child: Text(
              view.label,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (view) {
          if (view != null) {
            TelemetryService.logAction(
              'dashboard.view_changed',
              metadata: {'view': view.value},
            );
            viewNotifier.setView(view);
          }
        },
      );
    }

    // Desktop: segmented control
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DashboardView.values.map((view) {
          final isSelected = viewState.selectedView == view;
          return GestureDetector(
            onTap: () {
              TelemetryService.logAction(
                'dashboard.view_changed',
                metadata: {'view': view.value},
              );
              viewNotifier.setView(view);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                view.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

