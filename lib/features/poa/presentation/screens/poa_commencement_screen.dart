import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../widgets/poa_steps_sidebar.dart';

enum _CommencementType { incapacity, immediately, other }

class PoaCommencementScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaCommencementScreen({super.key, required this.flowData});

  @override
  State<PoaCommencementScreen> createState() => _PoaCommencementScreenState();
}

class _PoaCommencementScreenState extends State<PoaCommencementScreen> {
  late _CommencementType _selected;
  late TextEditingController _otherController;

  // Views, wishes and preferences
  late bool _hasViewsWishes;
  late TextEditingController _viewsWishesController;

  // Terms and instructions
  late bool _hasTerms;
  late TextEditingController _termsController;

  @override
  void initState() {
    super.initState();
    switch (widget.flowData.commencementType) {
      case 'IMMEDIATELY':
        _selected = _CommencementType.immediately;
        break;
      case 'OTHER':
        _selected = _CommencementType.other;
        break;
      default:
        _selected = _CommencementType.incapacity;
    }
    _otherController =
        TextEditingController(text: widget.flowData.commencementOther ?? '');

    _hasViewsWishes = widget.flowData.hasViewsWishes ?? false;
    _viewsWishesController =
        TextEditingController(text: widget.flowData.viewsWishes ?? '');

    _hasTerms = widget.flowData.hasTermsInstructions ?? false;
    _termsController =
        TextEditingController(text: widget.flowData.termsInstructions ?? '');
  }

  @override
  void dispose() {
    _otherController.dispose();
    _viewsWishesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  PoaFlowData _collectCurrentData() {
    String typeKey;
    switch (_selected) {
      case _CommencementType.immediately:
        typeKey = 'IMMEDIATELY';
        break;
      case _CommencementType.other:
        typeKey = 'OTHER';
        break;
      default:
        typeKey = 'INCAPACITY';
    }

    return widget.flowData.copyWith(
      commencementType: typeKey,
      commencementOther:
          _selected == _CommencementType.other ? _otherController.text.trim() : null,
      hasViewsWishes: _hasViewsWishes,
      viewsWishes: _hasViewsWishes ? _viewsWishesController.text.trim() : null,
      hasTermsInstructions: _hasTerms,
      termsInstructions: _hasTerms ? _termsController.text.trim() : null,
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
      drawer: PoaStepsSidebar(currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: 4,
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
                      'Commencement for financial matters',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 24),

                    // Option 1: Incapacity
                    RadioListOption(
                      isSelected: _selected == _CommencementType.incapacity,
                      title:
                          'When i do not have capacity to make decisions for financial matters',
                      onTap: () => setState(
                          () => _selected = _CommencementType.incapacity),
                    ),
                    const SizedBox(height: 12),

                    // Option 2: Immediately
                    RadioListOption(
                      isSelected: _selected == _CommencementType.immediately,
                      title: 'Immediately',
                      onTap: () => setState(
                          () => _selected = _CommencementType.immediately),
                    ),
                    const SizedBox(height: 12),

                    // Option 3: Others
                    RadioListOption(
                      isSelected: _selected == _CommencementType.other,
                      title: 'Others',
                      onTap: () =>
                          setState(() => _selected = _CommencementType.other),
                    ),

                    // Text field appears when "Others" is selected
                    if (_selected == _CommencementType.other) ...[
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _otherController,
                        label: '',
                        placeholder: 'Please specify when your attorney can start making financial decisions',
                        maxLines: 4,
                      ),
                    ],

                    // ── Views, wishes and preferences ──────────────────────
                    const SizedBox(height: 32),
                    Text(
                      'Views, wishes and preferences (optional)',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Would you like to record your views, wishes and preferences?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _hasViewsWishes,
                            label: 'Yes',
                            onTap: () =>
                                setState(() => _hasViewsWishes = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_hasViewsWishes,
                            label: 'No',
                            onTap: () =>
                                setState(() => _hasViewsWishes = false),
                          ),
                        ),
                      ],
                    ),
                    if (_hasViewsWishes) ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _viewsWishesController,
                        label: '',
                        placeholder: 'Enter views, wishes and preferences',
                        minLines: 4,
                        maxLines: 8,
                      ),
                    ],

                    // ── Terms and instructions ─────────────────────────────
                    const SizedBox(height: 32),
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
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _hasTerms,
                            label: 'Yes',
                            onTap: () =>
                                setState(() => _hasTerms = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_hasTerms,
                            label: 'No',
                            onTap: () =>
                                setState(() => _hasTerms = false),
                          ),
                        ),
                      ],
                    ),
                    if (_hasTerms) ...[
                      const SizedBox(height: 16),
                      AppTextArea(
                        controller: _termsController,
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
