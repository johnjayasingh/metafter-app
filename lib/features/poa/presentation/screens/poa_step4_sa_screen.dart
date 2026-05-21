import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_commencement_sa_section.dart';
import '../widgets/poa_steps_sidebar.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';

/// POA South Australia Step 4 — Commencement (when this EPA takes effect).
class PoaStep4Sa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep4Sa({super.key, required this.flowData});

  @override
  State<PoaStep4Sa> createState() => _PoaStep4SaState();
}

class _PoaStep4SaState extends State<PoaStep4Sa> {
  late String _commencementType;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    _commencementType =
        widget.flowData.saCommencementType ?? 'LEGAL_INCAPACITY';
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saCommencementType: _commencementType,
    );
  }

  Future<void> _handleNext() async {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
      config.nextRoute(4),
      extra: _collectData(),
    );
    if (result != null) setState(() => _returnedFromNext = result);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 4, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 4,
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
                child: PoaCommencementSaSection(
                  selectedType: _commencementType,
                  onTypeChanged: (type) =>
                      setState(() => _commencementType = type),
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
