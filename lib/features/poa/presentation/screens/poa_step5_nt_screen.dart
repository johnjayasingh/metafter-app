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
import '../widgets/poa_steps_sidebar.dart';

/// POA Northern Territory Step 5 — Land dealings. Final step: submits to API.
class PoaStep5Nt extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep5Nt({super.key, required this.flowData});

  @override
  State<PoaStep5Nt> createState() => _PoaStep5NtState();
}

class _PoaStep5NtState extends State<PoaStep5Nt> {
  final PoaService _poaService = PoaService();
  bool _isSubmitting = false;

  late bool _ownsLand;
  late bool _dmCanDealLand;

  @override
  void initState() {
    super.initState();
    _ownsLand = widget.flowData.ntOwnsLand ?? false;
    _dmCanDealLand = widget.flowData.ntDmCanDealLand ?? false;
  }

  PoaFlowData _buildFinalData() {
    return widget.flowData.copyWith(
      ntOwnsLand: _ownsLand,
      ntDmCanDealLand: _ownsLand ? _dmCanDealLand : false,
    );
  }

  Future<void> _handleSaveAndDownload() async {
    setState(() => _isSubmitting = true);

    try {
      final finalData = _buildFinalData();
      final result = await _poaService.createOrUpdatePoa(finalData);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.isSuccess) {
        SnackBarUtils.showSuccess(
            context, 'Power of attorney saved successfully.');
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
      SnackBarUtils.showError(context, 'An error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
        currentStep: 5,
        userState: widget.flowData.state,
      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Land dealings trigger',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 20),
                    Text(
                      'Do you own land/real estate in the Northern Territory?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _ownsLand,
                            label: 'Yes',
                            onTap: () => setState(() => _ownsLand = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_ownsLand,
                            label: 'No',
                            onTap: () => setState(() {
                              _ownsLand = false;
                              _dmCanDealLand = false;
                            }),
                          ),
                        ),
                      ],
                    ),
                    if (_ownsLand) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Do you want your financial decision-maker(s) to deal with your NT land/real estate (sell, lease, mortgage, sign land documents)?',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _dmCanDealLand,
                              label: 'Yes',
                              onTap: () =>
                                  setState(() => _dmCanDealLand = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: !_dmCanDealLand,
                              label: 'No',
                              onTap: () =>
                                  setState(() => _dmCanDealLand = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: () => context.pop(widget.flowData),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Save & Download',
                        onPressed:
                            _isSubmitting ? null : _handleSaveAndDownload,
                        isLoading: _isSubmitting,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
