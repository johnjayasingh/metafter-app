import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../widgets/poa_attorney_section.dart';
import '../widgets/poa_additional_powers_section.dart';
import '../widgets/poa_functions_limits_section.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../widgets/poa_directions_section.dart';

class PoaStep2Nsw extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep2Nsw({super.key, required this.flowData});

  @override
  State<PoaStep2Nsw> createState() => _PoaStep2NswState();
}

class _PoaStep2NswState extends State<PoaStep2Nsw> {
  late String _commencementType;
  late TextEditingController _commencementOtherController;
  late bool _hasViewsWishes;
  late TextEditingController _viewsWishesController;
  late bool _hasConditionsLimitations;
  late TextEditingController _conditionsLimitationsController;

  // (ci_* sub-fields removed — NSW uses single conditions/limitations toggle)

  // Attorney lists populated by PoaAttorneySection callbacks
  List<PoaPersonData> _attorneys = [];
  List<PoaPersonData> _successive = [];
  List<PoaPersonData> _guardians = [];
  List<PoaPersonData> _substitutes = [];

  // Additional powers (single-select)
  String? _selectedAdditionalPower;
  List<PoaPersonData> _benefitsPersons = [];

  // Functions and Limits (EG)
  late bool _egCanDecideLivingPlace;
  late bool _egCanDecideHealthcare;
  late TextEditingController _egHealthcareController;
  late bool _egCanDecideOtherPersonalService;
  late TextEditingController _egOtherPersonalServiceController;
  late bool _egCanConsentMedicalAndDental;
  late TextEditingController _egMedicalDetailController;
  late TextEditingController _egOtherDetailController;

  // Directions (EG)
  late bool _egHasDirections;
  late TextEditingController _egDirectionsController;

  @override
  void initState() {
    super.initState();
    _commencementType = widget.flowData.commencementType ?? 'INCAPACITY';
    _commencementOtherController =
        TextEditingController(text: widget.flowData.commencementOther ?? '');
    _hasViewsWishes = widget.flowData.hasViewsWishes ?? false;
    _viewsWishesController =
        TextEditingController(text: widget.flowData.viewsWishes ?? '');
    _hasConditionsLimitations =
        widget.flowData.hasConditionsLimitations ?? false;
    _conditionsLimitationsController = TextEditingController(
        text: widget.flowData.conditionsLimitations ?? '');

    // Additional powers
    _selectedAdditionalPower = widget.flowData.selectedAdditionalPower;
    _benefitsPersons = List.from(widget.flowData.benefitsPersons);

    // Functions and Limits
    _egCanDecideLivingPlace =
        widget.flowData.egCanDecideLivingPlace ?? false;
    _egCanDecideHealthcare =
        widget.flowData.egCanDecideHealthcare ?? false;
    _egHealthcareController =
        TextEditingController(text: widget.flowData.egHealthcareDetail ?? '');
    _egCanDecideOtherPersonalService =
        widget.flowData.egCanDecideOtherPersonalService ?? false;
    _egOtherPersonalServiceController = TextEditingController(
        text: widget.flowData.egOtherPersonalService ?? '');
    _egCanConsentMedicalAndDental =
        widget.flowData.egCanConsentMedicalAndDental ?? false;
    _egMedicalDetailController =
        TextEditingController(text: widget.flowData.egMedicalDetail ?? '');
    _egOtherDetailController =
        TextEditingController(text: widget.flowData.egOtherDetail ?? '');

    // Directions
    _egHasDirections = widget.flowData.egHasDirections ?? false;
    _egDirectionsController =
        TextEditingController(text: widget.flowData.egDirectionsDetail ?? '');
  }

  @override
  void dispose() {
    _commencementOtherController.dispose();
    _viewsWishesController.dispose();
    _conditionsLimitationsController.dispose();
    _egHealthcareController.dispose();
    _egOtherPersonalServiceController.dispose();
    _egMedicalDetailController.dispose();
    _egOtherDetailController.dispose();
    _egDirectionsController.dispose();
    super.dispose();
  }

  PoaFlowData _collectCurrentData() {
    return widget.flowData.copyWith(
      commencementType: _commencementType,
      commencementOther: _commencementType == 'OTHER'
          ? _commencementOtherController.text.trim()
          : null,
      hasViewsWishes: _hasViewsWishes,
      viewsWishes:
          _hasViewsWishes ? _viewsWishesController.text.trim() : null,
      hasConditionsLimitations: _hasConditionsLimitations,
      conditionsLimitations: _hasConditionsLimitations
          ? _conditionsLimitationsController.text.trim()
          : null,
      selectedAdditionalPower: _selectedAdditionalPower,
      benefitsPersons: _benefitsPersons,
      egCanDecideLivingPlace: _egCanDecideLivingPlace,
      egCanDecideHealthcare: _egCanDecideHealthcare,
      egHealthcareDetail: _egCanDecideHealthcare
          ? _egHealthcareController.text.trim()
          : null,
      egCanDecideOtherPersonalService: _egCanDecideOtherPersonalService,
      egOtherPersonalService: _egCanDecideOtherPersonalService
          ? _egOtherPersonalServiceController.text.trim()
          : null,
      egCanConsentMedicalAndDental: _egCanConsentMedicalAndDental,
      egMedicalDetail: _egCanConsentMedicalAndDental
          ? _egMedicalDetailController.text.trim()
          : null,
      egOtherDetail: _egOtherDetailController.text.trim().isNotEmpty
          ? _egOtherDetailController.text.trim()
          : null,
      egHasDirections: _egHasDirections,
      egDirectionsDetail: _egHasDirections
          ? _egDirectionsController.text.trim()
          : null,
    );
  }

