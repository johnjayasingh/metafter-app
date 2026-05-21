import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// Reusable commencement section for POA Step 2.
///
/// Shows three radio options (Incapacity, Immediately, Other) with an
/// optional text area when "Other" is selected.
///
/// The parent owns [selectedType] (`'INCAPACITY'` | `'IMMEDIATELY'` | `'OTHER'`)
/// and provides [otherController] for the free-text field.
class PoaCommencementSection extends StatelessWidget {
  final String selectedType;
  final TextEditingController otherController;
  final ValueChanged<String> onTypeChanged;

  const PoaCommencementSection({
    super.key,
    required this.selectedType,
    required this.otherController,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commencement for financial matters',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 24),
        RadioListOption(
          isSelected: selectedType == 'INCAPACITY',
          title:
              'When i do not have capacity to make decisions for financial matters',
          onTap: () => onTypeChanged('INCAPACITY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedType == 'IMMEDIATELY',
          title: 'Immediately',
          onTap: () => onTypeChanged('IMMEDIATELY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedType == 'OTHER',
          title: 'Others',
          onTap: () => onTypeChanged('OTHER'),
        ),
        if (selectedType == 'OTHER') ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: otherController,
            label: '',
            placeholder:
                'Please specify when your attorney can start making financial decisions',
            maxLines: 4,
          ),
        ],
      ],
    );
  }
}
