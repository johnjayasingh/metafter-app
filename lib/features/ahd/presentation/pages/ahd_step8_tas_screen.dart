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

/// AHD Tasmania Step 8 — Interpreter/translator statement
///
/// API fields (in ahd_persons):
///   - WITNESS_INTERPRETER: full_name
///   - INTERPRETER: other.language, other.naati_number
class AhdStep8TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep8TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep8TasScreen> createState() => _AhdStep8TasScreenState();
}

class _AhdStep8TasScreenState extends State<AhdStep8TasScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _interpreterNameController;
  late final TextEditingController _interpreterNaatiController;
  late String? _interpreterLanguage;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _interpreterNameController =
        TextEditingController(text: d.tasInterpreterName ?? '');
    _interpreterNaatiController =
        TextEditingController(text: d.tasInterpreterNaati ?? '');
    _interpreterLanguage = d.tasInterpreterLanguage;
  }

  @override
  void dispose() {
    _interpreterNameController.dispose();
    _interpreterNaatiController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasInterpreterName: _interpreterNameController.text.trim(),
      tasInterpreterNaati: _interpreterNaatiController.text.trim(),
      tasInterpreterLanguage: _interpreterLanguage,
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
        title: 'Interpreter/translator statement',
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
                      Text('Interpreter/translator statement',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'If an interpreter/translator is used when this document is completed or witnessed, they must certify as follows:',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _interpreterNameController,
                        label: 'Name of interpreter/translator',
                      ),
                      const SizedBox(height: 16),
                      AppDropdown(
                        label: 'Language',
                        value: _interpreterLanguage,
                        items: InterpreterLanguages.values,
                        onChanged: (v) =>
                            setState(() => _interpreterLanguage = v),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _interpreterNaatiController,
                        label: 'NAATI number',
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
