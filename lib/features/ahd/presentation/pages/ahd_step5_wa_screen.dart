import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_enums.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD WA Step 5 — Medical research consent
/// 12 separate questions mapping to medical_research_consent sub-fields
class AhdStep5WaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep5WaScreen({super.key, required this.flowData});

  @override
  State<AhdStep5WaScreen> createState() => _AhdStep5WaScreenState();
}

class _AhdStep5WaScreenState extends State<AhdStep5WaScreen> {
  late String? _placebos;
  late String? _useEquipment;
  late String? _lessPractitioners;
  late String? _comparativeAssessment;
  late String? _bloodSamples;
  late String? _tissueSample;
  late String? _nonIntrusiveTreatment;
  late String? _beingObserved;
  late String? _undertakingSurvey;
  late String? _collectingDisclosing;
  late String? _evaluatingSamples;
  late String? _other;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _placebos = d.waMrPlacebos;
    _useEquipment = d.waMrUseEquipment;
    _lessPractitioners = d.waMrLessPractitioners;
    _comparativeAssessment = d.waMrComparativeAssessment;
    _bloodSamples = d.waMrBloodSamples;
    _tissueSample = d.waMrTissueSample;
    _nonIntrusiveTreatment = d.waMrNonIntrusiveTreatment;
    _beingObserved = d.waMrBeingObserved;
    _undertakingSurvey = d.waMrUndertakingSurvey;
    _collectingDisclosing = d.waMrCollectingDisclosing;
    _evaluatingSamples = d.waMrEvaluatingSamples;
    _other = d.waMrOther;
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waMrPlacebos: _placebos,
      waMrUseEquipment: _useEquipment,
      waMrLessPractitioners: _lessPractitioners,
      waMrComparativeAssessment: _comparativeAssessment,
      waMrBloodSamples: _bloodSamples,
      waMrTissueSample: _tissueSample,
      waMrNonIntrusiveTreatment: _nonIntrusiveTreatment,
      waMrBeingObserved: _beingObserved,
      waMrUndertakingSurvey: _undertakingSurvey,
      waMrCollectingDisclosing: _collectingDisclosing,
      waMrEvaluatingSamples: _evaluatingSamples,
      waMrOther: _other,
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result =
        await context.push<AhdFlowData>(config.nextRoute(5), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  Widget _buildQuestion({
    required String title,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.questionTitle),
        const SizedBox(height: 10),
        ...MedicalResearchConsent.all.map(
          (opt) => _ResearchOption(
            label: MedicalResearchConsent.displayName(opt),
            isSelected: value == opt,
            onTap: () => setState(() => onChanged(opt)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer:
          AhdStepsSidebar(currentStep: 5, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 5,
        totalSteps: config.totalSteps,
        title: 'Medical research',
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
                    Text('Medical research', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Select your consent preference for each medical research activity.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 24),
                    _buildQuestion(
                      title:
                          'The administration of pharmaceuticals or placebos (inactive drug)',
                      value: _placebos,
                      onChanged: (v) => _placebos = v,
                    ),
                    _buildQuestion(
                      title: 'The use of equipment or a device',
                      value: _useEquipment,
                      onChanged: (v) => _useEquipment = v,
                    ),
                    _buildQuestion(
                      title:
                          'Providing health care that has not yet gained the support of a substantial number of practitioners in that field',
                      value: _lessPractitioners,
                      onChanged: (v) => _lessPractitioners = v,
                    ),
                    _buildQuestion(
                      title:
                          'Providing health care to carry out a comparative assessment',
                      value: _comparativeAssessment,
                      onChanged: (v) => _comparativeAssessment = v,
                    ),
                    _buildQuestion(
                      title: 'Taking blood samples',
                      value: _bloodSamples,
                      onChanged: (v) => _bloodSamples = v,
                    ),
                    _buildQuestion(
                      title:
                          'Taking samples of tissue or fluid from the body, including the mouth, throat, nasal cavity, eyes or ears',
                      value: _tissueSample,
                      onChanged: (v) => _tissueSample = v,
                    ),
                    _buildQuestion(
                      title:
                          'Any non-intrusive examination of the mouth, throat, nasal cavity, eyes or ears',
                      value: _nonIntrusiveTreatment,
                      onChanged: (v) => _nonIntrusiveTreatment = v,
                    ),
                    _buildQuestion(
                      title: 'Being observed',
                      value: _beingObserved,
                      onChanged: (v) => _beingObserved = v,
                    ),
                    _buildQuestion(
                      title:
                          'Undertaking a survey, interview or focus group',
                      value: _undertakingSurvey,
                      onChanged: (v) => _undertakingSurvey = v,
                    ),
                    _buildQuestion(
                      title:
                          'Collecting, using or disclosing information, including personal information',
                      value: _collectingDisclosing,
                      onChanged: (v) => _collectingDisclosing = v,
                    ),
                    _buildQuestion(
                      title:
                          'Considering or evaluating samples or information taken under an activity listed above',
                      value: _evaluatingSamples,
                      onChanged: (v) => _evaluatingSamples = v,
                    ),
                    _buildQuestion(
                      title: 'Any other medical research not listed above',
                      value: _other,
                      onChanged: (v) => _other = v,
                    ),
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

class _ResearchOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResearchOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5F0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1A7A4A)
                : const Color(0xFFD0D5DD),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFD0D5DD),
                  width: 1,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1A7A4A),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF101828)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
