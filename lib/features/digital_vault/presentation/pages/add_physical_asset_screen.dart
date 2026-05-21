import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/data/models/will_models.dart'
    show AssetTypeItem, InstitutionItem;
import '../../../will_creation/presentation/bloc/will_bloc.dart';
import '../../../will_creation/presentation/bloc/will_event.dart';
import '../../../will_creation/presentation/bloc/will_state.dart';
import '../../data/models/vault_models.dart';
import '../cubit/vault_cubit.dart';
import '../cubit/vault_state.dart';
import '../widgets/vault_warning_banner.dart';

class AddPhysicalAssetScreen extends StatefulWidget {
  final VaultItem? existingItem;

  const AddPhysicalAssetScreen({super.key, this.existingItem});

  @override
  State<AddPhysicalAssetScreen> createState() =>
      _AddPhysicalAssetScreenState();
}

class _AddPhysicalAssetScreenState extends State<AddPhysicalAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  bool _isSaving = false;

  // Asset type & institution from API
  List<AssetTypeItem> _assetTypes = [];
  List<InstitutionItem> _institutions = [];
  AssetTypeItem? _selectedAssetType;
  InstitutionItem? _selectedInstitution;
  String? _selectedLocation;
  bool _isLoadingAssetTypes = true;
  bool _isLoadingInstitutions = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _loadAssetTypes();

    if (_isEditing) {
      final data = widget.existingItem!.assetData;
      _nameController.text = data.name;
      _detailController.text = data.description;
      _selectedLocation =
          (data.location.isNotEmpty && FormConstants.countries.contains(data.location))
              ? data.location
              : null;
    } else if (DebugDataService.isEnabled) {
      final mock = DebugDataService.debugVaultAssetData;
      _nameController.text = mock['name'] ?? '';
      _detailController.text = mock['description'] ?? '';
      final loc = mock['location'] ?? '';
      _selectedLocation =
          (loc.isNotEmpty && FormConstants.countries.contains(loc)) ? loc : null;
    }
  }

  void _loadAssetTypes() {
    context.read<WillBloc>().add(const GetAssetTypeCatalogEvent());
  }

  void _loadInstitutions(String assetTypeId) {
    setState(() => _isLoadingInstitutions = true);
    context.read<WillBloc>().add(GetAssetInstitutionsEvent(assetTypeId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _selectFromWillAssets() {
    final cubitState = context.read<VaultCubit>().state;
    List<WillAsset> willAssets = [];
    if (cubitState is VaultLoaded) willAssets = cubitState.willAssets;
    if (cubitState is VaultOperationSuccess) willAssets = cubitState.willAssets;

    if (willAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assets found from your will')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: willAssets.length,
        itemBuilder: (ctx, i) {
          final asset = willAssets[i];
          return ListTile(
            title: Text(asset.name),
            subtitle:
                asset.institution != null ? Text(asset.institution!) : null,
            onTap: () {
              setState(() {
                _nameController.text = asset.name;
                if (asset.description != null) {
                  _detailController.text = asset.description!;
                }
                // Try to match asset type
                _selectedAssetType = _assetTypes.cast<AssetTypeItem?>().firstWhere(
                  (t) =>
                      t!.id == asset.typeId ||
                      t.name.toLowerCase() == (asset.type ?? '').toLowerCase(),
                  orElse: () => null,
                );
                // Try to match location
                _selectedLocation =
                    (asset.location != null && FormConstants.countries.contains(asset.location))
                        ? asset.location
                        : null;
              });
              Navigator.pop(ctx);
              // Load institutions for matched asset type
              if (_selectedAssetType != null) {
                _loadInstitutions(_selectedAssetType!.id);
                // We'll try to match institution after they load
                // Store the will asset temporarily to match institution later
                _pendingInstitutionMatch = asset.institutionId ?? asset.institution;
              }
            },
          );
        },
      ),
    );
  }

  // Used to match institution after institutions list loads from "Select from Will Assets"
  String? _pendingInstitutionMatch;

  void _onSave() {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedAssetType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an asset type')),
      );
      return;
    }

    if (_selectedInstitution == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an institution')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final assetData = AssetData(
      name: _nameController.text.trim(),
      assetType: _selectedAssetType!.name,
      assetTypeId: _selectedAssetType!.id,
      institution: _selectedInstitution!.name,
      institutionId: _selectedInstitution!.id,
      location: _selectedLocation ?? '',
      description: _detailController.text.trim(),
    );

    final payload = VaultItemCreate(
      assetId: widget.existingItem?.id,
      type: VaultAssetType.asset,
      data: assetData.toMap(),
    );

    context.read<VaultCubit>().createItem(payload);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WillBloc, WillState>(
          listener: (context, state) {
            if (state is AssetTypeCatalogLoaded) {
              setState(() {
                _assetTypes = state.assetTypes;
                _isLoadingAssetTypes = false;

                // If editing, match existing asset type
                if (_isEditing && widget.existingItem != null) {
                  final data = widget.existingItem!.assetData;
                  final existingType = data.assetTypeId ?? data.assetType ?? '';
                  _selectedAssetType =
                      _assetTypes.cast<AssetTypeItem?>().firstWhere(
                            (t) =>
                                t!.id == existingType ||
                                t.name.toLowerCase() == existingType.toLowerCase(),
                            orElse: () => null,
                          );
                  if (_selectedAssetType != null) {
                    _pendingInstitutionMatch =
                        data.institutionId ?? data.institution;
                    _loadInstitutions(_selectedAssetType!.id);
                  }
                }
              });
            } else if (state is AssetInstitutionsLoaded) {
              setState(() {
                _institutions = state.institutions;
                _isLoadingInstitutions = false;

                // Try to match pending institution
                if (_pendingInstitutionMatch != null) {
                  final match = _pendingInstitutionMatch!;
                  _selectedInstitution =
                      _institutions.cast<InstitutionItem?>().firstWhere(
                            (inst) =>
                                inst!.id == match ||
                                inst.identifier == match ||
                                inst.name.toLowerCase() == match.toLowerCase(),
                            orElse: () => null,
                          );
                  _pendingInstitutionMatch = null;
                }
              });
            }
          },
        ),
        BlocListener<VaultCubit, VaultState>(
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
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Asset' : 'Assets - Add',
            style: AppTextStyles.sectionTitle,
          ),
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: _isLoadingAssetTypes
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const VaultWarningBanner(
                                message:
                                    'Do not include sensitive information such as account numbers, passwords, or PIN numbers.',
                              ),
                              const SizedBox(height: 16),
                              AppSecondaryButton(
                                text: 'Select from Will Assets',
                                icon: Icons.list_alt,
                                onPressed: _selectFromWillAssets,
                              ),
                              const SizedBox(height: 24),
                              AppTextField(
                                controller: _nameController,
                                label: 'Name of asset',
                                isRequired: true,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 16),
                              _buildAssetTypeDropdown(),
                              const SizedBox(height: 16),
                              _buildInstitutionDropdown(),
                              const SizedBox(height: 16),
                              _buildLocationDropdown(),
                              const SizedBox(height: 16),
                              AppTextArea(
                                controller: _detailController,
                                label: 'Details',
                                maxLines: 6,
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
                              text: 'Close',
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
        ),
      ),
    );
  }

  Widget _buildAssetTypeDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Type of asset *',
        labelStyle: AppTextStyles.inputLabel,
        floatingLabelStyle: AppTextStyles.inputLabelFloating,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: AppColors.backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AssetTypeItem>(
          value: _selectedAssetType,
          hint: Text('Select asset type', style: AppTextStyles.inputHint),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 20, color: AppColors.textPrimary),
          items: _assetTypes.map((AssetTypeItem type) {
            return DropdownMenuItem<AssetTypeItem>(
              value: type,
              child: Text(type.name, style: AppTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAssetType = value;
              _selectedInstitution = null;
              _institutions = [];
            });
            if (value != null) {
              _loadInstitutions(value.id);
            }
          },
        ),
      ),
    );
  }

  Widget _buildInstitutionDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Institution *',
        labelStyle: AppTextStyles.inputLabel,
        floatingLabelStyle: AppTextStyles.inputLabelFloating,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: AppColors.backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: _isLoadingInstitutions
          ? const Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading institutions...'),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<InstitutionItem>(
                value: _selectedInstitution,
                hint: Text(
                  _selectedAssetType == null
                      ? 'Select asset type first'
                      : 'Select institution',
                  style: AppTextStyles.inputHint,
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: AppColors.textPrimary),
                items: _institutions.map((InstitutionItem institution) {
                  return DropdownMenuItem<InstitutionItem>(
                    value: institution,
                    child:
                        Text(institution.name, style: AppTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: _selectedAssetType != null
                    ? (value) {
                        setState(() {
                          _selectedInstitution = value;
                        });
                      }
                    : null,
              ),
            ),
    );
  }

  Widget _buildLocationDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Location',
        labelStyle: AppTextStyles.inputLabel,
        floatingLabelStyle: AppTextStyles.inputLabelFloating,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: AppColors.backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocation,
          hint: Text('Select location', style: AppTextStyles.inputHint),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 20, color: AppColors.textPrimary),
          items: FormConstants.countries.map((String country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(country, style: AppTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLocation = value;
            });
          },
        ),
      ),
    );
  }
}
