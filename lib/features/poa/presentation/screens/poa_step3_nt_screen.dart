import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA Northern Territory Step 3 — Donor details (name, address, DOB).
class PoaStep3Nt extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep3Nt({super.key, required this.flowData});

  @override
  State<PoaStep3Nt> createState() => _PoaStep3NtState();
}

class _PoaStep3NtState extends State<PoaStep3Nt> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _fullNameController =
        TextEditingController(text: fd.ntDonorFullName ?? '');
    _addressController =
        TextEditingController(text: fd.ntDonorAddress ?? '');
    _dobController = TextEditingController(text: fd.ntDonorDob ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      ntDonorFullName: _fullNameController.text.trim(),
      ntDonorAddress: _addressController.text.trim(),
      ntDonorDob: _dobController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
      config.nextRoute(3),
      extra: _collectData(),
    );
    if (result != null) setState(() => _returnedFromNext = result);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: config.totalSteps,
        title: 'Enduring power of attorney',
        enableDrawer: true,
        exitTitle: 'Exit power of attorney?',
        exitDescription:
            'Your progress will be lost. You can start a new power of attorney at any time.',
        exitDiscardButtonText: 'Exit POA',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 4),
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
                      Text('Donor', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your personal details as the donor.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 20),
                      Text('What is your full legal name?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _fullNameController,
                        label: 'Full legal name',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your full legal name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('What is your residential address?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _addressController,
                        label: 'Residential address',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your residential address'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('What is your date of birth?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppDatePickerField(
                        controller: _dobController,
                        label: 'Date of birth',
                        isRequired: true,
                        onDateSelected: (date) {
                          _dobController.text =
                              AppDatePickerField.formatDate(date);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PoaBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
