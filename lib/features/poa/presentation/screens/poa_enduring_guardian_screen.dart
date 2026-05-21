import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../data/models/poa_models.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_steps_sidebar.dart';
import 'poa_attorneys_screen.dart';

class PoaEnduringGuardianScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaEnduringGuardianScreen({super.key, required this.flowData});

  @override
  State<PoaEnduringGuardianScreen> createState() =>
      _PoaEnduringGuardianScreenState();
}

class _PoaEnduringGuardianScreenState
    extends State<PoaEnduringGuardianScreen> {
  List<PoaPersonData> _guardians = [];
  final _poaService = PoaService();
  List<RecipientInfo> _previousPeople = [];
  bool _isLoading = true;
  bool _isOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadGuardians();
    _loadPreviousPeople();
  }

  Future<void> _loadGuardians() async {
    setState(() => _isLoading = true);
    final guardians =
        await _poaService.getAttorneysByType(AttorneyType.ENDURING_GUARDIAN);
    if (!mounted) return;
    setState(() {
      _guardians = guardians;
      _isLoading = false;
    });
  }

  Future<void> _loadPreviousPeople() async {
    final persons = await _poaService.getWillPeople();
    if (!mounted) return;
    setState(() {
      _previousPeople = persons
          .where((p) =>
              (p['first_name'] != null || p['full_name'] != null))
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
          })
          .toList();
    });
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

  PoaFlowData _collectCurrentData() {
    return widget.flowData
        .copyWith(enduringGuardians: List.from(_guardians));
  }

  void _handleNext() {
    final updated = _collectCurrentData();
    context.push(AppRouter.poaSubstituteEnduringGuardian, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PoaStepsSidebar(currentStep: 1),
      appBar: WillCreationAppBar(
        currentStep: 1,
        totalSteps: 6,
        showStepNumber: false,
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enduring Guardian(s)',
                              style: AppTextStyles.pageTitle),
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
                                  onTap: _isOperationInProgress
                                      ? null
                                      : _showSelectPreviousSheet,
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

                                if (_guardians.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ..._guardians.asMap().entries.map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: PoaPersonCard(
                                        person: entry.value,
                                        onEdit: _isOperationInProgress
                                            ? () {}
                                            : () =>
                                                _editGuardian(entry.key),
                                        onDelete: _isOperationInProgress
                                            ? () {}
                                            : () =>
                                                _removeGuardian(entry.key),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                                AppPrimaryButton(
                                  text: '+ Add Enduring Guardian',
                                  onPressed: _isOperationInProgress
                                      ? null
                                      : _addGuardian,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            PoaBottomBar(
              onPrevious: () => context.pop(_collectCurrentData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
