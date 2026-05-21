/// Centralized form constants for the application.
class FormConstants {
  FormConstants._();

  // ==================== Country Codes ====================

  /// Standard country code list used across phone inputs.
  static const List<String> countryCodes = [
    '+61', // Australia
    '+1',  // USA/Canada
    '+44', // UK
    '+91', // India
    '+64', // New Zealand
    '+65', // Singapore
    '+86', // China
    '+81', // Japan
  ];

  /// Default country code
  static const String defaultCountryCode = '+61';
}
