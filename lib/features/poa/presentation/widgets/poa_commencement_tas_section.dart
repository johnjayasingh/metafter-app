import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// TAS-specific commencement section for POA Step 2.
///
/// Shows two radio options:
/// - At the time of execution
/// - Only on legal incapacity
class PoaCommencementTasSection extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const PoaCommencementTasSection({
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
          'When do you want this Enduring Power of Attorney to start?',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 24),
        RadioListOption(
          isSelected: selectedType == 'AT_EXECUTION',
          title: 'At the time of execution',
          onTap: () => onTypeChanged('AT_EXECUTION'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedType == 'INCAPACITY',
          title: 'Only on legal incapacity',
          onTap: () => onTypeChanged('INCAPACITY'),
        ),
      ],
    );
  }
}
