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

/// AHD Queensland Step 8 — Appointing an attorney for health matters
///
/// API fields:
///   - attorney_and_advice.attorney_decision_power
///   - attorney_and_advice.attorney_decision_power_detail
///   - ahd_persons type=ATTORNEY_HEALTH_MATTERS
class AhdStep8QldScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep8QldScreen({super.key, required this.flowData});

  @override
  State<AhdStep8QldScreen> createState() => _AhdStep8QldScreenState();
}

class _AhdStep8QldScreenState extends State<AhdStep8QldScreen> {
  final _formKey = GlobalKey<FormState>();

  late final List<AhdAttorneyData> _attorneys;
  late String? _decisionMethod;
  late final TextEditingController _decisionOtherController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _attorneys = List.from(d.healthAttorneys);
    _decisionMethod = d.attorneyDecisionMethod;
    _decisionOtherController =
        TextEditingController(text: d.attorneyDecisionOther ?? '');
  }

  @override
  void dispose() {
    _decisionOtherController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      healthAttorneys: List.from(_attorneys),
      attorneyDecisionMethod: _decisionMethod,
      attorneyDecisionOther: _decisionOtherController.text.trim(),
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

  Future<void> _addAttorney() async {
    final result = await context
        .push<AhdAttorneyData>(AppRouter.ahdAddAttorney);
    if (result != null) {
      setState(() => _attorneys.add(result));
    }
  }

  void _removeAttorney(int index) {
    setState(() => _attorneys.removeAt(index));
  }

  Future<void> _editAttorney(int index) async {
    final result = await context.push<AhdAttorneyData>(
      AppRouter.ahdAddAttorney,
      extra: _attorneys[index],
    );
    if (result != null) {
      setState(() => _attorneys[index] = result);
    }
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
        title: 'Appointing an attorney for health matters',
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
                      Text('Appointing an attorney for health matters',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Who are you appointing as your attorney for health matters?',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),

                      // Attorney list
                      ..._attorneys.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AttorneyCard(
                            person: entry.value,
                            onEdit: () => _editAttorney(entry.key),
                            onDelete: () =>
                                _removeAttorney(entry.key),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        text: '+ Add attorney',
                        onPressed: _addAttorney,
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'How much your attorneys make decisions',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),

                      ...AttorneyDecisionPower.all.map(
                        (option) => RadioListOption(
                          title:
                              AttorneyDecisionPower.displayName(option),
                          isSelected: _decisionMethod == option,
                          onTap: () => setState(
                              () => _decisionMethod = option),
                        ),
                      ),
                      if (_decisionMethod ==
                          AttorneyDecisionPower.other) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _decisionOtherController,
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

class _AttorneyCard extends StatelessWidget {
  final AhdAttorneyData person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AttorneyCard({
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundLightGreen,
            child: Text(
              person.initials,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.fullName, style: AppTextStyles.itemLabel),
                Text('Attorney',
                    style: AppTextStyles.cardSecondary),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
