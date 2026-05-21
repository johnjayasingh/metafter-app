import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_dto.dart';
import '../../data/models/ahd_enums.dart';
import '../../data/models/ahd_flow_config.dart';
import '../../data/services/ahd_service.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD WA Step 7 — Declaration and signature (final step)
///
/// This is the final step: builds AhdCreateDto from accumulated WA flow data
/// and submits via AhdService().createOrUpdateAhdDto(dto).
class AhdStep7WaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep7WaScreen({super.key, required this.flowData});

  @override
  State<AhdStep7WaScreen> createState() => _AhdStep7WaScreenState();
}

class _AhdStep7WaScreenState extends State<AhdStep7WaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  String? _combineNonEmptyTexts(List<String?> values) {
    final nonEmpty = values
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (nonEmpty.isEmpty) return null;

    final unique = <String>[];
    for (final value in nonEmpty) {
      if (!unique.contains(value)) unique.add(value);
    }
    return unique.join('\n');
  }

  AhdFlowData _collectData() {
    return widget.flowData;
  }

  /// Build [AhdCreateDto] from the accumulated WA flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // ENDURING_GUARDIAN
    if ((data.waGuardianFirstName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.waGuardianFirstName!,
        personType: AhdPersonType.enduringGuardian,
        phone: data.waGuardianPhone,
      ));
    }
    // SECONDARY_ENDURING_GUARDIAN
    if ((data.waSubstituteGuardianFirstName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.waSubstituteGuardianFirstName!,
        personType: AhdPersonType.secondaryEnduringGuardian,
        phone: data.waSubstituteGuardianPhone,
      ));
    }
    // TERTIARY_ENDURING_GUARDIAN
    if ((data.waOtherSubstituteFirstName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.waOtherSubstituteFirstName!,
        personType: AhdPersonType.tertiaryEnduringGuardian,
        phone: data.waOtherSubstitutePhone,
      ));
    }
    // MEDICAL_ADVISOR
    if ((data.waMedicalAdvisorFirstName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.waMedicalAdvisorFirstName!,
        personType: AhdPersonType.medicalAdvisor,
        phone: data.waMedicalAdvisorPhone,
        other: {
          if ((data.waMedicalAdvisorPractice ?? '').isNotEmpty)
            'practice': data.waMedicalAdvisorPractice,
        },
      ));
    }
    // LEGAL_ADVISOR
    if ((data.waLegalAdvisorFirstName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.waLegalAdvisorFirstName!,
        personType: AhdPersonType.legalAdvisor,
        phone: data.waLegalAdvisorPhone,
        other: {
          if ((data.waLegalAdvisorPractice ?? '').isNotEmpty)
            'practice': data.waLegalAdvisorPractice,
        },
      ));
    }

    // Map interpreter choice to API enum
    String? interpreterUsage;
    if (data.waInterpreterChoice == WaInterpreterChoice.englishFirstLanguage) {
      interpreterUsage = 'ENGLISH_FIRST_LANGUAGE';
    } else if (data.waInterpreterChoice ==
        WaInterpreterChoice.engagedInterpreter) {
      interpreterUsage = 'ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER';
    } else if (data.waInterpreterChoice ==
        WaInterpreterChoice.didNotEngage) {
      interpreterUsage = 'ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER';
    }

    // Map EPG choice
    String? epgStatus;
    if (data.waEpgChoice == WaEpgChoice.made) {
      epgStatus = 'DONE';
    } else if (data.waEpgChoice == WaEpgChoice.notMade) {
      epgStatus = 'NOT_DONE';
    }

    // Map medical/legal advice
    String? medicalAdvice;
    if (data.waMedicalAdviceChoice == WaAdviceChoice.didObtain) {
      medicalAdvice = 'OBTAIN_MEDICAL_ADVICE';
    } else if (data.waMedicalAdviceChoice == WaAdviceChoice.didNotObtain) {
      medicalAdvice = 'NOT_OBTAIN_MEDICAL_ADVICE';
    }
    String? legalAdvice;
    if (data.waLegalAdviceChoice == WaAdviceChoice.didObtain) {
      legalAdvice = 'OBTAIN_LEGAL_ADVICE';
    } else if (data.waLegalAdviceChoice == WaAdviceChoice.didNotObtain) {
      legalAdvice = 'NOT_OBTAIN_LEGAL_ADVICE';
    }

    // Map living well choices to API enum values
    final livingWellMap = {
      'FAMILY_FRIENDS': 'SPEND_TIME_WITH_FAMILY',
      'LIVING_INDEPENDENTLY': 'LIVE_INDEPENDENTLY',
      'VISIT_HOMETOWN': 'VISIT_HOMETOWN',
      'SELF_CARE': 'CARE_MYSELF',
      'KEEPING_ACTIVE': 'KEEP_ACTIVE',
      'RECREATIONAL_ACTIVITIES': 'RECREATIONAL_ACTIVITIES',
      'RELIGIOUS_CULTURAL': 'PRACTISING_RELIGION',
      'CULTURAL_VALUES': 'LIVE_WITH_CULTURAL_RELIGIOUS_VALUES',
      'WORKING': 'WORKING_IN_A_JOB',
    };
    final apiLivingWell = data.waLivingWellChoices
        .map((k) => livingWellMap[k] ?? k)
        .toList();

    // Map comfort choices to API enum values
    final comfortMap = {
      'NO_PAIN': 'MANAGED_SYMPTOMS',
      'LOVED_ONES': 'LOVED_ONES_NEARBY',
      'CULTURAL_TRADITIONS': 'CULTURAL_RELIGIOUS',
      'PASTORAL_CARE': 'SPIRITUAL_CARE',
      'SURROUNDINGS': 'HEALTHY_SURROUNDINGS',
    };
    final apiComfort = data.waComfortChoices
        .map((k) => comfortMap[k] ?? k)
        .toList();

    // Map nearing death location to API enum
    final nearingDeathMap = {
      'AT_HOME': 'AT_HOME',
      'NOT_AT_HOME': 'NOT_AT_HOME',
      'NO_PREFERENCE': 'NO_PREFERENCE',
      'BEST_CARE': 'RECEIVE_CARE',
      'OTHER': 'OTHER',
    };
    final apiNearingDeath = data.waNearingDeathLocations.isNotEmpty
        ? data.waNearingDeathLocations
            .map((loc) => nearingDeathMap[loc] ?? loc)
            .toList()
        : null;

    final comfortNarrative = _combineNonEmptyTexts([
      data.waComfortPainDetails,
      data.waComfortSurroundingsDetails,
    ]);

    return AhdCreateDto(
      isAcdRevoked: data.waRevokeAcd ?? false,
      healthConditions: HealthConditionsDto(
        majorHealthConditions: data.waHealthConditions,
        thingsImportantForMe: data.waTreatmentPreferences,
        nearingDeathPreference: comfortNarrative,
        comfortNearingDeath:
            apiComfort.isNotEmpty ? apiComfort : null,
      ),
      livingPreferences: LivingPreferencesDto(
        healthTreatmentPriority: data.waTreatmentPreferences,
        livingWellImportance:
            apiLivingWell.isNotEmpty ? apiLivingWell : null,
        isNearingDeath: apiNearingDeath,
        nearingDeathGoalsDetail: data.waNearingDeathLocationDetails,
        comfortPainDetails: data.waComfortPainDetails,
        comfortSurroundingsDetails: data.waComfortSurroundingsDetails,
      ),
      lifeSustainingTreatment: LifeSustainingTreatmentDto(
        treatmentType: AhdEnumMapper.mapWaLifeSustainingTreatment(data.waLifeSustainingTreatment),
        treatmentInstruction: data.waLifeSustainingDetails,
        assistedVentilation: AhdEnumMapper.mapTreatmentChoice(data.waAssistedVentilation),
        assistedVentilationInstruction: data.waAssistedVentilationDetails,
        artificialNutrition: AhdEnumMapper.mapTreatmentChoice(data.waArtificialNutrition),
        artificialNutritionInstruction: data.waArtificialNutritionDetails,
        antibiotics: AhdEnumMapper.mapTreatmentChoice(data.waAntibiotics),
        antibioticsInstruction: data.waAntibioticsDetails,
        bloodTransfusion: AhdEnumMapper.mapBloodTransfusion(data.waBloodProducts),
        bloodTransfusionInstruction: data.waBloodProductsDetails,
        otherTreatment: AhdEnumMapper.mapTreatmentChoice(data.waOtherTreatment),
        otherInstruction: data.waOtherTreatmentDetails ?? data.waOtherTreatmentName,
      ),
      cprAndResuscitation: CprAndResuscitationDto(
        cprResuscitation: AhdEnumMapper.mapTreatmentChoice(data.waCpr),
        cprResuscitationInstruction: data.waCprDetails,
      ),
      treatmentDecisions: TreatmentDecisionsDto(
        artificialHydration: AhdEnumMapper.mapTreatmentChoice(data.waArtificialHydration),
        artificialHydrationInstruction: data.waArtificialHydrationDetails,
        otherTreatmentDecision: AhdEnumMapper.mapTreatmentChoice(data.waDialysis),
        otherTreatmentDecisionInstruction: data.waDialysisDetails,
      ),
      attorneyAndAdvice: AttorneyAndAdviceDto(
        hasUsedInterpreter: interpreterUsage,
        hasEpg: epgStatus,
        epgDate: data.waEpgDate,
        epgPlaceDetail: data.waEpgLocation,
        seekMedicalAdvice: medicalAdvice,
        seekLegalAdvice: legalAdvice,
      ),
      declarationsAndWishes: DeclarationsAndWishesDto(
        whatWorriesMost: data.waWorries,
        nearingDeathInstruction: data.waNearingDeathLocationDetails,
      ),
      medicalResearchConsent: MedicalResearchConsentDto(
        placebos: data.waMrPlacebos,
        useEquipment: data.waMrUseEquipment,
        lessPractitionersSupport: data.waMrLessPractitioners,
        comparativeAssessment: data.waMrComparativeAssessment,
        bloodSamples: data.waMrBloodSamples,
        tissueSample: data.waMrTissueSample,
        nonIntrusiveTreatment: data.waMrNonIntrusiveTreatment,
        beingObserved: data.waMrBeingObserved,
        undertakingSurvey: data.waMrUndertakingSurvey,
        collecingDisclosingInformation: data.waMrCollectingDisclosing,
        evaluatingSamples: data.waMrEvaluatingSamples,
        other: data.waMrOther,
      ),
      organAndBodyDonation: OrganAndBodyDonationDto(
        authorisation: null,
      ),
      ahdPersons: persons.isNotEmpty ? persons : null,
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
          currentStep: 7, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 7,
        totalSteps: config.totalSteps,
        title: 'Review & Submit',
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
                      Text('Review & Submit',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 16),
                      Text(
                        'Please review your advance health directive details and submit when ready.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            AhdBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _isSubmitting ? null : _handleFinish,
              nextText: 'Submit',
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
