import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A reusable date picker field widget with consistent styling.
/// 
/// Usage:
/// ```dart
/// AppDatePickerField(
///   controller: _dobController,
///   label: 'Date of birth',
///   isRequired: true,
///   onDateSelected: (date) {
///     _dobController.text = AppDatePickerField.formatDate(date);
///   },
/// )
/// ```
class AppDatePickerField extends StatelessWidget {
  /// The controller for the date field (displays formatted date)
  final TextEditingController controller;
  
  /// The label text
  final String label;
  
  /// Whether this field is required
  final bool isRequired;
  
  /// Callback when a date is selected
  final ValueChanged<DateTime>? onDateSelected;
  
  /// The first selectable date
  final DateTime? firstDate;
  
  /// The last selectable date
  final DateTime? lastDate;
  
  /// The initial date shown in the picker
  final DateTime? initialDate;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Custom help text
  final String? helpText;

  const AppDatePickerField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.enabled = true,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => _selectDate(context) : null,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          style: AppTextStyles.inputText,
          validator: isRequired ? _defaultValidator : null,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            labelStyle: AppTextStyles.inputLabel,
            floatingLabelStyle: AppTextStyles.inputLabelFloating,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.textSecondary,
            ),
            helperText: helpText,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? now;
    
    // Determine initial date
    DateTime initial = initialDate ?? DateTime(now.year - 30, now.month, now.day);
    if (initial.isBefore(first)) {
      initial = first;
    } else if (initial.isAfter(last)) {
      initial = last;
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: helpText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: AppColors.backgroundWhite,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      controller.text = formatDate(picked);
      onDateSelected?.call(picked);
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a date';
    }
    return null;
  }

  /// Formats a DateTime to display format (DD/MM/YYYY)
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formats a DateTime to API format (YYYY-MM-DD)
  static String formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parses a display format date (DD/MM/YYYY) to DateTime
  static DateTime? parseDateFromDisplay(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    final parts = dateString.split('/');
    if (parts.length == 3) {
      try {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Parses an API format date (YYYY-MM-DD) to display format (DD/MM/YYYY)
  static String formatApiDateForDisplay(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty) return '';
    final parts = apiDate.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return apiDate;
  }

  /// Converts display format (DD/MM/YYYY) to API format (YYYY-MM-DD)
  static String formatDisplayDateForApi(String? displayDate) {
    if (displayDate == null || displayDate.isEmpty) return '';
    final parts = displayDate.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return displayDate;
  }
}

/// A specialized date picker for date of birth with age constraints
class AppDobField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final ValueChanged<DateTime>? onDateSelected;
  final bool enabled;
  
  /// If true, only allows selecting dates for minors (under 18)
  final bool isMinor;

  const AppDobField({
    super.key,
    required this.controller,
    this.label = 'Date of birth',
    this.isRequired = true,
    this.onDateSelected,
    this.enabled = true,
    this.isMinor = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    
    DateTime firstDate;
    DateTime lastDate;
    DateTime initialDate;
    
    if (isMinor) {
      // Minor: born after 18 years ago, up to today
      firstDate = eighteenYearsAgo.add(const Duration(days: 1));
      lastDate = now;
      initialDate = DateTime(now.year - 5, now.month, now.day); // Default ~5 years old
    } else {
      // Adult: born 18+ years ago
      firstDate = DateTime(1900);
      lastDate = eighteenYearsAgo;
      initialDate = DateTime(now.year - 30, now.month, now.day); // Default ~30 years old
    }
    
    return AppDatePickerField(
      controller: controller,
      label: label,
      isRequired: isRequired,
      onDateSelected: onDateSelected,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      enabled: enabled,
      helpText: isMinor 
          ? 'Select date of birth (must be under 18)'
          : 'Select date of birth (must be 18 or older)',
    );
  }
}
