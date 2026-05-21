import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/debug_config.dart';
import '../../../../core/utils/exit_confirmation_sheet.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/will_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';

class BasicDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? previousData;
  
  const BasicDetailsScreen({super.key, this.previousData});

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _suburbController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _stateController = TextEditingController();
  String? _selectedCountry = 'Australia'; // Default to Australia
  List<String> _otherNames = []; // List of aliases/other known names
  bool _hasOtherNames = false; // Toggle for "known by another name" question
  
  final List<String> _countries = ['Australia']; // Only Australia for now
  
  bool _hasCapacity = false;
  bool _isMedicalProofUploaded = false;
  bool _isUploadingMedicalProof = false;
  String? _medicalProofFileName;
  bool _isLoading = true;
  String? _existingWillId; // Track if editing existing will

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Check if there's existing will data
    final storage = SecureStorageService();
    final willId = await storage.getWillId();

    if (willId != null) {
      // Will ID exists, load the initial will data
      _existingWillId = willId; // Store for later use when saving
      if (mounted) {
        context.read<WillBloc>().add(GetInitialWillEvent(willId));
      }
      return;
    }

    // Only prepopulate with test data for NEW wills if debug flag is enabled
    if (DebugConfig.usePrepopulatedData) {
      setState(() {
        _fullNameController.text = DebugConfig.testBasicDetails['firstName'] as String;
        _middleNameController.text = DebugConfig.testBasicDetails['middleName'] as String;
        _lastNameController.text = DebugConfig.testBasicDetails['lastName'] as String;
        _dobController.text = DebugConfig.testBasicDetails['dob'] as String;
        _addressController.text = DebugConfig.testBasicDetails['addressLine1'] as String;
        _suburbController.text = DebugConfig.testBasicDetails['suburb'] as String;
        _postcodeController.text = DebugConfig.testBasicDetails['postcode'] as String;
        _selectedCountry = DebugConfig.testBasicDetails['country'] as String;
        _hasCapacity = widget.previousData?['hasCapacity'] ?? true;
      });
    }
    
    // Load previous data from navigation
    if (widget.previousData != null) {
      setState(() {
        _hasCapacity = widget.previousData!['hasCapacity'] ?? _hasCapacity;
      });
    }
    
    // New will - clear any stale form data
    setState(() {
      _fullNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _dobController.clear();
      _addressController.clear();
      _suburbController.clear();
      _postcodeController.clear();
      _stateController.clear();
      _selectedCountry = 'Australia';
      _otherNames = [];
      _hasOtherNames = false;
      _existingWillId = null;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _pickMedicalProofFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _medicalProofFileName = file.name;
          });
          if (_existingWillId != null && mounted) {
            setState(() => _isUploadingMedicalProof = true);
            context.read<WillBloc>().add(
              UploadMedicalProofEvent(
                willId: _existingWillId!,
                filePath: file.path!,
                fileName: file.name,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to pick file: $e');
    }
  }

  void _showAddOtherNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Other Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter name (e.g., maiden name)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _otherNames.add(controller.text.trim());
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWillData() async {
    // Convert date from DD/MM/YYYY to YYYY-MM-DD
    String convertedDob = _dobController.text.trim();
    if (convertedDob.contains('/')) {
      final parts = convertedDob.split('/');
      if (parts.length == 3) {
        convertedDob = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    }
    // Reject invalid sentinel values that may have been stored from a bad previous save
    final dobRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dobRegex.hasMatch(convertedDob)) {
      SnackBarUtils.showError(context, 'Please enter a valid date of birth');
      return;
    }

    final request = InitialWillRequest(
      willId: _existingWillId, // Pass existing ID for update, null for create
      hasCapacity: _hasCapacity,
      firstName: _fullNameController.text,
      middleName: _middleNameController.text.isEmpty ? null : _middleNameController.text,
      lastName: _lastNameController.text,
      dob: convertedDob,
      addressLine1: _addressController.text,
      suburb: _suburbController.text,
      postcode: _postcodeController.text,
      country: _selectedCountry ?? 'Australia',
      state: _stateController.text.isEmpty ? null : FormConstants.toStateApiValue(_stateController.text),
      otherNames: _otherNames.isEmpty ? null : _otherNames,
    );

    context.read<WillBloc>().add(CreateInitialWillEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listener: (context, state) {
        if (state is WillSuccess) {
          // Save will ID for future steps
          if (state.data != null && state.data is InitialWillData) {
            final willData = state.data as InitialWillData;
            final storage = SecureStorageService();
            storage.saveWillId(willData.willId);
            setState(() {
              _isLoading = false;
            });
          }
          // Navigate to next step using go (replaces current route)
          context.go(AppRouter.relationshipStatus);
        } else if (state is WillError) {
          // Only show error if message is not empty (skip network errors)
          if (state.message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
        } else if (state is InitialWillLoaded && _existingWillId != null) {
          // Load existing data only when editing an existing will
          setState(() {
            _fullNameController.text = state.willData.firstName;
            _middleNameController.text = state.willData.middleName ?? '';
            _lastNameController.text = state.willData.lastName;
            _dobController.text = state.willData.dob;
            _addressController.text = state.willData.addressLine1;
            _suburbController.text = state.willData.suburb;
            _postcodeController.text = state.willData.postcode;
            _stateController.text = FormConstants.toStateApiValue(state.willData.state) ?? '';
            _selectedCountry = state.willData.country;
            _otherNames = state.willData.otherNames ?? [];
            _hasOtherNames = _otherNames.isNotEmpty;
            _hasCapacity = state.willData.hasCapacity;
            _isMedicalProofUploaded = state.willData.isMedicalProofDocumentUploaded;
            _medicalProofFileName = state.willData.medicalProofDocumentFile;
            _existingWillId = state.willData.willId;
            _isLoading = false;
          });
        } else if (state is MedicalProofUploaded) {
          setState(() {
            _isUploadingMedicalProof = false;
            _isMedicalProofUploaded = true;
            _medicalProofFileName = state.fileName;
          });
          SnackBarUtils.showSuccess(context, 'Medical proof uploaded successfully');
        }
      },
      builder: (context, state) {
        if (_isLoading || state is WillLoading) {
          return Scaffold(
            backgroundColor: AppColors.backgroundWhite,
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          );
        }

        return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: _existingWillId != null ? WillStepsSidebar(currentStep: 1) : null,
      drawerEnableOpenDragGesture: _existingWillId != null,
      appBar: WillCreationAppBar(
        currentStep: 1,
        totalSteps: 11,
        title: 'Your details',
        showBackButton: true,
        enableDrawer: _existingWillId != null,
        onBack: () {
          showExitConfirmationSheet(context);
        },
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
                      // Page header
                      Text(
                        "Let's start with you",
                        style: AppTextStyles.pageTitleWithColor(
                          AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your Will online—add your details, name heirs',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),

                      // Basic Details Section
                      Text(
                        'Basic details',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your legal name and address details',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 16),

                      // Full name
                      AppTextField(
                        controller: _fullNameController,
                        label: 'Full name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Middle name (optional)
                      AppTextField(
                        controller: _middleNameController,
                        label: 'Middle name',
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),

                      // Last name
                      AppTextField(
                        controller: _lastNameController,
                        label: 'Last name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // DOB
                      AppDatePickerField(
                        controller: _dobController,
                        label: 'DOB',
                        isRequired: true,
                        onDateSelected: (date) {
                          setState(() {
                            _dobController.text = AppDatePickerField.formatDate(date);
                          });
                        },
                      ),

                      const SizedBox(height: 24),
                      // Section separator
                      Container(
                        height: 1,
                        color: AppColors.borderGray,
                      ),
                      const SizedBox(height: 24),

                      // Address Section
                      Text(
                        'Address',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Where are you based',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      AppTextField(
                        controller: _addressController,
                        label: 'Address',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Suburb
                      AppTextField(
                        controller: _suburbController,
                        label: 'Suburb',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // State
                      AppDropdownFormField<String>(
                        value: _stateController.text.isEmpty ? null : _stateController.text,
                        label: 'State',
                        items: FormConstants.australianStateKeys,
                        displayName: (value) => FormConstants.getStateDisplayName(value),
                        onChanged: (value) {
                          setState(() {
                            _stateController.text = value ?? '';
                          });
                          // Re-validate after setState to clear any errors
                          Future.microtask(() {
                            _formKey.currentState?.validate();
                          });
                        },
                        isRequired: true,
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
                            return 'This field is required';
                          }
                          if (value.trim().length != 4) {
                            return 'Postcode must be 4 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Country
                      AppDropdownFormField<String>(
                        value: _selectedCountry,
                        label: 'Country',
                        items: _countries,
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                          });
                          // Re-validate after setState to clear any errors
                          Future.microtask(() {
                            _formKey.currentState?.validate();
                          });
                        },
                        isRequired: true,
                      ),
                      
                      const SizedBox(height: 24),
                      // Section separator
                      Container(
                        height: 1,
                        color: AppColors.borderGray,
                      ),
                      const SizedBox(height: 24),
                      
                      // Other Names Section (Aliases)
                      Text(
                        'Have you ever been known by another name?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'E.g., maiden name, previous married name, or nicknames',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 16),
                      
                      // Yes/No toggle buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _hasOtherNames = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _hasOtherNames 
                                      ? AppColors.primaryGreen 
                                      : AppColors.backgroundWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _hasOtherNames 
                                        ? AppColors.primaryGreen 
                                        : AppColors.borderGray,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Yes',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _hasOtherNames 
                                          ? Colors.white 
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _hasOtherNames = false;
                                  _otherNames.clear(); // Clear names when selecting No
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: !_hasOtherNames 
                                      ? AppColors.primaryGreen 
                                      : AppColors.backgroundWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !_hasOtherNames 
                                        ? AppColors.primaryGreen 
                                        : AppColors.borderGray,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'No',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: !_hasOtherNames 
                                          ? Colors.white 
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Show other names input when Yes is selected
                      if (_hasOtherNames) ...[
                        const SizedBox(height: 16),
                        
                        // Display existing other names
                        if (_otherNames.isNotEmpty) ...[
                          ..._otherNames.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.lightGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: AppTextStyles.inputText,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _otherNames.removeAt(entry.key);
                                        // If no more names, turn off the toggle
                                        if (_otherNames.isEmpty) {
                                          _hasOtherNames = false;
                                        }
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(height: 8),
                        ],
                        
                        // Add new other name button
                        AppSecondaryButton(
                          text: 'Add name',
                          icon: Icons.add,
                          onPressed: () => _showAddOtherNameDialog(),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Container(height: 1, color: AppColors.borderGray),
                      const SizedBox(height: 24),

                      // Capacity Section
                      Text('Capacity', style: AppTextStyles.questionTitle),
                      const SizedBox(height: 4),
                      Text(
                        "Declare that you're capable of creating a will under the right circumstances",
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: AppColors.borderGray,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 2),
                              child: Checkbox(
                                value: _hasCapacity,
                                onChanged: (value) {
                                  setState(() {
                                    _hasCapacity = value ?? false;
                                  });
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                activeColor: AppColors.primaryGreen,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: _hasCapacity
                                      ? AppColors.primaryGreen
                                      : AppColors.textSecondary,
                                  width: 2.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'I declare that I have the mental capacity to create my Will and I am willing to provide a medical clearance certificate if requested.',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'A medical clearance certificate may be requested to confirm your testamentary capacity. This is a document from a qualified medical practitioner confirming you understand the nature and effect of making a Will.',
                          style: AppTextStyles.disclaimer.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Medical proof upload
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _isMedicalProofUploaded ||
                                _medicalProofFileName != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Medical clearance certificate (optional)',
                                          style: AppTextStyles.subtitle
                                              .copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                      ),
                                      if (_isMedicalProofUploaded)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentGreen
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: AppColors.accentGreen,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Uploaded',
                                                style: AppTextStyles
                                                    .disclaimer
                                                    .copyWith(
                                                      color:
                                                          AppColors.accentGreen,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundWhite,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.accentGreen
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors
                                                .backgroundLightGreen,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.description_outlined,
                                            color: AppColors.primaryGreen,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _medicalProofFileName ??
                                                    'Document',
                                                style: AppTextStyles
                                                    .bodyMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'PDF Document',
                                                style: AppTextStyles
                                                    .disclaimer
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _isUploadingMedicalProof
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors
                                                          .primaryGreen,
                                                    ),
                                              )
                                            : TextButton(
                                                onPressed:
                                                    _pickMedicalProofFile,
                                                child: Text(
                                                  'Replace',
                                                  style: AppTextStyles
                                                      .bodyMedium
                                                      .copyWith(
                                                        color: AppColors
                                                            .primaryGreen,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Upload medical clearance certificate (optional)',
                                      style: AppTextStyles.subtitle,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _isUploadingMedicalProof
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryGreen,
                                          ),
                                        )
                                      : SizedBox(
                                          width: 85,
                                          child: AppPrimaryButton(
                                            text: 'Upload',
                                            onPressed: _pickMedicalProofFile,
                                            fullWidth: false,
                                          ),
                                        ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom buttons
            AppBottomActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: AppCancelButton(
                      text: 'Exit',
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          NavigationUtils.goToHomeAndRefresh(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Next step',
                      onPressed: !_hasCapacity
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _saveWillData();
                              }
                            },
                      isDisabled: !_hasCapacity,
                      isLoading: _isLoading || state is WillLoading,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
