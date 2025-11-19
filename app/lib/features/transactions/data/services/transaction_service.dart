import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class TransactionService {
  /// Lista transações com filtros
  static Future<Response> list({
    String? type,
    int? accountId,
    int? categoryId,
    String? from,
    String? to,
    String? search,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (accountId != null) queryParams['account_id'] = accountId;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page;

    return await DioClient.get(
      ApiConfig.transactions,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Obtém uma transação por ID
  static Future<Response> get(int id) async {
    return await DioClient.get('${ApiConfig.transactions}/$id');
  }

  /// Cria uma nova transação
  static Future<Response> create({
    required int accountId,
    int? categoryId,
    required String type,
    required double amount,
    required DateTime occurredAt,
    required String description,
    String? attachmentPath,
  }) async {
    return await DioClient.post(
      ApiConfig.transactions,
      data: {
        'account_id': accountId,
        if (categoryId != null) 'category_id': categoryId,
        'type': type,
        'amount': amount,
        'occurred_at': occurredAt.toIso8601String(),
        'description': description,
        if (attachmentPath != null) 'attachment_path': attachmentPath,
      },
    );
  }

  /// Atualiza uma transação
  static Future<Response> update(
    int id, {
    int? accountId,
    int? categoryId,
    String? type,
    double? amount,
    DateTime? occurredAt,
    String? description,
  }) async {
    return await DioClient.put(
      '${ApiConfig.transactions}/$id',
      data: {
        if (accountId != null) 'account_id': accountId,
        if (categoryId != null) 'category_id': categoryId,
        if (type != null) 'type': type,
        if (amount != null) 'amount': amount,
        if (occurredAt != null) 'occurred_at': occurredAt.toIso8601String(),
        if (description != null) 'description': description,
      },
    );
  }

  /// Deleta uma transação
  static Future<Response> delete(int id) async {
    return await DioClient.delete('${ApiConfig.transactions}/$id');
  }
}

