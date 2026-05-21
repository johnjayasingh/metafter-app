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

/// AHD Tasmania Step 9 — Expiry date of ACD
///
/// API fields:
///   - acd_expiry_date
class AhdStep9TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep9TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep9TasScreen> createState() => _AhdStep9TasScreenState();
}

class _AhdStep9TasScreenState extends State<AhdStep9TasScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _expiryDateController;

  @override
  void initState() {
    super.initState();
    _expiryDateController =
        TextEditingController(text: widget.flowData.tasExpiryDate ?? '');
  }

  @override
  void dispose() {
    _expiryDateController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasExpiryDate: _expiryDateController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
        title: 'Expiry date of ACD',
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
                      Text('Expiry date of ACD',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'This ACD expires on:',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),
                      AppDatePickerField(
                        controller: _expiryDateController,
                        label: 'Date',
                        onDateSelected: (date) {
                          setState(() {
                            _expiryDateController.text =
                                AppDatePickerField.formatDate(date);
                          });
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
