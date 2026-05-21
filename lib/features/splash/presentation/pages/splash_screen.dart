import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/config/environment_config.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPackageInfo();
    _navigateToNext();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(AppConstants.splashDuration);
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
    
    if (!mounted) return;
    
    if (isFirstLaunch) {
      context.go(AppRouter.onboarding);
      return;
    }

    // Wait for the AuthBloc to finish its auth check (including token refresh)
    final authBloc = context.read<AuthBloc>();
    final currentState = authBloc.state;

    if (currentState.status == AuthStatus.authenticated) {
      context.go(AppRouter.home);
    } else if (currentState.status == AuthStatus.unauthenticated ||
               currentState.status == AuthStatus.error) {
      context.go(AppRouter.signIn);
    } else {
      // Still loading — listen for the final result
      await for (final state in authBloc.stream) {
        if (!mounted) return;
        if (state.status == AuthStatus.authenticated) {
          context.go(AppRouter.home);
          return;
        } else if (state.status == AuthStatus.unauthenticated ||
                   state.status == AuthStatus.error) {
          context.go(AppRouter.signIn);
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!EnvironmentConfig.isProduction)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: EnvironmentConfig.isLocal
                          ? Colors.purple.withOpacity(0.9)
                          : EnvironmentConfig.isDev
                          ? Colors.orange.withOpacity(0.9)
                          : Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          EnvironmentConfig.environmentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_version.isNotEmpty)
                          Text(
                            'v$_version ($_buildNumber)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                // Logo SVG
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 200,
                  height: 50,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
