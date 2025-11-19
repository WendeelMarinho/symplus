import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class DueItemService {
  /// Lista todos os vencimentos
  static Future<Response> list({
    String? status,
    String? type,
    int? accountId,
    int? categoryId,
    String? from,
    String? to,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) {
      queryParams['status'] = status;
    }
    if (type != null) {
      queryParams['type'] = type;
    }
    if (accountId != null) {
      queryParams['account_id'] = accountId;
    }
    if (categoryId != null) {
      queryParams['category_id'] = categoryId;
    }
    if (from != null) {
      queryParams['from'] = from;
    }
    if (to != null) {
      queryParams['to'] = to;
    }
    if (page != null) {
      queryParams['page'] = page;
    }
    if (perPage != null) {
      queryParams['per_page'] = perPage;
    }

    return await DioClient.get(
      ApiConfig.dueItems,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Obtém um vencimento específico
  static Future<Response> get(int id) async {
    return await DioClient.get('${ApiConfig.dueItems}/$id');
  }

  /// Cria um novo vencimento
  static Future<Response> create({
    required String title,
    required double amount,
    required DateTime dueDate,
    required String type,
    String? description,
  }) async {
    return await DioClient.post(
      ApiConfig.dueItems,
      data: {
        'title': title,
        'amount': amount,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'type': type,
        if (description != null) 'description': description,
      },
    );
  }

  /// Atualiza um vencimento
  static Future<Response> update(
    int id, {
    String? title,
    double? amount,
    DateTime? dueDate,
    String? type,
    String? status,
    String? description,
  }) async {
    return await DioClient.put(
      '${ApiConfig.dueItems}/$id',
      data: {
        if (title != null) 'title': title,
        if (amount != null) 'amount': amount,
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T')[0],
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
      },
    );
  }

  /// Marca um vencimento como pago
  static Future<Response> markPaid(int id) async {
    return await DioClient.post('${ApiConfig.dueItems}/$id/mark-paid');
  }

  /// Deleta um vencimento
  static Future<Response> delete(int id) async {
    return await DioClient.delete('${ApiConfig.dueItems}/$id');
  }
}

