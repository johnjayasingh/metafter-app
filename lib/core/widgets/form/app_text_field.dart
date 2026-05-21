import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/input_formatters.dart';

/// A reusable text field widget with consistent styling across the app.
/// 
/// Usage:
/// ```dart
/// AppTextField(
///   controller: _nameController,
///   label: 'Full name',
///   isRequired: true,
/// )
/// ```
class AppTextField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;
  
  /// The label text (displayed as floating label)
  final String label;
  
  /// Whether this field is required (adds * to label)
  final bool isRequired;
  
  /// The type of keyboard to show
  final TextInputType? keyboardType;
  
  /// Optional suffix icon (e.g., calendar icon for date fields)
  final IconData? suffixIcon;
  
  /// Optional suffix icon widget for custom icons
  final Widget? suffixIconWidget;
  
  /// Optional prefix icon
  final IconData? prefixIcon;
  
  /// Additional input formatters
  final List<TextInputFormatter>? inputFormatters;
  
  /// Custom validator function
  final String? Function(String?)? validator;
  
  /// Whether the field is read-only
  final bool readOnly;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Callback when the field is tapped (useful for date pickers)
  final VoidCallback? onTap;
  
  /// Callback when the text changes
  final ValueChanged<String>? onChanged;
  
  /// Maximum number of lines
  final int maxLines;
  
  /// Minimum number of lines
  final int? minLines;
  
  /// Maximum length of input
  final int? maxLength;
  
  /// Whether to obscure text (for passwords)
  final bool obscureText;
  
  /// Text capitalization behavior
  final TextCapitalization textCapitalization;
  
  /// Focus node for the field
  final FocusNode? focusNode;
  
  /// Auto-validate mode
  final AutovalidateMode? autovalidateMode;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.keyboardType,
    this.suffixIcon,
    this.suffixIconWidget,
    this.prefixIcon,
    this.inputFormatters,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure minLines never exceeds maxLines (guard against assertion errors)
    final effectiveMinLines = minLines != null
        ? (minLines! > maxLines ? maxLines : minLines!)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AppTextStyles.inputLabelExternal,
            children: isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: AppTextStyles.inputLabelExternal
                          .copyWith(color: AppColors.error),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLines,
          minLines: effectiveMinLines,
          maxLength: maxLength,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          focusNode: focusNode,
          autovalidateMode: autovalidateMode,
          inputFormatters: [
            NoLeadingSpaceFormatter(),
            ...?inputFormatters,
          ],
          validator: validator ?? (isRequired ? _defaultRequiredValidator : null),
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIconWidget ?? (suffixIcon != null
                ? Icon(suffixIcon, size: 20, color: AppColors.textSecondary)
                : null),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.textSecondary)
                : null,
          ),
        ),
      ],
    );
  }

  String? _defaultRequiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}

/// A specialized email text field with built-in validation
class AppEmailField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? additionalValidator;

  const AppEmailField({
    super.key,
    required this.controller,
    this.label = 'Email address',
    this.isRequired = true,
    this.enabled = true,
    this.onChanged,
    this.additionalValidator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      isRequired: isRequired,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Please enter email address';
        }
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'Please enter a valid email address';
          }
        }
        // Run additional validation (e.g., duplicate check)
        if (additionalValidator != null) {
          final additionalError = additionalValidator!(value);
          if (additionalError != null) return additionalError;
        }
        return null;
      },
    );
  }
}

/// A specialized text area for multi-line input.
///
/// Shows a minimum of 3 visible lines and auto-expands as the user types.
/// No internal scrolling — the field grows to fit all content.
class AppTextArea extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final bool isRequired;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const AppTextArea({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.isRequired = false,
    this.maxLines = 8,
    this.minLines,
    this.maxLength,
    this.onChanged,
  });

  @override
  State<AppTextArea> createState() => _AppTextAreaState();
}

class _AppTextAreaState extends State<AppTextArea> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Trigger rebuild so the ConstrainedBox recalculates with new content
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Guarantee at least 3 visible lines
    final effectiveMinLines = (widget.minLines != null && widget.minLines! > 3)
        ? widget.minLines!
        : 4;

    // Calculate minimum height: lines * lineHeight + vertical padding
    const double fontSize = 14.0;
    const double lineHeight = 1.5;
    const double verticalPadding = 32.0; // 16 top + 16 bottom
    final double minHeight =
        (effectiveMinLines * fontSize * lineHeight) + verticalPadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            style: AppTextStyles.inputLabelExternal,
            children: widget.isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: AppTextStyles.inputLabelExternal
                          .copyWith(color: AppColors.error),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            minLines: effectiveMinLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            textCapitalization: TextCapitalization.sentences,
            validator: widget.isRequired
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'This field is required' : null
                : null,
            style: AppTextStyles.inputText.copyWith(height: lineHeight),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppTextStyles.inputLabel,
              filled: true,
              fillColor: AppColors.backgroundWhite,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

