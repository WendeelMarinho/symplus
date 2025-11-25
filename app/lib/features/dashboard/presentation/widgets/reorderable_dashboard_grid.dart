import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../providers/dashboard_layout_provider.dart';
import '../../data/models/dashboard_layout.dart';
import '../../data/models/dashboard_widget.dart';

/// Widget que gerencia a grid reordenável do dashboard
class ReorderableDashboardGrid extends ConsumerStatefulWidget {
  final Map<String, Widget> widgetMap;
  final DashboardLayout? layout;
  final Function(List<String>)? onLayoutChanged;

  const ReorderableDashboardGrid({
    super.key,
    required this.widgetMap,
    this.layout,
    this.onLayoutChanged,
  });

  @override
  ConsumerState<ReorderableDashboardGrid> createState() => _ReorderableDashboardGridState();
}

class _ReorderableDashboardGridState extends ConsumerState<ReorderableDashboardGrid> {
  @override
  void initState() {
    super.initState();
    // Atualizar ordem quando os widgets disponíveis mudam
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final availableIds = widget.widgetMap.keys.toList();
      ref.read(dashboardLayoutProvider.notifier).updateOrderWithAvailableIds(availableIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layoutState = ref.watch(dashboardLayoutProvider);
    final isMobile = ResponsiveUtils.isMobile(context);

    // Se temos um layout específico, usar ele; senão usar o layout provider antigo
    List<String> widgetOrder;
    if (widget.layout != null && widget.layout!.widgets.isNotEmpty) {
      // Filtrar widgets visíveis e ordenar pelo layout
      final visibleWidgets = widget.layout!.widgets
          .where((w) => w.visible && widget.widgetMap.containsKey(w.id))
          .toList();
      visibleWidgets.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
      widgetOrder = visibleWidgets.map((w) => w.id).toList();
      
      // Adicionar widgets que não estão no layout mas estão disponíveis
      for (final id in widget.widgetMap.keys) {
        if (!widgetOrder.contains(id)) {
          widgetOrder.add(id);
        }
      }
    } else {
      // Fallback: usar ordem do layout provider antigo
      if (layoutState.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      // Se não há ordem salva, usar ordem natural dos widgets
      widgetOrder = layoutState.widgetOrder.isEmpty 
          ? widget.widgetMap.keys.toList()
          : layoutState.widgetOrder;
    }

    // Ordenar widgets de acordo com a ordem
    var orderedWidgets = _getOrderedWidgets(widgetOrder, widget.widgetMap);
    var orderedIds = _getOrderedIds(widgetOrder, widget.widgetMap);

    // Garantir que temos widgets para exibir
    if (orderedWidgets.isEmpty && widget.widgetMap.isNotEmpty) {
      // Se não há ordem definida, usar ordem natural
      widgetOrder = widget.widgetMap.keys.toList();
      orderedWidgets = _getOrderedWidgets(widgetOrder, widget.widgetMap);
      orderedIds = _getOrderedIds(widgetOrder, widget.widgetMap);
    }

    // Se não há widgets, retornar widget vazio
    if (orderedWidgets.isEmpty) {
      return const Center(
        child: Text('Nenhum widget disponível'),
      );
    }

    // Para mobile: usar ReorderableListView (já é scrollável)
    if (isMobile) {
      return ReorderableListView(
        padding: EdgeInsets.zero,
        onReorder: (oldIndex, newIndex) {
          final newOrder = List<String>.from(orderedIds);
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = newOrder.removeAt(oldIndex);
          newOrder.insert(newIndex, item);
          
          if (widget.onLayoutChanged != null) {
            widget.onLayoutChanged!(newOrder);
          } else {
            ref.read(dashboardLayoutProvider.notifier).reorderWidgets(oldIndex, newIndex);
          }
        },
        children: orderedWidgets.asMap().entries.map((entry) {
          final index = entry.key;
          final widgetItem = entry.value;
          final widgetId = orderedIds[index];
          return Padding(
            key: ValueKey(widgetId),
            padding: EdgeInsets.only(
              left: ResponsiveUtils.getResponsivePadding(context).left,
              right: ResponsiveUtils.getResponsivePadding(context).right,
              bottom: 16,
              top: index == 0 ? ResponsiveUtils.getResponsivePadding(context).top : 0,
            ),
            child: widgetItem,
          );
        }).toList(),
      );
    }

    // Para desktop/tablet: usar SingleChildScrollView com Column/Wrap responsivo
    // Em vez de SliverGrid com childAspectRatio fixo, usar uma abordagem mais flexível
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 768 && width < 1200;
        final isDesktop = width >= 1200;
        
        // Calcular número de colunas baseado na largura disponível
        final crossAxisCount = isDesktop
            ? 3
            : isTablet
                ? 2
                : 1;

        // Usar SingleChildScrollView com Column para evitar problemas de constraints
        return SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Organizar widgets em linhas responsivas
                ..._buildResponsiveRows(
                  orderedWidgets,
                  orderedIds,
                  crossAxisCount,
                  width,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Constrói linhas responsivas de widgets
  List<Widget> _buildResponsiveRows(
    List<Widget> widgets,
    List<String> widgetIds,
    int crossAxisCount,
    double maxWidth,
  ) {
    if (crossAxisCount == 1) {
      // Uma coluna: retornar widgets em coluna simples
      return widgets.asMap().entries.map((entry) {
        final index = entry.key;
        final widgetItem = entry.value;
        return Padding(
          key: ValueKey(widgetIds[index]),
          padding: EdgeInsets.only(
            bottom: 16,
            top: index == 0 ? 0 : 0,
          ),
          child: widgetItem,
        );
      }).toList();
    }

    // Múltiplas colunas: agrupar widgets em linhas usando Expanded para evitar overflow
    final rows = <Widget>[];
    final spacing = 16.0;

    for (int i = 0; i < widgets.length; i += crossAxisCount) {
      final rowWidgets = <Widget>[];
      for (int j = 0; j < crossAxisCount && (i + j) < widgets.length; j++) {
        final index = i + j;
        rowWidgets.add(
          Expanded(
            child: Padding(
              key: ValueKey(widgetIds[index]),
              padding: EdgeInsets.only(
                right: j < crossAxisCount - 1 ? spacing : 0,
              ),
              child: widgets[index],
            ),
          ),
        );
      }
      
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: 16,
            top: i == 0 ? 0 : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowWidgets,
          ),
        ),
      );
    }

    return rows;
  }

  /// Retorna os widgets na ordem especificada
  List<Widget> _getOrderedWidgets(
    List<String> order,
    Map<String, Widget> widgetMap,
  ) {
    final ordered = <Widget>[];
    final usedIds = <String>{};

    // Adicionar widgets na ordem especificada
    for (final id in order) {
      if (widgetMap.containsKey(id) && !usedIds.contains(id)) {
        ordered.add(widgetMap[id]!);
        usedIds.add(id);
      }
    }

    // Adicionar widgets que não estavam na ordem (novos widgets)
    for (final entry in widgetMap.entries) {
      if (!usedIds.contains(entry.key)) {
        ordered.add(entry.value);
      }
    }

    return ordered;
  }

  /// Retorna os IDs na ordem especificada (para usar como keys)
  List<String> _getOrderedIds(
    List<String> order,
    Map<String, Widget> widgetMap,
  ) {
    final ordered = <String>[];
    final usedIds = <String>{};

    // Adicionar IDs na ordem especificada
    for (final id in order) {
      if (widgetMap.containsKey(id) && !usedIds.contains(id)) {
        ordered.add(id);
        usedIds.add(id);
      }
    }

    // Adicionar IDs que não estavam na ordem (novos widgets)
    for (final entry in widgetMap.entries) {
      if (!usedIds.contains(entry.key)) {
        ordered.add(entry.key);
      }
    }

    return ordered;
  }
}
