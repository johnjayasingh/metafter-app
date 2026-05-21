import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _name.text = _draft.name;
    _email.text = _draft.email;
    _phone.text = _draft.phone;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? get _nameError => SignupValidators.fullName(_name.text);

  /// Email / phone are an either-or pair. We only require both formats to
  /// pass if the user actually filled in that field.
  String? get _emailError {
    if (_email.text.trim().isEmpty && _phone.text.trim().isNotEmpty) {
      return null;
    }
    return SignupValidators.email(_email.text,
        required: _phone.text.trim().isEmpty);
  }

  String? get _phoneError {
    if (_phone.text.trim().isEmpty && _email.text.trim().isNotEmpty) {
      return null;
    }
    return SignupValidators.phone(_phone.text,
        required: _email.text.trim().isEmpty);
  }

  bool get _isValid =>
      _nameError == null && _emailError == null && _phoneError == null;

  void _onNext() {
    if (!_isValid) {
      setState(() => _showErrors = true);
      return;
    }
    _draft.update(() {
      _draft.name = _name.text.trim();
      _draft.email = _email.text.trim();
      _draft.phone = _phone.text.trim();
    });
    context.push(AppRouter.signupOtp);
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      title: 'What should I call you?',
      bottomButton: MetafterPrimaryButton(
        label: 'Next',
        onPressed: _onNext,
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
            label: 'Email ID',
            controller: _email,
            hint: 'lunaray@gmail.com',
            keyboardType: TextInputType.emailAddress,
            errorText: _showErrors ? _emailError : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const _OrDivider(),
          const SizedBox(height: 12),
          MetafterPhoneField(
            controller: _phone,
            errorText: _showErrors ? _phoneError : null,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              )),
        ),
        const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
      ],
    );
  }
}
