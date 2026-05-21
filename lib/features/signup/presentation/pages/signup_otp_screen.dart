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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus so the keyboard opens as soon as the screen mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _code => _controller.text;

  bool get _complete => _code.length == _length;

  void _onContinue() {
    // TODO: call backend verify-otp endpoint with _code.
    context.push(AppRouter.signupProfile);
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
        label: 'Continue',
        onPressed: _complete ? _onContinue : null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: Stack(
          children: [
            // Visible UI: a single grey pill split into 6 cells.
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
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
                      final isCurrent = _focusNode.hasFocus &&
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
