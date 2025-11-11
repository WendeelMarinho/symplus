import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class SubscriptionService {
  /// Obtém a assinatura atual
  static Future<Response> get() async {
    return await DioClient.get(ApiConfig.subscription);
  }

  /// Atualiza a assinatura (upgrade/downgrade)
  static Future<Response> update({
    required String plan,
    String? paymentMethodId,
  }) async {
    return await DioClient.put(
      ApiConfig.subscription,
      data: {
        'plan': plan,
        if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      },
    );
  }

  /// Cancela a assinatura
  static Future<Response> cancel() async {
    return await DioClient.post('${ApiConfig.subscription}/cancel');
  }
}

