import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../../poa/data/services/poa_service.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../../data/services/ahd_service.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Step 2 — combines all health directive sections into one scrollable screen:
///   - Health Conditions & Concerns
///   - Views, Wishes & Preferences
///   - Directions about Life-Sustaining Treatment
///   - Directions about Other Healthcare
///   - Directions about Blood Transfusions
///   - Doctor Certificate
///   - Appointing Attorneys for Health Matters
///   - Declaration & Signatures
class AhdStep2Screen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep2Screen({super.key, required this.flowData});

  @override
  State<AhdStep2Screen> createState() => _AhdStep2ScreenState();
}

class _AhdStep2ScreenState extends State<AhdStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // ── Section 1: Health Conditions ──
  late final TextEditingController _healthConditionsController;

  // ── Section 2: Views, Wishes & Preferences ──
  late final TextEditingController _thingsImportantController;
  late final TextEditingController _culturalValuesController;
  late final TextEditingController _nearingDeathComfortController;
  late final TextEditingController _peopleNotInvolvedController;

  // ── Section 3: Life-Sustaining Directives ──
  late String? _lifeSustainingDirective;
  late final TextEditingController _directiveDetailsController;

  // Per-treatment choices
  late String? _lifeSustainingTreatment;
  late final TextEditingController _lifeSustainingDetailsController;
  late String? _assistedVentilation;
  late final TextEditingController _assistedVentilationDetailsController;
  late String? _artificialNutrition;
  late final TextEditingController _artificialNutritionDetailsController;
  late String? _artificialHydration;
  late final TextEditingController _artificialHydrationDetailsController;
  late String? _antibiotics;
  late final TextEditingController _antibioticsDetailsController;
  late String? _otherTreatment;
  late final TextEditingController _otherTreatmentDetailsController;

  // ── Section 4: Other Healthcare Directions ──
  late List<_HealthDirectionEntry> _otherHealthEntries;

  // ── Section 5: Blood Transfusions ──
  late String? _bloodTransfusionChoice;
  late final TextEditingController _bloodTransfusionOtherController;

  // ── Section 6: Doctor Certificate ──
  late final TextEditingController _doctorNameController;
  late final TextEditingController _facilityNameController;
  late final TextEditingController _doctorDobController;
  late final TextEditingController _doctorPhoneController;
  late final TextEditingController _doctorSignController;
  late final TextEditingController _doctorAddressController;
  late final TextEditingController _doctorSuburbController;
  late final TextEditingController _doctorPostcodeController;
  String? _doctorSelectedState;
  String _doctorCountryCode = FormConstants.defaultCountryCode;

  // ── Section 7: Appointing Attorneys ──
  late List<AhdAttorneyData> _attorneys;
  final PoaService _poaService = PoaService();
  List<RecipientInfo> _previousPeople = [];
  late String? _decisionMethod;
  late final TextEditingController _decisionOtherController;
  late final TextEditingController _termsController;

  // ── Section 8: Declaration ──
  late final TextEditingController _declarationController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;

    // Health conditions
    _healthConditionsController = TextEditingController(
        text: d.healthConditions ?? '');

    // Views & wishes
    _thingsImportantController = TextEditingController(
        text: d.thingsImportant ?? '');
    _culturalValuesController = TextEditingController(
        text: d.culturalValues ?? '');
    _nearingDeathComfortController = TextEditingController(
        text: d.nearingDeathComfort ?? '');
    _peopleNotInvolvedController = TextEditingController(
        text: d.peopleNotInvolved ?? '');

    // Directions — raw API values need mapping to VIC UI values
    _lifeSustainingDirective = _apiToVicDirective(d.lifeSustainingDirective);
    _directiveDetailsController = TextEditingController(
        text: d.lifeSustainingDirectiveDetails ?? '');
    _lifeSustainingTreatment = _apiToVicTreatment(d.lifeSustainingTreatment);
    _lifeSustainingDetailsController = TextEditingController(
        text: d.lifeSustainingTreatmentDetails ?? '');
    _assistedVentilation = _apiToVicTreatment(d.assistedVentilation);
    _assistedVentilationDetailsController = TextEditingController(
        text: d.assistedVentilationDetails ?? '');
    _artificialNutrition = _apiToVicTreatment(d.artificialNutrition);
    _artificialNutritionDetailsController = TextEditingController(
        text: d.artificialNutritionDetails ?? '');
    _artificialHydration = _apiToVicTreatment(d.artificialHydration);
    _artificialHydrationDetailsController = TextEditingController(
        text: d.artificialHydrationDetails ?? '');
    _antibiotics = _apiToVicTreatment(d.antibiotics);
    _antibioticsDetailsController = TextEditingController(
        text: d.antibioticsDetails ?? '');
    _otherTreatment = _apiToVicTreatment(d.otherTreatment);
    _otherTreatmentDetailsController = TextEditingController(
        text: d.otherTreatmentDetails ?? '');

    // Other healthcare
    if (d.otherHealthCareDirections.isEmpty) {
      _otherHealthEntries = [
        _HealthDirectionEntry(
          conditionController: TextEditingController(),
          directionsController: TextEditingController(),
        ),
      ];
    } else {
      _otherHealthEntries = d.otherHealthCareDirections
          .map((dir) => _HealthDirectionEntry(
                conditionController:
                    TextEditingController(text: dir.healthCondition),
                directionsController:
                    TextEditingController(text: dir.directions),
              ))
          .toList();
    }

    // Blood transfusions
    _bloodTransfusionChoice = d.bloodTransfusionChoice;
    _bloodTransfusionOtherController = TextEditingController(
        text: d.bloodTransfusionOther ?? '');

    // Doctor certificate
    _doctorNameController = TextEditingController(
        text: d.doctorName ?? '');
    _facilityNameController = TextEditingController(
        text: d.facilityName ?? '');
    _doctorDobController = TextEditingController(
        text: d.doctorDob ?? '');
    _doctorSignController = TextEditingController(
        text: d.doctorSign ?? '');
    _doctorAddressController = TextEditingController(
        text: d.doctorAddress ?? '');
    _doctorSuburbController = TextEditingController(
        text: d.doctorSuburb ?? '');
    _doctorPostcodeController = TextEditingController(
        text: d.doctorPostcode ?? '');
    _doctorSelectedState = d.doctorState;

    if (d.doctorPhone != null && d.doctorPhone!.isNotEmpty) {
      final (cc, local) = AppPhoneInput.parsePhoneNumber(d.doctorPhone!);
      _doctorCountryCode = cc;
      _doctorPhoneController = TextEditingController(text: local);
    } else {
      _doctorPhoneController = TextEditingController();
    }

    // Attorneys
    _attorneys = List<AhdAttorneyData>.from(d.healthAttorneys);
    _decisionMethod = d.attorneyDecisionMethod;
    _decisionOtherController = TextEditingController(
        text: d.attorneyDecisionOther ?? '');
    _termsController = TextEditingController(
        text: d.attorneyTerms ?? '');
    _loadPreviousPeople();

    // Declaration
    _declarationController = TextEditingController(
        text: d.declarationDetails ?? '');
  }

  @override
  void dispose() {
    _healthConditionsController.dispose();
    _thingsImportantController.dispose();
    _culturalValuesController.dispose();
    _nearingDeathComfortController.dispose();
    _peopleNotInvolvedController.dispose();
    _directiveDetailsController.dispose();
    _lifeSustainingDetailsController.dispose();
    _assistedVentilationDetailsController.dispose();
    _artificialNutritionDetailsController.dispose();
    _artificialHydrationDetailsController.dispose();
    _antibioticsDetailsController.dispose();
    _otherTreatmentDetailsController.dispose();
    for (final e in _otherHealthEntries) {
      e.conditionController.dispose();
      e.directionsController.dispose();
    }
    _bloodTransfusionOtherController.dispose();
    _doctorNameController.dispose();
    _facilityNameController.dispose();
    _doctorDobController.dispose();
    _doctorPhoneController.dispose();
    _doctorSignController.dispose();
    _doctorAddressController.dispose();
    _doctorSuburbController.dispose();
    _doctorPostcodeController.dispose();
    _decisionOtherController.dispose();
    _termsController.dispose();
    _declarationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousPeople() async {
    final willPersons = await _poaService.getWillPeople();
    if (!mounted) return;
    final List<RecipientInfo> combined = [];
    final Set<String> seen = {};
    for (final p in willPersons) {
      if (p['first_name'] == null && p['full_name'] == null) continue;
      final firstName = p['first_name'] as String? ?? '';
      final lastName = p['last_name'] as String? ?? '';
      final key = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      combined.add(RecipientInfo(
        id: p['id']?.toString() ?? '',
        firstName: firstName,
        middleName: p['middle_name'] as String?,
        lastName: lastName,
        email: p['email'] as String?,
        mobile: p['phone'] as String?,
        address: p['address'] as String?,
      ));
    }
    setState(() => _previousPeople = combined);
  }

  Future<void> _showSelectPreviousSheet(
      List<AhdAttorneyData> targetList) async {
    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: _previousPeople,
        title: 'Select previously added',
        subtitle: 'Select from previously added persons',
        emptyMessage: 'No previously added persons found.',
      ),
    );
    if (selected != null && mounted) {
      final person = AhdAttorneyData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        email: selected.email,
        phone: selected.mobile,
        address: selected.address,
      );
      setState(() => targetList.add(person));
    }
  }

  /// Map raw API directive value → VIC UI value for radio buttons.
  static String? _apiToVicDirective(String? d) {
    switch (d) {
      case 'CONSENT':
        return LifeSustainingDirective.consentAll;
      case 'REFUSE':
        return LifeSustainingDirective.refuseAll;
      case 'ATTORNEY_DECISION':
        return LifeSustainingDirective.attorneyDecides;
      case 'SPECIFIC_DIRECTION':
        return LifeSustainingDirective.enterDetails;
      default:
        return d; // already a VIC value or null
    }
  }

  /// Map raw API treatment value → VIC UI value for radio buttons.
  static String? _apiToVicTreatment(String? choice) {
    switch (choice) {
      case 'CONSENT':
        return TreatmentChoice.consentAll;
      case 'REFUSE':
        return TreatmentChoice.refuseAll;
      case 'CIRCUMSTANCE':
        return TreatmentChoice.consentCircumstances;
      default:
        return choice; // already a VIC value or null
    }
  }

  AhdFlowData _collectData() {
    final otherDirections = _otherHealthEntries
        .map((e) => HealthCareDirection(
              healthCondition: e.conditionController.text.trim(),
              directions: e.directionsController.text.trim(),
            ))
        .where((d) => d.healthCondition.isNotEmpty || d.directions.isNotEmpty)
        .toList();

    final fullPhone = _doctorPhoneController.text.trim().isNotEmpty
        ? '$_doctorCountryCode${_doctorPhoneController.text.trim()}'
        : null;

    return (_returnedFromNext ?? widget.flowData).copyWith(
      // Health conditions
      healthConditions: _healthConditionsController.text.trim(),
      // Views & wishes
      thingsImportant: _thingsImportantController.text.trim(),
      culturalValues: _culturalValuesController.text.trim(),
      nearingDeathComfort: _nearingDeathComfortController.text.trim(),
      peopleNotInvolved: _peopleNotInvolvedController.text.trim(),
      // Directions
      lifeSustainingDirective: _lifeSustainingDirective,
      lifeSustainingDirectiveDetails:
          _lifeSustainingDirective == LifeSustainingDirective.enterDetails
              ? _directiveDetailsController.text.trim()
              : null,
      lifeSustainingTreatment: _lifeSustainingTreatment,
      lifeSustainingTreatmentDetails:
          _lifeSustainingTreatment == TreatmentChoice.consentCircumstances
              ? _lifeSustainingDetailsController.text.trim()
              : null,
      assistedVentilation: _assistedVentilation,
      assistedVentilationDetails:
          _assistedVentilation == TreatmentChoice.consentCircumstances
              ? _assistedVentilationDetailsController.text.trim()
              : null,
      artificialNutrition: _artificialNutrition,
      artificialNutritionDetails:
          _artificialNutrition == TreatmentChoice.consentCircumstances
              ? _artificialNutritionDetailsController.text.trim()
              : null,
      artificialHydration: _artificialHydration,
      artificialHydrationDetails:
          _artificialHydration == TreatmentChoice.consentCircumstances
              ? _artificialHydrationDetailsController.text.trim()
              : null,
      antibiotics: _antibiotics,
      antibioticsDetails:
          _antibiotics == TreatmentChoice.consentCircumstances
              ? _antibioticsDetailsController.text.trim()
              : null,
      otherTreatment: _otherTreatment,
      otherTreatmentDetails:
          _otherTreatment == TreatmentChoice.consentCircumstances
              ? _otherTreatmentDetailsController.text.trim()
              : null,
      // Other healthcare
      otherHealthCareDirections: otherDirections,
      // Blood transfusions
      bloodTransfusionChoice: _bloodTransfusionChoice,
      bloodTransfusionOther:
          _bloodTransfusionChoice == BloodTransfusionChoice.other
              ? _bloodTransfusionOtherController.text.trim()
              : null,
      // Doctor certificate
      doctorName: _doctorNameController.text.trim(),
      facilityName: _facilityNameController.text.trim(),
      doctorDob: _doctorDobController.text.trim(),
      doctorPhone: fullPhone,
      doctorSign: _doctorSignController.text.trim(),
      doctorAddress: _doctorAddressController.text.trim(),
      doctorSuburb: _doctorSuburbController.text.trim(),
      doctorPostcode: _doctorPostcodeController.text.trim(),
      doctorState: _doctorSelectedState,
      // Attorneys
      healthAttorneys: List.from(_attorneys),
      attorneyDecisionMethod: _decisionMethod,
      attorneyDecisionOther:
          _decisionMethod == AttorneyDecisionMethod.other
              ? _decisionOtherController.text.trim()
              : null,
      attorneyTerms: _termsController.text.trim(),
      // Declaration
      declarationDetails: _declarationController.text.trim(),
    );
  }

  AhdFlowData? _returnedFromNext;

  /// Whether this state has more steps after step 2.
  bool get _hasMoreSteps {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return config.totalSteps > 2;
  }

  /// Navigate to step 3 (for states with more steps).
  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(2), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  /// Submit AHD directly (for states where step 2 is the final step).
  Future<void> _handleFinish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final finalData = _collectData();

    try {
      final result = await AhdService().createOrUpdateAhd(finalData);
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
      SnackBarUtils.showError(context, 'An error occurred. Please try again.');
    }
  }

  // ── Attorney management ──

  Future<void> _addAttorney() async {
    final result =
        await context.push<AhdAttorneyData>(AppRouter.ahdAddAttorney);
    if (result != null) {
      setState(() => _attorneys.add(result));
    }
  }

  void _removeAttorney(int index) {
    setState(() => _attorneys.removeAt(index));
  }

  Future<void> _editAttorney(int index) async {
    final result = await context.push<AhdAttorneyData>(
      AppRouter.ahdAddAttorney,
      extra: _attorneys[index],
    );
    if (result != null) {
      setState(() => _attorneys[index] = result);
    }
  }

  // ── Other healthcare entries ──

  void _addHealthEntry() {
    setState(() {
      _otherHealthEntries.add(
        _HealthDirectionEntry(
          conditionController: TextEditingController(),
          directionsController: TextEditingController(),
        ),
      );
    });
  }

  void _removeHealthEntry(int index) {
    if (_otherHealthEntries.length <= 1) return;
    setState(() {
      _otherHealthEntries[index].conditionController.dispose();
      _otherHealthEntries[index].directionsController.dispose();
      _otherHealthEntries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: config.totalSteps,
        title: 'Advance health directive',
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
                      // ═══ Section 1: Views, Wishes & Preferences ═══
                      _buildSectionHeader(
                          'Your views, wishes and preferences'),
                      const SizedBox(height: 24),

                      Text('My major health conditions and concerns are',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _thingsImportantController,
                        label: 'Enter details',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'These are the cultural, religious or spiritual values, rituals or beliefs I would like considered in my health car',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _culturalValuesController,
                        label: 'Enter details',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'When I am nearing death, the following would be important to me and would comfort me: (e.g. you may prefer to die at home or you may like a certain type of music played)',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _nearingDeathComfortController,
                        label: 'Enter details',
                        isRequired: true,
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'I would prefer these people not be involved in discussions about my health care',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _peopleNotInvolvedController,
                        label: 'Enter details',
                        maxLines: 5,
                        minLines: 3,
                      ),

                      _buildSectionDivider(),

                      // ═══ Section 3: Directions ═══
                      _buildSectionHeader(
                          'Directions about life-sustaining treatment'),
                      const SizedBox(height: 24),

                      RadioListOption(
                        isSelected: _lifeSustainingDirective ==
                            LifeSustainingDirective.consentAll,
                        title:
                            'I consent to all treatments aimed at sustaining or prolonging my life',
                        onTap: () => setState(() =>
                            _lifeSustainingDirective =
                                LifeSustainingDirective.consentAll),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _lifeSustainingDirective ==
                            LifeSustainingDirective.refuseAll,
                        title:
                            'I refuse any treatments aimed at sustaining or prolonging my life',
                        onTap: () => setState(() =>
                            _lifeSustainingDirective =
                                LifeSustainingDirective.refuseAll),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _lifeSustainingDirective ==
                            LifeSustainingDirective.attorneyDecides,
                        title:
                            'I cannot decide at this point. I want my attorney(s) to make the decisions about life-sustaining treatment on my behalf at the time the decision needs to be made using the information in this advance health directive and in consultation with my health providers and the people I have listed in section 3.',
                        onTap: () => setState(() =>
                            _lifeSustainingDirective =
                                LifeSustainingDirective.attorneyDecides),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _lifeSustainingDirective ==
                            LifeSustainingDirective.enterDetails,
                        title:
                            'I give the following specific directions about life-sustaining treatments:',
                        onTap: () => setState(() =>
                            _lifeSustainingDirective =
                                LifeSustainingDirective.enterDetails),
                      ),

                      if (_lifeSustainingDirective ==
                          LifeSustainingDirective.enterDetails) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _directiveDetailsController,
                          label: 'Enter details',
                          maxLines: 4,
                          minLines: 3,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Per-treatment sections
                      _buildTreatmentSection(
                        title: 'Life-sustaining treatment',
                        selectedValue: _lifeSustainingTreatment,
                        detailsController: _lifeSustainingDetailsController,
                        onChanged: (v) =>
                            setState(() => _lifeSustainingTreatment = v),
                      ),
                      _buildTreatmentSection(
                        title: 'Assisted ventilation',
                        subtitle:
                            'e.g. a machine which assists your breathing through a face mask or a breathing tube',
                        selectedValue: _assistedVentilation,
                        detailsController:
                            _assistedVentilationDetailsController,
                        onChanged: (v) =>
                            setState(() => _assistedVentilation = v),
                      ),
                      _buildTreatmentSection(
                        title: 'Artificial nutrition',
                        subtitle:
                            'e.g. a machine which assists your breathing through a face mask or a breathing tube',
                        selectedValue: _artificialNutrition,
                        detailsController:
                            _artificialNutritionDetailsController,
                        onChanged: (v) =>
                            setState(() => _artificialNutrition = v),
                      ),
                      _buildTreatmentSection(
                        title: 'Artificial hydration',
                        subtitle: 'e.g. intravenous (IV) fluids',
                        selectedValue: _artificialHydration,
                        detailsController:
                            _artificialHydrationDetailsController,
                        onChanged: (v) =>
                            setState(() => _artificialHydration = v),
                      ),
                      _buildTreatmentSection(
                        title: 'Antibiotics',
                        selectedValue: _antibiotics,
                        detailsController: _antibioticsDetailsController,
                        onChanged: (v) =>
                            setState(() => _antibiotics = v),
                      ),
                      _buildTreatmentSection(
                        title: 'Other life-sustaining treatment',
                        selectedValue: _otherTreatment,
                        detailsController: _otherTreatmentDetailsController,
                        onChanged: (v) =>
                            setState(() => _otherTreatment = v),
                      ),

                      _buildSectionDivider(),

                      // ═══ Section 4: Other Healthcare Directions ═══
                      _buildSectionHeader('Directions about other healthcare'),
                      const SizedBox(height: 8),
                      Text(
                        'My major health conditions and concerns are',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),

                      // Health condition input at top
                      AppTextField(
                        controller: _otherHealthEntries.isNotEmpty
                            ? _otherHealthEntries.first.conditionController
                            : TextEditingController(),
                        label: 'Health condition',
                      ),
                      const SizedBox(height: 16),

                      for (int i = 0;
                          i < _otherHealthEntries.length;
                          i++) ...[
                        _buildOtherHealthCard(i),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _addHealthEntry,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.borderGray),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Add new Health condition',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),

                      _buildSectionDivider(),

                      // ═══ Section 5: Health Conditions ═══
                      _buildSectionHeader('Your health conditions and concerns'),
                      const SizedBox(height: 24),
                      AppTextArea(
                        controller: _healthConditionsController,
                        label: 'My major health conditions and concerns are',
                        isRequired: true,
                        maxLength: 4000,
                        maxLines: 8,
                        minLines: 4,
                      ),

                      _buildSectionDivider(),

                      // ═══ Section 6: Doctor Certificate ═══
                      _buildSectionHeader('Doctor certificate'),
                      const SizedBox(height: 24),

                      AppTextField(
                        controller: _doctorNameController,
                        label: "Doctor's name",
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _facilityNameController,
                        label: 'Name of facility or practice',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _doctorDobController,
                        label: 'DOB',
                        onDateSelected: (date) {
                          setState(() {
                            _doctorDobController.text =
                                AppDatePickerField.formatDate(date);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AppPhoneInput(
                        controller: _doctorPhoneController,
                        countryCode: _doctorCountryCode,
                        onCountryCodeChanged: (code) =>
                            setState(() => _doctorCountryCode = code),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _doctorSignController,
                        label: 'Doctors sign',
                        isRequired: true,
                      ),
                      const SizedBox(height: 24),

                      // Doctor address
                      Container(
                        height: 1,
                        color: AppColors.borderGray,
                      ),
                      const SizedBox(height: 24),
                      Text('Address', style: AppTextStyles.questionTitle),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _doctorAddressController,
                        label: 'Address',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _doctorSuburbController,
                        label: 'Suburb',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _doctorPostcodeController,
                        label: 'Postcode',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              value.trim().length != 4) {
                            return 'Postcode must be 4 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppDropdownFormField<String>(
                        value: 'Australia',
                        label: 'Country',
                        items: const ['Australia'],
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 16),

                      AppDropdownFormField<String>(
                        value: _doctorSelectedState,
                        label: 'State',
                        items: FormConstants.australianStateKeys,
                        displayName: (value) =>
                            FormConstants.getStateDisplayName(value),
                        onChanged: (value) {
                          setState(() => _doctorSelectedState = value);
                        },
                      ),

                      _buildSectionDivider(),

                      // ═══ Section 7: Appointing Attorneys ═══
                      _buildSectionHeader(
                          'Appointing an attorneys for health matters'),
                      const SizedBox(height: 24),

                      // Attorney selection area
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your selection will show up here',
                              style: AppTextStyles.instructionSmall,
                            ),
                            const SizedBox(height: 12),

                            // Select previously added row
                            InkWell(
                              onTap: () => _showSelectPreviousSheet(_attorneys),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.borderGray),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Select previously added',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Added attorneys list
                            if (_attorneys.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ..._attorneys.asMap().entries.map(
                                (entry) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: _AhdPersonCard(
                                    person: entry.value,
                                    onEdit: () =>
                                        _editAttorney(entry.key),
                                    onDelete: () =>
                                        _removeAttorney(entry.key),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            AppPrimaryButton(
                              text: '+ Add Attorney',
                              onPressed: _addAttorney,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Decision method
                      Text(
                        'How much your attorneys make decisions',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),

                      RadioListOption(
                        isSelected: _decisionMethod ==
                            AttorneyDecisionMethod.jointly,
                        title:
                            'Jointly (all of my attorneys must agree on all decisions)',
                        onTap: () => setState(() => _decisionMethod =
                            AttorneyDecisionMethod.jointly),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _decisionMethod ==
                            AttorneyDecisionMethod.severally,
                        title:
                            'Severally (any one of my attorneys may decide)',
                        onTap: () => setState(() => _decisionMethod =
                            AttorneyDecisionMethod.severally),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _decisionMethod ==
                            AttorneyDecisionMethod.majority,
                        title:
                            'By a majority (more than half of my attorneys must agree on all decisions)',
                        onTap: () => setState(() => _decisionMethod =
                            AttorneyDecisionMethod.majority),
                      ),
                      const SizedBox(height: 8),
                      RadioListOption(
                        isSelected: _decisionMethod ==
                            AttorneyDecisionMethod.other,
                        title: 'Other',
                        onTap: () => setState(() => _decisionMethod =
                            AttorneyDecisionMethod.other),
                      ),
                      if (_decisionMethod ==
                          AttorneyDecisionMethod.other) ...[
                        const SizedBox(height: 12),
                        AppTextArea(
                          controller: _decisionOtherController,
                          label: 'Enter details',
                          maxLines: 4,
                          minLines: 3,
                        ),
                      ],

                      _buildSectionDivider(),

                      // ═══ Section 8: Declaration ═══
                      _buildSectionHeader('Declaration and signatures'),
                      const SizedBox(height: 24),

                      AppTextArea(
                        controller: _declarationController,
                        label: 'Enter details',
                        maxLines: 8,
                        minLines: 4,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom bar
            AhdBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _hasMoreSteps ? _handleNext : _handleFinish,
              nextText: _hasMoreSteps ? 'Next step' : 'Finish',
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper builders ──

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTextStyles.pageTitle);
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

  Widget _buildTreatmentSection({
    required String title,
    String? subtitle,
    required String? selectedValue,
    required TextEditingController detailsController,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: AppColors.borderGray),
        const SizedBox(height: 20),
        Text(title, style: AppTextStyles.questionTitle),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.subtitle),
        ],
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: selectedValue == TreatmentChoice.consentAll,
          title: 'I consent to this treatment in all circumstances',
          onTap: () => onChanged(TreatmentChoice.consentAll),
        ),
        const SizedBox(height: 8),
        RadioListOption(
          isSelected: selectedValue == TreatmentChoice.refuseAll,
          title: 'I refuse this treatment in al circumstances',
          onTap: () => onChanged(TreatmentChoice.refuseAll),
        ),
        const SizedBox(height: 8),
        RadioListOption(
          isSelected:
              selectedValue == TreatmentChoice.consentCircumstances,
          title:
              'consent to this treatment in the following circumstances',
          onTap: () => onChanged(TreatmentChoice.consentCircumstances),
        ),
        if (selectedValue == TreatmentChoice.consentCircumstances) ...[
          const SizedBox(height: 12),
          AppTextArea(
            controller: detailsController,
            label: 'Enter details',
            maxLines: 4,
            minLines: 3,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtherHealthCard(int index) {
    final entry = _otherHealthEntries[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${index + 1}.  conditions and concerns',
                style: AppTextStyles.itemLabel,
              ),
              if (_otherHealthEntries.length > 1)
                GestureDetector(
                  onTap: () => _removeHealthEntry(index),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextArea(
            controller: entry.directionsController,
            label: 'Directions about my health care',
            maxLines: 4,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}

// ── Helper classes ──

class _HealthDirectionEntry {
  final TextEditingController conditionController;
  final TextEditingController directionsController;

  _HealthDirectionEntry({
    required this.conditionController,
    required this.directionsController,
  });
}

class _AhdPersonCard extends StatelessWidget {
  final AhdAttorneyData person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AhdPersonCard({
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundLightGreen,
            child: Text(
              person.initials,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.fullName, style: AppTextStyles.itemLabel),
                Text('Attorney', style: AppTextStyles.cardSecondary),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
