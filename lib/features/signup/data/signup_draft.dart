import 'package:flutter/foundation.dart';

/// Lightweight in-memory model carrying the data the user enters across
/// the multi-step signup flow.
///
/// This is a deliberately simple `ChangeNotifier` so we don't have to add
/// a state-management dependency for the prototype. Replace with a Bloc /
/// repository call once the API is wired up.
class SignupDraft extends ChangeNotifier {
  SignupDraft._();
  static final SignupDraft instance = SignupDraft._();

  String name = '';
  String email = '';
  String phone = '';
  String countryCode = '+91';

  String role = '';
  String designation = '';
  String company = '';
  String introduction = '';

  /// Local file path / data uri of the uploaded profile photo.
  String? photoPath;

  /// Local file path / data uri of the captured selfie.
  String? selfiePath;

  void update(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void reset() {
    name = '';
    email = '';
    phone = '';
    countryCode = '+91';
    role = '';
    designation = '';
    company = '';
    introduction = '';
    photoPath = null;
    selfiePath = null;
    notifyListeners();
  }
}
