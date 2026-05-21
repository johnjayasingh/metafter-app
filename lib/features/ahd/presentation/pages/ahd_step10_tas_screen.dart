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

/// AHD Tasmania Step 10 — Revoking your ACD
///
/// API fields:
///   - is_acd_revoked
class AhdStep10TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep10TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep10TasScreen> createState() => _AhdStep10TasScreenState();
}

class _AhdStep10TasScreenState extends State<AhdStep10TasScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isAcdRevoked;

  @override
  void initState() {
    super.initState();
    _isAcdRevoked = widget.flowData.tasRevokeAcd ?? false;
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasRevokeAcd: _isAcdRevoked,
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(8), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 8, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 8,
        totalSteps: config.totalSteps,
        title: 'Revoking your ACD',
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
                      Text('Revoking your ACD',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),
                      AppCheckbox(
                        label: 'Tick here if this ACD has been revoked',
                        value: _isAcdRevoked,
                        onChanged: (v) =>
                            setState(() => _isAcdRevoked = v ?? false),
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
