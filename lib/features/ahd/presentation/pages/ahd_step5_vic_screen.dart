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

/// AHD Victoria Step 5 — Witnessing
///
/// API fields (in ahd_persons):
///   - WITNESS_MEDICAL_PRACTITIONER: full_name, other.qualification
///   - WITNESS_PERSON: full_name
class AhdStep5VicScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep5VicScreen({super.key, required this.flowData});

  @override
  State<AhdStep5VicScreen> createState() => _AhdStep5VicScreenState();
}

class _AhdStep5VicScreenState extends State<AhdStep5VicScreen> {
  final _formKey = GlobalKey<FormState>();

  // Witness 1 — Registered medical practitioner
  late final TextEditingController _witness1NameController;
  late final TextEditingController _witness1QualificationController;

  // Witness 2 — Adult witness
  late final TextEditingController _witness2NameController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _witness1NameController =
        TextEditingController(text: d.vicWitness1FullName ?? '');
    _witness1QualificationController =
        TextEditingController(text: d.vicWitness1Qualification ?? '');
    _witness2NameController =
        TextEditingController(text: d.vicWitness2FullName ?? '');
  }

  @override
  void dispose() {
    _witness1NameController.dispose();
    _witness1QualificationController.dispose();
    _witness2NameController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      vicWitness1FullName: _witness1NameController.text.trim(),
      vicWitness1Qualification:
          _witness1QualificationController.text.trim(),
      vicWitness2FullName: _witness2NameController.text.trim(),
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
        title: 'Witnessing',
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
                      Text('Witnessing', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      // ── Witness 1 — Registered medical practitioner ──
                      Text(
                        'Witness 1 – Registered medical practitioner',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _witness1NameController,
                        label: 'Full name of registered medical practitioner',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _witness1QualificationController,
                        label:
                            'Qualification and AHPRA number of registered medical practitioner',
                        isRequired: true,
                      ),

                      _buildSectionDivider(),

                      // ── Witness 2 — Adult witness ──
                      Text(
                        'Witness 2 – Adult witness',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _witness2NameController,
                        label: 'Full name of witness',
                        isRequired: true,
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
