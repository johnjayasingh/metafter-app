import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/profile_models.dart';
import '../../data/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressController;
  late final TextEditingController _suburbController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _countryController;
  String? _selectedState;
  bool _emailPreference = false;
  bool _smsPreference = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.userProfile.firstName);
    _middleNameController = TextEditingController(text: widget.userProfile.middleName);
    _lastNameController = TextEditingController(text: widget.userProfile.lastName ?? '');
    _emailController = TextEditingController(text: widget.userProfile.email);
    _phoneController = TextEditingController(text: widget.userProfile.mobile);
    _dobController = TextEditingController(text: widget.userProfile.dob ?? '');
    _addressController = TextEditingController(text: widget.userProfile.address ?? '');
    _suburbController = TextEditingController(text: widget.userProfile.suburb ?? '');
    _postcodeController = TextEditingController(text: widget.userProfile.postcode ?? '');
    _countryController = TextEditingController(text: widget.userProfile.country);

    // Initialize contact preferences
    final contactPref = widget.userProfile.contactPreference ?? [];
    _emailPreference = contactPref.contains('EMAIL');
    _smsPreference = contactPref.contains('SMS');

    final rawState = widget.userProfile.state;
    final normalizedState = FormConstants.toStateApiValue(rawState);
    print('[EditProfile] Raw state from profile: "$rawState"');
    print('[EditProfile] Normalized state: "$normalizedState"');
    print('[EditProfile] Available state keys: ${FormConstants.australianStateKeys}');
    _selectedState = normalizedState;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Validate required fields
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your state'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Build contact preference list
    final contactPreferences = <String>[];
    if (_emailPreference) contactPreferences.add('EMAIL');
    if (_smsPreference) contactPreferences.add('SMS');

    final updateRequest = UserProfileUpdateRequest(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _phoneController.text.trim(),
      dob: _dobController.text.trim().isEmpty
          ? null
          : _dobController.text.trim(),
      state: _selectedState,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      suburb: _suburbController.text.trim().isEmpty
          ? null
          : _suburbController.text.trim(),
      postcode: _postcodeController.text.trim().isEmpty
          ? null
          : _postcodeController.text.trim(),
      country: _countryController.text.trim(),
      contactPreference: contactPreferences,
    );

    final response = await _profileService.updateProfile(updateRequest);

    setState(() => _isSaving = false);

    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Return true to indicate success
        context.pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty 
                ? response.message 
                : 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.pageTitle),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'First name',
                    controller: _firstNameController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Middle name',
                    controller: _middleNameController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Last name',
                    controller: _lastNameController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderGray),
                          borderRadius: BorderRadius.circular(12),
                          color: _isSaving ? Colors.grey[100] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('+61', style: AppTextStyles.bodyMedium),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Phone number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_isSaving,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'DOB *',
                    controller: _dobController,
                    readOnly: true,
                    enabled: !_isSaving,
                    suffixIconWidget: const Icon(Icons.calendar_today, size: 20),
                    onTap: _isSaving ? null : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1956, 1, 20),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _dobController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Contact Preference Section
                  Text('Contact Preference', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 4),
                  Text(
                    'How would you like to be contacted?',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _emailPreference,
                    onChanged: _isSaving ? null : (value) {
                      setState(() => _emailPreference = value ?? false);
                    },
                    title: Text('Email', style: AppTextStyles.bodyMedium),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryGreen,
                  ),
                  CheckboxListTile(
                    value: _smsPreference,
                    onChanged: _isSaving ? null : (value) {
                      setState(() => _smsPreference = value ?? false);
                    },
                    title: Text('SMS', style: AppTextStyles.bodyMedium),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 32),

                  // Address Section
                  Text('Address', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Where are you based',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Address',
                    controller: _addressController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Suburb',
                    controller: _suburbController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  AppDropdownFormField<String>(
                    value: _selectedState,
                    label: 'State',
                    isRequired: true,
                    items: FormConstants.australianStateKeys,
                    displayName: (s) => FormConstants.getStateDisplayName(s),
                    onChanged: _isSaving ? null : (v) => setState(() => _selectedState = v),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Postcode',
                    controller: _postcodeController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && value.trim().length != 4) {
                        return 'Postcode must be 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Country',
                    controller: _countryController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      text: 'Cancel',
                      onPressed: _isSaving ? null : () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      text: _isSaving ? 'Saving...' : 'Save',
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
