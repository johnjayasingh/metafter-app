import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient();
  static const String _createCheckoutEndpoint = '/user/create-checkout';

  /// Creates a checkout session for the selected subscription plan
  /// Returns the checkout URL or session ID on success, null on failure
  Future<Map<String, dynamic>?> createCheckout({
    required String willId,
    required String priceId,
  }) async {
    try {
      print('🚀 Creating checkout session');
      print('📦 Will ID: $willId');
      print('💰 Price ID: $priceId');
      
      final response = await _apiClient.post(
        _createCheckoutEndpoint,
        data: {
          'will_id': willId,
          'price_id': priceId,
        },
      );

      print('📊 RESPONSE STATUS: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Checkout session created successfully');
        print('📦 Response data: ${response.data}');
        return response.data;
      } else {
        print('❌ Error creating checkout: ${response.statusCode}');
        print('📦 Error response: ${response.data}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception creating checkout: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }
}
