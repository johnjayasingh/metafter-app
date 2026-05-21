import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';

class LegalReviewStep {
  final int stepNumber;
  final String title;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  const LegalReviewStep({
    required this.stepNumber,
    required this.title,
    required this.icon,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class LegalReviewStepsSidebar extends StatelessWidget {
  final int currentStep;
  final String willId;

  const LegalReviewStepsSidebar({
    super.key,
    required this.currentStep,
    required this.willId,
  });

  List<LegalReviewStep> get steps => [
    LegalReviewStep(
      stepNumber: 1,
      title: 'Send for legal review',
      icon: Icons.rate_review_outlined,
      isCompleted: currentStep > 1,
      isCurrent: currentStep == 1,
    ),
    LegalReviewStep(
      stepNumber: 2,
      title: 'Assign lawyer',
      icon: Icons.gavel_outlined,
      isCompleted: currentStep > 2,
      isCurrent: currentStep == 2,
    ),
    LegalReviewStep(
      stepNumber: 3,
      title: 'Notification recipient',
      icon: Icons.notifications_outlined,
      isCompleted: currentStep > 3,
      isCurrent: currentStep == 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundWhite,
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Legal review',
                      style: AppTextStyles.cardTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.primaryGreen,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Review the Will with your lawyer',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // Steps list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return _StepItem(
                    step: step,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate based on step number
                      switch (step.stepNumber) {
                        case 1:
                          context.go(
                            AppRouter.legalReview,
                            extra: {'willId': willId, 'userName': ''},
                          );
                          break;
                        case 2:
                          context.go(
                            AppRouter.assignLawyer,
                            extra: {'willId': willId},
                          );
                          break;
                        case 3:
                          context.go(
                            AppRouter.notificationRecipient,
                            extra: {'willId': willId},
                          );
                          break;
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final LegalReviewStep step;
  final VoidCallback onTap;

  const _StepItem({
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color textColor;
    Color numberBackgroundColor;
    Color numberTextColor;

    if (step.isCurrent) {
      iconColor = AppColors.primaryGreen;
      textColor = AppColors.textPrimary;
      numberBackgroundColor = AppColors.primaryGreen;
      numberTextColor = Colors.white;
    } else if (step.isCompleted) {
      iconColor = AppColors.primaryGreen;
      textColor = AppColors.textSecondary;
      numberBackgroundColor = AppColors.primaryGreen;
      numberTextColor = Colors.white;
    } else {
      iconColor = AppColors.textTertiary;
      textColor = AppColors.textTertiary;
      numberBackgroundColor = AppColors.backgroundLight;
      numberTextColor = AppColors.textTertiary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Icon
              Icon(
                step.icon,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              // Step title
              Expanded(
                child: Text(
                  step.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: step.isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              // Step number or checkmark
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: numberBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: step.isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : Text(
                          '${step.stepNumber}',
                          style: TextStyle(
                            color: numberTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
