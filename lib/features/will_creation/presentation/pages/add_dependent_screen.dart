import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/debug_config.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/select_caretaker_bottom_sheet.dart';
import '../widgets/radio_option_widgets.dart';

class AddDependentScreen extends StatefulWidget {
  final DependentPersonData? existingDependent; // For editing dependent person
  final PetData? existingPet; // For editing pet

  const AddDependentScreen({
    super.key,
    this.existingDependent,
    this.existingPet,
  });

  @override
  State<AddDependentScreen> createState() => _AddDependentScreenState();
}

class _AddDependentScreenState extends State<AddDependentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _petNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  String? _dependentDob;

  // Pet-specific fields
  final _breedController = TextEditingController();
  final _registrationController = TextEditingController();
  final _vetNameController = TextEditingController();
  final _vetContactController = TextEditingController();

  // Caretaker/Guardian fields
  final _caretakerFullNameController = TextEditingController();
  final _caretakerMiddleNameController = TextEditingController();
  final _caretakerLastNameController = TextEditingController();
  final _caretakerEmailController = TextEditingController();
  final _caretakerPhoneController = TextEditingController();
  final _caretakerAddressController = TextEditingController();
  final _caretakerInstructionController = TextEditingController();
  String? _caretakerDob;

  // Backup Guardian fields
  final _backupGuardianFullNameController = TextEditingController();
  final _backupGuardianMiddleNameController = TextEditingController();
  final _backupGuardianLastNameController = TextEditingController();
  final _backupGuardianEmailController = TextEditingController();
  final _backupGuardianPhoneController = TextEditingController();
  
  // Guardian DOB fields
  final _guardianDobController = TextEditingController();
  String? _guardianDob;
  final _backupGuardianDobController = TextEditingController();
  String? _backupGuardianDob;

  DependentType? _dependentType;
  String? _selectedRelation;
  String? _selectedAnimal;
  String _selectedCountryCode = FormConstants.defaultCountryCode;
  String _caretakerCountryCode = FormConstants.defaultCountryCode;
  String _backupGuardianCountryCode = FormConstants.defaultCountryCode;
  String? _guardianRelationship;
  String? _backupGuardianRelationship;
  String? _caretakerRelationship;
  String? _addCaretaker; // 'yes' or 'no' or null
  String? _addBackupGuardian; // 'yes' or 'no' or null
  String? _addPetGuardian; // 'yes' or 'no' or null for pet guardian
  String? _selectedPreviousCaretaker;
  String? _selectedPreviousBackupGuardian;
  CaretakerInfo? _selectedCaretakerInfo; // ignore: unused_field
  
  // Pet allowance fields
  bool _addPetAllowance = false;
  final _allowanceAmountController = TextEditingController();

  final SecureStorageService _storageService = SecureStorageService();
  bool _isSubmitting = false;
  List<CaretakerInfo> _loadedCaretakers = [];

  bool get _isEditMode =>
      widget.existingDependent != null || widget.existingPet != null;

  // Get appropriate relations based on dependent type
  List<String> get _relations {
    if (_dependentType == DependentType.minor) {
      return FormConstants.minorRelations;
    } else if (_dependentType == DependentType.major) {
      return FormConstants.adultRelations;
    }
    return FormConstants.allRelations;
  }

  @override
  void initState() {
    super.initState();
    _initializeForEditMode();
    _loadGuardians();
  }

  void _initializeForEditMode() {
    if (widget.existingDependent != null) {
      // Edit mode for dependent person
      final dep = widget.existingDependent!;
      // Set dependent type based on is_minor field from API
      _dependentType = dep.dependent.isMinor ? DependentType.minor : DependentType.major;
      _fullNameController.text = dep.dependent.firstName;
      _middleNameController.text = dep.dependent.middleName ?? '';
      _lastNameController.text = dep.dependent.lastName;

      // Set relation only if it exists in the appropriate list
      final relation = dep.dependent.relationship;
      final validRelations = _dependentType == DependentType.minor
          ? FormConstants.minorRelations
          : FormConstants.adultRelations;
      _selectedRelation = validRelations.contains(relation) ? relation : null;

      _emailController.text = dep.dependent.email ?? '';
      if (dep.dependent.mobile != null && dep.dependent.mobile!.isNotEmpty) {
        final (code, number) = AppPhoneInput.parsePhoneNumber(
          dep.dependent.mobile!,
        );
        _selectedCountryCode = code;
        _phoneController.text = number;
      }
      // DOB and Address
      _dependentDob = dep.dependent.dob;
      if (_dependentDob != null) {
        _dobController.text = _dependentDob!;
      }
      _addressController.text = dep.dependent.address ?? '';
      // Guardian data
      if (dep.guardian != null) {
        _addCaretaker = 'yes';
        _caretakerFullNameController.text = dep.guardian!.firstName;
        _caretakerMiddleNameController.text = dep.guardian!.middleName ?? '';
        _caretakerLastNameController.text = dep.guardian!.lastName;
        _caretakerEmailController.text = dep.guardian!.email ?? '';
        _guardianDob = dep.guardian!.dob;
        if (_guardianDob != null) {
          _guardianDobController.text = _guardianDob!;
        }
        if (dep.guardian!.mobile != null && dep.guardian!.mobile!.isNotEmpty) {
          final (guardianCode, guardianNumber) = AppPhoneInput.parsePhoneNumber(
            dep.guardian!.mobile!,
          );
          _caretakerCountryCode = guardianCode;
          _caretakerPhoneController.text = guardianNumber;
        }
        _guardianRelationship = dep.guardian!.relationship;
      }
      
      // Backup guardian data
      if (dep.backupGuardian != null) {
        _addBackupGuardian = 'yes';
        _backupGuardianFullNameController.text = dep.backupGuardian!.firstName;
        _backupGuardianMiddleNameController.text = dep.backupGuardian!.middleName ?? '';
        _backupGuardianLastNameController.text = dep.backupGuardian!.lastName;
        _backupGuardianEmailController.text = dep.backupGuardian!.email ?? '';
        _backupGuardianDob = dep.backupGuardian!.dob;
        if (_backupGuardianDob != null) {
          _backupGuardianDobController.text = _backupGuardianDob!;
        }
        if (dep.backupGuardian!.mobile != null && dep.backupGuardian!.mobile!.isNotEmpty) {
          final (bgCode, bgNumber) = AppPhoneInput.parsePhoneNumber(
            dep.backupGuardian!.mobile!,
          );
          _backupGuardianCountryCode = bgCode;
          _backupGuardianPhoneController.text = bgNumber;
        }
        _backupGuardianRelationship = dep.backupGuardian!.relationship;
      }
    } else if (widget.existingPet != null) {
      // Edit mode for pet
      final pet = widget.existingPet!;
      _dependentType = DependentType.pet;
      _petNameController.text = pet.animalName;
      _selectedAnimal = pet.animalCategory;

      // Populate pet-specific fields if available
      _breedController.text = pet.breed ?? '';
      _registrationController.text = pet.registration ?? '';
      _vetNameController.text = pet.vetName ?? '';
      _vetContactController.text = pet.vetContact ?? '';
      
      // Populate allowance fields
      _addPetAllowance = pet.addAllowance ?? false;
      if (pet.allowanceAmount != null) {
        _allowanceAmountController.text = pet.allowanceAmount!.toStringAsFixed(0);
      }

      // Populate caretaker fields if caretaker exists
      if (pet.caretaker != null) {
        _addPetGuardian = 'yes';
        _caretakerFullNameController.text = pet.caretaker!.firstName;
        _caretakerMiddleNameController.text = pet.caretaker!.middleName ?? '';
        _caretakerLastNameController.text = pet.caretaker!.lastName;
        _caretakerEmailController.text = pet.caretaker!.email ?? '';
        _caretakerInstructionController.text = pet.caretaker!.instruction;
        _caretakerDob = pet.caretaker!.dob;
        _caretakerAddressController.text = pet.caretaker!.address ?? '';
        final (petCaretakerCode, petCaretakerNumber) =
            AppPhoneInput.parsePhoneNumber(pet.caretaker!.mobile ?? '');
        _caretakerCountryCode = petCaretakerCode;
        _caretakerPhoneController.text = petCaretakerNumber;
        _caretakerRelationship = pet.caretaker!.relationship;
      } else {
        // No caretaker exists, pre-select "No"
        _addPetGuardian = 'no';
      }
    } else if (DebugConfig.usePrepopulatedData) {
      // Check if we should prepopulate for minor or pet based on debug config
      final debugDependentType =
          DebugConfig.testDependent['dependentType'] ?? 'minor';
      _dependentType = DependentType.fromString(debugDependentType);

      if (debugDependentType == 'pet') {
        // Prepopulate with pet test data
        _petNameController.text = DebugConfig.testPet['fullName'] ?? '';
        _selectedAnimal = DebugConfig.testPet['petType'];
        _addPetGuardian = 'yes';
        _caretakerFullNameController.text =
            DebugConfig.testPet['caretakerFullName'] ?? '';
        _caretakerMiddleNameController.text =
            DebugConfig.testPet['caretakerMiddleName'] ?? '';
        _caretakerLastNameController.text =
            DebugConfig.testPet['caretakerLastName'] ?? '';
        _caretakerEmailController.text =
            DebugConfig.testPet['caretakerEmail'] ?? '';
        final caretakerPhone = DebugConfig.testPet['caretakerPhone'] as String?;
        final (debugPetCaretakerCode, debugPetCaretakerNumber) =
            AppPhoneInput.parsePhoneNumber(caretakerPhone);
        _caretakerCountryCode = debugPetCaretakerCode;
        _caretakerPhoneController.text = debugPetCaretakerNumber;
        _caretakerInstructionController.text =
            'Please take good care of my beloved pet.';
      } else {
        // Prepopulate with minor test data
        _fullNameController.text = DebugConfig.testDependent['fullName'] ?? '';
        _middleNameController.text =
            DebugConfig.testDependent['middleName'] ?? '';
        _lastNameController.text = DebugConfig.testDependent['lastName'] ?? '';
        _selectedRelation = DebugConfig.testDependent['relationship'];
        _emailController.text = DebugConfig.testDependent['email'] ?? '';
        final phone = DebugConfig.testDependent['phone'] as String?;
        final (debugCode, debugNumber) = AppPhoneInput.parsePhoneNumber(phone);
        _selectedCountryCode = debugCode;
        _phoneController.text = debugNumber;
        // Caretaker data
        _addCaretaker = 'yes';
        _caretakerFullNameController.text =
            DebugConfig.testDependent['guardianFullName'] ?? '';
        _caretakerMiddleNameController.text =
            DebugConfig.testDependent['guardianMiddleName'] ?? '';
        _caretakerLastNameController.text =
            DebugConfig.testDependent['guardianLastName'] ?? '';
        _caretakerEmailController.text =
            DebugConfig.testDependent['guardianEmail'] ?? '';
        final guardianPhone =
            DebugConfig.testDependent['guardianPhone'] as String?;
        final (debugGuardianCode, debugGuardianNumber) =
            AppPhoneInput.parsePhoneNumber(guardianPhone);
        _caretakerCountryCode = debugGuardianCode;
        _caretakerPhoneController.text = debugGuardianNumber;
      }
    }
  }

  Future<void> _loadGuardians() async {
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      // Load from dependent/person API which has guardians
      context.read<WillBloc>().add(GetDependentPersonsEvent(willId));
      // Also load partners and all will persons so any adult can be a guardian
      context.read<WillBloc>().add(GetPartnersEvent(willId));
      context.read<WillBloc>().add(GetWillPersonsEvent(willId));
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _petNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _breedController.dispose();
    _registrationController.dispose();
    _vetNameController.dispose();
    _vetContactController.dispose();
    _caretakerFullNameController.dispose();
    _caretakerMiddleNameController.dispose();
    _caretakerLastNameController.dispose();
    _caretakerEmailController.dispose();
    _caretakerPhoneController.dispose();
    _caretakerAddressController.dispose();
    _caretakerInstructionController.dispose();
    _backupGuardianFullNameController.dispose();
    _backupGuardianMiddleNameController.dispose();
    _backupGuardianLastNameController.dispose();
    _backupGuardianEmailController.dispose();
    _backupGuardianPhoneController.dispose();
    _allowanceAmountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields based on dependent type
    if (_dependentType == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please select a dependent type');
      return;
    }
    if (_dependentType == DependentType.pet && _selectedAnimal == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please select an animal type');
      return;
    }
    if ((_dependentType == DependentType.minor || _dependentType == DependentType.major) &&
        _selectedRelation == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please select a relation');
      return;
    }
    if ((_dependentType == DependentType.minor || _dependentType == DependentType.major) &&
        (_dependentDob == null || _dependentDob!.isEmpty)) {
      SnackBarUtils.showTopSnackBar(context, 'Please select date of birth');
      return;
    }
    if ((_dependentType == DependentType.minor || _dependentType == DependentType.major) &&
        _addressController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Please enter address');
      return;
    }
    // Require guardian selection for minors
    if (_dependentType == DependentType.minor && _addCaretaker == null) {
      SnackBarUtils.showTopSnackBar(
        context,
        'Please select whether to add a Guardian (Minor)',
      );
      return;
    }

    final willId = await _storageService.getWillId();
    if (willId == null) {
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, 'Will ID not found');
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    if (_dependentType == DependentType.pet) {
      // Add or update pet
      CareTaker? caretaker;

      // Only create caretaker if user selected "Yes" for adding pet guardian
      if (_addPetGuardian == 'yes' &&
          _caretakerFullNameController.text.isNotEmpty) {
        final petCaretakerPhone = _caretakerPhoneController.text.trim();
        final petCaretakerEmail = _caretakerEmailController.text.trim();
        caretaker = CareTaker(
          id: widget.existingPet?.caretaker?.id,
          firstName: _caretakerFullNameController.text,
          middleName: _caretakerMiddleNameController.text.isNotEmpty
              ? _caretakerMiddleNameController.text
              : null,
          lastName: _caretakerLastNameController.text,
          email: petCaretakerEmail.isNotEmpty ? petCaretakerEmail : null,
          mobile: petCaretakerPhone.isNotEmpty
              ? AppPhoneInput.combinePhoneNumber(
                  _caretakerCountryCode,
                  petCaretakerPhone,
                  withSpace: false,
                )
              : null,
          instruction: _caretakerInstructionController.text.isNotEmpty
              ? _caretakerInstructionController.text
              : 'Please take care of my pet.',
          relationship: _caretakerRelationship,
          dob: _caretakerDob,
          address: _caretakerAddressController.text.isNotEmpty
              ? _caretakerAddressController.text
              : null,
        );
      }

      // Check if we need to remove an existing caretaker
      // This happens when editing a pet that had a caretaker but user selected "No"
      final shouldRemoveCaretaker = _isEditMode && 
          widget.existingPet?.caretaker != null && 
          _addPetGuardian == 'no';

      final request = PetRequest(
        willPetId: widget.existingPet != null
            ? int.tryParse(widget.existingPet!.id)
            : null,
        willId: willId,
        animalName: _petNameController.text,
        animalCategory: _selectedAnimal ?? 'DOG',
        caretaker: caretaker,
        removeCaretaker: shouldRemoveCaretaker,
        breed: _breedController.text.isNotEmpty ? _breedController.text : null,
        registration: _registrationController.text.isNotEmpty
            ? _registrationController.text
            : null,
        vetName: _vetNameController.text.isNotEmpty
            ? _vetNameController.text
            : null,
        vetContact: _vetContactController.text.isNotEmpty
            ? _vetContactController.text
            : null,
        addAllowance: _addPetAllowance,
        allowanceAmount: _addPetAllowance && _allowanceAmountController.text.isNotEmpty
            ? double.tryParse(_allowanceAmountController.text)
            : null,
      );

      if (mounted) {
        context.read<WillBloc>().add(AddPetEvent(request));
      }
    } else {
      // Add or update dependent person (minor or major)
      final phoneTrimmed = _phoneController.text.trim();
      final emailTrimmed = _emailController.text.trim();

      final dependent = DependentDetails(
        id: widget.existingDependent != null
            ? int.tryParse(widget.existingDependent!.id)
            : null,
        firstName: _fullNameController.text,
        middleName: _middleNameController.text.isNotEmpty
            ? _middleNameController.text
            : null,
        lastName: _lastNameController.text,
        mobile: phoneTrimmed.isNotEmpty
            ? AppPhoneInput.combinePhoneNumber(
                _selectedCountryCode,
                phoneTrimmed,
                withSpace: false,
              )
            : null,
        email: emailTrimmed.isNotEmpty ? emailTrimmed : null,
        relationship: _selectedRelation ?? 'OTHER',
        isMinor: _dependentType == DependentType.minor,
        dob: _dependentDob,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
      );

      PersonDetails? guardian;
      if (_addCaretaker == 'yes' &&
          _caretakerFullNameController.text.isNotEmpty) {
        final guardianPhone = _caretakerPhoneController.text.trim();
        final guardianEmail = _caretakerEmailController.text.trim();
        guardian = PersonDetails(
          id: widget.existingDependent?.guardianId != null
              ? int.tryParse(widget.existingDependent!.guardianId!)
              : null,
          firstName: _caretakerFullNameController.text,
          middleName: _caretakerMiddleNameController.text.isNotEmpty
              ? _caretakerMiddleNameController.text
              : null,
          lastName: _caretakerLastNameController.text,
          email: guardianEmail.isNotEmpty ? guardianEmail : null,
          mobile: guardianPhone.isNotEmpty
              ? AppPhoneInput.combinePhoneNumber(
                  _caretakerCountryCode,
                  guardianPhone,
                  withSpace: false,
                )
              : null,
          relationship: _guardianRelationship,
          dob: _guardianDob,
        );
      }

      PersonDetails? backupGuardian;
      if (_addBackupGuardian == 'yes' &&
          _backupGuardianFullNameController.text.isNotEmpty) {
        final bgPhone = _backupGuardianPhoneController.text.trim();
        final bgEmail = _backupGuardianEmailController.text.trim();
        backupGuardian = PersonDetails(
          id: widget.existingDependent?.backupGuardianId != null
              ? int.tryParse(widget.existingDependent!.backupGuardianId!)
              : null,
          firstName: _backupGuardianFullNameController.text,
          middleName: _backupGuardianMiddleNameController.text.isNotEmpty
              ? _backupGuardianMiddleNameController.text
              : null,
          lastName: _backupGuardianLastNameController.text,
          email: bgEmail.isNotEmpty ? bgEmail : null,
          mobile: bgPhone.isNotEmpty
              ? AppPhoneInput.combinePhoneNumber(
                  _backupGuardianCountryCode,
                  bgPhone,
                  withSpace: false,
                )
              : null,
          relationship: _backupGuardianRelationship,
          dob: _backupGuardianDob,
        );
      }

      final request = DependentPersonRequest(
        willId: willId,
        dependent: dependent,
        guardian: guardian,
        backupGuardian: backupGuardian,
      );

      if (mounted) {
        context.read<WillBloc>().add(AddDependentPersonEvent(request));
      }
    }
  }

  void _extractGuardiansFromDependents(List<DependentPersonData> dependents) {
    final existingNames = _loadedCaretakers
        .map((c) => '${c.firstName}${c.middleName ?? ''}${c.lastName}'
            .toLowerCase()
            .replaceAll(' ', ''))
        .toSet();

    final newCaretakers = <CaretakerInfo>[];

    for (final dependent in dependents) {
      if (dependent.guardian != null && dependent.guardianId != null) {
        final g = dependent.guardian!;
        final fullName = '${g.firstName}${g.middleName ?? ''}${g.lastName}'
            .toLowerCase()
            .replaceAll(' ', '');
        if (!existingNames.contains(fullName)) {
          existingNames.add(fullName);
          newCaretakers.add(
            CaretakerInfo.fromPersonDetails(
              dependent.guardianId!,
              dependent.guardian!,
            ),
          );
        }
      }
    }

    if (newCaretakers.isNotEmpty) {
      setState(() {
        _loadedCaretakers = [..._loadedCaretakers, ...newCaretakers];
      });
    }
  }

  void _addPartnersAsGuardianOptions(List<PartnerData> partners) {
    final existingNames = _loadedCaretakers.map((c) =>
        '${c.firstName}${c.lastName}'.toLowerCase().replaceAll(' ', '')).toSet();
    
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
          dob: p.dob,
          relationship: p.relationship,
        ));
      }
    }

    if (newCaretakers.isNotEmpty) {
      setState(() {
        _loadedCaretakers = [..._loadedCaretakers, ...newCaretakers];
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listenWhen: (previous, current) {
        // Listen for guardians loading or submission results
        return current is DependentPersonsLoaded ||
            current is PartnersLoaded ||
            current is WillPersonsLoaded ||
            current is PetsLoaded ||
            (_isSubmitting && current is WillError);
      },
      listener: (context, state) {
        if (state is DependentPersonsLoaded) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            SnackBarUtils.showSuccess(
              context,
              _isEditMode ? 'Updated successfully' : 'Added successfully',
            );
            context.pop();
          } else {
            // Just loading guardians list
            _extractGuardiansFromDependents(state.dependents);
          }
        } else if (state is PartnersLoaded) {
          // Add partners as potential guardian options
          _addPartnersAsGuardianOptions(state.partners);
        } else if (state is WillPersonsLoaded) {
          // Add all adults from will persons as potential guardian options
          _addWillPersonsAsGuardianOptions(state.persons);
        } else if (state is PetsLoaded) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            SnackBarUtils.showSuccess(
              context,
              _isEditMode ? 'Updated successfully' : 'Added successfully',
            );
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
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            _isEditMode ? 'Edit dependant' : 'Add dependant',
            style: AppTextStyles.questionTitle,
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
                        // Dependent Type Selection
                        RadioListOption(
                          isSelected: _dependentType == DependentType.major,
                          title: 'This dependent is an adult',
                          subtitle: 'Add an adult family member as a dependent',
                          onTap: () {
                            setState(() {
                              _dependentType = _dependentType == DependentType.major
                                  ? null
                                  : DependentType.major;
                              // Reset other type's data when switching
                              if (_dependentType == DependentType.major) {
                                _petNameController.clear();
                                _selectedAnimal = null;
                                _addCaretaker = null;
                                _selectedRelation =
                                    null; // Clear relation as list changes
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        RadioListOption(
                          isSelected: _dependentType == DependentType.minor,
                          title: 'This dependent is a minor',
                          subtitle:
                              'When adding a minor, a guardian has to be added under this as well',
                          onTap: () {
                            setState(() {
                              _dependentType = _dependentType == DependentType.minor
                                  ? null
                                  : DependentType.minor;
                              // Reset other type's data when switching
                              if (_dependentType == DependentType.minor) {
                                _petNameController.clear();
                                _selectedAnimal = null;
                                _selectedRelation =
                                    null; // Clear relation as list changes
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        RadioListOption(
                          isSelected: _dependentType == DependentType.pet,
                          title: 'This dependent is a pet',
                          subtitle:
                              'When adding a pet, a guardian has to be added under this as well',
                          onTap: () {
                            setState(() {
                              _dependentType = _dependentType == DependentType.pet
                                  ? null
                                  : DependentType.pet;
                              // Reset other type's data when switching
                              if (_dependentType == DependentType.pet) {
                                _fullNameController.clear();
                                _middleNameController.clear();
                                _lastNameController.clear();
                                _selectedRelation = null;
                                // Reset pet guardian choice
                                _addPetGuardian = null;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Minor or Major (Adult) Form
                        if (_dependentType == DependentType.minor ||
                            _dependentType == DependentType.major) ...[
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
                          const SizedBox(height: 12),
                          AppDropdown<String>(
                            value: _selectedRelation,
                            label: 'Select relation',
                            items: _relations,
                            displayName: FormConstants.getRelationDisplayName,
                            onChanged: (value) {
                              setState(() {
                                _selectedRelation = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _emailController,
                            label: _dependentType == DependentType.major ? 'Email address' : 'Email address (optional)',
                            keyboardType: TextInputType.emailAddress,
                            isRequired: _dependentType == DependentType.major,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
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
                            isRequired: _dependentType == DependentType.major,
                            label: _dependentType == DependentType.major ? 'Phone number' : 'Phone number (optional)',
                          ),
                          const SizedBox(height: 12),
                          // DOB field
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dependentType == DependentType.minor
                                    ? DateTime(DateTime.now().year - 5)
                                    : DateTime(1990),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _dependentDob =
                                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                  _dobController.text = _dependentDob!;
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
                          // Address field
                          AppTextField(
                            controller: _addressController,
                            label: 'Address',
                            isRequired: true,
                          ),
                          const SizedBox(height: 24),

                          // Add Guardian (Minor) question - mandatory for minors
                          if (_dependentType == DependentType.minor) ...[
                            Text(
                              'Add a Guardian (Minor)?',
                              style: AppTextStyles.questionTitle,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioButtonOption(
                                    isSelected: _addCaretaker == 'yes',
                                    label: 'Yes',
                                    onTap: () {
                                      setState(() {
                                        _addCaretaker = 'yes';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RadioButtonOption(
                                    isSelected: _addCaretaker == 'no',
                                    label: 'No',
                                    onTap: () {
                                      setState(() {
                                        _addCaretaker = 'no';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Show guardian fields when Yes is selected
                            if (_addCaretaker == 'yes') ...[
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
                                      _selectedPreviousCaretaker =
                                          result.fullName;
                                      _selectedCaretakerInfo = result;
                                      // Populate caretaker fields
                                      _caretakerFullNameController.text =
                                          result.firstName;
                                      _caretakerMiddleNameController.text =
                                          result.middleName ?? '';
                                      _caretakerLastNameController.text =
                                          result.lastName;
                                      _caretakerEmailController.text =
                                          result.email ?? '';
                                      final (
                                        resultCode,
                                        resultNumber,
                                      ) = AppPhoneInput.parsePhoneNumber(
                                        result.mobile,
                                      );
                                      _caretakerCountryCode = resultCode;
                                      _caretakerPhoneController.text =
                                          resultNumber;
                                      // Populate DOB and relationship
                                      _guardianDob = result.dob;
                                      _guardianDobController.text =
                                          result.dob != null
                                              ? AppDatePickerField.formatApiDateForDisplay(result.dob!)
                                              : '';
                                      _guardianRelationship =
                                          result.relationship;
                                    });
                                  }
                                },
                                child: Container(
                                  height: 48,
                                  decoration: AppDecorations.card,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedPreviousCaretaker ??
                                              'Select previously added',
                                          style:
                                              _selectedPreviousCaretaker != null
                                              ? AppTextStyles.inputText
                                              : AppTextStyles.inputHint,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _caretakerFullNameController,
                                label: 'Full name',
                                isRequired: true,
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
                                isRequired: true,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _caretakerEmailController,
                                label: 'Email address',
                                keyboardType: TextInputType.emailAddress,
                                isRequired: true,
                                validator: (value) {
                                  if (value != null && value.trim().isNotEmpty) {
                                    final emailRegex = RegExp(
                                      r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$',
                                    );
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              AppPhoneInput(
                                controller: _caretakerPhoneController,
                                countryCode: _caretakerCountryCode,
                                onCountryCodeChanged: (code) {
                                  setState(() {
                                    _caretakerCountryCode = code;
                                  });
                                },
                                isRequired: true,
                                label: 'Phone number',
                              ),
                              const SizedBox(height: 12),
                              AppDatePickerField(
                                controller: _guardianDobController,
                                label: 'Date of birth',
                                isRequired: true,
                                onDateSelected: (date) {
                                  setState(() {
                                    _guardianDob = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                    _guardianDobController.text = _guardianDob!;
                                  });
                                },
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
                          ], // End of guardian section for minor
                          
                          // Add Backup Guardian question - only for minors
                          if (_dependentType == DependentType.minor) ...[
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
                                    final (
                                      bgCode,
                                      bgNumber,
                                    ) = AppPhoneInput.parsePhoneNumber(
                                      result.mobile,
                                    );
                                    _backupGuardianCountryCode = bgCode;
                                    _backupGuardianPhoneController.text =
                                        bgNumber;
                                    // Populate DOB and relationship
                                    _backupGuardianDob = result.dob;
                                    _backupGuardianDobController.text =
                                        result.dob != null
                                            ? AppDatePickerField.formatApiDateForDisplay(result.dob!)
                                            : '';
                                    _backupGuardianRelationship =
                                        result.relationship;
                                  });
                                }
                              },
                              child: Container(
                                height: 48,
                                decoration: AppDecorations.card,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedPreviousBackupGuardian ??
                                            'Select previously added',
                                        style:
                                            _selectedPreviousBackupGuardian != null
                                            ? AppTextStyles.inputText
                                            : AppTextStyles.inputHint,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
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
                                    r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$',
                                  );
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
                                setState(() {
                                  _backupGuardianCountryCode = code;
                                });
                              },
                              isRequired: true,
                              label: 'Phone number',
                            ),
                            const SizedBox(height: 12),
                            AppDatePickerField(
                              controller: _backupGuardianDobController,
                              label: 'Date of birth',
                              isRequired: true,
                              onDateSelected: (date) {
                                setState(() {
                                  _backupGuardianDob = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                  _backupGuardianDobController.text = _backupGuardianDob!;
                                });
                              },
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
                          ], // End of backup guardian section for minor
                        ], // End of minor || major section

                        if (_dependentType == DependentType.pet) ...[
                          // Pet Form
                          AppTextField(
                            controller: _petNameController,
                            label: 'Pet\'s name',
                            isRequired: false,
                          ),
                          const SizedBox(height: 12),
                          AppDropdown<String>(
                            value: _selectedAnimal,
                            label: 'Animal',
                            items: FormConstants.animalTypes,
                            displayName: FormConstants.getAnimalDisplayName,
                            onChanged: (value) {
                              setState(() {
                                _selectedAnimal = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _breedController,
                            label: 'Breed',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _registrationController,
                            label: 'Registration or Microchip number',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _vetNameController,
                            label: 'Vet\'s name',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _vetContactController,
                            label: 'Vet\'s contact',
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 24),

                          // Guardian (Pet) - optional (moved before maintenance)
                          Text(
                            'Would you like to add a guardian for your pet?',
                            style: AppTextStyles.questionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A guardian will be responsible for your pet\'s care',
                            style: AppTextStyles.subtitleSmall.copyWith(
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: RadioButtonOption(
                                  isSelected: _addPetGuardian == 'yes',
                                  label: 'Yes',
                                  onTap: () {
                                    setState(() {
                                      _addPetGuardian = 'yes';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RadioButtonOption(
                                  isSelected: _addPetGuardian == 'no',
                                  label: 'No',
                                  onTap: () {
                                    setState(() {
                                      _addPetGuardian = 'no';
                                      // Clear guardian fields when No is selected
                                      _selectedPreviousCaretaker = null;
                                      _selectedCaretakerInfo = null;
                                      _caretakerFullNameController.clear();
                                      _caretakerMiddleNameController.clear();
                                      _caretakerLastNameController.clear();
                                      _caretakerEmailController.clear();
                                      _caretakerPhoneController.clear();
                                      _caretakerAddressController.clear();
                                      _caretakerInstructionController.clear();
                                      _caretakerDob = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Show guardian fields only when Yes is selected
                          if (_addPetGuardian == 'yes') ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              // Show bottom sheet to select previously added caretaker
                              final result =
                                  await showModalBottomSheet<CaretakerInfo>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        SelectCaretakerBottomSheet(
                                          caretakers: _loadedCaretakers,
                                        ),
                                  );
                              if (result != null) {
                                setState(() {
                                  _selectedPreviousCaretaker = result.fullName;
                                  _selectedCaretakerInfo = result;
                                  // Populate caretaker fields
                                  _caretakerFullNameController.text =
                                      result.firstName;
                                  _caretakerMiddleNameController.text =
                                      result.middleName ?? '';
                                  _caretakerLastNameController.text =
                                      result.lastName;
                                  _caretakerEmailController.text =
                                      result.email ?? '';
                                  final (
                                    petResultCode,
                                    petResultNumber,
                                  ) = AppPhoneInput.parsePhoneNumber(
                                    result.mobile,
                                  );
                                  _caretakerCountryCode = petResultCode;
                                  _caretakerPhoneController.text =
                                      petResultNumber;
                                  // Populate DOB and relationship
                                  _caretakerDob = result.dob;
                                  _caretakerRelationship =
                                      result.relationship;
                                });
                              }
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: AppDecorations.card,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedPreviousCaretaker ??
                                        'Select previously added',
                                    style: _selectedPreviousCaretaker != null
                                        ? AppTextStyles.inputText
                                        : AppTextStyles.inputHint,
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _caretakerFullNameController,
                            label: 'First name',
                            isRequired: true,
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
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          // DOB field
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _caretakerDob =
                                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                });
                              }
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: AppDecorations.card,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_caretakerDob != null) ...[
                                        Text(
                                          'DOB',
                                          style:
                                              AppTextStyles.inputLabelFloating,
                                        ),
                                        Text(
                                          _caretakerDob!,
                                          style: AppTextStyles.inputText,
                                        ),
                                      ] else
                                        Text(
                                          'DOB *',
                                          style: AppTextStyles.inputHint,
                                        ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _caretakerAddressController,
                            label: 'Address',
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _caretakerEmailController,
                            label: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppPhoneInput(
                            controller: _caretakerPhoneController,
                            countryCode: _caretakerCountryCode,
                            onCountryCodeChanged: (code) {
                              setState(() {
                                _caretakerCountryCode = code;
                              });
                            },
                            isRequired: true,
                            label: 'Phone number',
                          ),
                          const SizedBox(height: 12),
                          AppDropdownFormField<String>(
                            value: _caretakerRelationship,
                            label: 'Relationship',
                            items: FormConstants.personRelations,
                            displayName: FormConstants.getRelationDisplayName,
                            onChanged: (value) {
                              setState(() {
                                _caretakerRelationship = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 100,
                            decoration: AppDecorations.card,
                            child: TextField(
                              controller: _caretakerInstructionController,
                              maxLines: 4,
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: 'Instruction to caretaker',
                                hintStyle: AppTextStyles.inputHint,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          ], // End of pet guardian fields conditional

                          const SizedBox(height: 24),
                          
                          // Pet Allowance Section
                          Text(
                            'Gift for pet maintenance (optional)',
                            style: AppTextStyles.questionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set aside an amount for your pet\'s ongoing care',
                            style: AppTextStyles.subtitleSmall.copyWith(
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Allowance checkbox
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _addPetAllowance = !_addPetAllowance;
                                if (!_addPetAllowance) {
                                  _allowanceAmountController.clear();
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _addPetAllowance 
                                      ? AppColors.primaryGreen 
                                      : AppColors.borderGray,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _addPetAllowance,
                                      onChanged: (value) {
                                        setState(() {
                                          _addPetAllowance = value ?? false;
                                          if (!_addPetAllowance) {
                                            _allowanceAmountController.clear();
                                          }
                                        });
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      activeColor: AppColors.primaryGreen,
                                      checkColor: Colors.white,
                                      side: BorderSide(
                                        color: _addPetAllowance 
                                            ? AppColors.primaryGreen 
                                            : AppColors.textSecondary,
                                        width: 2.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Add allowance for pet care',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Allowance amount field (shown when checkbox is checked)
                          if (_addPetAllowance) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _allowanceAmountController,
                              label: 'Allowance amount (\$)',
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              validator: (value) {
                                if (_addPetAllowance && (value == null || value.isEmpty)) {
                                  return 'Please enter an allowance amount';
                                }
                                if (value != null && value.isNotEmpty) {
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter a valid amount';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
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
