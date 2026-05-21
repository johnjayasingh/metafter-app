import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// Directions section for Enduring Guardians on POA Step 2.
///
/// Displays a Yes/No toggle and, when "Yes" is selected, a text area for
/// entering direction details.
class PoaDirectionsSection extends StatelessWidget {
  final bool hasDirections;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;

  const PoaDirectionsSection({
    super.key,
    required this.hasDirections,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Directions', style: AppTextStyles.pageTitle),
        const SizedBox(height: 8),
        Text(
          'Would you like to give any directions to your enduring guardian?',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: hasDirections,
                label: 'Yes',
                onTap: () => onToggle(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: !hasDirections,
                label: 'No',
                onTap: () => onToggle(false),
              ),
            ),
          ],
        ),
        if (hasDirections) ...[
          const SizedBox(height: 16),
          AppTextArea(
            controller: controller,
            label: '',
            placeholder: 'Enter your directions',
            minLines: 6,
            maxLines: 10,
          ),
        ],
      ],
    );
  }
}
