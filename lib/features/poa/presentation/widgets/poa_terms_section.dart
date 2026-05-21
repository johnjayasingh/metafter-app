import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// Reusable terms-and-instructions section for POA Step 2.
///
/// Displays a Yes/No toggle and, when "Yes" is selected, a text area for
/// the attorney's instructions.
class PoaTermsSection extends StatelessWidget {
  final bool hasTerms;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;

  const PoaTermsSection({
    super.key,
    required this.hasTerms,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms and instructions of your attorney',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 8),
        Text(
          "Would you like to set terms or limits on your attorney's power and/or give specific instructions that your attorney must follow?",
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: hasTerms,
                label: 'Yes',
                onTap: () => onToggle(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: !hasTerms,
                label: 'No',
                onTap: () => onToggle(false),
              ),
            ),
          ],
        ),
        if (hasTerms) ...[
          const SizedBox(height: 16),
          AppTextArea(
            controller: controller,
            label: '',
            placeholder: 'Enter your instructions',
            minLines: 6,
            maxLines: 10,
          ),
        ],
      ],
    );
  }
}
