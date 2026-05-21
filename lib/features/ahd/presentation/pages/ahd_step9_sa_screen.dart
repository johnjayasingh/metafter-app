import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD South Australia Step 9 — Witnessing
///
/// API fields (in ahd_persons):
///   - WITNESS_PRIMARY: full_name
///   - WITNESS_AUTHORIZED: full_name, other.witness_category, phone
class AhdStep9SaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep9SaScreen({super.key, required this.flowData});

  @override
  State<AhdStep9SaScreen> createState() => _AhdStep9SaScreenState();
}

class _AhdStep9SaScreenState extends State<AhdStep9SaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Person giving directive
  late final TextEditingController _witnessFullNameController;
  late final TextEditingController _witnessPhoneController;
  String _witnessCountryCode = FormConstants.defaultCountryCode;

  // Authorised witness
  late final TextEditingController _authorisedWitnessFullNameController;
  String? _witnessCategory;
  late final TextEditingController _authorisedWitnessPhoneController;
  String _countryCode = FormConstants.defaultCountryCode;
  late final TextEditingController _extraExecutionStatementController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _witnessFullNameController =
        TextEditingController(text: d.saWitnessFullName ?? '');
    if (d.saWitnessPhone != null && d.saWitnessPhone!.isNotEmpty) {
      final (cc, local) = AppPhoneInput.parsePhoneNumber(d.saWitnessPhone!);
      _witnessCountryCode = cc;
      _witnessPhoneController = TextEditingController(text: local);
    } else {
      _witnessPhoneController = TextEditingController();
    }
    _authorisedWitnessFullNameController =
        TextEditingController(text: d.saAuthorisedWitnessFullName ?? '');
    _witnessCategory = d.saWitnessCategory;
    _authorisedWitnessPhoneController =
        TextEditingController(text: d.saAuthorisedWitnessPhone ?? '');
    _extraExecutionStatementController =
        TextEditingController(text: d.saExtraExecutionStatement ?? '');
  }

  @override
  void dispose() {
    _witnessFullNameController.dispose();
    _witnessPhoneController.dispose();
    _authorisedWitnessFullNameController.dispose();
    _authorisedWitnessPhoneController.dispose();
    _extraExecutionStatementController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      saWitnessFullName: _witnessFullNameController.text.trim(),
      saWitnessPhone: _witnessPhoneController.text.trim().isNotEmpty
          ? '$_witnessCountryCode${_witnessPhoneController.text.trim()}'
          : null,
      saAuthorisedWitnessFullName:
          _authorisedWitnessFullNameController.text.trim(),
      saWitnessCategory: _witnessCategory,
      saAuthorisedWitnessPhone:
          _authorisedWitnessPhoneController.text.trim(),
      saExtraExecutionStatement:
          _extraExecutionStatementController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(9), extra: updated);
    if (result != null) _returnedFromNext = result;
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
        title: 'Witnessing',
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
                      Text('Witnessing', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),

                      // Person giving directive
                      Text(
                        'Person giving this directive',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _witnessFullNameController,
                        label: 'Full name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppPhoneInput(
                        controller: _witnessPhoneController,
                        countryCode: _witnessCountryCode,
                        onCountryCodeChanged: (code) =>
                            setState(() => _witnessCountryCode = code),
                      ),

                      _buildSectionDivider(),

                      // Authorised witness
                      Text(
                        'Authorised witness',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _authorisedWitnessFullNameController,
                        label: 'Full name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppDropdownFormField<String>(
                        label: 'Witness category',
                        value: _witnessCategory,
                        isRequired: true,
                        items: SaWitnessCategory.all,
                        displayName: (v) =>
                            SaWitnessCategory.displayName(v),
                        onChanged: (v) =>
                            setState(() => _witnessCategory = v),
                      ),
                      const SizedBox(height: 16),
                      AppPhoneInput(
                        controller: _authorisedWitnessPhoneController,
                        countryCode: _countryCode,
                        onCountryCodeChanged: (code) {
                          setState(() => _countryCode = code);
                        },
                        label: 'Phone number',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _extraExecutionStatementController,
                        label: 'Extra execution statement',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
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

  Widget _buildSectionDivider() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(height: 1, color: AppColors.borderGray),
        const SizedBox(height: 32),
      ],
    );
  }
}
