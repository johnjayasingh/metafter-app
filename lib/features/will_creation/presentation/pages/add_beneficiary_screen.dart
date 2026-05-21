import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/constants/debug_config.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/select_caretaker_bottom_sheet.dart';
import '../widgets/radio_option_widgets.dart';

class AddBeneficiaryScreen extends StatefulWidget {
  final BeneficiaryPersonData? existingData;
  
  const AddBeneficiaryScreen({
    super.key, 
    this.existingData,
  });

  @override
  State<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends State<AddBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  final SecureStorageService _storageService = SecureStorageService();
  bool _isSubmitting = false;
  List<CaretakerInfo> _loadedCaretakers = [];
  // Guardian fields
  final _caretakerFullNameController = TextEditingController();
  final _caretakerMiddleNameController = TextEditingController();
  final _caretakerLastNameController = TextEditingController();
  final _caretakerEmailController = TextEditingController();
  final _caretakerPhoneController = TextEditingController();
  final _caretakerDobController = TextEditingController();
  
  // Backup Guardian fields
  final _backupGuardianFullNameController = TextEditingController();
  final _backupGuardianMiddleNameController = TextEditingController();
  final _backupGuardianLastNameController = TextEditingController();
  final _backupGuardianEmailController = TextEditingController();
  final _backupGuardianPhoneController = TextEditingController();
  final _backupGuardianDobController = TextEditingController();
  
  String? _isMinor; // 'yes' or 'no'
  String? _selectedRelation;
  String _selectedCountryCode = FormConstants.defaultCountryCode;
  String _caretakerCountryCode = FormConstants.defaultCountryCode;
  String _backupGuardianCountryCode = FormConstants.defaultCountryCode;
  String? _guardianRelationship;
  String? _backupGuardianRelationship;
  String? _addGuardian; // 'yes' or 'no'
  String? _addBackupGuardian; // 'yes' or 'no'
  String? _selectedPreviousCaretaker;
  String? _selectedPreviousBackupGuardian;

  // Relations for beneficiary (using centralized FormConstants)
  List<String> get _relations => FormConstants.personRelations;

  bool get _isEditMode => widget.existingData != null;

  @override
  void initState() {
    super.initState();
    _initializeForEditMode();
    _loadGuardians();
  }

