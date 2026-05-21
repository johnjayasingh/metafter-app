import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD WA Step 6 — People who helped me complete this form
///
/// API fields (in attorney_and_advice):
///   - has_used_interpreter (WaInterpreterChoice)
///   - has_epg / epg_date / epg_place_detail (WaEpgChoice)
///   - seek_medical_advice / seek_legal_advice (WaAdviceChoice)
///
/// Persons: ENDURING_GUARDIAN, SECONDARY_ENDURING_GUARDIAN,
///   TERTIARY_ENDURING_GUARDIAN, MEDICAL_ADVISOR, LEGAL_ADVISOR
class AhdStep6WaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep6WaScreen({super.key, required this.flowData});

  @override
  State<AhdStep6WaScreen> createState() => _AhdStep6WaScreenState();
}

class _AhdStep6WaScreenState extends State<AhdStep6WaScreen> {
  // ── Interpreter ──
  late String? _interpreterChoice;

  // ── EPG ──
  late String? _epgChoice;
  late final TextEditingController _epgDateController;
  late final TextEditingController _epgLocationController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianPhoneController;
  late final TextEditingController _substituteGuardianNameController;
  late final TextEditingController _substituteGuardianPhoneController;
  late final TextEditingController _otherSubstituteNameController;
  late final TextEditingController _otherSubstitutePhoneController;

  // ── Medical advice ──
  late String? _medicalAdviceChoice;
  late final TextEditingController _medicalAdvisorNameController;
  late final TextEditingController _medicalAdvisorPhoneController;
  late final TextEditingController _medicalAdvisorPracticeController;

  // ── Legal advice ──
  late String? _legalAdviceChoice;
  late final TextEditingController _legalAdvisorNameController;
  late final TextEditingController _legalAdvisorPhoneController;
  late final TextEditingController _legalAdvisorPracticeController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;

    _interpreterChoice = d.waInterpreterChoice;

    _epgChoice = d.waEpgChoice;
    _epgDateController = TextEditingController(text: d.waEpgDate ?? '');
    _epgLocationController =
        TextEditingController(text: d.waEpgLocation ?? '');
    _guardianNameController =
        TextEditingController(text: d.waGuardianFirstName ?? '');
    _guardianPhoneController =
        TextEditingController(text: d.waGuardianPhone ?? '');
    _substituteGuardianNameController =
        TextEditingController(text: d.waSubstituteGuardianFirstName ?? '');
    _substituteGuardianPhoneController =
        TextEditingController(text: d.waSubstituteGuardianPhone ?? '');
    _otherSubstituteNameController =
        TextEditingController(text: d.waOtherSubstituteFirstName ?? '');
    _otherSubstitutePhoneController =
        TextEditingController(text: d.waOtherSubstitutePhone ?? '');

    _medicalAdviceChoice = d.waMedicalAdviceChoice;
    _medicalAdvisorNameController =
        TextEditingController(text: d.waMedicalAdvisorFirstName ?? '');
    _medicalAdvisorPhoneController =
        TextEditingController(text: d.waMedicalAdvisorPhone ?? '');
    _medicalAdvisorPracticeController =
        TextEditingController(text: d.waMedicalAdvisorPractice ?? '');

