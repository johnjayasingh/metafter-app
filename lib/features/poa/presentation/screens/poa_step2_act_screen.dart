import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaStep2Act extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep2Act({super.key, required this.flowData});

  @override
  State<PoaStep2Act> createState() => _PoaStep2ActState();
}

class _PoaStep2ActState extends State<PoaStep2Act> {
  final _formKey = GlobalKey<FormState>();

  // ── Eligibility gates ──
  late bool _isOver18;
  late bool _understandsEpa;

  // ── Principal (appointor) ──
  late TextEditingController _principalFullNameController;
  late TextEditingController _principalAddressController;
  late TextEditingController _principalEmailController;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _isOver18 = fd.actIsOver18 ?? true;
    _understandsEpa = fd.actUnderstandsEpa ?? true;
    _principalFullNameController =
        TextEditingController(text: fd.actPrincipalFullName ?? '');
    _principalAddressController =
        TextEditingController(text: fd.actPrincipalAddress ?? '');
    _principalEmailController =
        TextEditingController(text: fd.actPrincipalEmail ?? '');
  }

  @override
  void dispose() {
    _principalFullNameController.dispose();
    _principalAddressController.dispose();
    _principalEmailController.dispose();
    super.dispose();
  }

  PoaFlowData _collectCurrentData() {
    return widget.flowData.copyWith(
      actIsOver18: _isOver18,
      actUnderstandsEpa: _understandsEpa,
      actPrincipalFullName: _principalFullNameController.text.trim(),
      actPrincipalAddress: _principalAddressController.text.trim(),
      actPrincipalEmail: _principalEmailController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!_isOver18) {
      SnackBarUtils.showError(context, 'You must be 18 years or older to create an EPA.');
      return;
    }
    if (!_understandsEpa) {
      SnackBarUtils.showError(context, 'You must understand the nature and effect of making an EPA.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final config = PoaFlowConfig.forState(widget.flowData.state);
    final updated = _collectCurrentData();
    final result = await context.push<PoaFlowData>(config.nextRoute(2), extra: updated);
    if (result != null && mounted) {
      // Merge returned data so going forward again preserves later steps' data
      setState(() {});
    }
  }

  void _handlePrevious() {
    context.pop(_collectCurrentData());
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
          currentStep: 2, userState: widget.flowData.state),
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
                      _buildEligibilitySection(),
                      const SizedBox(height: 32),
                      _buildPrincipalSection(),
                    ],
                  ),
                ),
              ),
            ),
            PoaBottomBar(
              onPrevious: _handlePrevious,
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eligibility gates', style: AppTextStyles.pageTitle),
        const SizedBox(height: 20),
        Text('Are you 18 years or older?', style: AppTextStyles.subtitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: _isOver18,
                label: 'Yes',
                onTap: () => setState(() => _isOver18 = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: !_isOver18,
                label: 'No',
                onTap: () => setState(() => _isOver18 = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Do you understand what you\'re signing and are you signing freely?',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: _understandsEpa,
                label: 'Yes',
                onTap: () => setState(() => _understandsEpa = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: !_understandsEpa,
                label: 'No',
                onTap: () => setState(() => _understandsEpa = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrincipalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Principal (appointor)', style: AppTextStyles.pageTitle),
        const SizedBox(height: 20),
        AppTextField(
          controller: _principalFullNameController,
          label: 'Full legal name',
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter your full legal name'
              : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _principalAddressController,
          label: 'Residential address',
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter your residential address'
              : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _principalEmailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter your email address'
              : null,
        ),
      ],
    );
  }
}
