import 'package:digitalwill/core/theme/app_colors.dart';
import 'package:digitalwill/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/debug_config.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/contact_validator.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';

class AddFormerPartnerScreen extends StatefulWidget {
  final PartnerData? existingData;
  final String? partnerType; // CURRENT, DEFACTO, or FORMER

  const AddFormerPartnerScreen({
    super.key, 
    this.existingData,
    this.partnerType,
  });

  @override
  State<AddFormerPartnerScreen> createState() => _AddFormerPartnerScreenState();
}

class _AddFormerPartnerScreenState extends State<AddFormerPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedCountryCode = FormConstants.defaultCountryCode;
  String? _selectedPartnerType;
  String? _selectedRelationship;
  String? _dob;

  final SecureStorageService _storageService = SecureStorageService();
  bool _isSubmitting = false;
  bool _isLoadingPartnerType = false;
  List<ExistingContact> _existingContacts = [];
  ContactValidator _contactValidator = ContactValidator([]);

  bool get _isEditMode => widget.existingData != null;
  
  String get _partnerType => _selectedPartnerType ?? widget.existingData?.partner.partnerType ?? widget.partnerType ?? PartnerType.former;
  
  String get _partnerTypeLabel => PartnerType.getDisplayName(_partnerType);
  
  String get _screenTitle {
    if (_isEditMode) {
      return 'Edit Partner';
    }
    return 'Add Partner';
  }

  // Partner type options for dropdown
  final List<String> _partnerTypes = [
    PartnerType.current,
    PartnerType.defacto,
    PartnerType.former,
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingContacts();
    _loadRelationshipStatus();
    if (widget.existingData != null) {
      _fullNameController.text = widget.existingData!.partner.firstName;
      _middleNameController.text = widget.existingData!.partner.middleName ?? '';
      _lastNameController.text = widget.existingData!.partner.lastName;
      _emailController.text = widget.existingData!.partner.email;
      final (code, number) = AppPhoneInput.parsePhoneNumber(widget.existingData!.partner.mobile);
      _selectedCountryCode = code;
      _phoneController.text = number;
      _selectedPartnerType = widget.existingData!.partner.partnerType;
      _selectedRelationship = widget.existingData!.partner.relationship;
      _addressController.text = widget.existingData!.partner.address ?? '';
      _dob = widget.existingData!.partner.dob;
      if (_dob != null) {
        _dobController.text = _dob!;
      }
    } else {
      // Set initial partner type from widget or default to former
      _selectedPartnerType = widget.partnerType ?? PartnerType.former;
      
      if (DebugConfig.usePrepopulatedData) {
        _fullNameController.text = DebugConfig.testFormerPartner['fullName'] ?? '';
        _middleNameController.text = DebugConfig.testFormerPartner['middleName'] ?? '';
        _lastNameController.text = DebugConfig.testFormerPartner['lastName'] ?? '';
        _emailController.text = DebugConfig.testFormerPartner['email'] ?? '';
        final phone = DebugConfig.testFormerPartner['phone'] as String?;
        if (phone != null && phone.isNotEmpty) {
          final (code, number) = AppPhoneInput.parsePhoneNumber(phone);
          _selectedCountryCode = code;
          _phoneController.text = number;
        }
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingContacts() async {
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetPartnersEvent(willId));
    }
  }

  Future<void> _loadRelationshipStatus() async {
    if (_isEditMode) return; // No need to load for edit mode
    setState(() => _isLoadingPartnerType = true);
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetFamilyInitialEvent(willId));
    }
  }

  void _setPartnerTypeFromRelationshipStatus(String? relationshipStatus) {
    // Only auto-set if not in edit mode and no explicit partnerType was passed
    if (_isEditMode) return;
    if (widget.partnerType != null) return;

    String defaultType;
    if (relationshipStatus == 'MARRIED' || relationshipStatus == 'MARRIED_OR_ENGAGED') {
      defaultType = PartnerType.current;
    } else if (relationshipStatus == 'DE_FACTO' || relationshipStatus == 'DEFACTO') {
      defaultType = PartnerType.defacto;
    } else {
      defaultType = PartnerType.former;
    }
    setState(() {
      _selectedPartnerType = defaultType;
      _isLoadingPartnerType = false;
    });
  }

  void _buildContactList(List<PartnerData> partners) {
    final contacts = <ExistingContact>[];
    for (final partner in partners) {
      // Skip the current partner being edited
      if (_isEditMode && partner.id == widget.existingData!.id) continue;
      contacts.add(ExistingContact(
        id: partner.partner.id,
        name: '${partner.partner.firstName} ${partner.partner.lastName}',
        email: partner.partner.email,
        mobile: partner.partner.mobile,
      ));
    }
    setState(() {
      _existingContacts = contacts;
      _contactValidator = ContactValidator(_existingContacts);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final willId = await _storageService.getWillId();
    if (willId == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Will ID not found')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final partner = PartnerDetails(
      id: _isEditMode ? widget.existingData!.partner.id : null,
      firstName: _fullNameController.text,
      middleName: _middleNameController.text.isNotEmpty
          ? _middleNameController.text
          : null,
      lastName: _lastNameController.text,
      email: _emailController.text,
      mobile: AppPhoneInput.combinePhoneNumber(
        _selectedCountryCode, 
        _phoneController.text, 
        withSpace: false,
      ),
      partnerType: _partnerType,
      relationship: _selectedRelationship,
      dob: _dob,
      address: _addressController.text.isNotEmpty
          ? _addressController.text
          : null,
    );

    final request = PartnerRequest(
      willId: willId,
      partner: partner,
    );

    context.read<WillBloc>().add(AddPartnerEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listenWhen: (previous, current) {
        return current is PartnersLoaded || 
            current is FamilyInitialLoaded ||
            (_isSubmitting && current is WillError);
      },
      listener: (context, state) {
        if (state is FamilyInitialLoaded) {
          _setPartnerTypeFromRelationshipStatus(state.familyData.relationshipStatus);
        } else if (state is WillError && _isLoadingPartnerType) {
          setState(() => _isLoadingPartnerType = false);
        } else if (state is PartnersLoaded) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEditMode
                      ? '$_partnerTypeLabel updated successfully'
                      : '$_partnerTypeLabel added successfully',
                ),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
            context.pop();
          } else {
            // Loading partners for contact validation
            _buildContactList(state.partners);
          }
        } else if (state is WillError) {
          setState(() => _isSubmitting = false);
          // Only show error if message is not empty (skip network errors)
          if (state.message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.textBrand,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            _screenTitle,
            style: AppTextStyles.stepTitle,
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Partner Type Selection
                        Text(
                          'Partner type',
                          style: AppTextStyles.itemLabel,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select the type of partner relationship',
                          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingPartnerType)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          )
                        else
                        AppDropdownFormField<String>(
                          value: _selectedPartnerType,
                          label: 'Partner type',
                          items: _partnerTypes,
                          displayName: (type) => PartnerType.getDisplayName(type),
                          onChanged: (value) {
                            setState(() {
                              _selectedPartnerType = value;
                            });
                          },
                          isRequired: true,
                        ),

                        const SizedBox(height: 24),

                        // Name Section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What\'s your partner\'s name?',
                                style: AppTextStyles.itemLabel,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please provide the individual\'s full legal name to ensure they are easily identifiable',
                                style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _fullNameController,
                                label: 'Full name',
                                isRequired: true,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _middleNameController,
                                label: 'Middle name',
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _lastNameController,
                                label: 'Last name',
                                isRequired: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Method of Verification Section
                        Text(
                          'Method of verification',
                          style: AppTextStyles.itemLabel,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Identification methods are used by your Executor to identify people in your Will',
                          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        AppEmailField(
                          controller: _emailController,
                          label: 'Email address',
                          isRequired: true,
                          additionalValidator: (value) {
                            return _contactValidator.validateEmailUnique(
                              value,
                              excludeId: _isEditMode ? widget.existingData!.partner.id : null,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        AppPhoneInput(
                          controller: _phoneController,
                          countryCode: _selectedCountryCode,
                          onCountryCodeChanged: (code) {
                            setState(() {
                              _selectedCountryCode = code;
                            });
                          },
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            final digitsOnly = value.trim().replaceAll(RegExp(r'\D'), '');
                            if (digitsOnly.length < 7) {
                              return 'Phone number must be at least 7 digits';
                            }
                            if (digitsOnly.length > 15) {
                              return 'Phone number must not exceed 15 digits';
                            }
                            final fullPhone = AppPhoneInput.combinePhoneNumber(
                              _selectedCountryCode, value, withSpace: false,
                            );
                            return _contactValidator.validatePhoneUnique(
                              fullPhone,
                              excludeId: _isEditMode ? widget.existingData!.partner.id : null,
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // DOB and Address Section
                        Text(
                          'Additional details',
                          style: AppTextStyles.itemLabel,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide date of birth and address for identification',
                          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        // DOB field
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime(1990),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _dob =
                                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                _dobController.text = _dob!;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: AppTextField(
                              controller: _dobController,
                              label: 'Date of birth',
                              isRequired: true,
                              suffixIcon: Icons.calendar_today,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _addressController,
                          label: 'Address',
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        AppDropdownFormField<String>(
                          value: _selectedRelationship,
                          label: 'Relationship',
                          items: FormConstants.partnerRelations,
                          displayName: FormConstants.getRelationDisplayName,
                          onChanged: (value) {
                            setState(() {
                              _selectedRelationship = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom button
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
      ),
    );
  }
}
