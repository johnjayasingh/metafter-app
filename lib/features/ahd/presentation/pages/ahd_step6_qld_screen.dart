import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_enums.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Queensland Step 6 — Directions about other healthcare
///
/// API fields:
///   - other_health_directions[] (health_condition, health_direction)
///   - life_sustaining_treatment.blood_transfusion + instruction
class AhdStep6QldScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep6QldScreen({super.key, required this.flowData});

  @override
  State<AhdStep6QldScreen> createState() => _AhdStep6QldScreenState();
}

class _AhdStep6QldScreenState extends State<AhdStep6QldScreen> {
  final _formKey = GlobalKey<FormState>();

  late final List<HealthCareDirection> _otherDirections;
  late String? _bloodTransfusion;
  late final TextEditingController _bloodTransfusionDetailsCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _otherDirections = List.from(d.otherHealthCareDirections);
    _bloodTransfusion = d.bloodTransfusionChoice;
    _bloodTransfusionDetailsCtrl =
        TextEditingController(text: d.bloodTransfusionOther ?? '');
  }

  @override
  void dispose() {
    _bloodTransfusionDetailsCtrl.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      otherHealthCareDirections: List.from(_otherDirections),
      bloodTransfusionChoice: _bloodTransfusion,
      bloodTransfusionOther: _bloodTransfusionDetailsCtrl.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(6), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  void _addDirection() {
    setState(() {
      _otherDirections.add(const HealthCareDirection());
    });
  }

  void _removeDirection(int index) {
    setState(() => _otherDirections.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 6, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 6,
        totalSteps: config.totalSteps,
        title: 'Directions about other healthcare',
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
                      Text('Directions about other healthcare',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      ..._otherDirections.asMap().entries.map((entry) {
                        final i = entry.key;
                        final dir = entry.value;
                        return _HealthDirectionCard(
                          index: i,
                          direction: dir,
                          onConditionChanged: (v) => setState(
                              () => _otherDirections[i] =
                                  dir.copyWith(healthCondition: v)),
                          onDirectionChanged: (v) => setState(
                              () => _otherDirections[i] =
                                  dir.copyWith(directions: v)),
                          onRemove: () => _removeDirection(i),
                        );
                      }),

                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        text: '+ Add health condition & direction',
                        onPressed: _addDirection,
                      ),

                      const SizedBox(height: 32),

                      // Blood transfusion
                      Text('Directions about blood transfusion',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      ...BloodTransfusion.all.map(
                        (option) => RadioListOption(
                          title: BloodTransfusion.displayName(option),
                          isSelected: _bloodTransfusion == option,
                          onTap: () => setState(
                              () => _bloodTransfusion = option),
                        ),
                      ),
                      if (_bloodTransfusion ==
                          BloodTransfusion.other) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _bloodTransfusionDetailsCtrl,
                          label: 'Specify',
                          maxLines: 4,
                          minLines: 2,
                        ),
                      ],
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

class _HealthDirectionCard extends StatefulWidget {
  final int index;
  final HealthCareDirection direction;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<String> onDirectionChanged;
  final VoidCallback onRemove;

  const _HealthDirectionCard({
    required this.index,
    required this.direction,
    required this.onConditionChanged,
    required this.onDirectionChanged,
    required this.onRemove,
  });

  @override
  State<_HealthDirectionCard> createState() => _HealthDirectionCardState();
}

class _HealthDirectionCardState extends State<_HealthDirectionCard> {
  late final TextEditingController _conditionCtrl;
  late final TextEditingController _directionCtrl;

  @override
  void initState() {
    super.initState();
    _conditionCtrl =
        TextEditingController(text: widget.direction.healthCondition);
    _directionCtrl =
        TextEditingController(text: widget.direction.directions);
    _conditionCtrl.addListener(
        () => widget.onConditionChanged(_conditionCtrl.text));
    _directionCtrl.addListener(
        () => widget.onDirectionChanged(_directionCtrl.text));
  }

  @override
  void dispose() {
    _conditionCtrl.dispose();
    _directionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Condition ${widget.index + 1}',
                  style: AppTextStyles.questionTitle),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _conditionCtrl,
            label: 'Health condition',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _directionCtrl,
            label: 'Direction',
          ),
        ],
      ),
    );
  }
}
