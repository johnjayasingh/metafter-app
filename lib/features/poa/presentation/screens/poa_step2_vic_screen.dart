import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_attorney_section.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaStep2Vic extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep2Vic({super.key, required this.flowData});

  @override
  State<PoaStep2Vic> createState() => _PoaStep2VicState();
}

class _PoaStep2VicState extends State<PoaStep2Vic> {
  /// Victoria uses a single-select matter type:
  /// 'PERSONAL_HEALTH', 'FINANCIAL', 'BOTH', or 'SPECIFIC'
  late String _selectedMatter;
  late TextEditingController _specificMattersController;

  List<PoaPersonData> _attorneys = [];
  List<PoaPersonData> _successive = [];

  // Revocation
  late bool _hasRevocation;
  late TextEditingController _revocationController;

  // Conditions and instructions (multi-select checkboxes)
  late bool _ciConflictTransactions;
  late TextEditingController _conflictTransactionsController;
  late bool _ciGifts;
  late TextEditingController _giftsController;
  late bool _ciDependentMaintenance;
  late TextEditingController _dependentMaintenanceController;
  late bool _ciPaymentToAttorney;
  late TextEditingController _paymentToAttorneyController;
  late TextEditingController _additionalConditionsController;

  // Commencement
  late String _commencementType;

  // Assistance with signing
  late bool _needsAssistance;

  // Medical treatment decision maker
  List<PoaPersonData> _medicalDecisionMakers = [];

  // Limitations and conditions
  late bool _hasLimitations;
  late TextEditingController _limitationsController;

  @override
  void initState() {
    super.initState();
    // Determine initial matter selection from flowData
    final matters = widget.flowData.matters;
    if (matters.contains('SPECIFIC')) {
      _selectedMatter = 'SPECIFIC';
    } else if (matters.contains('PERSONAL_HEALTH') && matters.contains('FINANCIAL')) {
      _selectedMatter = 'BOTH';
    } else if (matters.contains('FINANCIAL')) {
      _selectedMatter = 'FINANCIAL';
    } else {
      _selectedMatter = 'PERSONAL_HEALTH';
    }
    _specificMattersController = TextEditingController(
      text: widget.flowData.specificMatters ?? '',
    );
    _attorneys = List<PoaPersonData>.from(widget.flowData.attorneys);
    _successive = List<PoaPersonData>.from(widget.flowData.successiveAttorneys);

    _hasRevocation = widget.flowData.hasRevocation ?? false;
    _revocationController = TextEditingController(
      text: widget.flowData.revocationDetails ?? '',
    );

    _commencementType = widget.flowData.commencementType ?? 'UPON_ATTORNEY_RECEIVING_CONDITION';
    _ciConflictTransactions = (widget.flowData.ciConflictTransactions ?? '').isNotEmpty;
    _ciGifts = (widget.flowData.ciGifts ?? '').isNotEmpty;
    _ciDependentMaintenance = (widget.flowData.ciDependentMaintenance ?? '').isNotEmpty;
    _ciPaymentToAttorney = (widget.flowData.ciPaymentToAttorney ?? '').isNotEmpty;
    _conflictTransactionsController = TextEditingController(
      text: widget.flowData.ciConflictTransactions ?? '',
    );
    _giftsController = TextEditingController(
      text: widget.flowData.ciGifts ?? '',
    );
    _dependentMaintenanceController = TextEditingController(
      text: widget.flowData.ciDependentMaintenance ?? '',
    );
    _paymentToAttorneyController = TextEditingController(
      text: widget.flowData.ciPaymentToAttorney ?? '',
    );
    _additionalConditionsController = TextEditingController(
      text: widget.flowData.ciAdditionalCondition ?? '',
    );

    _needsAssistance = widget.flowData.needsSigningAssistance ?? false;

    _medicalDecisionMakers = [];

    _hasLimitations = widget.flowData.hasLimitations ?? false;
    _limitationsController = TextEditingController(
      text: widget.flowData.limitationsDetails ?? '',
    );
  }

  @override
  void dispose() {
    _specificMattersController.dispose();
    _revocationController.dispose();
    _conflictTransactionsController.dispose();
    _giftsController.dispose();
    _dependentMaintenanceController.dispose();
    _paymentToAttorneyController.dispose();
    _additionalConditionsController.dispose();

    _limitationsController.dispose();
    super.dispose();
  }

