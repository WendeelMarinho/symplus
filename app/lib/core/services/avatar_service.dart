import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../network/dio_client.dart';
import '../config/api_config.dart';
import '../auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service para upload de avatar/logo
class AvatarService {
  /// Faz upload de avatar/logo do usuário ou empresa
  /// 
  /// Retorna a URL do arquivo após upload bem-sucedido
  static Future<String> uploadAvatar({
    required PlatformFile file,
    required Ref ref,
    Function(int sent, int total)? onSendProgress,
  }) async {
    // Validar tamanho (máximo 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB em bytes
    final fileSize = file.size;
    
    if (fileSize > maxSize) {
      throw Exception('Arquivo muito grande. Máximo: 5MB');
    }

    // Validar tipo (apenas imagens)
    final allowedTypes = ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'];
    final mimeType = _getMimeType(file.name);
    
    if (!allowedTypes.contains(mimeType)) {
      throw Exception('Tipo de arquivo não permitido. Use PNG, JPG ou WEBP');
    }

    // Criar MultipartFile
    MultipartFile multipartFile;
    
    if (file.bytes != null) {
      // Web - usar bytes
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
        contentType: MediaType.parse(mimeType),
      );
    } else if (file.path != null) {
      // Mobile - usar path
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
        contentType: MediaType.parse(mimeType),
      );
    } else {
      throw Exception('Arquivo inválido');
    }

    // Determinar se é empresa ou PF
    final authState = ref.read(authProvider);
    final isCompany = authState.organizationName != null && 
                      authState.organizationName!.isNotEmpty;

    // Criar FormData
    final formData = FormData.fromMap({
      'file': multipartFile,
      'type': isCompany ? 'company_logo' : 'user_avatar',
    });

    try {
      // Fazer upload usando o endpoint de documentos
      // O backend pode ter um endpoint específico para avatar, mas por enquanto
      // vamos usar o endpoint de documentos com category='avatar'
      final response = await DioClient.instance.post(
        ApiConfig.documents,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        
        // Tentar obter URL do documento
        String? url;
        if (data['url'] != null) {
          url = data['url'] as String;
        } else if (data['storage_path'] != null) {
          // Se não tiver URL direta, construir a URL
          final storagePath = data['storage_path'] as String;
          url = '${ApiConfig.baseUrl}/storage/$storagePath';
        } else if (data['id'] != null) {
          // Usar ID para construir URL de download
          final id = data['id'] as int;
          url = '${ApiConfig.baseUrl}${ApiConfig.documents}/$id/download';
        }

        if (url == null) {
          throw Exception('Não foi possível obter URL do arquivo');
        }

        return url;
      } else {
        throw Exception('Erro ao fazer upload: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData?['message'] ?? 
                           errorData?['error'] ?? 
                           'Erro ao fazer upload';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    }
  }

  /// Obtém o MIME type baseado na extensão do arquivo
  static String _getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

