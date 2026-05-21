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

/// AHD South Australia Step 5 — Values and wishes
///
/// API fields:
///   - health_conditions.things_important_for_me
///   - living_preferences.wish_to_live
///   - living_preferences.health_treatment_priority
///   - health_conditions.people_not_to_involve_healthcare_discussion
///   - health_conditions.nearing_death_preference
///   - treatment_decisions.healthcare_preferred
class AhdStep5SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep5SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep5SaScreen> createState() => _AhdStep5SaScreenState();
}

class _AhdStep5SaScreenState extends State<AhdStep5SaScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _livingWellController;
  late final TextEditingController _whereToLiveController;
  late final TextEditingController _otherThingsKnownController;
  late final TextEditingController _otherPeopleInvolvedController;
  late final TextEditingController _nearingDeathController;
  late final TextEditingController _healthcarePreferredController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _livingWellController =
        TextEditingController(text: d.saLivingWell ?? '');
    _whereToLiveController =
        TextEditingController(text: d.saWhereToLive ?? '');
    _otherThingsKnownController =
        TextEditingController(text: d.saOtherThingsKnown ?? '');
    _otherPeopleInvolvedController =
        TextEditingController(text: d.saOtherPeopleInvolved ?? '');
    _nearingDeathController =
        TextEditingController(text: d.saNearingDeath ?? '');
    _healthcarePreferredController =
        TextEditingController(text: d.saHealthcarePreferred ?? '');
  }

  @override
  void dispose() {
    _livingWellController.dispose();
    _whereToLiveController.dispose();
    _otherThingsKnownController.dispose();
    _otherPeopleInvolvedController.dispose();
    _nearingDeathController.dispose();
    _healthcarePreferredController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saLivingWell: _livingWellController.text.trim(),
      saWhereToLive: _whereToLiveController.text.trim(),
      saOtherThingsKnown: _otherThingsKnownController.text.trim(),
      saOtherPeopleInvolved: _otherPeopleInvolvedController.text.trim(),
      saNearingDeath: _nearingDeathController.text.trim(),
      saHealthcarePreferred: _healthcarePreferredController.text.trim(),
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
        title: 'Values and wishes',
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
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Values and wishes ',
                                style: AppTextStyles.pageTitle),
                            TextSpan(
                                text: '(optional)',
                                style: AppTextStyles.subtitle),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'What is important to me: What living well means to me.',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Refer to Part 3a of the Do-It-Yourself Guide.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _livingWellController,
                        label: '',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Where I wish to live',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Refer to Part 3c of the Do-It-Yourself Guide.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _whereToLiveController,
                        label: '',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Other things I would like known are',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Refer to Part 3d of the Do-It-Yourself Guide.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _otherThingsKnownController,
                        label: '',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Other people I would like involved in discussions about my care',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Refer to Part 3e of the Do-It-Yourself Guide.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _otherPeopleInvolvedController,
                        label: '',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'I am nearing death, the following would be important to me',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Refer to Part 3f of the Do-It-Yourself Guide.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _nearingDeathController,
                        label: '',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Healthcare I prefer',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _healthcarePreferredController,
                        label: '',
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
