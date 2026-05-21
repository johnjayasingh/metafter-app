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

/// AHD NSW Step 4 — Directions about medical care
///
/// API fields:
///   - cpr_and_resuscitation.medical_not_expected_to_recover
///   - treatment_decisions.other_medical_support
///   - treatment_decisions.other_medical_support_instruction
class AhdStep4NswScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep4NswScreen({super.key, required this.flowData});

  @override
  State<AhdStep4NswScreen> createState() => _AhdStep4NswScreenState();
}

class _AhdStep4NswScreenState extends State<AhdStep4NswScreen> {
  late String? _cprChoice;
  late String? _medicalTreatmentType;
  late final TextEditingController _medicalTreatmentOtherController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _cprChoice = d.nswCprChoice;
    _medicalTreatmentType = d.nswMedicalTreatmentType;
    _medicalTreatmentOtherController =
        TextEditingController(text: d.nswMedicalTreatmentOther ?? '');
  }

  @override
  void dispose() {
    _medicalTreatmentOtherController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      nswCprChoice: _cprChoice,
      nswMedicalTreatmentType: _medicalTreatmentType,
      nswMedicalTreatmentOther:
          _medicalTreatmentType == MedicalTreatmentType.other
              ? _medicalTreatmentOtherController.text.trim()
              : null,
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(5), extra: updated);
    if (result != null) _returnedFromNext = result;
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
        title: 'Directions about medical care',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Directions about medical care',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    Text(
                      'If I am not expected to recover, or if my life is unbearable as indicated in my Personal Values About Dying',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 16),
                    RadioListOption(
                      isSelected: _cprChoice == CprChoice.accept,
                      title: 'I would accept CPR',
                      onTap: () => setState(
                          () => _cprChoice = CprChoice.accept),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _cprChoice == CprChoice.doNotAccept,
                      title:
                          'I would not accept CPR. Do not try to restart my heart or breathing',
                      onTap: () => setState(
                          () => _cprChoice = CprChoice.doNotAccept),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'If my quality of life becomes unbearable as indicated in my Personal Values About Dying, I want the following medical support',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 16),
                    RadioListOption(
                      isSelected: _medicalTreatmentType ==
                          MedicalTreatmentType.artificialVentilation,
                      title: 'Artificial ventilation through a tube',
                      subtitle:
                          'also called \'life support\', breathing machine',
                      onTap: () => setState(() =>
                          _medicalTreatmentType =
                              MedicalTreatmentType.artificialVentilation),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _medicalTreatmentType ==
                          MedicalTreatmentType.renalDialysis,
                      title: 'Renal dialysis',
                      subtitle: 'kidney function replacement',
                      onTap: () => setState(() =>
                          _medicalTreatmentType =
                              MedicalTreatmentType.renalDialysis),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _medicalTreatmentType ==
                          MedicalTreatmentType.lifeProlonging,
                      title:
                          'Life prolonging treatments that require continuous administration of drug',
                      onTap: () => setState(() =>
                          _medicalTreatmentType =
                              MedicalTreatmentType.lifeProlonging),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _medicalTreatmentType ==
                          MedicalTreatmentType.other,
                      title: 'Other',
                      onTap: () => setState(() =>
                          _medicalTreatmentType =
                              MedicalTreatmentType.other),
                    ),
                    if (_medicalTreatmentType ==
                        MedicalTreatmentType.other) ...[
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _medicalTreatmentOtherController,
                        label: 'Enter details',
                        maxLines: 4,
                        minLines: 3,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
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
