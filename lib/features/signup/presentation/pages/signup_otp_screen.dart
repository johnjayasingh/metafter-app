import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';

class SignupOtpScreen extends StatefulWidget {
  const SignupOtpScreen({super.key});

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
  static const int _length = 6;
  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _complete => _code.length == _length;

  void _onChanged(int i, String value) {
    if (value.isNotEmpty && i < _length - 1) {
      _focusNodes[i + 1].requestFocus();
    } else if (value.isEmpty && i > 0) {
      _focusNodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  void _onContinue() {
    // TODO: call backend verify-otp endpoint with _code.
    context.push(AppRouter.signupProfile);
  }

  @override
  Widget build(BuildContext context) {
    final draft = SignupDraft.instance;
    final destination = draft.email.isNotEmpty ? draft.email : draft.phone;

    return SignupScaffold(
      title: 'Almost there...',
      subtitle: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'We sent a verification code to your '),
            TextSpan(text: draft.email.isNotEmpty ? 'email id\n' : 'phone\n'),
            TextSpan(
              text: destination.isEmpty ? 'your account' : '$destination.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      bottomButton: MetafterPrimaryButton(
        label: 'Continue',
        onPressed: _complete ? _onContinue : null,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEBEC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: List.generate(_length, (i) {
            return Expanded(
              child: _OtpSlot(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (v) => _onChanged(i, v),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _OtpSlot extends StatelessWidget {
  const _OtpSlot({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      cursorColor: AppColors.brandRed,
      cursorHeight: 22,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.0,
      ),
      decoration: const InputDecoration(
        counterText: '',
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: onChanged,
    );
  }
}
