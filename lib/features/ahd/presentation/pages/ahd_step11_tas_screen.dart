import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_dto.dart';
import '../../data/models/ahd_enums.dart' hide InterpreterLanguages;
import '../../data/models/ahd_flow_config.dart';
import '../../data/services/ahd_service.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Tasmania Step 11 — Organ and Tissue Donation (final step)
///
/// API fields:
///   - is_registered_australian_organ_donor
///   - is_registered_tasmania_bequest_program
///
/// This is the final step: builds AhdCreateDto from accumulated flow data
/// and submits via AhdService().createOrUpdateAhdDto(dto).
class AhdStep11TasScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep11TasScreen({super.key, required this.flowData});

  @override
  State<AhdStep11TasScreen> createState() => _AhdStep11TasScreenState();
}

class _AhdStep11TasScreenState extends State<AhdStep11TasScreen> {
  final _formKey = GlobalKey<FormState>();
  late String? _isOrganDonor;
  late String? _isBodyBequest;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _isOrganDonor = d.tasOrganDonorRegister == true ? 'yes' : d.tasOrganDonorRegister == false ? 'no' : null;
    _isBodyBequest = d.tasBodyBequestProgram == true ? 'yes' : d.tasBodyBequestProgram == false ? 'no' : null;
  }

  AhdFlowData _collectData() {
    return widget.flowData.copyWith(
      tasOrganDonorRegister: _isOrganDonor == 'yes',
      tasBodyBequestProgram: _isBodyBequest == 'yes',
    );
  }

  /// Build [AhdCreateDto] from the accumulated TAS flow data.
  AhdCreateDto _buildDto(AhdFlowData data) {
    final persons = <AhdPersonDto>[];

    // PRIMARY_PERSON — key signature (full name + date)
    if ((data.tasSignFullName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.tasSignFullName!,
        personType: AhdPersonType.primaryPerson,
        other: {
          if (data.tasSignDate != null) 'date': data.tasSignDate,
        },
      ));
    }

    // HELPER — delegated person who completed form on behalf
    if ((data.tasDelegatedPersonName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.tasDelegatedPersonName!,
        personType: AhdPersonType.helper,
        other: {
          if (data.tasDelegatedAcdPersonName != null)
            'ahd_primary_person_name': data.tasDelegatedAcdPersonName,
          if (data.tasDelegatedRelationship != null)
            'relationship': data.tasDelegatedRelationship,
        },
      ));
    }

    // Witnesses — medical practitioner or adult witness
    for (final w in data.tasWitnesses) {
      persons.add(AhdPersonDto(
        fullName: w.fullName.trim(),
        personType: w.isHealthPractitioner == true
            ? AhdPersonType.witnessMedicalPractitioner
            : AhdPersonType.witnessPerson,
        phone: w.phone,
        address: w.address,
        suburb: w.addressSuburb,
        postcode: w.addressPostcode,
        country: w.addressCountry,
        other: {
          if (w.qualification != null && w.qualification!.isNotEmpty)
            'qualification': w.qualification,
          if (w.signature != null && w.signature!.isNotEmpty)
            'signature': w.signature,
          if (w.dob != null && w.dob!.isNotEmpty) 'dob': w.dob,
          if (w.houseNumber != null && w.houseNumber!.isNotEmpty)
            'house_number': w.houseNumber,
        },
      ));
    }

    // INTERPRETER — interpreter/translator
    if ((data.tasInterpreterName ?? '').isNotEmpty) {
      persons.add(AhdPersonDto(
        fullName: data.tasInterpreterName!,
        personType: AhdPersonType.interpreter,
        other: {
          if (data.tasInterpreterLanguage != null)
            'language': data.tasInterpreterLanguage,
          if (data.tasInterpreterNaati != null)
            'naati_number': data.tasInterpreterNaati,
        },
      ));
    }

    return AhdCreateDto(
      // Health conditions
      healthConditions: HealthConditionsDto(
        majorHealthConditions: data.tasHealthConditions,
      ),
      // Values / wishes
      livingPreferences: LivingPreferencesDto(
        wishToLive: data.tasViewsWishes,
      ),
      // Treatment decisions
      treatmentDecisions: TreatmentDecisionsDto(
        otherTreatmentDecision: (data.tasMedicalTreatmentRefuse ?? '').isNotEmpty
            ? 'REFUSE'
            : (data.tasMedicalCircumstances ?? '').isNotEmpty
            ? 'CIRCUMSTANCE'
                : null,
        otherTreatmentDecisionInstruction: data.tasMedicalTreatmentRefuse,
        healthCircumstanceDecisionInstruction: data.tasMedicalCircumstances,
      ),
      // Expiry date
      acdExpiryDate: data.tasExpiryDate,
      // Revoke
      isAcdRevoked: data.tasRevokeAcd ?? false,
      // Organ donation flags
      isRegisteredAustralianOrganDonor: _isOrganDonor == 'yes',
      isRegisteredTasmaniaBequestProgram: _isBodyBequest == 'yes',
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
        title: 'Organ and Tissue Donation',
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
                      Text('Organ and Tissue Donation',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),
                      Text(
                        'I am registered on the Australian Organ Donor register',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      AppYesNoRadio(
                        value: _isOrganDonor,
                        onChanged: (v) =>
                            setState(() => _isOrganDonor = v),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'I am a donor under the University of Tasmania\'s Body Bequest Program',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      AppYesNoRadio(
                        value: _isBodyBequest,
                        onChanged: (v) =>
                            setState(() => _isBodyBequest = v),
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
            ),
          ],
        ),
      ),
    );
  }
}
