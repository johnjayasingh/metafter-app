import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/vault_models.dart';
import '../cubit/vault_cubit.dart';
import '../cubit/vault_state.dart';

class AddContactScreen extends StatefulWidget {
  final VaultItem? existingItem;

  const AddContactScreen({super.key, this.existingItem});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _countryCode = '+61';
  bool _isSaving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final data = widget.existingItem!.contactData;
      _firstNameController.text = data.firstName;
      _lastNameController.text = data.lastName;
      _emailController.text = data.email ?? '';
      if (data.phone != null) {
        final (code, number) = AppPhoneInput.parsePhoneNumber(data.phone!);
        _countryCode = code;
        _phoneController.text = number;
      }
    } else if (DebugDataService.isEnabled) {
      final mock = DebugDataService.debugVaultContactData;
      _firstNameController.text = mock['firstName'] ?? '';
      _lastNameController.text = mock['lastName'] ?? '';
      _emailController.text = mock['email'] ?? '';
      if (mock['phone'] != null && mock['phone']!.isNotEmpty) {
        final (code, number) = AppPhoneInput.parsePhoneNumber(mock['phone']!);
        _countryCode = code;
        _phoneController.text = number;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _selectFromWillPeople() {
    final cubitState = context.read<VaultCubit>().state;
    List<WillPerson> willPeople = [];
    if (cubitState is VaultLoaded) willPeople = cubitState.willPeople;
    if (cubitState is VaultOperationSuccess) willPeople = cubitState.willPeople;

    if (willPeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No people found from your will')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: willPeople.length,
        itemBuilder: (ctx, i) {
          final person = willPeople[i];
          return ListTile(
            title: Text(person.fullName),
            subtitle: person.email != null ? Text(person.email!) : null,
            onTap: () {
              setState(() {
                _firstNameController.text = person.firstName;
                _lastNameController.text = person.lastName;
                if (person.email != null) {
                  _emailController.text = person.email!;
                }
                if (person.mobile != null) {
                  final (code, number) =
                      AppPhoneInput.parsePhoneNumber(person.mobile!);
                  _countryCode = code;
                  _phoneController.text = number;
                }
              });
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  void _onSave() {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final phone = _phoneController.text.trim();
    final contactData = ContactData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: phone.isNotEmpty
          ? AppPhoneInput.combinePhoneNumber(_countryCode, phone)
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    final payload = VaultItemCreate(
      assetId: widget.existingItem?.id,
      type: VaultAssetType.contact,
      data: contactData.toMap(),
    );

    context.read<VaultCubit>().createItem(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Contact' : 'Add Person',
          style: AppTextStyles.sectionTitle,
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<VaultCubit, VaultState>(
        listener: (context, state) {
          if (state is VaultOperationSuccess) {
            context.read<VaultCubit>().acknowledgeSuccess();
            context.pop(true);
          } else if (state is VaultError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          } else if (state is VaultOperationLoading) {
            setState(() => _isSaving = true);
          }
        },
        builder: (context, state) {
          return SafeArea(
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
                          Text(
                            'Add the details of this important contact so your Executor knows who to reach.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppSecondaryButton(
                            text: 'Select from Will People',
                            icon: Icons.people_outline,
                            onPressed: _selectFromWillPeople,
                          ),
                          const SizedBox(height: 24),
                          AppTextField(
                            controller: _firstNameController,
                            label: 'First name',
                            isRequired: true,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _lastNameController,
                            label: 'Last name',
                            isRequired: true,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          AppPhoneInput(
                            controller: _phoneController,
                            countryCode: _countryCode,
                            onCountryCodeChanged: (code) {
                              setState(() => _countryCode = code);
                            },
                            label: 'Phone number',
                          ),
                          const SizedBox(height: 16),
                          AppEmailField(
                            controller: _emailController,
                            label: 'Email address',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppBottomActionBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppCancelButton(
                          text: 'Cancel',
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          text: _isSaving ? 'Saving...' : 'Save',
                          onPressed: _isSaving ? null : _onSave,
                          isLoading: _isSaving,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
