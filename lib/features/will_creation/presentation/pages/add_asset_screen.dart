import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/will_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';

class AddAssetScreen extends StatefulWidget {
  final WillAsset? existingAsset; // For edit mode

  const AddAssetScreen({super.key, this.existingAsset});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Selected values - now storing objects with UUIDs
  AssetTypeItem? _selectedAssetType;
  InstitutionItem? _selectedInstitution;
  String? _selectedLocation;

  // Data from API
  List<AssetTypeItem> _assetTypes = [];
  List<InstitutionItem> _institutions = [];
  bool _isLoadingAssetTypes = true;
  bool _isLoadingInstitutions = false;

  final SecureStorageService _storageService = SecureStorageService();
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingAsset != null;

  @override
  void initState() {
    super.initState();
    _loadAssetTypes();
    
    if (widget.existingAsset != null) {
      _assetNameController.text = widget.existingAsset!.assetName ?? '';
      _descriptionController.text = widget.existingAsset!.description;
      // Only set location if it exists in the known countries list
      final loc = widget.existingAsset!.location;
      _selectedLocation = (loc != null && FormConstants.countries.contains(loc))
          ? loc
          : null;
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
    _assetNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAssetType == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an asset type')),
      );
      return;
    }

    if (_selectedInstitution == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an institution')),
      );
      return;
    }

    final willId = await _storageService.getWillId();
    if (willId == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Will ID not found')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final assetId = _isEditMode && widget.existingAsset?.id != null 
        ? int.tryParse(widget.existingAsset!.id) 
        : null;

    final request = WillAssetRequest(
      willId: willId,
      assetType: _selectedAssetType!.id,  // Send UUID
      assetName: _assetNameController.text.trim().isEmpty ? null : _assetNameController.text.trim(),
      institution: _selectedInstitution!.id,  // Send UUID
      location: _selectedLocation,
      description: _descriptionController.text,
      assetId: assetId,
    );

    context.read<WillBloc>().add(AddAssetEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listener: (context, state) {
        if (state is AssetTypeCatalogLoaded) {
          setState(() {
            _assetTypes = state.assetTypes;
            _isLoadingAssetTypes = false;
            
            // If editing, find and select the matching asset type
            if (_isEditMode && widget.existingAsset != null) {
              final existingType = widget.existingAsset!.assetType;
              // Try to match by id, identifier, or name (API may return any of these)
              _selectedAssetType = _assetTypes.cast<AssetTypeItem?>().firstWhere(
                (type) => type!.id == existingType || 
                          type.identifier == existingType ||
                          type.name.toLowerCase() == existingType.toLowerCase(),
                orElse: () => null,
              );
              if (_selectedAssetType != null) {
                // Load institutions for the selected type
                _loadInstitutions(_selectedAssetType!.id);
              }
            }
          });
        } else if (state is AssetInstitutionsLoaded) {
          setState(() {
            _institutions = state.institutions;
            _isLoadingInstitutions = false;
            
            // If editing, find and select the matching institution
            if (_isEditMode && widget.existingAsset != null) {
              final existingInstitution = widget.existingAsset!.institution;
              // Try to match by id, identifier, or name (API may return any of these)
              _selectedInstitution = _institutions.cast<InstitutionItem?>().firstWhere(
                (inst) => inst!.id == existingInstitution || 
                          inst.identifier == existingInstitution ||
                          inst.name.toLowerCase() == existingInstitution.toLowerCase(),
                orElse: () => null,
              );
            }
          });
        } else if (state is AssetsLoaded && _isSubmitting) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode ? 'Asset updated successfully' : 'Asset added successfully',
              ),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          context.pop();
        } else if (state is WillError && _isSubmitting) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
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
            _isEditMode ? 'Edit asset' : 'Add assets',
            style: AppTextStyles.sectionTitle,
          ),
          centerTitle: false,
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
                              // Asset Name
                              AppTextField(
                                controller: _assetNameController,
                                label: 'Asset name',
                              ),
                              const SizedBox(height: 24),

                              // Asset Type Dropdown
                              _buildAssetTypeDropdown(),
                              const SizedBox(height: 24),

                              // Institution Dropdown
                              _buildInstitutionDropdown(),
                              const SizedBox(height: 24),

                              // Location Dropdown
                              _buildLocationDropdown(),
                              const SizedBox(height: 24),

                              // Description Field
                              AppTextArea(
                                controller: _descriptionController,
                                label: 'Description',
                                isRequired: false,
                                maxLines: 6,
                                minLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom button
                    AppBottomActionBar(
                      child: AppPrimaryButton(
                        text: _isEditMode ? 'Save changes' : 'Add asset',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AssetTypeItem>(
          value: _selectedAssetType,
          hint: Text('Select asset type', style: AppTextStyles.inputHint),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textPrimary),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textPrimary),
                items: _institutions.map((InstitutionItem institution) {
                  return DropdownMenuItem<InstitutionItem>(
                    value: institution,
                    child: Text(institution.name, style: AppTextStyles.bodyMedium),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (_selectedLocation != null && FormConstants.countries.contains(_selectedLocation))
              ? _selectedLocation
              : null,
          hint: Text('Select location', style: AppTextStyles.inputHint),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textPrimary),
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
