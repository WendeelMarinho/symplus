import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../../core/providers/period_filter_provider.dart';
import '../providers/custom_indicator_provider.dart';
import '../widgets/custom_indicator_card.dart';
import '../widgets/custom_indicator_dialog.dart';

/// Seção de Indicadores Personalizados para o Dashboard
class CustomIndicatorsSection extends ConsumerWidget {
  const CustomIndicatorsSection({super.key});

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CustomIndicatorDialog(),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(customIndicatorsProvider.notifier).create(
              name: result['name'] as String,
              categoryIds: result['categoryIds'] as List<int>,
            );
        if (context.mounted) {
          ToastService.showSuccess(context, 'Indicador criado com sucesso');
          TelemetryService.logAction('custom_indicator.created');
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.showError(context, 'Erro ao criar indicador: $e');
        }
      }
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    indicator,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CustomIndicatorDialog(indicator: indicator),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(customIndicatorsProvider.notifier).update(
              indicator.id,
              name: result['name'] as String,
              categoryIds: result['categoryIds'] as List<int>,
            );
        if (context.mounted) {
          ToastService.showSuccess(context, 'Indicador atualizado com sucesso');
          TelemetryService.logAction('custom_indicator.updated');
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.showError(context, 'Erro ao atualizar indicador: $e');
        }
      }
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    indicator,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir Indicador',
      message: 'Deseja realmente excluir o indicador "${indicator.name}"?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(customIndicatorsProvider.notifier).delete(indicator.id);
        if (context.mounted) {
          ToastService.showSuccess(context, 'Indicador excluído com sucesso');
          TelemetryService.logAction('custom_indicator.deleted');
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.showError(context, 'Erro ao excluir indicador: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customIndicatorsProvider);
    final isMobile = ResponsiveUtils.isMobile(context);

    // Observar mudanças no período e recarregar
    ref.listen<PeriodFilterState>(
      periodFilterProvider,
      (previous, next) {
        if (previous != next) {
          ref.read(customIndicatorsProvider.notifier).load();
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com título e botão criar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Indicadores Personalizados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Criar Indicador'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Conteúdo
        if (state.isLoading)
          const LoadingState()
        else if (state.error != null)
          ErrorState(
            message: state.error!,
            onRetry: () => ref.read(customIndicatorsProvider.notifier).load(),
          )
        else if (state.indicators.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum indicador personalizado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie indicadores para agrupar categorias e acompanhar seus gastos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Primeiro Indicador'),
                  ),
                ],
              ),
            ),
          )
        else
          // Grid de indicadores
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.2 : 1.1,
            ),
            itemCount: state.indicators.length,
            itemBuilder: (context, index) {
              final indicator = state.indicators[index];
              return CustomIndicatorCard(
                indicator: indicator,
                onEdit: () => _showEditDialog(context, ref, indicator),
                onDelete: () => _handleDelete(context, ref, indicator),
                onDetails: () {
                  context.go('/app/custom-indicators/${indicator.id}');
                },
              );
            },
          ),
      ],
    );
  }
}

