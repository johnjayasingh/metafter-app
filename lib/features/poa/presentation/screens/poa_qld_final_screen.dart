import 'package:flutter/material.dart';
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
import '../../data/models/poa_models.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaQldFinalScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaQldFinalScreen({super.key, required this.flowData});

  @override
  State<PoaQldFinalScreen> createState() => _PoaQldFinalScreenState();
}

class _PoaQldFinalScreenState extends State<PoaQldFinalScreen> {
  final PoaService _poaService = PoaService();
  bool _isSubmitting = false;
  bool _isLoadingAssistant = true;

  // ── Notification (health) ──
  late String _notifyWho;
  late TextEditingController _instructionsController;
  late List<PoaPersonData> _notifyPersons;
  late String? _notifyWhatOption;
  late TextEditingController _notifyOtherController;
  List<RecipientInfo> _previousPeople = [];

  // ── Notification (financial) ──
  late String _finNotifyWho;
  late TextEditingController _finInstructionsController;
  late List<PoaPersonData> _finNotifyPersons;
  late String? _finNotifyWhatOption;
  late TextEditingController _finNotifyOtherController;

  // ── Signing assistance ──
  late bool _needsAssistance;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;
  String _countryCode = FormConstants.defaultCountryCode;
  PoaPersonData? _existingAssistant;

  @override
  void initState() {
    super.initState();

    // Notification (health)
    _notifyWho = widget.flowData.notifyWho ?? 'ME';
    _instructionsController =
        TextEditingController(text: widget.flowData.notifyInstructions ?? '');
    _notifyPersons = List<PoaPersonData>.from(widget.flowData.notifyPersons);
    _notifyWhatOption = widget.flowData.notifyWhatOption;
    _notifyOtherController =
        TextEditingController(text: widget.flowData.notifyWhatOtherText ?? '');

    // Notification (financial)
    _finNotifyWho = widget.flowData.financialNotifyWho ?? 'ME';
    _finInstructionsController =
        TextEditingController(text: widget.flowData.financialNotifyInstructions ?? '');
    _finNotifyPersons = List<PoaPersonData>.from(widget.flowData.financialNotifyPersons);
    _finNotifyWhatOption = widget.flowData.financialNotifyWhatOption;
    _finNotifyOtherController =
        TextEditingController(text: widget.flowData.financialNotifyWhatOtherText ?? '');

    _loadPreviousPeople();

    // Signing assistance
    _needsAssistance = widget.flowData.needsSigningAssistance ?? true;
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _loadExistingAssistant();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _notifyOtherController.dispose();
    _finInstructionsController.dispose();
    _finNotifyOtherController.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  // ── Notification data loading ──────────────────────────────────────────────

  Future<void> _loadPreviousPeople() async {
    final persons = await _poaService.getWillPeople();
    if (!mounted) return;
    setState(() {
      _previousPeople = persons
          .where((p) =>
              (p['first_name'] != null || p['full_name'] != null))
          .map((p) {
            final firstName = p['first_name'] as String? ?? '';
            final middleName = p['middle_name'] as String?;
            final lastName = p['last_name'] as String? ?? '';
            return RecipientInfo(
              id: p['id']?.toString() ?? '',
              firstName: firstName,
              middleName: middleName,
              lastName: lastName,
              email: p['email'] as String?,
              mobile: p['phone'] as String?,
              address: p['address'] as String?,
            );
          })
          .toList();
    });
  }

  Future<void> _showSelectPersonSheet() async {
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
      setState(() {
        _notifyPersons.add(PoaPersonData(
          id: selected.id,
          firstName: selected.firstName,
          middleName: selected.middleName,
          lastName: selected.lastName,
          role: 'Contact',
          email: selected.email,
          phone: selected.mobile,
          address: selected.address,
        ));
      });
    }
  }

