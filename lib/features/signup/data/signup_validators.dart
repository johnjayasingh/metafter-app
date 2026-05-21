/// Lightweight, framework-agnostic validators used by the signup forms.
///
/// Each function returns `null` when the input is valid, or a
/// human-readable error string otherwise — mirroring Flutter's
/// `FormFieldValidator<String>` signature so it can be passed directly to
/// `TextFormField.validator` later if we migrate to `Form`.
class SignupValidators {
  SignupValidators._();

  /// Full name must be at least two words, each ≥ 2 characters, letters
  /// (with allowance for `-`, `'`, `.` and accents).
  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your full name';
    final parts =
        v.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return 'Please enter your first and last name';
    final namePart = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ'’\-\.]{2,}$");
    for (final p in parts) {
      if (!namePart.hasMatch(p)) {
        return 'Use letters only (min 2 characters per name)';
      }
    }
    return null;
  }

  /// Standard email regex. Allows the common subset; rejects spaces.
  static final RegExp _emailRe = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  static String? email(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Please enter your email' : null;
    if (!_emailRe.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Phone must be exactly 10 digits (India / default). Country-code aware
  /// validation can be added later.
  static String? phone(String? value, {bool required = true}) {
    final v = (value ?? '').replaceAll(RegExp(r'\s+'), '');
    if (v.isEmpty) return required ? 'Please enter your phone number' : null;
    if (!RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }
}
