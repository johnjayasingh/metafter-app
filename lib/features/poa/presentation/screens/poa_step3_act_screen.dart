import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

/// Controller group for a single ACT attorney card.
class _ActAttorneyControllers {
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController address;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController dob;
  bool isCorporation;
  String? corporationType; // 'PUBLIC_TRUSTEE', 'TRUSTEE_COMPANY', 'OTHERS'
  bool isBankrupt;

  _ActAttorneyControllers({
    String? firstName,
    String? lastName,
    String? address,
    String? email,
    String? phone,
    String? dob,
    this.isCorporation = false,
    this.corporationType,
    this.isBankrupt = false,
  })  : firstName = TextEditingController(text: firstName ?? ''),
        lastName = TextEditingController(text: lastName ?? ''),
        address = TextEditingController(text: address ?? ''),
        email = TextEditingController(text: email ?? ''),
        phone = TextEditingController(text: phone ?? ''),
        dob = TextEditingController(text: dob ?? '');

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    address.dispose();
    email.dispose();
    phone.dispose();
    dob.dispose();
  }

  ActAttorneyEntry toEntry() => ActAttorneyEntry(
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        address: address.text.trim(),
        email: email.text.trim().isNotEmpty ? email.text.trim() : null,
        phone: phone.text.trim().isNotEmpty ? phone.text.trim() : null,
        dob: dob.text.trim().isNotEmpty ? dob.text.trim() : null,
        isCorporation: isCorporation,
        corporationType: isCorporation ? corporationType : null,
        isBankrupt: isBankrupt,
      );
}

class PoaStep3Act extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep3Act({super.key, required this.flowData});

  @override
  State<PoaStep3Act> createState() => _PoaStep3ActState();
}

class _PoaStep3ActState extends State<PoaStep3Act> {
  final _formKey = GlobalKey<FormState>();

  // ── Attorneys ──
  late int _attorneyCount;
  final List<_ActAttorneyControllers> _attorneyControllers = [];

  // ── How attorneys act (only visible when count > 1) ──
  late String _howAttorneysAct;

  // ── Delegation ──
  late String _delegationType;
  late TextEditingController _delegationDescriptionController;

  // ── Matters (multi-select) ──
  late List<String> _selectedMatters;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;

