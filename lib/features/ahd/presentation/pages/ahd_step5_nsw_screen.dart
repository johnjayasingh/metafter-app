import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD NSW Step 5 — Organ and tissue donation
///
/// API fields:
///   - organ_and_body_donation.donate_organ
///   - organ_and_body_donation.consent_organ_donation
///   - organ_and_body_donation.donate_body
///   - organ_and_body_donation.consent_body_donation
class AhdStep5NswScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep5NswScreen({super.key, required this.flowData});

  @override
  State<AhdStep5NswScreen> createState() => _AhdStep5NswScreenState();
}

class _AhdStep5NswScreenState extends State<AhdStep5NswScreen> {
  late bool? _donateOrgans;
  late bool? _discussedDonation;
  late bool? _donateBody;
  late bool? _consentOrganDonation;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _donateOrgans = d.nswDonateOrgans;
    _discussedDonation = d.nswDiscussedDonation;
    _donateBody = d.nswDonateBody;
    _consentOrganDonation = d.nswConsentOrganDonation;
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      nswDonateOrgans: _donateOrgans,
      nswDiscussedDonation: _discussedDonation,
      nswDonateBody: _donateBody,
      nswConsentOrganDonation: _consentOrganDonation,
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(6), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 6, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 6,
        totalSteps: config.totalSteps,
        title: 'Specific requests for organ, tissue',
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
                    Text('Specific requests for organ, tissue',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    _buildYesNoQuestion(
                      'I would like to donate my organs and tissues for transplantation following my death.',
                      _donateOrgans,
                      (v) => setState(() => _donateOrgans = v),
                    ),
                    const SizedBox(height: 16),
                    _buildYesNoQuestion(
                      'I have discussed my organ and tissue donation wishes with my family',
                      _consentOrganDonation,
                      (v) => setState(() => _consentOrganDonation = v),
                    ),
                    const SizedBox(height: 16),
                    _buildYesNoQuestion(
                      'I would like to, or have already made arrangements to, donate my body',
                      _donateBody,
                      (v) => setState(() => _donateBody = v),
                    ),
                    const SizedBox(height: 16),
                    _buildYesNoQuestion(
                      'It is my wish to donate my organs for transplantation after my death. If I am dying, I consent to the doctors providing treatments for my organs before my death (including artificial ventilation, insertion of intravenous lines and administration of medications) intended only for the purpose of enabling me to donate my organs and tissue for transplantation.',
                      _discussedDonation,
                      (v) => setState(() => _discussedDonation = v),
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

  Widget _buildYesNoQuestion(
    String title,
    bool? selectedValue,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.questionTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: selectedValue == true,
                label: 'Yes',
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: selectedValue == false,
                label: 'No',
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
