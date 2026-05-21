import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// Reusable matters-selection section for POA Step 2.
///
/// Displays two radio-style checkboxes:
///  - Personal (including health) matters
///  - Financial matters
///
/// The parent owns the [selectedMatters] list and handles toggling via [onToggle].
class PoaMattersSection extends StatelessWidget {
  final List<String> selectedMatters;
  final ValueChanged<String> onToggle;

  const PoaMattersSection({
    super.key,
    required this.selectedMatters,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Matters', style: AppTextStyles.pageTitle),
        const SizedBox(height: 24),
        RadioListOption(
          isSelected: selectedMatters.contains('PERSONAL_HEALTH'),
          title: 'Personal (including health) matters',
          subtitle:
              'Personal matter relate to personal and lifestyle decisions this includes decisions about support services where and with whom you live health care and legal matters that do not relate to your financial or property matters',
          onTap: () => onToggle('PERSONAL_HEALTH'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedMatters.contains('FINANCIAL'),
          title: 'Financial matters',
          subtitle:
              'Financial matter relate to your financial or property affairs including paying expenses making investments selling property carrying on a business',
          onTap: () => onToggle('FINANCIAL'),
        ),
      ],
    );
  }
}
