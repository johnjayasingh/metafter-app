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
import 'poa_attorneys_screen.dart';

class PoaSuccessiveAttorneysScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaSuccessiveAttorneysScreen({super.key, required this.flowData});

  @override
  State<PoaSuccessiveAttorneysScreen> createState() =>
      _PoaSuccessiveAttorneysScreenState();
}

class _PoaSuccessiveAttorneysScreenState
    extends State<PoaSuccessiveAttorneysScreen> {
  List<PoaPersonData> _successive = [];
  final _poaService = PoaService();
  List<RecipientInfo> _previousPeople = [];
  bool _isLoading = true;
  bool _isOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadAttorneys();
    _loadPreviousPeople();
  }

  Future<void> _loadAttorneys() async {
    setState(() => _isLoading = true);
    final attorneys =
        await _poaService.getAttorneysByType(AttorneyType.SUCCESSIVE);
    if (!mounted) return;
    setState(() {
      _successive = attorneys;
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
        await _loadAttorneys();
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
        await _loadAttorneys();
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
        await _loadAttorneys();
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
      await _loadAttorneys();
    } else {
      SnackBarUtils.showError(context, 'Failed to remove successive attorney');
    }
    setState(() => _isOperationInProgress = false);
  }

  PoaFlowData _collectCurrentData() {
    return widget.flowData.copyWith(successiveAttorneys: List.from(_successive));
  }

  void _handleNext() {
    final updated = _collectCurrentData();
    context.push(AppRouter.poaEnduringGuardian, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WillCreationAppBar(
        currentStep: 4,
        totalSteps: 9,
        title: 'Enduring power of attorney',
        enableDrawer: false,
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

                          // Selection card
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

                                // Added successive attorneys
                                if (_successive.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ..._successive.asMap().entries.map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: PoaPersonCard(
                                        person: entry.value,
                                        onEdit: _isOperationInProgress
                                            ? () {}
                                            : () =>
                                                _editSuccessive(entry.key),
                                        onDelete: _isOperationInProgress
                                            ? () {}
                                            : () =>
                                                _removeSuccessive(entry.key),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                                AppPrimaryButton(
                                  text: '+ Add Successive attorney',
                                  onPressed: _isOperationInProgress
                                      ? null
                                      : _addSuccessive,
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
