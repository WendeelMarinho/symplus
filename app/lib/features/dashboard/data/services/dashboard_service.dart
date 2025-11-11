import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  static Future<DashboardData> getDashboard() async {
    try {
      final response = await DioClient.get(ApiConfig.dashboard);

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

