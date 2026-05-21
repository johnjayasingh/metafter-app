import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA Tasmania Step 2 — Eligibility gates.
class PoaStep2Tas extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep2Tas({super.key, required this.flowData});

  @override
  State<PoaStep2Tas> createState() => _PoaStep2TasState();
}

class _PoaStep2TasState extends State<PoaStep2Tas> {
  late bool _isAdult;
  late bool _understandsEpa;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    _isAdult = widget.flowData.tasIsAdult ?? true;
    _understandsEpa = widget.flowData.tasUnderstandsEpa ?? true;
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasIsAdult: _isAdult,
      tasUnderstandsEpa: _understandsEpa,
    );
  }

  Future<void> _handleNext() async {
    if (!_isAdult) {
      SnackBarUtils.showError(
          context, 'You must be 18 years or older to create an EPA.');
      return;
    }
    if (!_understandsEpa) {
      SnackBarUtils.showError(context,
          'You must understand the nature and effect of making an EPA.');
      return;
    }
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
        config.nextRoute(2), extra: _collectData());
    if (result != null) setState(() => _returnedFromNext = result);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
        currentStep: 2,
        userState: widget.flowData.state,
      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose form', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    // ── Are you 18 years or older? ──
                    Text(
                      'Are you 18 years or older?',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _isAdult,
                            label: 'Yes',
                            onTap: () => setState(() => _isAdult = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_isAdult,
                            label: 'No',
                            onTap: () => setState(() => _isAdult = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Understand EPA ──
                    Text(
                      'Do you understand the nature and effect of making an Enduring Power of Attorney?',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _understandsEpa,
                            label: 'Yes',
                            onTap: () =>
                                setState(() => _understandsEpa = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_understandsEpa,
                            label: 'No',
                            onTap: () =>
                                setState(() => _understandsEpa = false),
                          ),
                        ),
                      ],
                    ),
                  ],
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
