import 'package:flutter/foundation.dart';
import 'platform_helper.dart';

class ApiConfig {
  // URL base da API
  // 
  // Configuração automática por plataforma:
  // - Web: http://localhost:8000
  // - Android Emulator: http://10.0.2.2:8000
  // - iOS Simulator: http://localhost:8000
  // - Dispositivo físico: configure via --dart-define API_BASE_URL=http://SEU_IP:8000
  //
  // Para produção: https://api.symplus.dev
  static String get baseUrl {
    // Se definido via --dart-define, usa esse valor (prioridade máxima)
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Se estiver em modo release/produção, usa URL de produção
    if (kReleaseMode) {
      return 'https://srv1113923.hstgr.cloud';
    }

    // Detecção automática para desenvolvimento
    if (kIsWeb) {
      // Web: usa localhost
      return 'http://localhost:8000';
    }

    // Para mobile, tenta detectar Android (emulador)
    if (isAndroidPlatform()) {
      // Android: assume emulador (10.0.2.2) por padrão
      // Para dispositivo físico, configure via --dart-define API_BASE_URL=http://SEU_IP:8000
      return 'http://10.0.2.2:8000';
    }

    // Fallback para iOS ou outras plataformas
    // iOS Simulator pode usar localhost, mas dispositivo físico precisa de IP
    return 'http://localhost:8000';
  }

  static const String apiPrefix = '/api';

  // Endpoints
  static const String health = '$apiPrefix/health';
  static const String login = '$apiPrefix/auth/login';
  static const String logout = '$apiPrefix/auth/logout';
  static const String me = '$apiPrefix/me';

  // Resources
  static const String accounts = '$apiPrefix/accounts';
  static const String categories = '$apiPrefix/categories';
  static const String transactions = '$apiPrefix/transactions';
  static const String dueItems = '$apiPrefix/due-items';
  static const String documents = '$apiPrefix/documents';
  static const String reports = '$apiPrefix/reports';
  static const String dashboard = '$apiPrefix/dashboard';
  static const String dashboardLayout = '$apiPrefix/dashboard/layout';
  static const String dashboardTemplates = '$apiPrefix/dashboard/templates';
  static const String dashboardInsights = '$apiPrefix/dashboard/insights';
  static const String subscription = '$apiPrefix/subscription';
  static const String notifications = '$apiPrefix/notifications';
  static const String serviceRequests = '$apiPrefix/service-requests';

  // Headers
  static const String authHeader = 'Authorization';
  static const String orgHeader = 'X-Organization-Id';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

