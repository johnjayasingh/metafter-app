import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/ahd_models.dart';

/// Full-screen form to add or edit an AHD attorney.
/// Returns an [AhdAttorneyData] on pop.
class AhdAddAttorneyScreen extends StatefulWidget {
  final AhdAttorneyData? existing;

  const AhdAddAttorneyScreen({super.key, this.existing});

  @override
  State<AhdAddAttorneyScreen> createState() => _AhdAddAttorneyScreenState();
}

class _AhdAddAttorneyScreenState extends State<AhdAddAttorneyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _middleName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  String _countryCode = FormConstants.defaultCountryCode;
  late TextEditingController _dob;
  late TextEditingController _address;

  bool get _isEditing =>
      widget.existing != null && widget.existing!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _middleName = TextEditingController(text: p?.middleName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _email = TextEditingController(text: p?.email ?? '');

    if (p?.phone != null && p!.phone!.isNotEmpty) {
      final (cc, local) = AppPhoneInput.parsePhoneNumber(p.phone!);
      _countryCode = cc;
      _phone = TextEditingController(text: local);
    } else {
      _phone = TextEditingController();
    }
    _dob = TextEditingController(text: p?.dob ?? '');
    _address = TextEditingController(text: p?.address ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final fullPhone = _phone.text.trim().isNotEmpty
        ? '$_countryCode${_phone.text.trim()}'
        : null;

    final person = AhdAttorneyData(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim().isNotEmpty
          ? _middleName.text.trim()
          : null,
      lastName: _lastName.text.trim(),
      email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
      phone: fullPhone,
      dob: _dob.text.trim().isNotEmpty ? _dob.text.trim() : null,
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
          _isEditing ? 'Edit attorney' : 'Add attorney',
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
                      AppTextField(
                        controller: _firstName,
                        label: 'First name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _middleName,
                        label: 'Middle name',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _lastName,
                        label: 'Last name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppEmailField(
                        controller: _email,
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                      AppPhoneInput(
                        controller: _phone,
                        countryCode: _countryCode,
                        onCountryCodeChanged: (code) =>
                            setState(() => _countryCode = code),
                      ),
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _dob,
                        label: 'Date of birth',
                        onDateSelected: (date) {
                          _dob.text = AppDatePickerField.formatDate(date);
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _address,
                        label: 'Address',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Save button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                  child: SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      text: _isEditing ? 'Update' : 'Save',
                      onPressed: _save,
                    ),
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