    _attorneyCount = fd.actAttorneyCount ?? 1;
    _initAttorneyList(fd.actAttorneys);
    _howAttorneysAct = fd.actHowAttorneysAct ?? 'JOINTLY';
    _delegationType = fd.actDelegationType ?? 'NO_DELEGATION';
    _delegationDescriptionController =
        TextEditingController(text: fd.actDelegationDescription ?? '');
    _selectedMatters = List<String>.from(fd.actMatters);
  }

  void _initAttorneyList(List<ActAttorneyEntry> existing) {
    for (final c in _attorneyControllers) {
      c.dispose();
    }
    _attorneyControllers.clear();
    for (int i = 0; i < _attorneyCount; i++) {
      final e = i < existing.length ? existing[i] : null;
      _attorneyControllers.add(_ActAttorneyControllers(
        firstName: e?.firstName,
        lastName: e?.lastName,
        address: e?.address,
        email: e?.email,
        phone: e?.phone,
        dob: e?.dob,
        isCorporation: e?.isCorporation ?? false,
        corporationType: e?.corporationType,
        isBankrupt: e?.isBankrupt ?? false,
      ));
    }
  }

  void _onAttorneyCountChanged(int? count) {
    if (count == null) return;
    setState(() {
      _attorneyCount = count;
      while (_attorneyControllers.length < count) {
        _attorneyControllers.add(_ActAttorneyControllers());
      }
      while (_attorneyControllers.length > count) {
        _attorneyControllers.removeLast().dispose();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _attorneyControllers) {
      c.dispose();
    }
    _delegationDescriptionController.dispose();
    super.dispose();
  }

  PoaFlowData _collectCurrentData() {
    final attorneys = _attorneyControllers.map((c) => c.toEntry()).toList();
    return widget.flowData.copyWith(
      actAttorneyCount: _attorneyCount,
      actAttorneys: attorneys,
      actHowAttorneysAct: _attorneyCount > 1 ? _howAttorneysAct : null,
      actDelegationType: _delegationType,
      actDelegationDescription: _delegationType == 'SOME_POWERS'
          ? _delegationDescriptionController.text.trim()
          : null,
      actMatters: List.from(_selectedMatters),
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMatters.isEmpty) {
      SnackBarUtils.showError(context, 'Please select at least one matter this power of attorney will cover.');
      return;
    }
    if (_delegationType == 'SOME_POWERS' &&
        _delegationDescriptionController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please describe the powers to be delegated.');
      return;
    }

    final config = PoaFlowConfig.forState(widget.flowData.state);
    final updated = _collectCurrentData();
    await context.push<PoaFlowData>(config.nextRoute(3), extra: updated);
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
          currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
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
                      _buildAttorneysSection(),
                      if (_attorneyCount > 1) ...[
                        const SizedBox(height: 32),
                        _buildHowAttorneysActSection(),
                      ],
                      const SizedBox(height: 32),
                      _buildDelegationSection(),
                      const SizedBox(height: 32),
                      _buildMattersSection(),
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

  // ── Attorneys section ──────────────────────────────────────────────────────

  Widget _buildAttorneysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attorneys (appointed people)', style: AppTextStyles.pageTitle),
        const SizedBox(height: 20),
        Text('How many attorneys do you want to appoint?',
            style: AppTextStyles.subtitle),
        const SizedBox(height: 12),
        AppDropdown<int>(
          value: _attorneyCount,
          label: 'Select count',
          items: const [1, 2, 3],
          displayName: (v) => v.toString(),
          onChanged: _onAttorneyCountChanged,
        ),
        const SizedBox(height: 16),
        ..._buildAttorneyCards(),
      ],
    );
  }

  List<Widget> _buildAttorneyCards() {
    return _attorneyControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final ctrl = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLightGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attorney ${index + 1}',
                  style: AppTextStyles.pageTitle),
              const SizedBox(height: 16),
              AppTextField(
                controller: ctrl.firstName,
                label: 'First name *',
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Please enter first name'
                        : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: ctrl.lastName,
                label: 'Last name *',
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Please enter last name'
                        : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: ctrl.address,
                label: 'Address',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: ctrl.email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: ctrl.phone,
                label: 'Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppDatePickerField(
                controller: ctrl.dob,
                label: 'Date of birth',
                lastDate: DateTime.now(),
                onDateSelected: (date) {
                  ctrl.dob.text =
                      AppDatePickerField.formatDateForApi(date);
                },
              ),
              const SizedBox(height: 16),
              // Is corporation?
              Text('Is this attorney a corporation?',
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioButtonOption(
                      isSelected: ctrl.isCorporation,
                      label: 'Yes',
                      onTap: () =>
                          setState(() => ctrl.isCorporation = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RadioButtonOption(
                      isSelected: !ctrl.isCorporation,
                      label: 'No',
                      onTap: () => setState(() {
                        ctrl.isCorporation = false;
                        ctrl.corporationType = null;
                      }),
                    ),
                  ),
                ],
              ),
              if (ctrl.isCorporation) ...[
                const SizedBox(height: 16),
                Text('What type of corporation?',
                    style: AppTextStyles.subtitle),
                const SizedBox(height: 12),
                RadioListOption(
                  isSelected: ctrl.corporationType == 'PUBLIC_TRUSTEE',
                  title: 'Public trustee and guardian',
                  onTap: () => setState(
                      () => ctrl.corporationType = 'PUBLIC_TRUSTEE'),
                ),
                const SizedBox(height: 8),
                RadioListOption(
                  isSelected: ctrl.corporationType == 'TRUSTEE_COMPANY',
                  title: 'Trustee company',
                  onTap: () => setState(
                      () => ctrl.corporationType = 'TRUSTEE_COMPANY'),
                ),
                const SizedBox(height: 8),
                RadioListOption(
                  isSelected: ctrl.corporationType == 'OTHERS',
                  title: 'Others',
                  onTap: () =>
                      setState(() => ctrl.corporationType = 'OTHERS'),
                ),
              ],
              const SizedBox(height: 16),
              // Bankrupt?
              Text(
                  'Has this attorney been declared bankrupt or insolvent?',
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioButtonOption(
                      isSelected: ctrl.isBankrupt,
                      label: 'Yes',
                      onTap: () =>
                          setState(() => ctrl.isBankrupt = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RadioButtonOption(
                      isSelected: !ctrl.isBankrupt,
                      label: 'No',
                      onTap: () =>
                          setState(() => ctrl.isBankrupt = false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── How attorneys act section ──────────────────────────────────────────────

  Widget _buildHowAttorneysActSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How should your attorneys act?',
            style: AppTextStyles.pageTitle),
        const SizedBox(height: 16),
        RadioListOption(
          isSelected: _howAttorneysAct == 'JOINTLY',
          title: 'Together (jointly)',
          onTap: () => setState(() => _howAttorneysAct = 'JOINTLY'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _howAttorneysAct == 'JOINTLY_SEVERALLY',
          title: 'Separately (jointly and severally)',
          onTap: () => setState(() => _howAttorneysAct = 'JOINTLY_SEVERALLY'),
        ),
      ],
    );
  }

  // ── Delegation section ─────────────────────────────────────────────────────

  Widget _buildDelegationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allow attorneys to delegate', style: AppTextStyles.pageTitle),
        const SizedBox(height: 16),
        RadioListOption(
          isSelected: _delegationType == 'NO_DELEGATION',
          title: 'No delegation',
          onTap: () => setState(() => _delegationType = 'NO_DELEGATION'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _delegationType == 'ALL_POWERS',
          title: 'Delegate all powers',
          onTap: () => setState(() => _delegationType = 'ALL_POWERS'),
        ),
        const SizedBox(height: 12),
        RadioListOption(
          isSelected: _delegationType == 'SOME_POWERS',
          title: 'Delegate some powers',
          onTap: () => setState(() => _delegationType = 'SOME_POWERS'),
        ),
        if (_delegationType == 'SOME_POWERS') ...[
          const SizedBox(height: 16),
          Text(
            'Describe what powers they will be able to delegate',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 8),
          AppTextArea(
            controller: _delegationDescriptionController,
            label: '',
            placeholder: 'Enter details',
            isRequired: true,
            minLines: 4,
            maxLines: 8,
          ),
        ],
      ],
    );
  }

  // ── Matters section ────────────────────────────────────────────────────────

  void _toggleMatter(String matter) {
    setState(() {
      if (_selectedMatters.contains(matter)) {
        _selectedMatters.remove(matter);
      } else {
        _selectedMatters.add(matter);
      }
    });
  }

  Widget _buildMatterCheckbox(String value, String label) {
    final isSelected = _selectedMatters.contains(value);
    return GestureDetector(
      onTap: () => _toggleMatter(value),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleMatter(value),
              activeColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildMattersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Matters covered (scope)', style: AppTextStyles.pageTitle),
        const SizedBox(height: 8),
        Text('Select the matters this power of attorney will cover.',
            style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        _buildMatterCheckbox('PROPERTY', 'Property'),
        const SizedBox(height: 12),
        _buildMatterCheckbox('PERSONAL_CARE', 'Personal care'),
        const SizedBox(height: 12),
        _buildMatterCheckbox('HEALTH_CARE', 'Health care'),
        const SizedBox(height: 12),
        _buildMatterCheckbox('MEDICAL_RESEARCH', 'Medical research'),
      ],
    );
  }
}
