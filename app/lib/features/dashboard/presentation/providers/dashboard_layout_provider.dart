import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/dashboard_layout_service.dart';

/// Estado da ordem dos widgets do dashboard
class DashboardLayoutState {
  final List<String> widgetOrder;
  final bool isLoading;

  DashboardLayoutState({
    required this.widgetOrder,
    this.isLoading = false,
  });

  DashboardLayoutState copyWith({
    List<String>? widgetOrder,
    bool? isLoading,
  }) {
    return DashboardLayoutState(
      widgetOrder: widgetOrder ?? this.widgetOrder,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider para gerenciar a ordem dos widgets do dashboard
class DashboardLayoutNotifier extends StateNotifier<DashboardLayoutState> {
  DashboardLayoutNotifier() : super(DashboardLayoutState(widgetOrder: [])) {
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    state = state.copyWith(isLoading: true);
    final order = await DashboardLayoutService.getOrder();
    state = DashboardLayoutState(widgetOrder: order, isLoading: false);
  }

  /// Reordena os widgets
  /// 
  /// [oldIndex] e [newIndex] são os índices na lista ordenada atual
  Future<void> reorderWidgets(int oldIndex, int newIndex) async {
    // Ajustar newIndex se necessário (ReorderableListView já faz isso, mas garantimos)
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final newOrder = List<String>.from(state.widgetOrder);
    
    // Validar índices
    if (oldIndex < 0 || oldIndex >= newOrder.length || 
        newIndex < 0 || newIndex >= newOrder.length) {
      return;
    }
    
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    
    state = state.copyWith(widgetOrder: newOrder);
    await DashboardLayoutService.saveOrder(newOrder);
  }
  
  /// Atualiza a ordem dos widgets com base nos IDs disponíveis
  /// 
  /// Remove IDs que não existem mais e adiciona novos IDs no final
  Future<void> updateOrderWithAvailableIds(List<String> availableIds) async {
    final currentOrder = List<String>.from(state.widgetOrder);
    final newOrder = <String>[];
    final usedIds = <String>{};
    
    // Manter ordem dos IDs existentes
    for (final id in currentOrder) {
      if (availableIds.contains(id) && !usedIds.contains(id)) {
        newOrder.add(id);
        usedIds.add(id);
      }
    }
    
    // Adicionar novos IDs no final
    for (final id in availableIds) {
      if (!usedIds.contains(id)) {
        newOrder.add(id);
      }
    }
    
    if (newOrder != currentOrder) {
      state = state.copyWith(widgetOrder: newOrder);
      await DashboardLayoutService.saveOrder(newOrder);
    }
  }

  /// Reseta a ordem para o padrão
  Future<void> resetOrder() async {
    await DashboardLayoutService.resetOrder();
    await _loadOrder();
  }
}

/// Provider do estado do layout
final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, DashboardLayoutState>(
  (ref) => DashboardLayoutNotifier(),
);

