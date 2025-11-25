import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/dashboard_widget.dart';
import '../../data/models/dashboard_layout.dart';
import '../../data/services/dashboard_layout_service.dart';

/// Estado da visão e layout do dashboard
class DashboardViewState {
  final DashboardView selectedView;
  final DashboardLayout? currentLayout;
  final bool isLoading;
  final String? error;

  DashboardViewState({
    required this.selectedView,
    this.currentLayout,
    this.isLoading = false,
    this.error,
  });

  DashboardViewState copyWith({
    DashboardView? selectedView,
    DashboardLayout? currentLayout,
    bool? isLoading,
    String? error,
  }) {
    return DashboardViewState(
      selectedView: selectedView ?? this.selectedView,
      currentLayout: currentLayout ?? this.currentLayout,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider para gerenciar a visão e layout do dashboard
class DashboardViewNotifier extends StateNotifier<DashboardViewState> {
  DashboardViewNotifier() : super(DashboardViewState(selectedView: DashboardView.cash)) {
    _loadView();
  }

  /// Carrega a visão salva do usuário
  Future<void> _loadView() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedView = prefs.getString('dashboard_view');
      final view = savedView != null
          ? DashboardView.fromString(savedView)
          : DashboardView.cash;

      state = state.copyWith(selectedView: view);
      await _loadLayout();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Carrega o layout para a visão atual
  /// O serviço já faz fallback automático para templates em caso de 404
  Future<void> _loadLayout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Tenta carregar layout salvo do backend
      // O serviço já faz fallback automático para template se retornar 404
      final layout = await DashboardLayoutService.getLayout(
        view: state.selectedView,
      );

      if (layout != null) {
        state = state.copyWith(
          currentLayout: layout,
          isLoading: false,
        );
      } else {
        // Se ainda assim retornar null, usar template padrão local
        final template = DashboardLayoutService.getDefaultTemplate(state.selectedView);
        state = state.copyWith(
          currentLayout: template,
          isLoading: false,
        );
      }
    } catch (e) {
      // Em caso de erro inesperado, usa template padrão local
      final template = DashboardLayoutService.getDefaultTemplate(state.selectedView);
      state = state.copyWith(
        currentLayout: template,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Altera a visão do dashboard
  Future<void> setView(DashboardView view) async {
    if (view == state.selectedView) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_view', view.value);

      state = state.copyWith(selectedView: view);
      await _loadLayout();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Salva o layout personalizado
  Future<void> saveLayout(DashboardLayout layout) async {
    state = state.copyWith(isLoading: true);

    try {
      final savedLayout = await DashboardLayoutService.saveLayout(layout: layout);
      state = state.copyWith(
        currentLayout: savedLayout,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Atualiza a ordem dos widgets no layout atual
  Future<void> updateWidgetOrder(List<String> widgetIds) async {
    final currentLayout = state.currentLayout;
    if (currentLayout == null) return;

    // Cria nova lista de widgets na ordem especificada
    final orderedWidgets = <DashboardWidget>[];
    final existingWidgets = Map.fromEntries(
      currentLayout.widgets.map((w) => MapEntry(w.id, w)),
    );

    // Adiciona widgets na ordem especificada, atualizando defaultOrder
    for (int i = 0; i < widgetIds.length; i++) {
      final id = widgetIds[i];
      if (existingWidgets.containsKey(id)) {
        final widget = existingWidgets[id]!;
        orderedWidgets.add(DashboardWidget(
          id: widget.id,
          type: widget.type,
          defaultSpan: widget.defaultSpan,
          defaultOrder: i + 1, // Atualizar ordem baseado na posição
          visible: widget.visible,
          metadata: widget.metadata,
        ));
      }
    }

    // Adiciona widgets que não estavam na lista (novos widgets)
    int nextOrder = widgetIds.length + 1;
    for (final widget in currentLayout.widgets) {
      if (!widgetIds.contains(widget.id)) {
        orderedWidgets.add(DashboardWidget(
          id: widget.id,
          type: widget.type,
          defaultSpan: widget.defaultSpan,
          defaultOrder: nextOrder++,
          visible: widget.visible,
          metadata: widget.metadata,
        ));
      }
    }

    final updatedLayout = DashboardLayout(
      id: currentLayout.id,
      view: currentLayout.view,
      widgets: orderedWidgets,
      isTemplate: false,
      updatedAt: DateTime.now(),
    );

    await saveLayout(updatedLayout);
  }
}

/// Provider do estado da visão
final dashboardViewProvider =
    StateNotifierProvider<DashboardViewNotifier, DashboardViewState>(
  (ref) => DashboardViewNotifier(),
);

