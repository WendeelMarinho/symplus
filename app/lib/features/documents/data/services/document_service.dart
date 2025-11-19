import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class DocumentService {
  /// Lista todos os documentos
  static Future<Response> list({
    String? category,
    String? documentableType,
    int? documentableId,
    String? search,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) {
      queryParams['category'] = category;
    }
    if (documentableType != null) {
      queryParams['documentable_type'] = documentableType;
    }
    if (documentableId != null) {
      queryParams['documentable_id'] = documentableId;
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
      ApiConfig.documents,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Obtém um documento específico
  static Future<Response> get(int id) async {
    return await DioClient.get('${ApiConfig.documents}/$id');
  }

  /// Faz upload de um documento
  static Future<Response> upload({
    required PlatformFile file,
    String? name,
    String? description,
    String? category,
    String? documentableType,
    int? documentableId,
    Function(int sent, int total)? onSendProgress,
  }) async {
    MultipartFile multipartFile;
    
    if (file.bytes != null) {
      // Web - usar bytes
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
        contentType: MediaType.parse(_getMimeType(file.name)),
      );
    } else if (file.path != null) {
      // Mobile - usar path
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
        contentType: MediaType.parse(_getMimeType(file.name)),
      );
    } else {
      throw Exception('File must have either bytes or path');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (documentableType != null) 'documentable_type': documentableType,
      if (documentableId != null) 'documentable_id': documentableId,
    });

    return await DioClient.instance.post(
      ApiConfig.documents,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  /// Atualiza um documento (metadados)
  static Future<Response> update(
    int id, {
    String? name,
    String? description,
    String? category,
  }) async {
    return await DioClient.put(
      '${ApiConfig.documents}/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
      },
    );
  }

  /// Deleta um documento
  static Future<Response> delete(int id) async {
    return await DioClient.delete('${ApiConfig.documents}/$id');
  }

  /// Obtém URL temporária para download
  static Future<Response> getUrl(int id, {int? expires}) async {
    final queryParams = <String, dynamic>{};
    if (expires != null) {
      queryParams['expires'] = expires;
    }

    return await DioClient.get(
      '${ApiConfig.documents}/$id/url',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Faz download do documento
  static Future<Response> download(int id) async {
    return await DioClient.instance.get(
      '${ApiConfig.documents}/$id/download',
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );
  }

  static String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}

