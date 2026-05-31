import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../../core/routes/app_router.dart';
import '../../data/signup_draft.dart';
import '../../data/signup_validators.dart';
import '../widgets/metafter_field.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';

class SignupBasicsScreen extends StatefulWidget {
  const SignupBasicsScreen({super.key});

  @override
  State<SignupBasicsScreen> createState() => _SignupBasicsScreenState();
}

class _SignupBasicsScreenState extends State<SignupBasicsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  final _draft = SignupDraft.instance;

  /// When true we surface inline error messages on the fields. We only
  /// flip this on after the first submit attempt so users aren't shouted
  /// at while still typing.
  bool _showErrors = false;

  String _dialCode = '+91';
  String _isoCode = 'IN';
  bool _phoneValid = false;

  @override
  void initState() {
    super.initState();
    _name.text = _draft.name;
    _phone.text = _draft.phone;
    if (_draft.countryCode.isNotEmpty) {
      _dialCode = _draft.countryCode;
    }
    // Treat a prefilled non-empty phone as valid optimistically; the
    // IntlPhoneField will re-validate on the next edit.
    if (_phone.text.trim().isNotEmpty) {
      _phoneValid = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? get _nameError => SignupValidators.fullName(_name.text);

  String? get _phoneError {
    if (_phone.text.trim().isEmpty) return 'Phone number is required';
    if (!_phoneValid) return 'Invalid phone number';
    return null;
  }

  bool get _isValid => _nameError == null && _phoneError == null;

  void _onNext() {
    if (!_isValid) {
      setState(() => _showErrors = true);
      return;
    }
    _draft.update(() {
      _draft.name = _name.text.trim();
      _draft.phone = _phone.text.trim();
      _draft.countryCode = _dialCode;
    });
    context.push(AppRouter.signupOtp);
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      title: 'What should I call you?',
      bottomButton: MetafterPrimaryButton(
        label: 'Next',
        onPressed: _isValid ? _onNext : null,
      ),
      child: Column(
        children: [
          MetafterField(
            label: 'Name',
            controller: _name,
            hint: 'Luna Ray',
            textCapitalization: TextCapitalization.words,
            errorText: _showErrors ? _nameError : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          MetafterPhoneField(
            controller: _phone,
            initialCountryCode: _isoCode,
            errorText: _showErrors ? _phoneError : null,
            onChanged: (PhoneNumber number) {
              setState(() {
                _dialCode = '+${number.countryCode.replaceAll('+', '')}';
                _phoneValid = _isCompleteNumber(number);
              });
            },
            onCountryChanged: (country) {
              setState(() {
                _isoCode = country.code;
                _dialCode = '+${country.dialCode}';
              });
            },
          ),
        ],
      ),
    );
  }

  /// `intl_phone_field` doesn't expose a sync isValid getter, so we mirror
  /// its built-in length check: the national number length must fall inside
  /// the country's allowed range.
  bool _isCompleteNumber(PhoneNumber number) {
    try {
      return number.isValidNumber();
    } catch (_) {
      return false;
    }
  }
}
