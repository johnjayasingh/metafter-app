import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A prominent, centralized checkbox widget for consistent styling across the app.
/// 
/// WCMVP-862: Make any checkboxes prominent in the app
/// 
/// Usage:
/// ```dart
/// AppCheckbox(
///   value: _isChecked,
///   onChanged: (value) => setState(() => _isChecked = value ?? false),
///   label: 'I agree to the terms',
/// )
/// ```
class AppCheckbox extends StatelessWidget {
  /// Whether the checkbox is checked
  final bool value;
  
  /// Callback when the checkbox value changes
  final ValueChanged<bool?>? onChanged;
  
  /// Optional label text displayed next to the checkbox
  final String? label;
  
  /// Optional widget to display instead of label text
  final Widget? labelWidget;
  
  /// Size of the checkbox (default: 24)
  final double size;
  
  /// Whether the checkbox is enabled
  final bool enabled;

  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.labelWidget,
    this.size = 24,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final checkbox = SizedBox(
      width: size,
      height: size,
      child: Checkbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primaryGreen,
        checkColor: Colors.white,
        side: BorderSide(
          color: value ? AppColors.primaryGreen : AppColors.textSecondary,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );

    // If no label, just return the checkbox
    if (label == null && labelWidget == null) {
      return checkbox;
    }

    // Return checkbox with label
    return GestureDetector(
      onTap: enabled && onChanged != null
          ? () => onChanged!(!value)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          checkbox,
          const SizedBox(width: 12),
          Expanded(
            child: labelWidget ?? Text(
              label!,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A prominent checkbox with a container background for important confirmations
class AppCheckboxCard extends StatelessWidget {
  /// Whether the checkbox is checked
  final bool value;
  
  /// Callback when the checkbox value changes
  final ValueChanged<bool?>? onChanged;
  
  /// The label text or widget
  final String? label;
  
  /// Optional widget to display instead of label text
  final Widget? labelWidget;
  
  /// Background color of the card (default: light green)
  final Color? backgroundColor;
  
  /// Whether the checkbox is enabled
  final bool enabled;

  const AppCheckboxCard({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.labelWidget,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && onChanged != null
          ? () => onChanged!(!value)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.backgroundLightGreen.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.primaryGreen : AppColors.borderLight,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeColor: AppColors.primaryGreen,
                checkColor: Colors.white,
                side: BorderSide(
                  color: value ? AppColors.primaryGreen : AppColors.textSecondary,
                  width: 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: labelWidget ?? Text(
                label ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
