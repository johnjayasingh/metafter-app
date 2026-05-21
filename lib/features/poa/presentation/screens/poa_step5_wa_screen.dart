import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_conditions_limitations_section.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA Western Australia Step 5 — Conditions or restrictions.
class PoaStep5Wa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep5Wa({super.key, required this.flowData});

  @override
  State<PoaStep5Wa> createState() => _PoaStep5WaState();
}

class _PoaStep5WaState extends State<PoaStep5Wa> {
  late bool _hasConditions;
  late TextEditingController _conditionsController;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    _hasConditions = widget.flowData.waHasConditions ?? false;
    _conditionsController =
        TextEditingController(text: widget.flowData.waConditions ?? '');
  }

  @override
  void dispose() {
    _conditionsController.dispose();
    super.dispose();
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waHasConditions: _hasConditions,
      waConditions: _hasConditions ? _conditionsController.text.trim() : null,
    );
  }

  Future<void> _handleNext() async {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
      config.nextRoute(5),
      extra: _collectData(),
    );
    if (result != null) setState(() => _returnedFromNext = result);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 5, userState: widget.flowData.state),
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
                child: PoaConditionsLimitationsSection(
                  hasConditionsLimitations: _hasConditions,
                  controller: _conditionsController,
                  onToggle: (val) => setState(() => _hasConditions = val),
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
