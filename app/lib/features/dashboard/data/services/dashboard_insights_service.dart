import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';
import '../models/dashboard_layout.dart';

/// Serviço para buscar insights do dashboard
class DashboardInsightsService {
  /// Busca insights para os widgets do dashboard
  /// 
  /// [from] e [to] são opcionais - se não fornecidos, o backend retorna insights padrão
  static Future<List<DashboardInsight>> getInsights({
    String? from,
    String? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = from;
      }
      if (to != null) {
        queryParams['to'] = to;
      }

      final response = await DioClient.get(
        ApiConfig.dashboardInsights,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((e) => DashboardInsight.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load insights');
      }
    } on DioException catch (e) {
      // Se a API não estiver disponível, retorna lista vazia (fallback)
      if (e.response?.statusCode == 404 || e.response == null) {
        return [];
      }
      rethrow;
    } catch (e) {
      // Qualquer outro erro também retorna lista vazia (não quebra o dashboard)
      return [];
    }
  }
}

