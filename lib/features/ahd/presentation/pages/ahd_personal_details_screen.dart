import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/environment_config.dart';
import '../../../../core/services/mock_ahd_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../profile/data/models/profile_models.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../../data/services/ahd_service.dart';
import '../widgets/ahd_steps_sidebar.dart';

class AhdPersonalDetailsScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdPersonalDetailsScreen({super.key, required this.flowData});

  @override
  State<AhdPersonalDetailsScreen> createState() =>
      _AhdPersonalDetailsScreenState();
}

class _AhdPersonalDetailsScreenState extends State<AhdPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AhdService _ahdService = AhdService();
  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _profile;
  AhdFlowData? _existingAhd;
  AhdFlowData? _returnedFlowData;

  late final TextEditingController _fullNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    // Load profile and existing AHD in parallel
    final results = await Future.wait([
      _profileService.getProfile(),
      _ahdService.getAhdDetails(),
    ]);

    if (!mounted) return;

    final profileResponse = results[0] as dynamic;
    final ahdResponse = results[1] as AhdResponse;

    setState(() {
      _isLoading = false;
      if (profileResponse.isSuccess && profileResponse.data != null) {
        _profile = profileResponse.data;
        _populateFieldsFromProfile();
      }
      if (ahdResponse.isSuccess && ahdResponse.data != null) {
        _existingAhd = AhdFlowData.fromApiJson(ahdResponse.data!);
        print('🔴 [AHD Step1] Loaded existing AHD from API — state=${_existingAhd?.state}, healthConditions=${_existingAhd?.healthConditions?.substring(0, (_existingAhd?.healthConditions?.length ?? 0).clamp(0, 40))}...');
      } else {
        print('🔴 [AHD Step1] No existing AHD from API (isSuccess=${ahdResponse.isSuccess}, data=${ahdResponse.data == null ? "null" : "present"})');
      }
    });
  }

  void _populateFieldsFromProfile() {
    if (_profile == null) return;
    final p = _profile!;

    // Build full name
    final nameParts = <String>[
      p.firstName,
      if (p.middleName.isNotEmpty) p.middleName,
      if (p.lastName != null && p.lastName!.isNotEmpty) p.lastName!,
    ];
    _fullNameController.text = nameParts.join(' ');
    _dobController.text = p.dob ?? '';
    _addressController.text = p.address ?? '';
    _phoneController.text = p.mobile;
    _emailController.text = p.email;
    _selectedState = FormConstants.toStateApiValue(p.state);
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    // Update profile via API
    if (_profile != null) {
      final request = UserProfileUpdateRequest(
        firstName: _profile!.firstName,
        middleName: _profile!.middleName,
        lastName: _profile!.lastName,
        email: _emailController.text.trim(),
        mobile: _phoneController.text.trim(),
        dob: _dobController.text.trim().isNotEmpty
            ? _dobController.text.trim()
            : null,
        state: _selectedState,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        suburb: _profile!.suburb,
        postcode: _profile!.postcode,
        country: _profile!.country,
        contactPreference: _profile!.contactPreference ?? [],
      );
      final updateResponse = await _profileService.updateProfile(request);
      if (!mounted) return;

      if (!updateResponse.isSuccess) {
        setState(() => _isSaving = false);
        SnackBarUtils.showError(context, 'Failed to update profile');
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    // When debug prefill is on, always use mock data so all steps are pre-filled.
    // Otherwise: returned data (if user went back) → existing AHD → fresh.
    final AhdFlowData base;
    final String baseSource;
    if (EnvironmentConfig.useDebugPrefill && _selectedState != null) {
      base = MockAhdData.forState(_selectedState!);
      baseSource = 'MOCK';
    } else if (_returnedFlowData != null) {
      base = _returnedFlowData!;
      baseSource = 'RETURNED (back navigation)';
    } else if (_existingAhd != null) {
      base = _existingAhd!;
      baseSource = 'EXISTING API';
    } else {
      base = widget.flowData;
      baseSource = 'FRESH (empty)';
    }
    print('🔴 [AHD Step1] _handleNext base=$baseSource, healthConditions=${base.healthConditions != null}, lifeSustainingDirective=${base.lifeSustainingDirective}');
    final updated = base.copyWith(
      fullName: _fullNameController.text.trim(),
      dob: _dobController.text.trim(),
      addressLine1: _addressController.text.trim(),
      state: _selectedState,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    final config = AhdFlowConfig.forState(_selectedState);
    if (mounted) {
      final result = await context.push<AhdFlowData>(config.nextRoute(1), extra: updated);
      if (result != null) {
        _returnedFlowData = result;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(_selectedState);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(currentStep: 1, userState: _selectedState),
      appBar: WillCreationAppBar(
        currentStep: 1,
        totalSteps: config.totalSteps,
        title: 'Advance health directive',
        enableDrawer: true,
        exitTitle: 'Exit advance health directive?',
        exitDescription:
            'Your progress will be lost. You can start a new advance health directive at any time.',
        exitDiscardButtonText: 'Exit AHD',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 5),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your personal details',
                                style: AppTextStyles.pageTitle),
                            const SizedBox(height: 24),

                            // Full name
                            AppTextField(
                              controller: _fullNameController,
                              label: 'Full name',
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),

                            // Date of birth
                            AppDatePickerField(
                              controller: _dobController,
                              label: 'Date of birth',
                              isRequired: true,
                              onDateSelected: (date) {
                                setState(() {
                                  _dobController.text =
                                      AppDatePickerField.formatDate(date);
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            // Address section
                            Container(
                                height: 1, color: AppColors.borderGray),
                            const SizedBox(height: 24),
                            Text('Address',
                                style: AppTextStyles.questionTitle),
                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _addressController,
                              label: 'Address',
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),

                            AppDropdownFormField<String>(
                              value: _selectedState,
                              label: 'State',
                              items: FormConstants.australianStateKeys,
                              displayName: (value) =>
                                  FormConstants.getStateDisplayName(value),
                              onChanged: (value) {
                                setState(() => _selectedState = value);
                                Future.microtask(
                                    () => _formKey.currentState?.validate());
                              },
                              isRequired: true,
                            ),
                            const SizedBox(height: 24),

                            // Contact section
                            Container(
                                height: 1, color: AppColors.borderGray),
                            const SizedBox(height: 24),
                            Text('Contact',
                                style: AppTextStyles.questionTitle),
                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _phoneController,
                              label: 'Phone number',
                              isRequired: true,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d\s\+\-\(\)]')),
                              ],
                            ),
                            const SizedBox(height: 16),

                            AppEmailField(
                              controller: _emailController,
                              label: 'Email',
                              isRequired: true,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),

            // Bottom bar
            _AhdFirstStepBottomBar(
              onNext: _handleNext,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}

class _AhdFirstStepBottomBar extends StatelessWidget {
  final VoidCallback onNext;
  final bool isLoading;

  const _AhdFirstStepBottomBar({
    required this.onNext,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            text: 'Next step',
            onPressed: onNext,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }
}
