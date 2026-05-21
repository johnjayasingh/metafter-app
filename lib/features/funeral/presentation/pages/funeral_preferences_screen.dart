import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/funeral_models.dart';
import '../../data/models/funeral_flow_data.dart';
import '../../data/services/funeral_service.dart';

class FuneralPreferencesScreen extends StatefulWidget {
  final FuneralFlowData? existingData;

  const FuneralPreferencesScreen({super.key, this.existingData});

  @override
  State<FuneralPreferencesScreen> createState() =>
      _FuneralPreferencesScreenState();
}

class _FuneralPreferencesScreenState extends State<FuneralPreferencesScreen> {
  final FuneralService _funeralService = FuneralService();
  late FuneralFlowData _flowData;
  FuneralPreference? _selectedPreference;
  bool _isSaving = false;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Sub-field controllers
  final _ashesDisposalController = TextEditingController();
  final _specificRitesController = TextEditingController();
  final _cemeteryNameController = TextEditingController();
  final _placeOfWorshipController = TextEditingController();
  final _donationNotAcceptedController = TextEditingController();

  // Dropdown state
  Religion? _selectedReligion;

  // Direction person state (direction_by list)
  List<DirectionPerson> _directionBy = [];

  // Will people for selection
  List<WillPerson> _willPeople = [];

  // Science donation institutions
  List<ScienceDonationInstitution> _scienceInstitutions = [];
  String? _selectedUniversityId;
  bool _isLoadingInstitutions = false;

  @override
  void initState() {
    super.initState();
    _flowData = widget.existingData ?? FuneralFlowData();
    _selectedPreference = _flowData.funeralPreference;

    // Populate from existing preference data
    final prefData = _flowData.funeralPreferenceData;
    if (prefData != null) {
      _ashesDisposalController.text = prefData.ashDisposalInstruction ?? '';
      _specificRitesController.text = prefData.specificRite ?? '';
      _cemeteryNameController.text = prefData.cemeteryName ?? '';
      _placeOfWorshipController.text = prefData.placeOfWorship ?? '';
      _donationNotAcceptedController.text =
          prefData.donationNotAcceptedBackup ?? '';
      _selectedReligion = prefData.religion;
      _selectedUniversityId = prefData.universityId;
      if (prefData.directionBy != null) {
        _directionBy = List.from(prefData.directionBy!);
      }
    }

    _loadWillPeople();
    if (_selectedPreference == FuneralPreference.scienceDonation) {
      _loadScienceInstitutions();
    }
  }

  @override
  void dispose() {
    _ashesDisposalController.dispose();
    _specificRitesController.dispose();
    _cemeteryNameController.dispose();
    _placeOfWorshipController.dispose();
    _donationNotAcceptedController.dispose();
    super.dispose();
  }

  Future<void> _loadWillPeople() async {
    final people = await _funeralService.getWillPeople();
    if (!mounted) return;
    setState(() {
      _willPeople = people;
    });
  }

  Future<void> _loadScienceInstitutions() async {
    setState(() => _isLoadingInstitutions = true);
    final institutions =
        await _funeralService.getScienceDonationInstitutions();
    if (!mounted) return;
    setState(() {
      _scienceInstitutions = institutions;
      _isLoadingInstitutions = false;
    });
  }

  void _onPreferenceSelected(FuneralPreference pref) {
    setState(() {
      _selectedPreference = pref;
    });
    if (pref == FuneralPreference.scienceDonation &&
        _scienceInstitutions.isEmpty) {
      _loadScienceInstitutions();
    }
  }