  Future<void> _addPerson() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: PoaPersonData(
        id: '',
        firstName: '',
        lastName: '',
        role: 'Contact',
      ),
    );
    if (result != null) {
      setState(() {
        _notifyPersons.add(
          PoaPersonData(
            id: result.id,
            firstName: result.firstName,
            middleName: result.middleName,
            lastName: result.lastName,
            role: 'Contact',
            email: result.email,
            phone: result.phone,
          ),
        );
      });
    }
  }

  void _removePerson(int index) {
    setState(() {
      _notifyPersons.removeAt(index);
    });
  }

  // ── Financial notification person management ──

  Future<void> _showFinSelectPersonSheet() async {
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
      setState(() {
        _finNotifyPersons.add(PoaPersonData(
          id: selected.id,
          firstName: selected.firstName,
          middleName: selected.middleName,
          lastName: selected.lastName,
          role: 'Contact',
          email: selected.email,
          phone: selected.mobile,
          address: selected.address,
        ));
      });
    }
  }

  Future<void> _addFinPerson() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: PoaPersonData(
        id: '',
        firstName: '',
        lastName: '',
        role: 'Contact',
      ),
    );
    if (result != null) {
      setState(() {
        _finNotifyPersons.add(
          PoaPersonData(
            id: result.id,
            firstName: result.firstName,
            middleName: result.middleName,
            lastName: result.lastName,
            role: 'Contact',
            email: result.email,
            phone: result.phone,
          ),
        );
      });
    }
  }

  void _removeFinPerson(int index) {
    setState(() {
      _finNotifyPersons.removeAt(index);
    });
  }

  // ── Signing assistance data loading ────────────────────────────────────────

  Future<void> _loadExistingAssistant() async {
    final assistants =
        await _poaService.getAttorneysByType(AttorneyType.PERSONAL_ASSISTANCE);
    if (!mounted) return;
    if (assistants.isNotEmpty) {
      final a = assistants.first;
      _existingAssistant = a;
      _firstName.text = a.firstName;
      _lastName.text = a.lastName;
      _email.text = a.email ?? '';
      _address.text = a.address ?? '';
      if (a.phone != null && a.phone!.isNotEmpty) {
        final (cc, local) = AppPhoneInput.parsePhoneNumber(a.phone!);
        _countryCode = cc;
        _phone.text = local;
      }
      _needsAssistance = true;
    }
    setState(() => _isLoadingAssistant = false);
  }

  PoaFlowData _collectCurrentData() {
    final healthNotifyOf = _notifyWhatOption ?? 'WRITTEN_NOTICE';
    final finNotifyOf = _finNotifyWhatOption ?? 'WRITTEN_NOTICE';
    return widget.flowData.copyWith(
      notifyWho: _notifyWho,
      notifyInstructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      notifyPersons: List.from(_notifyPersons),
      notifyWhatOption: healthNotifyOf,
      notifyWhatOtherText: healthNotifyOf == 'OTHER'
          ? _notifyOtherController.text.trim()
          : null,
      financialNotifyWho: _finNotifyWho,
      financialNotifyInstructions:
          _finInstructionsController.text.trim().isNotEmpty
              ? _finInstructionsController.text.trim()
              : null,
      financialNotifyPersons: List.from(_finNotifyPersons),
      financialNotifyWhatOption: finNotifyOf,
      financialNotifyWhatOtherText: finNotifyOf == 'OTHER'
          ? _finNotifyOtherController.text.trim()
          : null,
      needsSigningAssistance: _needsAssistance,
    );
  }

  // ── Finish ─────────────────────────────────────────────────────────────────

  Future<void> _handleFinish() async {
    final hasHealth = widget.flowData.matters.contains('PERSONAL_HEALTH');

    // Default to WRITTEN_NOTICE if user hasn't selected a notify option
    final healthNotifyOf = _notifyWhatOption ?? 'WRITTEN_NOTICE';
    final finNotifyOf = _finNotifyWhatOption ?? 'WRITTEN_NOTICE';

    // Only one section is shown at a time (health OR financial).
    // Build finalData using whichever section is active.
    final PoaFlowData finalData;
    if (hasHealth) {
      finalData = widget.flowData.copyWith(
        notifyWho: _notifyWho,
        notifyInstructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        notifyPersons: List.from(_notifyPersons),
        notifyWhatOption: healthNotifyOf,
        notifyWhatOtherText: healthNotifyOf == 'OTHER'
            ? _notifyOtherController.text.trim()
            : null,
        needsSigningAssistance: _needsAssistance,
      );
    } else {
      finalData = widget.flowData.copyWith(
        financialNotifyWho: _finNotifyWho,
        financialNotifyInstructions: _finInstructionsController.text.trim().isNotEmpty
            ? _finInstructionsController.text.trim()
            : null,
        financialNotifyPersons: List.from(_finNotifyPersons),
        financialNotifyWhatOption: finNotifyOf,
        financialNotifyWhatOtherText: finNotifyOf == 'OTHER'
            ? _finNotifyOtherController.text.trim()
            : null,
        needsSigningAssistance: _needsAssistance,
      );
    }

    if (_needsAssistance) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Save or update the PERSONAL_ASSISTANCE person if needed
      if (_needsAssistance) {
        final fullPhone = _phone.text.trim().isNotEmpty
            ? '$_countryCode${_phone.text.trim()}'
            : null;

        final person = PoaPersonData(
          id: _existingAssistant?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
          phone: fullPhone,
          address:
              _address.text.trim().isNotEmpty ? _address.text.trim() : null,
          attorneyId: _existingAssistant?.attorneyId,
          attorneyPoaId: _existingAssistant?.attorneyPoaId,
          attorneyType: AttorneyType.PERSONAL_ASSISTANCE,
          role: 'Personal Assistance',
        );

        final assistantResponse = _existingAssistant?.attorneyPoaId != null
            ? await _poaService.updateAttorneyForPoa(
                person,
                type: AttorneyType.PERSONAL_ASSISTANCE,
              )
            : await _poaService.createAttorneyForPoa(
                person,
                type: AttorneyType.PERSONAL_ASSISTANCE,
              );

        if (!mounted) return;
        if (assistantResponse.isFailure) {
          setState(() => _isSubmitting = false);
          SnackBarUtils.showError(
            context,
            assistantResponse.message.isNotEmpty
                ? assistantResponse.message
                : 'Failed to save signing assistance person.',
          );
          return;
        }
      }

      // Remove old MEDICAL_DECISION_MAKER attorneys before creating fresh ones
      // to avoid duplicates on re-save.
      await _poaService.deleteAttorneysByType(AttorneyType.MEDICAL_DECISION_MAKER);

      // Collect unique notification persons (deduplicate by email)
      final allNotifyPersons = <String, PoaPersonData>{};
      for (final person in _notifyPersons) {
        final key = person.email ?? person.fullName;
        allNotifyPersons[key] = person;
      }
      for (final person in _finNotifyPersons) {
        final key = person.email ?? person.fullName;
        allNotifyPersons[key] = person;
      }

      // Save notification persons as MEDICAL_DECISION_MAKER attorneys
      // so the web app can read them via getAttorneysForPOA.
      for (final person in allNotifyPersons.values) {
        await _poaService.createAttorneyForPoa(
          PoaPersonData(
            id: person.id,
            firstName: person.firstName,
            middleName: person.middleName,
            lastName: person.lastName,
            role: 'Contact',
            email: person.email,
            phone: person.phone,
            address: person.address,
            attorneyType: AttorneyType.MEDICAL_DECISION_MAKER,
          ),
          type: AttorneyType.MEDICAL_DECISION_MAKER,
        );
      }

      // Save the overall POA
      final result = await _poaService.createOrUpdatePoa(finalData);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.isSuccess) {
        SnackBarUtils.showSuccess(
          context,
          'Power of attorney created successfully.',
        );
        context.go(AppRouter.home, extra: 4);
      } else {
        SnackBarUtils.showError(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to save power of attorney. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackBarUtils.showError(
        context,
        'An error occurred. Please try again.',
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasHealth = widget.flowData.matters.contains('PERSONAL_HEALTH');
    final hasFinancial = widget.flowData.matters.contains('FINANCIAL');
    final notifTitle = hasHealth
        ? 'Notification for health matters'
        : 'Notification for financial matters';

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: 3,
        title: notifTitle,
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
              child: _isLoadingAssistant
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Health notification section (when health matters selected) ──
                            if (hasHealth) ...[
                            Text(
                              'Notification for including health matters',
                              style: AppTextStyles.pageTitle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Who would you like to notify?',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: RadioButtonOption(
                                    isSelected: _notifyWho == 'ME',
                                    label: 'Me',
                                    onTap: () =>
                                        setState(() => _notifyWho = 'ME'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RadioButtonOption(
                                    isSelected: _notifyWho == 'NOMINATED_PERSON',
                                    label: 'Nominated person',
                                    onTap: () =>
                                        setState(() => _notifyWho = 'NOMINATED_PERSON'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            AppTextArea(
                              controller: _instructionsController,
                              label: '',
                              placeholder: 'Enter your instructions',
                              minLines: 6,
                              maxLines: 10,
                            ),
                            const SizedBox(height: 20),

                            // Persons selection card
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
                                  InkWell(
                                    onTap: _showSelectPersonSheet,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            Border.all(color: AppColors.borderGray),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Select previously added',
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                          const Icon(Icons.arrow_forward_ios,
                                              size: 16,
                                              color: AppColors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_notifyPersons.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    ..._notifyPersons.asMap().entries.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _NotifyPersonCard(
                                          person: entry.value,
                                          onDelete: () => _removePerson(entry.key),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  AppPrimaryButton(
                                    text: '+ Add persons',
                                    onPressed: _addPerson,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // What do you want to notify section
                            Text(
                              'What do you want to notify?',
                              style: AppTextStyles.questionTitle,
                            ),
                            const SizedBox(height: 16),

                            RadioListOption(
                              isSelected: _notifyWhatOption == 'WRITTEN_NOTICE',
                              title: 'Written notice of intention',
                              onTap: () =>
                                  setState(() => _notifyWhatOption = 'WRITTEN_NOTICE'),
                            ),
                            const SizedBox(height: 12),
                            RadioListOption(
                              isSelected: _notifyWhatOption == 'OTHER',
                              title: 'Other',
                              onTap: () =>
                                  setState(() => _notifyWhatOption = 'OTHER'),
                            ),
                            if (_notifyWhatOption == 'OTHER') ...[
                              const SizedBox(height: 16),
                              AppTextArea(
                                controller: _notifyOtherController,
                                label: '',
                                placeholder: 'Please specify',
                                minLines: 3,
                                maxLines: 6,
                              ),
                            ],

                            ], // end health notification section

                            // ── Financial notification section (only when no health matters) ──
                            if (!hasHealth && hasFinancial) ...[
                              const SizedBox(height: 32),
                              Text(
                                'Notifications for financial matters',
                                style: AppTextStyles.pageTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Who would you like to notify?',
                                style: AppTextStyles.subtitle,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: RadioButtonOption(
                                      isSelected: _finNotifyWho == 'ME',
                                      label: 'Me',
                                      onTap: () =>
                                          setState(() => _finNotifyWho = 'ME'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RadioButtonOption(
                                      isSelected: _finNotifyWho == 'NOMINATED_PERSON',
                                      label: 'Nominated person',
                                      onTap: () =>
                                          setState(() => _finNotifyWho = 'NOMINATED_PERSON'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              AppTextArea(
                                controller: _finInstructionsController,
                                label: '',
                                placeholder: 'Enter your instructions',
                                minLines: 6,
                                maxLines: 10,
                              ),
                              const SizedBox(height: 20),

                              // Persons selection card
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
                                    InkWell(
                                      onTap: _showFinSelectPersonSheet,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border:
                                              Border.all(color: AppColors.borderGray),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Select previously added',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                            const Icon(Icons.arrow_forward_ios,
                                                size: 16,
                                                color: AppColors.textSecondary),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_finNotifyPersons.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      ..._finNotifyPersons.asMap().entries.map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: _NotifyPersonCard(
                                            person: entry.value,
                                            onDelete: () => _removeFinPerson(entry.key),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    AppPrimaryButton(
                                      text: '+ Add persons',
                                      onPressed: _addFinPerson,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // What do you want to notify section
                              Text(
                                'What do you want to notify?',
                                style: AppTextStyles.questionTitle,
                              ),
                              const SizedBox(height: 16),

                              RadioListOption(
                                isSelected: _finNotifyWhatOption == 'WRITTEN_NOTICE',
                                title: 'Written notice of intention',
                                onTap: () =>
                                    setState(() => _finNotifyWhatOption = 'WRITTEN_NOTICE'),
                              ),
                              const SizedBox(height: 12),
                              RadioListOption(
                                isSelected: _finNotifyWhatOption == 'OTHER',
                                title: 'Other',
                                onTap: () =>
                                    setState(() => _finNotifyWhatOption = 'OTHER'),
                              ),
                              if (_finNotifyWhatOption == 'OTHER') ...[
                                const SizedBox(height: 16),
                                AppTextArea(
                                  controller: _finNotifyOtherController,
                                  label: '',
                                  placeholder: 'Please specify',
                                  minLines: 3,
                                  maxLines: 6,
                                ),
                              ],
                            ],

                            // ── Signing assistance section ──
                            const SizedBox(height: 32),
                            Text(
                              'Assistance with signing',
                              style: AppTextStyles.pageTitle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Do you need another person to sign on your behalf as you are physically unable to sign the document yourself?',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: RadioButtonOption(
                                    isSelected: _needsAssistance,
                                    label: 'Yes',
                                    onTap: () =>
                                        setState(() => _needsAssistance = true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RadioButtonOption(
                                    isSelected: !_needsAssistance,
                                    label: 'No',
                                    onTap: () =>
                                        setState(() => _needsAssistance = false),
                                  ),
                                ),
                              ],
                            ),

                            if (_needsAssistance) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLightGreen,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Person assisting with signing',
                                      style: AppTextStyles.questionTitle,
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: _firstName,
                                      label: 'First name *',
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Please enter first name'
                                              : null,
                                    ),
                                    const SizedBox(height: 12),
                                    AppTextField(
                                      controller: _lastName,
                                      label: 'Last name *',
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Please enter last name'
                                              : null,
                                    ),
                                    const SizedBox(height: 12),
                                    AppEmailField(
                                      controller: _email,
                                      label: 'Email address (optional)',
                                      isRequired: false,
                                    ),
                                    const SizedBox(height: 12),
                                    AppPhoneInput(
                                      controller: _phone,
                                      countryCode: _countryCode,
                                      onCountryCodeChanged: (code) =>
                                          setState(() => _countryCode = code),
                                      label: 'Mobile number (optional)',
                                    ),
                                    const SizedBox(height: 12),
                                    AppTextField(
                                      controller: _address,
                                      label: 'Address (optional)',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: () => context.pop(_collectCurrentData()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Save & Download',
                        onPressed: _isSubmitting ? null : _handleFinish,
                        isLoading: _isSubmitting,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notify person card ──────────────────────────────────────────────────────

class _NotifyPersonCard extends StatelessWidget {
  final PoaPersonData person;
  final VoidCallback onDelete;

  const _NotifyPersonCard({required this.person, required this.onDelete});

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
                Text(person.role, style: AppTextStyles.cardSecondary),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline,
                  size: 20, color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