  void _initializeForEditMode() {
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _fullNameController.text = data.firstName;
      _middleNameController.text = data.middleName ?? '';
      _lastNameController.text = data.lastName;
      _dobController.text = AppDatePickerField.formatApiDateForDisplay(data.dob);
      _selectedRelation = data.relationship;
      _emailController.text = data.email ?? '';
      _isMinor = data.isMinor ? 'yes' : 'no';
      _addressController.text = data.address ?? '';
      
      // Parse phone number using centralized utility
      if (data.mobile != null && data.mobile!.isNotEmpty) {
        final (countryCode, localNumber) = AppPhoneInput.parsePhoneNumber(data.mobile!);
        _selectedCountryCode = countryCode;
        _phoneController.text = localNumber;
      }

      // Guardian data
      if (data.guardian != null) {
        _addGuardian = 'yes';
        _caretakerFullNameController.text = data.guardian!.firstName;
        _caretakerMiddleNameController.text = data.guardian!.middleName ?? '';
        _caretakerLastNameController.text = data.guardian!.lastName;
        _caretakerEmailController.text = data.guardian!.email ?? '';

        // Parse guardian phone
        if (data.guardian!.mobile != null && data.guardian!.mobile!.isNotEmpty) {
          final (guardianCountryCode, guardianLocalNumber) = AppPhoneInput.parsePhoneNumber(data.guardian!.mobile!);
          _caretakerCountryCode = guardianCountryCode;
          _caretakerPhoneController.text = guardianLocalNumber;
        }

        _caretakerDobController.text = AppDatePickerField.formatApiDateForDisplay(data.guardian!.dob);
        _guardianRelationship = data.guardian!.relationship;
      }

      // Backup guardian data
      if (data.backupGuardian != null) {
        _addBackupGuardian = 'yes';
        _backupGuardianFullNameController.text = data.backupGuardian!.firstName;
        _backupGuardianMiddleNameController.text = data.backupGuardian!.middleName ?? '';
        _backupGuardianLastNameController.text = data.backupGuardian!.lastName;
        _backupGuardianEmailController.text = data.backupGuardian!.email ?? '';

        if (data.backupGuardian!.mobile != null && data.backupGuardian!.mobile!.isNotEmpty) {
          final (bgCountryCode, bgLocalNumber) = AppPhoneInput.parsePhoneNumber(data.backupGuardian!.mobile!);
          _backupGuardianCountryCode = bgCountryCode;
          _backupGuardianPhoneController.text = bgLocalNumber;
        }
        
        _backupGuardianDobController.text = AppDatePickerField.formatApiDateForDisplay(data.backupGuardian!.dob);
        _backupGuardianRelationship = data.backupGuardian!.relationship;
      }
    } else if (DebugConfig.usePrepopulatedData) {
      // Prepopulate with test data
      _fullNameController.text = DebugConfig.testBeneficiary['fullName'] ?? '';
      _middleNameController.text = DebugConfig.testBeneficiary['middleName'] ?? '';
      _lastNameController.text = DebugConfig.testBeneficiary['lastName'] ?? '';
      _dobController.text = DebugConfig.testBeneficiary['dob'] ?? '';
      _selectedRelation = DebugConfig.testBeneficiary['relation'];
      _emailController.text = DebugConfig.testBeneficiary['email'] ?? '';
      _isMinor = DebugConfig.testBeneficiary['isMinor'];
      
      final phone = DebugConfig.testBeneficiary['phone'] as String?;
      final (countryCode, localNumber) = AppPhoneInput.parsePhoneNumber(phone);
      _selectedCountryCode = countryCode;
      _phoneController.text = localNumber;
    }
  }

  Future<void> _loadGuardians() async {
    final willId = await _storageService.getWillId();
    if (willId != null) {
      // Load all will persons - this is the comprehensive source of all adults
      context.read<WillBloc>().add(GetWillPersonsEvent(willId));
    }
  }

  void _buildGuardianOptionsFromWillPersons(List<WillPersonData> persons) {
    final caretakers = <CaretakerInfo>[];
    final seenNames = <String>{};
    for (final person in persons) {
      // Only include adults
      if (person.isMinor == true) continue;
      final firstName = person.firstName ?? '';
      final lastName = person.lastName ?? '';
      if (firstName.isEmpty && lastName.isEmpty) continue;
      final fullName = '$firstName$lastName'.toLowerCase().replaceAll(' ', '');
      if (!seenNames.contains(fullName)) {
        seenNames.add(fullName);
        caretakers.add(CaretakerInfo(
          id: person.willPersonId.toString(),
          firstName: firstName,
          middleName: person.middleName,
          lastName: lastName,
          email: person.email,
          mobile: person.mobile,
          dob: person.dob,
          relationship: person.relationship,
        ));
      }
    }
    setState(() {
      _loadedCaretakers = caretakers;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _caretakerFullNameController.dispose();
    _caretakerMiddleNameController.dispose();
    _caretakerLastNameController.dispose();
    _caretakerEmailController.dispose();
    _caretakerPhoneController.dispose();
    _caretakerDobController.dispose();
    _backupGuardianFullNameController.dispose();
    _backupGuardianMiddleNameController.dispose();
    _backupGuardianLastNameController.dispose();
    _backupGuardianEmailController.dispose();
    _backupGuardianPhoneController.dispose();
    _backupGuardianDobController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Prevent duplicate submissions on rapid clicks
    if (_isSubmitting) return;
    
    if (!_formKey.currentState!.validate()) return;
    
    // Validate required fields
    if (_fullNameController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please enter first name');
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please enter last name');
      return;
    }
    if (_selectedRelation == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please select a relation');
      return;
    }
    if (_isMinor == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please specify if this person is a minor');
      return;
    }
    // Validate email format only if provided
    if (_emailController.text.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        SnackBarUtils.showTopSnackBar(context, 'Please enter a valid email address');
        return;
      }
    }
    if (_dobController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please select date of birth');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please enter address');
      return;
    }
    
    final willId = await _storageService.getWillId();
    if (willId == null) {
      SnackBarUtils.showTopSnackBar(context, 'Will ID not found');
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    final beneficiary = BeneficiaryDetails(
      id: _isEditMode ? int.tryParse(widget.existingData!.id) : null,
      firstName: _fullNameController.text,
      middleName: _middleNameController.text.isNotEmpty ? _middleNameController.text : null,
      lastName: _lastNameController.text,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      mobile: _phoneController.text.trim().isNotEmpty
          ? AppPhoneInput.combinePhoneNumber(_selectedCountryCode, _phoneController.text)
          : null,
      relationship: _selectedRelation!,
      isMinor: _isMinor == 'yes',
      dob: _dobController.text.isNotEmpty ? _dobController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
    );
    
    // Create guardian if minor and guardian is added
    GuardianDetails? guardian;
    if (_isMinor == 'yes' && _addGuardian == 'yes' && _caretakerFullNameController.text.isNotEmpty) {
      final guardianPhone = _caretakerPhoneController.text.trim();
      final guardianEmail = _caretakerEmailController.text.trim();
      guardian = GuardianDetails(
        id: (_isEditMode && widget.existingData!.guardian != null)
            ? int.tryParse(widget.existingData!.guardian!.id)
            : null,
        firstName: _caretakerFullNameController.text,
        middleName: _caretakerMiddleNameController.text.isNotEmpty ? _caretakerMiddleNameController.text : null,
        lastName: _caretakerLastNameController.text,
        email: guardianEmail.isNotEmpty ? guardianEmail : null,
        mobile: guardianPhone.isNotEmpty
            ? AppPhoneInput.combinePhoneNumber(_caretakerCountryCode, guardianPhone)
            : null,
        dob: _caretakerDobController.text.isNotEmpty ? _caretakerDobController.text : null,
        relationship: _guardianRelationship,
      );
    }
    
    // Create backup guardian if minor and backup guardian is added
    GuardianDetails? backupGuardian;
    if (_isMinor == 'yes' && _addBackupGuardian == 'yes' && _backupGuardianFullNameController.text.isNotEmpty) {
      final bgPhone = _backupGuardianPhoneController.text.trim();
      final bgEmail = _backupGuardianEmailController.text.trim();
      backupGuardian = GuardianDetails(
        id: (_isEditMode && widget.existingData!.backupGuardian != null)
            ? int.tryParse(widget.existingData!.backupGuardian!.id)
            : null,
        firstName: _backupGuardianFullNameController.text,
        middleName: _backupGuardianMiddleNameController.text.isNotEmpty ? _backupGuardianMiddleNameController.text : null,
        lastName: _backupGuardianLastNameController.text,
        email: bgEmail.isNotEmpty ? bgEmail : null,
        mobile: bgPhone.isNotEmpty
            ? AppPhoneInput.combinePhoneNumber(_backupGuardianCountryCode, bgPhone)
            : null,
        dob: _backupGuardianDobController.text.isNotEmpty ? _backupGuardianDobController.text : null,
        relationship: _backupGuardianRelationship,
      );
    }
    
    final request = BeneficiaryPersonRequest(
      willId: willId,
      beneficiary: beneficiary,
      guardian: guardian,
      backupGuardian: backupGuardian,
    );
    
    context.read<WillBloc>().add(AddBeneficiaryPersonEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listenWhen: (previous, current) {
        // Listen for will persons loading or submission results
        return current is WillPersonsLoaded ||
               current is BeneficiaryPersonsLoaded ||
               (_isSubmitting && current is WillError);
      },
      listener: (context, state) {
        if (state is WillPersonsLoaded) {
          _buildGuardianOptionsFromWillPersons(state.persons);
        } else if (state is BeneficiaryPersonsLoaded) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            SnackBarUtils.showSuccess(context, _isEditMode ? 'Beneficiary updated successfully' : 'Beneficiary added successfully');
            context.pop();
          }
        } else if (state is WillError && _isSubmitting) {
          setState(() => _isSubmitting = false);
          SnackBarUtils.showError(context, 'Error: ${state.message}');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                decoration: AppDecorations.closeButtonBordered,
              child: const Center(
                child: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          _isEditMode ? 'Edit Beneficiary' : 'Add Beneficiaries',
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      _isEditMode ? 'Edit Beneficiary' : 'Add Beneficiaries',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide the full legal name to ensure they are easily identifiable',
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Is this beneficiary a minor?
                    Text(
                      'Is this beneficiary a minor?',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When adding a minor, a guardian has to be added under this as well',
                      style: AppTextStyles.subtitleSmall.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _isMinor == 'yes',
                            label: 'Yes',
                            onTap: () {
                              setState(() {
                                _isMinor = 'yes';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _isMinor == 'no',
                            label: 'No',
                            onTap: () {
                              setState(() {
                                _isMinor = 'no';
                                _addGuardian = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Form Fields - Using centralized AppTextField widget
                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _middleNameController,
                      label: 'Middle name (optional)',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _lastNameController,
                      label: 'Last name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    // DOB field with age constraints based on minor status
                    AppDobField(
                      controller: _dobController,
                      isRequired: true,
                      isMinor: _isMinor == 'yes',
                    ),
                    const SizedBox(height: 12),
                    // Relation dropdown using centralized constants
                    AppDropdown<String>(
                      value: _selectedRelation,
                      label: 'Relation',
                      items: FormConstants.personRelations,
                      displayName: FormConstants.getRelationDisplayName,
                      onChanged: (value) {
                        setState(() {
                          _selectedRelation = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Email field - optional for minors, required for adults
                    AppEmailField(
                      controller: _emailController,
                      isRequired: _isMinor == 'no',
                      label: _isMinor == 'no' ? 'Email' : 'Email (optional)',
                    ),
                    const SizedBox(height: 12),
                    // Phone input - required for adults, optional for minors
                    AppPhoneInput(
                      controller: _phoneController,
                      countryCode: _selectedCountryCode,
                      onCountryCodeChanged: (code) => setState(() => _selectedCountryCode = code),
                      isRequired: _isMinor == 'no',
                      label: _isMinor == 'no' ? 'Phone number' : 'Phone number (optional)',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _addressController,
                      label: 'Address',
                      isRequired: true,
                    ),

                    // Show caretaker section only if minor
                    if (_isMinor == 'yes') ...[
                      const SizedBox(height: 24),
                      
                      // Add Guardian (Minor) question - mandatory
                      Text(
                        'Add a Guardian (Minor)?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _addGuardian == 'yes',
                              label: 'Yes',
                              onTap: () {
                                setState(() {
                                  _addGuardian = 'yes';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _addGuardian == 'no',
                              label: 'No',
                              onTap: () {
                                setState(() {
                                  _addGuardian = 'no';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      // Show guardian fields when Yes is selected
                      if (_addGuardian == 'yes') ...[
                        const SizedBox(height: 16),
                        AppSelectField(
                          selectedText: _selectedPreviousCaretaker,
                          placeholder: 'Select previously added',
                          onTap: () async {
                            final result = await showModalBottomSheet<CaretakerInfo>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SelectCaretakerBottomSheet(
                                caretakers: _loadedCaretakers,
                                isGuardian: true,
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _selectedPreviousCaretaker = result.fullName;
                                _caretakerFullNameController.text = result.firstName;
                                _caretakerMiddleNameController.text = result.middleName ?? '';
                                _caretakerLastNameController.text = result.lastName;
                                _caretakerEmailController.text = result.email ?? '';

                                final (countryCode, localNumber) = AppPhoneInput.parsePhoneNumber(result.mobile);
                                _caretakerCountryCode = countryCode;
                                _caretakerPhoneController.text = localNumber;

                                _caretakerDobController.text =
                                    result.dob != null
                                        ? AppDatePickerField.formatApiDateForDisplay(result.dob!)
                                        : '';
                                _guardianRelationship = result.relationship;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _caretakerFullNameController,
                          label: 'Full name',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _caretakerMiddleNameController,
                          label: 'Middle name',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _caretakerLastNameController,
                          label: 'Last name',
                        ),
                        const SizedBox(height: 12),
                        AppEmailField(
                          controller: _caretakerEmailController,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        // Guardian phone input
                        AppPhoneInput(
                          controller: _caretakerPhoneController,
                          countryCode: _caretakerCountryCode,
                          onCountryCodeChanged: (code) => setState(() => _caretakerCountryCode = code),
                          isRequired: true,
                          label: 'Phone number',
                        ),
                        const SizedBox(height: 12),
                        // Guardian DOB field - adults only (must be 18+)
                        AppDobField(
                          controller: _caretakerDobController,
                          isRequired: true,
                          isMinor: false, // Guardian must be an adult
                        ),
                        const SizedBox(height: 12),
                        AppDropdownFormField<String>(
                          value: _guardianRelationship,
                          label: 'Relationship',
                          items: FormConstants.personRelations,
                          displayName: FormConstants.getRelationDisplayName,
                          onChanged: (value) {
                            setState(() {
                              _guardianRelationship = value;
                            });
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Add Backup Guardian question
                      Text(
                        'Add a Backup Guardian?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _addBackupGuardian == 'yes',
                              label: 'Yes',
                              onTap: () {
                                setState(() {
                                  _addBackupGuardian = 'yes';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _addBackupGuardian == 'no',
                              label: 'No',
                              onTap: () {
                                setState(() {
                                  _addBackupGuardian = 'no';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      // Show backup guardian fields when Yes is selected
                      if (_addBackupGuardian == 'yes') ...[
                        const SizedBox(height: 16),
                        AppSelectField(
                          selectedText: _selectedPreviousBackupGuardian,
                          placeholder: 'Select previously added',
                          onTap: () async {
                            final result = await showModalBottomSheet<CaretakerInfo>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SelectCaretakerBottomSheet(
                                caretakers: _loadedCaretakers,
                                isGuardian: true,
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _selectedPreviousBackupGuardian = result.fullName;
                                _backupGuardianFullNameController.text = result.firstName;
                                _backupGuardianMiddleNameController.text = result.middleName ?? '';
                                _backupGuardianLastNameController.text = result.lastName;
                                _backupGuardianEmailController.text = result.email ?? '';

                                final (countryCode, localNumber) = AppPhoneInput.parsePhoneNumber(result.mobile);
                                _backupGuardianCountryCode = countryCode;
                                _backupGuardianPhoneController.text = localNumber;

                                _backupGuardianDobController.text =
                                    result.dob != null
                                        ? AppDatePickerField.formatApiDateForDisplay(result.dob!)
                                        : '';
                                _backupGuardianRelationship = result.relationship;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _backupGuardianFullNameController,
                          label: 'Full name',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _backupGuardianMiddleNameController,
                          label: 'Middle name',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _backupGuardianLastNameController,
                          label: 'Last name',
                        ),
                        const SizedBox(height: 12),
                        AppEmailField(
                          controller: _backupGuardianEmailController,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        AppPhoneInput(
                          controller: _backupGuardianPhoneController,
                          countryCode: _backupGuardianCountryCode,
                          onCountryCodeChanged: (code) => setState(() => _backupGuardianCountryCode = code),
                          isRequired: true,
                          label: 'Phone number',
                        ),
                        const SizedBox(height: 12),
                        AppDobField(
                          controller: _backupGuardianDobController,
                          isMinor: false,
                        ),
                        const SizedBox(height: 12),
                        AppDropdownFormField<String>(
                          value: _backupGuardianRelationship,
                          label: 'Relationship',
                          items: FormConstants.personRelations,
                          displayName: FormConstants.getRelationDisplayName,
                          onChanged: (value) {
                            setState(() {
                              _backupGuardianRelationship = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom button - using centralized button widget
          AppBottomActionBar(
            child: AppPrimaryButton(
              text: _isEditMode ? 'Update' : 'Add',
              onPressed: _submitForm,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
