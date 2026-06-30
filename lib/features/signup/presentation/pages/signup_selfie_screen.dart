import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/face/face_liveness_channel.dart';
import '../../../../core/face/face_verification_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';

/// Runs a live face scan (Amazon Rekognition Face Liveness) via the native
/// liveness UI, then hands off to the verifying screen which resolves whether
/// the live face matches the uploaded profile photo.
class SignupSelfieScreen extends StatefulWidget {
  const SignupSelfieScreen({super.key});

  @override
  State<SignupSelfieScreen> createState() => _SignupSelfieScreenState();
}

class _SignupSelfieScreenState extends State<SignupSelfieScreen> {
  final _draft = SignupDraft.instance;
  bool _running = false;

  Future<void> _startScan() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      final sessionId = await FaceVerificationService.instance
          .startLiveness(photoPath: _draft.photoPath);
      _draft.update(() {
        _draft.livenessSessionId = sessionId;
        _draft.photoUploaded = true;
      });
      if (!mounted) return;
      // Reset before navigating so the screen is interactive if the user pops
      // back here to retry after a failed verification.
      setState(() => _running = false);
      context.push(AppRouter.signupVerifying);
    } on FaceLivenessException catch (e) {
      if (!mounted) return;
      setState(() => _running = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.isUnavailable
                ? 'Face scan isn’t available here — you can skip and verify later.'
                : 'Face scan didn’t complete: ${e.message}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _running = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t start the face scan. $e')),
      );
    }
  }

  void _skip() {
    _draft.update(() => _draft.livenessSessionId = null);
    context.push(AppRouter.signupVerifying);
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      showBack: true,
      title: 'Verify it’s really you',
      subtitle: const Text(
        'We’ll run a quick face scan and match it with your profile photo to '
        'confirm your identity.',
      ),
      bottomButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MetafterPrimaryButton(
            label: _running ? 'Starting…' : 'Start face scan',
            onPressed: _running ? null : _startScan,
          ),
          TextButton(
            onPressed: _running ? null : _skip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text(
              'Skip for now',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    color: AppColors.textSecondary,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hold your face inside the circle and follow the on-screen prompts.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
