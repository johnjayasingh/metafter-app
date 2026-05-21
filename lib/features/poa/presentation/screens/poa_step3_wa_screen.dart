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

/// Helper: controllers for a single WA person card.
class WaPersonControllers {
  final TextEditingController name;
  final TextEditingController address;
  final TextEditingController email;

  WaPersonControllers({String? name, String? address, String? email})
      : name = TextEditingController(text: name ?? ''),
        address = TextEditingController(text: address ?? ''),
        email = TextEditingController(text: email ?? '');

  void dispose() {
    name.dispose();
    address.dispose();
    email.dispose();
  }

  WaPersonEntry toEntry() => WaPersonEntry(
        name: name.text.trim(),
        address: address.text.trim(),
        email: email.text.trim(),
      );
}

/// POA Western Australia Step 3 — Attorney appointment.
class PoaStep3Wa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep3Wa({super.key, required this.flowData});

  @override
  State<PoaStep3Wa> createState() => _PoaStep3WaState();
}

class _PoaStep3WaState extends State<PoaStep3Wa> {
  late String _appointmentType;
  final List<WaPersonControllers> _attorneyControllers = [];

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _appointmentType = fd.waAttorneyAppointmentType ?? 'SOLE';
    _initAttorneyList(fd.waAttorneys);
  }

  void _initAttorneyList(List<WaPersonEntry> existing) {
    for (final c in _attorneyControllers) {
      c.dispose();
    }
    _attorneyControllers.clear();
    final minCount = _minCount(_appointmentType);
    final count = existing.length > minCount ? existing.length : minCount;
    for (int i = 0; i < count; i++) {
      final e = i < existing.length ? existing[i] : null;
      _attorneyControllers.add(WaPersonControllers(
        name: e?.name,
        address: e?.address,
        email: e?.email,
      ));
    }
  }

  int _minCount(String type) =>
      (type == 'SOLE') ? 1 : 2;

  void _onTypeChanged(String type) {
    setState(() {
      _appointmentType = type;
      // Grow if needed
      while (_attorneyControllers.length < _minCount(type)) {
        _attorneyControllers.add(WaPersonControllers());
      }
      // Trim for SOLE
      if (type == 'SOLE') {
        while (_attorneyControllers.length > 1) {
          _attorneyControllers.removeLast().dispose();
        }
      }
    });
  }

  void _addAttorney() =>
      setState(() => _attorneyControllers.add(WaPersonControllers()));

  void _removeAttorney(int index) {
    if (_attorneyControllers.length <= _minCount(_appointmentType)) return;
    setState(() => _attorneyControllers.removeAt(index).dispose());
  }

  @override
  void dispose() {
    for (final c in _attorneyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waAttorneyAppointmentType: _appointmentType,
      waAttorneys: _attorneyControllers.map((c) => c.toEntry()).toList(),
    );
  }

  Future<void> _handleNext() async {
    for (int i = 0; i < _attorneyControllers.length; i++) {
      if (_attorneyControllers[i].name.text.trim().isEmpty) {
        SnackBarUtils.showError(
            context, 'Please enter the name for Attorney ${i + 1}.');
        return;
      }
    }
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
      config.nextRoute(3),
      extra: _collectData(),
    );
    if (result != null) setState(() => _returnedFromNext = result);
  }

  Widget _buildPersonCard(int index, WaPersonControllers ctrl, String label) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTextStyles.pageTitle),
                if (_attorneyControllers.length > _minCount(_appointmentType))
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: () => _removeAttorney(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: ctrl.name,
              label: 'Full legal name',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: ctrl.address,
              label: 'Address',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: ctrl.email,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(currentStep: 3, userState: widget.flowData.state),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attorney appointment',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'How do you want to appoint your attorney(s)?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),
                    RadioListOption(
                      isSelected: _appointmentType == 'SOLE',
                      title: 'Sole attorney',
                      onTap: () => _onTypeChanged('SOLE'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _appointmentType == 'JOINT',
                      title: 'Joint attorneys (must act together)',
                      onTap: () => _onTypeChanged('JOINT'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _appointmentType == 'JOINT_AND_SEVERAL',
                      title:
                          'Joint and several attorneys (can act together or independently)',
                      onTap: () => _onTypeChanged('JOINT_AND_SEVERAL'),
                    ),
                    const SizedBox(height: 24),
                    ..._attorneyControllers.asMap().entries.map((entry) =>
                        _buildPersonCard(
                            entry.key, entry.value, 'Attorney ${entry.key + 1}')),
                    if (_appointmentType == 'JOINT_AND_SEVERAL')
                      TextButton.icon(
                        onPressed: _addAttorney,
                        icon: const Icon(Icons.add),
                        label: const Text('Add another attorney'),
                      ),
                  ],
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
