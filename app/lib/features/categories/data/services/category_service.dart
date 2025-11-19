import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class CategoryService {
  /// Lista todas as categorias
  static Future<Response> list({
    String? type,
    String? search,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) {
      queryParams['type'] = type;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (page != null) {
      queryParams['page'] = page;
    }
    if (perPage != null) {
      queryParams['per_page'] = perPage;
    }

    return await DioClient.get(
      ApiConfig.categories,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Obtém uma categoria específica
  static Future<Response> get(int id) async {
    return await DioClient.get('${ApiConfig.categories}/$id');
  }

  /// Cria uma nova categoria
  static Future<Response> create({
    required String type,
    required String name,
    String? color,
  }) async {
    return await DioClient.post(
      ApiConfig.categories,
      data: {
        'type': type,
        'name': name,
        if (color != null) 'color': color,
      },
    );
  }

  /// Atualiza uma categoria
  static Future<Response> update(
    int id, {
    String? type,
    String? name,
    String? color,
  }) async {
    return await DioClient.put(
      '${ApiConfig.categories}/$id',
      data: {
        if (type != null) 'type': type,
        if (name != null) 'name': name,
        if (color != null) 'color': color,
      },
    );
  }

  /// Deleta uma categoria
  static Future<Response> delete(int id) async {
    return await DioClient.delete('${ApiConfig.categories}/$id');
  }
}

