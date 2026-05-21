import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Victoria Step 3 — Values directive
///
/// API fields:
///   - declarations_and_wishes.what_matter_most
///   - declarations_and_wishes.what_worries_most
///   - declarations_and_wishes.unacceptable_medical_treatment_outcome
///   - declarations_and_wishes.other_things_known
///   - declarations_and_wishes.other_people_involved_in_care_discussion
///   - health_conditions.nearing_death_preference
///   - organ_donation (CONSENT / REFUSE)
class AhdStep3VicScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3VicScreen({super.key, required this.flowData});

  @override
  State<AhdStep3VicScreen> createState() => _AhdStep3VicScreenState();
}

class _AhdStep3VicScreenState extends State<AhdStep3VicScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _whatMattersController;
  late final TextEditingController _whatWorriesController;
  late final TextEditingController _unacceptableOutcomesController;
  late final TextEditingController _otherThingsKnownController;
  late final TextEditingController _peopleInvolvedController;
  late final TextEditingController _nearingDeathController;
  late String? _organDonation;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _whatMattersController =
        TextEditingController(text: d.thingsImportant ?? '');
    _whatWorriesController =
        TextEditingController(text: d.thingsWorry ?? '');
    _unacceptableOutcomesController =
        TextEditingController(text: d.vicUnacceptableOutcomes ?? '');
    _otherThingsKnownController =
        TextEditingController(text: d.vicOtherThingsKnown ?? '');
    _peopleInvolvedController =
        TextEditingController(text: d.vicPeopleInvolved ?? '');
    _nearingDeathController =
        TextEditingController(text: d.nearingDeathComfort ?? '');
    _organDonation = d.vicOrganDonation;
  }

  @override
  void dispose() {
    _whatMattersController.dispose();
    _whatWorriesController.dispose();
    _unacceptableOutcomesController.dispose();
    _otherThingsKnownController.dispose();
    _peopleInvolvedController.dispose();
    _nearingDeathController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      thingsImportant: _whatMattersController.text.trim(),
      thingsWorry: _whatWorriesController.text.trim(),
      vicUnacceptableOutcomes: _unacceptableOutcomesController.text.trim(),
      vicOtherThingsKnown: _otherThingsKnownController.text.trim(),
      vicPeopleInvolved: _peopleInvolvedController.text.trim(),
      nearingDeathComfort: _nearingDeathController.text.trim(),
      vicOrganDonation: _organDonation,
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
        title: 'Values directive',
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
                      Text('Values directive',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      Text('What matters most in my life',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _whatMattersController,
                        label: 'What matters most in my life',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text('What worries me most about my future',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _whatWorriesController,
                        label: 'What worries me most',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'For me, unacceptable outcomes of medical treatment after illness or injury are',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _unacceptableOutcomesController,
                        label: 'Unacceptable outcomes',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text('Other things I would like known are',
                          style: AppTextStyles.questionTitle),
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
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _peopleInvolvedController,
                        label: '',
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'If I am nearing death the following things would be important to me',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _nearingDeathController,
                        label: '',
                        maxLines: 5,
                        minLines: 3,
                      ),

                      _buildSectionDivider(),

                      // ── Organ and Tissue Donation ──
                      Text('Organ and Tissue Donation',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 16),
                      RadioListOption(
                        isSelected:
                            _organDonation == OrganDonationChoice.willing,
                        title:
                            'I am willing to be considered for organ and tissue donation, and recognize that medical interventions may be necessary for donation to take place.',
                        onTap: () => setState(() =>
                            _organDonation = OrganDonationChoice.willing),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected:
                            _organDonation == OrganDonationChoice.notWilling,
                        title:
                            'I am not willing to be considered for organ and tissue donation.',
                        onTap: () => setState(() =>
                            _organDonation = OrganDonationChoice.notWilling),
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

  Widget _buildSectionDivider() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(height: 1, color: AppColors.borderGray),
        const SizedBox(height: 32),
      ],
    );
  }
}
