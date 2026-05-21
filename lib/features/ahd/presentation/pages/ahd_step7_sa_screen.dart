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

/// AHD South Australia Step 7 — Organ and Tissue Donation
///
/// API fields:
///   - organ_donation (OrganDonationChoice)
///   - organ_and_body_donation.organ_donation_instruction
class AhdStep7SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep7SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep7SaScreen> createState() => _AhdStep7SaScreenState();
}

class _AhdStep7SaScreenState extends State<AhdStep7SaScreen> {
  late String? _organDonationChoice;
  late final TextEditingController _organDonationInstructionController;

  @override
  void initState() {
    super.initState();
    _organDonationChoice = widget.flowData.saOrganDonationChoice;
    _organDonationInstructionController = TextEditingController(
        text: widget.flowData.saOrganDonationInstruction ?? '');
  }

  @override
  void dispose() {
    _organDonationInstructionController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saOrganDonationChoice: _organDonationChoice,
      saOrganDonationInstruction:
          _organDonationInstructionController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(7), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 7, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 7,
        totalSteps: config.totalSteps,
        title: 'Organ and Tissue Donation',
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
                    Text('Organ and Tissue Donation',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Select one statement below and mark your response by checking the box.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 16),
                    RadioListOption(
                      title:
                          'I am willing to be considered for organ and tissue donation, and recognize that medical interventions may be necessary for donation to take place.',
                      isSelected: _organDonationChoice ==
                          OrganDonationChoice.willing,
                      onTap: () => setState(() => _organDonationChoice =
                          OrganDonationChoice.willing),
                    ),
                    RadioListOption(
                      title:
                          'I am not willing to be considered for organ and tissue donation.',
                      isSelected: _organDonationChoice ==
                          OrganDonationChoice.notWilling,
                      onTap: () => setState(() => _organDonationChoice =
                          OrganDonationChoice.notWilling),
                    ),
                    if (_organDonationChoice != null) ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _organDonationInstructionController,
                        label: 'Enter details',
                        maxLines: 5,
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
