import 'package:digitalwill/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_router.dart';

class WillStep {
  final int stepNumber;
  final String title;
  final IconData icon;
  final String route;
  final bool isCompleted;
  final bool isCurrent;

  const WillStep({
    required this.stepNumber,
    required this.title,
    required this.icon,
    required this.route,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class WillStepsSidebar extends StatelessWidget {
  final int currentStep;

  const WillStepsSidebar({super.key, required this.currentStep});

  List<WillStep> get steps => [
    WillStep(
      stepNumber: 1,
      title: 'Your details',
      icon: Icons.person_outline,
      route: AppRouter.basicDetails,
      isCompleted: currentStep > 1,
      isCurrent: currentStep == 1,
    ),
    WillStep(
      stepNumber: 2,
      title: 'Relationship Status',
      icon: Icons.favorite_border,
      route: AppRouter.relationshipStatus,
      isCompleted: currentStep > 2,
      isCurrent: currentStep == 2,
    ),
    WillStep(
      stepNumber: 3,
      title: 'Family & Dependents',
      icon: Icons.group_outlined,
      route: AppRouter.familyDetails,
      isCompleted: currentStep > 3,
      isCurrent: currentStep == 3,
    ),
    WillStep(
      stepNumber: 4,
      title: 'Beneficiaries',
      icon: Icons.people_outline,
      route: AppRouter.beneficiaries,
      isCompleted: currentStep > 4,
      isCurrent: currentStep == 4,
    ),
    WillStep(
      stepNumber: 5,
      title: 'Charities',
      icon: Icons.volunteer_activism,
      route: AppRouter.charitySelection,
      isCompleted: currentStep > 5,
      isCurrent: currentStep == 5,
    ),
    WillStep(
      stepNumber: 6,
      title: 'Assets',
      icon: Icons.account_balance_wallet_outlined,
      route: AppRouter.listAssets,
      isCompleted: currentStep > 6,
      isCurrent: currentStep == 6,
    ),
    WillStep(
      stepNumber: 7,
      title: 'Allocation',
      icon: Icons.pie_chart_outline,
      route: AppRouter.assetAllocation,
      isCompleted: currentStep > 7,
      isCurrent: currentStep == 7,
    ),
    WillStep(
      stepNumber: 8,
      title: 'Specific Gifts',
      icon: Icons.card_giftcard_outlined,
      route: AppRouter.giftsQuestion,
      isCompleted: currentStep > 8,
      isCurrent: currentStep == 8,
    ),
    WillStep(
      stepNumber: 9,
      title: 'Executors',
      icon: Icons.gavel_outlined,
      route: AppRouter.executors,
      isCompleted: currentStep > 9,
      isCurrent: currentStep == 9,
    ),
    WillStep(
      stepNumber: 10,
      title: 'Witnesses',
      icon: Icons.gavel_outlined,
      route: AppRouter.witness,
      isCompleted: currentStep > 10,
      isCurrent: currentStep == 10,
    ),
    WillStep(
      stepNumber: 11,
      title: 'Review',
      icon: Icons.rate_review_outlined,
      route: AppRouter.review,
      isCompleted: currentStep > 11,
      isCurrent: currentStep == 11,
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
                      'Create new will',
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
                'Add your details, name heirs, decide who gets what, and sign with witnesses. Simple and secure.',
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
                      context.go(step.route);
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
  final WillStep step;
  final VoidCallback onTap;

  const _StepItem({required this.step, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = step.isCurrent
        ? AppColors.lightGreen
        : Colors.transparent;

    final textColor = step.isCurrent
        ? AppColors.primaryGreen
        : AppColors.textDarkGray;

    final iconColor = step.isCompleted
        ? AppColors.successGreen
        : step.isCurrent
        ? AppColors.primaryGreen
        : AppColors.textGray2;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: backgroundColor),
        child: Row(
          children: [
            // Icon with completion indicator
            SizedBox(
              width: 20,
              height: 20,
              child: step.isCompleted
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                      size: 20,
                    )
                  : Icon(step.icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: step.isCurrent
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            // Step number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: step.isCurrent
                    ? AppColors.primaryGreen
                    : step.isCompleted
                    ? AppColors.successGreen
                    : AppColors.backgroundLightGray2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${step.stepNumber}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: step.isCurrent || step.isCompleted
                      ? Colors.white
                      : AppColors.textGray2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
