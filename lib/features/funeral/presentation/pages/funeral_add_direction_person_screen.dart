import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';

/// Full-screen form to add a person for "Under whose direction".
/// Returns a [RecipientInfo] on pop.
class FuneralAddDirectionPersonScreen extends StatefulWidget {
  const FuneralAddDirectionPersonScreen({super.key});

  @override
  State<FuneralAddDirectionPersonScreen> createState() =>
      _FuneralAddDirectionPersonScreenState();
}

class _FuneralAddDirectionPersonScreenState
    extends State<FuneralAddDirectionPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _middleName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;
  String _countryCode = FormConstants.defaultCountryCode;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _middleName = TextEditingController();
    _lastName = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final fullPhone = _phone.text.trim().isNotEmpty
        ? '$_countryCode${_phone.text.trim()}'
        : null;

    final person = RecipientInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim().isNotEmpty
          ? _middleName.text.trim()
          : null,
      lastName: _lastName.text.trim(),
      email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
      mobile: fullPhone,
      address: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
    );

    context.pop(person);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
        title: Text(
          'Add direction person',
          style: AppTextStyles.pageTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's the person's name?",
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please provide the individual\'s full name to ensure they are easily identifiable',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _firstName,
                        label: 'First name',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        controller: _middleName,
                        label: 'Middle name (optional)',
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        controller: _lastName,
                        label: 'Last name',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      AppEmailField(
                        controller: _email,
                        label: 'Email address (optional)',
                      ),
                      const SizedBox(height: 12),

                      AppPhoneInput(
                        controller: _phone,
                        countryCode: _countryCode,
                        onCountryCodeChanged: (code) =>
                            setState(() => _countryCode = code),
                        label: 'Mobile number (optional)',
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        controller: _address,
                        label: 'Address (optional)',
                      ),
                    ],
                  ),
                ),
              ),

              // Save button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: AppPrimaryButton(
                    text: 'Add direction person',
                    onPressed: _save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
