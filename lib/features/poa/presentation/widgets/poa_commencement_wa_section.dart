import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// WA-specific commencement section for POA Step 2.
///
/// Shows two radio options:
/// - Immediately after execution and acceptance
/// - Only when SAT declaration in force
class PoaCommencementWaSection extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const PoaCommencementWaSection({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you want your attorney\'s power to start?',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 24),
        RadioListOption(
          isSelected: selectedType == 'IMMEDIATELY',
          title: 'Immediately after execution and acceptance',
          onTap: () => onTypeChanged('IMMEDIATELY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedType == 'SAT_DECLARATION',
          title: 'Only when SAT declaration in force',
          onTap: () => onTypeChanged('SAT_DECLARATION'),
        ),
      ],
    );
  }
}
