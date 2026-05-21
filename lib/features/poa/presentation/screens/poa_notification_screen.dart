import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaNotificationScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaNotificationScreen({super.key, required this.flowData});

  @override
  State<PoaNotificationScreen> createState() => _PoaNotificationScreenState();
}

class _PoaNotificationScreenState extends State<PoaNotificationScreen> {
  late String _notifyWho; // 'ME' | 'NOMINATED_PERSON'
  late TextEditingController _instructionsController;
  late List<PoaPersonData> _notifyPersons;
  late String? _notifyWhatOption;
  late TextEditingController _notifyOtherController;
  final _poaService = PoaService();
  List<RecipientInfo> _previousPeople = [];

  @override
  void initState() {
    super.initState();
    print('🔴 [NotificationScreen] RECEIVED: notifyWho=${widget.flowData.notifyWho}, notifyWhatOption=${widget.flowData.notifyWhatOption}, notifyOther=${widget.flowData.notifyWhatOtherText}, notifyInstr=${widget.flowData.notifyInstructions}');
    _notifyWho = widget.flowData.notifyWho ?? 'ME';
    _instructionsController =
        TextEditingController(text: widget.flowData.notifyInstructions ?? '');
    _notifyPersons = List<PoaPersonData>.from(widget.flowData.notifyPersons);
    _notifyWhatOption = widget.flowData.notifyWhatOption;
    _notifyOtherController =
        TextEditingController(text: widget.flowData.notifyWhatOtherText ?? '');
    _loadPreviousPeople();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _notifyOtherController.dispose();
    super.dispose();
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

  Future<void> _showSelectPersonSheet() async {
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
      setState(() {
        _notifyPersons.add(PoaPersonData(
          id: selected.id,
          firstName: selected.firstName,
          middleName: selected.middleName,
          lastName: selected.lastName,
          role: 'Contact',
          email: selected.email,
          phone: selected.mobile,
          address: selected.address,
        ));
      });
    }
  }

