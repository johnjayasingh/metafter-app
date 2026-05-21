import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';

/// Captures the live selfie that will be matched against the uploaded
/// profile photo for identity verification.
class SignupSelfieScreen extends StatefulWidget {
  const SignupSelfieScreen({super.key});

  @override
  State<SignupSelfieScreen> createState() => _SignupSelfieScreenState();
}

class _SignupSelfieScreenState extends State<SignupSelfieScreen> {
  final _draft = SignupDraft.instance;
  bool _captured = false;

  Future<void> _onCapture() async {
    // TODO: integrate camera plugin. For the prototype we mark a selfie as
    // captured so the verifying step can proceed.
    setState(() => _captured = true);
    _draft.update(() => _draft.selfiePath = '');
  }

  void _onContinue() {
    context.push(AppRouter.signupVerifying);
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      title: 'Take a quick selfie',
      subtitle: const Text(
        'We’ll match it with your profile photo to confirm it’s really you.',
      ),
      bottomButton: _captured
          ? MetafterPrimaryButton(label: 'Continue', onPressed: _onContinue)
          : MetafterPrimaryButton(
              label: 'Capture Selfie', onPressed: _onCapture),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 240,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _captured
                      ? AppColors.brandRed
                      : Colors.black.withValues(alpha: 0.08),
                  width: 2,
                ),
              ),
              child: _captured
                  ? const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.brandRed,
                        size: 72,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.textSecondary,
                        size: 56,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _captured
                ? 'Looks good — tap continue to verify.'
                : 'Hold your face inside the frame and tap capture.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
