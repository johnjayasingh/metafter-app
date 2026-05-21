import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../widgets/form/form_widgets.dart';
import 'navigation_utils.dart';

/// Shows a bottom sheet asking the user to save their progress, discard changes, or continue editing.
/// 
/// [context] - The BuildContext to show the bottom sheet in
/// [onSaveDraft] - Optional callback to execute before navigating home when saving draft.
///                 If null, it will just navigate home without saving.
/// [onDiscard] - Optional callback to execute before navigating home when discarding.
///               If null, it will just navigate home.
/// [title] - Custom title for the dialog (defaults to "Exit will creation?")
/// [description] - Custom description text (defaults to will creation message)
/// [discardButtonText] - Custom text for the discard button (defaults to "Discard Will")
void showExitConfirmationSheet(
  BuildContext context, {
  VoidCallback? onSaveDraft,
  VoidCallback? onDiscard,
  VoidCallback? navigationCallback,
  bool hideSaveDraft = false,
  String? title,
  String? description,
  String? discardButtonText,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title ?? 'Exit will creation?',
                style: AppTextStyles.pageTitle,
              ),
              const SizedBox(height: 12),
              Text(
                description ?? 'You can save your progress as a draft and continue later, or discard this will.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!hideSaveDraft)
                AppPrimaryButton(
                  text: 'Save Draft',
                  onPressed: () {
                    onSaveDraft?.call();
                    Navigator.pop(context);
                    if (navigationCallback != null) {
                      navigationCallback.call();
                    } else {
                      NavigationUtils.goToHomeAndRefresh(context);
                    }
                  },
                ),
              if (!hideSaveDraft) const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    onDiscard?.call();
                    Navigator.pop(context);
                    if (navigationCallback != null) {
                      navigationCallback.call();
                    } else {
                      NavigationUtils.goToHomeAndRefresh(context);
                    }
                  },
                  style: AppDecorations.buttonSecondary,
                  child: Text(
                    discardButtonText ?? 'Discard Will',
                    style: AppTextStyles.buttonSecondary.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Continue Editing',
                  style: AppTextStyles.buttonSecondary.copyWith(
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
