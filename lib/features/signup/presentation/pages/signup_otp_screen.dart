import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/cognito_auth_service.dart';
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

  /// Seconds before "Resend" becomes tappable again after a send.
  static const int _resendCooldownSeconds = 30;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _cooldownTimer;
  int _cooldown = _resendCooldownSeconds;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus so the keyboard opens as soon as the screen mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // A code was just sent by the previous screen — start the cooldown.
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _verifying = false;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        if (_cooldown > 0) _cooldown--;
        if (_cooldown == 0) t.cancel();
      });
    });
  }

  /// Re-runs the CUSTOM_AUTH challenge for the same number — the backend
  /// Lambda sends a fresh SMS and [CognitoAuthService.answerOtp] validates
  /// against the new code.
  Future<void> _onResend() async {
    if (_cooldown > 0 || _resending || _verifying) return;
    final draft = SignupDraft.instance;
    final e164 = '${draft.countryCode}${draft.phone}';
    setState(() => _resending = true);
    try {
      await CognitoAuthService.instance.startSignIn(e164);
      if (!mounted) return;
      _controller.clear();
      _focusNode.requestFocus();
      _startCooldown();
      _showError('New code sent to ${draft.countryCode} ${draft.phone}.');
    } catch (_) {
      if (mounted) _showError('Could not resend the code. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  /// Back to the phone-entry screen; the draft keeps the typed number so the
  /// user only edits what's wrong.
  void _onChangeNumber() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.signupBasics);
    }
  }

  String get _code => _controller.text;

  bool get _complete => _code.length == _length;

  Future<void> _onContinue() async {
    if (!_complete || _verifying) return;
    setState(() => _verifying = true);
    try {
      final ok = await CognitoAuthService.instance.answerOtp(_code);
      if (!mounted) return;
      if (ok) {
        context.push(AppRouter.signupProfile);
        return;
      }
      _showError('That code didn\'t match. Try again.');
    } catch (_) {
      if (mounted) _showError('Incorrect or expired code. Request a new one.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final draft = SignupDraft.instance;
    final destination = draft.phone;

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
            const TextSpan(text: 'We sent a verification code to your\n'),
            TextSpan(
              text: destination.isEmpty
                  ? 'phone'
                  : 'phone ${draft.countryCode} $destination.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      bottomButton: MetafterPrimaryButton(
        label: _verifying ? 'Verifying…' : 'Continue',
        onPressed: (_complete && !_verifying) ? _onContinue : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _otpField(),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                "Didn't get the code?",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _onResend,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    _resending
                        ? 'Sending…'
                        : (_cooldown > 0
                              ? 'Resend in ${_cooldown}s'
                              : 'Resend code'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: (_cooldown == 0 && !_resending)
                          ? AppColors.brandRed
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _onChangeNumber,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Change number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpField() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          // Visible UI: a single grey pill split into 6 cells.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEBEC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _focusNode]),
              builder: (context, _) {
                return Row(
                  children: List.generate(_length, (i) {
                    final digits = _controller.text;
                    final char = i < digits.length ? digits[i] : '';
                    final isCurrent =
                        _focusNode.hasFocus &&
                        i == digits.length.clamp(0, _length - 1) &&
                        digits.length < _length;
                    return Expanded(
                      child: SizedBox(
                        height: 24,
                        child: Center(
                          child: char.isNotEmpty
                              ? Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : (isCurrent
                                    ? const _BlinkingCursor()
                                    : const SizedBox.shrink()),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          // Invisible TextField captures keyboard input.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: _length,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical brand-red bar that blinks at ~1Hz to mark the active OTP cell.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final visible = _ctrl.value < 0.5;
        return Container(
          width: 2,
          height: 22,
          color: visible ? AppColors.brandRed : Colors.transparent,
        );
      },
    );
  }
}
