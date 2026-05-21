import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_dto.dart';
import '../../data/models/ahd_enums.dart' hide InterpreterLanguages, SaWitnessCategory;
import '../../data/models/ahd_flow_config.dart';
import '../../data/services/ahd_service.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD South Australia Step 10 — Interpreter statement (final step)
///
/// API fields (in ahd_persons):
///   - INTERPRETER: full_name, other.naati_number
///
/// This is the final step: builds AhdCreateDto from accumulated flow data
/// and submits via AhdService().createOrUpdateAhdDto(dto).
class AhdStep10SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep10SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep10SaScreen> createState() => _AhdStep10SaScreenState();
}

class _AhdStep10SaScreenState extends State<AhdStep10SaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _interpreterNameController;
  late final TextEditingController _interpreterNaatiController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _interpreterNameController =
        TextEditingController(text: d.saInterpreterName ?? '');
    _interpreterNaatiController =
        TextEditingController(text: d.saInterpreterNaati ?? '');
  }

  @override
  void dispose() {
    _interpreterNameController.dispose();
    _interpreterNaatiController.dispose();
    super.dispose();
  }

  AhdFlowData _collectData() {
    return widget.flowData.copyWith(
      saInterpreterName: _interpreterNameController.text.trim(),
      saInterpreterNaati: _interpreterNaatiController.text.trim(),
    );
  }

  /// Map UI witness category values to API values.
  static String _mapWitnessCategory(String cat) {
    switch (cat) {
      case 'LEGAL_PRACTITIONER':
        return 'LAWYER';
      case 'PROCLAIMED_POLICE_OFFICER':
        return 'COMMISSIONER_FOR_DECLARATIONS';
      default:
        return cat;
    }
  }

  /// Build [AhdCreateDto] from the accumulated SA flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // SUBSTITUTE_DECISION_MAKER persons (from step 2 attorney list)
    for (int i = 0; i < data.saSubstituteDecisionMakers.length; i++) {
      final a = data.saSubstituteDecisionMakers[i];
      // Acceptance data (address, date) from step 3
      final addr = i == 0 ? data.saSubDm1Address : data.saSubDm2Address;
      final date = i == 0 ? data.saSubDm1Date : data.saSubDm2Date;
      persons.add(AhdPersonDto(
        fullName: a.fullName,
        personType: i == 0
            ? AhdPersonType.substituteDecisionMaker
            : AhdPersonType.substituteDecisionMakerSecondary,
        address: addr ?? a.address,
        phone: a.phone,
        other: {
          if (date != null && date.isNotEmpty) 'date': date,
        },
      ));
    }

    // If step 3 has DM1 data but step 2 had no DMs, add from step 3
    if (data.saSubstituteDecisionMakers.isEmpty &&
        (data.saSubDm1FullName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.saSubDm1FullName!,
        personType: AhdPersonType.substituteDecisionMaker,
        address: data.saSubDm1Address,
        other: {
          if (data.saSubDm1Date != null && data.saSubDm1Date!.isNotEmpty)
            'date': data.saSubDm1Date!,
        },
      ));
    }

    // If step 3 has DM2 data but step 2 only had ≤1 DM, add the second
    if (data.saSubstituteDecisionMakers.length < 2 &&
        (data.saSubDm2FullName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.saSubDm2FullName!,
        personType: AhdPersonType.substituteDecisionMakerSecondary,
        address: data.saSubDm2Address,
        other: {
          if (data.saSubDm2Date != null && data.saSubDm2Date!.isNotEmpty)
            'date': data.saSubDm2Date!,
        },
      ));
    }

    // WITNESS_PRIMARY — person giving directive
    if ((data.saWitnessFullName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.saWitnessFullName!,
        personType: AhdPersonType.witnessPrimary,
        phone: data.saWitnessPhone,
        other: {
          if (data.saWitnessSignature != null &&
              data.saWitnessSignature!.isNotEmpty)
            'signature': data.saWitnessSignature,
          if (data.saWitnessDate != null && data.saWitnessDate!.isNotEmpty)
            'date': data.saWitnessDate,
        },
      ));
    }

    // WITNESS_AUTHORIZED — authorised witness
    if ((data.saAuthorisedWitnessFullName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.saAuthorisedWitnessFullName!,
        personType: AhdPersonType.witnessAuthorized,
        phone: data.saAuthorisedWitnessPhone,
        other: {
          if (data.saWitnessCategory != null)
            'witness_category': _mapWitnessCategory(data.saWitnessCategory!),
          if (data.saAuthorisedWitnessSignature != null &&
              data.saAuthorisedWitnessSignature!.isNotEmpty)
            'signature': data.saAuthorisedWitnessSignature,
          if (data.saAuthorisedWitnessDate != null &&
              data.saAuthorisedWitnessDate!.isNotEmpty)
            'date': data.saAuthorisedWitnessDate,
          if (data.saExtraExecutionStatement != null &&
              data.saExtraExecutionStatement!.isNotEmpty)
            'statement': data.saExtraExecutionStatement,
        },
      ));
    }

    // INTERPRETER
    final interpName = _interpreterNameController.text.trim();
    if (interpName.isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: interpName,
        personType: AhdPersonType.interpreter,
        other: {
          if (_interpreterNaatiController.text.trim().isNotEmpty)
            'naati_number': _interpreterNaatiController.text.trim(),
        },
      ));
    }

    return AhdCreateDto(
      // Health conditions
      healthConditions: HealthConditionsDto(
        majorHealthConditions: data.healthConditions,
        thingsImportantForMe: data.saLivingWell,
        nearingDeathPreference: data.saNearingDeath,
        peopleNotToInvolveHealthcareDiscussion: data.saOtherPeopleInvolved,
      ),
      // Living preferences
      livingPreferences: LivingPreferencesDto(
        wishToLive: data.saWhereToLive,
      ),
      // Treatment decisions — healthcare preferred
      treatmentDecisions: TreatmentDecisionsDto(
        healthcarePreferred: data.saHealthcarePreferred,
      ),
      // Declarations and wishes
      declarationsAndWishes: DeclarationsAndWishesDto(
        appointmentConditon: data.saConditionsOfAppointments,
        otherMedicalDecision: data.saRefusalHealthCare,
        otherThingsKnown: data.saOtherThingsKnown,
        declaration: data.saStatementResponse,
      ),
      // Organ donation — flat field + nested instruction
      organDonation: data.saOrganDonationChoice,
      organAndBodyDonation: (data.saOrganDonationInstruction ?? '').isNotEmpty
          ? OrganAndBodyDonationDto(
              organDonationInstruction: data.saOrganDonationInstruction,
            )
          : null,
      // Medical treatment refuse
      medicalTreatmentRefuse: data.saRefusalHealthCare,
      // Expiry date
      acdExpiryDate: data.saExpiryDate,
      // Persons
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
          currentStep: 10, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 10,
        totalSteps: config.totalSteps,
        title: 'Interpreter statement',
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
                      Text('Interpreter statement',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      Text(
                        'If an interpreter assisted in the preparation of this document:',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _interpreterNameController,
                        label: 'Name of interpreter',
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'If accredited with the National Accreditation Authority',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _interpreterNaatiController,
                        label: 'NAATI number',
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
