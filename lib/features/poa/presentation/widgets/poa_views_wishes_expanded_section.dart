import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';

/// Expanded views-wishes section with single preference question + directions.
///
/// Used by Queensland and states that require detailed preference fields.
class PoaViewsWishesExpandedSection extends StatelessWidget {
  final String? hasPreference;
  final ValueChanged<String> onPreferenceChanged;
  final TextEditingController preferencesController;

  final TextEditingController directionsController;

  const PoaViewsWishesExpandedSection({
    super.key,
    required this.hasPreference,
    required this.onPreferenceChanged,
    required this.preferencesController,
    required this.directionsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your views, wishes and preferences',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 8),
        Text(
          '(optional)',
          style: AppTextStyles.subtitle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),

        // Question 1: Important things
        _buildYesNoQuestion(
          question: 'Would you like to provide your views, wishes and preferences?',
          value: hasPreference,
          onChanged: onPreferenceChanged,
          controller: preferencesController,
          placeholder: 'Please describe what is important to you',
        ),
      ],
    );
  }

  Widget _buildYesNoQuestion({
    required String question,
    required String? value,
    required ValueChanged<String> onChanged,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: AppTextStyles.itemLabel,
        ),
        const SizedBox(height: 12),
        AppYesNoRadio(
          value: value,
          onChanged: onChanged,
        ),
        if (value == 'yes') ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: controller,
            label: '',
            placeholder: placeholder,
            minLines: 4,
            maxLines: 8,
          ),
        ],
      ],
    );
  }
}
