import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../network/dio_client.dart';

/// Ferramenta de diagnóstico para problemas de conexão com a API
class ApiDiagnostics {
  /// Testa a conexão com a API e retorna um relatório detalhado
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'apiBaseUrl': ApiConfig.baseUrl,
      'tests': <String, dynamic>{},
    };

    // Teste 1: Health check
    try {
      debugPrint('🔍 Teste 1: Health check...');
      final healthResponse = await DioClient.get(ApiConfig.health);
      results['tests']['healthCheck'] = {
        'status': 'success',
        'statusCode': healthResponse.statusCode,
        'data': healthResponse.data,
        'headers': _extractCorsHeaders(healthResponse.headers),
      };
      debugPrint('✅ Health check OK: ${healthResponse.statusCode}');
    } catch (e) {
      results['tests']['healthCheck'] = {
        'status': 'error',
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
        'isDioException': e is DioException,
        'dioErrorType': e is DioException ? e.type.toString() : null,
      };
      debugPrint('❌ Health check falhou: $e');
    }

    // Teste 2: Verificar se é problema de CORS
    if (kIsWeb) {
      try {
        debugPrint('🔍 Teste 2: Teste direto via fetch (bypass Dio)...');
        // Este teste será feito via JavaScript no console
        results['tests']['corsTest'] = {
          'status': 'pending',
          'note': 'Execute no console do navegador:',
          'javascript': '''
fetch('${ApiConfig.baseUrl}${ApiConfig.health}', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
})
.then(r => {
  console.log('✅ Fetch OK:', r.status, r.statusText);
  return r.json();
})
.then(data => console.log('✅ Data:', data))
.catch(err => {
  console.error('❌ Fetch Error:', err);
  console.error('   Isso indica problema de CORS ou rede');
});
          ''',
        };
      } catch (e) {
        results['tests']['corsTest'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
    }

    return results;
  }

  /// Extrai headers CORS relevantes
  static Map<String, String> _extractCorsHeaders(Headers headers) {
    return {
      'access-control-allow-origin': headers.value('access-control-allow-origin') ?? 'NÃO ENCONTRADO',
      'access-control-allow-methods': headers.value('access-control-allow-methods') ?? 'NÃO ENCONTRADO',
      'access-control-allow-headers': headers.value('access-control-allow-headers') ?? 'NÃO ENCONTRADO',
      'access-control-allow-credentials': headers.value('access-control-allow-credentials') ?? 'NÃO ENCONTRADO',
    };
  }

  /// Gera um relatório formatado
  static String formatReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Relatório de Diagnóstico da API');
    buffer.writeln('=' * 50);
    buffer.writeln('URL Base: ${results['apiBaseUrl']}');
    buffer.writeln('Timestamp: ${results['timestamp']}');
    buffer.writeln('');

    final tests = results['tests'] as Map<String, dynamic>;
    
    tests.forEach((testName, testResult) {
      buffer.writeln('🧪 $testName:');
      if (testResult['status'] == 'success') {
        buffer.writeln('   ✅ Status: ${testResult['statusCode']}');
        buffer.writeln('   📋 CORS Headers:');
        final corsHeaders = testResult['headers'] as Map<String, String>;
        corsHeaders.forEach((key, value) {
          buffer.writeln('      $key: $value');
        });
      } else if (testResult['status'] == 'error') {
        buffer.writeln('   ❌ Erro: ${testResult['error']}');
        buffer.writeln('   Tipo: ${testResult['errorType']}');
        if (testResult['isDioException'] == true) {
          buffer.writeln('   DioError Type: ${testResult['dioErrorType']}');
        }
      }
      buffer.writeln('');
    });

    return buffer.toString();
  }
}

