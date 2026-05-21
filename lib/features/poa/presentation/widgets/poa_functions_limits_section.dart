import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';

/// Functions and Limits section for Enduring Guardians on POA Step 2.
///
/// Displays toggleable options for each guardian function with optional
/// text areas for details when toggled on.
class PoaFunctionsLimitsSection extends StatelessWidget {
  final bool canDecideLivingPlace;
  final bool canDecideHealthcare;
  final TextEditingController healthcareController;
  final bool canDecideOtherPersonalService;
  final TextEditingController otherPersonalServiceController;
  final bool canConsentMedicalAndDental;
  final TextEditingController medicalDetailController;
  final TextEditingController otherDetailController;
  final ValueChanged<bool> onDecideLivingPlaceChanged;
  final ValueChanged<bool> onDecideHealthcareChanged;
  final ValueChanged<bool> onDecideOtherPersonalServiceChanged;
  final ValueChanged<bool> onConsentMedicalAndDentalChanged;

  const PoaFunctionsLimitsSection({
    super.key,
    required this.canDecideLivingPlace,
    required this.canDecideHealthcare,
    required this.healthcareController,
    required this.canDecideOtherPersonalService,
    required this.otherPersonalServiceController,
    required this.canConsentMedicalAndDental,
    required this.medicalDetailController,
    required this.otherDetailController,
    required this.onDecideLivingPlaceChanged,
    required this.onDecideHealthcareChanged,
    required this.onDecideOtherPersonalServiceChanged,
    required this.onConsentMedicalAndDentalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Functions and Limits', style: AppTextStyles.pageTitle),
        const SizedBox(height: 24),

        // Decide where I live
        _buildToggleItem(
          title: 'Decide where I live',
          isSelected: canDecideLivingPlace,
          onTap: () => onDecideLivingPlaceChanged(!canDecideLivingPlace),
        ),

        // Decide what health care I receive
        const SizedBox(height: 12),
        _buildToggleItem(
          title: 'Decide what health care I receive',
          isSelected: canDecideHealthcare,
          onTap: () => onDecideHealthcareChanged(!canDecideHealthcare),
        ),
        if (canDecideHealthcare) ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: healthcareController,
            label: '',
            placeholder: 'Enter health care details',
            minLines: 4,
            maxLines: 8,
          ),
        ],

        // Decide what other kinds of personal services I receive
        const SizedBox(height: 12),
        _buildToggleItem(
          title: 'Decide what other kinds of personal services I receive',
          isSelected: canDecideOtherPersonalService,
          onTap: () => onDecideOtherPersonalServiceChanged(
              !canDecideOtherPersonalService),
        ),
        if (canDecideOtherPersonalService) ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: otherPersonalServiceController,
            label: '',
            placeholder: 'Enter personal services details',
            minLines: 4,
            maxLines: 8,
          ),
        ],

        // Consent to the carrying out of medical or dental treatment
        const SizedBox(height: 12),
        _buildToggleItem(
          title:
              'Consent to the carrying out of medical or dental treatment on me',
          isSelected: canConsentMedicalAndDental,
          onTap: () =>
              onConsentMedicalAndDentalChanged(!canConsentMedicalAndDental),
        ),
        if (canConsentMedicalAndDental) ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: medicalDetailController,
            label: '',
            placeholder: 'Enter medical or dental treatment details',
            minLines: 4,
            maxLines: 8,
          ),
        ],

        // Others (always visible)
        const SizedBox(height: 16),
        Text('Others', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        AppTextArea(
          controller: otherDetailController,
          label: '',
          placeholder: 'Enter other details',
          minLines: 4,
          maxLines: 8,
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: RadioListOption(
            isSelected: isSelected,
            title: title,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}
