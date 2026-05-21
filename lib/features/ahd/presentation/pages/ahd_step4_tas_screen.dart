import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Tasmania Step 4 — Medical treatment refuse
///
/// API fields:
///   - treatment_decisions.other_treatment_decision (REFUSE/CIRCUMSTANCE)
///   - treatment_decisions.other_treatment_decision_instruction
///   - treatment_decisions.health_circumstance_decision_instruction
class AhdStep4TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep4TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep4TasScreen> createState() => _AhdStep4TasScreenState();
}

class _AhdStep4TasScreenState extends State<AhdStep4TasScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _refuseController;
  late final TextEditingController _circumstancesController;

  // Track which radio is selected: 'REFUSE' or 'CIRCUMSTANCE'
  late String? _treatmentChoice;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _refuseController =
        TextEditingController(text: d.tasMedicalTreatmentRefuse ?? '');
    _circumstancesController =
        TextEditingController(text: d.tasMedicalCircumstances ?? '');
    // Determine initial choice based on which field has content
    if ((d.tasMedicalCircumstances ?? '').isNotEmpty) {
      _treatmentChoice = 'CIRCUMSTANCE';
    } else if ((d.tasMedicalTreatmentRefuse ?? '').isNotEmpty) {
      _treatmentChoice = 'REFUSE';
    } else {
      _treatmentChoice = null;
    }
  }

  @override
  void dispose() {
    _refuseController.dispose();
    _circumstancesController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasMedicalTreatmentRefuse:
          _treatmentChoice == 'REFUSE' ? _refuseController.text.trim() : null,
      tasMedicalCircumstances:
          _treatmentChoice == 'CIRCUMSTANCE'
              ? _circumstancesController.text.trim()
              : null,
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(4), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 4, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 4,
        totalSteps: config.totalSteps,
        title: 'Medical treatment refuse',
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Medical treatment',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      RadioListOption(
                        isSelected: _treatmentChoice == 'REFUSE',
                        title: 'Medical treatment I refuse',
                        onTap: () =>
                            setState(() => _treatmentChoice = 'REFUSE'),
                      ),
                      if (_treatmentChoice == 'REFUSE') ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _refuseController,
                          label: 'Treatment I refuse',
                          maxLines: 5,
                          minLines: 3,
                        ),
                      ],
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _treatmentChoice == 'CIRCUMSTANCE',
                        title: 'Under what circumstances',
                        onTap: () => setState(
                            () => _treatmentChoice = 'CIRCUMSTANCE'),
                      ),
                      if (_treatmentChoice == 'CIRCUMSTANCE') ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _circumstancesController,
                          label: 'Circumstances',
                          maxLines: 5,
                          minLines: 3,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
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
