import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/debug_config.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';

class AddWitnessScreen extends StatefulWidget {
  final WitnessData? existingWitness;

  const AddWitnessScreen({super.key, this.existingWitness});

  @override
  State<AddWitnessScreen> createState() => _AddWitnessScreenState();
}

class _AddWitnessScreenState extends State<AddWitnessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();
  String? _willId;
  final _secureStorage = SecureStorageService();
  bool _handledSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadWillData();

    // Populate fields if editing
    if (widget.existingWitness != null) {
      _firstNameController.text = widget.existingWitness!.firstName;
      _middleNameController.text = widget.existingWitness!.middleName ?? '';
      _lastNameController.text = widget.existingWitness!.lastName;
      _emailController.text = widget.existingWitness!.email;
      _noteController.text = widget.existingWitness!.note ?? '';
      _addressController.text = widget.existingWitness!.address ?? '';
    } else if (DebugConfig.usePrepopulatedData) {
      // Prepopulate with test data for development
      final testData = DebugConfig.testWitness;
      _firstNameController.text = testData['firstName'] as String;
      _middleNameController.text = testData['middleName'] as String;
      _lastNameController.text = testData['lastName'] as String;
      _emailController.text = testData['email'] as String;
      _noteController.text = testData['note'] as String;
    }
  }

  Future<void> _loadWillData() async {
    _willId = await _secureStorage.getWillId();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveWitness() {
    if (_formKey.currentState!.validate() && _willId != null) {
      final witness = WitnessData(
        id: widget.existingWitness?.id ?? '',
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      // Preserve any existing mobile number but no longer collect it in the form
      mobile: widget.existingWitness?.mobile,
        notes: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (widget.existingWitness != null) {
        // Update existing witness
        context.read<WillBloc>().add(UpdateWitnessEvent(_willId!, witness));
      } else {
        // Add new witness
        context.read<WillBloc>().add(AddWitnessEvent(_willId!, witness));
      }
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
          'Add witness',
          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocListener<WillBloc, WillState>(
        listener: (context, state) {
          if ((state is WitnessAdded || state is WitnessUpdated) && !_handledSuccess) {
            _handledSuccess = true;
            SnackBarUtils.showSuccess(
              context,
              widget.existingWitness != null
                  ? 'Witness updated successfully'
                  : 'Witness added successfully',
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop();
              }
            });
          } else if (state is WillError) {
            SnackBarUtils.showError(context, state.message);
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

                      // Email Address
                      AppEmailField(
                        controller: _emailController,
                        label: 'Email address',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      AppTextField(
                        controller: _addressController,
                        label: 'Address',
                      ),
                      const SizedBox(height: 16),

                      // Note to Witness
                      AppTextArea(
                        controller: _noteController,
                        label: 'Note to witness',
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Button
            AppBottomActionBar(
              child: AppPrimaryButton(
                text: widget.existingWitness != null ? 'Update witness' : 'Add witness',
                onPressed: _saveWitness,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
