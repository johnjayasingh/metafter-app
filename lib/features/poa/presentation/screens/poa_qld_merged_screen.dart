import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../data/models/poa_models.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_steps_sidebar.dart';
import 'poa_attorneys_screen.dart';

enum _CommencementType { incapacity, immediately, other }

class PoaQldMergedScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaQldMergedScreen({super.key, required this.flowData});

  @override
  State<PoaQldMergedScreen> createState() => _PoaQldMergedScreenState();
}

class _PoaQldMergedScreenState extends State<PoaQldMergedScreen> {
  final PoaService _poaService = PoaService();
  bool _isOperationInProgress = false;

  // ── Matters ──
  late List<String> _selectedMatters;

  // ── Attorneys ──
  List<PoaPersonData> _attorneys = [];
  List<PoaPersonData> _successive = [];
  List<PoaPersonData> _guardians = [];
  List<PoaPersonData> _substitutes = [];
  List<RecipientInfo> _previousPeople = [];

  // ── Commencement ──
  late _CommencementType _commencementSelected;
  late TextEditingController _commencementOtherController;

  // ── Views & wishes ──
  late TextEditingController _importantThingsController;
  late TextEditingController _culturalValuesController;
  late TextEditingController _nearingDeathController;
  late TextEditingController _excludedPeopleController;
  late TextEditingController _directionsController;

  // ── Terms & instructions ──
  late bool _hasTerms;
  late TextEditingController _termsController;

  @override
  void initState() {
    super.initState();

    // Matters
    _selectedMatters = List<String>.from(widget.flowData.matters);
    if (_selectedMatters.isEmpty) {
      _selectedMatters.add('PERSONAL_HEALTH');
    }

    // Attorneys
    _loadAttorneys();
    _loadSuccessiveAttorneys();
    _loadGuardians();
    _loadSubstitutes();
    _loadPreviousPeople();

    // Commencement
    switch (widget.flowData.commencementType) {
      case 'IMMEDIATELY':
        _commencementSelected = _CommencementType.immediately;
        break;
      case 'OTHER':
        _commencementSelected = _CommencementType.other;
        break;
      default:
        _commencementSelected = _CommencementType.incapacity;
    }
    _commencementOtherController =
        TextEditingController(text: widget.flowData.commencementOther ?? '');

    // Views & wishes — prefill from preferences if available
    _importantThingsController =
        TextEditingController(text: widget.flowData.preferences ?? '');
    _culturalValuesController = TextEditingController();
    _nearingDeathController = TextEditingController();
    _excludedPeopleController = TextEditingController();
    _directionsController =
        TextEditingController(text: widget.flowData.directions ?? '');

    // Terms & instructions
    _hasTerms = widget.flowData.hasTermsInstructions ?? true;
    _termsController =
        TextEditingController(text: widget.flowData.termsInstructions ?? '');
  }

  @override
  void dispose() {
    _commencementOtherController.dispose();
    _importantThingsController.dispose();
    _culturalValuesController.dispose();
    _nearingDeathController.dispose();
    _excludedPeopleController.dispose();
    _directionsController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  // ── Matters ────────────────────────────────────────────────────────────────

  void _toggleMatter(String matter) {
    setState(() {
      _selectedMatters
        ..clear()
        ..add(matter);
    });
  }

  // ── Attorney loading ───────────────────────────────────────────────────────

  Future<void> _loadAttorneys() async {
    final attorneys = await _poaService.getAttorneysByType(AttorneyType.PRIMARY);
    if (!mounted) return;
    setState(() => _attorneys = attorneys);
  }

  Future<void> _loadSuccessiveAttorneys() async {
    final attorneys = await _poaService.getAttorneysByType(AttorneyType.SUCCESSIVE);
    if (!mounted) return;
    setState(() => _successive = attorneys);
  }

  Future<void> _loadGuardians() async {
    final guardians =
        await _poaService.getAttorneysByType(AttorneyType.ENDURING_GUARDIAN);
    if (!mounted) return;
    setState(() => _guardians = guardians);
  }

  Future<void> _loadSubstitutes() async {
    final substitutes = await _poaService
        .getAttorneysByType(AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN);
    if (!mounted) return;
    setState(() => _substitutes = substitutes);
  }

  Future<void> _loadPreviousPeople() async {
    final results = await Future.wait([
      _poaService.getWillPeople(),
      _poaService.getAttorneysForPoa(),
    ]);
    if (!mounted) return;

    final willPersons = results[0] as List<Map<String, dynamic>>;
    final poaAttorneys = results[1] as List<PoaPersonData>;

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

    for (final a in poaAttorneys) {
      final key =
          '${a.firstName.toLowerCase()}_${a.lastName.toLowerCase()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      combined.add(RecipientInfo(
        id: a.id,
        firstName: a.firstName,
        middleName: a.middleName,
        lastName: a.lastName,
        email: a.email,
        mobile: a.phone,
        address: a.address,
      ));
    }

