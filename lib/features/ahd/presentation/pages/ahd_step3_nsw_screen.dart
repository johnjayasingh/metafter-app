import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD NSW Step 3 — Personal values about dying
///
/// API fields:
///   - quality_of_life_tolerance.no_longer_recognise_family
///   - quality_of_life_tolerance.no_bladder_control
///   - quality_of_life_tolerance.cant_feed_wash_dress
///   - quality_of_life_tolerance.rely_people_for_movement
///   - quality_of_life_tolerance.need_life_tube_for_food
///   - quality_of_life_tolerance.cant_converse_with_people
///   - cpr_and_resuscitation.cpr_instruction
class AhdStep3NswScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3NswScreen({super.key, required this.flowData});

  @override
  State<AhdStep3NswScreen> createState() => _AhdStep3NswScreenState();
}

class _AhdStep3NswScreenState extends State<AhdStep3NswScreen> {
  late String? _cannotRecogniseFamily;
  late String? _noBladderControl;
  late String? _cannotFeedWashDress;
  late String? _cannotMoveInOutBed;
  late String? _cannotEatDrink;
  late String? _cannotMoveReposition;
  late String? _endOfLifeCare;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _cannotRecogniseFamily = d.nswCannotRecogniseFamily;
    _noBladderControl = d.nswNoBladderControl;
    _cannotFeedWashDress = d.nswCannotFeedWashDress;
    _cannotMoveInOutBed = d.nswCannotMoveInOutBed;
    _cannotEatDrink = d.nswCannotEatDrink;
    _cannotMoveReposition = d.nswCannotMoveReposition;
    _endOfLifeCare = d.nswEndOfLifeCare;
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      nswCannotRecogniseFamily: _cannotRecogniseFamily,
      nswNoBladderControl: _noBladderControl,
      nswCannotFeedWashDress: _cannotFeedWashDress,
      nswCannotMoveInOutBed: _cannotMoveInOutBed,
      nswCannotEatDrink: _cannotEatDrink,
      nswCannotMoveReposition: _cannotMoveReposition,
      nswEndOfLifeCare: _endOfLifeCare,
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(4), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 4, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 4,
        totalSteps: config.totalSteps,
        title: 'Personal values about dying',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal values about dying',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    _buildBearabilityScenario(
                      'If I can no longer recognise my family and loved ones, I would find life...',
                      _cannotRecogniseFamily,
                      (v) => setState(() => _cannotRecogniseFamily = v),
                    ),
                    _buildBearabilityScenario(
                      'If I no longer have control of my bladder and bowels, I would find life...',
                      _noBladderControl,
                      (v) => setState(() => _noBladderControl = v),
                    ),
                    _buildBearabilityScenario(
                      'If I cannot feed, wash or dress myself I would find life...',
                      _cannotFeedWashDress,
                      (v) => setState(() => _cannotFeedWashDress = v),
                    ),
                    _buildBearabilityScenario(
                      'If I cannot move myself in or out of bed and must rely on other people to reposition (shift or move) me, I would find life...',
                      _cannotMoveInOutBed,
                      (v) => setState(() => _cannotMoveInOutBed = v),
                    ),
                    _buildBearabilityScenario(
                      'If I can no longer eat or drink and need to have food given to me through a tube in my stomach I would find life...',
                      _cannotEatDrink,
                      (v) => setState(() => _cannotEatDrink = v),
                    ),
                    _buildBearabilityScenario(
                      'If I cannot have a conversation with others because I do not understand what people are saying, I would find life...',
                      _cannotMoveReposition,
                      (v) => setState(() => _cannotMoveReposition = v),
                    ),
                    _buildBearabilityScenario(
                      'At the end of my life when my time comes for dying, I would like to be cared for, if possible',
                      _endOfLifeCare,
                      (v) => setState(() => _endOfLifeCare = v),
                    ),
                  ],
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

  Widget _buildBearabilityScenario(
    String title,
    String? selectedValue,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.questionTitle),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedValue == BearabilityChoice.bearable,
          title: 'Bearable',
          onTap: () => onChanged(BearabilityChoice.bearable),
        ),
        const SizedBox(height: 8),
        RadioListOption(
          isSelected: selectedValue == BearabilityChoice.unbearable,
          title: 'Unbearable',
          subtitle:
              'I would like treatment discontinued and to be allowed to die a natural death',
          onTap: () => onChanged(BearabilityChoice.unbearable),
        ),
        const SizedBox(height: 8),
        RadioListOption(
          isSelected: selectedValue == BearabilityChoice.unsure,
          title: 'Unsure',
          onTap: () => onChanged(BearabilityChoice.unsure),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
