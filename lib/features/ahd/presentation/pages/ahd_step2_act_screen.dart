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

/// AHD ACT Step 2 — Advance Consent Direction
///
/// Sections:
///   1. Medical treatment refuse → `medical_treatment_refuse`
///   2. Previous direction revoked → `is_acd_revoked`
class AhdStep2ActScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep2ActScreen({super.key, required this.flowData});

  @override
  State<AhdStep2ActScreen> createState() => _AhdStep2ActScreenState();
}

class _AhdStep2ActScreenState extends State<AhdStep2ActScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _medicalTreatmentRefuseController;
  late bool _isAcdRevoked;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _medicalTreatmentRefuseController =
        TextEditingController(text: d.actMedicalTreatmentRefuse ?? '');
    _isAcdRevoked = d.actRevokePreviousDirections ?? false;
  }

  @override
  void dispose() {
    _medicalTreatmentRefuseController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      actMedicalTreatmentRefuse:
          _medicalTreatmentRefuseController.text.trim(),
      actRevokePreviousDirections: _isAcdRevoked,
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
        title: 'Advance Consent Direction',
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
                      // ═══ Section 1: Medical treatment refuse ═══
                      AppTextArea(
                        controller: _medicalTreatmentRefuseController,
                        label:
                            'Make this direction to refuse, or require the withdrawal of, medical treatment generally or a particular kind of medical treatment',
                        maxLines: 6,
                        minLines: 4,
                      ),

                      _buildSectionDivider(),

                      // ═══ Section 2: Previous direction revoked ═══
                      Text(
                        'Previous direction revoked',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: CheckboxListTile(
                          value: _isAcdRevoked,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (value) {
                            setState(() {
                              _isAcdRevoked = value ?? false;
                            });
                          },
                          title: Text(
                            'I revoke all directions previously made by me under the Medical Treatment Act 1994 (if any) and all other directions made by me under the Medical Treatment (Health Directions) Act 2006 (if any).',
                            style: AppTextStyles.bodyMedium,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
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