  void _showSelectDirectionPersonSheet() {
    if (_willPeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No family members found')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Select person', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select from family members',
                style: AppTextStyles.subtitle,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _willPeople.length,
                itemBuilder: (context, index) {
                  final person = _willPeople[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.backgroundLightGreen,
                      child: Text(
                        _getInitials(person.displayName),
                        style: AppTextStyles.itemLabel.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(person.displayName,
                        style: AppTextStyles.itemLabel),
                    subtitle: person.email != null
                        ? Text(person.email!,
                            style: AppTextStyles.cardSecondary)
                        : null,
                    onTap: () {
                      final directionPerson = DirectionPerson(
                        firstName: person.firstName,
                        lastName: person.lastName,
                        email: person.email,
                      );
                      setState(() {
                        // Avoid duplicates by email
                        final exists = _directionBy.any((d) =>
                            d.email == directionPerson.email &&
                            d.firstName == directionPerson.firstName);
                        if (!exists) {
                          _directionBy.add(directionPerson);
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewDirectionPerson() async {
    final result = await context.push<dynamic>(
      AppRouter.funeralAddDirectionPerson,
    );
    if (result != null && mounted) {
      // RecipientInfo from the add person screen
      final directionPerson = DirectionPerson(
        firstName: result.firstName,
        lastName: result.lastName,
        email: result.email,
        relation: null,
      );
      setState(() {
        _directionBy.add(directionPerson);
      });
      _loadWillPeople();
    }
  }

  void _removeDirectionPerson(int index) {
    setState(() {
      _directionBy.removeAt(index);
    });
  }

  String? _validatePreferenceFields() {
    switch (_selectedPreference!) {
      case FuneralPreference.cremationReligious:
        if (_selectedReligion == null) return 'Please select a religion';
        break;
      case FuneralPreference.burialReligious:
        if (_selectedReligion == null) return 'Please select a religion';
        if (_cemeteryNameController.text.trim().isEmpty) {
          return 'Please enter a cemetery name';
        }
        break;
      case FuneralPreference.scienceDonation:
        if (_selectedUniversityId == null) {
          return 'Please select a university or institution';
        }
        break;
      case FuneralPreference.cremationNonReligious:
      case FuneralPreference.greenBurial:
      case FuneralPreference.noPreference:
        break;
    }
    return null;
  }

  Future<void> _saveAndContinue() async {
    if (_selectedPreference == null) return;

    // Validate preference-specific fields
    final validationError = _validatePreferenceFields();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Validate form fields (text inputs)
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      _flowData.funeralPreference = _selectedPreference;

      // Build funeral_preference_data based on selected preference
      FuneralPreferenceData? prefData;
      switch (_selectedPreference!) {
        case FuneralPreference.cremationNonReligious:
          prefData = FuneralPreferenceData(
            ashDisposalInstruction:
                _trimOrNull(_ashesDisposalController.text),
            directionBy: _directionBy.isNotEmpty ? _directionBy : null,
          );
          break;
        case FuneralPreference.cremationReligious:
          prefData = FuneralPreferenceData(
            religion: _selectedReligion,
            specificRite: _trimOrNull(_specificRitesController.text),
            ashDisposalInstruction:
                _trimOrNull(_ashesDisposalController.text),
            directionBy: _directionBy.isNotEmpty ? _directionBy : null,
          );
          break;
        case FuneralPreference.burialReligious:
          prefData = FuneralPreferenceData(
            religion: _selectedReligion,
            placeOfWorship: _trimOrNull(_placeOfWorshipController.text),
            cemeteryName: _trimOrNull(_cemeteryNameController.text),
          );
          break;
        case FuneralPreference.scienceDonation:
          prefData = FuneralPreferenceData(
            universityId: _selectedUniversityId,
            donationNotAcceptedBackup:
                _trimOrNull(_donationNotAcceptedController.text),
          );
          break;
        case FuneralPreference.greenBurial:
          prefData = null;
          break;
        case FuneralPreference.noPreference:
          prefData = null;
          break;
      }

      _flowData.funeralPreferenceData = prefData;

      // Save to API
      await _funeralService.createOrUpdateFuneral(_flowData.toFuneralModel());

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        context.push(
          AppRouter.funeralServiceDetails,
          extra: _flowData,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String? _trimOrNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  void _exitAndRefresh() {
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: WillCreationAppBar(
        currentStep: 1,
        totalSteps: 4,
        title: 'Funeral preferences',
        showBackButton: true,
        showStepNumber: true,
        exitTitle: 'Exit funeral preferences?',
        exitDescription:
            'You can save your progress as a draft and continue later, or discard these preferences.',
        exitDiscardButtonText: 'Discard Preferences',
        onExitNavigate: _exitAndRefresh,
        onBack: () {
          context.pop();
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
                    Text(
                      'What are your Funeral preferences',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your preferred funeral arrangement type.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 32),

                    // Option 1: Simple Cremation (Non-Religious)
                    RadioListOption(
                      isSelected: _selectedPreference ==
                          FuneralPreference.cremationNonReligious,
                      title: 'Simple Cremation (Non-Religious)',
                      onTap: () => _onPreferenceSelected(
                          FuneralPreference.cremationNonReligious),
                    ),
                    if (_selectedPreference ==
                        FuneralPreference.cremationNonReligious)
                      _buildCremationNonReligiousFields(),
                    const SizedBox(height: 12),

                    // Option 2: Cremation (Religious/Cultural)
                    RadioListOption(
                      isSelected: _selectedPreference ==
                          FuneralPreference.cremationReligious,
                      title: 'Cremation (Religious/Cultural)',
                      onTap: () => _onPreferenceSelected(
                          FuneralPreference.cremationReligious),
                    ),
                    if (_selectedPreference ==
                        FuneralPreference.cremationReligious)
                      _buildCremationReligiousFields(),
                    const SizedBox(height: 12),

                    // Option 3: Traditional Burial (Religious)
                    RadioListOption(
                      isSelected: _selectedPreference ==
                          FuneralPreference.burialReligious,
                      title: 'Traditional Burial (Religious)',
                      onTap: () => _onPreferenceSelected(
                          FuneralPreference.burialReligious),
                    ),
                    if (_selectedPreference ==
                        FuneralPreference.burialReligious)
                      _buildBurialReligiousFields(),
                    const SizedBox(height: 12),

                    // Option 4: Green / Natural Burial
                    RadioListOption(
                      isSelected: _selectedPreference ==
                          FuneralPreference.greenBurial,
                      title: 'Green / Natural Burial',
                      onTap: () => _onPreferenceSelected(
                          FuneralPreference.greenBurial),
                    ),
                    const SizedBox(height: 12),

                    // Option 5: Donation to Science
                    RadioListOption(
                      isSelected: _selectedPreference ==
                          FuneralPreference.scienceDonation,
                      title: 'Donation to Science',
                      onTap: () => _onPreferenceSelected(
                          FuneralPreference.scienceDonation),
                    ),
                    if (_selectedPreference ==
                        FuneralPreference.scienceDonation)
                      _buildScienceDonationFields(),
                    const SizedBox(height: 12),

                    // Option 6: No Preference / Trustee Discretion
                    RadioListOption(
                      isSelected: _selectedPreference ==
                          FuneralPreference.noPreference,
                      title: 'No Preference / Trustee Discretion',
                      onTap: () => _onPreferenceSelected(
                          FuneralPreference.noPreference),
                    ),
                  ],
                ),
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: AppPrimaryButton(
                  text: _isSaving ? 'Saving...' : 'Next step',
                  onPressed: (_selectedPreference != null && !_isSaving)
                      ? _saveAndContinue
                      : null,
                  fullWidth: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub-field builder methods ---

  Widget _buildCremationNonReligiousFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextArea(
            controller: _ashesDisposalController,
            label: 'Ashes disposal instructions',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildDirectionBySection(),
        ],
      ),
    );
  }

  Widget _buildCremationReligiousFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<String>(
            value: _selectedReligion?.value,
            label: 'Religion Culture',
            isRequired: true,
            items: Religion.values.map((r) => r.value).toList(),
            displayName: (val) => Religion.fromString(val).displayLabel,
            onChanged: (val) => setState(() {
              _selectedReligion = val != null ? Religion.fromString(val) : null;
            }),
          ),
          const SizedBox(height: 16),
          AppTextArea(
            controller: _specificRitesController,
            label: 'Specific rites',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          AppTextArea(
            controller: _ashesDisposalController,
            label: 'Ashes disposal instructions',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildDirectionBySection(),
        ],
      ),
    );
  }

  Widget _buildBurialReligiousFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<String>(
            value: _selectedReligion?.value,
            label: 'Religion Culture',
            isRequired: true,
            items: Religion.values.map((r) => r.value).toList(),
            displayName: (val) => Religion.fromString(val).displayLabel,
            onChanged: (val) => setState(() {
              _selectedReligion = val != null ? Religion.fromString(val) : null;
            }),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _placeOfWorshipController,
            label: 'Place of worship',
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _cemeteryNameController,
            label: 'Cemetery name',
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a cemetery name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScienceDonationFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingInstitutions)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            AppDropdown<String>(
              value: _selectedUniversityId,
              label: 'University or institution',
              isRequired: true,
              items: _scienceInstitutions
                  .map((i) => i.id ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList(),
              displayName: (id) {
                final inst = _scienceInstitutions.firstWhere(
                  (i) => i.id == id,
                  orElse: () =>
                      ScienceDonationInstitution(id: id, name: id),
                );
                return inst.name;
              },
              onChanged: (value) {
                setState(() {
                  _selectedUniversityId = value;
                });
              },
            ),
          const SizedBox(height: 16),
          AppTextArea(
            controller: _donationNotAcceptedController,
            label: 'If the donation is not accepted what should be the cremation be',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionBySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLightGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Under whose direction',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),

            // "Select previously added" row
            InkWell(
              onTap: _showSelectDirectionPersonSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select from family members',
                      style: AppTextStyles.subtitle,
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            // Show selected direction persons
            if (_directionBy.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._directionBy.asMap().entries.map((entry) {
                final index = entry.key;
                final person = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.backgroundLightGreen,
                          child: Text(
                            _getInitials(person.fullName),
                            style: AppTextStyles.itemLabel.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.fullName,
                                style: AppTextStyles.itemLabel,
                              ),
                              if (person.relation != null)
                                Text(
                                  person.relation!,
                                  style: AppTextStyles.cardSecondary.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeDirectionPerson(index),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.close,
                                size: 20, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),
            AppPrimaryButton(
              text: '+ Add new person',
              onPressed: _addNewDirectionPerson,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
