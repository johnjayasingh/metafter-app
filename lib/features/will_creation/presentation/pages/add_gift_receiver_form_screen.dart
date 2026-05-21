import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/family_models.dart';
import '../../data/models/gift_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/radio_option_widgets.dart';
import '../widgets/select_caretaker_bottom_sheet.dart';
import '../widgets/select_recipient_bottom_sheet.dart';
import '../../../../core/theme/app_decorations.dart';

/// Screen to add / edit a single gift receiver.
/// Returns a [GiftReceiverDetails] via [Navigator.pop] on save.
class AddGiftReceiverFormScreen extends StatefulWidget {
  /// When non-null the form is in edit mode and pre-populated.
  final GiftReceiverDetails? existingReceiver;

  const AddGiftReceiverFormScreen({super.key, this.existingReceiver});

  @override
  State<AddGiftReceiverFormScreen> createState() =>
      _AddGiftReceiverFormScreenState();
}

class _AddGiftReceiverFormScreenState extends State<AddGiftReceiverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Guardian controllers
  final _guardianFullNameController = TextEditingController();
  final _guardianMiddleNameController = TextEditingController();
  final _guardianLastNameController = TextEditingController();
  final _guardianEmailController = TextEditingController();
  final _guardianPhoneController = TextEditingController();

  // Backup guardian controllers
  final _backupGuardianFullNameController = TextEditingController();
  final _backupGuardianMiddleNameController = TextEditingController();
  final _backupGuardianLastNameController = TextEditingController();
  final _backupGuardianEmailController = TextEditingController();
  final _backupGuardianPhoneController = TextEditingController();

  final SecureStorageService _storageService = SecureStorageService();

  String? _addGuardian;
  String? _addBackupGuardian;
  String? _guardianRelationship;
  String? _backupGuardianRelationship;
  String _guardianCountryCode = FormConstants.defaultCountryCode;
  String _backupGuardianCountryCode = FormConstants.defaultCountryCode;
  String? _selectedPreviousGuardian;
  String? _selectedPreviousBackupGuardian;
  List<CaretakerInfo> _loadedCaretakers = [];

  String? _isMinor;
  String? _selectedRelation;
  String _selectedCountryCode = FormConstants.defaultCountryCode;
  int? _selectedWillPersonId;

  // For "select previously added" bottom sheet
  List<RecipientInfo> _availableRecipients = [];
  bool _isRecipientsLoading = false;

  List<String> get _relations {
    if (_isMinor == 'yes') return FormConstants.minorRelations;
    if (_isMinor == 'no') return FormConstants.adultRelations;
    return FormConstants.allRelations;
  }

  bool get _isEditMode => widget.existingReceiver != null;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadGuardians();
    _loadAvailableRecipients();
  }

  void _initializeData() {
    final data = widget.existingReceiver;
    if (data != null) {
      _firstNameController.text = data.firstName;
      _middleNameController.text = data.middleName ?? '';
      _lastNameController.text = data.lastName;
      _dobController.text = _formatDobForDisplay(data.dob);
      _emailController.text = data.email ?? '';
      _addressController.text = data.address ?? '';
      _selectedRelation = data.relationship;
      _isMinor = data.isMinor ? 'yes' : 'no';
      _selectedWillPersonId = data.willPersonId;
      if (data.mobile != null && data.mobile!.isNotEmpty) {
        final (code, number) = AppPhoneInput.parsePhoneNumber(data.mobile!);
        _selectedCountryCode = code;
        _phoneController.text = number;
      }

      if (data.guardian != null) {
        final g = data.guardian!;
        _addGuardian = 'yes';
        _guardianFullNameController.text = g.firstName;
        _guardianMiddleNameController.text = g.middleName ?? '';
        _guardianLastNameController.text = g.lastName;
        _guardianEmailController.text = g.email ?? '';
        if (g.mobile != null && g.mobile!.isNotEmpty) {
          final (gCode, gNumber) = AppPhoneInput.parsePhoneNumber(g.mobile!);
          _guardianCountryCode = gCode;
          _guardianPhoneController.text = gNumber;
        }
        _guardianRelationship = g.relationship;
      }
      if (data.backupGuardian != null) {
        final bg = data.backupGuardian!;
        _addBackupGuardian = 'yes';
        _backupGuardianFullNameController.text = bg.firstName;
        _backupGuardianMiddleNameController.text = bg.middleName ?? '';
        _backupGuardianLastNameController.text = bg.lastName;
        _backupGuardianEmailController.text = bg.email ?? '';
        if (bg.mobile != null && bg.mobile!.isNotEmpty) {
          final (bgCode, bgNumber) = AppPhoneInput.parsePhoneNumber(bg.mobile!);
          _backupGuardianCountryCode = bgCode;
          _backupGuardianPhoneController.text = bgNumber;
        }
        _backupGuardianRelationship = bg.relationship;
      }
    }
  }

  Future<void> _loadGuardians() async {
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetDependentPersonsEvent(willId));
      context.read<WillBloc>().add(GetPartnersEvent(willId));
    }
  }

  Future<void> _loadAvailableRecipients() async {
    setState(() {
      _isRecipientsLoading = true;
      _availableRecipients = [];
    });
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetWillPersonsEvent(willId));
    }
  }

  void _addPartnersAsGuardianOptions(List<PartnerData> partners) {
    final existingNames = _loadedCaretakers
        .map((c) => '${c.firstName}${c.lastName}'.toLowerCase().replaceAll(' ', ''))
        .toSet();
    final newCaretakers = <CaretakerInfo>[];
    for (final partner in partners) {
      final p = partner.partner;
      final fullName = '${p.firstName}${p.lastName}'.toLowerCase().replaceAll(' ', '');
      if (!existingNames.contains(fullName)) {
        existingNames.add(fullName);
        newCaretakers.add(CaretakerInfo(
          id: partner.id,
          firstName: p.firstName,
          middleName: p.middleName,
          lastName: p.lastName,
          email: p.email,
          mobile: p.mobile,
        ));
      }
    }
    if (newCaretakers.isNotEmpty) {
      setState(() {
        _loadedCaretakers = [..._loadedCaretakers, ...newCaretakers];
      });
    }
  }

  void _extractGuardiansFromDependents(List<DependentPersonData> dependents) {
    final caretakers = <CaretakerInfo>[];
    final seenNames = <String>{};
    for (final dependent in dependents) {
      if (dependent.guardian != null && dependent.guardianId != null) {
        final g = dependent.guardian!;
        final fullName = '${g.firstName}${g.middleName ?? ''}${g.lastName}'
            .toLowerCase()
            .replaceAll(' ', '');
        if (!seenNames.contains(fullName)) {
          seenNames.add(fullName);
          caretakers.add(
            CaretakerInfo.fromPersonDetails(
              dependent.guardianId!,
              dependent.guardian!,
            ),
          );
        }
      }
    }
    setState(() => _loadedCaretakers = caretakers);
  }

  void _addWillPersonsAsGuardianOptions(List<WillPersonData> persons) {
    final existingNames = _loadedCaretakers
        .map((c) => '${c.firstName}${c.lastName}'.toLowerCase().replaceAll(' ', ''))
        .toSet();
    final newCaretakers = <CaretakerInfo>[];
    for (final person in persons) {
      // Only include adults
      if (person.isMinor == true) continue;
      final firstName = person.firstName ?? '';
      final lastName = person.lastName ?? '';
      if (firstName.isEmpty && lastName.isEmpty) continue;
      final fullName = '$firstName$lastName'.toLowerCase().replaceAll(' ', '');
      if (!existingNames.contains(fullName)) {
        existingNames.add(fullName);
        newCaretakers.add(CaretakerInfo(
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
    if (newCaretakers.isNotEmpty) {
      setState(() {
        _loadedCaretakers = [..._loadedCaretakers, ...newCaretakers];
      });
    }
  }

  void _prefillFromRecipient(RecipientInfo data) {
    setState(() {
      _firstNameController.text = data.firstName;
      _middleNameController.text = data.middleName ?? '';
      _lastNameController.text = data.lastName;
      _emailController.text = data.email ?? '';
      if (data.dob != null && data.dob!.isNotEmpty) {
        _dobController.text = _formatDobForDisplay(data.dob);
      }
      if (data.address != null && data.address!.isNotEmpty) {
        _addressController.text = data.address!;
      }
      if (data.mobile != null && data.mobile!.isNotEmpty) {
        final (code, number) = AppPhoneInput.parsePhoneNumber(data.mobile!);
        _selectedCountryCode = code;
        _phoneController.text = number;
      }
      _selectedRelation = data.relation;
      _selectedWillPersonId = data.willPersonId;
      if (data.relation == 'SON' ||
          data.relation == 'DAUGHTER' ||
          data.relation == 'STEP_SON' ||
          data.relation == 'STEP_DAUGHTER' ||
          data.displayType == 'Minor') {
        _isMinor = 'yes';
      } else if (data.displayType == 'Person') {
        _isMinor = 'no';
      }
    });
  }

  String _formatDobForDisplay(String? dob) {
    if (dob == null || dob.isEmpty) return '';
    final parts = dob.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return dob;
  }

  void _showSelectRecipientBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocBuilder<WillBloc, WillState>(
          builder: (ctx, state) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderGray, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppTextButton(
                          text: 'Cancel',
                          color: AppColors.textSecondary,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        Text(
                          'Select Recipient',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 60),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isRecipientsLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _availableRecipients.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No previously added people found.\nAdd dependents, beneficiaries or former partners first.',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _availableRecipients.length,
                                itemBuilder: (ctx, index) {
                                  final r = _availableRecipients[index];
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _prefillFromRecipient(r);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundWhite,
                                        border:
                                            Border.all(color: AppColors.borderGray),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                AppColors.backgroundLightGreen,
                                            child: Text(
                                              '${r.firstName.isNotEmpty ? r.firstName[0].toUpperCase() : '?'}'
                                              '${r.lastName.isNotEmpty ? r.lastName[0].toUpperCase() : ''}',
                                              style: AppTextStyles.avatarInitialsLarge
                                                  .copyWith(
                                                      color: AppColors.primaryGreen),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${r.firstName} ${r.lastName}'
                                                      .trim(),
                                                  style: AppTextStyles.itemLabel,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  r.relation != null
                                                      ? FormConstants
                                                          .getRelationDisplayName(
                                                              r.relation!)
                                                      : (r.displayType ?? 'Person'),
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                          color: AppColors
                                                              .textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios,
                                              size: 16,
                                              color: AppColors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveRecipient() {
    if (!_formKey.currentState!.validate()) return;

    if (_firstNameController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please enter first name');
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please enter last name');
      return;
    }
    if (_isMinor == null) {
      SnackBarUtils.showTopSnackBar(
          context, 'Please specify if this person is a minor');
      return;
    }
    if (_dobController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please select date of birth');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please enter address');
      return;
    }
    if (_isMinor == 'no') {
      if (_emailController.text.trim().isEmpty) {
        SnackBarUtils.showTopSnackBar(context, 'Please enter email address');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        SnackBarUtils.showTopSnackBar(context, 'Please enter phone number');
        return;
      }
    }
    if (_emailController.text.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        SnackBarUtils.showTopSnackBar(
            context, 'Please enter a valid email address');
        return;
      }
    }
    if (_selectedRelation == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please select a relation');
      return;
    }

    // Build guardian
    GuardianDetails? guardian;
    if (_isMinor == 'yes' &&
        _addGuardian == 'yes' &&
        _guardianFullNameController.text.trim().isNotEmpty) {
      guardian = GuardianDetails(
        firstName: _guardianFullNameController.text.trim(),
        middleName: _guardianMiddleNameController.text.trim().isNotEmpty
            ? _guardianMiddleNameController.text.trim()
            : null,
        lastName: _guardianLastNameController.text.trim(),
        email: _guardianEmailController.text.trim(),
        mobile: AppPhoneInput.combinePhoneNumber(
          _guardianCountryCode,
          _guardianPhoneController.text.trim(),
          withSpace: false,
        ),
        relationship: _guardianRelationship,
      );
    }

    // Build backup guardian
    GuardianDetails? backupGuardian;
    if (_isMinor == 'yes' &&
        _addBackupGuardian == 'yes' &&
        _backupGuardianFullNameController.text.trim().isNotEmpty) {
      backupGuardian = GuardianDetails(
        firstName: _backupGuardianFullNameController.text.trim(),
        middleName: _backupGuardianMiddleNameController.text.trim().isNotEmpty
            ? _backupGuardianMiddleNameController.text.trim()
            : null,
        lastName: _backupGuardianLastNameController.text.trim(),
        email: _backupGuardianEmailController.text.trim(),
        mobile: AppPhoneInput.combinePhoneNumber(
          _backupGuardianCountryCode,
          _backupGuardianPhoneController.text.trim(),
          withSpace: false,
        ),
        relationship: _backupGuardianRelationship,
      );
    }

    final phoneTrimmed = _phoneController.text.trim();
    final emailTrimmed = _emailController.text.trim();

    final receiver = GiftReceiverDetails(
      id: widget.existingReceiver?.id,
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isNotEmpty
          ? _middleNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim(),
      mobile: phoneTrimmed.isNotEmpty
          ? AppPhoneInput.combinePhoneNumber(
              _selectedCountryCode,
              phoneTrimmed,
              withSpace: false,
            )
          : null,
      email: emailTrimmed.isNotEmpty ? emailTrimmed : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      relationship: _selectedRelation!,
      isMinor: _isMinor == 'yes',
      dob: _dobController.text.trim().isNotEmpty
          ? _dobController.text.trim()
          : null,
      willPersonId: _selectedWillPersonId,
      guardian: guardian,
      backupGuardian: backupGuardian,
    );

    Navigator.pop(context, receiver);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _guardianFullNameController.dispose();
    _guardianMiddleNameController.dispose();
    _guardianLastNameController.dispose();
    _guardianEmailController.dispose();
    _guardianPhoneController.dispose();
    _backupGuardianFullNameController.dispose();
    _backupGuardianMiddleNameController.dispose();
    _backupGuardianLastNameController.dispose();
    _backupGuardianEmailController.dispose();
    _backupGuardianPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listener: (context, state) {
        if (state is DependentPersonsLoaded) {
          _extractGuardiansFromDependents(state.dependents);
        } else if (state is WillPersonsLoaded) {
          setState(() {
            _availableRecipients = state.persons.map((person) {
              // Sanitize mobile: treat "undefined" or just a country code as empty
              String? sanitizedMobile = person.mobile;
              if (sanitizedMobile != null) {
                final trimmed = sanitizedMobile.replaceAll(RegExp(r'[\s\-]+'), '');
                if (trimmed.isEmpty ||
                    trimmed.contains('undefined') ||
                    RegExp(r'^\+\d{1,3}$').hasMatch(trimmed)) {
                  sanitizedMobile = '';
                }
              }
              return RecipientInfo(
                id: 'person_${person.willPersonId}',
                firstName: person.firstName ?? '',
                middleName: person.middleName,
                lastName: person.lastName ?? '',
                email: person.email ?? '',
                mobile: sanitizedMobile ?? '',
                relation: person.relationship,
                displayType: person.isMinor == true ? 'Minor' : 'Person',
                willPersonId: person.willPersonId,
                dob: person.dob,
                address: person.address,
              );
            }).toList();
            _isRecipientsLoading = false;
          });
          _addWillPersonsAsGuardianOptions(state.persons);
        } else if (state is PartnersLoaded) {
          _addPartnersAsGuardianOptions(state.partners);
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
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back,
                      color: AppColors.textBrand, size: 20),
                ),
              ),
            ),
          ),
          title: Text(
            _isEditMode ? 'Edit recipient' : 'Add recipient',
            style: AppTextStyles.questionTitle,
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
                      Text(
                        "Enter the recipient's full legal name as it appears on their official identification.",
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Select previously added
                      if (!_isEditMode)
                        InkWell(
                          onTap: _showSelectRecipientBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundWhite,
                              border: Border.all(color: AppColors.borderGray),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select previously added',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.textPrimary),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),

                      if (!_isEditMode) const SizedBox(height: 24),

                      // Minor / Adult
                      Row(
                        children: [
                          Expanded(
                            child: RadioListOption(
                              isSelected: _isMinor == 'yes',
                              title: 'This recipient is a minor',
                              subtitle:
                                  'When adding a minor, a guardian has to be added under this as well',
                              onTap: () {
                                setState(() {
                                  _isMinor = 'yes';
                                  _selectedRelation = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListOption(
                              isSelected: _isMinor == 'no',
                              title: 'This recipient is an adult',
                              onTap: () {
                                setState(() {
                                  _isMinor = 'no';
                                  _selectedRelation = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Form fields
                      AppTextField(
                        controller: _firstNameController,
                        label: 'First name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _middleNameController,
                        label: 'Middle name',
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _lastNameController,
                        label: 'Last name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _dobController,
                        label: 'DOB',
                        isRequired: true,
                        onDateSelected: (date) {
                          setState(() {
                            _dobController.text =
                                AppDatePickerField.formatDate(date);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailController,
                        label: _isMinor == 'no'
                            ? 'Email address'
                            : 'Email address (optional)',
                        keyboardType: TextInputType.emailAddress,
                        isRequired: _isMinor == 'no',
                      ),
                      const SizedBox(height: 16),
                      AppPhoneInput(
                        controller: _phoneController,
                        countryCode: _selectedCountryCode,
                        onCountryCodeChanged: (code) {
                          setState(() => _selectedCountryCode = code);
                        },
                        isRequired: _isMinor == 'no',
                        label: _isMinor == 'no'
                            ? 'Phone number'
                            : 'Phone number (optional)',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _addressController,
                        label: 'Address',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppDropdownFormField<String>(
                        value: _selectedRelation,
                        label: 'Relation',
                        items: _relations,
                        displayName: (value) =>
                            FormConstants.getRelationDisplayName(value),
                        onChanged: (value) {
                          setState(() => _selectedRelation = value);
                        },
                        isRequired: true,
                      ),

                      // Guardian section (minors)
                      if (_isMinor == 'yes') ...[
                        const SizedBox(height: 24),
                        Divider(color: AppColors.borderLight),
                        const SizedBox(height: 16),
                        Text('Add a Guardian?',
                            style: AppTextStyles.questionTitle),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: RadioButtonOption(
                                isSelected: _addGuardian == 'yes',
                                label: 'Yes',
                                onTap: () =>
                                    setState(() => _addGuardian = 'yes'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RadioButtonOption(
                                isSelected: _addGuardian == 'no',
                                label: 'No',
                                onTap: () =>
                                    setState(() => _addGuardian = 'no'),
                              ),
                            ),
                          ],
                        ),
                        if (_addGuardian == 'yes') ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              final result =
                                  await showModalBottomSheet<CaretakerInfo>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    SelectCaretakerBottomSheet(
                                  caretakers: _loadedCaretakers,
                                  isGuardian: true,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _selectedPreviousGuardian = result.fullName;
                                  _guardianFullNameController.text =
                                      result.firstName;
                                  _guardianMiddleNameController.text =
                                      result.middleName ?? '';
                                  _guardianLastNameController.text =
                                      result.lastName;
                                  _guardianEmailController.text =
                                      result.email ?? '';
                                  final (gCode, gNumber) =
                                      AppPhoneInput.parsePhoneNumber(
                                          result.mobile);
                                  _guardianCountryCode = gCode;
                                  _guardianPhoneController.text = gNumber;
                                });
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: AppDecorations.card,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedPreviousGuardian ??
                                          'Select previously added',
                                      style: _selectedPreviousGuardian != null
                                          ? AppTextStyles.inputText
                                          : AppTextStyles.inputHint,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _guardianFullNameController,
                            label: 'Full name',
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _guardianMiddleNameController,
                            label: 'Middle name',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _guardianLastNameController,
                            label: 'Last name',
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _guardianEmailController,
                            label: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                    r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppPhoneInput(
                            controller: _guardianPhoneController,
                            countryCode: _guardianCountryCode,
                            onCountryCodeChanged: (code) {
                              setState(() => _guardianCountryCode = code);
                            },
                            isRequired: true,
                            label: 'Phone number',
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

                        // Backup guardian
                        const SizedBox(height: 24),
                        Text('Add a Backup Guardian?',
                            style: AppTextStyles.questionTitle),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: RadioButtonOption(
                                isSelected: _addBackupGuardian == 'yes',
                                label: 'Yes',
                                onTap: () => setState(
                                    () => _addBackupGuardian = 'yes'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RadioButtonOption(
                                isSelected: _addBackupGuardian == 'no',
                                label: 'No',
                                onTap: () => setState(
                                    () => _addBackupGuardian = 'no'),
                              ),
                            ),
                          ],
                        ),
                        if (_addBackupGuardian == 'yes') ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              final result =
                                  await showModalBottomSheet<CaretakerInfo>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    SelectCaretakerBottomSheet(
                                  caretakers: _loadedCaretakers,
                                  isGuardian: true,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _selectedPreviousBackupGuardian =
                                      result.fullName;
                                  _backupGuardianFullNameController.text =
                                      result.firstName;
                                  _backupGuardianMiddleNameController.text =
                                      result.middleName ?? '';
                                  _backupGuardianLastNameController.text =
                                      result.lastName;
                                  _backupGuardianEmailController.text =
                                      result.email ?? '';
                                  final (bgCode, bgNumber) =
                                      AppPhoneInput.parsePhoneNumber(
                                          result.mobile);
                                  _backupGuardianCountryCode = bgCode;
                                  _backupGuardianPhoneController.text =
                                      bgNumber;
                                });
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: AppDecorations.card,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedPreviousBackupGuardian ??
                                          'Select previously added',
                                      style:
                                          _selectedPreviousBackupGuardian !=
                                                  null
                                              ? AppTextStyles.inputText
                                              : AppTextStyles.inputHint,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _backupGuardianFullNameController,
                            label: 'Full name',
                            isRequired: true,
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
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _backupGuardianEmailController,
                            label: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                    r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppPhoneInput(
                            controller: _backupGuardianPhoneController,
                            countryCode: _backupGuardianCountryCode,
                            onCountryCodeChanged: (code) {
                              setState(
                                  () => _backupGuardianCountryCode = code);
                            },
                            isRequired: true,
                            label: 'Phone number',
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

            // Bottom save button
            AppBottomActionBar(
              child: AppPrimaryButton(
                text: _isEditMode ? 'Update recipient' : 'Save recipient',
                onPressed: _saveRecipient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
