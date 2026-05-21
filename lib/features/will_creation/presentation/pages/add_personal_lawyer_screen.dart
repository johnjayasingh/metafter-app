import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/debug_config.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../data/models/business_models.dart';

class AddPersonalLawyerScreen extends StatefulWidget {
  final String willId;
  final AssignedLawyer? existingLawyer;

  const AddPersonalLawyerScreen({
    super.key,
    required this.willId,
    this.existingLawyer,
  });

  @override
  State<AddPersonalLawyerScreen> createState() =>
      _AddPersonalLawyerScreenState();
}

class _AddPersonalLawyerScreenState extends State<AddPersonalLawyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firmNameController = TextEditingController();
  final _addressController = TextEditingController();

  String _countryCode = FormConstants.defaultCountryCode;
  bool _isLoading = false;
  String? _errorMessage;

  late final BusinessRepositoryImpl _businessRepository;

  @override
  void initState() {
    super.initState();
    _businessRepository = BusinessRepositoryImpl(apiClient: ApiClient());

    // Populate fields if editing existing lawyer
    if (widget.existingLawyer != null) {
      final lawyer = widget.existingLawyer!;
      print('📝 Editing lawyer: ${lawyer.firstName} ${lawyer.lastName}');
      print('📝 Lawyer address: ${lawyer.address}');
      print('📝 Lawyer firm name: ${lawyer.lawFirmName}');
      
      _firstNameController.text = lawyer.firstName;
      _middleNameController.text = lawyer.middleName ?? '';
      _lastNameController.text = lawyer.lastName;
      _emailController.text = lawyer.email;

      // Handle firm name from lawFirmName field
      _firmNameController.text = lawyer.lawFirmName;
      _addressController.text = lawyer.address ?? '';

      // Extract phone number and country code
      final mobile = lawyer.mobile ?? '';
      if (mobile.isNotEmpty) {
        final (code, number) = AppPhoneInput.parsePhoneNumber(mobile);
        _countryCode = code;
        _phoneController.text = number;
      }
    } else if (DebugConfig.usePrepopulatedData) {
      // Prepopulate with test data for development
      final testData = DebugConfig.testPersonalLawyer;
      _firstNameController.text = testData['firstName'] as String;
      _middleNameController.text = testData['middleName'] as String;
      _lastNameController.text = testData['lastName'] as String;
      _emailController.text = testData['email'] as String;
      _phoneController.text = testData['phone'] as String;
      _countryCode = testData['countryCode'] as String;
      _firmNameController.text = testData['firmName'] as String;
      _addressController.text = testData['address'] as String;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firmNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveLawyer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = PersonalLawyerRequest(
        willId: widget.willId,
        id: widget.existingLawyer != null
            ? int.tryParse(widget.existingLawyer!.id)
            : null,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: AppPhoneInput.combinePhoneNumber(_countryCode, _phoneController.text),
        firmName: _firmNameController.text.trim().isEmpty
            ? null
            : _firmNameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      final response = await _businessRepository.savePersonalLawyer(request);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingLawyer != null
                    ? 'Lawyer updated successfully'
                    : 'Lawyer added successfully',
              ),
              backgroundColor: AppColors.accentGreen,
            ),
          );
          // Return true to indicate success
          context.pop(true);
        }
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to save lawyer';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving lawyer: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingLawyer != null;

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
          isEditing ? 'Edit personal lawyer' : 'Add a personal lawyer',
          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Name
                    AppTextField(
                      controller: _firstNameController,
                      label: 'First name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Middle Name
                    AppTextField(
                      controller: _middleNameController,
                      label: 'Middle name (optional)',
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    AppTextField(
                      controller: _lastNameController,
                      label: 'Last name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Email Address
                    AppEmailField(
                      controller: _emailController,
                      label: 'Email address',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Phone Number with Country Code
                    AppPhoneInput(
                      controller: _phoneController,
                      countryCode: _countryCode,
                      onCountryCodeChanged: (value) {
                        setState(() {
                          _countryCode = value;
                        });
                      },
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Firm Name
                    AppTextField(
                      controller: _firmNameController,
                      label: 'Firm name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    AppTextArea(
                      controller: _addressController,
                      label: 'Address',
                      isRequired: true,
                      maxLines: 3,
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Extra padding so address field scrolls above keyboard
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 120 : 24),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Button
          AppBottomActionBar(
            child: AppPrimaryButton(
              text: isEditing ? 'Update lawyer' : 'Add lawyer',
              onPressed: _saveLawyer,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
