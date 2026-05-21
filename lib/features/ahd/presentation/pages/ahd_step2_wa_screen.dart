import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD WA Step 2 — Your health conditions and concerns
///
/// API fields:
///   - health_conditions.major_health_conditions
///   - life_and_health_priorities.health_treatment_priority
class AhdStep2WaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep2WaScreen({super.key, required this.flowData});

  @override
  State<AhdStep2WaScreen> createState() => _AhdStep2WaScreenState();
}

class _AhdStep2WaScreenState extends State<AhdStep2WaScreen> {
  late bool _revokeAcd;
  late final TextEditingController _healthConditionsController;
  late final TextEditingController _treatmentPreferencesController;

  @override
  void initState() {
    super.initState();
    _revokeAcd = widget.flowData.waRevokeAcd ?? false;
    _healthConditionsController =
        TextEditingController(text: widget.flowData.waHealthConditions ?? '');
    _treatmentPreferencesController =
        TextEditingController(text: widget.flowData.waTreatmentPreferences ?? '');
  }

  @override
  void dispose() {
    _healthConditionsController.dispose();
    _treatmentPreferencesController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waRevokeAcd: _revokeAcd,
      waHealthConditions: _healthConditionsController.text.trim(),
      waTreatmentPreferences: _treatmentPreferencesController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(2), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: config.totalSteps,
        title: 'Your health conditions and concerns',
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
                    CheckboxListTile(
                      value: _revokeAcd,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (v) =>
                          setState(() => _revokeAcd = v ?? false),
                      title: Text(
                        'Please tick the box below to indicate that by making this Advance Health Directive you revoke all prior Advance Health Directives completed by you.',
                        style: AppTextStyles.questionTitle,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    Text('Your health conditions and concerns',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    Text(
                      'Please list any major health conditions below',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 12),
                    AppTextArea(
                      controller: _healthConditionsController,
                      label: 'Health conditions',
                      maxLines: 6,
                      minLines: 4,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Please describe what is important to you when talking to health professionals about your treatment',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 12),
                    AppTextArea(
                      controller: _treatmentPreferencesController,
                      label: 'Treatment preferences',
                      maxLines: 6,
                      minLines: 4,
                    ),
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
