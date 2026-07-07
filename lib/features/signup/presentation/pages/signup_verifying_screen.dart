import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/cognito_auth_service.dart';
import '../../../../core/domain/models.dart';
import '../../../../core/face/face_verification_service.dart';
import '../../../../core/network/profile_api.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/services/bootstrap_services.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';
import 'signup_photo_screen.dart' show SignupProfileCard;

enum _VerifyState { verifying, verified, failed, skipped }

/// Final signup step (DESIGN_SPEC §3.7 "Verifying..").
///
/// Local-first: the profile row is persisted to the on-device DB and the
/// relay transport is connected BEFORE the verification verdict resolves —
/// verification only adds the badge. Nothing here may block "Done": every
/// network step is best-effort.
class SignupVerifyingScreen extends StatefulWidget {
  const SignupVerifyingScreen({super.key});

  @override
  State<SignupVerifyingScreen> createState() => _SignupVerifyingScreenState();
}

class _SignupVerifyingScreenState extends State<SignupVerifyingScreen> {
  final _draft = SignupDraft.instance;
  _VerifyState _state = _VerifyState.verifying;
  IdentityVerificationResult? _result;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // 1. Persist the local profile first — it is the post-signup source of
    //    truth (the backend stores no profile data).
    await _saveLocalProfile();

    // 2. Bring the relay up so our public keys reach the directory.
    //    connectTransport already swallows failures internally.
    if (AppServices.isReady) {
      await connectTransport();
    }

    // 3. Resolve the verification verdict (if a liveness session ran).
    await _resolve();
  }

  Future<void> _saveLocalProfile() async {
    try {
      String? sub;
      try {
        sub = await CognitoAuthService.instance.currentSub();
      } catch (e) {
        debugPrint('currentSub failed: $e');
      }
      sub ??= await SecureStorageService().getUserId();
      if (sub == null || sub.isEmpty) {
        debugPrint('No sub available — profile save deferred');
        return;
      }
      if (!AppServices.isReady) {
        debugPrint('AppServices not ready — profile save deferred');
        return;
      }
      final existing = AppServices.I.profile.profile.value;
      await AppServices.I.profile.save(MyProfile(
        sub: sub,
        name: _draft.name,
        role: _draft.role,
        designation: _draft.designation,
        company: _draft.company,
        intro: _draft.introduction,
        photoPath: _draft.photoPath,
        verified: existing?.verified ?? false,
        verifiedBadgeSig: existing?.verifiedBadgeSig,
      ));
    } catch (e) {
      // Best-effort — a local hiccup must not trap the user here.
      debugPrint('Local profile save failed: $e');
    }
  }

  Future<void> _resolve() async {
    final sessionId = _draft.livenessSessionId;
    final photoKey = _draft.verificationPhotoKey;
    if (sessionId == null || photoKey == null) {
      // Liveness was skipped / unavailable — nothing to resolve.
      if (mounted) setState(() => _state = _VerifyState.skipped);
      return;
    }
    if (mounted) setState(() => _state = _VerifyState.verifying);
    try {
      final result =
          await FaceVerificationService.instance.resolve(sessionId, photoKey);
      if (result.verified) {
        final badgeSig = result.badgeSig;
        if (badgeSig != null && badgeSig.isNotEmpty && AppServices.isReady) {
          try {
            await AppServices.I.profile.markVerified(badgeSig);
          } catch (e) {
            debugPrint('markVerified failed: $e');
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = result.verified ? _VerifyState.verified : _VerifyState.failed;
      });
    } catch (e) {
      debugPrint('Verification resolution failed: $e');
      if (!mounted) return;
      setState(() => _state = _VerifyState.failed);
    }
  }

  Future<void> _onDone() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    // The draft stays around for re-login prefill; the MyProfile row saved in
    // [_run] is the post-signup source of truth.
    await _draft.save();
    if (!mounted) return;
    context.go(AppRouter.home);
  }

  String get _title {
    switch (_state) {
      case _VerifyState.verifying:
        return 'Verifying..';
      case _VerifyState.verified:
        return 'Verified!';
      case _VerifyState.failed:
        return 'Couldn’t verify';
      case _VerifyState.skipped:
        return 'Almost done';
    }
  }

  String get _message {
    switch (_state) {
      case _VerifyState.verifying:
        return 'We’re verifying your photo. You can continue while we verify your photo in the background.';
      case _VerifyState.verified:
        return 'Your identity is verified. You can start meeting people around you.';
      case _VerifyState.failed:
        final reason = _result?.reason;
        if (reason == 'liveness_failed') {
          return 'The face scan didn’t pass our liveness check. Please try again in good lighting.';
        }
        if (reason == 'face_mismatch') {
          return 'Your face scan didn’t match your profile photo. Try again, or continue and verify later.';
        }
        return 'We couldn’t verify your identity right now. You can try again or continue and verify later.';
      case _VerifyState.skipped:
        return 'You can verify your identity anytime from your profile to unlock a verified badge.';
    }
  }

  Widget _bottom() {
    if (_state == _VerifyState.verifying) {
      // Verification must not block entry (DESIGN_SPEC §3.7).
      return MetafterPrimaryButton(
        label: _submitting ? 'Finishing…' : 'Done',
        onPressed: _submitting ? null : _onDone,
      );
    }
    if (_state == _VerifyState.failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MetafterPrimaryButton(
            label: 'Try again',
            onPressed: _submitting ? null : () => context.pop(),
          ),
          TextButton(
            onPressed: _submitting ? null : _onDone,
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(
              _submitting ? 'Finishing…' : 'Continue anyway',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }
    // verified / skipped
    return MetafterPrimaryButton(
      label: _submitting ? 'Finishing…' : 'Done',
      onPressed: _submitting ? null : _onDone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = '${_draft.designation.isEmpty ? "" : _draft.designation}'
        '${_draft.company.isEmpty ? "" : " - ${_draft.company}"}';
    return SignupScaffold(
      title: _title,
      bottomButton: _bottom(),
      child: Column(
        children: [
          const SizedBox(height: 24),
          SignupProfileCard(
            photoPath:
                (_draft.photoPath ?? '').isNotEmpty ? _draft.photoPath : null,
            name: _draft.name,
            subtitle: subtitle,
          ),
          const SizedBox(height: 48),
          if (_state == _VerifyState.verifying)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: CircularProgressIndicator(color: AppColors.brandRed),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