  void _handleNext() {
    if (_attorneys.isEmpty) {
      SnackBarUtils.showError(context, 'Please add at least one attorney.');
      return;
    }
    if (_guardians.isEmpty) {
      SnackBarUtils.showError(context, 'Please add at least one enduring guardian.');
      return;
    }
    if (_hasViewsWishes && _viewsWishesController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your views and wishes or select No.');
      return;
    }
    if (_hasConditionsLimitations && _conditionsLimitationsController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter conditions and limitations or select No.');
      return;
    }
    if (_commencementType == 'OTHER' && _commencementOtherController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please specify the commencement details.');
      return;
    }
    if (_egHasDirections && _egDirectionsController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter directions or select No.');
      return;
    }

    final updated = _collectCurrentData();
    context.push(AppRouter.poaReviewNsw, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
          currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: config.totalSteps,
        title: 'Enduring power of attorney',
        enableDrawer: true,
        exitTitle: 'Exit power of attorney?',
        exitDescription:
            'Your progress will be lost. You can start a new power of attorney at any time.',
        exitDiscardButtonText: 'Exit POA',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 4),
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
                    // ── Attorney(s) section ──
                    const SizedBox(height: 32),
                    PoaAttorneySection(
                      type: AttorneyType.PRIMARY,
                      title: 'Attorney(s)',
                      addButtonText: '+ Add Attorney',
                      onChanged: (list) => setState(() => _attorneys = list),
                    ),

                    // ── Successive Attorney(s) section ──
                    const SizedBox(height: 32),
                    PoaAttorneySection(
                      type: AttorneyType.SUCCESSIVE,
                      title: 'Successive attorney(s)',
                      isOptional: true,
                      addButtonText: '+ Add Successive attorney',
                      onChanged: (list) => setState(() => _successive = list),
                    ),

                    // ── Additional Powers section ──
                    const SizedBox(height: 32),
                    PoaAdditionalPowersSection(
                      selectedPower: _selectedAdditionalPower,
                      onSelectedPowerChanged: (val) =>
                          setState(() => _selectedAdditionalPower = val),
                      onBenefitsPersonsChanged: (list) =>
                          _benefitsPersons = list,
                    ),

                    // ── Conditions and limitations (optional) ──
                    const SizedBox(height: 32),
                    Text('Conditions and limitations (optional)',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListOption(
                            isSelected: _hasConditionsLimitations,
                            title: 'Yes',
                            onTap: () => setState(
                                () => _hasConditionsLimitations = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioListOption(
                            isSelected: !_hasConditionsLimitations,
                            title: 'No',
                            onTap: () => setState(
                                () => _hasConditionsLimitations = false),
                          ),
                        ),
                      ],
                    ),
                    if (_hasConditionsLimitations) ...[
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _conditionsLimitationsController,
                        label: '',
                        placeholder: 'Enter conditions and limitations',
                        minLines: 4,
                        maxLines: 8,
                      ),
                    ],

                    // ── Enduring Guardian(s) section ──
                    const SizedBox(height: 32),
                    PoaAttorneySection(
                      type: AttorneyType.ENDURING_GUARDIAN,
                      title: 'Enduring Guardian(s)',
                      addButtonText: '+ Add Enduring Guardian',
                      onChanged: (list) => _guardians = list,
                    ),

                    // ── Substitute Enduring Guardian(s) section ──
                    const SizedBox(height: 32),
                    PoaAttorneySection(
                      type: AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN,
                      title: 'Substitute Enduring Guardian(s)',
                      isOptional: true,
                      addButtonText: '+ Add Substitute Enduring Guardian',
                      onChanged: (list) => _substitutes = list,
                    ),

                    // ── Functions and Limits section ──
                    const SizedBox(height: 32),
                    PoaFunctionsLimitsSection(
                      canDecideLivingPlace: _egCanDecideLivingPlace,
                      canDecideHealthcare: _egCanDecideHealthcare,
                      healthcareController: _egHealthcareController,
                      canDecideOtherPersonalService:
                          _egCanDecideOtherPersonalService,
                      otherPersonalServiceController:
                          _egOtherPersonalServiceController,
                      canConsentMedicalAndDental:
                          _egCanConsentMedicalAndDental,
                      medicalDetailController: _egMedicalDetailController,
                      otherDetailController: _egOtherDetailController,
                      onDecideLivingPlaceChanged: (val) =>
                          setState(() => _egCanDecideLivingPlace = val),
                      onDecideHealthcareChanged: (val) =>
                          setState(() => _egCanDecideHealthcare = val),
                      onDecideOtherPersonalServiceChanged: (val) => setState(
                          () => _egCanDecideOtherPersonalService = val),
                      onConsentMedicalAndDentalChanged: (val) => setState(
                          () => _egCanConsentMedicalAndDental = val),
                    ),

                    // ── Directions section ──
                    const SizedBox(height: 32),
                    PoaDirectionsSection(
                      hasDirections: _egHasDirections,
                      controller: _egDirectionsController,
                      onToggle: (val) =>
                          setState(() => _egHasDirections = val),
                    ),

                  ],
                ),
              ),
            ),
            PoaBottomBar(
              onPrevious: () => context.pop(_collectCurrentData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
