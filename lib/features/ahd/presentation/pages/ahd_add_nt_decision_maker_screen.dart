import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';

/// Full-screen form to add or edit an NT AHD decision maker.
/// Returns an [AhdAttorneyData] on pop.
///
/// When [isPrimary] is true (adult/PRIMARY_PERSON), only shows:
///   - Full name, Address, Matters
/// When [isPrimary] is false (appointed/DECISION_MAKER), shows:
///   - Full name, DOB, Phone, Address
class AhdAddNtDecisionMakerScreen extends StatefulWidget {
  final AhdAttorneyData? existing;
  final bool isPrimary;

  const AhdAddNtDecisionMakerScreen({
    super.key,
    this.existing,
    this.isPrimary = false,
  });

  @override
  State<AhdAddNtDecisionMakerScreen> createState() =>
      _AhdAddNtDecisionMakerScreenState();
}

class _AhdAddNtDecisionMakerScreenState
    extends State<AhdAddNtDecisionMakerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullName;
  late TextEditingController _address;
  late TextEditingController _dob;
  late TextEditingController _phone;
  String _countryCode = FormConstants.defaultCountryCode;
  String? _matters;

  bool get _isEditing =>
      widget.existing != null && widget.existing!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _fullName = TextEditingController(text: p?.firstName ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    _dob = TextEditingController(text: p?.dob ?? '');
    _matters = p?.matters;

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
    _fullName.dispose();
    _address.dispose();
    _dob.dispose();
    _phone.dispose();
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
      firstName: _fullName.text.trim(),
      lastName: '',
      phone: widget.isPrimary ? null : fullPhone,
      dob: widget.isPrimary
          ? null
          : (_dob.text.trim().isNotEmpty ? _dob.text.trim() : null),
      address: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
      matters: widget.isPrimary ? _matters : null,
    );

    context.pop(person);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isPrimary ? 'decision maker' : 'decision maker';
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
          _isEditing ? 'Edit $label' : 'Add $label',
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
                        controller: _fullName,
                        label: 'Full name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Appointed: DOB + Phone
                      if (!widget.isPrimary) ...[
                        AppDatePickerField(
                          controller: _dob,
                          label: 'DOB',
                          onDateSelected: (date) {
                            setState(() {
                              _dob.text = AppDatePickerField.formatDate(date);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        AppPhoneInput(
                          controller: _phone,
                          countryCode: _countryCode,
                          onCountryCodeChanged: (code) =>
                              setState(() => _countryCode = code),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Address (both types)
                      AppTextField(
                        controller: _address,
                        label: 'Address',
                      ),

                      // Appointed: Matters section
                      if (!widget.isPrimary) ...[
                        const SizedBox(height: 24),
                        Text('Matters', style: AppTextStyles.questionTitle),
                        const SizedBox(height: 12),
                        RadioListOption(
                          isSelected: _matters == NtMatters.allMatters,
                          title: 'All matters',
                          onTap: () =>
                              setState(() => _matters = NtMatters.allMatters),
                        ),
                        RadioListOption(
                          isSelected: _matters == NtMatters.financialMatters,
                          title:
                              'Financial matters (including dealing in property)',
                          onTap: () => setState(
                              () => _matters = NtMatters.financialMatters),
                        ),
                        RadioListOption(
                          isSelected:
                              _matters == NtMatters.personalHealthMatters,
                          title: 'Personal/health matters',
                          onTap: () => setState(
                              () => _matters = NtMatters.personalHealthMatters),
                        ),
                        RadioListOption(
                          isSelected: _matters == NtMatters.limitedMatters,
                          title: 'Limited matters (specify)',
                          onTap: () => setState(
                              () => _matters = NtMatters.limitedMatters),
                        ),
                      ],
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
                      text: _isEditing ? 'Update' : 'Add $label',
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
