import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/poa_models.dart';
import '../widgets/poa_steps_sidebar.dart';

class PoaMattersScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaMattersScreen({super.key, required this.flowData});

  @override
  State<PoaMattersScreen> createState() => _PoaMattersScreenState();
}

class _PoaMattersScreenState extends State<PoaMattersScreen> {
  late List<String> _selectedMatters;

  @override
  void initState() {
    super.initState();
    _selectedMatters = List<String>.from(widget.flowData.matters);
    if (_selectedMatters.isEmpty) {
      _selectedMatters.add('PERSONAL_HEALTH');
    }
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

  PoaFlowData _collectCurrentData() {
    return widget.flowData.copyWith(matters: List.from(_selectedMatters));
  }

  void _handleNext() {
    final updated = _collectCurrentData();
    context.push(AppRouter.poaAttorneys, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PoaStepsSidebar(currentStep: 2),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: 8,
        title: 'Enduring power of attorney',
        enableDrawer: true,
        exitTitle: 'Exit power of attorney?',
        exitDescription: 'Your progress will be lost. You can start a new power of attorney at any time.',
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
                    Text('Matters', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    // Personal (including health) matters
                    RadioListOption(
                      isSelected: _selectedMatters.contains('PERSONAL_HEALTH'),
                      title: 'Personal (including health) matters',
                      subtitle:
                          'Personal matter relate to personal and lifestyle decisions this includes decisions about support services where and with whom you live health care and legal matters that do not relate to your financial or property matters',
                      onTap: () => _toggleMatter('PERSONAL_HEALTH'),
                    ),
                    const SizedBox(height: 12),

                    // Financial matters
                    RadioListOption(
                      isSelected: _selectedMatters.contains('FINANCIAL'),
                      title: 'Financial matters',
                      subtitle:
                          'Financial matter relate to your financial or property affairs including paying expenses making investments selling property carrying on a business',
                      onTap: () => _toggleMatter('FINANCIAL'),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            _PoaBottomBar(
              onPrevious: () => context.pop(_collectCurrentData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared bottom bar widget (private to this flow) ───────────────────────

class _PoaBottomBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const _PoaBottomBar({
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                onPressed: onPrevious,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                text: 'Next step',
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
