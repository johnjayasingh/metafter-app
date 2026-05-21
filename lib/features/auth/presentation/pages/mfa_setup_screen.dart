import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class MfaSetupScreen extends StatefulWidget {
  final String session;
  final String qrData;

  const MfaSetupScreen({
    super.key,
    required this.session,
    required this.qrData,
  });

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _storage = SecureStorageService();
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

  void _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      // Get user email from storage
      final email = await _storage.getUserEmail();
      
      if (email == null || email.isEmpty) {
        SnackBarUtils.showError(
          context,
          'Email not found. Please login again.',
        );
        return;
      }

      // Use AuthMfaValidateRequested for MFA setup (first-time setup)
      context.read<AuthBloc>().add(
            AuthMfaValidateRequested(
              session: widget.session,
              otp: code,
              email: email,
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
      backgroundColor: AppColors.backgroundWhite,
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
          'Set Up MFA',
          style: AppTextStyles.pageTitle.copyWith(
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated && !state.hasError) {
            // MFA setup successful - show success message and redirect to sign in
            SnackBarUtils.showSuccess(
              context,
              'MFA setup successful! Please sign in again with your MFA code.',
            );
            context.go('/sign-in');
          } else if (state.status == AuthStatus.error) {
            setState(() {
              _hasError = true;
            });
            _clearAllFields();
            SnackBarUtils.showError(
              context,
              state.errorMessage ?? 'Verification failed',
            );
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
                    // Description
                    Text(
                      'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.)',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),

                    ResponsiveUtils.scaledBox(context, height: 16),

                    // QR Code
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderGray,
                            width: 1,
                          ),
                        ),
                        child: QrImageView(
                          data: widget.qrData,
                          version: QrVersions.auto,
                          size: 200.scaled(context),
                        ),
                      ),
                    ),

                    ResponsiveUtils.scaledBox(context, height: 16),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLightGray4,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup Instructions:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep(
                            '1',
                            'Open your authenticator app',
                          ),
                          const SizedBox(height: 8),
                          _buildInstructionStep(
                            '2',
                            'Scan the QR code above',
                          ),
                          const SizedBox(height: 8),
                          _buildInstructionStep(
                            '3',
                            'Enter the 6-digit code below',
                          ),
                        ],
                      ),
                    ),

                    ResponsiveUtils.scaledBox(context, height: 16),

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
                      text: 'Verify and Continue',
                      onPressed: _verifyCode,
                      isLoading: isLoading,
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

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
}
