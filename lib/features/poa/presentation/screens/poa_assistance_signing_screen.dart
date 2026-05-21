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
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaAssistanceSigningScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaAssistanceSigningScreen({super.key, required this.flowData});

  @override
  State<PoaAssistanceSigningScreen> createState() =>
      _PoaAssistanceSigningScreenState();
}

class _PoaAssistanceSigningScreenState
    extends State<PoaAssistanceSigningScreen> {
  late bool _needsAssistance;
  bool _isSubmitting = false;
  bool _isLoadingAssistant = true;
  final PoaService _poaService = PoaService();

  // Inline person form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;
  String _countryCode = FormConstants.defaultCountryCode;

  // Existing backend record (if any)
  PoaPersonData? _existingAssistant;

  @override
  void initState() {
    super.initState();
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
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

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

  Future<void> _handleFinish() async {
    final finalData = widget.flowData.copyWith(
      needsSigningAssistance: _needsAssistance,
    );

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

        final assistantResponse = _existingAssistant?.attorneyId != null
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

      // Save NT financial decision makers via attorney endpoint
      if (finalData.state?.toLowerCase() == 'northern_territory' && finalData.ntFinancialDms.isNotEmpty) {
        const dmTypes = [
          AttorneyType.FINANCIAL_DECISION_MAKER_PRIMARY,
          AttorneyType.FINANCIAL_DECISION_MAKER_SECONDARY,
          AttorneyType.FINANCIAL_DECISION_MAKER_TERTIARY,
          AttorneyType.FINANCIAL_DECISION_MAKER_QUATERNARY,
        ];
        // Delete existing DMs to avoid duplicates on re-save
        for (final t in dmTypes) {
          await _poaService.deleteAttorneysByType(t);
        }
        for (int i = 0; i < finalData.ntFinancialDms.length && i < dmTypes.length; i++) {
          final dm = finalData.ntFinancialDms[i];
          if (dm.name.trim().isEmpty) continue;
          final (first, middle, last) = PoaPersonData.parseFullName(dm.name.trim());
          final dmPerson = PoaPersonData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            firstName: first,
            middleName: middle,
            lastName: last,
            address: dm.address.trim(),
            attorneyType: dmTypes[i],
            role: 'Financial Decision Maker',
          );
          final dmResponse = await _poaService.createAttorneyForPoa(
            dmPerson,
            type: dmTypes[i],
          );
          if (!mounted) return;
          if (dmResponse.isFailure) {
            setState(() => _isSubmitting = false);
            SnackBarUtils.showError(
              context,
              'Failed to save decision maker ${i + 1}.',
            );
            return;
          }
        }
      }

      // VIC medical treatment decision maker is now saved directly by
      // PoaAttorneySection on Step 2 — no manual save needed here.

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

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final signingStep = config.totalSteps;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: signingStep, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: signingStep,
        totalSteps: config.totalSteps,
        title: 'Assistance & Signing',
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

                            // Yes / No
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
                                    onTap: () => setState(
                                        () => _needsAssistance = false),
                                  ),
                                ),
                              ],
                            ),

                            // Inline person form when "Yes" is selected
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
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Finish',
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
