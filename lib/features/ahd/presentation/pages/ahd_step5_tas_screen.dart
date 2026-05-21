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

/// AHD Tasmania Step 5 — Your signature
///
/// API fields:
///   - ahd_persons (HELPER): full_name, other.ahd_primary_person_name, other.relationship
class AhdStep5TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep5TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep5TasScreen> createState() => _AhdStep5TasScreenState();
}

class _AhdStep5TasScreenState extends State<AhdStep5TasScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _delegatedNameController;
  late final TextEditingController _delegatedAcdPersonNameController;
  String? _delegatedRelationship;
  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _delegatedNameController =
        TextEditingController(text: d.tasDelegatedPersonName ?? '');
    _delegatedAcdPersonNameController =
        TextEditingController(text: d.tasDelegatedAcdPersonName ?? '');
    _delegatedRelationship = d.tasDelegatedRelationship;
  }

  @override
  void dispose() {
    _delegatedNameController.dispose();
    _delegatedAcdPersonNameController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasDelegatedPersonName: _delegatedNameController.text.trim(),
      tasDelegatedAcdPersonName: _delegatedAcdPersonNameController.text.trim(),
      tasDelegatedRelationship: _delegatedRelationship,
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
        title: 'Your signature',
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
                      Text('Your signature',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'If you are unable to complete or sign this form yourself you may ask someone else to fill in the form on your behalf. However the contents must be fully directed by you and the form must be completed in your presence. If you have asked someone to complete the form on your behalf they must fill in the box below.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _delegatedNameController,
                        label: 'Full name of person completing this form',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _delegatedAcdPersonNameController,
                        label: 'Full name of person giving this ACD',
                      ),
                      const SizedBox(height: 16),
                      AppDropdownFormField<String>(
                        label: 'Relationship to you',
                        value: _delegatedRelationship,
                        items: const [
                          'SON', 'DAUGHTER', 'STEP_SON', 'STEP_DAUGHTER',
                          'NEPHEW', 'NIECE', 'FATHER', 'MOTHER',
                          'GUARDIAN', 'CARETAKER', 'OTHER',
                        ],
                        displayName: (v) => v[0] + v.substring(1).toLowerCase().replaceAll('_', ' '),
                        onChanged: (v) =>
                            setState(() => _delegatedRelationship = v),
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
