import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/face/face_verification_service.dart';
import '../../../../core/network/profile_api.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';
import 'signup_photo_screen.dart' show SignupProfileCard;

enum _VerifyState { verifying, verified, failed, skipped }

/// Resolves the identity-verification verdict for the liveness session started
/// on the previous screen, then lets the user finish signup.
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
    _resolve();
  }

  Future<void> _resolve() async {
    final sessionId = _draft.livenessSessionId;
    if (sessionId == null) {
      // Liveness was skipped / unavailable — nothing to resolve.
      setState(() => _state = _VerifyState.skipped);
      return;
    }
    setState(() => _state = _VerifyState.verifying);
    try {
      final result = await FaceVerificationService.instance.resolve(sessionId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = result.verified ? _VerifyState.verified : _VerifyState.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _VerifyState.failed);
    }
  }

  Future<void> _onDone() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    // Best-effort: a sync hiccup shouldn't trap the user on this screen.
    try {
      await ProfileApi().putProfile(
        displayName: _draft.name,
        headline:
            _draft.designation.isNotEmpty ? _draft.designation : _draft.role,
        company: _draft.company,
        bio: _draft.introduction,
      );
      // If liveness was skipped, the photo was never uploaded — do it now.
      if (!_draft.photoUploaded &&
          _draft.photoPath != null &&
          _draft.photoPath!.isNotEmpty) {
        await ProfileApi().uploadPhoto(File(_draft.photoPath!));
        _draft.photoUploaded = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile will finish syncing later. $e')),
        );
      }
    }

    await _draft.save();
    if (!mounted) return;
    context.go(AppRouter.home);
  }

  String get _title {
    switch (_state) {
      case _VerifyState.verifying:
        return 'Verifying…';
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
        return 'We’re matching your face scan with your profile photo. This only takes a moment.';
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
      return const MetafterPrimaryButton(label: 'Verifying…', onPressed: null);
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
            photoPath: null,
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
