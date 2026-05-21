import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/ahd_models.dart';

/// Full-screen form to add or edit an SA AHD substitute decision-maker.
/// Returns an [AhdAttorneyData] on pop.
class AhdAddSubstituteDmScreen extends StatefulWidget {
  final AhdAttorneyData? existing;

  const AhdAddSubstituteDmScreen({super.key, this.existing});

  @override
  State<AhdAddSubstituteDmScreen> createState() =>
      _AhdAddSubstituteDmScreenState();
}

class _AhdAddSubstituteDmScreenState extends State<AhdAddSubstituteDmScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullName;
  late TextEditingController _phone;
  String _countryCode = FormConstants.defaultCountryCode;
  late TextEditingController _address;

  bool get _isEditing =>
      widget.existing != null && widget.existing!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _fullName = TextEditingController(text: p?.firstName ?? '');

    if (p?.phone != null && p!.phone!.isNotEmpty) {
      final (cc, local) = AppPhoneInput.parsePhoneNumber(p.phone!);
      _countryCode = cc;
      _phone = TextEditingController(text: local);
    } else {
      _phone = TextEditingController();
    }

    _address = TextEditingController(text: p?.address ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
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
      firstName: _fullName.text.trim(),
      lastName: '',
      phone: fullPhone,
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
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          'Substitute Decision-Maker',
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
                      AppPhoneInput(
                        controller: _phone,
                        countryCode: _countryCode,
                        onCountryCodeChanged: (code) =>
                            setState(() => _countryCode = code),
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
                      text: _isEditing
                          ? 'Update'
                          : 'Add Substitute Decision-Maker',
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
