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

/// AHD NT Step 3 — Other information
///
/// API fields:
///   - declarations_and_wishes.other_things_known
///   - declarations_and_wishes.cultural_request
///   - declarations_and_wishes.after_death_importance
///   - declarations_and_wishes.nearing_death_instruction
class AhdStep3NtScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3NtScreen({super.key, required this.flowData});

  @override
  State<AhdStep3NtScreen> createState() => _AhdStep3NtScreenState();
}

class _AhdStep3NtScreenState extends State<AhdStep3NtScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _otherMedicalInfoController;
  late final TextEditingController _culturalRequestsController;
  late final TextEditingController _afterDeathPreferencesController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _otherMedicalInfoController =
        TextEditingController(text: d.ntOtherMedicalInfo ?? '');
    _culturalRequestsController =
        TextEditingController(text: d.ntCulturalRequests ?? '');
    _afterDeathPreferencesController =
        TextEditingController(text: d.ntAfterDeath1 ?? d.ntAfterDeath2 ?? '');
  }

  @override
  void dispose() {
    _otherMedicalInfoController.dispose();
    _culturalRequestsController.dispose();
    _afterDeathPreferencesController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      ntOtherMedicalInfo: _otherMedicalInfoController.text.trim(),
      ntCulturalRequests: _culturalRequestsController.text.trim(),
      ntAfterDeath1: _afterDeathPreferencesController.text.trim(),
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
        title: 'Other information',
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
                      Text('Other information',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      Text(
                        'Any other information that may help with medical decisions?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _otherMedicalInfoController,
                        label: 'Other medical information',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Any cultural or spiritual requests?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _culturalRequestsController,
                        label: 'Cultural requests',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'After death, what is important to you? For example, a ceremonial smoking, or for my body to be returned to my birth country, blessings, cremation, burial etc.',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _afterDeathPreferencesController,
                        label: 'After death preferences',
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
