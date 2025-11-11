import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class AccountService {
  /// Lista todas as contas
  static Future<Response> list({
    String? search,
    String? type,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
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
      ApiConfig.accounts,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Obtém uma conta específica
  static Future<Response> get(int id) async {
    return await DioClient.get('${ApiConfig.accounts}/$id');
  }

  /// Cria uma nova conta
  static Future<Response> create({
    required String name,
    required String currency,
    double? openingBalance,
  }) async {
    return await DioClient.post(
      ApiConfig.accounts,
      data: {
        'name': name,
        'currency': currency,
        if (openingBalance != null) 'opening_balance': openingBalance,
      },
    );
  }

  /// Atualiza uma conta
  static Future<Response> update(
    int id, {
    String? name,
    String? currency,
    double? openingBalance,
  }) async {
    return await DioClient.put(
      '${ApiConfig.accounts}/$id',
      data: {
        if (name != null) 'name': name,
        if (currency != null) 'currency': currency,
        if (openingBalance != null) 'opening_balance': openingBalance,
      },
    );
  }

  /// Deleta uma conta
  static Future<Response> delete(int id) async {
    return await DioClient.delete('${ApiConfig.accounts}/$id');
  }
}

