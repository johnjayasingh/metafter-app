import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/metafter_logo.dart';
import '../../../signup/data/signup_draft.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      // Skip onboarding if the user has already completed signup.
      final next = SignupDraft.instance.isOnboarded
          ? AppRouter.home
          : AppRouter.onboarding;
      context.go(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
