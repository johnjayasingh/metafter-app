import 'package:flutter/services.dart';

/// Input formatter that prevents leading spaces
/// Allows spaces after the first character but not at the beginning
class NoLeadingSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value starts with a space, reject it
    if (newValue.text.startsWith(' ')) {
      // Remove leading spaces
      final trimmedText = newValue.text.trimLeft();
      return TextEditingValue(
        text: trimmedText,
        selection: TextSelection.collapsed(
          offset: trimmedText.length.clamp(0, trimmedText.length),
        ),
      );
    }
    return newValue;
  }
}

/// Input formatter that trims spaces from both ends
class TrimSpacesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Don't trim while typing, only prevent leading spaces
    if (newValue.text.startsWith(' ')) {
      final trimmedText = newValue.text.trimLeft();
      return TextEditingValue(
        text: trimmedText,
        selection: TextSelection.collapsed(
          offset: trimmedText.length.clamp(0, trimmedText.length),
        ),
      );
    }
    return newValue;
  }
}
