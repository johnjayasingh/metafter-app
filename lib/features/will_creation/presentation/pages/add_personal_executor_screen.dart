import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/debug_config.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';

class AddPersonalExecutorScreen extends StatefulWidget {
  final String? executorId;
  final bool isPrimary;

  const AddPersonalExecutorScreen({super.key, this.executorId, this.isPrimary = true});

  @override
  State<AddPersonalExecutorScreen> createState() => _AddPersonalExecutorScreenState();
}

class _AddPersonalExecutorScreenState extends State<AddPersonalExecutorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  String _countryCode = FormConstants.defaultCountryCode;
  String _selectedRelationship = 'GUARDIAN';
  String? _willId;
  final _secureStorage = SecureStorageService();
  bool _handledSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadWillData();
    print('📝 AddPersonalExecutorScreen initState - executorId: ${widget.executorId}');
  }

  void _populateFieldsFromExecutor(ExecutorDetails executor) {
    print('📝 Populating fields for executor: ${executor.firstName} ${executor.lastName} (ID: ${executor.id})');
    setState(() {
      _firstNameController.text = executor.firstName;
      _middleNameController.text = executor.middleName ?? '';
      _lastNameController.text = executor.lastName;
      _emailController.text = executor.email;
      _selectedRelationship = executor.relationship ?? _selectedRelationship;
      _addressController.text = executor.address ?? '';
      if (executor.dob != null && executor.dob!.isNotEmpty) {
        _dobController.text = AppDatePickerField.formatApiDateForDisplay(executor.dob!);
      }

      // Extract phone number using centralized utility
      final (countryCode, localNumber) = AppPhoneInput.parsePhoneNumber(executor.mobile);
      _countryCode = countryCode;
      _phoneController.text = localNumber;
    });
  }

  ExecutorDetails? _getExecutorById(String executorId) {
    // This will be called from BlocBuilder when ExecutorsLoaded state is received
    return null; // Placeholder, will be implemented in build method
  }

  void _loadDebugData() {
    if (DebugConfig.usePrepopulatedData) {
      setState(() {
        final testData = DebugConfig.testPersonalExecutor;
        _firstNameController.text = testData['firstName'] as String;
        _middleNameController.text = testData['middleName'] as String;
        _lastNameController.text = testData['lastName'] as String;
        _emailController.text = testData['email'] as String;
        _phoneController.text = testData['phone'] as String;
        _countryCode = testData['countryCode'] as String;
        _selectedRelationship = testData['relationship'] as String;
      });
    }
  }

  Future<void> _loadWillData() async {
    _willId = await _secureStorage.getWillId();
    
    // If editing, try to get executor from current BLoC state first
    if (widget.executorId != null && _willId != null && mounted) {
      print('📝 Looking for executor with ID: ${widget.executorId}');
      
      final currentState = context.read<WillBloc>().state;
      if (currentState is ExecutorsLoaded) {
        print('📝 Executors already loaded in state, searching...');
        final executorToEdit = currentState.executors
            .where((e) => e.executor.id?.toString() == widget.executorId || e.id == widget.executorId)
            .firstOrNull;
        
        if (executorToEdit != null) {
          print('📝 Found executor in state: ${executorToEdit.executor.firstName} ${executorToEdit.executor.lastName}');
          _populateFieldsFromExecutor(executorToEdit.executor);
          return; // Don't fetch again
        }
      }
      
      // If not found in state, fetch from API
      print('📝 Executor not in state, fetching from API...');
      context.read<WillBloc>().add(GetExecutorsEvent(_willId!));
    } else if (widget.executorId == null) {
      // Only load debug data if not editing
      _loadDebugData();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _saveExecutor() {
    if (_formKey.currentState!.validate() && _willId != null) {
      if (_dobController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date of birth'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter address'), backgroundColor: Colors.red),
        );
        return;
      }
      final executorIdInt = widget.executorId != null ? int.tryParse(widget.executorId!) : null;
      final executor = ExecutorDetails(
        id: executorIdInt,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: AppPhoneInput.combinePhoneNumber(_countryCode, _phoneController.text, withSpace: false),
        relationship: _selectedRelationship,
        address: _addressController.text.trim(),
        dob: _dobController.text.trim(),
      );

      print('💾 Saving executor: ${executor.firstName} ${executor.lastName} (ID: ${executor.id})');

      final request = ExecutorRequest(
        willId: _willId!,
        executorDetails: executor,
        isPrimary: widget.isPrimary,
      );

      context.read<WillBloc>().add(AllocateExecutorEvent(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.executorId != null ? 'Edit Executor' : 'Add a personal Executors',
          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocListener<WillBloc, WillState>(
        listener: (context, state) {
          if (state is ExecutorsLoaded && widget.executorId != null) {
            // Find the executor to edit
            final executorToEdit = state.executors
                .where((e) => e.executor.id?.toString() == widget.executorId || e.id == widget.executorId)
                .firstOrNull;
            
            if (executorToEdit != null && _firstNameController.text.isEmpty) {
              print('📝 Found executor to edit: ${executorToEdit.executor.firstName} ${executorToEdit.executor.lastName}');
              _populateFieldsFromExecutor(executorToEdit.executor);
            }
          } else if (state is ExecutorAllocated && !_handledSuccess) {
            _handledSuccess = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.executorId != null 
                    ? 'Executor updated successfully' 
                    : 'Executor added successfully',
                ),
                backgroundColor: AppColors.accentGreen,
              ),
            );
            // Pop back to executors screen to trigger .then() callback
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop();
              }
            });
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
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Name - using centralized AppTextField
                      AppTextField(
                        controller: _firstNameController,
                        label: 'First name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Middle Name
                      AppTextField(
                        controller: _middleNameController,
                        label: 'Middle name',
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      AppTextField(
                        controller: _lastNameController,
                        label: 'Last name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Email Address - using centralized AppEmailField
                      AppEmailField(
                        controller: _emailController,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number with Country Code - using centralized AppPhoneInput
                      AppPhoneInput(
                        controller: _phoneController,
                        countryCode: _countryCode,
                        onCountryCodeChanged: (code) => setState(() => _countryCode = code),
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      AppTextField(
                        controller: _addressController,
                        label: 'Address',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth
                      AppDatePickerField(
                        controller: _dobController,
                        label: 'Date of birth',
                        isRequired: true,
                        onDateSelected: (date) {
                          _dobController.text =
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                        },
                      ),
                      const SizedBox(height: 16),

                      // Relationship - using centralized AppDropdownFormField
                      AppDropdownFormField<String>(
                        value: FormConstants.adultRelations.contains(_selectedRelationship)
                            ? _selectedRelationship
                            : 'GUARDIAN',
                        label: 'Select relationship',
                        items: FormConstants.adultRelations,
                        displayName: FormConstants.getRelationDisplayName,
                        onChanged: (value) {
                          setState(() {
                            _selectedRelationship = value!;
                          });
                        },
                        isRequired: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Button - using centralized AppBottomActionBar and AppPrimaryButton
            AppBottomActionBar(
              child: SafeArea(
                child: AppPrimaryButton(
                  text: widget.executorId != null ? 'Update executor' : 'Add executors',
                  onPressed: _saveExecutor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
