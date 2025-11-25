import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../config/api_config.dart';
import '../storage/storage_service.dart';
import '../auth/auth_session_handler.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          ApiConfig.contentTypeHeader: 'application/json',
          ApiConfig.acceptHeader: 'application/json',
        },
      ),
    );

    // Interceptor para adicionar token e organization ID
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Adicionar token de autenticação
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers[ApiConfig.authHeader] = 'Bearer $token';
          }

          // Adicionar organization ID
          final orgId = await StorageService.getOrganizationId();
          if (orgId != null) {
            options.headers[ApiConfig.orgHeader] = orgId;
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // Tratar erros 401 (não autenticado)
          if (error.response?.statusCode == 401) {
            // Tratar expiração de token
            await AuthSessionHandler.handleTokenExpired();
          }
          return handler.next(error);
        },
      ),
    );

    // Logger (apenas em debug)
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }

    return dio;
  }

  // Métodos HTTP
  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

