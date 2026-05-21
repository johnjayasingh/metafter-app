import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/app_enums.dart';
import '../../data/repositories/will_repository_impl.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/legal_review_steps_sidebar.dart';

class NotificationRecipientScreen extends StatefulWidget {
  final String willId;

  const NotificationRecipientScreen({super.key, required this.willId});

  @override
  State<NotificationRecipientScreen> createState() =>
      _NotificationRecipientScreenState();
}

class _NotificationRecipientScreenState
    extends State<NotificationRecipientScreen> {
  late final WillRepositoryImpl _willRepository;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<NotificationRecipient> _recipients = [];
  Set<int> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _willRepository = WillRepositoryImpl(apiClient: ApiClient());
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<NotificationRecipient> allRecipients = [];

      // Load beneficiaries and executors in a single API call
      final response = await _willRepository.getWillUsersByRoles(
        widget.willId,
        [WillUserRole.executor.value, WillUserRole.beneficiary.value],
      );

      if (response.isSuccess && response.data != null) {
        for (final user in response.data!) {
          allRecipients.add(
            NotificationRecipient(
              userId: user.id,
              firstName: user.firstName,
              lastName: user.lastName,
              role: WillUserRole.fromString(user.role).displayName,
            ),
          );
        }
      }

      setState(() {
        _recipients = allRecipients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading recipients: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitNotificationRecipients() async {
    if (_selectedUserIds.isEmpty) {
      SnackBarUtils.showError(
        context,
        'Please select at least one recipient',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _willRepository.sendNotificationRecipients(
        widget.willId,
        _selectedUserIds.toList(),
      );

      if (response.isSuccess) {
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            'Notification recipients added successfully',
          );

          // Navigate to will timeline
          context.go(
            AppRouter.willTimeline,
            extra: {
              'willId': widget.willId,
              'fullName': '',
              'status': '',
            },
          );
        }
      } else {
        setState(() {
          _errorMessage = (response.message?.isNotEmpty ?? false)
              ? response.message!
              : 'Failed to add notification recipients';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting recipients: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: LegalReviewStepsSidebar(
        currentStep: 3,
        willId: widget.willId,
      ),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: 3,
        showStepNumber: true,
        title: 'Notification recipient',
        skipExitConfirmation: true,
        onExitNavigate: () => context.go(AppRouter.home),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and description
                    Text(
                      'Notification recipient',
                      style: AppTextStyles.pageTitle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recipients will receive notification of will status',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Recipients list section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification recipient',
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Loading state
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            )
                          // Empty state
                          else if (_recipients.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No recipients available',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          // Recipients list
                          else
                            ...List.generate(_recipients.length, (index) {
                              final recipient = _recipients[index];
                              final isSelected =
                                  _selectedUserIds.contains(recipient.userId);

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < _recipients.length - 1
                                      ? 12
                                      : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedUserIds
                                            .remove(recipient.userId);
                                      } else {
                                        _selectedUserIds.add(recipient.userId);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundWhite,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.borderLight,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Checkbox
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedUserIds
                                                      .add(recipient.userId);
                                                } else {
                                                  _selectedUserIds
                                                      .remove(recipient.userId);
                                                }
                                              });
                                            },
                                            activeColor:
                                                AppColors.primaryGreen,
                                            checkColor: Colors.white,
                                            side: BorderSide(
                                              color: isSelected
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
                                        const SizedBox(width: 12),
                                        // Avatar
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.lightGreen,
                                          child: Text(
                                            recipient.firstName[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color:
                                                  AppColors.primaryDarkGreen,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Name and role
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipient.fullName,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                recipient.role,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textTertiary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom navigation buttons
            AppBottomActionBar(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      text: 'Previous',
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go(
                                AppRouter.assignLawyer,
                                extra: {'willId': widget.willId},
                              ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Finish',
                      onPressed: _isSubmitting
                          ? null
                          : _submitNotificationRecipients,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to hold recipient data
class NotificationRecipient {
  final int userId;
  final String firstName;
  final String lastName;
  final String role;

  NotificationRecipient({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  String get fullName {
    if (lastName.isEmpty) {
      return firstName;
    }
    return '$firstName $lastName';
  }
}
