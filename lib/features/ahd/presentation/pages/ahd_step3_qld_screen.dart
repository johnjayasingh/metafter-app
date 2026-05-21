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

/// AHD Queensland Step 3 — Your values, wishes and preferences
///
/// API fields:
///   - health_conditions.things_important_for_me
///   - health_conditions.beliefs_considered_during_health_care
///   - health_conditions.nearing_death_preference
///   - health_conditions.people_not_to_involve_healthcare_discussion
class AhdStep3QldScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3QldScreen({super.key, required this.flowData});

  @override
  State<AhdStep3QldScreen> createState() => _AhdStep3QldScreenState();
}

class _AhdStep3QldScreenState extends State<AhdStep3QldScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _thingsImportantController;
  late final TextEditingController _culturalValuesController;
  late final TextEditingController _nearingDeathController;
  late final TextEditingController _peopleNotInvolvedController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _thingsImportantController =
        TextEditingController(text: d.thingsImportant ?? '');
    _culturalValuesController =
        TextEditingController(text: d.culturalValues ?? '');
    _nearingDeathController =
        TextEditingController(text: d.nearingDeathComfort ?? '');
    _peopleNotInvolvedController =
        TextEditingController(text: d.peopleNotInvolved ?? '');
  }

  @override
  void dispose() {
    _thingsImportantController.dispose();
    _culturalValuesController.dispose();
    _nearingDeathController.dispose();
    _peopleNotInvolvedController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      thingsImportant: _thingsImportantController.text.trim(),
      culturalValues: _culturalValuesController.text.trim(),
      nearingDeathComfort: _nearingDeathController.text.trim(),
      peopleNotInvolved: _peopleNotInvolvedController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(3), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: config.totalSteps,
        title: 'Your values, wishes and preferences',
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
                      Text('Your values, wishes and preferences',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      AppTextArea(
                        controller: _thingsImportantController,
                        label:
                            'These things are important to me: (Describe what living well means to you now and into the future)',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      AppTextArea(
                        controller: _culturalValuesController,
                        label:
                            'These are the cultural, religious or spiritual values, rituals or beliefs I would like considered in my health care',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      AppTextArea(
                        controller: _nearingDeathController,
                        label:
                            'When I am nearing death, the following would be important to me and would comfort me: (e.g. you may prefer to die at home or you may like a certain type of music played)',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      AppTextArea(
                        controller: _peopleNotInvolvedController,
                        label:
                            'I would prefer these people not be involved in discussions about my health care',
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
