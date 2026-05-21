import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/poa_flow_config.dart';

class _PoaStep {
  final int stepNumber;
  final String title;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  const _PoaStep({
    required this.stepNumber,
    required this.title,
    required this.icon,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class PoaStepsSidebar extends StatelessWidget {
  final int currentStep;
  final String? userState;

  const PoaStepsSidebar({
    super.key,
    required this.currentStep,
    this.userState,
  });

  List<_PoaStep> get steps {
    final config = PoaFlowConfig.forState(userState);
    return config.steps
        .map((def) => _PoaStep(
              stepNumber: def.stepNumber,
              title: def.title,
              icon: def.icon,
              isCompleted: currentStep > def.stepNumber,
              isCurrent: currentStep == def.stepNumber,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundWhite,
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Power of attorney',
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
                'Complete the steps to create your enduring power of attorney.',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return _StepItem(
                    step: step,
                    onTap: () => Navigator.pop(context),
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
  final _PoaStep step;
  final VoidCallback onTap;

  const _StepItem({required this.step, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        step.isCurrent ? AppColors.lightGreen : Colors.transparent;

    final textColor =
        step.isCurrent ? AppColors.primaryGreen : AppColors.textDarkGray;

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
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      step.isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
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
