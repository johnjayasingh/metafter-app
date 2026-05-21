import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// Simplified views-wishes section: Yes/No toggle with a single text area.
///
/// Used by NSW and most states where detailed text areas are not required.
class PoaViewsWishesSection extends StatelessWidget {
  final bool hasViewsWishes;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;

  const PoaViewsWishesSection({
    super.key,
    required this.hasViewsWishes,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Views, wishes and preferences (optional)',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 8),
        Text(
          'Would you like to record your views, wishes and preferences?',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: hasViewsWishes,
                label: 'Yes',
                onTap: () => onToggle(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: !hasViewsWishes,
                label: 'No',
                onTap: () => onToggle(false),
              ),
            ),
          ],
        ),
        if (hasViewsWishes) ...[
          const SizedBox(height: 16),
          AppTextArea(
            controller: controller,
            label: '',
            placeholder: 'Enter views, wishes and preferences',
            minLines: 4,
            maxLines: 8,
          ),
        ],
      ],
    );
  }
}
