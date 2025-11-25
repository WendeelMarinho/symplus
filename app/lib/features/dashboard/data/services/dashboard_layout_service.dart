import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';
import '../models/dashboard_layout.dart';
import '../models/dashboard_widget.dart';

/// Serviço para gerenciar layouts e templates do dashboard
class DashboardLayoutService {
  /// Busca o layout salvo do usuário/organização para uma visão específica
  /// Se não encontrar (404), faz fallback automático para o template padrão
  static Future<DashboardLayout?> getLayout({
    required DashboardView view,
  }) async {
    try {
      final response = await DioClient.get(
        ApiConfig.dashboardLayout,
        queryParameters: {'view': view.value},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return DashboardLayout.fromJson(data as Map<String, dynamic>);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Layout não encontrado - fazer fallback automático para template
        try {
          final template = await getTemplate(view: view);
          return template;
        } catch (templateError) {
          // Se falhar ao buscar template, usar template local padrão
          return getDefaultTemplate(view);
        }
      }
      // Para outros erros, retornar null e deixar o provider tratar
      return null;
    } catch (e) {
      // Em caso de erro inesperado, retornar null
      return null;
    }
  }

  /// Salva o layout personalizado do usuário/organização
  static Future<DashboardLayout> saveLayout({
    required DashboardLayout layout,
  }) async {
    try {
      final response = await DioClient.put(
        ApiConfig.dashboardLayout,
        data: layout.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>;
        return DashboardLayout.fromJson(data);
      } else {
        throw Exception('Failed to save layout');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Busca templates disponíveis
  static Future<List<DashboardLayout>> getTemplates() async {
    try {
      final response = await DioClient.get(ApiConfig.dashboardTemplates);

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((e) => DashboardLayout.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load templates');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Busca template padrão para uma visão específica
  /// Primeiro tenta buscar do backend, se falhar usa template local
  static Future<DashboardLayout> getTemplate({
    required DashboardView view,
  }) async {
    try {
      final templates = await getTemplates();
      final template = templates.firstWhere(
        (t) => t.view == view && t.isTemplate,
        orElse: () => getDefaultTemplate(view),
      );
      return template;
    } catch (e) {
      // Se falhar ao buscar templates do backend, usar template local padrão
      return getDefaultTemplate(view);
    }
  }

  /// Template padrão local (fallback se backend não estiver disponível)
  static DashboardLayout getDefaultTemplate(DashboardView view) {
    switch (view) {
      case DashboardView.cash:
        return DashboardLayout(
          view: view,
          isTemplate: true,
          widgets: [
            DashboardWidget(id: 'kpi_cards', type: 'kpi', defaultSpan: 12, defaultOrder: 1),
            DashboardWidget(id: 'account_balances', type: 'account', defaultSpan: 6, defaultOrder: 2),
            DashboardWidget(id: 'cash_flow_chart', type: 'chart', defaultSpan: 6, defaultOrder: 3),
            DashboardWidget(id: 'alerts_recent', type: 'alert', defaultSpan: 12, defaultOrder: 4),
            DashboardWidget(id: 'calendar', type: 'calendar', defaultSpan: 12, defaultOrder: 5),
          ],
        );
      case DashboardView.result:
        return DashboardLayout(
          view: view,
          isTemplate: true,
          widgets: [
            DashboardWidget(id: 'kpi_cards', type: 'kpi', defaultSpan: 12, defaultOrder: 1),
            DashboardWidget(id: 'custom_indicators', type: 'indicator', defaultSpan: 12, defaultOrder: 2),
            DashboardWidget(id: 'charts_pl', type: 'chart', defaultSpan: 6, defaultOrder: 3),
            DashboardWidget(id: 'charts_categories', type: 'chart', defaultSpan: 6, defaultOrder: 4),
            DashboardWidget(id: 'quarterly_summary', type: 'summary', defaultSpan: 12, defaultOrder: 5),
          ],
        );
      case DashboardView.collection:
        return DashboardLayout(
          view: view,
          isTemplate: true,
          widgets: [
            DashboardWidget(id: 'kpi_collection', type: 'kpi', defaultSpan: 12, defaultOrder: 1),
            DashboardWidget(id: 'alerts_recent', type: 'alert', defaultSpan: 12, defaultOrder: 2),
            DashboardWidget(id: 'calendar', type: 'calendar', defaultSpan: 12, defaultOrder: 3),
          ],
        );
    }
  }

  // Métodos de compatibilidade com o sistema antigo (usando shared_preferences)
  // TODO: Migrar para usar o novo sistema de layouts quando possível

  /// Busca a ordem dos widgets salva localmente (compatibilidade)
  static Future<List<String>> getOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderJson = prefs.getString('dashboard_widget_order');
      if (orderJson != null) {
        // Assumindo que é uma lista JSON simples
        // Se for necessário, pode usar json.decode
        return orderJson.split(',').where((s) => s.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Salva a ordem dos widgets localmente (compatibilidade)
  static Future<void> saveOrder(List<String> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_widget_order', order.join(','));
    } catch (e) {
      // Silently fail
    }
  }

  /// Reseta a ordem para o padrão (compatibilidade)
  static Future<void> resetOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dashboard_widget_order');
    } catch (e) {
      // Silently fail
    }
  }
}