    setState(() => _previousPeople = combined);
  }

  // ── Primary Attorney CRUD ──────────────────────────────────────────────────

  Future<void> _showSelectPreviousSheet() async {
    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: _previousPeople,
        title: 'Select previously added',
        subtitle: 'Select from previously added persons',
        emptyMessage: 'No previously added persons found.\nTap "+ Add Attorney" to add one.',
      ),
    );
    if (selected != null && mounted) {
      final person = PoaPersonData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        role: 'Attorney',
        email: selected.email,
        phone: selected.mobile,
        relation: selected.relation,
        address: selected.address,
      );
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        person,
        type: AttorneyType.PRIMARY,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadAttorneys();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty ? response.message : 'Failed to add attorney',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _addAttorney() async {
    final result = await context.push<PoaPersonData>(AppRouter.poaAddAttorney);
    if (result != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        result,
        type: AttorneyType.PRIMARY,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadAttorneys();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty ? response.message : 'Failed to add attorney',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _editAttorney(int index) async {
    final updated = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: _attorneys[index],
    );
    if (updated != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = updated.attorneyId != null
          ? await _poaService.updateAttorneyForPoa(updated, type: AttorneyType.PRIMARY)
          : await _poaService.createAttorneyForPoa(updated, type: AttorneyType.PRIMARY);
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadAttorneys();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty ? response.message : 'Failed to update attorney',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _removeAttorney(int index) async {
    final attorney = _attorneys[index];
    if (attorney.attorneyPoaId == null) {
      setState(() => _attorneys.removeAt(index));
      return;
    }
    setState(() => _isOperationInProgress = true);
    final response = await _poaService.deleteAttorneyForPoa(attorney.attorneyPoaId!);
    if (!mounted) return;
    if (response.isSuccess) {
      await _loadAttorneys();
    } else {
      SnackBarUtils.showError(context, 'Failed to remove attorney');
    }
    setState(() => _isOperationInProgress = false);
  }

  // ── Successive Attorney CRUD ───────────────────────────────────────────────

  Future<void> _showSelectPreviousSheetForSuccessive() async {
    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: _previousPeople,
        title: 'Select previously added',
        subtitle: 'Select from previously added persons',
        emptyMessage:
            'No previously added persons found.\nTap "+ Add Successive attorney" to add one.',
      ),
    );
    if (selected != null && mounted) {
      final person = PoaPersonData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        role: 'Successive Attorney',
        email: selected.email,
        phone: selected.mobile,
        relation: selected.relation,
        address: selected.address,
      );
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        person,
        type: AttorneyType.SUCCESSIVE,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadSuccessiveAttorneys();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add successive attorney',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _addSuccessive() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: PoaPersonData(
        id: '',
        firstName: '',
        lastName: '',
        role: 'Successive Attorney',
      ),
    );
    if (result != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        result,
        type: AttorneyType.SUCCESSIVE,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadSuccessiveAttorneys();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add successive attorney',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _editSuccessive(int index) async {
    final updated = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: _successive[index],
    );
    if (updated != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = updated.attorneyId != null
          ? await _poaService.updateAttorneyForPoa(
              updated,
              type: AttorneyType.SUCCESSIVE,
            )
          : await _poaService.createAttorneyForPoa(
              updated,
              type: AttorneyType.SUCCESSIVE,
            );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadSuccessiveAttorneys();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update successive attorney',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _removeSuccessive(int index) async {
    final attorney = _successive[index];
    if (attorney.attorneyPoaId == null) {
      setState(() => _successive.removeAt(index));
      return;
    }
    setState(() => _isOperationInProgress = true);
    final response =
        await _poaService.deleteAttorneyForPoa(attorney.attorneyPoaId!);
    if (!mounted) return;
    if (response.isSuccess) {
      await _loadSuccessiveAttorneys();
    } else {
      SnackBarUtils.showError(context, 'Failed to remove successive attorney');
    }
    setState(() => _isOperationInProgress = false);
  }

  // ── Enduring Guardian CRUD ─────────────────────────────────────────────────

  Future<void> _showSelectPreviousSheetForGuardian() async {
    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: _previousPeople,
        title: 'Select previously added',
        subtitle: 'Select from previously added persons',
        emptyMessage:
            'No previously added persons found.\nTap "+ Add Enduring Guardian" to add one.',
      ),
    );
    if (selected != null && mounted) {
      final person = PoaPersonData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        role: 'Enduring Guardian',
        email: selected.email,
        phone: selected.mobile,
        relation: selected.relation,
        address: selected.address,
      );
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        person,
        type: AttorneyType.ENDURING_GUARDIAN,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadGuardians();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add enduring guardian',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _addGuardian() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: PoaPersonData(
        id: '',
        firstName: '',
        lastName: '',
        role: 'Enduring Guardian',
      ),
    );
    if (result != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        result,
        type: AttorneyType.ENDURING_GUARDIAN,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadGuardians();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add enduring guardian',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _editGuardian(int index) async {
    final updated = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: _guardians[index],
    );
    if (updated != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = updated.attorneyId != null
          ? await _poaService.updateAttorneyForPoa(
              updated,
              type: AttorneyType.ENDURING_GUARDIAN,
            )
          : await _poaService.createAttorneyForPoa(
              updated,
              type: AttorneyType.ENDURING_GUARDIAN,
            );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadGuardians();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update enduring guardian',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _removeGuardian(int index) async {
    final guardian = _guardians[index];
    if (guardian.attorneyPoaId == null) {
      setState(() => _guardians.removeAt(index));
      return;
    }
    setState(() => _isOperationInProgress = true);
    final response =
        await _poaService.deleteAttorneyForPoa(guardian.attorneyPoaId!);
    if (!mounted) return;
    if (response.isSuccess) {
      await _loadGuardians();
    } else {
      SnackBarUtils.showError(context, 'Failed to remove enduring guardian');
    }
    setState(() => _isOperationInProgress = false);
  }

  // ── Substitute Enduring Guardian CRUD ──────────────────────────────────────

  Future<void> _showSelectPreviousSheetForSubstitute() async {
    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: _previousPeople,
        title: 'Select previously added',
        subtitle: 'Select from previously added persons',
        emptyMessage:
            'No previously added persons found.\nTap "+ Add Substitute" to add one.',
      ),
    );
    if (selected != null && mounted) {
      final person = PoaPersonData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        role: 'Substitute Enduring Guardian',
        email: selected.email,
        phone: selected.mobile,
        relation: selected.relation,
        address: selected.address,
      );
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        person,
        type: AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadSubstitutes();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add substitute enduring guardian',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _addSubstitute() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: PoaPersonData(
        id: '',
        firstName: '',
        lastName: '',
        role: 'Substitute Enduring Guardian',
      ),
    );
    if (result != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        result,
        type: AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadSubstitutes();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add substitute enduring guardian',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _editSubstitute(int index) async {
    final updated = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: _substitutes[index],
    );
    if (updated != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = updated.attorneyId != null
          ? await _poaService.updateAttorneyForPoa(
              updated,
              type: AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN,
            )
          : await _poaService.createAttorneyForPoa(
              updated,
              type: AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN,
            );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadSubstitutes();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update substitute enduring guardian',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _removeSubstitute(int index) async {
    final substitute = _substitutes[index];
    if (substitute.attorneyPoaId == null) {
      setState(() => _substitutes.removeAt(index));
      return;
    }
    setState(() => _isOperationInProgress = true);
    final response =
        await _poaService.deleteAttorneyForPoa(substitute.attorneyPoaId!);
    if (!mounted) return;
    if (response.isSuccess) {
      await _loadSubstitutes();
    } else {
      SnackBarUtils.showError(
          context, 'Failed to remove substitute enduring guardian');
    }
    setState(() => _isOperationInProgress = false);
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  PoaFlowData _collectCurrentData() {
    // Commencement
    String typeKey;
    switch (_commencementSelected) {
      case _CommencementType.immediately:
        typeKey = 'IMMEDIATELY';
        break;
      case _CommencementType.other:
        typeKey = 'OTHER';
        break;
      default:
        typeKey = 'INCAPACITY';
    }

    // Views & wishes — combine the 4 text areas into preferences
    final hasContent = _importantThingsController.text.trim().isNotEmpty ||
        _culturalValuesController.text.trim().isNotEmpty ||
        _nearingDeathController.text.trim().isNotEmpty ||
        _excludedPeopleController.text.trim().isNotEmpty;

    // Combine the views/wishes into a single preferences text for the API
    final preferencesParts = <String>[];
    if (_importantThingsController.text.trim().isNotEmpty) {
      preferencesParts.add(_importantThingsController.text.trim());
    }
    if (_culturalValuesController.text.trim().isNotEmpty) {
      preferencesParts.add(_culturalValuesController.text.trim());
    }
    if (_nearingDeathController.text.trim().isNotEmpty) {
      preferencesParts.add(_nearingDeathController.text.trim());
    }
    if (_excludedPeopleController.text.trim().isNotEmpty) {
      preferencesParts.add(_excludedPeopleController.text.trim());
    }
    final preferencesText = preferencesParts.join('\n\n');

    return widget.flowData.copyWith(
      // Matters
      matters: List.from(_selectedMatters),
      // Attorneys
      attorneys: List.from(_attorneys),
      successiveAttorneys: List.from(_successive),
      enduringGuardians: List.from(_guardians),
      substituteEnduringGuardians: List.from(_substitutes),
      // Commencement
      commencementType: typeKey,
      commencementOther: _commencementSelected == _CommencementType.other
          ? _commencementOtherController.text.trim()
          : null,
      // Views & wishes → mapped to has_preference / preferences for API
      hasViewsWishes: hasContent,
      hasPreference: hasContent ? 'yes' : 'no',
      preferences: hasContent ? preferencesText : null,
      directions: _directionsController.text.trim(),
      // Terms & instructions
      hasTermsInstructions: _hasTerms,
      termsInstructions: _hasTerms ? _termsController.text.trim() : null,
    );
  }

  void _handleNext() {
    final updated = _collectCurrentData();
    context.push(AppRouter.poaQldFinal, extra: updated);
  }

  // ── Attorney card builder ──────────────────────────────────────────────────

  Widget _buildAttorneyCard({
    required String instructionText,
    required VoidCallback onSelectPrevious,
    required List<PoaPersonData> persons,
    required Future<void> Function(int) onEdit,
    required Future<void> Function(int) onDelete,
    required String addButtonText,
    required VoidCallback onAdd,
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
            instructionText,
            style: AppTextStyles.instructionSmall,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isOperationInProgress ? null : onSelectPrevious,
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
          if (persons.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...persons.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PoaPersonCard(
                  person: entry.value,
                  onEdit: _isOperationInProgress
                      ? () {}
                      : () => onEdit(entry.key),
                  onDelete: _isOperationInProgress
                      ? () {}
                      : () => onDelete(entry.key),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppPrimaryButton(
            text: addButtonText,
            onPressed: _isOperationInProgress ? null : onAdd,
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: 3,
        title: 'Enduring power of attorney',
        enableDrawer: true,
        exitTitle: 'Exit power of attorney?',
        exitDescription:
            'Your progress will be lost. You can start a new power of attorney at any time.',
        exitDiscardButtonText: 'Exit POA',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 4),
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
                    // ── Attorney(s) section ──
                    Text('Attorney(s)', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    _buildAttorneyCard(
                      instructionText: 'Your selection will show up here',
                      onSelectPrevious: _showSelectPreviousSheet,
                      persons: _attorneys,
                      onEdit: _editAttorney,
                      onDelete: _removeAttorney,
                      addButtonText: '+ Add Attorney',
                      onAdd: _addAttorney,
                    ),

                    // ── Matters section ──
                    const SizedBox(height: 32),
                    Text('Matters', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    RadioListOption(
                      isSelected: _selectedMatters.contains('PERSONAL_HEALTH'),
                      title: 'Personal (including health) matters',
                      subtitle:
                          'Personal matter relate to personal and lifestyle decisions this includes decisions about support services where and with whom you live health care and legal matters that do not relate to your financial or property matters',
                      onTap: () => _toggleMatter('PERSONAL_HEALTH'),
                    ),
                    const SizedBox(height: 12),

                    RadioListOption(
                      isSelected: _selectedMatters.contains('FINANCIAL'),
                      title: 'Financial matters',
                      subtitle:
                          'Financial matter relate to your financial or property affairs including paying expenses making investments selling property carrying on a business',
                      onTap: () => _toggleMatter('FINANCIAL'),
                    ),

                    // ── Commencement section ──
                    const SizedBox(height: 32),
                    Text(
                      'Commencement for financial matters',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 24),

                    RadioListOption(
                      isSelected:
                          _commencementSelected == _CommencementType.incapacity,
                      title:
                          'When i do not have capacity to make decisions for financial matters',
                      onTap: () => setState(
                          () => _commencementSelected = _CommencementType.incapacity),
                    ),
                    const SizedBox(height: 12),

                    RadioListOption(
                      isSelected:
                          _commencementSelected == _CommencementType.immediately,
                      title: 'Immediately',
                      onTap: () => setState(
                          () => _commencementSelected = _CommencementType.immediately),
                    ),
                    const SizedBox(height: 12),

                    RadioListOption(
                      isSelected:
                          _commencementSelected == _CommencementType.other,
                      title: 'Others',
                      onTap: () => setState(
                          () => _commencementSelected = _CommencementType.other),
                    ),

                    if (_commencementSelected == _CommencementType.other) ...[
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _commencementOtherController,
                        label:
                            'Please specify when your attorney can start making financial decisions',
                        maxLines: 4,
                      ),
                    ],

                    // ── Views, wishes and preferences section ──
                    const SizedBox(height: 32),
                    Text(
                      'Your views, wishes and preferences',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(optional)',
                      style: AppTextStyles.subtitle.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),

                    AppTextArea(
                      controller: _importantThingsController,
                      label: 'These things are important to me',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),

                    AppTextArea(
                      controller: _culturalValuesController,
                      label:
                          'These are the cultural, religious or spiritual values, rituals or beliefs I would like considered in my health care',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),

                    AppTextArea(
                      controller: _nearingDeathController,
                      label:
                          'When I am nearing death, the following would be important to me and would comfort me: (e.g. you may prefer to die at home or you may like a certain type of music played)',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),

                    AppTextArea(
                      controller: _excludedPeopleController,
                      label:
                          'I would prefer these people not be involved in discussions about my health care',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    // ── Terms & instructions section ──
                    const SizedBox(height: 32),
                    Text(
                      'Terms and instructions of your attorney',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Would you like to set terms or limits on your attorney\'s power and/or give specific instructions that your attorney must follow?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _hasTerms,
                            label: 'Yes',
                            onTap: () => setState(() => _hasTerms = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_hasTerms,
                            label: 'No',
                            onTap: () => setState(() => _hasTerms = false),
                          ),
                        ),
                      ],
                    ),

                    if (_hasTerms) ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _termsController,
                        label: 'Instructions',
                        minLines: 6,
                        maxLines: 10,
                      ),
                    ],

                    // ── Successive Attorney(s) section ──
                    const SizedBox(height: 32),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Successive attorney(s) ',
                          style: AppTextStyles.pageTitle,
                        ),
                        Text(
                          '(optional)',
                          style: AppTextStyles.pageTitle.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildAttorneyCard(
                      instructionText: 'Your selection will show up here',
                      onSelectPrevious: _showSelectPreviousSheetForSuccessive,
                      persons: _successive,
                      onEdit: _editSuccessive,
                      onDelete: _removeSuccessive,
                      addButtonText: '+ Add Successive attorney',
                      onAdd: _addSuccessive,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: () => context.pop(_collectCurrentData()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Next step',
                        onPressed: _handleNext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
