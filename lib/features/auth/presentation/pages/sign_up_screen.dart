import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/debug_config.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    if (DebugConfig.usePrepopulatedData) {
      _firstNameController.text = DebugConfig.testSignUp['firstName'] as String;
      _lastNameController.text = DebugConfig.testSignUp['lastName'] as String;
      _emailController.text = DebugConfig.testSignUp['email'] as String;
      _passwordController.text = DebugConfig.testSignUp['password'] as String;
      _confirmPasswordController.text =
          DebugConfig.testSignUp['confirmPassword'] as String;
      _acceptedTerms = true;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignupRequested(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.otpVerificationRequired) {
            // Navigate to OTP verification screen
            context.push(
              AppRouter.otpVerification,
              extra: {'sessionId': state.sessionId, 'email': state.email},
            );
          } else if (state.status == AuthStatus.error) {
            // Check if it's a "user already exists" error
            if (state.errorMessage?.toLowerCase().contains('already exists') == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account already exists. Please sign in.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
              context.go(AppRouter.signIn);
            } else {
              // Show other errors only if message is not empty (skip network errors)
              final errorMsg = state.errorMessage ?? 'Signup failed';
              if (errorMsg.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMsg),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state.isLoading;

            return Container(
              decoration: BoxDecoration(color: AppColors.backgroundWhite),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
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
                                      width: 134.92.scaled(context),
                                      height: 24.scaled(context),
                                    ),
                                  ),

                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 16,
                                  ),

                                  // Welcome title
                                  Text(
                                    'Welcome to Willcloud',
                                    style: AppTextStyles.welcomeTitle,
                                    textAlign: TextAlign.center,
                                  ),

                                  ResponsiveUtils.scaledBox(context, height: 8),

                                  // Description
                                  Text(
                                    'Securely access your account to continue creating or reviewing your will.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 14.scaled(context),
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                      letterSpacing: 0.07.scaled(context),
                                      color: AppColors.subscriptionDescription,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  ResponsiveUtils.scaledBox(
                                    context,
                                    height: 24,
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
                                          'assets/images/x_icon.svg',
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
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontSize: 12.scaled(context),
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textGray,
                                            height: 1.5,
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

                                  // Sign up card
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
                                        // First Name field
                                        AppTextField(
                                          controller: _firstNameController,
                                          label: 'First Name',
                                          isRequired: true,
                                          keyboardType: TextInputType.name,
                                          textCapitalization: TextCapitalization.words,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your first name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Last Name field
                                        AppTextField(
                                          controller: _lastNameController,
                                          label: 'Last Name',
                                          isRequired: true,
                                          keyboardType: TextInputType.name,
                                          textCapitalization: TextCapitalization.words,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your last name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Email field
                                        AppTextField(
                                          controller: _emailController,
                                          label: 'Email',
                                          isRequired: true,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
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
                                          isRequired: true,
                                          obscureText: !_isPasswordVisible,
                                          suffixIconWidget: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter a password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Confirm password field
                                        AppTextField(
                                          controller: _confirmPasswordController,
                                          label: 'Confirm Password',
                                          isRequired: true,
                                          obscureText: !_isConfirmPasswordVisible,
                                          suffixIconWidget: IconButton(
                                            icon: Icon(
                                              _isConfirmPasswordVisible
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please confirm your password';
                                            }
                                            if (value != _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Terms and Privacy checkbox
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _acceptedTerms,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _acceptedTerms =
                                                        value ?? false;
                                                  });
                                                },
                                                activeColor:
                                                    AppColors.primaryGreen,
                                                checkColor: Colors.white,
                                                side: BorderSide(
                                                  color: _acceptedTerms
                                                      ? AppColors.primaryGreen
                                                      : AppColors.textSecondary,
                                                  width: 2.0,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _acceptedTerms =
                                                        !_acceptedTerms;
                                                  });
                                                },
                                                child: RichText(
                                                  text: TextSpan(
                                                    style:
                                                        AppTextStyles.bodyMedium.copyWith(
                                                          fontSize: 14.scaled(
                                                            context,
                                                          ),
                                                          color: const Color(
                                                            0xFF5A6982,
                                                          ),
                                                        ),
                                                    children: [
                                                      const TextSpan(
                                                        text: 'I agree to the ',
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            'Terms of Service',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .primaryGreen,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const TextSpan(
                                                        text: ' and ',
                                                      ),
                                                      TextSpan(
                                                        text: 'Privacy Policy',
                                                        style: TextStyle(
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          color: AppColors
                                                              .primaryGreen,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 16),

                                        // Sign up button
                                        AppPrimaryButton(
                                          text: 'Sign Up',
                                          onPressed: _signUp,
                                          isLoading: isLoading,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Sign in link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      AppTextButton(
                                        text: 'Sign in',
                                        onPressed: () {
                                          context.go(AppRouter.signIn);
                                        },
                                        color: AppColors.primaryGreen,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
              color: AppColors.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isPng
              ? Image.asset(assetPath, width: 20, height: 20)
              : SvgPicture.asset(
                  assetPath,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
