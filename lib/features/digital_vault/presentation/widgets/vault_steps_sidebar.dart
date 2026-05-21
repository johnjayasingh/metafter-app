import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class _VaultStep {
  final int stepNumber;
  final String title;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  const _VaultStep({
    required this.stepNumber,
    required this.title,
    required this.icon,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class VaultStepsSidebar extends StatelessWidget {
  final int currentStep;

  const VaultStepsSidebar({super.key, required this.currentStep});

  List<_VaultStep> get _steps => [
        _VaultStep(
          stepNumber: 1,
          title: 'Account Details',
          icon: Icons.lock_outline,
          isCompleted: currentStep > 1,
          isCurrent: currentStep == 1,
        ),
        _VaultStep(
          stepNumber: 2,
          title: 'Closure Instructions',
          icon: Icons.assignment_outlined,
          isCompleted: currentStep > 2,
          isCurrent: currentStep == 2,
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
                    child: Text('Digital Vault', style: AppTextStyles.cardTitle),
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
                'Securely store your account credentials',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // Steps
            ...(_steps.map((step) => _StepItem(
              step: step,
              onTap: () {
                Navigator.pop(context);
                switch (step.stepNumber) {
                  case 1:
                    // Already on step 1 – just close drawer
                    break;
                  case 2:
                    context.push(AppRouter.digitalVaultInstructions);
                    break;
                }
              },
            ))),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final _VaultStep step;
  final VoidCallback onTap;

  const _StepItem({required this.step, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final Color textColor;
    final Color numberBg;
    final Color numberFg;

    if (step.isCurrent) {
      iconColor = AppColors.primaryGreen;
      textColor = AppColors.textPrimary;
      numberBg = AppColors.primaryGreen;
      numberFg = Colors.white;
    } else if (step.isCompleted) {
      iconColor = AppColors.primaryGreen;
      textColor = AppColors.textSecondary;
      numberBg = AppColors.primaryGreen;
      numberFg = Colors.white;
    } else {
      iconColor = AppColors.textTertiary;
      textColor = AppColors.textTertiary;
      numberBg = AppColors.backgroundLight;
      numberFg = AppColors.textTertiary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(step.icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: step.isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: numberBg, shape: BoxShape.circle),
                child: Center(
                  child: step.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${step.stepNumber}',
                          style: TextStyle(
                            color: numberFg,
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
