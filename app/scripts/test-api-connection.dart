import 'dart:io';
import 'package:dio/dio.dart';
import '../lib/config/api_config.dart';
import '../lib/core/network/dio_client.dart';

/// Script para testar a conexão com a API
/// Execute com: dart run scripts/test-api-connection.dart
void main() async {
  print('🧪 Testando conexão com a API...');
  print('📍 URL Base: ${ApiConfig.baseUrl}');
  print('📍 Health Endpoint: ${ApiConfig.baseUrl}${ApiConfig.health}');
  print('');

  try {
    // Teste 1: Health check
    print('1️⃣ Testando health check...');
    final healthResponse = await DioClient.get(ApiConfig.health);
    print('✅ Health check OK: ${healthResponse.statusCode}');
    print('   Response: ${healthResponse.data}');
    print('');

    // Teste 2: Verificar CORS headers
    print('2️⃣ Verificando headers CORS...');
    final headers = healthResponse.headers;
    final corsOrigin = headers.value('access-control-allow-origin');
    final corsMethods = headers.value('access-control-allow-methods');
    final corsHeaders = headers.value('access-control-allow-headers');
    
    print('   CORS Origin: ${corsOrigin ?? "NÃO ENCONTRADO"}');
    print('   CORS Methods: ${corsMethods ?? "NÃO ENCONTRADO"}');
    print('   CORS Headers: ${corsHeaders ?? "NÃO ENCONTRADO"}');
    print('');

    if (corsOrigin == null) {
      print('⚠️  AVISO: Headers CORS não encontrados!');
      print('   Isso pode causar problemas em requisições do navegador.');
    } else {
      print('✅ Headers CORS configurados corretamente!');
    }

  } on DioException catch (e) {
    print('❌ Erro ao conectar com a API:');
    print('   Tipo: ${e.type}');
    print('   Mensagem: ${e.message}');
    print('   Status: ${e.response?.statusCode}');
    print('   Data: ${e.response?.data}');
    
    if (e.type == DioExceptionType.connectionError) {
      print('');
      print('💡 Possíveis causas:');
      print('   1. Servidor não está acessível');
      print('   2. Problema de CORS (verifique o console do navegador)');
      print('   3. Certificado SSL inválido');
      print('   4. Firewall bloqueando a conexão');
    }
    
    exit(1);
  } catch (e) {
    print('❌ Erro inesperado: $e');
    exit(1);
  }

  print('');
  print('✅ Todos os testes passaram!');
}

