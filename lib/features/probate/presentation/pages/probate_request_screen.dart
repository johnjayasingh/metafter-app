import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/services/probate_service.dart';

class ProbateRequestScreen extends StatefulWidget {
  const ProbateRequestScreen({super.key});

  @override
  State<ProbateRequestScreen> createState() => _ProbateRequestScreenState();
}

class _ProbateRequestScreenState extends State<ProbateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _probateService = ProbateService();

  // ── Personal info ──────────────────────────────────────────────────────────
  final _surnameController = TextEditingController();
  final _givenNamesController = TextEditingController();
  String? _gender;
  final _occupationController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDob;
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _suburbController = TextEditingController();
  String? _state;
  final _postcodeController = TextEditingController();
  String _countryCode = '+61';
  final _phoneController = TextEditingController();

  // ── Service source ─────────────────────────────────────────────────────────
  String? _serviceSource;

  // ── Deceased info ──────────────────────────────────────────────────────────
  final _deceasedAddressController = TextEditingController();
  String? _isDeceasedQldResident; // 'true' / 'false'
  String? _isDeceasedLeftPropertyQld;
  String? _isDeceasedLeftWill;
  String? _isExecutorApplying;
  String? _isExecutorApplied;

  // ── Document ───────────────────────────────────────────────────────────────
  String? _documentPath;
  String? _documentName;

  bool _isSubmitting = false;

  // ── Lookup tables ──────────────────────────────────────────────────────────
  static const _genders = ['male', 'female', 'non_binary', 'prefer_not_to_say'];
  static const _genderLabels = {
    'male': 'Male',
    'female': 'Female',
    'non_binary': 'Non-binary',
    'prefer_not_to_say': 'Prefer not to say',
  };

  static const _boolOptions = ['true', 'false'];
  static const _boolLabels = {'true': 'Yes', 'false': 'No'};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _givenNamesController.dispose();
    _occupationController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    _deceasedAddressController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        setState(() {
          _documentPath = file.path;
          _documentName = file.name;
        });
      }
    }
  }

  Future<void> _submit() async {
    // Validate all required fields
    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      SnackBarUtils.showError(context, 'Please select your gender');
      return;
    }
    if (_state == null) {
      SnackBarUtils.showError(context, 'Please select your state');
      return;
    }
    if (_serviceSource == null) {
      SnackBarUtils.showError(context, 'Please select how you heard about this service');
      return;
    }
    if (_isDeceasedQldResident == null ||
        _isDeceasedLeftPropertyQld == null ||
        _isDeceasedLeftWill == null ||
        _isExecutorApplying == null ||
        _isExecutorApplied == null) {
      SnackBarUtils.showError(context, 'Please answer all questions about the deceased');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final phoneNumber = '${_countryCode} ${_phoneController.text.trim()}';
      final result = await _probateService.createProbateRequest(
        surname: _surnameController.text.trim(),
        givenNames: _givenNamesController.text.trim(),
        gender: _gender,
        occupation: _occupationController.text.trim(),
        dateOfBirth: _selectedDob != null
            ? '${_selectedDob!.year.toString().padLeft(4, '0')}-'
              '${_selectedDob!.month.toString().padLeft(2, '0')}-'
              '${_selectedDob!.day.toString().padLeft(2, '0')}'
            : null,
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        suburb: _suburbController.text.trim(),
        state: _state,
        postcode: _postcodeController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? phoneNumber : null,
        serviceSource: _serviceSource,
        deceasedLastKnownAddress: _deceasedAddressController.text.trim(),
        isDeceasedResident: _isDeceasedQldResident == 'true',
        isDeceasedLeftProperty: _isDeceasedLeftPropertyQld == 'true',
        isDeceasedLeftWill: _isDeceasedLeftWill == 'true',
        isExecutorApplying: _isExecutorApplying == 'true',
        isExecutorApplied: _isExecutorApplied == 'true',
        documentPath: _documentPath,
        documentName: _documentName,
      );

      if (!mounted) return;

      if (result != null) {
        SnackBarUtils.showSuccess(
          context,
          'Probate request submitted successfully',
        );
        // Navigate back to home after successful submission
        context.go(AppRouter.home);
      } else {
        SnackBarUtils.showError(
          context,
          'Failed to submit probate request. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: WillCreationAppBar(
        title: 'Probate Request',
        currentStep: 1,
        totalSteps: 1,
        showStepNumber: false,
        skipExitConfirmation: true,
        onExitNavigate: () => context.go(AppRouter.home),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page title
                      Text(
                        'Probate Request',
                        style: AppTextStyles.pageTitle.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Probate confirms the will in court and allows you to act as the executor',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AppColors.borderGray),
                      ),

                      // ── Section 1: Personal info ─────────────────────────
                      _buildSectionHeader('Your Details'),
                      const SizedBox(height: 16),

                      // Surname
                      AppTextField(
                        controller: _surnameController,
                        label: 'Surname',
                        isRequired: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Surname is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Given names
                      AppTextField(
                        controller: _givenNamesController,
                        label: 'Given name/s',
                        isRequired: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Given name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      AppDropdown<String>(
                        value: _gender,
                        label: 'Gender',
                        items: _genders,
                        displayName: (g) => _genderLabels[g] ?? g,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 16),

                      // Occupation
                      AppTextField(
                        controller: _occupationController,
                        label: 'Occupation',
                        isRequired: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Occupation is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // DOB
                      AppDatePickerField(
                        controller: _dobController,
                        label: 'DOB',
                        isRequired: true,
                        lastDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDob = date;
                            _dobController.text =
                                '${date.day.toString().padLeft(2, '0')}/'
                                '${date.month.toString().padLeft(2, '0')}/'
                                '${date.year}';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      AppTextField(
                        controller: _emailController,
                        label: 'Email address',
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailReg.hasMatch(v.trim())) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      AppTextField(
                        controller: _addressController,
                        label: 'Address',
                        isRequired: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Suburb
                      AppTextField(
                        controller: _suburbController,
                        label: 'Suburb',
                        isRequired: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Suburb is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // State
                      AppDropdown<String>(
                        value: _state,
                        label: 'State',
                        items: FormConstants.australianStateKeys,
                        displayName: (s) => FormConstants.getStateDisplayName(s),
                        onChanged: (v) => setState(() => _state = v),
                      ),
                      const SizedBox(height: 16),

                      // Postcode
                      AppTextField(
                        controller: _postcodeController,
                        label: 'Postcode',
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Postcode is required';
                          }
                          if (value.trim().length != 4) {
                            return 'Postcode must be 4 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone number (full width)
                      _buildFieldLabel('Phone number'),
                      const SizedBox(height: 8),
                      AppPhoneInput(
                        controller: _phoneController,
                        countryCode: _countryCode,
                        onCountryCodeChanged: (code) =>
                            setState(() => _countryCode = code),
                        isRequired: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Section 2: Service source ─────────────────────────
                      _buildSectionHeader('How did you hear about this service?'),
                      const SizedBox(height: 16),

                      _buildFieldLabel('State'),
                      const SizedBox(height: 8),
                      AppDropdown<String>(
                        value: _serviceSource,
                        label: 'Select',
                        items: FormConstants.australianStateKeys,
                        displayName: (s) => FormConstants.getStateDisplayName(s),
                        onChanged: (v) => setState(() => _serviceSource = v),
                      ),
                      if (_serviceSource == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            'Please select how you heard about this service',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.errorRed2,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // ── Section 3: About the Deceased ─────────────────────
                      _buildSectionHeader('About the Deceased'),
                      const SizedBox(height: 16),

                      _buildFieldLabel('Deceased last residential address'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _deceasedAddressController,
                        label: 'Enter address',
                        isRequired: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Deceased address is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Did the deceased reside in the state
                      _buildBoolDropdown(
                        label: 'Did the deceased reside in the state',
                        value: _isDeceasedQldResident,
                        onChanged: (v) =>
                            setState(() => _isDeceasedQldResident = v),
                      ),
                      const SizedBox(height: 16),

                      // Did the deceased leave property in the state
                      _buildBoolDropdown(
                        label: 'Did the deceased leave property in the state',
                        value: _isDeceasedLeftPropertyQld,
                        onChanged: (v) =>
                            setState(() => _isDeceasedLeftPropertyQld = v),
                      ),
                      const SizedBox(height: 16),

                      // Did the deceased leave a last will
                      _buildBoolDropdown(
                        label: 'Did the deceased leave a last will',
                        value: _isDeceasedLeftWill,
                        onChanged: (v) =>
                            setState(() => _isDeceasedLeftWill = v),
                      ),
                      const SizedBox(height: 16),

                      // Are you the executor of the last will
                      _buildBoolDropdown(
                        label: 'Are you the executor of the last will',
                        value: _isExecutorApplying,
                        onChanged: (v) =>
                            setState(() => _isExecutorApplying = v),
                      ),
                      const SizedBox(height: 16),

                      // Are all executors appointed
                      _buildBoolDropdown(
                        label: 'Are all of the executives appointed under the last',
                        value: _isExecutorApplied,
                        onChanged: (v) =>
                            setState(() => _isExecutorApplied = v),
                      ),

                      const SizedBox(height: 32),

                      // ── Section 4: Upload document ─────────────────────────
                      _buildUploadSection(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Bottom bar ────────────────────────────────────────────────
              AppBottomActionBar(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Back',
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (context.canPop()) context.pop();
                                else context.go(AppRouter.home);
                              },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Request probate',
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBoolDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        AppDropdown<String>(
          value: value,
          label: 'Select',
          items: _boolOptions,
          displayName: (v) => _boolLabels[v] ?? v,
          onChanged: onChanged,
        ),
        if (value == null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'This field is required',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorRed2,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: AppColors.primaryDarkGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload document',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This step ensures banks, registries, and other institutions can legally recognise your authority.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_documentName != null)
            GestureDetector(
              onTap: _pickDocument,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined, size: 18,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _documentName!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() {
                            _documentPath = null;
                            _documentName = null;
                          }),
                      child: const Icon(Icons.close, size: 16,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            AppPrimaryButton(
              text: 'Choose file',
              icon: Icons.attach_file,
              fullWidth: false,
              onPressed: _pickDocument,
            ),
        ],
      ),
    );
  }
}
