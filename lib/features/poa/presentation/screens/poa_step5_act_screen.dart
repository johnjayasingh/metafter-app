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
import '../../data/services/poa_service.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaStep5Act extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep5Act({super.key, required this.flowData});

  @override
  State<PoaStep5Act> createState() => _PoaStep5ActState();
}

class _PoaStep5ActState extends State<PoaStep5Act> {
  final _formKey = GlobalKey<FormState>();
  final PoaService _poaService = PoaService();

  late bool _signingSelf;
  late TextEditingController _directedSignerNameController;
  late TextEditingController _directedSignerAddressController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _signingSelf = fd.actSigningSelf ?? true;
    _directedSignerNameController =
        TextEditingController(text: fd.actDirectedSignerName ?? '');
    _directedSignerAddressController =
        TextEditingController(text: fd.actDirectedSignerAddress ?? '');
  }

  @override
  void dispose() {
    _directedSignerNameController.dispose();
    _directedSignerAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleFinish() async {
    if (!_formKey.currentState!.validate()) return;

    final finalData = widget.flowData.copyWith(
      actSigningSelf: _signingSelf,
      actDirectedSignerName: !_signingSelf
          ? _directedSignerNameController.text.trim()
          : null,
      actDirectedSignerAddress: !_signingSelf
          ? _directedSignerAddressController.text.trim()
          : null,
    );

    setState(() => _isSubmitting = true);

    try {
      // 1. Delete existing appointed attorneys to avoid duplicates on re-save.
      await _poaService.deleteAttorneysByType(AttorneyType.APPOINTED_ATTORNEY);

      // 2. Save each ACT attorney via the attorney-for-poa endpoint.
      for (final attorney in finalData.actAttorneys) {
        if (attorney.firstName.trim().isEmpty && attorney.lastName.trim().isEmpty) continue;
        final person = PoaPersonData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          firstName: attorney.firstName.trim(),
          lastName: attorney.lastName.trim(),
          address: attorney.address.trim().isNotEmpty
              ? attorney.address.trim()
              : null,
          email: attorney.email,
          phone: attorney.phone,
          dob: attorney.dob,
          attorneyType: AttorneyType.APPOINTED_ATTORNEY,
          role: 'Appointed Attorney',
          isCorporation: attorney.isCorporation,
          corporationType: attorney.isCorporation ? attorney.corporationType : null,
          isBankrupt: attorney.isBankrupt,
        );
        final attyResult = await _poaService.createAttorneyForPoa(
          person,
          type: AttorneyType.APPOINTED_ATTORNEY,
        );
        if (attyResult.isFailure) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          SnackBarUtils.showError(
            context,
            'Failed to save attorney: ${attorney.fullName}',
          );
          return;
        }
      }

      // 3. Save the POA data.
      final result = await _poaService.createOrUpdatePoa(finalData);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.isSuccess) {
        SnackBarUtils.showSuccess(
          context,
          'Power of attorney created successfully.',
        );
        context.go(AppRouter.home, extra: 4);
      } else {
        SnackBarUtils.showError(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to save power of attorney. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackBarUtils.showError(
        context,
        'An error occurred. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
          currentStep: 5, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 5,
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
                      _buildSigningSection(),
                    ],
                  ),
                ),
              ),
            ),
            PoaBottomBar(
              onPrevious: () {
                final updated = widget.flowData.copyWith(
                  actSigningSelf: _signingSelf,
                  actDirectedSignerName: !_signingSelf
                      ? _directedSignerNameController.text.trim()
                      : null,
                  actDirectedSignerAddress: !_signingSelf
                      ? _directedSignerAddressController.text.trim()
                      : null,
                );
                context.pop(updated);
              },
              onNext: _isSubmitting ? null : _handleFinish,
              nextText: 'Finish',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSigningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Signing method', style: AppTextStyles.pageTitle),
        const SizedBox(height: 8),
        Text(
            'Will you be signing this Enduring Power of Attorney document yourself?',
            style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioButtonOption(
                isSelected: _signingSelf,
                label: 'Yes',
                onTap: () => setState(() => _signingSelf = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioButtonOption(
                isSelected: !_signingSelf,
                label: 'No',
                onTap: () => setState(() => _signingSelf = false),
              ),
            ),
          ],
        ),
        if (!_signingSelf) ...[
          const SizedBox(height: 20),
          AppTextField(
            controller: _directedSignerNameController,
            label: 'Full name of person directed to sign',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter the signer\'s full name'
                : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _directedSignerAddressController,
            label: 'Address of person directed to sign',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter the signer\'s address'
                : null,
          ),
        ],
      ],
    );
  }
}
