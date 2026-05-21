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

/// POA Tasmania Step 5 — Conditions/Restrictions. Final step: submits to API.
class PoaStep5Tas extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep5Tas({super.key, required this.flowData});

  @override
  State<PoaStep5Tas> createState() => _PoaStep5TasState();
}

class _PoaStep5TasState extends State<PoaStep5Tas> {
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
          context, 'Please enter conditions/restrictions or select No.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final finalData = _buildFinalData();

      // Delete existing attorneys to avoid duplicates, then re-save
      await _poaService.deleteAttorneysByType(AttorneyType.PRIMARY);
      for (final atty in finalData.attorneys) {
        await _poaService.createAttorneyForPoa(atty, type: AttorneyType.PRIMARY);
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
                        onPressed: () => context.pop(),
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