  Future<void> _addPerson() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: PoaPersonData(
        id: '',
        firstName: '',
        lastName: '',
        role: 'Contact',
      ),
    );
    if (result != null) {
      setState(() {
        _notifyPersons.add(
          PoaPersonData(
            id: result.id,
            firstName: result.firstName,
            middleName: result.middleName,
            lastName: result.lastName,
            role: 'Contact',
            email: result.email,
            phone: result.phone,
          ),
        );
      });
    }
  }

  void _removePerson(int index) {
    setState(() {
      _notifyPersons.removeAt(index);
    });
  }

  bool _isSubmitting = false;

  PoaFlowData _collectCurrentData() {
    final notifyOf = _notifyWhatOption ?? 'WRITTEN_NOTICE';
    return widget.flowData.copyWith(
      notifyWho: _notifyWho,
      notifyInstructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      notifyPersons: List.from(_notifyPersons),
      notifyWhatOption: notifyOf,
      notifyWhatOtherText: notifyOf == 'OTHER'
          ? _notifyOtherController.text.trim()
          : null,
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectCurrentData();

    final config = PoaFlowConfig.forState(widget.flowData.state);
    final stateKey = config.stateKey;
    // Notification is the final step for states without a separate
    // assistance signing screen (NT, VIC, etc.)
    final isLastStep = stateKey == 'northern_territory' ||
        stateKey == 'victoria';

    if (isLastStep) {
      await _saveAndFinish(updated);
    } else {
      context.push(AppRouter.poaAssistanceSigning, extra: updated);
    }
  }

  /// Save attorneys (if applicable) and the overall POA, then navigate home.
  Future<void> _saveAndFinish(PoaFlowData finalData) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // Save NT donor (name, address, DOB) via attorney endpoint
      if (finalData.ntDonorFullName != null &&
          finalData.ntDonorFullName!.trim().isNotEmpty) {
        // Delete existing donor to avoid duplicates on re-save
        await _poaService.deleteAttorneysByType(AttorneyType.ATTORNEY_DONOR);

        final (first, middle, last) =
            PoaPersonData.parseFullName(finalData.ntDonorFullName!.trim());

        // Convert display format (DD/MM/YYYY) to API format (YYYY-MM-DD)
        String? apiDob;
        if (finalData.ntDonorDob != null &&
            finalData.ntDonorDob!.trim().isNotEmpty) {
          final parsed = AppDatePickerField.parseDateFromDisplay(
              finalData.ntDonorDob!.trim());
          if (parsed != null) {
            apiDob = AppDatePickerField.formatDateForApi(parsed);
          } else {
            // Already in API format or unknown — pass through
            apiDob = finalData.ntDonorDob!.trim();
          }
        }

        final donorPerson = PoaPersonData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          firstName: first,
          middleName: middle,
          lastName: last,
          address: finalData.ntDonorAddress?.trim(),
          dob: apiDob,
          attorneyType: AttorneyType.ATTORNEY_DONOR,
          role: 'Donor',
        );
        final donorResponse = await _poaService.createAttorneyForPoa(
          donorPerson,
          type: AttorneyType.ATTORNEY_DONOR,
        );
        if (!mounted) return;
        if (donorResponse.isFailure) {
          setState(() => _isSubmitting = false);
          SnackBarUtils.showError(
            context,
            'Failed to save donor details.',
          );
          return;
        }
      }

      // Save NT financial decision makers via attorney endpoint
      if (finalData.ntFinancialDms.isNotEmpty) {
        const dmTypes = [
          AttorneyType.FINANCIAL_DECISION_MAKER_PRIMARY,
          AttorneyType.FINANCIAL_DECISION_MAKER_SECONDARY,
          AttorneyType.FINANCIAL_DECISION_MAKER_TERTIARY,
          AttorneyType.FINANCIAL_DECISION_MAKER_QUATERNARY,
        ];
        for (final t in dmTypes) {
          await _poaService.deleteAttorneysByType(t);
        }
        for (int i = 0;
            i < finalData.ntFinancialDms.length && i < dmTypes.length;
            i++) {
          final dm = finalData.ntFinancialDms[i];
          if (dm.name.trim().isEmpty) continue;
          final (first, middle, last) =
              PoaPersonData.parseFullName(dm.name.trim());
          final dmPerson = PoaPersonData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            firstName: first,
            middleName: middle,
            lastName: last,
            address: dm.address.trim(),
            attorneyType: dmTypes[i],
            role: 'Financial Decision Maker',
          );
          final dmResponse = await _poaService.createAttorneyForPoa(
            dmPerson,
            type: dmTypes[i],
          );
          if (!mounted) return;
          if (dmResponse.isFailure) {
            setState(() => _isSubmitting = false);
            SnackBarUtils.showError(
              context,
              'Failed to save decision maker ${i + 1}.',
            );
            return;
          }
        }
      }

      // Save the overall POA
      final result = await _poaService.createOrUpdatePoa(finalData);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.isSuccess) {
        SnackBarUtils.showSuccess(
          context,
          'Power of attorney created successfully.',
        );
        context.go(AppRouter.home, extra: 4);
      } else {
        SnackBarUtils.showError(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to save power of attorney. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackBarUtils.showError(
        context,
        'An error occurred. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final notificationStep = config.totalSteps - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: notificationStep, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: notificationStep,
        totalSteps: config.totalSteps,
        title: 'Notification for health matters',
        enableDrawer: true,
        exitTitle: 'Exit power of attorney?',
        exitDescription: 'Your progress will be lost. You can start a new power of attorney at any time.',
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
                    Text(
                      'Notification for including health matters',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Who would you like to notify?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 16),

                    // Me / Nominated person
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _notifyWho == 'ME',
                            label: 'Me',
                            onTap: () =>
                                setState(() => _notifyWho = 'ME'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _notifyWho == 'NOMINATED_PERSON',
                            label: 'Nominated person',
                            onTap: () =>
                                setState(() => _notifyWho = 'NOMINATED_PERSON'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Instructions text area - Always visible
                    AppTextArea(
                      controller: _instructionsController,
                      label: '',
                      placeholder: 'Enter your instructions',
                      minLines: 6,
                      maxLines: 10,
                    ),

                    // Persons selection card - Only visible when NOMINATED_PERSON is selected
                    if (_notifyWho == 'NOMINATED_PERSON') ...[
                      const SizedBox(height: 20),
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
                              onTap: _showSelectPersonSheet,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.borderGray),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Select previously added',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                            if (_notifyPersons.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ..._notifyPersons.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _NotifyPersonCard(
                                    person: entry.value,
                                    onDelete: () => _removePerson(entry.key),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            AppPrimaryButton(
                              text: '+ Add persons',
                              onPressed: _addPerson,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // What do you want to notify section
                    Text(
                      'What do you want to notify?',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 16),

                    RadioListOption(
                      isSelected: _notifyWhatOption == 'WRITTEN_NOTICE',
                      title: 'Written notice of intention',
                      onTap: () =>
                          setState(() => _notifyWhatOption = 'WRITTEN_NOTICE'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _notifyWhatOption == 'OTHER',
                      title: 'Other',
                      onTap: () =>
                          setState(() => _notifyWhatOption = 'OTHER'),
                    ),
                    if (_notifyWhatOption == 'OTHER') ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _notifyOtherController,
                        label: '',
                        placeholder: 'Please specify',
                        minLines: 3,
                        maxLines: 6,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            _PoaBottomBar(
              onPrevious: () => context.pop(_collectCurrentData()),
              onNext: _handleNext,
              nextLabel: (config.stateKey == 'northern_territory' ||
                      config.stateKey == 'victoria')
                  ? 'Save'
                  : 'Next step',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notify person card ─────────────────────────────────────────────────────

class _NotifyPersonCard extends StatelessWidget {
  final PoaPersonData person;
  final VoidCallback onDelete;

  const _NotifyPersonCard({required this.person, required this.onDelete});

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
                Text(person.role, style: AppTextStyles.cardSecondary),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline,
                  size: 20, color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ─────────────────────────────────────────────────────────────

class _PoaBottomBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String nextLabel;
  const _PoaBottomBar({
    required this.onPrevious,
    required this.onNext,
    this.nextLabel = 'Next step',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                onPressed: onPrevious,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                text: nextLabel,
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
