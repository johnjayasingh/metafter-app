import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/onboarding/presentation/pages/splash_screen.dart';
import '../../features/signup/presentation/pages/signup_basics_screen.dart';
import '../../features/signup/presentation/pages/signup_otp_screen.dart';
import '../../features/signup/presentation/pages/signup_photo_screen.dart';
import '../../features/signup/presentation/pages/signup_profile_screen.dart';
import '../../features/signup/presentation/pages/signup_selfie_screen.dart';
import '../../features/signup/presentation/pages/signup_verifying_screen.dart';
import '../../main.dart' as main_file;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Minimal app router skeleton.
///
/// Add new routes by declaring a `static const String` route name and a
/// matching `GoRoute` entry in [router]. Feature modules should add their
/// own routes here (or expose a helper that returns a `List<RouteBase>`).
class AppRouter {
  AppRouter._();

  // Route paths
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  // Signup flow
  static const String signupBasics = '/signup';
  static const String signupOtp = '/signup/otp';
  static const String signupProfile = '/signup/profile';
  static const String signupPhoto = '/signup/photo';
  static const String signupSelfie = '/signup/selfie';
  static const String signupVerifying = '/signup/verifying';

  static final GoRouter router = GoRouter(
    navigatorKey: main_file.navigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const _HomePlaceholder(),
      ),
      GoRoute(
        path: signupBasics,
        builder: (context, state) => const SignupBasicsScreen(),
      ),
      GoRoute(
        path: signupOtp,
        builder: (context, state) => const SignupOtpScreen(),
      ),
      GoRoute(
        path: signupProfile,
        builder: (context, state) => const SignupProfileScreen(),
      ),
      GoRoute(
        path: signupPhoto,
        builder: (context, state) => const SignupPhotoScreen(),
      ),
      GoRoute(
        path: signupSelfie,
        builder: (context, state) => const SignupSelfieScreen(),
      ),
      GoRoute(
        path: signupVerifying,
        builder: (context, state) => const SignupVerifyingScreen(),
      ),
    ],
  );
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('Metafter', style: AppTextStyles.sectionTitle),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, size: 72, color: AppColors.primaryDarkGreen),
              const SizedBox(height: 24),
              Text('Welcome to Metafter', style: AppTextStyles.welcomeTitle),
              const SizedBox(height: 8),
              Text(
                'Start building your features under lib/features/.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
