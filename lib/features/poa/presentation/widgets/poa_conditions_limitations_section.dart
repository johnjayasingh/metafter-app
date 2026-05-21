import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// Conditions and limitations section for POA Step 2.
///
/// Displays a Yes/No toggle and, when "Yes" is selected, a text area for
/// entering conditions and limitations details.
class PoaConditionsLimitationsSection extends StatelessWidget {
  final bool hasConditionsLimitations;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;

  const PoaConditionsLimitationsSection({
    super.key,
    required this.hasConditionsLimitations,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Conditions and Limitations ',
              style: AppTextStyles.pageTitle,
            ),
            Text(
              '(optional)',
              style: AppTextStyles.pageTitle.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Would you like to set any conditions and limitations on the powers granted to your attorney?',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: hasConditionsLimitations,
                label: 'Yes',
                onTap: () => onToggle(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: !hasConditionsLimitations,
                label: 'No',
                onTap: () => onToggle(false),
              ),
            ),
          ],
        ),
        if (hasConditionsLimitations) ...[
          const SizedBox(height: 16),
          AppTextArea(
            controller: controller,
            label: '',
            placeholder:
                'Enter the details of your Limitations and conditions',
            minLines: 6,
            maxLines: 10,
          ),
        ],
      ],
    );
  }
}
