/// Utility for validating that phone numbers and emails are unique
/// across all entities in the will (partners, dependents, beneficiaries, etc.)
class ContactValidator {
  /// List of existing contacts to validate against
  /// Each entry is a map with 'email', 'mobile', and 'name' keys
  final List<ExistingContact> _existingContacts;

  ContactValidator(this._existingContacts);

  /// Check if an email is already used by another person
  /// Returns the name of the person using it, or null if unique
  String? checkDuplicateEmail(String email, {int? excludeId}) {
    if (email.trim().isEmpty) return null;
    final normalizedEmail = email.trim().toLowerCase();
    for (final contact in _existingContacts) {
      if (contact.id != null && contact.id == excludeId) continue;
      if (contact.email.trim().toLowerCase() == normalizedEmail) {
        return contact.name;
      }
    }
    return null;
  }

  /// Check if a phone number is already used by another person
  /// Returns the name of the person using it, or null if unique
  String? checkDuplicatePhone(String phone, {int? excludeId}) {
    if (phone.trim().isEmpty) return null;
    // Normalize phone: remove spaces, dashes, etc.
    final normalizedPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    for (final contact in _existingContacts) {
      if (contact.id != null && contact.id == excludeId) continue;
      final existingNormalized = contact.mobile.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (existingNormalized == normalizedPhone && normalizedPhone.isNotEmpty) {
        return contact.name;
      }
    }
    return null;
  }

  /// Validate email uniqueness and return error message if duplicate
  String? validateEmailUnique(String? value, {int? excludeId}) {
    if (value == null || value.trim().isEmpty) return null;
    final duplicateName = checkDuplicateEmail(value, excludeId: excludeId);
    if (duplicateName != null) {
      return 'This email is already used by $duplicateName';
    }
    return null;
  }

  /// Validate phone uniqueness and return error message if duplicate
  String? validatePhoneUnique(String? fullPhone, {int? excludeId}) {
    if (fullPhone == null || fullPhone.trim().isEmpty) return null;
    final duplicateName = checkDuplicatePhone(fullPhone, excludeId: excludeId);
    if (duplicateName != null) {
      return 'This phone number is already used by $duplicateName';
    }
    return null;
  }
}

/// Represents an existing contact for duplicate validation
class ExistingContact {
  final int? id;
  final String name;
  final String email;
  final String mobile;

  const ExistingContact({
    this.id,
    required this.name,
    required this.email,
    required this.mobile,
  });
}
