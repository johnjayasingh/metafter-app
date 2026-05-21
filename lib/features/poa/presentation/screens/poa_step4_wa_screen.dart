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
import 'poa_step3_wa_screen.dart' show WaPersonControllers;

/// POA Western Australia Step 4 — Substitute attorney(s).
class PoaStep4Wa extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep4Wa({super.key, required this.flowData});

  @override
  State<PoaStep4Wa> createState() => _PoaStep4WaState();
}

class _PoaStep4WaState extends State<PoaStep4Wa> {
  late bool _hasSubstitute;
  late String _substituteAppointmentType;
  final List<WaPersonControllers> _substituteControllers = [];
  late String _substituteActsFor;
  late TextEditingController _substituteWhenToActController;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _hasSubstitute = fd.waHasSubstitute ?? false;
    _substituteAppointmentType = fd.waSubstituteAppointmentType ?? 'SOLE';
    _initSubstituteList(fd.waSubstitutes);
    _substituteActsFor = fd.waSubstituteActsFor ?? 'ATTORNEY_1';
    _substituteWhenToActController =
        TextEditingController(text: fd.waSubstituteWhenToAct ?? '');
  }

  void _initSubstituteList(List<WaPersonEntry> existing) {
    for (final c in _substituteControllers) {
      c.dispose();
    }
    _substituteControllers.clear();
    final minCount = _minCount(_substituteAppointmentType);
    final count = existing.length > minCount ? existing.length : minCount;
    for (int i = 0; i < count; i++) {
      final e = i < existing.length ? existing[i] : null;
      _substituteControllers.add(WaPersonControllers(
        name: e?.name,
        address: e?.address,
        email: e?.email,
      ));
    }
  }

  int _minCount(String type) => (type == 'SOLE') ? 1 : 2;

  void _onSubstituteTypeChanged(String type) {
    setState(() {
      _substituteAppointmentType = type;
      while (_substituteControllers.length < _minCount(type)) {
        _substituteControllers.add(WaPersonControllers());
      }
      if (type == 'SOLE') {
        while (_substituteControllers.length > 1) {
          _substituteControllers.removeLast().dispose();
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in _substituteControllers) {
      c.dispose();
    }
    _substituteWhenToActController.dispose();
    super.dispose();
  }

  PoaFlowData _collectData() {
    final substitutes = _hasSubstitute
        ? _substituteControllers.map((c) => c.toEntry()).toList()
        : <WaPersonEntry>[];
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waHasSubstitute: _hasSubstitute,
      waSubstituteAppointmentType:
          _hasSubstitute ? _substituteAppointmentType : null,
      waSubstitutes: substitutes,
      waSubstituteActsFor: _hasSubstitute ? _substituteActsFor : null,
      waSubstituteWhenToAct: _hasSubstitute
          ? _substituteWhenToActController.text.trim()
          : null,
    );
  }

  Future<void> _handleNext() async {
    if (_hasSubstitute) {
      for (int i = 0; i < _substituteControllers.length; i++) {
        if (_substituteControllers[i].name.text.trim().isEmpty) {
          SnackBarUtils.showError(
              context, 'Please enter the name for Substitute ${i + 1}.');
          return;
        }
      }
    }
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
      config.nextRoute(4),
      extra: _collectData(),
    );
    if (result != null) setState(() => _returnedFromNext = result);
  }

  Widget _buildSubstituteCard(int index, WaPersonControllers ctrl) {
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
            Text('Substitute ${index + 1}', style: AppTextStyles.pageTitle),
            const SizedBox(height: 12),
            AppTextField(controller: ctrl.name, label: 'Full legal name'),
            const SizedBox(height: 12),
            AppTextField(controller: ctrl.address, label: 'Address'),
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
      drawer: PoaStepsSidebar(currentStep: 4, userState: widget.flowData.state),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Substitute attorney',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Would you like to appoint a substitute attorney?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _hasSubstitute,
                            label: 'Yes',
                            onTap: () {
                              setState(() {
                                _hasSubstitute = true;
                                if (_substituteControllers.isEmpty) {
                                  _substituteControllers
                                      .add(WaPersonControllers());
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: !_hasSubstitute,
                            label: 'No',
                            onTap: () =>
                                setState(() => _hasSubstitute = false),
                          ),
                        ),
                      ],
                    ),
                    if (_hasSubstitute) ...[
                      const SizedBox(height: 24),
                      Text('How are substitutes appointed?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _substituteAppointmentType == 'SOLE',
                        title: 'Sole substitute',
                        onTap: () => _onSubstituteTypeChanged('SOLE'),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _substituteAppointmentType == 'JOINT',
                        title: 'Joint substitutes',
                        onTap: () => _onSubstituteTypeChanged('JOINT'),
                      ),
                      const SizedBox(height: 24),
                      ..._substituteControllers.asMap().entries.map(
                          (entry) =>
                              _buildSubstituteCard(entry.key, entry.value)),
                      const SizedBox(height: 16),
                      Text('Who does the substitute act for?',
                          style: AppTextStyles.questionTitle),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _substituteActsFor == 'ATTORNEY_1',
                        title: 'Attorney 1',
                        onTap: () =>
                            setState(() => _substituteActsFor = 'ATTORNEY_1'),
                      ),
                      const SizedBox(height: 12),
                      RadioListOption(
                        isSelected: _substituteActsFor == 'ALL_ATTORNEYS',
                        title: 'All attorneys',
                        onTap: () => setState(
                            () => _substituteActsFor = 'ALL_ATTORNEYS'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'When can the substitute act?',
                        style: AppTextStyles.questionTitle,
                      ),
                      const SizedBox(height: 8),
                      AppTextArea(
                        controller: _substituteWhenToActController,
                        label: '',
                        placeholder:
                            'Describe conditions under which the substitute can act',
                        minLines: 4,
                        maxLines: 8,
                      ),
                    ],
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
