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

/// AHD NSW Step 7 — Authorisation (final step)
///
/// API fields:
///   - organ_and_body_donation.authorisation
///
/// Builds [AhdCreateDto] from accumulated NSW flow data and submits.
class AhdStep7NswScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep7NswScreen({super.key, required this.flowData});

  @override
  State<AhdStep7NswScreen> createState() => _AhdStep7NswScreenState();
}

class _AhdStep7NswScreenState extends State<AhdStep7NswScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _authorisationController;

  @override
  void initState() {
    super.initState();
    _authorisationController =
        TextEditingController(text: widget.flowData.nswAuthorisation ?? '');
  }

  @override
  void dispose() {
    _authorisationController.dispose();
    super.dispose();
  }

  AhdFlowData _collectData() {
    return widget.flowData.copyWith(
      nswAuthorisation: _authorisationController.text.trim(),
    );
  }

  // ── Enum mapping helpers ──

  String? _mapBearability(String? choice) {
    switch (choice) {
      case BearabilityChoice.bearable:
        return BearableStatus.bearable;
      case BearabilityChoice.unbearable:
        return BearableStatus.unbearable;
      case BearabilityChoice.unsure:
        return BearableStatus.unsure;
      default:
        return choice;
    }
  }

  String? _mapCprChoice(String? choice) {
    switch (choice) {
      case CprChoice.accept:
        return CprMedicalDecision.acceptCpr;
      case CprChoice.doNotAccept:
        return CprMedicalDecision.rejectCpr;
      default:
        return choice;
    }
  }

  String? _mapMedicalTreatment(String? type) {
    switch (type) {
      case MedicalTreatmentType.artificialVentilation:
        return OtherMedicalSupport.artificialVentilation;
      case MedicalTreatmentType.renalDialysis:
        return OtherMedicalSupport.renalDialysis;
      case MedicalTreatmentType.lifeProlonging:
        return OtherMedicalSupport.lifeProlongingTreatment;
      case MedicalTreatmentType.other:
        return OtherMedicalSupport.other;
      default:
        return type;
    }
  }

  /// Build [AhdCreateDto] from accumulated NSW flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // Enduring guardians → ENDURING_GUARDIAN
    for (final g in data.nswEnduringGuardians) {
      if (g.firstName.isEmpty && g.lastName.isEmpty) continue;
      persons.add(AhdPersonDto(
        fullName: g.fullName,
        personType: AhdPersonType.enduringGuardian,
        dob: g.dob,
        phone: g.phone,
        address: g.address,
        suburb: g.addressSuburb,
        state: g.addressState,
        postcode: g.addressPostcode,
        country: g.addressCountry,
      ));
    }

    // Persons responsible → MEDICAL_GUARDIAN
    for (final p in data.nswPersonsResponsible) {
      if (p.firstName.isEmpty && p.lastName.isEmpty) continue;
      persons.add(AhdPersonDto(
        fullName: p.fullName,
        personType: AhdPersonType.medicalGuardian,
        dob: p.dob,
        phone: p.phone,
        address: p.address,
        suburb: p.addressSuburb,
        state: p.addressState,
        postcode: p.addressPostcode,
        country: p.addressCountry,
      ));
    }

    return AhdCreateDto(
      isEnduringGuardianAppointed: data.nswHasEnduringGuardian,
      qualityOfLifeTolerance: QualityOfLifeToleranceDto(
        noLongerRecogniseFamily: _mapBearability(data.nswCannotRecogniseFamily),
        noBladderControl: _mapBearability(data.nswNoBladderControl),
        cantFeedWashDress: _mapBearability(data.nswCannotFeedWashDress),
        relyPeopleForMovement: _mapBearability(data.nswCannotMoveInOutBed),
        needLifeTubeForFood: _mapBearability(data.nswCannotEatDrink),
        cantConverseWithPeople: _mapBearability(data.nswCannotMoveReposition),
      ),
      cprAndResuscitation: CprAndResuscitationDto(
        cprInstruction: _mapBearability(data.nswEndOfLifeCare),
        medicalNotExpectedToRecover: _mapCprChoice(data.nswCprChoice),
      ),
      treatmentDecisions: TreatmentDecisionsDto(
        otherMedicalSupport: _mapMedicalTreatment(data.nswMedicalTreatmentType),
        otherMedicalSupportInstruction: data.nswMedicalTreatmentOther,
      ),
      organAndBodyDonation: OrganAndBodyDonationDto(
        donateOrgan: data.nswDonateOrgans,
        consentOrganDonation: data.nswConsentOrganDonation,
        donateBody: data.nswDonateBody,
        consentBodyDonation: data.nswDiscussedDonation,
        authorisation: _authorisationController.text.trim(),
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
        title: 'Authorisation',
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
                      Text('Authorisation',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),
                      AppTextArea(
                        controller: _authorisationController,
                        label: 'Enter authorisation details',
                        isRequired: true,
                        maxLength: 4000,
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
              nextText: 'Finish',
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
