import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Tasmania Step 3 — Your views, wishes and preferences
///
/// API fields:
///   - living_preferences.wish_to_live
class AhdStep3TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep3TasScreen> createState() => _AhdStep3TasScreenState();
}

class _AhdStep3TasScreenState extends State<AhdStep3TasScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _viewsWishesController;

  @override
  void initState() {
    super.initState();
    _viewsWishesController =
        TextEditingController(text: widget.flowData.tasViewsWishes ?? '');
  }

  @override
  void dispose() {
    _viewsWishesController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasViewsWishes: _viewsWishesController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(3), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: config.totalSteps,
        title: 'Your views, wishes and preferences',
        enableDrawer: true,
        exitTitle: 'Exit advance health directive?',
        exitDescription:
            'Your progress will be lost. You can start a new advance health directive at any time.',
        exitDiscardButtonText: 'Exit AHD',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 5),
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
                      Text('Your views, wishes and preferences',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'The values, and preferences you express here can guide a person making a decision about your health care.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),
                      AppTextArea(
                        controller: _viewsWishesController,
                        label: 'Views and wishes',
                        maxLines: 8,
                        minLines: 4,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            AhdBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
