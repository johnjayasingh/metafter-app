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

/// AHD South Australia Step 8 — Expiry date
///
/// API fields:
///   - acd_expiry_date
class AhdStep8SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep8SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep8SaScreen> createState() => _AhdStep8SaScreenState();
}

class _AhdStep8SaScreenState extends State<AhdStep8SaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _expiryDateController;

  @override
  void initState() {
    super.initState();
    _expiryDateController =
        TextEditingController(text: widget.flowData.saExpiryDate ?? '');
  }

  @override
  void dispose() {
    _expiryDateController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saExpiryDate: _expiryDateController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(8), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 8, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 8,
        totalSteps: config.totalSteps,
        title: 'Expiry date',
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
                                text: 'Expiry date ',
                                style: AppTextStyles.pageTitle),
                            TextSpan(
                                text: '(optional)',
                                style: AppTextStyles.subtitle),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This Advance Care Directive expires on:',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppDatePickerField(
                        controller: _expiryDateController,
                        label: 'Expiry date',
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 36500)),
                        onDateSelected: (date) {
                          _expiryDateController.text =
                              AppDatePickerField.formatDate(date);
                        },
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
