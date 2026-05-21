import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized decorations, borders, and shadows for the application
/// Usage: Container(decoration: AppDecorations.cardSelected)
class AppDecorations {
  // ==================== Container Decorations ====================
  
  /// White card with border
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderGray,
          width: 1,
        ),
      );

  /// Selected card (green background + green border)
  static BoxDecoration get cardSelected => BoxDecoration(
        color: AppColors.backgroundLightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen,
          width: 2,
        ),
      );

  /// Light green card
  static BoxDecoration get cardLightGreen => BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(24),
      );

  /// Bottom sheet container
  static BoxDecoration get bottomSheet => const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      );

  /// Button container (rounded 12px)
  static BoxDecoration get button => BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(12),
      );

  /// Close button container
  static BoxDecoration get closeButton => BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      );

  /// Close button container with border
  static BoxDecoration get closeButtonBordered => BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 1),
      );

  /// Avatar circle
  static BoxDecoration get avatar => const BoxDecoration(
        color: AppColors.borderGray,
        shape: BoxShape.circle,
      );

  // ==================== Radio Buttons ====================
  
  /// Radio button outer circle (unselected)
  static BoxDecoration get radioUnselected => BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundWhite,
        border: Border.all(
          color: AppColors.borderLight,
          width: 2,
        ),
      );

  /// Radio button outer circle (selected)
  static BoxDecoration get radioSelected => BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen,
        border: Border.all(
          color: AppColors.primaryGreen,
          width: 2,
        ),
      );

  /// Radio button inner circle
  static const BoxDecoration radioInner = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.primaryGreen,
  );

  // ==================== Borders ====================
  
  /// Standard border (gray, 1px)
  static Border get borderStandard => Border.all(
        color: AppColors.borderGray,
        width: 1,
      );

  /// Selected border (green, 2px)
  static Border get borderSelected => Border.all(
        color: AppColors.primaryGreen,
        width: 2,
      );

  /// Top border only
  static const Border borderTop = Border(
    top: BorderSide(color: AppColors.borderGray, width: 1),
  );

  /// Bottom border only
  static const Border borderBottom = Border(
    bottom: BorderSide(color: AppColors.borderGray, width: 1),
  );

  /// Divider line
  static Container get divider => Container(
        height: 1,
        color: AppColors.borderGray,
      );

  // ==================== Shadows ====================
  
  /// Light shadow for bottom containers
  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ];

  /// Card shadow
  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  // ==================== Button Styles ====================
  
  /// Primary elevated button style
  static ButtonStyle get buttonPrimary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  /// Disabled button style
  static ButtonStyle get buttonDisabled => ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonDisabled,
        disabledBackgroundColor: AppColors.buttonDisabled,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  /// Secondary outlined button style
  static ButtonStyle get buttonSecondary => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  /// Cancel button style
  static ButtonStyle get buttonCancel => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: AppColors.borderGray),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  /// Small button style (compact padding)
  static ButtonStyle get buttonSmall => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  // ==================== Option Cards (Radio/Checkbox Style) ====================
  
  /// Option card decoration (unselected)
  static BoxDecoration optionCard({required bool isSelected}) => BoxDecoration(
        color: isSelected ? AppColors.backgroundLightGreen : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
          width: isSelected ? 2 : 1,
        ),
      );

  /// Yes/No button decoration
  static BoxDecoration yesNoButton({required bool isSelected}) => BoxDecoration(
        color: isSelected ? AppColors.lightGreen : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
          width: 1,
        ),
      );

  // ==================== Input Fields ====================
  
  /// Text field decoration
  static InputDecoration textField({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.backgroundWhite,
      );
}