  PoaFlowData _collectCurrentData() {
    // Map Victoria's single-select matter to the list format
    List<String> mattersForModel;
    switch (_selectedMatter) {
      case 'BOTH':
        mattersForModel = ['PERSONAL_HEALTH', 'FINANCIAL'];
        break;
      case 'SPECIFIC':
        mattersForModel = ['SPECIFIC'];
        break;
      default:
        mattersForModel = [_selectedMatter];
    }

    return widget.flowData.copyWith(
      matters: mattersForModel,
      specificMatters: _selectedMatter == 'SPECIFIC'
          ? _specificMattersController.text.trim()
          : null,
      attorneys: List.from(_attorneys),
      successiveAttorneys: List.from(_successive),
      hasRevocation: _hasRevocation,
      revocationDetails: _hasRevocation ? _revocationController.text.trim() : null,
      commencementType: _commencementType,
      ciConflictTransactions: _ciConflictTransactions
          ? _conflictTransactionsController.text.trim()
          : null,
      ciGifts: _ciGifts
          ? _giftsController.text.trim()
          : null,
      ciDependentMaintenance: _ciDependentMaintenance
          ? _dependentMaintenanceController.text.trim()
          : null,
      ciPaymentToAttorney: _ciPaymentToAttorney
          ? _paymentToAttorneyController.text.trim()
          : null,
      ciAdditionalCondition: _additionalConditionsController.text.trim().isNotEmpty
          ? _additionalConditionsController.text.trim()
          : null,
      needsSigningAssistance: _needsAssistance,
      hasMedicalDecisionMaker: _medicalDecisionMakers.isNotEmpty,
      hasLimitations: _hasLimitations,
      limitationsDetails: _hasLimitations ? _limitationsController.text.trim() : null,
    );
  }

  void _handleNext() {
    if (_attorneys.isEmpty) {
      SnackBarUtils.showError(context, 'Please add at least one attorney.');
      return;
    }
    if (_selectedMatter == 'SPECIFIC' &&
        _specificMattersController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter the specific matters.');
      return;
    }
    if (_hasRevocation && _revocationController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter revocation details or select No.');
      return;
    }
    if (_hasLimitations && _limitationsController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter limitations and conditions or select No.');
      return;
    }

    final updated = _collectCurrentData();
    context.push(AppRouter.poaNotification, extra: updated);
  }

