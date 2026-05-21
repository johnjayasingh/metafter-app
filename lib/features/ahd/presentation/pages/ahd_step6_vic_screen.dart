import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart' hide InterpreterLanguages, SaWitnessCategory;
import '../../data/models/ahd_dto.dart';
import '../../data/models/ahd_enums.dart';
import '../../data/models/ahd_flow_config.dart';
import '../../data/services/ahd_service.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Victoria Step 6 — Signature of interpreter (final step)
///
/// API fields (in ahd_persons):
///   - INTERPRETER: full_name, other.naati_number, other.language
///
/// Builds [AhdCreateDto] from accumulated flow data and submits.
class AhdStep6VicScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep6VicScreen({super.key, required this.flowData});

  @override
  State<AhdStep6VicScreen> createState() => _AhdStep6VicScreenState();
}

class _AhdStep6VicScreenState extends State<AhdStep6VicScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _interpreterNameController;
  late final TextEditingController _interpreterNaatiController;
  late String? _interpreterLanguage;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _interpreterNameController =
        TextEditingController(text: d.vicInterpreterName ?? '');
    _interpreterNaatiController =
        TextEditingController(text: d.vicInterpreterNaati ?? '');
    _interpreterLanguage = d.vicInterpreterLanguage;
  }

  @override
  void dispose() {
    _interpreterNameController.dispose();
    _interpreterNaatiController.dispose();
    super.dispose();
  }

  AhdFlowData _collectData() {
    return widget.flowData.copyWith(
      vicInterpreterName: _interpreterNameController.text.trim(),
      vicInterpreterNaati: _interpreterNaatiController.text.trim(),
      vicInterpreterLanguage: _interpreterLanguage,
    );
  }

  /// Build [AhdCreateDto] from the accumulated VIC flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // Witness 1 — Registered medical practitioner
    if ((data.vicWitness1FullName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.vicWitness1FullName!,
        personType: AhdPersonType.witnessMedicalPractitioner,
        other: {
          if ((data.vicWitness1Qualification ?? '').isNotEmpty)
            'qualification': data.vicWitness1Qualification!,
        },
      ));
    }

    // Witness 2 — Adult witness
    if ((data.vicWitness2FullName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.vicWitness2FullName!,
        personType: AhdPersonType.witnessPerson,
      ));
    }

    // Interpreter (optional)
    final interpName = _interpreterNameController.text.trim();
    if (interpName.isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: interpName,
        personType: AhdPersonType.interpreter,
        other: {
          if (_interpreterNaatiController.text.trim().isNotEmpty)
            'naati_number': _interpreterNaatiController.text.trim(),
          if (_interpreterLanguage != null)
            'language': _interpreterLanguage,
        },
      ));
    }

    return AhdCreateDto(
      healthConditions: HealthConditionsDto(
        majorHealthConditions: data.healthConditions,
        nearingDeathPreference: data.nearingDeathComfort,
      ),
      declarationsAndWishes: DeclarationsAndWishesDto(
        whatMatterMost: data.thingsImportant,
        whatWorriesMost: data.thingsWorry,
        unacceptableMedicalTreatmentOutcome: data.vicUnacceptableOutcomes,
        otherThingsKnown: data.vicOtherThingsKnown,
        otherPeopleInvolvedInCareDiscussion: data.vicPeopleInvolved,
      ),
      organDonation: data.vicOrganDonation,
      medicalTreatmentConsent: data.vicConsentTreatment,
      medicalTreatmentRefuse: data.vicRefuseTreatment,
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
          currentStep: 6, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 6,
        totalSteps: config.totalSteps,
        title: 'Signature of interpreter',
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
                      Text('Signature of interpreter',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _interpreterNameController,
                        label: 'Name of interpreter',
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'If accredited with the National Accreditation Authority',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _interpreterNaatiController,
                        label: 'NAATI number',
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'I am competent to interpret from English into the following language',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppDropdown<String>(
                        value: _interpreterLanguage,
                        label: 'Language',
                        items: InterpreterLanguages.values,
                        displayName: InterpreterLanguages.displayName,
                        onChanged: (val) =>
                            setState(() => _interpreterLanguage = val),
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
