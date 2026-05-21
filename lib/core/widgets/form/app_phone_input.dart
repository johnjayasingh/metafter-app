import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/form_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/input_formatters.dart';

/// A reusable phone input widget with country code selector.
/// 
/// Usage:
/// ```dart
/// AppPhoneInput(
///   controller: _phoneController,
///   countryCode: _selectedCountryCode,
///   onCountryCodeChanged: (code) => setState(() => _selectedCountryCode = code),
///   isRequired: true,
/// )
/// ```
class AppPhoneInput extends StatelessWidget {
  /// The controller for the phone number
  final TextEditingController controller;
  
  /// The currently selected country code
  final String countryCode;
  
  /// Callback when country code changes
  final ValueChanged<String> onCountryCodeChanged;
  
  /// Whether this field is required
  final bool isRequired;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Custom validator function
  final String? Function(String?)? validator;
  
  /// Callback when the phone number changes
  final ValueChanged<String>? onChanged;
  
  /// The list of available country codes (defaults to FormConstants.countryCodes)
  final List<String>? countryCodes;
  
  /// Width of the country code dropdown
  final double countryCodeWidth;
  
  /// Custom label for the phone number field
  final String? label;

  const AppPhoneInput({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.countryCodes,
    this.countryCodeWidth = 90,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final codes = countryCodes ?? FormConstants.countryCodes;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country code dropdown
        Container(
          width: countryCodeWidth,
          height: 48,
          decoration: AppDecorations.card.copyWith(
            color: enabled ? AppColors.backgroundWhite : AppColors.backgroundGray,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: codes.contains(countryCode) ? countryCode : codes.first,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: codes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: AppTextStyles.inputText,
                  ),
                );
              }).toList(),
              onChanged: enabled ? (String? newValue) {
                if (newValue != null) {
                  onCountryCodeChanged(newValue);
                }
              } : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Phone number field
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            enabled: enabled,
            onChanged: onChanged,
            inputFormatters: [
              NoLeadingSpaceFormatter(),
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: validator ?? (isRequired ? _defaultValidator : null),
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              labelText: label ?? (isRequired ? 'Phone number *' : 'Phone number'),
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
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    final digitsOnly = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7) {
      return 'Phone number must be at least 7 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number must not exceed 15 digits';
    }
    if (!RegExp(r'^\d{7,15}$').hasMatch(digitsOnly)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Combines country code and phone number into a single string
  /// Format: '+61 412345678' (with space) or '+61412345678' (without space)
  static String combinePhoneNumber(String countryCode, String phoneNumber, {bool withSpace = true}) {
    final trimmedPhone = phoneNumber.trim();
    if (withSpace) {
      return '$countryCode $trimmedPhone';
    }
    return '$countryCode$trimmedPhone';
  }

  /// Parses a combined phone number into country code and local number
  /// Returns a tuple of (countryCode, localNumber)
  static (String, String) parsePhoneNumber(String? fullNumber, {String defaultCountryCode = '+61'}) {
    if (fullNumber == null || fullNumber.isEmpty) {
      return (defaultCountryCode, '');
    }
    
    // Try to extract country code (assumes format: +XX or +XXX followed by space or digits)
    for (final code in FormConstants.countryCodes) {
      if (fullNumber.startsWith(code)) {
        String localPart = fullNumber.substring(code.length);
        // Remove leading space if present
        if (localPart.startsWith(' ')) {
          localPart = localPart.substring(1);
        }
        return (code, localPart);
      }
    }
    
    // If no known country code found, return default with full number
    return (defaultCountryCode, fullNumber);
  }
}
