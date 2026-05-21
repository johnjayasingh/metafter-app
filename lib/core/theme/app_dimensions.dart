import 'package:flutter/material.dart';

/// Centralized dimensions and sizing constants for the application
class AppDimensions {
  // ==================== Base Design Dimensions ====================
  /// Base design width (reference screen width)
  static const double baseDesignWidth = 393.0;

  // ==================== Responsive Size Calculation ====================
  /// Calculate responsive size based on design size and screen width
  /// Pass a size from your design (based on 393px screen) and get the responsive size
  /// 
  /// Example: responsiveSize(context, 274) -> returns ~274 on 393px, scales on other sizes
  static double responsiveSize(BuildContext context, double designSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (designSize / baseDesignWidth);
  }

  // ==================== Card Dimensions ====================
  /// Subscription card base width (designed for 393px screen)
  static const double subscriptionCardBaseWidth = 274.0;

  /// Calculate responsive card width based on screen width
  /// Returns card width maintaining 274/393 ratio
  static double getSubscriptionCardWidth(BuildContext context) {
    return responsiveSize(context, subscriptionCardBaseWidth);
  }

  // ==================== Border Radius ====================
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 8.0;
  static const double smallBorderRadius = 4.0;

  // ==================== Padding & Spacing ====================
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
  static const double paddingXXLarge = 24.0;
  static const double paddingHuge = 32.0;

  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 20.0;
  static const double spacingXXLarge = 24.0;
  static const double spacingHuge = 32.0;

  // ==================== Component Heights ====================
  static const double buttonHeight = 56.0;
  static const double appBarHeight = 80.0;

  // ==================== Icon Sizes ====================
  static const double iconSmall = 14.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;

  // ==================== Shadow ====================
  static const double shadowBlurRadius = 8.0;
  static const double shadowLargeBlurRadius = 24.0;
  static const Offset shadowOffset = Offset(0, 2);
  static const Offset shadowLargeOffset = Offset(0, 4);
}
