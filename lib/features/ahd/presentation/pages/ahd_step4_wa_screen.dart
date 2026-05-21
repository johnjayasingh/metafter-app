import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
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

/// AHD WA Step 4 — Treatment decisions
class AhdStep4WaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep4WaScreen({super.key, required this.flowData});

  @override
  State<AhdStep4WaScreen> createState() => _AhdStep4WaScreenState();
}

class _AhdStep4WaScreenState extends State<AhdStep4WaScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Life-sustaining treatment (main question) ──
  late String? _lifeSustainingTreatment;
  late final TextEditingController _lifeSustainingDetailsController;

  // ── Per-treatment selections ──
  late String? _cpr;
  late final TextEditingController _cprDetailsController;
  late String? _assistedVentilation;
  late final TextEditingController _assistedVentilationDetailsController;
  late String? _artificialNutrition;
  late final TextEditingController _artificialNutritionDetailsController;
  late String? _artificialHydration;
  late final TextEditingController _artificialHydrationDetailsController;
  late String? _antibiotics;
  late final TextEditingController _antibioticsDetailsController;
  late String? _bloodProducts;
  late final TextEditingController _bloodProductsDetailsController;
  late String? _dialysis;
  late final TextEditingController _dialysisDetailsController;
  late String? _otherTreatment;
  late final TextEditingController _otherTreatmentDetailsController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;

    _lifeSustainingTreatment = d.waLifeSustainingTreatment;
    _lifeSustainingDetailsController =
        TextEditingController(text: d.waLifeSustainingDetails ?? '');

    _cpr = d.waCpr;
    _cprDetailsController = TextEditingController(text: d.waCprDetails ?? '');
    _assistedVentilation = d.waAssistedVentilation;
    _assistedVentilationDetailsController =
        TextEditingController(text: d.waAssistedVentilationDetails ?? '');
    _artificialNutrition = d.waArtificialNutrition;
    _artificialNutritionDetailsController =
        TextEditingController(text: d.waArtificialNutritionDetails ?? '');
    _artificialHydration = d.waArtificialHydration;
    _artificialHydrationDetailsController =
        TextEditingController(text: d.waArtificialHydrationDetails ?? '');
    _antibiotics = d.waAntibiotics;
    _antibioticsDetailsController =
        TextEditingController(text: d.waAntibioticsDetails ?? '');
    _bloodProducts = d.waBloodProducts;
    _bloodProductsDetailsController =
        TextEditingController(text: d.waBloodProductsDetails ?? '');
    _dialysis = d.waDialysis;
    _dialysisDetailsController =
        TextEditingController(text: d.waDialysisDetails ?? '');
    _otherTreatment = d.waOtherTreatment;
    _otherTreatmentDetailsController =
        TextEditingController(text: d.waOtherTreatmentDetails ?? '');
  }

  @override
  void dispose() {
    _lifeSustainingDetailsController.dispose();
    _cprDetailsController.dispose();
    _assistedVentilationDetailsController.dispose();
    _artificialNutritionDetailsController.dispose();
    _artificialHydrationDetailsController.dispose();
    _antibioticsDetailsController.dispose();
    _bloodProductsDetailsController.dispose();
    _dialysisDetailsController.dispose();
    _otherTreatmentDetailsController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  static String? _mapOtherTreatmentToLst(String? choice) {
    switch (choice) {
      case TreatmentChoice.consentAll:
        return LifeSustainingTreatmentDecision.consentToAllTreatment;
      case TreatmentChoice.refuseAll:
        return LifeSustainingTreatmentDecision.refuseAllTreatment;
      case TreatmentChoice.consentCircumstances:
        return LifeSustainingTreatmentDecision.consentSpecificTreatment;
      case TreatmentChoice.cantDecide:
        return LifeSustainingTreatmentDecision.cantDecide;
      default:
        return null;
    }
  }

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waLifeSustainingTreatment: _lifeSustainingTreatment,
      waLifeSustainingDetails:
          _lifeSustainingTreatment == WaLifeSustainingMain.specificTreatment
              ? _lifeSustainingDetailsController.text.trim()
              : null,
      waCpr: _cpr,
      waCprDetails: _cpr == TreatmentChoice.consentCircumstances
          ? _cprDetailsController.text.trim()
          : null,
      waAssistedVentilation: _assistedVentilation,
      waAssistedVentilationDetails:
          _assistedVentilation == TreatmentChoice.consentCircumstances
              ? _assistedVentilationDetailsController.text.trim()
              : null,
      waArtificialNutrition: _artificialNutrition,
      waArtificialNutritionDetails:
          _artificialNutrition == TreatmentChoice.consentCircumstances
              ? _artificialNutritionDetailsController.text.trim()
              : null,
      waArtificialHydration: _artificialHydration,
      waArtificialHydrationDetails:
          _artificialHydration == TreatmentChoice.consentCircumstances
              ? _artificialHydrationDetailsController.text.trim()
              : null,
      waAntibiotics: _antibiotics,
      waAntibioticsDetails:
          _antibiotics == TreatmentChoice.consentCircumstances
              ? _antibioticsDetailsController.text.trim()
              : null,
      waBloodProducts: _bloodProducts,
      waBloodProductsDetails:
          _bloodProducts == TreatmentChoice.consentCircumstances
              ? _bloodProductsDetailsController.text.trim()
              : null,
      waDialysis: _dialysis,
      waDialysisDetails: _dialysis == TreatmentChoice.consentCircumstances
          ? _dialysisDetailsController.text.trim()
          : null,
      lstStateTreatment: _mapOtherTreatmentToLst(_otherTreatment),
      waOtherTreatment: _otherTreatment,
      waOtherTreatmentDetails:
          _otherTreatment == TreatmentChoice.consentCircumstances
              ? _otherTreatmentDetailsController.text.trim()
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

  // ── Helper: per-treatment radio section ──
  Widget _buildTreatmentSection({
    required String title,
    required String? selectedValue,
    required TextEditingController detailsController,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: AppColors.borderGray),
        const SizedBox(height: 20),
        Text(title, style: AppTextStyles.questionTitle),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedValue == TreatmentChoice.consentAll,
          title: 'I consent to this treatment in all circumstances',
          onTap: () => onChanged(TreatmentChoice.consentAll),
        ),
        const SizedBox(height: 8),
        RadioListOption(
          isSelected: selectedValue == TreatmentChoice.refuseAll,
          title: 'I refuse this treatment in all circumstances',
          onTap: () => onChanged(TreatmentChoice.refuseAll),
        ),
        const SizedBox(height: 8),
        RadioListOption(
          isSelected: selectedValue == TreatmentChoice.consentCircumstances,
          title: 'I consent to this treatment in the following circumstances',
          onTap: () => onChanged(TreatmentChoice.consentCircumstances),
        ),
        if (selectedValue == TreatmentChoice.consentCircumstances) ...[
          const SizedBox(height: 12),
          AppTextArea(
              controller: detailsController,
              label: 'Enter details',
              maxLines: 4,
              minLines: 3),
        ],
        const SizedBox(height: 8),
        RadioListOption(
          isSelected: selectedValue == TreatmentChoice.cantDecide,
          title: 'I cannot decide at this time',
          onTap: () => onChanged(TreatmentChoice.cantDecide),
        ),
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
          currentStep: 4, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 4,
        totalSteps: config.totalSteps,
        title: 'Treatment decisions',
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
                      Text('Treatment decisions',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      // ── Main life-sustaining treatment question ──
                      Text('Life-sustaining treatment',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _lifeSustainingTreatment ==
                            WaLifeSustainingMain.consentAll,
                        title:
                            'I consent to all treatments aimed at sustaining or prolonging my life.',
                        onTap: () => setState(() => _lifeSustainingTreatment =
                            WaLifeSustainingMain.consentAll),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _lifeSustainingTreatment ==
                            WaLifeSustainingMain.consentUntilRecover,
                        title:
                            'I consent to all treatments aimed at sustaining or prolonging my life unless it is apparent that I am so unwell from injury or illness that there is no reasonable prospect that I will recover to the extent that I can survive without continuous life-sustaining treatments. In such a situation, I withdraw consent to life-sustaining treatments.',
                        onTap: () => setState(() => _lifeSustainingTreatment =
                            WaLifeSustainingMain.consentUntilRecover),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _lifeSustainingTreatment ==
                            WaLifeSustainingMain.specificTreatment,
                        title:
                            'I make the following decisions about specific life-sustaining treatments as listed in the table below.',
                        onTap: () => setState(() => _lifeSustainingTreatment =
                            WaLifeSustainingMain.specificTreatment),
                      ),
                      if (_lifeSustainingTreatment ==
                          WaLifeSustainingMain.specificTreatment) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _lifeSustainingDetailsController,
                          label: 'Enter details',
                          maxLines: 4,
                          minLines: 3,
                        ),
                      ],
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _lifeSustainingTreatment ==
                            WaLifeSustainingMain.refuseAll,
                        title:
                            'I refuse consent to all treatments aimed at sustaining or prolonging my life.',
                        onTap: () => setState(() => _lifeSustainingTreatment =
                            WaLifeSustainingMain.refuseAll),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _lifeSustainingTreatment ==
                            WaLifeSustainingMain.cantDecide,
                        title: 'I cannot decide at this time.',
                        onTap: () => setState(() => _lifeSustainingTreatment =
                            WaLifeSustainingMain.cantDecide),
                      ),
                      const SizedBox(height: 24),

                      // ── Per-treatment sections ──
                      _buildTreatmentSection(
                        title: 'CPR Cardiopulmonary resuscitation',
                        selectedValue: _cpr,
                        detailsController: _cprDetailsController,
                        onChanged: (v) => setState(() => _cpr = v),
                      ),
                      _buildTreatmentSection(
                        title:
                            'Assisted ventilation - A machine that helps you breathe using a face mask or tube',
                        selectedValue: _assistedVentilation,
                        detailsController:
                            _assistedVentilationDetailsController,
                        onChanged: (v) =>
                            setState(() => _assistedVentilation = v),
                      ),
                      _buildTreatmentSection(
                        title:
                            'Artificial nutrition - A feeding tube through the nose or stomach',
                        selectedValue: _artificialNutrition,
                        detailsController:
                            _artificialNutritionDetailsController,
                        onChanged: (v) =>
                            setState(() => _artificialNutrition = v),
                      ),
                      _buildTreatmentSection(
                        title:
                            'Artificial hydration - Fluids given via a tube into a vein, tissues or the stomach',
                        selectedValue: _artificialHydration,
                        detailsController:
                            _artificialHydrationDetailsController,
                        onChanged: (v) =>
                            setState(() => _artificialHydration = v),
                      ),
                      _buildTreatmentSection(
                        title:
                            'Antibiotics - Drugs given to help fight infection, given by mouth, injection or by drip tube',
                        selectedValue: _antibiotics,
                        detailsController: _antibioticsDetailsController,
                        onChanged: (v) => setState(() => _antibiotics = v),
                      ),
                      _buildTreatmentSection(
                        title:
                            'Receiving blood products such as a blood transfusion',
                        selectedValue: _bloodProducts,
                        detailsController: _bloodProductsDetailsController,
                        onChanged: (v) => setState(() => _bloodProducts = v),
                      ),
                      _buildTreatmentSection(
                        title: 'Kidney dialysis',
                        selectedValue: _dialysis,
                        detailsController: _dialysisDetailsController,
                        onChanged: (v) => setState(() => _dialysis = v),
                      ),

                      // ── Other life-sustaining treatment ──
                      Container(height: 1, color: AppColors.borderGray),
                      const SizedBox(height: 20),
                      Text('Other life-sustaining treatment',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 16),
                      RadioListOption(
                        isSelected:
                            _otherTreatment == TreatmentChoice.consentAll,
                        title:
                            'I consent to this treatment in all circumstances',
                        onTap: () => setState(() =>
                            _otherTreatment = TreatmentChoice.consentAll),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected:
                            _otherTreatment == TreatmentChoice.refuseAll,
                        title:
                            'I refuse consent to this treatment in all circumstances',
                        onTap: () => setState(() =>
                            _otherTreatment = TreatmentChoice.refuseAll),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _otherTreatment ==
                            TreatmentChoice.consentCircumstances,
                        title:
                            'I consent to this treatment in the following circumstances',
                        onTap: () => setState(() => _otherTreatment =
                            TreatmentChoice.consentCircumstances),
                      ),
                      if (_otherTreatment ==
                          TreatmentChoice.consentCircumstances) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _otherTreatmentDetailsController,
                          label: 'Enter details',
                          maxLines: 4,
                          minLines: 3,
                        ),
                      ],
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected:
                            _otherTreatment == TreatmentChoice.cantDecide,
                        title: 'I cannot decide at this time',
                        onTap: () => setState(() =>
                            _otherTreatment = TreatmentChoice.cantDecide),
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
