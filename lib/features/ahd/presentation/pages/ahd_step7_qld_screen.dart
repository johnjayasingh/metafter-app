import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD Queensland Step 7 — Doctor certificate
///
/// API fields (in ahd_persons):
///   - DOCTOR: full_name, dob, phone, address, suburb, other.facility_name
class AhdStep7QldScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep7QldScreen({super.key, required this.flowData});

  @override
  State<AhdStep7QldScreen> createState() => _AhdStep7QldScreenState();
}

class _AhdStep7QldScreenState extends State<AhdStep7QldScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _doctorNameController;
  late final TextEditingController _facilityNameController;
  late final TextEditingController _doctorPhoneController;
  late final TextEditingController _doctorDobController;
  late final TextEditingController _doctorAddressController;
  late final TextEditingController _doctorSuburbController;
  late final TextEditingController _doctorPostcodeController;
  String? _doctorState;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _doctorNameController =
        TextEditingController(text: d.doctorName ?? '');
    _facilityNameController =
        TextEditingController(text: d.facilityName ?? '');
    _doctorPhoneController =
        TextEditingController(text: d.doctorPhone ?? '');
    _doctorDobController =
        TextEditingController(text: d.doctorDob ?? '');
    _doctorAddressController =
        TextEditingController(text: d.doctorAddress ?? '');
    _doctorSuburbController =
        TextEditingController(text: d.doctorSuburb ?? '');
    _doctorPostcodeController =
        TextEditingController(text: d.doctorPostcode ?? '');
    _doctorState = d.doctorState;
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _facilityNameController.dispose();
    _doctorPhoneController.dispose();
    _doctorDobController.dispose();
    _doctorAddressController.dispose();
    _doctorSuburbController.dispose();
    _doctorPostcodeController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      doctorName: _doctorNameController.text.trim(),
      facilityName: _facilityNameController.text.trim(),
      doctorPhone: _doctorPhoneController.text.trim(),
      doctorDob: _doctorDobController.text.trim(),
      doctorAddress: _doctorAddressController.text.trim(),
      doctorSuburb: _doctorSuburbController.text.trim(),
      doctorPostcode: _doctorPostcodeController.text.trim(),
      doctorState: _doctorState,
    );
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(7), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 7, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 7,
        totalSteps: config.totalSteps,
        title: 'Doctor certificate',
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
                      Text('Doctor certificate',
                          style: AppTextStyles.pageTitle),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _doctorNameController,
                        label: "Doctor's name",
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _facilityNameController,
                        label: 'Name of facility or practice',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _doctorPhoneController,
                        label: 'Phone number',
                      ),
                      const SizedBox(height: 16),
                      AppDatePickerField(
                        controller: _doctorDobController,
                        label: 'Date of birth',
                        onDateSelected: (date) {
                          _doctorDobController.text =
                              AppDatePickerField.formatDate(date);
                        },
                      ),
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
                        controller: TextEditingController(
                            text: FormConstants.defaultCountry),
                        label: 'Country',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      AppDropdownFormField<String>(
                        label: 'State',
                        value: _doctorState,
                        items: FormConstants.australianStateKeys,
                        displayName: (v) =>
                            FormConstants.getStateDisplayName(v),
                        onChanged: (v) => setState(() => _doctorState = v),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _doctorPostcodeController,
                        label: 'Postcode',
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
}
