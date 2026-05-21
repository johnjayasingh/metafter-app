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

/// Helper: controllers for a single NT decision-maker card.
class _DmControllers {
  final TextEditingController name;
  final TextEditingController address;

  _DmControllers({String? name, String? address})
      : name = TextEditingController(text: name ?? ''),
        address = TextEditingController(text: address ?? '');

  void dispose() {
    name.dispose();
    address.dispose();
  }

  NtDecisionMakerEntry toEntry() => NtDecisionMakerEntry(
        name: name.text.trim(),
        address: address.text.trim(),
      );
}

/// POA Northern Territory Step 4 — Decision-makers for financial matters.
class PoaStep4Nt extends StatefulWidget {
  final PoaFlowData flowData;
  const PoaStep4Nt({super.key, required this.flowData});

  @override
  State<PoaStep4Nt> createState() => _PoaStep4NtState();
}

class _PoaStep4NtState extends State<PoaStep4Nt> {
  late int _financialDmCount;
  final List<_DmControllers> _dmControllers = [];
  late String _financialDmActingMethod;
  late TextEditingController _financialLimitsController;

  PoaFlowData? _returnedFromNext;

  @override
  void initState() {
    super.initState();
    final fd = widget.flowData;
    _financialDmCount = fd.ntFinancialDmCount ?? 1;
    _initDmList(fd.ntFinancialDms);
    _financialDmActingMethod = fd.ntFinancialDmActingMethod ?? 'SEVERALLY';
    _financialLimitsController =
        TextEditingController(text: fd.ntFinancialLimits ?? '');
  }

  void _initDmList(List<NtDecisionMakerEntry> existing) {
    for (final c in _dmControllers) {
      c.dispose();
    }
    _dmControllers.clear();
    for (int i = 0; i < _financialDmCount; i++) {
      final e = i < existing.length ? existing[i] : null;
      _dmControllers.add(_DmControllers(
        name: e?.name,
        address: e?.address,
      ));
    }
  }

  void _onDmCountChanged(int? count) {
    if (count == null) return;
    setState(() {
      _financialDmCount = count;
      while (_dmControllers.length < count) {
        _dmControllers.add(_DmControllers());
      }
      while (_dmControllers.length > count) {
        _dmControllers.removeLast().dispose();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _dmControllers) {
      c.dispose();
    }
    _financialLimitsController.dispose();
    super.dispose();
  }

  PoaFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      ntFinancialDmCount: _financialDmCount,
      ntFinancialDms: _dmControllers.map((c) => c.toEntry()).toList(),
      ntFinancialDmActingMethod: _financialDmActingMethod,
      ntFinancialLimits: _financialLimitsController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    for (int i = 0; i < _dmControllers.length; i++) {
      if (_dmControllers[i].name.text.trim().isEmpty) {
        SnackBarUtils.showError(
            context, 'Please enter the name for Decision maker ${i + 1}.');
        return;
      }
    }
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final result = await context.push<PoaFlowData>(
      config.nextRoute(4),
      extra: _collectData(),
    );
    if (result != null) setState(() => _returnedFromNext = result);
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
                    Text(
                      'Decision-maker for financial matters',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Who will be your decision-maker(s) for financial matters (including property)?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How many financial decision-makers do you want to appoint?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 8),
                    AppDropdown<int>(
                      value: _financialDmCount,
                      label: 'Select count',
                      items: const [1, 2, 3, 4],
                      displayName: (item) => item.toString(),
                      onChanged: _onDmCountChanged,
                    ),
                    const SizedBox(height: 24),
                    ..._dmControllers.asMap().entries.map((entry) {
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
                              Text(
                                'Decision maker ${index + 1}',
                                style: AppTextStyles.pageTitle,
                              ),
                              const SizedBox(height: 16),
                              Text('Who is your decision maker?',
                                  style: AppTextStyles.subtitle),
                              const SizedBox(height: 8),
                              AppTextArea(
                                controller: ctrl.name,
                                label: '',
                                placeholder: 'Enter details',
                                minLines: 2,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 16),
                              Text('What is their address?',
                                  style: AppTextStyles.subtitle),
                              const SizedBox(height: 8),
                              AppTextArea(
                                controller: ctrl.address,
                                label: '',
                                placeholder: 'Enter details',
                                minLines: 2,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Text(
                      'How should your decision-makers make financial decisions?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 16),
                    RadioListOption(
                      isSelected: _financialDmActingMethod == 'SEVERALLY',
                      title: 'Severally',
                      onTap: () => setState(
                          () => _financialDmActingMethod = 'SEVERALLY'),
                    ),
                    const SizedBox(height: 12),
                    RadioListOption(
                      isSelected: _financialDmActingMethod == 'JOINTLY',
                      title: 'Jointly',
                      onTap: () =>
                          setState(() => _financialDmActingMethod = 'JOINTLY'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Any limits or instructions for your decision-maker(s) about financial matters?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 8),
                    AppTextArea(
                      controller: _financialLimitsController,
                      label: '',
                      placeholder: 'Enter details',
                      minLines: 4,
                      maxLines: 8,
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
