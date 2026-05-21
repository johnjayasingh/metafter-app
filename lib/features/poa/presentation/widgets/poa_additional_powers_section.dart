import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../data/models/poa_models.dart';
import '../../data/services/poa_service.dart';
import '../screens/poa_attorneys_screen.dart';
import 'package:go_router/go_router.dart';

/// Additional powers section for POA Step 2.
///
/// Displays three single-select radio options:
///  - Reasonable gifts
///  - Benefits to attorney
///  - Benefits to selected person (with person management sub-section)
class PoaAdditionalPowersSection extends StatefulWidget {
  /// Currently selected power: 'REASONABLE_GIFTS', 'BENEFIT_TO_ATTORNEY',
  /// 'BENEFIT_TO_SELECTED_PERSON', or null if none selected.
  final String? selectedPower;
  final ValueChanged<String?> onSelectedPowerChanged;
  final ValueChanged<List<PoaPersonData>> onBenefitsPersonsChanged;

  const PoaAdditionalPowersSection({
    super.key,
    required this.selectedPower,
    required this.onSelectedPowerChanged,
    required this.onBenefitsPersonsChanged,
  });

  @override
  State<PoaAdditionalPowersSection> createState() =>
      _PoaAdditionalPowersSectionState();
}

class _PoaAdditionalPowersSectionState
    extends State<PoaAdditionalPowersSection> {
  final PoaService _poaService = PoaService();
  List<PoaPersonData> _benefitsPersons = [];
  List<RecipientInfo> _previousPeople = [];
  final bool _isOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousPeople();
    _loadExistingBenefitsPersons();
  }

  Future<void> _loadPreviousPeople() async {
    final persons = await _poaService.getWillPeople();
    if (!mounted) return;
    setState(() {
      _previousPeople = persons
          .where((p) => (p['first_name'] != null || p['full_name'] != null))
          .map((p) {
        final firstName = p['first_name'] as String? ?? '';
        final middleName = p['middle_name'] as String?;
        final lastName = p['last_name'] as String? ?? '';
        return RecipientInfo(
          id: p['id']?.toString() ?? '',
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          email: p['email'] as String?,
          mobile: p['phone'] as String?,
          address: p['address'] as String?,
        );
      }).toList();
    });
  }

  /// Load existing ADDITIONAL_AUTHORITY attorneys from the API so
  /// benefits persons survive across sessions.
  Future<void> _loadExistingBenefitsPersons() async {
    try {
      final existing = await _poaService
          .getAttorneysByType(AttorneyType.ADDITIONAL_AUTHORITY);
      if (!mounted || existing.isEmpty) return;
      setState(() {
        _benefitsPersons = existing;
      });
      widget.onBenefitsPersonsChanged(_benefitsPersons);
    } catch (_) {
      // Silently ignore — list stays empty
    }
  }

  Future<void> _showSelectPreviousSheet() async {
    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: _previousPeople,
        title: 'Select previously added',
        subtitle: 'Select from previously added persons',
        emptyMessage:
            'No previously added persons found.\nTap "+ Add Person" to add one.',
      ),
    );
    if (selected != null && mounted) {
      final person = PoaPersonData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        role: 'Benefits Person',
        email: selected.email,
        phone: selected.mobile,
        relation: selected.relation,
        address: selected.address,
      );
      // Persist to backend
      await _poaService.createAttorneyForPoa(
        person,
        type: AttorneyType.ADDITIONAL_AUTHORITY,
      );
      // Reload from API to get correct attorneyPoaId for future deletes
      await _loadExistingBenefitsPersons();
    }
  }

  Future<void> _addPerson() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: PoaPersonData(
        id: '',
        firstName: '',
        lastName: '',
        role: 'Benefits Person',
      ),
    );
    if (result != null && mounted) {
      // Persist to backend
      await _poaService.createAttorneyForPoa(
        result,
        type: AttorneyType.ADDITIONAL_AUTHORITY,
      );
      // Reload from API to get correct attorneyPoaId for future deletes
      await _loadExistingBenefitsPersons();
    }
  }

  Future<void> _removePerson(int index) async {
    final person = _benefitsPersons[index];
    // Delete from backend if we have the relationship ID
    if (person.attorneyPoaId != null) {
      await _poaService.deleteAttorneyForPoa(person.attorneyPoaId!);
    }
    setState(() {
      _benefitsPersons = List.from(_benefitsPersons)..removeAt(index);
    });
    widget.onBenefitsPersonsChanged(_benefitsPersons);
  }

  void _selectPower(String power) {
    // Tapping the already-selected option deselects it
    if (widget.selectedPower == power) {
      widget.onSelectedPowerChanged(null);
    } else {
      widget.onSelectedPowerChanged(power);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPersonSection =
        widget.selectedPower == 'BENEFIT_TO_SELECTED_PERSON';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Addition powers', style: AppTextStyles.pageTitle),
        const SizedBox(height: 24),
        RadioListOption(
          isSelected: widget.selectedPower == 'REASONABLE_GIFTS',
          title: 'Reasonable gifts',
          subtitle:
              'Authorise your attorney to make reasonable gifts on your behalf',
          onTap: () => _selectPower('REASONABLE_GIFTS'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: widget.selectedPower == 'BENEFIT_TO_ATTORNEY',
          title: 'Benefits to attorney',
          subtitle:
              'Allow your attorney to benefit from decisions made on your behalf',
          onTap: () => _selectPower('BENEFIT_TO_ATTORNEY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: widget.selectedPower == 'BENEFIT_TO_SELECTED_PERSON',
          title: 'Benefits to selected person',
          subtitle:
              'Allow benefits to be directed to a specific person you nominate',
          onTap: () => _selectPower('BENEFIT_TO_SELECTED_PERSON'),
        ),
        if (showPersonSection) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your selection will show up here',
                  style: AppTextStyles.instructionSmall,
                ),
                const SizedBox(height: 12),

                // Select previously added row
                InkWell(
                  onTap:
                      _isOperationInProgress ? null : _showSelectPreviousSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select previously added',
                          style: AppTextStyles.bodyMedium,
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

                // Person cards
                if (_benefitsPersons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._benefitsPersons.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PoaPersonCard(
                            person: entry.value,
                            onEdit: () {},
                            onDelete: _isOperationInProgress
                                ? () {}
                                : () => _removePerson(entry.key),
                          ),
                        ),
                      ),
                ],

                const SizedBox(height: 12),
                AppPrimaryButton(
                  text: '+ Add Person',
                  onPressed: _isOperationInProgress ? null : _addPerson,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
