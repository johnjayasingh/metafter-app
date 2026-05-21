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

/// POA South Australia Step 3 — Donee/attorney details and how they act.
class PoaStep3Sa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep3Sa({super.key, required this.flowData});

  @override
  State<PoaStep3Sa> createState() => _PoaStep3SaState();
}

class _PoaStep3SaState extends State<PoaStep3Sa> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _doneeNameController;
  late TextEditingController _doneeAddressController;
  late TextEditingController _doneeEmailController;
  late String _doneeActingMethod;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _doneeNameController =
        TextEditingController(text: fd.doneeName ?? '');
    _doneeAddressController =
        TextEditingController(text: fd.doneeAddress ?? '');
    _doneeEmailController =
        TextEditingController(text: fd.doneeEmail ?? '');
    _doneeActingMethod = fd.doneeActingMethod ?? 'JOINTLY';
  }

  @override
  void dispose() {
    _doneeNameController.dispose();
    _doneeAddressController.dispose();
    _doneeEmailController.dispose();
    super.dispose();
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      doneeName: _doneeNameController.text.trim(),
      doneeAddress: _doneeAddressController.text.trim(),
      doneeEmail: _doneeEmailController.text.trim(),
      doneeActingMethod: _doneeActingMethod,
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
                      Text('Appointment: Donee(s)',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Who are you appointing as your donee(s) (attorney(s))?',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 20),
                      Text('Donee full legal name?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _doneeNameController,
                        label: 'Full legal name',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter the donee\'s full legal name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Donee address?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _doneeAddressController,
                        label: 'Address',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter the donee\'s address'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Donee email address?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _doneeEmailController,
                        label: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'When there is more than one donee, how do you want them to act?',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 16),
                      RadioListOption(
                        isSelected: _doneeActingMethod == 'JOINTLY',
                        title: 'Jointly (they must act together)',
                        onTap: () =>
                            setState(() => _doneeActingMethod = 'JOINTLY'),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _doneeActingMethod == 'JOINTLY_SEVERALLY',
                        title: 'Jointly and severally (either can act)',
                        onTap: () => setState(
                            () => _doneeActingMethod = 'JOINTLY_SEVERALLY'),
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
