import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class NotificationService {
  /// Lista todas as notificações
  static Future<Response> list({
    bool? read,
    String? type,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (read != null) {
      queryParams['read'] = read;
    }
    if (type != null) {
      queryParams['type'] = type;
    }
    if (page != null) {
      queryParams['page'] = page;
    }
    if (perPage != null) {
      queryParams['per_page'] = perPage;
    }

    return await DioClient.get(
      ApiConfig.notifications,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Obtém a contagem de notificações não lidas
  static Future<Response> unreadCount() async {
    return await DioClient.get('${ApiConfig.notifications}/unread-count');
  }

  /// Marca uma notificação como lida
  static Future<Response> markAsRead(String id) async {
    return await DioClient.post('${ApiConfig.notifications}/$id/mark-as-read');
  }

  /// Marca todas as notificações como lidas
  static Future<Response> markAllAsRead() async {
    return await DioClient.post('${ApiConfig.notifications}/mark-all-as-read');
  }

  /// Deleta uma notificação
  static Future<Response> delete(String id) async {
    return await DioClient.delete('${ApiConfig.notifications}/$id');
  }
}

