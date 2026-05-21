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

/// AHD NT Step 4 — Advanced consent decisions
///
/// API fields:
///   - cpr_and_resuscitation.cpr_consent
///   - cpr_and_resuscitation.cpr_consent_instruction (conditional)
///   - treatment_decisions.specific_treatment_no_consent
///   - treatment_decisions.specific_treatment_no_consent_instruction
///   - declarations_and_wishes.religious_beliefs
class AhdStep4NtScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep4NtScreen({super.key, required this.flowData});

  @override
  State<AhdStep4NtScreen> createState() => _AhdStep4NtScreenState();
}

class _AhdStep4NtScreenState extends State<AhdStep4NtScreen> {
  final _formKey = GlobalKey<FormState>();

  late String? _cprChoice;
  late final TextEditingController _cprConditionController;
  late String? _refusedTreatment;
  late final TextEditingController _refusedOtherController;
  late final TextEditingController _religiousBeliefsController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _cprChoice = d.ntCprChoice;
    _cprConditionController =
        TextEditingController(text: d.ntCprConditionDetails ?? '');
    _refusedTreatment = d.ntRefusedTreatments.isNotEmpty
        ? d.ntRefusedTreatments.first
        : null;
    _refusedOtherController =
        TextEditingController(text: d.ntRefusedTreatmentOther ?? '');
    _religiousBeliefsController =
        TextEditingController(text: d.ntReligiousBeliefs ?? '');
  }

  @override
  void dispose() {
    _cprConditionController.dispose();
    _refusedOtherController.dispose();
    _religiousBeliefsController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      ntCprChoice: _cprChoice,
      ntCprConditionDetails: _cprChoice == NtCprChoice.exceptUnacceptable
          ? _cprConditionController.text.trim()
          : null,
      ntRefusedTreatments:
          _refusedTreatment != null ? [_refusedTreatment!] : [],
      ntRefusedTreatmentOther: _refusedOtherController.text.trim(),
      ntReligiousBeliefs: _religiousBeliefsController.text.trim(),
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

  void _selectRefusedTreatment(String treatment) {
    setState(() {
      _refusedTreatment =
          _refusedTreatment == treatment ? null : treatment;
    });
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
        title: 'Advanced consent decisions',
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
                      Text('Advanced consent decisions',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      // ── CPR section ──
                      Text(
                        'If my heart stops and CPR is an option:',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      RadioListOption(
                        isSelected:
                            _cprChoice == NtCprChoice.attemptCpr,
                        title:
                            'Please try to restart my heart or breathing (attempt CPR)',
                        onTap: () => setState(
                            () => _cprChoice = NtCprChoice.attemptCpr),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected:
                            _cprChoice == NtCprChoice.exceptUnacceptable,
                        title:
                            'Except if it results in an unacceptable outcome. Refer to what you wrote in section 2b above and describe unacceptable outcomes, for example, I will not be able to live independently or go home.',
                        onTap: () => setState(() =>
                            _cprChoice = NtCprChoice.exceptUnacceptable),
                      ),
                      if (_cprChoice ==
                          NtCprChoice.exceptUnacceptable) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _cprConditionController,
                          label: 'Enter details',
                          maxLines: 4,
                          minLines: 2,
                        ),
                      ],
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected:
                            _cprChoice == NtCprChoice.naturalDeath,
                        title:
                            'Please allow me to die a natural death. Do not restart my heart or breathing (No CPR)',
                        onTap: () => setState(
                            () => _cprChoice = NtCprChoice.naturalDeath),
                      ),
                      const SizedBox(height: 24),

                      // ── Refused treatments section ──
                      Text(
                        'Are there specific medical treatments that you do not want?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      RadioListOption(
                        isSelected: _refusedTreatment ==
                            NtRefusedTreatment.artificialFeeding,
                        title: 'Artificial feeding / tube feeding',
                        onTap: () => _selectRefusedTreatment(
                            NtRefusedTreatment.artificialFeeding),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _refusedTreatment ==
                            NtRefusedTreatment.renalDialysis,
                        title: 'Renal dialysis',
                        onTap: () => _selectRefusedTreatment(
                            NtRefusedTreatment.renalDialysis),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _refusedTreatment ==
                            NtRefusedTreatment.bloodTransfusions,
                        title: 'Blood transfusions',
                        onTap: () => _selectRefusedTreatment(
                            NtRefusedTreatment.bloodTransfusions),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _refusedTreatment ==
                            NtRefusedTreatment.other,
                        title: 'Other',
                        onTap: () => _selectRefusedTreatment(
                            NtRefusedTreatment.other),
                      ),
                      if (_refusedTreatment ==
                          NtRefusedTreatment.other) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _refusedOtherController,
                          label: 'Please specify',
                          maxLines: 3,
                          minLines: 2,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── Religious beliefs section ──
                      Text(
                        'Do you have any religious or ethical beliefs that may affect your treatment? If yes, describe how your beliefs might affect your treatment:',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _religiousBeliefsController,
                        label: 'Religious beliefs',
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
