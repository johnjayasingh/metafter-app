import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/auth_models.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class MfaChallengeScreen extends StatefulWidget {
  final String session;
  final ChallengeType challengeType;

  const MfaChallengeScreen({
    super.key,
    required this.session,
    required this.challengeType,
  });

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
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

  void _verifyCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      context.read<AuthBloc>().add(
            AuthMfaConfirmRequested(
              session: widget.session,
              code: code,
            ),
          );
    }
  }

  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/sign-in');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray, width: 1),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new, color: AppColors.textBrand, size: 18),
              ),
            ),
          ),
        ),
        title: Text(
          'Verify Your Identity',
          style: AppTextStyles.pageTitle.copyWith(
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go('/home');
          } else if (state.status == AuthStatus.error) {
            setState(() {
              _hasError = true;
            });
            _clearAllFields();
            // Only show error if message is not empty (skip network errors)
            final errorMsg = state.errorMessage ?? 'Verification failed';
            if (errorMsg.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state.isLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResponsiveUtils.scaledBox(context, height: 48),

                    // Lock Icon
                    Center(
                      child: Container(
                        width: 100.scaled(context),
                        height: 100.scaled(context),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(50.scaled(context)),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 48.scaled(context),
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),

                    ResponsiveUtils.scaledBox(context, height: 32),

                    // Title
                    Text(
                      'Enter Authentication Code',
                      style: AppTextStyles.pageTitle,
                      textAlign: TextAlign.center,
                    ),

                    ResponsiveUtils.scaledBox(context, height: 12),

                    // Description
                    Text(
                      widget.challengeType == ChallengeType.softwareTokenMfa
                          ? 'Open your authenticator app and enter the 6-digit code'
                          : 'Enter the code sent to your phone',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),

                    ResponsiveUtils.scaledBox(context, height: 40),

                    // 6 OTP Input Boxes
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
                                  // Last field - verify code
                                  _focusNodes[index].unfocus();
                                  _verifyCode();
                                }
                              } else if (value.isEmpty && index > 0) {
                                // Move to previous field on backspace
                                _focusNodes[index - 1].requestFocus();
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
                      const SizedBox(height: 12),
                      Text(
                        'Invalid code. Please try again.',
                        style: AppTextStyles.error,
                        textAlign: TextAlign.center,
                      ),
                    ],

                    ResponsiveUtils.scaledBox(context, height: 32),

                    // Verify Button
                    AppPrimaryButton(
                      text: 'Verify',
                      onPressed: _verifyCode,
                      isLoading: isLoading,
                    ),

                    ResponsiveUtils.scaledBox(context, height: 24),

                    // Having trouble?
                    Center(
                      child: AppTextButton(
                        text: 'Having trouble?',
                        onPressed: () {
                          // TODO: Implement help/support
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support coming soon'),
                            ),
                          );
                        },
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
