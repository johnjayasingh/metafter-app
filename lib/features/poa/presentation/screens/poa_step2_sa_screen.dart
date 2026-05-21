import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA South Australia Step 2 — Donor details (name, address, second donor).
class PoaStep2Sa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep2Sa({super.key, required this.flowData});

  @override
  State<PoaStep2Sa> createState() => _PoaStep2SaState();
}

class _PoaStep2SaState extends State<PoaStep2Sa> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _donorNameController;
  late TextEditingController _donorAddressController;
  late TextEditingController _donorEmailController;

  late bool _hasSecondDonor;
  late TextEditingController _secondDonorNameController;
  late TextEditingController _secondDonorAddressController;
  late TextEditingController _secondDonorEmailController;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;

    _donorNameController =
        TextEditingController(text: fd.saDonorFullName ?? '');
    _donorAddressController =
        TextEditingController(text: fd.saDonorAddress ?? '');
    _donorEmailController =
        TextEditingController(text: fd.saDonorEmail ?? '');

    _hasSecondDonor = fd.saHasSecondDonor ?? false;
    _secondDonorNameController =
        TextEditingController(text: fd.saSecondDonorFullName ?? '');
    _secondDonorAddressController =
        TextEditingController(text: fd.saSecondDonorAddress ?? '');
    _secondDonorEmailController =
        TextEditingController(text: fd.saSecondDonorEmail ?? '');

  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _donorAddressController.dispose();
    _donorEmailController.dispose();
    _secondDonorNameController.dispose();
    _secondDonorAddressController.dispose();
    _secondDonorEmailController.dispose();
    super.dispose();
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saDonorFullName: _donorNameController.text.trim(),
      saDonorAddress: _donorAddressController.text.trim(),
      saDonorEmail: _donorEmailController.text.trim(),
      saHasSecondDonor: _hasSecondDonor,
      saSecondDonorFullName:
          _hasSecondDonor ? _secondDonorNameController.text.trim() : null,
      saSecondDonorAddress:
          _hasSecondDonor ? _secondDonorAddressController.text.trim() : null,
      saSecondDonorEmail:
          _hasSecondDonor ? _secondDonorEmailController.text.trim() : null,
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
      config.nextRoute(2),
      extra: _collectData(),
    );
    if (result != null) setState(() => _returnedFromNext = result);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
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
                      Text('Your details', style: AppTextStyles.pageTitle),
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
                        controller: _donorNameController,
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
                        controller: _donorAddressController,
                        label: 'Residential address',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your residential address'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('What is your email address?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _donorEmailController,
                        label: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Is there a second donor (eg. your spouse) who will also be appointing donees under this same document?',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _hasSecondDonor,
                              label: 'Yes',
                              onTap: () =>
                                  setState(() => _hasSecondDonor = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: !_hasSecondDonor,
                              label: 'No',
                              onTap: () =>
                                  setState(() => _hasSecondDonor = false),
                            ),
                          ),
                        ],
                      ),
                      if (_hasSecondDonor) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Second donor',
                                  style: AppTextStyles.pageTitle),
                              const SizedBox(height: 4),
                              const Divider(),
                              const SizedBox(height: 16),
                              Text('Second donor full legal name?',
                                  style: AppTextStyles.questionTitle),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: _secondDonorNameController,
                                label: 'Full legal name',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Please enter the second donor\'s name'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              Text('Second donor residential address?',
                                  style: AppTextStyles.questionTitle),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: _secondDonorAddressController,
                                label: 'Residential address',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Please enter the second donor\'s address'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              Text('Second donor email address?',
                                  style: AppTextStyles.questionTitle),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: _secondDonorEmailController,
                                label: 'Email address',
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                        ),
                      ],
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
