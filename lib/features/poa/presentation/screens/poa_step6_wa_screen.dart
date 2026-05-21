import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_commencement_wa_section.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA Western Australia Step 6 — Commencement. Final step: submits to API.
class PoaStep6Wa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep6Wa({super.key, required this.flowData});

  @override
  State<PoaStep6Wa> createState() => _PoaStep6WaState();
}

class _PoaStep6WaState extends State<PoaStep6Wa> {
  final PoaService _poaService = PoaService();
  bool _isSubmitting = false;

  late String _commencementType;

  @override
  void initState() {
    super.initState();
    _commencementType = widget.flowData.commencementType ?? 'IMMEDIATELY';
  }

  PoaFlowData _buildFinalData() {
    return widget.flowData.copyWith(
      commencementType: _commencementType,
    );
  }

  Future<void> _handleSaveAndDownload() async {
    setState(() => _isSubmitting = true);

    try {
      final finalData = _buildFinalData();

      // Delete existing WA attorneys then re-save
      await _poaService.deleteAttorneysByType(AttorneyType.PRIMARY);
      await _poaService.deleteAttorneysByType(AttorneyType.SUBSTITUTE);

      for (final entry in finalData.waAttorneys) {
        final (first, middle, last) = PoaPersonData.parseFullName(entry.name);
        await _poaService.createAttorneyForPoa(
          PoaPersonData(
            id: '',
            firstName: first,
            middleName: middle,
            lastName: last,
            address: entry.address,
            email: entry.email,
          ),
          type: AttorneyType.PRIMARY,
        );
      }

      if (finalData.waHasSubstitute ?? false) {
        for (final entry in finalData.waSubstitutes) {
          final (first, middle, last) =
              PoaPersonData.parseFullName(entry.name);
          await _poaService.createAttorneyForPoa(
            PoaPersonData(
              id: '',
              firstName: first,
              middleName: middle,
              lastName: last,
              address: entry.address,
              email: entry.email,
            ),
            type: AttorneyType.SUBSTITUTE,
          );
        }
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
        currentStep: 6,
        userState: widget.flowData.state,
      ),
      appBar: WillCreationAppBar(
        currentStep: 6,
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
                child: PoaCommencementWaSection(
                  selectedType: _commencementType,
                  onTypeChanged: (type) =>
                      setState(() => _commencementType = type),
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
