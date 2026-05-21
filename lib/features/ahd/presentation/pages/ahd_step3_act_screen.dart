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

/// AHD ACT Step 3 — Certification & Directed person (helper)
///
/// Sections:
///   1. Certification (static text)
///   2. Directed person (helper) — HELPER: full_name, address
class AhdStep3ActScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3ActScreen({super.key, required this.flowData});

  @override
  State<AhdStep3ActScreen> createState() => _AhdStep3ActScreenState();
}

class _AhdStep3ActScreenState extends State<AhdStep3ActScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _helperNameController;
  late final TextEditingController _helperAddressController;

  @override
  void initState() {
    super.initState();
    _helperNameController =
        TextEditingController(text: widget.flowData.actDirectedPersonName ?? '');
    _helperAddressController =
        TextEditingController(text: widget.flowData.actDirectedPersonAddress ?? '');
  }

  @override
  void dispose() {
    _helperNameController.dispose();
    _helperAddressController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      actDirectedPersonName: _helperNameController.text.trim(),
      actDirectedPersonAddress: _helperAddressController.text.trim(),
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
        title: 'Certification',
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
                      // ═══ Section 1: Certification ═══
                      Text(
                        'Certification',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I certify that',
                              style: AppTextStyles.questionTitle,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ' i. I am an adult',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ' ii. I do not have a guardian appointed or have impaired decision-making capacity',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ' iii. this direction is made voluntarily and without inducement or compulsion',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'OR',
                          style: AppTextStyles.pageTitle,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ═══ Section 2: Directed person (helper) ═══
                      Text(
                        'I directed the following person to sign this direction on my behalf',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _helperNameController,
                        label: 'Name',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _helperAddressController,
                        label: 'Address of person signing by direction',
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
