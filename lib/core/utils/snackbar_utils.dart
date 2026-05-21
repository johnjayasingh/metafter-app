import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Utility class for showing styled SnackBars
class SnackBarUtils {
  /// Shows a styled SnackBar with icon
  static void _showStyledSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows a SnackBar at the top of the screen (backwards compatibility)
  static void showTopSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showStyledSnackBar(
      context,
      message,
      backgroundColor: backgroundColor ?? AppColors.textPrimary,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  /// Shows a success SnackBar
  static void showSuccess(BuildContext context, String message) {
    _showStyledSnackBar(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle,
    );
  }

  /// Shows an error SnackBar
  static void showError(BuildContext context, String message) {
    // Skip showing snackbar for empty messages (network errors are suppressed)
    if (message.trim().isEmpty) return;
    
    _showStyledSnackBar(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  /// Shows a warning SnackBar
  static void showWarning(BuildContext context, String message) {
    _showStyledSnackBar(
      context,
      message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber,
    );
  }

  /// Shows an info SnackBar
  static void showInfo(BuildContext context, String message) {
    _showStyledSnackBar(
      context,
      message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline,
    );
  }
}
