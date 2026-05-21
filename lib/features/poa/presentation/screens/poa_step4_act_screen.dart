import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaStep4Act extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep4Act({super.key, required this.flowData});

  @override
  State<PoaStep4Act> createState() => _PoaStep4ActState();
}

class _PoaStep4ActState extends State<PoaStep4Act> {
  final _formKey = GlobalKey<FormState>();

  // ── Directions per matter ──
  late TextEditingController _directionsPropertyController;
  late TextEditingController _directionsPersonalCareController;
  late TextEditingController _directionsHealthCareController;
  late TextEditingController _directionsMedicalResearchController;

  // ── Medical treatment refusal ──
  late String _medicalTreatmentRefusal;
  late TextEditingController _specificTreatmentsController;

  // ── Property commencement ──
  late String _propertyCommencement;
  late TextEditingController _commencementCircumstanceController;

  // ── Prior EPA ──
  late String _priorEpa;
  late TextEditingController _priorEpaContinueWhichController;
  late TextEditingController _priorEpaDateController;
  late TextEditingController _priorEpaAttorneyNameController;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;

    _directionsPropertyController =
        TextEditingController(text: fd.actDirectionsProperty ?? '');
    _directionsPersonalCareController =
        TextEditingController(text: fd.actDirectionsPersonalCare ?? '');
    _directionsHealthCareController =
        TextEditingController(text: fd.actDirectionsHealthCare ?? '');
    _directionsMedicalResearchController =
        TextEditingController(text: fd.actDirectionsMedicalResearch ?? '');

    _medicalTreatmentRefusal =
        fd.actMedicalTreatmentRefusal ?? 'NOT_ALLOWED';
    _specificTreatmentsController =
        TextEditingController(text: fd.actSpecificTreatments ?? '');

    _propertyCommencement =
        fd.actPropertyCommencement ?? 'IMMEDIATELY';
    _commencementCircumstanceController =
        TextEditingController(text: fd.actCommencementCircumstance ?? '');

