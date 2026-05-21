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

/// AHD Queensland Step 9 — Declaration and signatures (final step)
///
/// API fields:
///   - declarations_and_wishes.declaration
///
/// This is the final step: builds AhdCreateDto from accumulated flow data
/// and submits via AhdService().createOrUpdateAhdDto(dto).
class AhdStep9QldScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep9QldScreen({super.key, required this.flowData});

  @override
  State<AhdStep9QldScreen> createState() => _AhdStep9QldScreenState();
}

class _AhdStep9QldScreenState extends State<AhdStep9QldScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _declarationController;

  @override
  void initState() {
    super.initState();
    _declarationController =
        TextEditingController(text: widget.flowData.declarationDetails ?? '');
  }

  @override
  void dispose() {
    _declarationController.dispose();
    super.dispose();
  }

  AhdFlowData _collectData() {
    return widget.flowData.copyWith(
      declarationDetails: _declarationController.text.trim(),
    );
  }

  /// Build [AhdCreateDto] from the accumulated QLD flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // DOCTOR person
    if ((data.doctorName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.doctorName!,
        personType: AhdPersonType.doctor,
        dob: data.doctorDob,
        phone: data.doctorPhone,
        address: data.doctorAddress,
        suburb: data.doctorSuburb,
        state: data.doctorState,
        postcode: data.doctorPostcode,
        other: {
          if ((data.facilityName ?? '').isNotEmpty)
            'facility_name': data.facilityName,
        },
      ));
    }

    // ATTORNEY_HEALTH_MATTERS persons
    for (final attorney in data.healthAttorneys) {
      persons.add(AhdPersonDto(
        fullName: attorney.fullName,
        personType: AhdPersonType.attorneyHealthMatters,
        address: attorney.address,
        phone: attorney.phone,
      ));
    }

    // Map other health care directions
    final otherDirections = data.otherHealthCareDirections
        .where((d) =>
            d.healthCondition.isNotEmpty ||
            d.directions.isNotEmpty)
        .map((d) => DirectionAboutOtherHealthcareDto(
              healthCondition: d.healthCondition,
              healthDirection: d.directions,
            ))
        .toList();

    return AhdCreateDto(
      // Health conditions
      healthConditions: HealthConditionsDto(
        majorHealthConditions: data.healthConditions,
        thingsImportantForMe: data.thingsImportant,
        believesConsideredDuringHealthCare: data.culturalValues,
        nearingDeathPreference: data.nearingDeathComfort,
        peopleNotToInvolveHealthcareDiscussion: data.peopleNotInvolved,
      ),
      // Life sustaining treatment
      lifeSustainingTreatment: LifeSustainingTreatmentDto(
        directionType: AhdEnumMapper.mapLifeSustainingDirective(data.lifeSustainingDirective),
        directionInstruction: data.lifeSustainingDirectiveDetails,
        treatmentType: AhdEnumMapper.mapTreatmentChoice(data.lifeSustainingTreatment),
        treatmentInstruction: data.lifeSustainingTreatmentDetails,
        assistedVentilation: AhdEnumMapper.mapTreatmentChoice(data.assistedVentilation),
        assistedVentilationInstruction: data.assistedVentilationDetails,
        artificialNutrition: AhdEnumMapper.mapTreatmentChoice(data.artificialNutrition),
        artificialNutritionInstruction: data.artificialNutritionDetails,
        antibiotics: AhdEnumMapper.mapTreatmentChoice(data.antibiotics),
        antibioticsInstruction: data.antibioticsDetails,
        bloodTransfusion: AhdEnumMapper.mapBloodTransfusion(data.bloodTransfusionChoice),
        bloodTransfusionInstruction: data.bloodTransfusionOther,
        otherTreatment: AhdEnumMapper.mapTreatmentChoice(data.otherTreatment),
        otherInstruction: data.otherTreatmentDetails,
      ),
      // Treatment decisions (artificial hydration is here per web)
      treatmentDecisions: TreatmentDecisionsDto(
        artificialHydration: AhdEnumMapper.mapTreatmentChoice(data.artificialHydration),
        artificialHydrationInstruction: data.artificialHydrationDetails,
      ),
      // Attorney and advice
      attorneyAndAdvice: AttorneyAndAdviceDto(
        attorneyDecisionPower: data.attorneyDecisionMethod,
        attorneyDecisionPowerDetail: data.attorneyDecisionOther,
      ),
      // Declarations and wishes
      declarationsAndWishes: DeclarationsAndWishesDto(
        declaration: _declarationController.text.trim(),
      ),
      // Other health directions
      otherHealthDirections:
          otherDirections.isNotEmpty ? otherDirections : null,
      // Persons
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
          currentStep: 9, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 9,
        totalSteps: config.totalSteps,
        title: 'Declaration and signatures',
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
                      Text('Declaration and signatures',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),
                      AppTextArea(
                        controller: _declarationController,
                        label: 'Declaration',
                        maxLines: 8,
                        minLines: 4,
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
              nextText: 'Submit',
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
