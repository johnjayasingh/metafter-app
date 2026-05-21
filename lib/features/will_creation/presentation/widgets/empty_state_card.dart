import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/form/form_widgets.dart';

class EmptyStateCard extends StatelessWidget {
  final String buttonText;
  final VoidCallback onAddPressed;
  final Widget? placeholderWidget;

  const EmptyStateCard({
    super.key,
    required this.buttonText,
    required this.onAddPressed,
    this.placeholderWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardLightGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your selection will show up here',
            style: AppTextStyles.instructionSmall,
          ),
          if (placeholderWidget != null) ...[
            const SizedBox(height: 16),
            placeholderWidget!,
          ],
          const SizedBox(height: 16),
          AppPrimaryButton(
            text: buttonText,
            onPressed: onAddPressed,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }
}
