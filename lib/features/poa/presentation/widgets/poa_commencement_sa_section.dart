import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// SA-specific commencement section for POA Step 2.
///
/// Shows two radio options:
/// - Upon execution (starts immediately once signed as a deed)
/// - Only on legal incapacity (starts only if you later lose legal capacity)
class PoaCommencementSaSection extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const PoaCommencementSaSection({
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
          'When the power becomes effective',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 8),
        Text(
          'When do you want this Enduring Power of Attorney to start?',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 24),
        RadioListOption(
          isSelected: selectedType == 'IMMEDIATELY',
          title:
              'Upon execution (starts immediately once signed as a deed)',
          onTap: () => onTypeChanged('IMMEDIATELY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedType == 'LEGAL_INCAPACITY',
          title:
              'Only on legal incapacity (starts only if you later lose legal capacity)',
          onTap: () => onTypeChanged('LEGAL_INCAPACITY'),
        ),
      ],
    );
  }
}
