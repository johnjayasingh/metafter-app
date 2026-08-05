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
      final session = await FaceVerificationService.instance
          .startLiveness(photoPath: _draft.photoPath);
      _draft.update(() {
        _draft.livenessSessionId = session.sessionId;
        _draft.verificationPhotoKey = session.photoKey;
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
                ? 'Face scan isn’t available on this device. Try again on a '
                      'device with a working front camera.'
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

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      showBack: true,
      title: 'Verify it’s really you',
      subtitle: const Text(
        'We’ll run a quick face scan and match it with your profile photo to '
        'confirm your identity.',
      ),
      // The face scan is mandatory — there is no "skip for now" path, so the
      // verifying screen always has a liveness session to resolve.
      bottomButton: MetafterPrimaryButton(
        label: _running ? 'Starting…' : 'Start face scan',
        onPressed: _running ? null : _startScan,
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
          // This is the ONLY briefing the user gets: the SDK's own start view
          // is disabled so the scan opens straight into the camera rather than
          // into a second, off-brand intro.
          const _ScanHint(
            icon: Icons.light_mode_outlined,
            text: 'Find a well-lit spot and take off hats or sunglasses.',
          ),
          const SizedBox(height: 12),
          const _ScanHint(
            icon: Icons.center_focus_weak_rounded,
            text: 'Hold your face inside the oval until it fills the frame.',
          ),
          const SizedBox(height: 12),
          const _ScanHint(
            icon: Icons.timer_outlined,
            text: 'Stay still — the check takes a couple of seconds.',
          ),
        ],
      ),
    );
  }
}

/// One line of pre-scan guidance — icon plus copy, in the app's own styling.
class _ScanHint extends StatelessWidget {
  const _ScanHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brandRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
