import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../../core/theme/app_colors.dart';

const Color _fieldFill = Color(0xFFEFEFEF);
const Color _fieldHint = Color(0xFF8E8E93);
const Color _fieldText = Color(0xFF434343);
const Color _fieldError = Color(0xFFD93636);

/// Total visual height of a single-line field per design spec (343×49).
const double _fieldHeight = 49;

TextStyle _inputTextStyle() => GoogleFonts.instrumentSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: _fieldText,
      height: 27 / 16,
    );

TextStyle _hintTextStyle() => GoogleFonts.instrumentSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: _fieldHint,
      height: 27 / 16,
    );

TextStyle _labelTextStyle() => GoogleFonts.instrumentSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

/// A label + filled text field matching the MetAfter signup design.
class MetafterField extends StatelessWidget {
  const MetafterField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.errorText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final isSingleLine = maxLines == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelTextStyle()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          cursorColor: AppColors.brandRed,
          style: _inputTextStyle(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _hintTextStyle(),
            filled: true,
            fillColor: _fieldFill,
            isDense: true,
            isCollapsed: false,
            constraints: isSingleLine
                ? const BoxConstraints(
                    minHeight: _fieldHeight, maxHeight: _fieldHeight)
                : const BoxConstraints(minHeight: _fieldHeight),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 11),
            border: _borderFor(false),
            enabledBorder: _borderFor(hasError),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _fieldError : AppColors.brandRed,
                width: 1.4,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.instrumentSans(
              fontSize: 12.5,
              color: _fieldError,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _borderFor(bool error) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: error
            ? const BorderSide(color: _fieldError, width: 1.2)
            : BorderSide.none,
      );
}

/// Phone field with country code picker, flag and per-country validation.
class MetafterPhoneField extends StatelessWidget {
  const MetafterPhoneField({
    super.key,
    required this.controller,
    this.label = 'Phone No',
    this.initialCountryCode = 'IN',
    this.onChanged,
    this.onCountryChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String initialCountryCode;
  final ValueChanged<PhoneNumber>? onChanged;
  final ValueChanged<Country>? onCountryChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelTextStyle()),
        const SizedBox(height: 8),
        Container(
          height: _fieldHeight,
          decoration: BoxDecoration(
            color: _fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: hasError
                ? Border.all(color: _fieldError, width: 1.2)
                : null,
          ),
          child: IntlPhoneField(
            controller: controller,
            initialCountryCode: initialCountryCode,
            cursorColor: AppColors.brandRed,
            dropdownIconPosition: IconPosition.trailing,
            disableLengthCheck: false,
            invalidNumberMessage: 'Invalid phone number',
            style: _inputTextStyle(),
            dropdownTextStyle: _inputTextStyle(),
            flagsButtonPadding: const EdgeInsets.only(left: 12),
            dropdownIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            showCountryFlag: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Phone number',
              hintStyle: _hintTextStyle(),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              counterText: '',
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
            ),
            onChanged: onChanged,
            onCountryChanged: onCountryChanged,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.instrumentSans(
              fontSize: 12.5,
              color: _fieldError,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Dropdown styled identically to [MetafterField].
class MetafterDropdownField<T> extends StatelessWidget {
  const MetafterDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelTextStyle()),
        const SizedBox(height: 8),
        Container(
          height: _fieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _fieldFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              hint: hint == null ? null : Text(hint!, style: _hintTextStyle()),
              style: _inputTextStyle(),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
