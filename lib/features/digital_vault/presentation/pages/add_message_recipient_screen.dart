import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/vault_models.dart';

class AddMessageRecipientScreen extends StatefulWidget {
  const AddMessageRecipientScreen({super.key});

  @override
  State<AddMessageRecipientScreen> createState() =>
      _AddMessageRecipientScreenState();
}

class _AddMessageRecipientScreenState
    extends State<AddMessageRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _countryCode = '+61';

  @override
  void initState() {
    super.initState();
    if (DebugDataService.isEnabled) {
      final mock = DebugDataService.debugVaultRecipientData;
      _firstNameController.text = mock['firstName'] ?? '';
      _lastNameController.text = mock['lastName'] ?? '';
      _emailController.text = mock['email'] ?? '';
      if (mock['mobile'] != null && mock['mobile']!.isNotEmpty) {
        final (code, number) = AppPhoneInput.parsePhoneNumber(mock['mobile']!);
        _countryCode = code;
        _phoneController.text = number;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();
    final recipient = WillPerson(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isNotEmpty
          ? _middleNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      mobile: phone.isNotEmpty
          ? AppPhoneInput.combinePhoneNumber(_countryCode, phone)
          : null,
    );

    context.pop(recipient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('Add Recipient', style: AppTextStyles.sectionTitle),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add the details of the person you would like to receive this message.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _firstNameController,
                        label: 'First name',
                        isRequired: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _middleNameController,
                        label: 'Middle name',
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _lastNameController,
                        label: 'Last name',
                        isRequired: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      AppEmailField(
                        controller: _emailController,
                        label: 'Email address',
                      ),
                      const SizedBox(height: 16),
                      AppPhoneInput(
                        controller: _phoneController,
                        countryCode: _countryCode,
                        onCountryCodeChanged: (code) {
                          setState(() => _countryCode = code);
                        },
                        label: 'Phone number',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppBottomActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: AppCancelButton(
                      text: 'Cancel',
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Save',
                      onPressed: _onSave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
