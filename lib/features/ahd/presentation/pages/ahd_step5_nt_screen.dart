import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD NT Step 5 — Appointed decision maker(s)
///
/// API fields (in ahd_persons):
///   - PRIMARY_PERSON: full_name, address, phone
///   - DECISION_MAKER: full_name, dob, phone, address, other.matters
class AhdStep5NtScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep5NtScreen({super.key, required this.flowData});

  @override
  State<AhdStep5NtScreen> createState() => _AhdStep5NtScreenState();
}

class _AhdStep5NtScreenState extends State<AhdStep5NtScreen> {
  final _formKey = GlobalKey<FormState>();

  late List<AhdAttorneyData> _primaryDecisionMakers;
  late List<AhdAttorneyData> _appointedDecisionMakers;

  @override
  void initState() {
    super.initState();
    _primaryDecisionMakers =
        List<AhdAttorneyData>.from(widget.flowData.ntDecisionMakers);
    _appointedDecisionMakers =
        List<AhdAttorneyData>.from(widget.flowData.ntAppointedDecisionMakers);
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      ntDecisionMakers: _primaryDecisionMakers,
      ntAppointedDecisionMakers: _appointedDecisionMakers,
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(5), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  // ── Primary decision maker management ──

  Future<void> _addPrimaryDecisionMaker() async {
    final result = await context
        .push<AhdAttorneyData>(AppRouter.ahdAddNtPrimaryDecisionMaker);
    if (result != null) {
      setState(() => _primaryDecisionMakers.add(result));
    }
  }

  Future<void> _editPrimaryDecisionMaker(int index) async {
    final result = await context.push<AhdAttorneyData>(
      AppRouter.ahdAddNtPrimaryDecisionMaker,
      extra: _primaryDecisionMakers[index],
    );
    if (result != null) {
      setState(() => _primaryDecisionMakers[index] = result);
    }
  }

  void _removePrimaryDecisionMaker(int index) {
    setState(() => _primaryDecisionMakers.removeAt(index));
  }

  // ── Appointed decision maker management ──

  Future<void> _addAppointedDecisionMaker() async {
    final result = await context
        .push<AhdAttorneyData>(AppRouter.ahdAddNtDecisionMaker);
    if (result != null) {
      setState(() => _appointedDecisionMakers.add(result));
    }
  }

  Future<void> _editAppointedDecisionMaker(int index) async {
    final result = await context.push<AhdAttorneyData>(
      AppRouter.ahdAddNtDecisionMaker,
      extra: _appointedDecisionMakers[index],
    );
    if (result != null) {
      setState(() => _appointedDecisionMakers[index] = result);
    }
  }

  void _removeAppointedDecisionMaker(int index) {
    setState(() => _appointedDecisionMakers.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 5, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 5,
        totalSteps: config.totalSteps,
        title: 'Appointed decision maker',
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
                      Text('Appointed decision maker',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Appointment of a decision maker is made by me, the Adult',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 24),

                      // ── Primary decision maker(s) ──
                      Text('Primary decision maker',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      ..._primaryDecisionMakers.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DecisionMakerCard(
                            person: entry.value,
                            label: 'Primary',
                            onEdit: () =>
                                _editPrimaryDecisionMaker(entry.key),
                            onDelete: () =>
                                _removePrimaryDecisionMaker(entry.key),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        text: '+ Add primary decision maker',
                        onPressed: _addPrimaryDecisionMaker,
                      ),
                      const SizedBox(height: 32),

                      // ── Appointed decision maker(s) ──
                      Text(
                        'To appoint as my decision maker:',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      ..._appointedDecisionMakers.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DecisionMakerCard(
                            person: entry.value,
                            label: 'Decision maker',
                            onEdit: () =>
                                _editAppointedDecisionMaker(entry.key),
                            onDelete: () =>
                                _removeAppointedDecisionMaker(entry.key),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        text: '+ Add decision maker',
                        onPressed: _addAppointedDecisionMaker,
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

class _DecisionMakerCard extends StatelessWidget {
  final AhdAttorneyData person;
  final String label;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DecisionMakerCard({
    required this.person,
    required this.label,
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
                Text(label, style: AppTextStyles.cardSecondary),
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