    _priorEpa = fd.actPriorEpa ?? 'NONE';
    _priorEpaContinueWhichController =
        TextEditingController(text: fd.actPriorEpaContinueWhich ?? '');
    _priorEpaDateController =
        TextEditingController(text: fd.actPriorEpaDate ?? '');
    _priorEpaAttorneyNameController =
        TextEditingController(text: fd.actPriorEpaAttorneyName ?? '');
  }

  @override
  void dispose() {
    _directionsPropertyController.dispose();
    _directionsPersonalCareController.dispose();
    _directionsHealthCareController.dispose();
    _directionsMedicalResearchController.dispose();
    _specificTreatmentsController.dispose();
    _commencementCircumstanceController.dispose();
    _priorEpaContinueWhichController.dispose();
    _priorEpaDateController.dispose();
    _priorEpaAttorneyNameController.dispose();
    super.dispose();
  }

  List<String> get _selectedMatters => widget.flowData.actMatters;

  PoaFlowData _collectCurrentData() {
    return widget.flowData.copyWith(
      actDirectionsProperty: _selectedMatters.contains('PROPERTY')
          ? _directionsPropertyController.text.trim()
          : null,
      actDirectionsPersonalCare: _selectedMatters.contains('PERSONAL_CARE')
          ? _directionsPersonalCareController.text.trim()
          : null,
      actDirectionsHealthCare: _selectedMatters.contains('HEALTH_CARE')
          ? _directionsHealthCareController.text.trim()
          : null,
      actDirectionsMedicalResearch:
          _selectedMatters.contains('MEDICAL_RESEARCH')
              ? _directionsMedicalResearchController.text.trim()
              : null,
      actMedicalTreatmentRefusal: _selectedMatters.contains('HEALTH_CARE')
          ? _medicalTreatmentRefusal
          : null,
      actSpecificTreatments:
          _medicalTreatmentRefusal == 'ALLOWED_SPECIFIC' &&
                  _selectedMatters.contains('HEALTH_CARE')
              ? _specificTreatmentsController.text.trim()
              : null,
      actPropertyCommencement: _selectedMatters.contains('PROPERTY')
          ? _propertyCommencement
          : null,
      actCommencementCircumstance: _selectedMatters.contains('PROPERTY')
          ? _commencementCircumstanceController.text.trim()
          : null,
      actPriorEpa: _priorEpa,
      actPriorEpaContinueWhich: _priorEpa == 'SOME_CONTINUE'
          ? _priorEpaContinueWhichController.text.trim()
          : null,
      actPriorEpaDate: _priorEpa != 'NONE'
          ? _priorEpaDateController.text.trim()
          : null,
      actPriorEpaAttorneyName: _priorEpa != 'NONE'
          ? _priorEpaAttorneyNameController.text.trim()
          : null,
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMatters.contains('HEALTH_CARE') &&
        _medicalTreatmentRefusal == 'ALLOWED_SPECIFIC' &&
        _specificTreatmentsController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please identify the specific treatments.');
      return;
    }
    if (_priorEpa != 'NONE' && _priorEpaDateController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter the date of the prior EPA.');
      return;
    }
    if (_priorEpa != 'NONE' && _priorEpaAttorneyNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter the attorney name for the prior EPA.');
      return;
    }
    if (_priorEpa == 'SOME_CONTINUE' &&
        _priorEpaContinueWhichController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please identify which Powers of Attorney will continue.');
      return;
    }

    final config = PoaFlowConfig.forState(widget.flowData.state);
    final updated = _collectCurrentData();
    await context.push<PoaFlowData>(config.nextRoute(4), extra: updated);
  }

  void _handlePrevious() {
    context.pop(_collectCurrentData());
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
          currentStep: 4, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 4,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDirectionsSection(),
                      if (_selectedMatters.contains('HEALTH_CARE')) ...[
                        const SizedBox(height: 32),
                        _buildMedicalTreatmentSection(),
                      ],
                      if (_selectedMatters.contains('PROPERTY')) ...[
                        const SizedBox(height: 32),
                        _buildCommencementSection(),
                      ],
                      const SizedBox(height: 32),
                      _buildPriorEpaSection(),
                    ],
                  ),
                ),
              ),
            ),
            PoaBottomBar(
              onPrevious: _handlePrevious,
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }

  // ── Directions / limits / conditions section ───────────────────────────────

  Widget _buildDirectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            Text('Directions / limits / conditions ',
                style: AppTextStyles.pageTitle),
            Text('(optional, per matter)',
                style: AppTextStyles.pageTitle
                    .copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
        if (_selectedMatters.contains('PROPERTY')) ...[
          const SizedBox(height: 20),
          Text('Please identify any specific directions for Property',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          AppTextArea(
            controller: _directionsPropertyController,
            label: 'Property directions',
            placeholder: 'Enter directions for Property',
            minLines: 3,
            maxLines: 6,
          ),
        ],
        if (_selectedMatters.contains('PERSONAL_CARE')) ...[
          const SizedBox(height: 20),
          Text('Please identify any specific directions for Personal Care',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          AppTextArea(
            controller: _directionsPersonalCareController,
            label: 'Personal care directions',
            placeholder: 'Enter directions for Personal Care',
            minLines: 3,
            maxLines: 6,
          ),
        ],
        if (_selectedMatters.contains('HEALTH_CARE')) ...[
          const SizedBox(height: 20),
          Text('Please identify any specific directions for Health Care',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          AppTextArea(
            controller: _directionsHealthCareController,
            label: 'Health care directions',
            placeholder: 'Enter directions for Health Care',
            minLines: 3,
            maxLines: 6,
          ),
        ],
        if (_selectedMatters.contains('MEDICAL_RESEARCH')) ...[
          const SizedBox(height: 20),
          Text(
              'Please identify any specific directions for Medical Research',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          AppTextArea(
            controller: _directionsMedicalResearchController,
            label: 'Medical research directions',
            placeholder: 'Enter directions for Medical Research',
            minLines: 3,
            maxLines: 6,
          ),
        ],
      ],
    );
  }

  // ── Medical treatment refusal section ──────────────────────────────────────

  Widget _buildMedicalTreatmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Refusal / withdrawal of medical treatment',
            style: AppTextStyles.pageTitle),
        const SizedBox(height: 8),
        Text(
            'Would you allow the refusal or withdrawal of medical treatment?',
            style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        RadioListOption(
          isSelected: _medicalTreatmentRefusal == 'NOT_ALLOWED',
          title: 'Not allowed',
          onTap: () => setState(
              () => _medicalTreatmentRefusal = 'NOT_ALLOWED'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _medicalTreatmentRefusal == 'ALLOWED_GENERALLY',
          title: 'Allowed generally',
          onTap: () => setState(
              () => _medicalTreatmentRefusal = 'ALLOWED_GENERALLY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _medicalTreatmentRefusal == 'ALLOWED_SPECIFIC',
          title: 'Allowed specific',
          onTap: () => setState(
              () => _medicalTreatmentRefusal = 'ALLOWED_SPECIFIC'),
        ),
        if (_medicalTreatmentRefusal == 'ALLOWED_SPECIFIC') ...[
          const SizedBox(height: 16),
          Text('Please identify any specific treatments',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          AppTextArea(
            controller: _specificTreatmentsController,
            label: 'Specific treatments',
            placeholder: 'Enter details',
            isRequired: true,
            minLines: 4,
            maxLines: 8,
          ),
        ],
      ],
    );
  }

  // ── Property commencement section ──────────────────────────────────────────

  Widget _buildCommencementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commencement of property powers',
            style: AppTextStyles.pageTitle),
        const SizedBox(height: 8),
        Text(
            'When would you like your attorney\'s powers over property to commence?',
            style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        RadioListOption(
          isSelected: _propertyCommencement == 'IMMEDIATELY',
          title: 'Immediately',
          onTap: () =>
              setState(() => _propertyCommencement = 'IMMEDIATELY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _propertyCommencement == 'FROM_DATE_EVENT',
          title: 'From date or event',
          onTap: () => setState(
              () => _propertyCommencement = 'FROM_DATE_EVENT'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _propertyCommencement == 'IMPAIRED_CAPACITY',
          title: 'Only when impaired capacity',
          onTap: () => setState(
              () => _propertyCommencement = 'IMPAIRED_CAPACITY'),
        ),
        const SizedBox(height: 16),
        Text(
            'Please identify the specific circumstance for commencement',
            style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        AppTextArea(
          controller: _commencementCircumstanceController,
          label: 'Commencement circumstance',
          placeholder: 'Enter details',
          minLines: 4,
          maxLines: 8,
        ),
      ],
    );
  }

  // ── Prior EPA section ──────────────────────────────────────────────────────

  Widget _buildPriorEpaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Do you have a prior Enduring Power of Attorney?',
            style: AppTextStyles.pageTitle),
        const SizedBox(height: 16),
        RadioListOption(
          isSelected: _priorEpa == 'NONE',
          title: 'None previous',
          onTap: () => setState(() => _priorEpa = 'NONE'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _priorEpa == 'REVOKE_ALL_PREVIOUS',
          title: 'Revoke all previous',
          onTap: () => setState(() => _priorEpa = 'REVOKE_ALL_PREVIOUS'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _priorEpa == 'SOME_CONTINUE',
          title: 'Some continue',
          onTap: () => setState(() => _priorEpa = 'SOME_CONTINUE'),
        ),
        if (_priorEpa == 'SOME_CONTINUE') ...[
          const SizedBox(height: 16),
          Text(
              'Please identify which Powers of Attorney will continue',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          AppTextArea(
            controller: _priorEpaContinueWhichController,
            label: 'Continuing EPAs',
            placeholder: 'Enter details',
            isRequired: true,
            minLines: 3,
            maxLines: 6,
          ),
        ],
        if (_priorEpa != 'NONE') ...[
          const SizedBox(height: 16),
          AppDatePickerField(
            controller: _priorEpaDateController,
            label: 'Date',
            isRequired: true,
            onDateSelected: (date) {
              _priorEpaDateController.text =
                  AppDatePickerField.formatDate(date);
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _priorEpaAttorneyNameController,
            label: 'Attorney name',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter the attorney name'
                : null,
          ),
        ],
      ],
    );
  }
}
