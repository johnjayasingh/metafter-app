import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/profile_api.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';
import 'signup_photo_screen.dart' show SignupProfileCard;

/// Final step: shows the user's profile card while we run the photo /
/// selfie similarity check in the background. The "Done" CTA simply
/// dismisses the flow — the verification continues server-side.
class SignupVerifyingScreen extends StatefulWidget {
  const SignupVerifyingScreen({super.key});

  @override
  State<SignupVerifyingScreen> createState() => _SignupVerifyingScreenState();
}

class _SignupVerifyingScreenState extends State<SignupVerifyingScreen> {
  Timer? _timer;
  bool _verified = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Simulate the async match check. Replace with API polling.
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _verified = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onDone() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final draft = SignupDraft.instance;

    // Push the collected profile to the backend now that the user is authed.
    // Best-effort: a sync hiccup shouldn't trap the user on this screen.
    try {
      await ProfileApi().putProfile(
        displayName: draft.name,
        headline: draft.designation.isNotEmpty ? draft.designation : draft.role,
        company: draft.company,
        bio: draft.introduction,
      );
      if (draft.photoPath != null && draft.photoPath!.isNotEmpty) {
        await ProfileApi().uploadPhoto(File(draft.photoPath!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile will finish syncing later. $e')),
        );
      }
    }

    // Persist the signup so the user stays signed in across launches.
    await draft.save();
    if (!mounted) return;
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    final draft = SignupDraft.instance;
    final subtitle = '${draft.designation.isEmpty ? "" : draft.designation}'
        '${draft.company.isEmpty ? "" : " - ${draft.company}"}';
    return SignupScaffold(
      title: _verified ? 'Verified!' : 'Verifying..',
      bottomButton: MetafterPrimaryButton(
        label: _submitting ? 'Finishing…' : 'Done',
        onPressed: _submitting ? null : _onDone,
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          SignupProfileCard(
            photoPath: null,
            name: draft.name,
            subtitle: subtitle,
          ),
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _verified
                  ? 'Your identity is verified. You can start meeting people around you.'
                  : 'We’re verifying your photo. You can continue while we verify your photo in the background.',
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
