import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../../poa/data/services/poa_service.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';
import 'ahd_step2_nsw_screen.dart';

/// AHD NSW Step 6 — Person responsible
///
/// API fields (in ahd_persons):
///   - MEDICAL_GUARDIAN: full_name, dob, phone, address
class AhdStep6NswScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep6NswScreen({super.key, required this.flowData});

  @override
  State<AhdStep6NswScreen> createState() => _AhdStep6NswScreenState();
}

class _AhdStep6NswScreenState extends State<AhdStep6NswScreen> {
  final PoaService _poaService = PoaService();

  late final List<AhdAttorneyData> _personsResponsible;
  List<RecipientInfo> _previousPeople = [];

  @override
  void initState() {
    super.initState();
    _personsResponsible = List.from(widget.flowData.nswPersonsResponsible);
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
      setState(() => _personsResponsible.add(person));
    }
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      nswPersonsResponsible: List.from(_personsResponsible),
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(3), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  Future<void> _addPersonResponsible() async {
    final result =
        await context.push<AhdAttorneyData>(AppRouter.ahdAddAttorney);
    if (result != null) {
      setState(() => _personsResponsible.add(result));
    }
  }

  void _removePersonResponsible(int index) {
    setState(() => _personsResponsible.removeAt(index));
  }

  Future<void> _editPersonResponsible(int index) async {
    final result = await context.push<AhdAttorneyData>(
      AppRouter.ahdAddAttorney,
      extra: _personsResponsible[index],
    );
    if (result != null) {
      setState(() => _personsResponsible[index] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: config.totalSteps,
        title: 'Person responsible',
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
                    Text('Person responsible',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'If, because of my medical condition, I am not able to understand and make decisions about my treatment or can\'t tell the doctors or my family, my Person Responsible as determined according to the hierarchy within the NSW Guardianship Act (1987) is',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 24),

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
                          InkWell(
                            onTap: _showSelectPreviousSheet,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.borderGray),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                          if (_personsResponsible.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ..._personsResponsible.asMap().entries.map(
                              (entry) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: NswPersonCard(
                                  person: entry.value,
                                  roleLabel: 'Person responsible',
                                  onEdit: () =>
                                      _editPersonResponsible(entry.key),
                                  onDelete: () =>
                                      _removePersonResponsible(
                                          entry.key),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          AppPrimaryButton(
                            text: '+ Add Person responsible',
                            onPressed: _addPersonResponsible,
                          ),
                        ],
                      ),
                    ),
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
}