    _legalAdviceChoice = d.waLegalAdviceChoice;
    _legalAdvisorNameController =
        TextEditingController(text: d.waLegalAdvisorFirstName ?? '');
    _legalAdvisorPhoneController =
        TextEditingController(text: d.waLegalAdvisorPhone ?? '');
    _legalAdvisorPracticeController =
        TextEditingController(text: d.waLegalAdvisorPractice ?? '');
  }

  @override
  void dispose() {
    _epgDateController.dispose();
    _epgLocationController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _substituteGuardianNameController.dispose();
    _substituteGuardianPhoneController.dispose();
    _otherSubstituteNameController.dispose();
    _otherSubstitutePhoneController.dispose();
    _medicalAdvisorNameController.dispose();
    _medicalAdvisorPhoneController.dispose();
    _medicalAdvisorPracticeController.dispose();
    _legalAdvisorNameController.dispose();
    _legalAdvisorPhoneController.dispose();
    _legalAdvisorPracticeController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waInterpreterChoice: _interpreterChoice,
      waEpgChoice: _epgChoice,
      waEpgDate: _epgChoice == WaEpgChoice.made
          ? _epgDateController.text.trim()
          : null,
      waEpgLocation: _epgChoice == WaEpgChoice.made
          ? _epgLocationController.text.trim()
          : null,
      waGuardianFirstName: _epgChoice == WaEpgChoice.made
          ? _guardianNameController.text.trim()
          : null,
      waGuardianPhone: _epgChoice == WaEpgChoice.made
          ? _guardianPhoneController.text.trim()
          : null,
      waSubstituteGuardianFirstName: _epgChoice == WaEpgChoice.made
          ? _substituteGuardianNameController.text.trim()
          : null,
      waSubstituteGuardianPhone: _epgChoice == WaEpgChoice.made
          ? _substituteGuardianPhoneController.text.trim()
          : null,
      waOtherSubstituteFirstName: _epgChoice == WaEpgChoice.made
          ? _otherSubstituteNameController.text.trim()
          : null,
      waOtherSubstitutePhone: _epgChoice == WaEpgChoice.made
          ? _otherSubstitutePhoneController.text.trim()
          : null,
      waMedicalAdviceChoice: _medicalAdviceChoice,
      waMedicalAdvisorFirstName:
          _medicalAdviceChoice == WaAdviceChoice.didObtain
              ? _medicalAdvisorNameController.text.trim()
              : null,
      waMedicalAdvisorPhone:
          _medicalAdviceChoice == WaAdviceChoice.didObtain
              ? _medicalAdvisorPhoneController.text.trim()
              : null,
      waMedicalAdvisorPractice:
          _medicalAdviceChoice == WaAdviceChoice.didObtain
              ? _medicalAdvisorPracticeController.text.trim()
              : null,
      waLegalAdviceChoice: _legalAdviceChoice,
      waLegalAdvisorFirstName:
          _legalAdviceChoice == WaAdviceChoice.didObtain
              ? _legalAdvisorNameController.text.trim()
              : null,
      waLegalAdvisorPhone:
          _legalAdviceChoice == WaAdviceChoice.didObtain
              ? _legalAdvisorPhoneController.text.trim()
              : null,
      waLegalAdvisorPractice:
          _legalAdviceChoice == WaAdviceChoice.didObtain
              ? _legalAdvisorPracticeController.text.trim()
              : null,
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(6), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  // ── Helpers ──

  Widget _buildNamePhoneFields({
    required TextEditingController nameController,
    required TextEditingController phoneController,
  }) {
    return Column(
      children: [
        AppTextField(controller: nameController, label: 'First name'),
        const SizedBox(height: 16),
        AppPhoneInput(
          controller: phoneController,
          countryCode: FormConstants.defaultCountryCode,
          onCountryCodeChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(height: 1, color: AppColors.borderGray),
        const SizedBox(height: 32),
      ],
    );
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
        title: 'People who helped',
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
                    Text('People who helped me complete this form',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    // ── Interpreter section ──
                    Text('Interpreter / Translator',
                        style: AppTextStyles.questionTitle),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _interpreterChoice ==
                          WaInterpreterChoice.englishFirstLanguage,
                      title:
                          'English is my first language \u2013 I did not need to engage an interpreter and/or translator.',
                      onTap: () => setState(() => _interpreterChoice =
                          WaInterpreterChoice.englishFirstLanguage),
                    ),
                    const SizedBox(height: 8),
                    RadioListOption(
                      isSelected: _interpreterChoice ==
                          WaInterpreterChoice.engagedInterpreter,
                      title:
                          'English is not my first language \u2013 I engaged an interpreter and/or translator when making this Advance Health Directive and I have attached an interpreter/translator statement.',
                      onTap: () => setState(() => _interpreterChoice =
                          WaInterpreterChoice.engagedInterpreter),
                    ),
                    const SizedBox(height: 8),
                    RadioListOption(
                      isSelected: _interpreterChoice ==
                          WaInterpreterChoice.didNotEngage,
                      title:
                          'English is not my first language \u2013 I did not engage an interpreter and/or translator when making this Advance Health Directive.',
                      onTap: () => setState(() => _interpreterChoice =
                          WaInterpreterChoice.didNotEngage),
                    ),

                    _buildSectionDivider(),

                    // ── EPG section ──
                    Text('Enduring Power of Guardianship',
                        style: AppTextStyles.questionTitle),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _epgChoice == WaEpgChoice.notMade,
                      title: 'I have not made an Enduring Power of Guardianship',
                      onTap: () =>
                          setState(() => _epgChoice = WaEpgChoice.notMade),
                    ),
                    const SizedBox(height: 8),
                    RadioListOption(
                      isSelected: _epgChoice == WaEpgChoice.made,
                      title: 'I have made an Enduring Power of Guardianship',
                      onTap: () =>
                          setState(() => _epgChoice = WaEpgChoice.made),
                    ),

                    if (_epgChoice == WaEpgChoice.made) ...[
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _epgDateController,
                        label: 'Date',
                        onDateSelected: (date) {
                          _epgDateController.text =
                              AppDatePickerField.formatDate(date);
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _epgLocationController,
                        label: 'Be as specific as possible',
                      ),
                      const SizedBox(height: 24),

                      Text('Enduring Guardian',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      _buildNamePhoneFields(
                        nameController: _guardianNameController,
                        phoneController: _guardianPhoneController,
                      ),
                      const SizedBox(height: 24),

                      Text('Substitute Guardian',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      _buildNamePhoneFields(
                        nameController: _substituteGuardianNameController,
                        phoneController: _substituteGuardianPhoneController,
                      ),
                      const SizedBox(height: 24),

                      Text('Other Substitute',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      _buildNamePhoneFields(
                        nameController: _otherSubstituteNameController,
                        phoneController: _otherSubstitutePhoneController,
                      ),
                    ],

                    _buildSectionDivider(),

                    // ── Medical advice section ──
                    Text('Medical advice',
                        style: AppTextStyles.questionTitle),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _medicalAdviceChoice ==
                          WaAdviceChoice.didNotObtain,
                      title:
                          'I did not obtain medical advice about the making of this Advance Health Directive.',
                      onTap: () => setState(() => _medicalAdviceChoice =
                          WaAdviceChoice.didNotObtain),
                    ),
                    const SizedBox(height: 8),
                    RadioListOption(
                      isSelected: _medicalAdviceChoice ==
                          WaAdviceChoice.didObtain,
                      title:
                          'I did obtain medical advice about the making of this Advance Health Directive.',
                      onTap: () => setState(() => _medicalAdviceChoice =
                          WaAdviceChoice.didObtain),
                    ),

                    if (_medicalAdviceChoice ==
                        WaAdviceChoice.didObtain) ...[
                      const SizedBox(height: 16),
                      _buildNamePhoneFields(
                        nameController: _medicalAdvisorNameController,
                        phoneController: _medicalAdvisorPhoneController,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _medicalAdvisorPracticeController,
                        label: 'Practice',
                      ),
                    ],

                    _buildSectionDivider(),

                    // ── Legal advice section ──
                    Text('Legal advice',
                        style: AppTextStyles.questionTitle),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _legalAdviceChoice ==
                          WaAdviceChoice.didNotObtain,
                      title:
                          'I did not obtain legal advice about the making of this Advance Health Directive.',
                      onTap: () => setState(() => _legalAdviceChoice =
                          WaAdviceChoice.didNotObtain),
                    ),
                    const SizedBox(height: 8),
                    RadioListOption(
                      isSelected: _legalAdviceChoice ==
                          WaAdviceChoice.didObtain,
                      title:
                          'I did obtain legal advice about the making of this Advance Health Directive.',
                      onTap: () => setState(() => _legalAdviceChoice =
                          WaAdviceChoice.didObtain),
                    ),

                    if (_legalAdviceChoice ==
                        WaAdviceChoice.didObtain) ...[
                      const SizedBox(height: 16),
                      _buildNamePhoneFields(
                        nameController: _legalAdvisorNameController,
                        phoneController: _legalAdvisorPhoneController,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _legalAdvisorPracticeController,
                        label: 'Practice',
                      ),
                    ],

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
