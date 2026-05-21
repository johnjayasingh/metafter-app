import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/poa_models.dart';

/// Full-screen form to add or edit a POA person (attorney, successive attorney,
/// notification contact, etc.).  Returns a [PoaPersonData] on pop.
class PoaAddAttorneyScreen extends StatefulWidget {
  /// When editing, pass the existing person; null means "add new".
  final PoaPersonData? existing;

  const PoaAddAttorneyScreen({super.key, this.existing});

  @override
  State<PoaAddAttorneyScreen> createState() => _PoaAddAttorneyScreenState();
}

class _PoaAddAttorneyScreenState extends State<PoaAddAttorneyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _middleName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;
  String _countryCode = FormConstants.defaultCountryCode;

  bool get _isEditing => widget.existing != null && widget.existing!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _middleName = TextEditingController(text: p?.middleName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _address = TextEditingController(text: p?.address ?? '');

    // Parse phone if provided
    if (p?.phone != null && p!.phone!.isNotEmpty) {
      final (cc, local) = AppPhoneInput.parsePhoneNumber(p.phone!);
      _countryCode = cc;
      _phone = TextEditingController(text: local);
    } else {
      _phone = TextEditingController();
    }
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

    final person = PoaPersonData(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim().isNotEmpty
          ? _middleName.text.trim()
          : null,
      lastName: _lastName.text.trim(),
      role: widget.existing?.role ?? 'Attorney',
      email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
      phone: fullPhone,
      address: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
      attorneyId: widget.existing?.attorneyId,
      attorneyPoaId: widget.existing?.attorneyPoaId,
      attorneyType: widget.existing?.attorneyType,
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
                      Text(
                        'Personal information',
                        style: AppTextStyles.questionTitle,
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
                        isRequired: false,
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
                    text: _isEditing ? 'Save changes' : 'Add attorney',
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
