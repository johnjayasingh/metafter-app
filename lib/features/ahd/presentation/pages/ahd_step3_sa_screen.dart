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

/// AHD South Australia Step 3 — Substitute Decision-Maker Acceptance
///
/// API fields (in ahd_persons):
///   - SUBSTITUTE_DECISION_MAKER: other.signature, other.date
///   - SUBSTITUTE_DECISION_MAKER_SECONDARY: other.signature, other.date
class AhdStep3SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep3SaScreen> createState() => _AhdStep3SaScreenState();
}

class _AhdStep3SaScreenState extends State<AhdStep3SaScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _subDm1FullNameController;
  late final TextEditingController _subDm1AddressController;
  late final TextEditingController _subDm1DateController;
  late final TextEditingController _subDm2FullNameController;
  late final TextEditingController _subDm2AddressController;
  late final TextEditingController _subDm2DateController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _subDm1FullNameController =
        TextEditingController(text: d.saSubDm1FullName ?? '');
    _subDm1AddressController =
        TextEditingController(text: d.saSubDm1Address ?? '');
    _subDm1DateController =
        TextEditingController(text: d.saSubDm1Date ?? '');
    _subDm2FullNameController =
        TextEditingController(text: d.saSubDm2FullName ?? '');
    _subDm2AddressController =
        TextEditingController(text: d.saSubDm2Address ?? '');
    _subDm2DateController =
        TextEditingController(text: d.saSubDm2Date ?? '');
  }

  @override
  void dispose() {
    _subDm1FullNameController.dispose();
    _subDm1AddressController.dispose();
    _subDm1DateController.dispose();
    _subDm2FullNameController.dispose();
    _subDm2AddressController.dispose();
    _subDm2DateController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saSubDm1FullName: _subDm1FullNameController.text.trim(),
      saSubDm1Address: _subDm1AddressController.text.trim(),
      saSubDm1Date: _subDm1DateController.text.trim(),
      saSubDm2FullName: _subDm2FullNameController.text.trim(),
      saSubDm2Address: _subDm2AddressController.text.trim(),
      saSubDm2Date: _subDm2DateController.text.trim(),
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
        title: 'Substitute Decision-Maker Acceptance',
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
                      Text('Substitute Decision-Maker Acceptance',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      // First preferred
                      Text(
                        'Substitute Decision-Maker (first preferred)',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _subDm1FullNameController,
                        label: 'Full name',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _subDm1AddressController,
                        label: 'Address',
                      ),
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _subDm1DateController,
                        label: 'Date',
                        onDateSelected: (date) {
                          _subDm1DateController.text =
                              AppDatePickerField.formatDate(date);
                        },
                      ),

                      const SizedBox(height: 32),

                      // Second
                      Text(
                        'Substitute Decision-Maker',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _subDm2FullNameController,
                        label: 'Full name',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _subDm2AddressController,
                        label: 'Address',
                      ),
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _subDm2DateController,
                        label: 'Date',
                        onDateSelected: (date) {
                          _subDm2DateController.text =
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
