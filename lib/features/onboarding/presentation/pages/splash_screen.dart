import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/cognito_auth_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/metafter_logo.dart';
import '../../../signup/data/signup_draft.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  /// Routes returning users straight to home. "Logged in" means either the
  /// legacy onboarded flag is set, OR a real Cognito session survived and a
  /// local profile exists — the latter covers users whose signup was
  /// interrupted before the final "Done" (so the flag was never persisted)
  /// yet who are genuinely authenticated. The session check runs alongside a
  /// minimum splash delay so the brand mark still shows for a beat.
  Future<void> _decideNext() async {
    final results = await Future.wait<Object?>([
      Future(() async {
        try {
          return await CognitoAuthService.instance.isSignedIn();
        } catch (_) {
          return false;
        }
      }),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;

    final signedIn = results[0] == true;
    final hasProfile =
        AppServices.isReady && AppServices.I.profile.profile.value != null;
    final onboarded = SignupDraft.instance.isOnboarded;
    final loggedIn = onboarded || (signedIn && hasProfile);

    context.go(loggedIn ? AppRouter.home : AppRouter.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    // The dolphin + ripple mark sits at roughly half the screen width.
    final logoSize = MediaQuery.of(context).size.shortestSide * 0.46;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.brandBlack,
        body: _SplashBackground(
          child: Center(
            child: MetafterLogo(
              variant: MetafterLogoVariant.white,
              height: logoSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandSunset),
      child: SafeArea(child: child),
    );
  }
}
