import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Design dimensions (base)
  static const double designWidth = 393;
  static const double designHeight = 852;

  /// Get scaled size based on screen dimensions
  static double getScale(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleWidth = size.width / designWidth;
    final scaleHeight = size.height / designHeight;
    return (scaleWidth + scaleHeight) / 2;
  }

  /// Scale a value based on screen size
  static double scale(BuildContext context, double value) {
    return value * getScale(context);
  }

  /// Scale width specifically
  static double scaleWidth(BuildContext context, double width) {
    final screenWidth = MediaQuery.of(context).size.width;
    return width * (screenWidth / designWidth);
  }

  /// Scale height specifically
  static double scaleHeight(BuildContext context, double height) {
    final screenHeight = MediaQuery.of(context).size.height;
    return height * (screenHeight / designHeight);
  }

  /// Get scaled EdgeInsets
  static EdgeInsets scaleEdgeInsets(
    BuildContext context, {
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0,
  }) {
    final scale = getScale(context);
    return EdgeInsets.only(
      top: top * scale,
      bottom: bottom * scale,
      left: left * scale,
      right: right * scale,
    );
  }

  /// Get scaled symmetric EdgeInsets
  static EdgeInsets scaleEdgeInsetsSymmetric(
    BuildContext context, {
    double vertical = 0,
    double horizontal = 0,
  }) {
    final scale = getScale(context);
    return EdgeInsets.symmetric(
      vertical: vertical * scale,
      horizontal: horizontal * scale,
    );
  }

  /// Get scaled all-around EdgeInsets
  static EdgeInsets scaleEdgeInsetsAll(BuildContext context, double value) {
    return EdgeInsets.all(value * getScale(context));
  }

  /// Get scaled SizedBox for spacing
  static SizedBox scaledBox(BuildContext context, {double? width, double? height}) {
    final scale = getScale(context);
    return SizedBox(
      width: width != null ? width * scale : null,
      height: height != null ? height * scale : null,
    );
  }
}

/// Extension methods for easier usage
extension ResponsiveExtension on num {
  /// Scale this value based on context
  double scaled(BuildContext context) => ResponsiveUtils.scale(context, toDouble());
  
  /// Scale this value as width
  double scaledWidth(BuildContext context) => ResponsiveUtils.scaleWidth(context, toDouble());
  
  /// Scale this value as height
  double scaledHeight(BuildContext context) => ResponsiveUtils.scaleHeight(context, toDouble());
}
