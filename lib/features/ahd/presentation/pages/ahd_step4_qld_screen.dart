import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_enums.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Queensland Step 4 — Directions about life sustaining treatment
///
/// API fields:
///   - life_sustaining_treatment.direction_type
///   - life_sustaining_treatment.direction_instruction
///   - life_sustaining_treatment.treatment_type
///   - life_sustaining_treatment.treatment_instruction
class AhdStep4QldScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep4QldScreen({super.key, required this.flowData});

  @override
  State<AhdStep4QldScreen> createState() => _AhdStep4QldScreenState();
}

class _AhdStep4QldScreenState extends State<AhdStep4QldScreen> {
  final _formKey = GlobalKey<FormState>();

  late String? _directionType;
  late final TextEditingController _directionInstructionController;
  late String? _treatmentType;
  late final TextEditingController _treatmentInstructionController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _directionType = d.lifeSustainingDirective;
    _directionInstructionController =
        TextEditingController(text: d.lifeSustainingDirectiveDetails ?? '');
    _treatmentType = d.lifeSustainingTreatment;
    _treatmentInstructionController =
        TextEditingController(text: d.lifeSustainingTreatmentDetails ?? '');
  }

  @override
  void dispose() {
    _directionInstructionController.dispose();
    _treatmentInstructionController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      lifeSustainingDirective: _directionType,
      lifeSustainingDirectiveDetails:
          _directionInstructionController.text.trim(),
      lifeSustainingTreatment: _treatmentType,
      lifeSustainingTreatmentDetails:
          _treatmentInstructionController.text.trim(),
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
        title: 'Directions about life sustaining',
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
                      Text('Directions about life-sustaining treatment',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text('Your directions',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 4),
                      Text(
                        'For (including health) matters and / or financial matters',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),

                      ...DirectionAboutLifeSustainingTreatment.all.map(
                        (option) => RadioListOption(
                          title: DirectionAboutLifeSustainingTreatment
                              .displayName(option),
                          isSelected: _directionType == option,
                          onTap: () =>
                              setState(() => _directionType = option),
                        ),
                      ),
                      if (_directionType ==
                          DirectionAboutLifeSustainingTreatment
                              .specificDirection) ...[
                        const SizedBox(height: 16),
                        AppTextArea(
                          controller: _directionInstructionController,
                          label: 'Specific directions',
                          maxLines: 5,
                          minLines: 3,
                        ),
                      ],

                      const SizedBox(height: 32),

                      Text('Life-sustaining treatment',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 16),

                      ...CommonAhdOptions.all.map(
                        (option) => RadioListOption(
                          title: CommonAhdOptions.displayName(option),
                          isSelected: _treatmentType == option,
                          onTap: () =>
                              setState(() => _treatmentType = option),
                        ),
                      ),
                      if (_treatmentType ==
                          CommonAhdOptions.circumstance) ...[
                        const SizedBox(height: 16),
                        AppTextArea(
                          controller: _treatmentInstructionController,
                          label: 'Specify circumstances',
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
