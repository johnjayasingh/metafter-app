import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_text_styles.dart';

/// A reusable dropdown widget with consistent styling across the app.
/// 
/// Usage:
/// ```dart
/// AppDropdown<String>(
///   value: _selectedRelation,
///   label: 'Relation',
///   items: ['SON', 'DAUGHTER', 'SPOUSE'],
///   displayName: (item) => item.toLowerCase(),
///   onChanged: (value) => setState(() => _selectedRelation = value),
/// )
/// ```
class AppDropdown<T> extends StatelessWidget {
  /// The currently selected value
  final T? value;
  
  /// The label/hint text when no value is selected
  final String label;
  
  /// The list of items to display
  final List<T> items;
  
  /// Callback when selection changes
  final ValueChanged<T?>? onChanged;
  
  /// Optional function to convert item to display string
  final String Function(T)? displayName;
  
  /// Whether this field is required
  final bool isRequired;
  
  /// Whether the dropdown is enabled
  final bool enabled;
  
  /// Optional icon to display
  final IconData? icon;
  
  /// Fixed height of the dropdown
  final double height;

  const AppDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.displayName,
    this.isRequired = false,
    this.enabled = true,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is actually in items list to prevent assertion error
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      height: height,
      decoration: AppDecorations.card.copyWith(
        color: enabled ? AppColors.backgroundWhite : AppColors.backgroundGray,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          hint: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              isRequired ? '$label *' : label,
              style: AppTextStyles.inputHint,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              icon ?? Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          isExpanded: true,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                displayName != null ? displayName!(item) : item.toString(),
                style: AppTextStyles.inputText,
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

/// A dropdown that uses DropdownButtonFormField for form validation support
class AppDropdownFormField<T> extends StatelessWidget {
  /// The currently selected value
  final T? value;
  
  /// The label text
  final String label;
  
  /// The list of items to display
  final List<T> items;
  
  /// Callback when selection changes
  final ValueChanged<T?>? onChanged;
  
  /// Optional function to convert item to display string
  final String Function(T)? displayName;
  
  /// Whether this field is required
  final bool isRequired;
  
  /// Whether the dropdown is enabled
  final bool enabled;
  
  /// Custom validator
  final String? Function(T?)? validator;

  const AppDropdownFormField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.displayName,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is actually in items list to prevent assertion error
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<T>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: AppTextStyles.inputLabel,
        floatingLabelStyle: AppTextStyles.inputLabelFloating,
        filled: true,
        fillColor: enabled ? AppColors.backgroundWhite : AppColors.backgroundGray,
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
          borderSide: const BorderSide(color: AppColors.primaryGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorMaxLines: 2,
        errorStyle: AppTextStyles.error.copyWith(fontSize: 12),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        size: 20,
        color: AppColors.textSecondary,
      ),
      style: AppTextStyles.inputText,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            displayName != null ? displayName!(item) : item.toString(),
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator ?? (isRequired ? _defaultRequiredValidator : null),
    );
  }

  String? _defaultRequiredValidator(T? value) {
    if (value == null) {
      return 'Please select a $label';
    }
    return null;
  }
}

/// A selectable container that looks like a dropdown but opens custom content
class AppSelectField extends StatelessWidget {
  /// The display text when a value is selected
  final String? selectedText;
  
  /// The placeholder text when no value is selected
  final String placeholder;
  
  /// Callback when the field is tapped
  final VoidCallback onTap;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Fixed height of the field
  final double height;

  const AppSelectField({
    super.key,
    this.selectedText,
    required this.placeholder,
    required this.onTap,
    this.enabled = true,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: height,
        decoration: AppDecorations.card.copyWith(
          color: enabled ? AppColors.backgroundWhite : AppColors.backgroundGray,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedText ?? placeholder,
                style: selectedText != null
                    ? AppTextStyles.inputText
                    : AppTextStyles.inputHint,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
