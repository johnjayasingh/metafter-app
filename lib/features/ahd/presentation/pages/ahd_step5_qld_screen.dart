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

/// AHD Queensland Step 5 — Life sustaining treatment details
///
/// API fields:
///   - life_sustaining_treatment.assisted_ventilation + instruction
///   - life_sustaining_treatment.artificial_nutrition + instruction
///   - treatment_decisions.artificial_hydration + instruction
///   - life_sustaining_treatment.antibiotics + instruction
///   - life_sustaining_treatment.other_treatment + instruction
class AhdStep5QldScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep5QldScreen({super.key, required this.flowData});

  @override
  State<AhdStep5QldScreen> createState() => _AhdStep5QldScreenState();
}

class _AhdStep5QldScreenState extends State<AhdStep5QldScreen> {
  final _formKey = GlobalKey<FormState>();

  late String? _assistedVentilation;
  late final TextEditingController _assistedVentilationDetailsCtrl;
  late String? _artificialNutrition;
  late final TextEditingController _artificialNutritionDetailsCtrl;
  late String? _artificialHydration;
  late final TextEditingController _artificialHydrationDetailsCtrl;
  late String? _antibiotics;
  late final TextEditingController _antibioticsDetailsCtrl;
  late String? _otherTreatment;
  late final TextEditingController _otherTreatmentDetailsCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _assistedVentilation = d.assistedVentilation;
    _assistedVentilationDetailsCtrl =
        TextEditingController(text: d.assistedVentilationDetails ?? '');
    _artificialNutrition = d.artificialNutrition;
    _artificialNutritionDetailsCtrl =
        TextEditingController(text: d.artificialNutritionDetails ?? '');
    _artificialHydration = d.artificialHydration;
    _artificialHydrationDetailsCtrl =
        TextEditingController(text: d.artificialHydrationDetails ?? '');
    _antibiotics = d.antibiotics;
    _antibioticsDetailsCtrl =
        TextEditingController(text: d.antibioticsDetails ?? '');
    _otherTreatment = d.otherTreatment;
    _otherTreatmentDetailsCtrl =
        TextEditingController(text: d.otherTreatmentDetails ?? '');
  }

  @override
  void dispose() {
    _assistedVentilationDetailsCtrl.dispose();
    _artificialNutritionDetailsCtrl.dispose();
    _artificialHydrationDetailsCtrl.dispose();
    _antibioticsDetailsCtrl.dispose();
    _otherTreatmentDetailsCtrl.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      assistedVentilation: _assistedVentilation,
      assistedVentilationDetails:
          _assistedVentilationDetailsCtrl.text.trim(),
      artificialNutrition: _artificialNutrition,
      artificialNutritionDetails:
          _artificialNutritionDetailsCtrl.text.trim(),
      artificialHydration: _artificialHydration,
      artificialHydrationDetails:
          _artificialHydrationDetailsCtrl.text.trim(),
      antibiotics: _antibiotics,
      antibioticsDetails: _antibioticsDetailsCtrl.text.trim(),
      otherTreatment: _otherTreatment,
      otherTreatmentDetails: _otherTreatmentDetailsCtrl.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(5), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  Widget _buildTreatmentSection({
    required String title,
    String? subtitle,
    required String? value,
    required ValueChanged<String> onChanged,
    required TextEditingController detailsController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.questionTitle),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.subtitle),
        ],
        const SizedBox(height: 12),
        ...CommonAhdOptions.all.map(
          (option) => RadioListOption(
            title: CommonAhdOptions.displayName(option),
            isSelected: value == option,
            onTap: () => onChanged(option),
          ),
        ),
        if (value == CommonAhdOptions.circumstance) ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: detailsController,
            label: 'Specify circumstances',
            maxLines: 4,
            minLines: 2,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 5, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 5,
        totalSteps: config.totalSteps,
        title: 'Life sustaining treatment',
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
                      Text('Life sustaining treatment',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      _buildTreatmentSection(
                        title: 'Assisted ventilation',
                        subtitle:
                            'e.g. a machine which assists your breathing through a face mask or a breathing tube',
                        value: _assistedVentilation,
                        onChanged: (v) =>
                            setState(() => _assistedVentilation = v),
                        detailsController:
                            _assistedVentilationDetailsCtrl,
                      ),

                      _buildTreatmentSection(
                        title: 'Artificial nutrition',
                        subtitle:
                            'e.g. a feeding tube through the nose or stomach',
                        value: _artificialNutrition,
                        onChanged: (v) =>
                            setState(() => _artificialNutrition = v),
                        detailsController:
                            _artificialNutritionDetailsCtrl,
                      ),

                      _buildTreatmentSection(
                        title: 'Artificial hydration',
                        subtitle: 'e.g. intravenous (IV) fluids',
                        value: _artificialHydration,
                        onChanged: (v) =>
                            setState(() => _artificialHydration = v),
                        detailsController:
                            _artificialHydrationDetailsCtrl,
                      ),

                      _buildTreatmentSection(
                        title: 'Antibiotics',
                        value: _antibiotics,
                        onChanged: (v) =>
                            setState(() => _antibiotics = v),
                        detailsController: _antibioticsDetailsCtrl,
                      ),

                      _buildTreatmentSection(
                        title: 'Other life sustaining treatment',
                        subtitle: 'State the treatment, e.g. kidney dialysis',
                        value: _otherTreatment,
                        onChanged: (v) =>
                            setState(() => _otherTreatment = v),
                        detailsController: _otherTreatmentDetailsCtrl,
                      ),
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
