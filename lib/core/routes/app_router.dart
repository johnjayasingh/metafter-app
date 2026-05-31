import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/discovery_home_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/onboarding/presentation/pages/splash_screen.dart';
import '../../features/signup/presentation/pages/signup_basics_screen.dart';
import '../../features/signup/presentation/pages/signup_otp_screen.dart';
import '../../features/signup/presentation/pages/signup_photo_screen.dart';
import '../../features/signup/presentation/pages/signup_profile_screen.dart';
import '../../features/signup/presentation/pages/signup_selfie_screen.dart';
import '../../features/signup/presentation/pages/signup_verifying_screen.dart';
import '../../main.dart' as main_file;

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
        builder: (context, state) => const DiscoveryHomeScreen(),
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
