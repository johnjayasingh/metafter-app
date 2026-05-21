import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../widgets/poa_matters_section.dart';
import '../widgets/poa_attorney_section.dart';
import '../widgets/poa_commencement_section.dart';
import '../widgets/poa_views_wishes_expanded_section.dart';
import '../widgets/poa_terms_section.dart';
import '../widgets/poa_bottom_bar.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaStep2Qld extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaStep2Qld({super.key, required this.flowData});

  @override
  State<PoaStep2Qld> createState() => _PoaStep2QldState();
}

class _PoaStep2QldState extends State<PoaStep2Qld> {
  List<String> _selectedMatters = [];
  List<PoaPersonData> _attorneys = [];
  List<PoaPersonData> _successive = [];
  List<PoaPersonData> _guardians = [];
  List<PoaPersonData> _substitutes = [];
  late String _commencementType;
  late TextEditingController _commencementOtherController;

  String? _hasPreference;
  late TextEditingController _preferencesController;

  late TextEditingController _directionsController;
  late bool _hasTerms;
  late TextEditingController _termsController;

  @override
  void initState() {
    super.initState();
    _selectedMatters = widget.flowData.matters.isNotEmpty
        ? List<String>.from(widget.flowData.matters)
        : ['PERSONAL_HEALTH'];
    _attorneys = List<PoaPersonData>.from(widget.flowData.attorneys);
    _successive = List<PoaPersonData>.from(
      widget.flowData.successiveAttorneys,
    );
    _guardians = List<PoaPersonData>.from(
      widget.flowData.enduringGuardians,
    );
    _substitutes = List<PoaPersonData>.from(
      widget.flowData.substituteEnduringGuardians,
    );
    _commencementType = widget.flowData.commencementType ?? 'INCAPACITY';
    _commencementOtherController = TextEditingController(
      text: widget.flowData.commencementOther ?? '',
    );

    _hasPreference = widget.flowData.hasPreference;
    _preferencesController = TextEditingController(
      text: widget.flowData.preferences ?? '',
    );

    _directionsController = TextEditingController(
      text: widget.flowData.directions ?? '',
    );
    _hasTerms = widget.flowData.hasTermsInstructions ?? false;
    _termsController = TextEditingController(
      text: widget.flowData.termsInstructions ?? '',
    );
  }

  @override
  void dispose() {
    _commencementOtherController.dispose();
    _preferencesController.dispose();
    _directionsController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _toggleMatter(String matter) {
    setState(() {
      if (_selectedMatters.contains(matter)) {
        if (_selectedMatters.length > 1) {
          _selectedMatters.remove(matter);
        }
      } else {
        _selectedMatters.add(matter);
      }
    });
  }

  bool get _hasFinancial => _selectedMatters.contains('FINANCIAL');

  PoaFlowData _collectCurrentData() {
    final hasContent = _hasPreference == 'yes' &&
        _preferencesController.text.trim().isNotEmpty;

    return widget.flowData.copyWith(
      matters: List.from(_selectedMatters),
      attorneys: List.from(_attorneys),
      successiveAttorneys: List.from(_successive),
      enduringGuardians: List.from(_guardians),
      substituteEnduringGuardians: List.from(_substitutes),
      commencementType: _hasFinancial ? _commencementType : null,
      commencementOther: _hasFinancial && _commencementType == 'OTHER'
          ? _commencementOtherController.text.trim()
          : null,
      hasViewsWishes: hasContent,
      hasPreference: _hasPreference,
      preferences: _hasPreference == 'yes'
          ? _preferencesController.text.trim()
          : null,
      directions: _directionsController.text.trim(),
      hasTermsInstructions: _hasTerms,
      termsInstructions: _hasTerms ? _termsController.text.trim() : null,
    );
  }

  void _handleNext() {
    if (_attorneys.isEmpty) {
      SnackBarUtils.showError(context, 'Please add at least one attorney.');
      return;
    }
    if (_hasFinancial && _commencementType == 'OTHER' && _commencementOtherController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please specify the commencement details.');
      return;
    }
    if (_hasPreference == 'yes' && _preferencesController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your preferences or select No.');
      return;
    }
    if (_hasTerms && _termsController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter terms and instructions or select No.');
      return;
    }

    final updated = _collectCurrentData();
    context.push(AppRouter.poaQldFinal, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    print('[PoaStep2Qld.build] RENDERING Queensland Step 2 — state: "${widget.flowData.state}"');
    final config = PoaFlowConfig.forState(widget.flowData.state);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
          currentStep: 2, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 2,
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
                    PoaMattersSection(
                      selectedMatters: _selectedMatters,
                      onToggle: _toggleMatter,
                    ),
                    const SizedBox(height: 32),
                    PoaAttorneySection(
                      type: AttorneyType.PRIMARY,
                      title: 'Attorney(s)',
                      addButtonText: '+ Add Attorney',
                      onChanged: (l) => setState(() => _attorneys = l),
                    ),
                    const SizedBox(height: 32),
                    PoaAttorneySection(
                      type: AttorneyType.SUCCESSIVE,
                      title: 'Successive attorney(s)',
                      isOptional: true,
                      addButtonText: '+ Add Successive attorney',
                      onChanged: (l) => _successive = l,
                    ),
                    if (_hasFinancial) ...[
                      const SizedBox(height: 32),
                      PoaCommencementSection(
                        selectedType: _commencementType,
                        otherController: _commencementOtherController,
                        onTypeChanged: (type) =>
                            setState(() => _commencementType = type),
                      ),
                    ],
                    const SizedBox(height: 32),
                    PoaViewsWishesExpandedSection(
                      hasPreference: _hasPreference,
                      onPreferenceChanged: (value) =>
                          setState(() => _hasPreference = value),
                      preferencesController: _preferencesController,
                      directionsController: _directionsController,
                    ),
                    const SizedBox(height: 32),
                    PoaTermsSection(
                      hasTerms: _hasTerms,
                      controller: _termsController,
                      onToggle: (val) =>
                          setState(() => _hasTerms = val),
                    ),
                  ],
                ),
              ),
            ),
            PoaBottomBar(
              onPrevious: () => context.pop(_collectCurrentData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
