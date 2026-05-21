import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_attorney_section.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA Tasmania Step 4 — Attorney(s) (up to 2) and how they act.
class PoaStep4Tas extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep4Tas({super.key, required this.flowData});

  @override
  State<PoaStep4Tas> createState() => _PoaStep4TasState();
}

class _PoaStep4TasState extends State<PoaStep4Tas> {
  late List<PoaPersonData> _attorneys;
  late String _howAttorneysAct;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    _attorneys = List.from(widget.flowData.attorneys);
    _howAttorneysAct = widget.flowData.tasHowAttorneysAct ?? 'JOINTLY';
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      attorneys: _attorneys,
      tasHowAttorneysAct: _attorneys.length > 1 ? _howAttorneysAct : null,
    );
  }

  Future<void> _handleNext() async {
    if (_attorneys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one attorney.')),
      );
      return;
    }
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
        config.nextRoute(4), extra: _collectData());
    if (result != null) setState(() => _returnedFromNext = result);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
        currentStep: 4,
        userState: widget.flowData.state,
      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attorney(s) appointed', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'How many attorneys do you want to appoint?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    PoaAttorneySection(
                      type: AttorneyType.PRIMARY,
                      title: 'Attorney(s)',
                      addButtonText: '+ Add Attorney',
                      maxPersons: 2,
                      onChanged: (list) => setState(() => _attorneys = list),
                    ),

                    // How attorneys act — only shown when 2 attorneys
                    if (_attorneys.length > 1) ...[
                      const SizedBox(height: 32),
                      Text(
                        'If you appoint two attorneys, how do they act?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      RadioListOption(
                        isSelected: _howAttorneysAct == 'JOINTLY',
                        title: 'Jointly',
                        onTap: () =>
                            setState(() => _howAttorneysAct = 'JOINTLY'),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _howAttorneysAct == 'JOINTLY_SEVERALLY',
                        title: 'Joint and severally',
                        onTap: () => setState(
                            () => _howAttorneysAct = 'JOINTLY_SEVERALLY'),
                      ),
                    ],
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
