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

/// AHD South Australia Step 2 — Appointment of Substitute Decision-Maker/s
///
/// API fields (in ahd_persons):
///   - SUBSTITUTE_DECISION_MAKER: full_name, address, phone
///   - SUBSTITUTE_DECISION_MAKER_SECONDARY: full_name, address, phone
class AhdStep2SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep2SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep2SaScreen> createState() => _AhdStep2SaScreenState();
}

class _AhdStep2SaScreenState extends State<AhdStep2SaScreen> {
  late final TextEditingController _healthConditionsController;
  late final List<AhdAttorneyData> _substituteDecisionMakers;
  @override
  void initState() {
    super.initState();
    _healthConditionsController = TextEditingController(
        text: widget.flowData.healthConditions ?? '');
    _substituteDecisionMakers =
        List.from(widget.flowData.saSubstituteDecisionMakers);
  }

  @override
  void dispose() {
    _healthConditionsController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      healthConditions: _healthConditionsController.text.trim().isNotEmpty
          ? _healthConditionsController.text.trim()
          : null,
      saSubstituteDecisionMakers: List.from(_substituteDecisionMakers),
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(2), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: config.totalSteps,
        title: 'Appointment of Substitute Decision-Maker/s',
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
                    Text('Major health conditions',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 16),
                    AppTextArea(
                      controller: _healthConditionsController,
                      label: 'Major health conditions',
                      maxLines: 8,
                    ),
                    const SizedBox(height: 24),

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
}

class SaPersonCard extends StatelessWidget {
  final AhdAttorneyData person;
  final String roleLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SaPersonCard({
    super.key,
    required this.person,
    required this.roleLabel,
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
                Text(roleLabel, style: AppTextStyles.cardSecondary),
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
