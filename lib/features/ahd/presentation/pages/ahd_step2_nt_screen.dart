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

/// AHD NT Step 2 — Advance care statement
///
/// API fields:
///   - living_preferences.wish_to_live
///   - living_preferences.nearing_death_goals_detail
///   - living_preferences.nearing_death_unacceptable
///   - treatment_decisions.consent_palliative_comfort_care
///   - living_preferences.where_to_die (HOME/HOSPITAL/OTHER)
///   - living_preferences.where_to_die_instruction
class AhdStep2NtScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep2NtScreen({super.key, required this.flowData});

  @override
  State<AhdStep2NtScreen> createState() => _AhdStep2NtScreenState();
}

class _AhdStep2NtScreenState extends State<AhdStep2NtScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lifeMeaningController;
  late final TextEditingController _nearingDeathGoalsController;
  late final TextEditingController _unacceptableOutcomesController;
  late final TextEditingController _palliativeCareController;
  late final TextEditingController _whereToDieController;
  late String? _whereToDieChoice;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _lifeMeaningController =
        TextEditingController(text: d.ntLifeMeaning ?? '');
    _nearingDeathGoalsController =
        TextEditingController(text: d.ntNearingDeathGoals ?? '');
    _unacceptableOutcomesController =
        TextEditingController(text: d.ntUnacceptableOutcomes ?? '');
    _palliativeCareController =
        TextEditingController(text: d.ntPalliativeCare ?? '');
    _whereToDieController =
        TextEditingController(text: d.ntWhereToDie ?? '');
    _whereToDieChoice = d.ntWhereToDieChoice;
  }

  @override
  void dispose() {
    _lifeMeaningController.dispose();
    _nearingDeathGoalsController.dispose();
    _unacceptableOutcomesController.dispose();
    _palliativeCareController.dispose();
    _whereToDieController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      ntLifeMeaning: _lifeMeaningController.text.trim(),
      ntNearingDeathGoals: _nearingDeathGoalsController.text.trim(),
      ntUnacceptableOutcomes: _unacceptableOutcomesController.text.trim(),
      ntPalliativeCare: _palliativeCareController.text.trim(),
      ntWhereToDie: _whereToDieController.text.trim(),
      ntWhereToDieChoice: _whereToDieChoice,
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
        title: 'Advance care statement',
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
                      Text('Advanced care statement',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      Text(
                        'What gives your life meaning? What do you value most in life? For example, independence, being on country/at home, being able to work, food, family etc',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _lifeMeaningController,
                        label: 'Life meaning',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'If nearing death, what are your goals/priorities? What is most important to you? For example, dignity, to be comfortable, and to have my friends and family around me etc.',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _nearingDeathGoalsController,
                        label: 'Nearing death goals',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'If nearing death, what is unacceptable to you? What do you NOT want? For example, not wanting particular family or people to visit or see me, being alone and feeling helpless etc.',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _unacceptableOutcomesController,
                        label: 'Unacceptable outcomes',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Consent to palliative and comfort care so that you can feel better, even though it won\'t cure you',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _palliativeCareController,
                        label: 'Palliative care consent',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Where would you like to finish up?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      RadioListOption(
                        isSelected: _whereToDieChoice ==
                            NtWhereToDieChoice.atHomeOnCountry,
                        title: 'At home / on country',
                        onTap: () => setState(() => _whereToDieChoice =
                            NtWhereToDieChoice.atHomeOnCountry),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _whereToDieChoice ==
                            NtWhereToDieChoice.hospitalHospice,
                        title: 'Hospital / hospice',
                        onTap: () => setState(() => _whereToDieChoice =
                            NtWhereToDieChoice.hospitalHospice),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected:
                            _whereToDieChoice == NtWhereToDieChoice.other,
                        title: 'Other',
                        onTap: () => setState(() =>
                            _whereToDieChoice = NtWhereToDieChoice.other),
                      ),
                      if (_whereToDieChoice == NtWhereToDieChoice.other) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _whereToDieController,
                          label: 'Please specify',
                          maxLines: 3,
                          minLines: 2,
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
