import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA Western Australia Step 2 — Document details (donor info + EPA date).
class PoaStep2Wa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep2Wa({super.key, required this.flowData});

  @override
  State<PoaStep2Wa> createState() => _PoaStep2WaState();
}

class _PoaStep2WaState extends State<PoaStep2Wa> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _epaDateController;
  late TextEditingController _fullLegalNameController;
  late TextEditingController _residentialAddressController;
  late TextEditingController _emailController;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _epaDateController = TextEditingController(text: fd.waEpaDate ?? '');
    _fullLegalNameController =
        TextEditingController(text: fd.waFullLegalName ?? '');
    _residentialAddressController =
        TextEditingController(text: fd.waResidentialAddress ?? '');
    _emailController = TextEditingController(text: fd.waEmail ?? '');
  }

  @override
  void dispose() {
    _epaDateController.dispose();
    _fullLegalNameController.dispose();
    _residentialAddressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waEpaDate: _epaDateController.text.trim(),
      waFullLegalName: _fullLegalNameController.text.trim(),
      waResidentialAddress: _residentialAddressController.text.trim(),
      waEmail: _emailController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_epaDateController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please select the EPA date.');
      return;
    }
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
                      Text('Document details', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your personal details for this Enduring Power of Attorney.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 20),
                      Text('What is the date of this EPA?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppDatePickerField(
                        controller: _epaDateController,
                        label: 'EPA date',
                        isRequired: true,
                        onDateSelected: (date) {
                          _epaDateController.text =
                              AppDatePickerField.formatDate(date);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('What is your full legal name?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _fullLegalNameController,
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
                        controller: _residentialAddressController,
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
                        controller: _emailController,
                        label: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your email address'
                            : null,
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
