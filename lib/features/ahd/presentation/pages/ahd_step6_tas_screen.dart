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

/// AHD Tasmania Step 6 — Key signature (primary person sign)
///
/// API fields:
///   - ahd_persons (PRIMARY_PERSON): signature, date
class AhdStep6TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep6TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep6TasScreen> createState() => _AhdStep6TasScreenState();
}

class _AhdStep6TasScreenState extends State<AhdStep6TasScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _signFullNameController;
  late final TextEditingController _signDateController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _signFullNameController =
        TextEditingController(text: d.tasSignFullName ?? '');
    _signDateController =
        TextEditingController(text: d.tasSignDate ?? '');
  }

  @override
  void dispose() {
    _signFullNameController.dispose();
    _signDateController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasSignFullName: _signFullNameController.text.trim(),
      tasSignDate: _signDateController.text.trim(),
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
        title: 'Key signature',
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
                      Text('Key signature',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _signFullNameController,
                        label: 'Full name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _signDateController,
                        label: 'Date',
                        onDateSelected: (date) {
                          setState(() {
                            _signDateController.text =
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
