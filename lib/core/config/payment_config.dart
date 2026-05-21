import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/environment_config.dart';

class PaymentConfig {
  static PaymentConfig? _instance;
  static Map<String, dynamic>? _config;

  static Future<void> initialize() async {
    if (_instance != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/config/payment_config.json');
      _config = json.decode(jsonString) as Map<String, dynamic>;
      _instance = PaymentConfig._();
      print('✅ Payment configuration loaded successfully');
    } catch (e) {
      print('❌ Error loading payment configuration: $e');
      // Fallback to empty config
      _config = {};
    }
  }

  PaymentConfig._();

  static PaymentConfig get instance {
    if (_instance == null) {
      throw StateError('PaymentConfig must be initialized before use. Call PaymentConfig.initialize() first.');
    }
    return _instance!;
  }

  /// Get payment configuration for current environment
  static Map<String, dynamic> get currentConfig {
    if (_config == null) {
      throw StateError('Payment configuration not loaded');
    }

    final environment = EnvironmentConfig.environment;
    String envKey;

    switch (environment) {
      case Environment.local:
        envKey = 'local';
        break;

      case Environment.dev:
        envKey = 'dev';
        break;
      case Environment.uat:
        envKey = 'uat';
        break;
      case Environment.production:
        envKey = 'production';
        break;
    }

    // Return environment-specific config, fallback to dev if not found
    return _config![envKey] as Map<String, dynamic>? ?? _config!['dev'] as Map<String, dynamic>;
  }

  /// Get all plans for current environment
  static Map<String, dynamic> get plans {
    return currentConfig['plans'] as Map<String, dynamic>;
  }

  /// Get specific plan configuration
  static Map<String, dynamic>? getPlan(String planType) {
    return plans[planType] as Map<String, dynamic>?;
  }

  /// Get price ID for a specific plan
  static String? getPriceId(String planType) {
    final plan = getPlan(planType);
    return plan?['priceId'] as String?;
  }

  /// Get price display for a specific plan
  static String? getPrice(String planType) {
    final plan = getPlan(planType);
    return plan?['price'] as String?;
  }

  /// Get features for a specific plan
  static List<String> getFeatures(String planType) {
    final plan = getPlan(planType);
    if (plan == null) return [];
    final features = plan['features'] as List<dynamic>?;
    return features?.map((e) => e.toString()).toList() ?? [];
  }

  /// Check if plan is popular
  static bool isPlanPopular(String planType) {
    final plan = getPlan(planType);
    return plan?['isPopular'] as bool? ?? false;
  }
}
