import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/exit_confirmation_sheet.dart';

class WillCreationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final VoidCallback? onBack;
  final bool showBackButton;
  final bool showStepNumber;
  final String? exitTitle;
  final String? exitDescription;
  final String? exitDiscardButtonText;
  final bool enableDrawer;
  final bool skipExitConfirmation;
  final VoidCallback? onExitNavigate;
  final bool hideSaveDraftOnExit;

  const WillCreationAppBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    this.onBack,
    this.showBackButton = false,
    this.showStepNumber = true,
    this.exitTitle,
    this.exitDescription,
    this.exitDiscardButtonText,
    this.enableDrawer = true,
    this.skipExitConfirmation = false,
    this.onExitNavigate,
    this.hideSaveDraftOnExit = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return AppBar(
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      titleSpacing: 0,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress indicator on the left - now clickable
              Expanded(
                child: GestureDetector(
                  onTap: enableDrawer
                      ? () {
                          Scaffold.of(context).openDrawer();
                        }
                      : null,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.progressBackground,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressGreen),
                                strokeWidth: 3,
                              ),
                            ),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppColors.backgroundWhite,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Steps and title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showStepNumber)
                              Row(
                                children: [
                                  Text(
                                    '$currentStep/$totalSteps',
                                    style: AppTextStyles.stepCounter,
                                  ),
                                  Text(
                                    ' steps',
                                    style: AppTextStyles.stepLabel,
                                  ),
                                ],
                              ),
                            Text(
                              title,
                              style: AppTextStyles.stepTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Close button on the right
              GestureDetector(
                onTap: () {
                  if (skipExitConfirmation) {
                    if (onExitNavigate != null) {
                      onExitNavigate!();
                    } else {
                      Navigator.pop(context);
                    }
                  } else {
                    showExitConfirmationSheet(
                      context,
                      title: exitTitle,
                      description: exitDescription,
                      discardButtonText: exitDiscardButtonText,
                      navigationCallback: onExitNavigate,
                      hideSaveDraft: hideSaveDraftOnExit,
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: AppDecorations.closeButtonBordered,
                  child: const Center(
                    child: Icon(Icons.close, color: AppColors.primaryDarkGreen, size: 20),
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
