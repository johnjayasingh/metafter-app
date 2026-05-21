import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaTermsInstructionsScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaTermsInstructionsScreen({super.key, required this.flowData});

  @override
  State<PoaTermsInstructionsScreen> createState() =>
      _PoaTermsInstructionsScreenState();
}

class _PoaTermsInstructionsScreenState
    extends State<PoaTermsInstructionsScreen> {
  late bool _hasTerms;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _hasTerms = widget.flowData.hasTermsInstructions ?? true;
    _controller =
        TextEditingController(text: widget.flowData.termsInstructions ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PoaFlowData _collectCurrentData() {
    return widget.flowData.copyWith(
      hasTermsInstructions: _hasTerms,
      termsInstructions: _hasTerms ? _controller.text.trim() : null,
    );
  }

  void _handleNext() {
    final updated = _collectCurrentData();
    context.push(AppRouter.poaNotification, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 4, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 4,
        totalSteps: 6,
        title: 'Enduring power of attorney',
        enableDrawer: true,
        exitTitle: 'Exit power of attorney?',
        exitDescription: 'Your progress will be lost. You can start a new power of attorney at any time.',
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
                    Text(
                      'Terms and instructions of your attorney',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Would you like to set terms or limits on your attorney\'s power and/or give specific instructions that your attorney must follow?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Yes / No
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _hasTerms,
                            label: 'Yes',
                            onTap: () => setState(() => _hasTerms = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_hasTerms,
                            label: 'No',
                            onTap: () => setState(() => _hasTerms = false),
                          ),
                        ),
                      ],
                    ),

                    // Instructions text area
                    if (_hasTerms) ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _controller,
                        label: '',
                        placeholder: 'Enter your instructions',
                        minLines: 6,
                        maxLines: 10,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            _PoaBottomBar(
              onPrevious: () => context.pop(_collectCurrentData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom bar ─────────────────────────────────────────────────────────────

class _PoaBottomBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const _PoaBottomBar({
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                text: 'Previous',
                onPressed: onPrevious,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                text: 'Next step',
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
