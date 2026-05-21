import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_dto.dart';
import '../../data/models/ahd_enums.dart';
import '../../data/models/ahd_flow_config.dart';
import '../../data/services/ahd_service.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD ACT Step 4 — Witnesses (final step)
///
/// API fields (in ahd_persons):
///   - WITNESS_PERSON: full_name, address
///
/// Builds [AhdCreateDto] from accumulated flow data and submits.
class AhdStep4ActScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep4ActScreen({super.key, required this.flowData});

  @override
  State<AhdStep4ActScreen> createState() => _AhdStep4ActScreenState();
}

class _AhdStep4ActScreenState extends State<AhdStep4ActScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _witnessFullNameController;
  late final TextEditingController _witnessAddressController;

  @override
  void initState() {
    super.initState();
    _witnessFullNameController =
        TextEditingController(text: widget.flowData.actWitness1FullName ?? '');
    _witnessAddressController =
        TextEditingController(text: widget.flowData.actWitness1Address ?? '');
  }

  @override
  void dispose() {
    _witnessFullNameController.dispose();
    _witnessAddressController.dispose();
    super.dispose();
  }

  AhdFlowData _collectData() {
    return widget.flowData.copyWith(
      actWitness1FullName: _witnessFullNameController.text.trim(),
      actWitness1Address: _witnessAddressController.text.trim(),
    );
  }

  /// Build [AhdCreateDto] from the accumulated ACT flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // Helper (directed signer) — person_type=HELPER
    if ((data.actDirectedPersonName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.actDirectedPersonName!,
        personType: AhdPersonType.helper,
        address: data.actDirectedPersonAddress,
      ));
    }

    // Witness — person_type=WITNESS_PERSON
    final witnessName = _witnessFullNameController.text.trim();
    if (witnessName.isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: witnessName,
        personType: AhdPersonType.witnessPerson,
        address: _witnessAddressController.text.trim(),
      ));
    }

    return AhdCreateDto(
      medicalTreatmentRefuse: data.actMedicalTreatmentRefuse,
      isAcdRevoked: data.actRevokePreviousDirections ?? false,
      ahdPersons: persons,
    );
  }

  Future<void> _handleFinish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final finalData = _collectData();
    final dto = _buildDto(finalData);

    try {
      final result = await AhdService().createOrUpdateAhdDto(dto);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (result.isSuccess) {
        SnackBarUtils.showSuccess(
          context,
          'Advance health directive saved successfully.',
        );
        context.go(AppRouter.home, extra: 5);
      } else {
        SnackBarUtils.showError(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackBarUtils.showError(
          context, 'An error occurred. Please try again.');
    }
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
        title: 'Witnesses',
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
                      Text('Witnesses', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'The witnesses must sign in the presence of each other and the person making the direction.',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _witnessFullNameController,
                        label: 'Full name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _witnessAddressController,
                        label: 'Address',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            AhdBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _handleFinish,
              nextText: 'Finish',
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
