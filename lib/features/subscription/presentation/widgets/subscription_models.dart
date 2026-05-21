import 'package:digitalwill/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/payment_config.dart';

enum PlanType {
  basic,
  standard,
  premium,
}

class SubscriptionPlan {
  final PlanType type;
  final String name;
  final String description;
  final String? price; // null for free plans
  final String? priceId; // Stripe price ID for checkout
  final String buttonText;
  final List<String> features;
  final String perfectFor;
  final bool isPopular;
  final Color accentColor;

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    this.price,
    this.priceId,
    required this.buttonText,
    required this.features,
    required this.perfectFor,
    this.isPopular = false,
    required this.accentColor,
  });

  /// Create SubscriptionPlan from PaymentConfig
  factory SubscriptionPlan.fromConfig(PlanType type, Map<String, dynamic> config) {
    Color accentColor;
    switch (type) {
      case PlanType.basic:
        accentColor = AppColors.success;
        break;
      case PlanType.standard:
        accentColor = AppColors.primaryGreen;
        break;
      case PlanType.premium:
        accentColor = AppColors.primaryGreen;
        break;
    }

    return SubscriptionPlan(
      type: type,
      name: config['name'] as String,
      description: config['description'] as String,
      price: config['price'] as String?,
      priceId: config['priceId'] as String?,
      buttonText: config['buttonText'] as String,
      features: (config['features'] as List<dynamic>).map((e) => e.toString()).toList(),
      perfectFor: config['perfectFor'] as String,
      isPopular: config['isPopular'] as bool? ?? false,
      accentColor: accentColor,
    );
  }
}

/// Load subscription plans from PaymentConfig
List<SubscriptionPlan> getSubscriptionPlans() {
  try {
    final basicConfig = PaymentConfig.getPlan('basic');
    final standardConfig = PaymentConfig.getPlan('standard');
    final premiumConfig = PaymentConfig.getPlan('premium');

    return [
      if (basicConfig != null) SubscriptionPlan.fromConfig(PlanType.basic, basicConfig),
      if (standardConfig != null) SubscriptionPlan.fromConfig(PlanType.standard, standardConfig),
      if (premiumConfig != null) SubscriptionPlan.fromConfig(PlanType.premium, premiumConfig),
    ];
  } catch (e) {
    print('❌ Error loading subscription plans from config: $e');
    // Fallback to hardcoded plans if config fails
    return _fallbackPlans;
  }
}

// Fallback plans in case configuration fails to load
final List<SubscriptionPlan> _fallbackPlans = [
  SubscriptionPlan(
    type: PlanType.basic,
    name: 'Basic',
    description: 'Just the essentials to get it done.',
    price: null, // Free
    priceId: null, // Free plan, no payment needed
    buttonText: 'Get started for Free',
    features: [
      'Create your legally valid Will',
      'Secure document generation',
      'Encrypted storage',
    ],
    perfectFor: 'Simple estates and confident self-starters',
    accentColor: AppColors.success,
  ),
  SubscriptionPlan(
    type: PlanType.standard,
    name: 'Standard',
    description: 'Add extra confidence and peace of mind.',
    price: '\$110',
    priceId: 'price_1SkP862NO1u7Z8eWmTPQwvxe',
    buttonText: 'Get started for \$110',
    features: [
      'Everything in Basic',
      'Share with executors and stakeholders',
      'Manual legal review by our team',
    ],
    perfectFor: 'Those who want legal assurance',
    isPopular: true,
    accentColor: AppColors.primaryGreen,
  ),
  SubscriptionPlan(
    type: PlanType.premium,
    name: 'Premium',
    description: 'The full experience with expert legal backup.',
    price: '\$340',
    priceId: 'price_1SkPDI2NO1u7Z8eWNYGisj84',
    buttonText: 'Get started for \$340',
    features: [
      'Everything in Standard',
      'Full legal review session (asynchronous)',
      'Enhanced guidance throughout',
    ],
    perfectFor: 'Complex family or asset situations',
    accentColor: AppColors.accentPurple,
  ),
];
