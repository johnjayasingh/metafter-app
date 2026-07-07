import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../../core/auth/cognito_auth_service.dart';
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
  final _email = TextEditingController();
  final _phone = TextEditingController();

  final _draft = SignupDraft.instance;

  /// When true we surface inline error messages on the fields. We only
  /// flip this on after the first submit attempt so users aren't shouted
  /// at while still typing.
  bool _showErrors = false;

  String _dialCode = '+91';
  String _isoCode = 'IN';
  bool _phoneValid = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name.text = _draft.name;
    _email.text = _draft.email;
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
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? get _nameError => SignupValidators.fullName(_name.text);

  /// Email is optional — only phone auth exists today, so the phone is the
  /// verification channel. A non-empty email must still be well-formed.
  String? get _emailError =>
      SignupValidators.email(_email.text, required: false);

  String? get _phoneError {
    if (_phone.text.trim().isEmpty) return 'Phone number is required';
    if (!_phoneValid) return 'Invalid phone number';
    return null;
  }

  bool get _isValid =>
      _nameError == null && _emailError == null && _phoneError == null;

  Future<void> _onNext() async {
    if (!_isValid || _submitting) {
      setState(() => _showErrors = true);
      return;
    }
    _draft.update(() {
      _draft.name = _name.text.trim();
      _draft.email = _email.text.trim();
      _draft.phone = _phone.text.trim();
      _draft.countryCode = _dialCode;
    });

    setState(() => _submitting = true);
    final e164 = '$_dialCode${_phone.text.trim()}';
    try {
      // Register the number if new, then start CUSTOM_AUTH so the backend
      // sends the SMS OTP. The pending Cognito session is held in-memory for
      // the OTP screen to answer.
      await CognitoAuthService.instance.signUpWithPhone(e164);
      await CognitoAuthService.instance.startSignIn(e164);
      if (mounted) context.push(AppRouter.signupOtp);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send code. $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      title: 'What should I call you?',
      bottomButton: MetafterPrimaryButton(
        label: _submitting ? 'Sending code…' : 'Next',
        onPressed: (_isValid && !_submitting) ? _onNext : null,
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
          MetafterField(
            label: 'Email ID (optional)',
            controller: _email,
            hint: 'lunaray@gmail.com',
            keyboardType: TextInputType.emailAddress,
            errorText: _showErrors ? _emailError : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          const _OrDivider(),
          const SizedBox(height: 18),
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

/// Centered "or" divider between the email and phone fields (§3.3).
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE0E0E0), height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE0E0E0), height: 1)),
      ],
    );
  }
}