  Widget _buildCheckboxItem({
    required String title,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!isSelected),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: AppTextStyles.bodyMedium),
              ),
            ],
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: controller,
            label: '',
            placeholder: 'Enter details',
            minLines: 3,
            maxLines: 6,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[PoaStep2Vic.build] RENDERING Victoria Step 2 — state: "${widget.flowData.state}"');
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
        currentStep: 2,
        userState: widget.flowData.state,
      ),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: config.totalSteps,
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
                    // ── Matters (Victoria-specific) ──────────────────
                    Text('Matters', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),
                    RadioListOption(
                      isSelected: _selectedMatter == 'PERSONAL_HEALTH',
                      title: 'Personal (including health) matters',
                      onTap: () => setState(() => _selectedMatter = 'PERSONAL_HEALTH'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _selectedMatter == 'FINANCIAL',
                      title: 'Financial matters',
                      onTap: () => setState(() => _selectedMatter = 'FINANCIAL'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _selectedMatter == 'BOTH',
                      title: 'Both personal and financial matters',
                      onTap: () => setState(() => _selectedMatter = 'BOTH'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _selectedMatter == 'SPECIFIC',
                      title: 'Specific matters',
                      onTap: () => setState(() => _selectedMatter = 'SPECIFIC'),
                    ),
                    if (_selectedMatter == 'SPECIFIC') ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _specificMattersController,
                        label: '',
                        placeholder: 'Please enter specific matters',
                        minLines: 4,
                        maxLines: 8,
                      ),
                    ],
                    const SizedBox(height: 32),

                    // ── Attorney(s) ──────────────────────────────────────
                    PoaAttorneySection(
                      type: AttorneyType.PRIMARY,
                      title: 'Attorney(s)',
                      addButtonText: '+ Add Attorney',
                      onChanged: (l) => setState(() => _attorneys = l),
                    ),
                    const SizedBox(height: 32),

                    // ── Successive attorney(s) ───────────────────────────
                    PoaAttorneySection(
                      type: AttorneyType.SUCCESSIVE,
                      title: 'Successive attorney(s)',
                      isOptional: true,
                      addButtonText: '+ Add Successive attorney',
                      onChanged: (l) => setState(() => _successive = l),
                    ),
                    const SizedBox(height: 32),

                    // ── Commencement ─────────────────────────────────────
                    Text('Commencement', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),
                    RadioListOption(
                      isSelected: _commencementType ==
                          'UPON_ATTORNEY_RECEIVING_CONDITION',
                      title: 'Upon my attorney receiving conditions',
                      onTap: () => setState(() => _commencementType =
                          'UPON_ATTORNEY_RECEIVING_CONDITION'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _commencementType == 'IMMEDIATELY',
                      title: 'Immediately',
                      onTap: () => setState(
                          () => _commencementType = 'IMMEDIATELY'),
                    ),
                    const SizedBox(height: 32),

                    // ── Revocation ───────────────────────────────────────
                    Text(
                      'Revocation',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Do you want to revoke any previous enduring powers of attorney?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _hasRevocation,
                            label: 'Yes',
                            onTap: () => setState(() => _hasRevocation = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_hasRevocation,
                            label: 'No',
                            onTap: () => setState(() => _hasRevocation = false),
                          ),
                        ),
                      ],
                    ),
                    if (_hasRevocation) ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _revocationController,
                        label: '',
                        placeholder: 'Enter details of previous power of attorney',
                        minLines: 4,
                        maxLines: 8,
                      ),
                    ],
                    const SizedBox(height: 32),

                    // ── Conditions and instructions ──────────────────────
                    Text('Conditions and instructions',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply:',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 16),
                    _buildCheckboxItem(
                      title: 'Conflict transactions',
                      isSelected: _ciConflictTransactions,
                      onChanged: (v) => setState(() => _ciConflictTransactions = v),
                      controller: _conflictTransactionsController,
                    ),
                    const SizedBox(height: 12),
                    _buildCheckboxItem(
                      title: 'Gifts',
                      isSelected: _ciGifts,
                      onChanged: (v) => setState(() => _ciGifts = v),
                      controller: _giftsController,
                    ),
                    const SizedBox(height: 12),
                    _buildCheckboxItem(
                      title: 'Maintenance of your dependants',
                      isSelected: _ciDependentMaintenance,
                      onChanged: (v) => setState(() => _ciDependentMaintenance = v),
                      controller: _dependentMaintenanceController,
                    ),
                    const SizedBox(height: 12),
                    _buildCheckboxItem(
                      title: 'Payments to attorney(s)',
                      isSelected: _ciPaymentToAttorney,
                      onChanged: (v) => setState(() => _ciPaymentToAttorney = v),
                      controller: _paymentToAttorneyController,
                    ),
                    const SizedBox(height: 12),
                    // Additional conditions or instructions — always visible (cl_advise_to_agents)
                    Text('Additional conditions or instructions', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    AppTextArea(
                      controller: _additionalConditionsController,
                      label: '',
                      placeholder: 'Enter details',
                      minLines: 3,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 32),

                    // ── Medical treatment decision maker ─────────────────
                    PoaAttorneySection(
                      type: AttorneyType.MEDICAL_DECISION_MAKER,
                      title: 'Medical treatment Decision maker',
                      addButtonText: '+ Add person',
                      maxPersons: 1,
                      onChanged: (l) => setState(() => _medicalDecisionMakers = l),
                    ),
                    const SizedBox(height: 32),

                    // ── Limitations and conditions ───────────────────────
                    Text(
                      'Limitations and conditions',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Would you like to add any limitations or conditions? (optional)',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _hasLimitations,
                            label: 'Yes',
                            onTap: () => setState(() => _hasLimitations = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_hasLimitations,
                            label: 'No',
                            onTap: () => setState(() => _hasLimitations = false),
                          ),
                        ),
                      ],
                    ),
                    if (_hasLimitations) ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _limitationsController,
                        label: '',
                        placeholder: 'Enter limitations and conditions',
                        minLines: 4,
                        maxLines: 8,
                      ),
                    ],
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
