import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

/// POA Tasmania Step 3 — Donor details & completion date.
class PoaStep3Tas extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep3Tas({super.key, required this.flowData});

  @override
  State<PoaStep3Tas> createState() => _PoaStep3TasState();
}

class _PoaStep3TasState extends State<PoaStep3Tas> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _completionDateController;
  late TextEditingController _fullNameController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  DateTime? _selectedDate;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;

    _completionDateController =
        TextEditingController(text: fd.tasCompletionDate ?? '');
    if (fd.tasCompletionDate != null && fd.tasCompletionDate!.isNotEmpty) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(fd.tasCompletionDate!);
        _completionDateController.text =
            DateFormat('dd/MM/yyyy').format(_selectedDate!);
      } catch (_) {}
    }

    _fullNameController =
        TextEditingController(text: fd.tasDonorFullName ?? '');
    _addressController =
        TextEditingController(text: fd.tasDonorAddress ?? '');
    _emailController = TextEditingController(text: fd.tasDonorEmail ?? '');
  }

  @override
  void dispose() {
    _completionDateController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _completionDateController.text =
            DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  PoaFlowData _collectData() {
    final apiDate =
        _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;
    return (_returnedFromNext ?? widget.flowData).copyWith(
      tasDonorFullName: _fullNameController.text.trim(),
      tasDonorAddress: _addressController.text.trim(),
      tasDonorEmail: _emailController.text.trim(),
      tasCompletionDate: apiDate,
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a completion date.')),
      );
      return;
    }
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
        config.nextRoute(3), extra: _collectData());
    if (result != null) setState(() => _returnedFromNext = result);
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
        currentStep: 3,
        userState: widget.flowData.state,
      ),
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
                      Text('Donor', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'What date are you completing this Enduring Power of Attorney?',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 20),
                      Text('Select date', style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _completionDateController,
                        label: 'Completion date',
                        readOnly: true,
                        onTap: _pickDate,
                        suffixIcon: Icons.calendar_today_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please select a date'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text('Your full legal name?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _fullNameController,
                        label: 'Full legal name',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your full legal name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Your residential address?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _addressController,
                        label: 'Residential address',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your residential address'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Your email address',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _emailController,
                        label: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PoaBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
