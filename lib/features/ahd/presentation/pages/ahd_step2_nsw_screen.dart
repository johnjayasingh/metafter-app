import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../../poa/data/services/poa_service.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD NSW Step 2 — Enduring guardian
///
/// API fields:
///   - is_enduring_guardian_appointed (bool)
///   - ahd_persons: person_type=ENDURING_GUARDIAN
class AhdStep2NswScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep2NswScreen({super.key, required this.flowData});

  @override
  State<AhdStep2NswScreen> createState() => _AhdStep2NswScreenState();
}

class _AhdStep2NswScreenState extends State<AhdStep2NswScreen> {
  final PoaService _poaService = PoaService();

  late bool? _hasEnduringGuardian;
  late final List<AhdAttorneyData> _enduringGuardians;
  List<RecipientInfo> _previousPeople = [];

  @override
  void initState() {
    super.initState();
    _hasEnduringGuardian = widget.flowData.nswHasEnduringGuardian;
    _enduringGuardians = List.from(widget.flowData.nswEnduringGuardians);
    _loadPreviousPeople();
  }

  Future<void> _loadPreviousPeople() async {
    final willPersons = await _poaService.getWillPeople();
    if (!mounted) return;

    final List<RecipientInfo> combined = [];
    final Set<String> seen = {};

    for (final p in willPersons) {
      if (p['first_name'] == null && p['full_name'] == null) continue;
      final firstName = p['first_name'] as String? ?? '';
      final lastName = p['last_name'] as String? ?? '';
      final key = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      combined.add(RecipientInfo(
        id: p['id']?.toString() ?? '',
        firstName: firstName,
        middleName: p['middle_name'] as String?,
        lastName: lastName,
        email: p['email'] as String?,
        mobile: p['phone'] as String?,
        address: p['address'] as String?,
      ));
    }

    setState(() => _previousPeople = combined);
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
        emptyMessage: 'No previously added persons found.',
      ),
    );
    if (selected != null && mounted) {
      final person = AhdAttorneyData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        email: selected.email,
        phone: selected.mobile,
        address: selected.address,
      );
      setState(() => _enduringGuardians.add(person));
    }
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      nswHasEnduringGuardian: _hasEnduringGuardian,
      nswEnduringGuardians: List.from(_enduringGuardians),
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(2), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  Future<void> _addEnduringGuardian() async {
    final result =
        await context.push<AhdAttorneyData>(AppRouter.ahdAddAttorney);
    if (result != null) {
      setState(() => _enduringGuardians.add(result));
    }
  }

  void _removeEnduringGuardian(int index) {
    setState(() => _enduringGuardians.removeAt(index));
  }

  Future<void> _editEnduringGuardian(int index) async {
    final result = await context.push<AhdAttorneyData>(
      AppRouter.ahdAddAttorney,
      extra: _enduringGuardians[index],
    );
    if (result != null) {
      setState(() => _enduringGuardians[index] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: config.totalSteps,
        title: 'Enduring guardian',
        enableDrawer: true,
        exitTitle: 'Exit advance health directive?',
        exitDescription:
            'Your progress will be lost. You can start a new advance health directive at any time.',
        exitDiscardButtonText: 'Exit AHD',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 5),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enduring guardian',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'I have legally appointed one or more people as my Enduring Guardian/s and they are aware of this Advance Care Directive',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 16),
                    RadioListOption(
                      isSelected: _hasEnduringGuardian == true,
                      title: 'Yes',
                      onTap: () => setState(
                          () => _hasEnduringGuardian = true),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _hasEnduringGuardian == false,
                      title: 'No',
                      onTap: () => setState(
                          () => _hasEnduringGuardian = false),
                    ),

                    if (_hasEnduringGuardian == true) ...[
                      const SizedBox(height: 24),
                      _buildAttorneySection(
                        attorneys: _enduringGuardians,
                        onAdd: _addEnduringGuardian,
                        onEdit: _editEnduringGuardian,
                        onRemove: _removeEnduringGuardian,
                        onSelectPrevious: _showSelectPreviousSheet,
                        roleLabel: 'Enduring guardian',
                        addLabel: '+ Add enduring guardian',
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            AhdBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttorneySection({
    required List<AhdAttorneyData> attorneys,
    required VoidCallback onAdd,
    required Future<void> Function(int) onEdit,
    required void Function(int) onRemove,
    required VoidCallback onSelectPrevious,
    required String roleLabel,
    required String addLabel,
  }) {
    return Container(
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
          InkWell(
            onTap: onSelectPrevious,
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
          if (attorneys.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...attorneys.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NswPersonCard(
                  person: entry.value,
                  roleLabel: roleLabel,
                  onEdit: () => onEdit(entry.key),
                  onDelete: () => onRemove(entry.key),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppPrimaryButton(
            text: addLabel,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

/// Reusable person card for NSW AHD screens.
class NswPersonCard extends StatelessWidget {
  final AhdAttorneyData person;
  final String roleLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NswPersonCard({
    super.key,
    required this.person,
    required this.roleLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              person.initials,
              style: AppTextStyles.bodyMedium.copyWith(
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
                Text(person.fullName, style: AppTextStyles.itemLabel),
                Text(roleLabel, style: AppTextStyles.cardSecondary),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
