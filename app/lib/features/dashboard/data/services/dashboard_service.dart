import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  /// Busca dados do dashboard
  /// 
  /// [from] e [to] são opcionais - se não fornecidos, o backend retorna dados padrão
  static Future<DashboardData> getDashboard({
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
        ApiConfig.dashboard,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return DashboardData.fromJson(data);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
}

