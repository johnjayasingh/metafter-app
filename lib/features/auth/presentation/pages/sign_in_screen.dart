import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/config/environment_config.dart';
import '../../../../core/constants/debug_config.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: DebugConfig.usePrepopulatedData
        ? DebugConfig.testSignIn['email'] as String
        : '',
  );
  final _passwordController = TextEditingController(
    text: DebugConfig.usePrepopulatedData
        ? DebugConfig.testSignIn['password'] as String
        : '',
  );
  bool _isPasswordVisible = false;
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Trigger login event
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Future<void> _viewOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, true);
    if (!mounted) return;
    context.go(AppRouter.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !EnvironmentConfig.isProduction
          ? PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: EnvironmentConfig.isLocal
                    ? Colors.purple.withOpacity(0.9)
                    : EnvironmentConfig.isDev
                    ? Colors.orange.withOpacity(0.9)
                    : Colors.blue.withOpacity(0.9),
                centerTitle: true,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${EnvironmentConfig.environmentName} BUILD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (_version.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        'v$_version ($_buildNumber)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            // Navigate to home
            context.go(AppRouter.home);
          } else if (state.status == AuthStatus.mfaSetupRequired) {
            // Navigate to MFA setup screen
            context.push(
              '/mfa-setup',
              extra: {'session': state.session, 'qrData': state.qrData},
            );
          } else if (state.status == AuthStatus.mfaChallengeRequired) {
            // Navigate to MFA challenge screen
            context.push(
              '/mfa-challenge',
              extra: {
                'session': state.session,
                'challengeType': state.challengeType,
              },
            );
          } else if (state.status == AuthStatus.otpVerificationRequired) {
            // Navigate to OTP verification (account not activated)
            context.push(
              '/otp-verification',
              extra: {
                'sessionId': state.sessionId ?? '',
                'email': state.email ?? '',
              },
            );
          } else if (state.status == AuthStatus.error) {
            final errorMsg = state.errorMessage ?? 'An error occurred';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state.isLoading;

            return Container(
              decoration: BoxDecoration(color: AppColors.cardBackground),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 40,
                                  ),

                                  // Logo
                                  Center(
                                    child: SvgPicture.asset(
                                      'assets/images/logo.svg',
                                      width: 134.scaled(context),
                                      height: 24.scaled(context),
                                    ),
                                  ),

                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 32,
                                  ),

                                  // Welcome title
                                  Text(
                                    'Welcome to Willcloud',
                                    style: AppTextStyles.welcomeTitle,
                                    textAlign: TextAlign.center,
                                  ),

                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 12,
                                  ),

                                  // Description
                                  Text(
                                    'Securely access your account to continue creating or reviewing your will.',
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                      color: AppColors.subscriptionDescription,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 48,
                                  ),

                                  // Social Login Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSocialButton(
                                          'assets/images/google_icon.svg',
                                          _showComingSoon,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSocialButton(
                                          'assets/images/apple_icon.svg',
                                          _showComingSoon,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSocialButton(
                                          'assets/images/x_icon.png',
                                          _showComingSoon,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSocialButton(
                                          'assets/images/facebook_icon.svg',
                                          _showComingSoon,
                                        ),
                                      ),
                                    ],
                                  ),

                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 24,
                                  ),

                                  // OR Divider
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          color: AppColors.borderLightGray,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'or',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textGray,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          color: AppColors.borderLightGray,
                                        ),
                                      ),
                                    ],
                                  ),

                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 12,
                                  ),

                                  // Sign in card
                                  Container(
                                    padding: const EdgeInsets.only(
                                      top: 24,
                                      bottom: 24,
                                      left: 0,
                                      right: 0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Email field
                                        AppTextField(
                                          controller: _emailController,
                                          label: 'Email',
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!value.contains('@')) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Password field
                                        AppTextField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          obscureText: !_isPasswordVisible,
                                          suffixIconWidget: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible =
                                                    !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Terms and Privacy text
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontSize: 14,
                                                color: AppColors.subscriptionDescription,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      'By continuing, you agree to our ',
                                                ),
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryGreen,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: TextStyle(
                                                    decoration: TextDecoration
                                                        .underline,
                                                    color:
                                                        AppColors.primaryGreen,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Sign in button
                                        AppPrimaryButton(
                                          text: 'Sign In',
                                          onPressed: _signIn,
                                          isLoading: isLoading,
                                        ),

                                        const SizedBox(height: 24),

                                        // Forgot password
                                        Center(
                                          child: AppTextButton(
                                            text: 'Forgot password?',
                                            onPressed: _viewOnboarding,
                                            color: AppColors.primaryVeryDarkGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  // Sign up link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'New to Willcloud? ',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      AppTextButton(
                                        text: 'Sign up',
                                        onPressed: () {
                                          context.go(AppRouter.signUp);
                                        },
                                        color: AppColors.primaryGreen,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // View onboarding link
                                  // Center(
                                  //   child: TextButton(
                                  //     onPressed: _viewOnboarding,
                                  //     child: Text(
                                  //       'View Onboarding',
                                  //       style: Theme.of(context).textTheme.bodyMedium
                                  //           ?.copyWith(
                                  //             color: AppColors.primaryDarkGreen,
                                  //             decoration: TextDecoration.underline,
                                  //           ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSocialButton(String assetPath, VoidCallback onPressed) {
    final isPng = assetPath.endsWith('.png');

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 39.scaled(context),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: isPng
              ? Image.asset(assetPath, width: 20, height: 20)
              : SvgPicture.asset(assetPath, width: 20, height: 20),
        ),
      ),
    );
  }
}
