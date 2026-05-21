import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaViewsWishesScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaViewsWishesScreen({super.key, required this.flowData});

  @override
  State<PoaViewsWishesScreen> createState() => _PoaViewsWishesScreenState();
}

class _PoaViewsWishesScreenState extends State<PoaViewsWishesScreen> {
  late TextEditingController _importantThingsController;
  late TextEditingController _culturalValuesController;
  late TextEditingController _nearingDeathController;
  late TextEditingController _excludedPeopleController;
  late TextEditingController _directionsController;

  @override
  void initState() {
    super.initState();
    _importantThingsController =
        TextEditingController(text: widget.flowData.preferences ?? '');
    _culturalValuesController = TextEditingController();
    _nearingDeathController = TextEditingController();
    _excludedPeopleController = TextEditingController();
    _directionsController =
        TextEditingController(text: widget.flowData.directions ?? '');
  }

  @override
  void dispose() {
    _importantThingsController.dispose();
    _culturalValuesController.dispose();
    _nearingDeathController.dispose();
    _excludedPeopleController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  PoaFlowData _collectCurrentData() {
    final hasContent = _importantThingsController.text.trim().isNotEmpty ||
        _culturalValuesController.text.trim().isNotEmpty ||
        _nearingDeathController.text.trim().isNotEmpty ||
        _excludedPeopleController.text.trim().isNotEmpty;

    return widget.flowData.copyWith(
      hasViewsWishes: hasContent,
      directions: _directionsController.text.trim(),
    );
  }

  void _handleNext() {
    final updated = _collectCurrentData();
    context.push(AppRouter.poaTermsInstructions, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: 6,
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
                    // ── Section: Views, wishes and preferences ──
                    Text(
                      'Your views, wishes and preferences',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 20),

                    AppTextArea(
                      controller: _importantThingsController,
                      label: 'These things are important to me',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),

                    AppTextArea(
                      controller: _culturalValuesController,
                      label:
                          'These are the cultural, religious or spiritual values, rituals or beliefs I would like considered in my health care',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),

                    AppTextArea(
                      controller: _nearingDeathController,
                      label:
                          'When I am nearing death, the following would be important to me and would comfort me: (e.g. you may prefer to die at home or you may like a certain type of music played)',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),

                    AppTextArea(
                      controller: _excludedPeopleController,
                      label:
                          'I would prefer these people not be involved in discussions about my health care',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 32),
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
