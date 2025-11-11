import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class ReportService {
  /// Gera relatório P&L
  static Future<Response> generatePl({
    required DateTime from,
    required DateTime to,
    String? groupBy, // 'category' ou 'month'
  }) async {
    final queryParams = <String, dynamic>{
      'from': from.toIso8601String().split('T')[0], // YYYY-MM-DD
      'to': to.toIso8601String().split('T')[0],
    };
    if (groupBy != null) {
      queryParams['group_by'] = groupBy;
    }

    return await DioClient.get(
      '${ApiConfig.reports}/pl',
      queryParameters: queryParams,
    );
  }
}

