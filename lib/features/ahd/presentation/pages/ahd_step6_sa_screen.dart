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

/// AHD South Australia Step 6 — Refusal/s of health care
///
/// API fields:
///   - medical_treatment_refuse
class AhdStep6SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep6SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep6SaScreen> createState() => _AhdStep6SaScreenState();
}

class _AhdStep6SaScreenState extends State<AhdStep6SaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _refusalController;

  @override
  void initState() {
    super.initState();
    _refusalController =
        TextEditingController(text: widget.flowData.saRefusalHealthCare ?? '');
  }

  @override
  void dispose() {
    _refusalController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saRefusalHealthCare: _refusalController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
        title: 'Refusal/s of health care',
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
                                text: 'Refusal/s of health care ',
                                style: AppTextStyles.pageTitle),
                            TextSpan(
                                text: '(optional)',
                                style: AppTextStyles.subtitle),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'I refuse the following health care:',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _refusalController,
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
