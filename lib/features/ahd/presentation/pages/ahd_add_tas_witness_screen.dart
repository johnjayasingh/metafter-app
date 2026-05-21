import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/ahd_models.dart';

/// Full-screen form to add or edit a TAS AHD witness.
/// Returns an [AhdAttorneyData] on pop.
class AhdAddTasWitnessScreen extends StatefulWidget {
  final AhdAttorneyData? existing;

  const AhdAddTasWitnessScreen({super.key, this.existing});

  @override
  State<AhdAddTasWitnessScreen> createState() => _AhdAddTasWitnessScreenState();
}

class _AhdAddTasWitnessScreenState extends State<AhdAddTasWitnessScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullName;
  bool _isHealthPractitioner = false;
  late TextEditingController _qualification;
  late TextEditingController _signature;
  late TextEditingController _dob;
  late TextEditingController _address;

  bool get _isEditing =>
      widget.existing != null && widget.existing!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _fullName = TextEditingController(text: p?.firstName ?? '');
    _isHealthPractitioner = p?.isHealthPractitioner ?? false;
    _qualification = TextEditingController(text: p?.qualification ?? '');
    _signature = TextEditingController(text: p?.signature ?? '');
    _dob = TextEditingController(text: p?.dob ?? '');
    _address = TextEditingController(text: p?.address ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _qualification.dispose();
    _signature.dispose();
    _dob.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final person = AhdAttorneyData(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _fullName.text.trim(),
      lastName: '',
      dob: _dob.text.trim().isNotEmpty ? _dob.text.trim() : null,
      address: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
      signature: _signature.text.trim().isNotEmpty
          ? _signature.text.trim()
          : null,
      isHealthPractitioner: _isHealthPractitioner,
      qualification: _qualification.text.trim().isNotEmpty
          ? _qualification.text.trim()
          : null,
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
          _isEditing ? 'Edit witness' : 'Add witness',
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
                        label: 'Name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _qualification,
                        label: 'Qualification and AHPRA number',
                      ),
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
                      text: _isEditing ? 'Update' : 'Add witness',
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
