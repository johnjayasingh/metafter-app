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

/// AHD NT Step 7 — Signing and witnessing (final step)
///
/// Builds [AhdCreateDto] from accumulated NT flow data and submits.
class AhdStep7NtScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep7NtScreen({super.key, required this.flowData});

  @override
  State<AhdStep7NtScreen> createState() => _AhdStep7NtScreenState();
}

class _AhdStep7NtScreenState extends State<AhdStep7NtScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _witnessNameController;
  late final TextEditingController _witnessAddressController;

  @override
  void initState() {
    super.initState();
    _witnessNameController = TextEditingController(text: widget.flowData.ntSign ?? '');
    _witnessAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _witnessNameController.dispose();
    _witnessAddressController.dispose();
    super.dispose();
  }

  AhdFlowData _collectData() {
    return widget.flowData.copyWith(
      ntSign: _witnessNameController.text.trim(),
    );
  }

  // ── Enum mapping helpers ──

  String? _mapCprChoice(String? choice) {
    switch (choice) {
      case NtCprChoice.attemptCpr:
        return CprConsent.restart;
      case NtCprChoice.exceptUnacceptable:
        return CprConsent.condition;
      case NtCprChoice.naturalDeath:
        return CprConsent.allowToDie;
      default:
        return choice;
    }
  }

  String? _mapWhereToDie(String? choice) {
    switch (choice) {
      case NtWhereToDieChoice.atHomeOnCountry:
        return WhereToDiePreference.home;
      case NtWhereToDieChoice.hospitalHospice:
        return WhereToDiePreference.hospital;
      case NtWhereToDieChoice.other:
        return WhereToDiePreference.other;
      default:
        return choice;
    }
  }

  String _mapRefusedTreatment(String t) {
    switch (t) {
      case NtRefusedTreatment.bloodTransfusions:
        return SpecificTreatmentNoConsent.transfusions;
      default:
        return t;
    }
  }

  String? _mapDecisionMethod(String? method) {
    switch (method) {
      case NtDecisionMethod.severally:
        return AttorneyDecisionPower.severally;
      case NtDecisionMethod.jointly:
        return AttorneyDecisionPower.jointly;
      case NtDecisionMethod.other:
        return AttorneyDecisionPower.other;
      default:
        return method;
    }
  }

  String _mapMatters(String m) {
    switch (m) {
      case NtMatters.allMatters:
        return 'BOTH';
      case NtMatters.personalHealthMatters:
        return AhdMatters.health;
      case NtMatters.financialMatters:
        return AhdMatters.finance;
      case NtMatters.limitedMatters:
        return AhdMatters.limited;
      default:
        return m;
    }
  }

  /// Build [AhdCreateDto] from accumulated NT flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // Decision makers with matters (person_type=DECISION_MAKER, matters in other)
    for (final dm in data.ntDecisionMakers) {
      if (dm.firstName.isEmpty) continue;
      final otherMap = <String, dynamic>{};
      if (dm.matters != null) {
        otherMap['matters'] = _mapMatters(dm.matters!);
      }
      persons.add(AhdPersonDto(
        fullName: dm.fullName,
        personType: AhdPersonType.primaryPerson,
        address: dm.address,
        phone: dm.phone,
        dob: dm.dob,
        other: otherMap.isNotEmpty ? otherMap : null,
      ));
    }

    // Appointed decision makers without matters (person_type=DECISION_MAKER)
    for (final dm in data.ntAppointedDecisionMakers) {
      if (dm.firstName.isEmpty) continue;
      persons.add(AhdPersonDto(
        fullName: dm.fullName,
        personType: AhdPersonType.decisionMaker,
        dob: dm.dob,
        phone: dm.phone,
        address: dm.address,
      ));
    }

    // Witness (person_type=WITNESS_PRIMARY with signature in other)
    final witnessName = _witnessNameController.text.trim();
    if (witnessName.isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: witnessName,
        personType: AhdPersonType.witnessPrimary,
        address: _witnessAddressController.text.trim(),
        other: {
          'signature': witnessName,
        },
      ));
    }

    // Map refused treatments
    String? specificTreatment;
    if (data.ntRefusedTreatments.isNotEmpty) {
      specificTreatment = _mapRefusedTreatment(data.ntRefusedTreatments.first);
    }

    return AhdCreateDto(
      livingPreferences: LivingPreferencesDto(
        nearingDeathGoalsDetail: data.ntNearingDeathGoals,
        nearingDeathUnacceptable: data.ntUnacceptableOutcomes,
        whereToDie: _mapWhereToDie(data.ntWhereToDieChoice),
        whereToDieInstruction: data.ntWhereToDie,
      ),
      treatmentDecisions: TreatmentDecisionsDto(
        consentPalliativeComfortCare: data.ntPalliativeCare,
        specificTreatmentNoConsent: specificTreatment,
        specificTreatmentNoConsentInstruction: data.ntRefusedTreatmentOther,
      ),
      cprAndResuscitation: CprAndResuscitationDto(
        cprConsent: _mapCprChoice(data.ntCprChoice),
        cprConsentInstruction: data.ntCprConditionDetails,
      ),
      declarationsAndWishes: DeclarationsAndWishesDto(
        whatMatterMost: data.ntLifeMeaning,
        otherMedicalDecision: data.ntOtherMedicalInfo,
        culturalRequest: data.ntCulturalRequests,
        religiousBeliefs: data.ntReligiousBeliefs,
        afterDeathImportance: data.ntAfterDeath1,
        nearingDeathInstruction: data.ntAfterDeath2,
      ),
      attorneyAndAdvice: AttorneyAndAdviceDto(
        attorneyDecisionPower: _mapDecisionMethod(data.ntDecisionMethod),
        attorneyDecisionPowerDetail: data.ntDecisionMethodOther,
      ),
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
          currentStep: 7, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 7,
        totalSteps: config.totalSteps,
        title: 'Signing and witnessing',
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
                      Text('Signing and witnessing',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'The witness must sign in the presence of the person making the advance care plan.',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 24),

                      Text('Witness', style: AppTextStyles.questionTitle),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _witnessNameController,
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
