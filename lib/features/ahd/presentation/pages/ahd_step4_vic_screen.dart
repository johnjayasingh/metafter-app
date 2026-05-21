import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Victoria Step 4 — Instructional directive
///
/// API fields:
///   - medical_treatment_consent
///   - declarations_and_wishes.other_medical_decision
class AhdStep4VicScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep4VicScreen({super.key, required this.flowData});

  @override
  State<AhdStep4VicScreen> createState() => _AhdStep4VicScreenState();
}

class _AhdStep4VicScreenState extends State<AhdStep4VicScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _consentTreatmentController;
  late final TextEditingController _refuseTreatmentController;

  @override
  void initState() {
    super.initState();
    _consentTreatmentController =
        TextEditingController(text: widget.flowData.vicConsentTreatment ?? '');
    _refuseTreatmentController =
        TextEditingController(text: widget.flowData.vicRefuseTreatment ?? '');
  }

  @override
  void dispose() {
    _consentTreatmentController.dispose();
    _refuseTreatmentController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      vicConsentTreatment: _consentTreatmentController.text.trim(),
      vicRefuseTreatment: _refuseTreatmentController.text.trim(),
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
        title: 'Instructional directive',
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
                      Text('Instructional directive',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      Text(
                        'I consent to the following medical treatment (Specify the medical treatment and the circumstances)',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _consentTreatmentController,
                        label: 'Treatment I consent to',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text('I refuse the following medical treatment',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Specify the medical treatment and the circumstances',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _refuseTreatmentController,
                        label: 'Treatment I refuse',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),

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
