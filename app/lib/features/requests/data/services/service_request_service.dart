import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class ServiceRequestService {
  /// Lista todos os tickets
  static Future<Response> list({
    String? status,
    String? priority,
    String? category,
    int? assignedTo,
    int? createdBy,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) {
      queryParams['status'] = status;
    }
    if (priority != null) {
      queryParams['priority'] = priority;
    }
    if (category != null) {
      queryParams['category'] = category;
    }
    if (assignedTo != null) {
      queryParams['assigned_to'] = assignedTo;
    }
    if (createdBy != null) {
      queryParams['created_by'] = createdBy;
    }
    if (page != null) {
      queryParams['page'] = page;
    }
    if (perPage != null) {
      queryParams['per_page'] = perPage;
    }

    return await DioClient.get(
      ApiConfig.serviceRequests,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Obtém um ticket específico
  static Future<Response> get(int id) async {
    return await DioClient.get('${ApiConfig.serviceRequests}/$id');
  }

  /// Cria um novo ticket
  static Future<Response> create({
    required String title,
    required String description,
    String? priority,
    String? category,
    int? assignedTo,
  }) async {
    return await DioClient.post(
      ApiConfig.serviceRequests,
      data: {
        'title': title,
        'description': description,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
        if (assignedTo != null) 'assigned_to': assignedTo,
      },
    );
  }

  /// Atualiza um ticket
  static Future<Response> update(
    int id, {
    String? title,
    String? description,
    String? status,
    String? priority,
    String? category,
    int? assignedTo,
  }) async {
    return await DioClient.put(
      '${ApiConfig.serviceRequests}/$id',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
        if (assignedTo != null) 'assigned_to': assignedTo,
      },
    );
  }

  /// Marca ticket como em progresso
  static Future<Response> markInProgress(int id) async {
    return await DioClient.post('${ApiConfig.serviceRequests}/$id/mark-in-progress');
  }

  /// Marca ticket como resolvido
  static Future<Response> markResolved(int id) async {
    return await DioClient.post('${ApiConfig.serviceRequests}/$id/mark-resolved');
  }

  /// Marca ticket como fechado
  static Future<Response> markClosed(int id) async {
    return await DioClient.post('${ApiConfig.serviceRequests}/$id/mark-closed');
  }

  /// Deleta um ticket
  static Future<Response> delete(int id) async {
    return await DioClient.delete('${ApiConfig.serviceRequests}/$id');
  }

  /// Adiciona comentário ao ticket
  static Future<Response> addComment(
    int serviceRequestId, {
    required String comment,
    bool isInternal = false,
  }) async {
    return await DioClient.post(
      '${ApiConfig.serviceRequests}/$serviceRequestId/comments',
      data: {
        'comment': comment,
        'is_internal': isInternal,
      },
    );
  }

  /// Atualiza comentário
  static Future<Response> updateComment(
    int serviceRequestId,
    int commentId, {
    required String comment,
  }) async {
    return await DioClient.put(
      '${ApiConfig.serviceRequests}/$serviceRequestId/comments/$commentId',
      data: {
        'comment': comment,
      },
    );
  }

  /// Deleta comentário
  static Future<Response> deleteComment(int serviceRequestId, int commentId) async {
    return await DioClient.delete(
      '${ApiConfig.serviceRequests}/$serviceRequestId/comments/$commentId',
    );
  }
}

