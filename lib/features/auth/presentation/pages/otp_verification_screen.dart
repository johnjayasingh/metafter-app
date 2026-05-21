import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String sessionId;
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.sessionId,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _hasError = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      context.read<AuthBloc>().add(
        AuthOtpValidateRequested(sessionId: widget.sessionId, otp: otp),
      );
    }
  }

  void _resendOtp() {
    // TODO: Implement resend OTP
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP resent to your email'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated && !state.hasError) {
            // OTP validated - show success toast and navigate to sign in
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully! You can now sign in.'),
                backgroundColor: AppColors.primaryGreen,
                duration: Duration(seconds: 3),
              ),
            );
            context.go(AppRouter.signIn);
          } else if (state.status == AuthStatus.error) {
            // Show error
            setState(() {
              _hasError = true;
            });
            // Clear all fields
            for (var controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state.isLoading;

            return Container(
              decoration: BoxDecoration(color: AppColors.backgroundWhite),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResponsiveUtils.scaledBox(context, height: 40),

                      // Logo
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/logo.svg',
                          width: 134.92.scaled(context),
                          height: 24.scaled(context),
                        ),
                      ),

                      ResponsiveUtils.scaledBox(context, height: 32),

                      // Account activation message (if coming from sign-in)
                      if (widget.sessionId.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please activate your account first. Tap "Resend code" to get a new verification code.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: 12.scaled(context),
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.warningDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ResponsiveUtils.scaledBox(context, height: 16),
                      ],

                      // Title
                      Text(
                        'Check your inbox',
                        style: AppTextStyles.pageTitle,
                        textAlign: TextAlign.center,
                      ),

                      ResponsiveUtils.scaledBox(context, height: 12),

                      // Description
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 14.scaled(context),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: 0.07.scaled(context),
                            color: AppColors.subscriptionDescription,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'We\'ve sent a 6-digit verification code to your email\n',
                            ),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const TextSpan(
                              text: '. Enter the code below to continue',
                            ),
                          ],
                        ),
                      ),

                      ResponsiveUtils.scaledBox(context, height: 32),

                      // OTP Input Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 48.scaled(context),
                            height: 56.scaled(context),
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: AppTextStyles.inputText.copyWith(
                                fontSize: 20.scaled(context),
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasError
                                        ? AppColors.errorRed
                                        : AppColors.borderGray,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasError
                                        ? AppColors.errorRed
                                        : AppColors.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.errorRed,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.errorRed,
                                    width: 2,
                                  ),
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _hasError = false;
                                });

                                if (value.isNotEmpty) {
                                  // Move to next field
                                  if (index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else {
                                    // Last field - verify OTP
                                    _focusNodes[index].unfocus();
                                    _verifyOtp();
                                  }
                                }
                              },
                              onTap: () {
                                // Clear error on tap
                                setState(() {
                                  _hasError = false;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      if (_hasError) ...[
                        ResponsiveUtils.scaledBox(context, height: 8),
                        Text(
                          'Invalid code. Please try again.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 12.scaled(context),
                            fontWeight: FontWeight.w500,
                            color: AppColors.errorRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      ResponsiveUtils.scaledBox(context, height: 24),

                      // Info text
                      Text(
                        'Didn\'t receive the email? Check your spam or\npromotions folder.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12.scaled(context),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: AppColors.subscriptionDescription,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      ResponsiveUtils.scaledBox(context, height: 12),

                      // Resend link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Didn\'t get the code? ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 12.scaled(context),
                              fontWeight: FontWeight.w500,
                              color: AppColors.subscriptionDescription,
                            ),
                          ),
                          AppTextButton(
                            text: 'Resend',
                            onPressed: isLoading ? null : _resendOtp,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),

                      ResponsiveUtils.scaledBox(context, height: 32),

                      // Verify button
                      AppPrimaryButton(
                        text: 'Verify',
                        onPressed: _verifyOtp,
                        isLoading: isLoading,
                      ),

                      ResponsiveUtils.scaledBox(context, height: 16),

                      // Use different email button
                      AppSecondaryButton(
                        text: 'Use a different email',
                        onPressed: () {
                          context.go(AppRouter.signUp);
                        },
                        isDisabled: isLoading,
                      ),

                      ResponsiveUtils.scaledBox(context, height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
