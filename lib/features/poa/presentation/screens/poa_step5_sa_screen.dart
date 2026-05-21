import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_conditions_limitations_section.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA South Australia Step 5 — Conditions/limitations. Final step: submits to API.
class PoaStep5Sa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep5Sa({super.key, required this.flowData});

  @override
  State<PoaStep5Sa> createState() => _PoaStep5SaState();
}

class _PoaStep5SaState extends State<PoaStep5Sa> {
  final PoaService _poaService = PoaService();
  bool _isSubmitting = false;

  late bool _hasConditions;
  late TextEditingController _conditionsController;

  @override
  void initState() {
    super.initState();
    _hasConditions = widget.flowData.hasConditionsLimitations ?? false;
    _conditionsController = TextEditingController(
      text: widget.flowData.conditionsLimitations ?? '',
    );
  }

  @override
  void dispose() {
    _conditionsController.dispose();
    super.dispose();
  }

  PoaFlowData _buildFinalData() {
    return widget.flowData.copyWith(
      hasConditionsLimitations: _hasConditions,
      conditionsLimitations:
          _hasConditions ? _conditionsController.text.trim() : null,
    );
  }

  Future<void> _handleSaveAndDownload() async {
    if (_hasConditions && _conditionsController.text.trim().isEmpty) {
      SnackBarUtils.showError(
          context, 'Please enter conditions/limitations or select No.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final finalData = _buildFinalData();

      // Delete existing SA attorneys and re-save to avoid duplicates
      await _poaService.deleteAttorneysByType(AttorneyType.SECOND_DONOR);
      await _poaService.deleteAttorneysByType(AttorneyType.ATTORNEY_DONEE);

      // Save second donor if applicable
      if ((finalData.saHasSecondDonor ?? false) &&
          (finalData.saSecondDonorFullName?.isNotEmpty ?? false)) {
        final name = finalData.saSecondDonorFullName!;
        final (first, middle, last) = PoaPersonData.parseFullName(name);
        await _poaService.createAttorneyForPoa(
          PoaPersonData(
            id: '',
            firstName: first,
            middleName: middle,
            lastName: last,
            address: finalData.saSecondDonorAddress ?? '',
            email: finalData.saSecondDonorEmail ?? '',
          ),
          type: AttorneyType.SECOND_DONOR,
        );
      }

      // Save donee
      if (finalData.doneeName?.isNotEmpty ?? false) {
        final name = finalData.doneeName!;
        final (first, middle, last) = PoaPersonData.parseFullName(name);
        await _poaService.createAttorneyForPoa(
          PoaPersonData(
            id: '',
            firstName: first,
            middleName: middle,
            lastName: last,
            address: finalData.doneeAddress ?? '',
            email: finalData.doneeEmail ?? '',
          ),
          type: AttorneyType.ATTORNEY_DONEE,
        );
      }

      final result = await _poaService.createOrUpdatePoa(finalData);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.isSuccess) {
        SnackBarUtils.showSuccess(
            context, 'Power of attorney saved successfully.');
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
      SnackBarUtils.showError(context, 'An error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
        currentStep: 5,
        userState: widget.flowData.state,
      ),
      appBar: WillCreationAppBar(
        currentStep: 5,
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
                child: PoaConditionsLimitationsSection(
                  hasConditionsLimitations: _hasConditions,
                  controller: _conditionsController,
                  onToggle: (val) => setState(() => _hasConditions = val),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: () => context.pop(widget.flowData),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Save & Download',
                        onPressed:
                            _isSubmitting ? null : _handleSaveAndDownload,
                        isLoading: _isSubmitting,
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
