import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../../will_creation/presentation/widgets/radio_option_widgets.dart';
import '../../data/models/vault_models.dart';
import '../cubit/vault_cubit.dart';

class ClosureInstructionsScreen extends StatefulWidget {
  const ClosureInstructionsScreen({super.key});

  @override
  State<ClosureInstructionsScreen> createState() => _ClosureInstructionsScreenState();
}

class _ClosureInstructionsScreenState extends State<ClosureInstructionsScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _executorNotesController = TextEditingController();
  ActionAfterDeath? _selectedAction;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPreference();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _executorNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPreference() async {
    final pref = await context.read<VaultCubit>().loadPreference();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (pref != null) {
          _selectedAction = pref.actionAfterDeath;
          _notesController.text = pref.notes ?? '';
          _executorNotesController.text = pref.executorNotes ?? '';
        }
      });
    }
  }

  Future<void> _handleFinish() async {
    if (_selectedAction == null) return;

    setState(() => _isSaving = true);

    final ok = await context.read<VaultCubit>().savePreference(
      VaultPreference(
        actionAfterDeath: _selectedAction!,
        notes: _notesController.text.trim(),
        executorNotes: _executorNotesController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      // Reload the vault asset list so the tab is fresh
      context.read<VaultCubit>().loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digital vault account saved successfully'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save preferences. Please try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: 2,
        title: 'Instructions',
        showBackButton: true,
        showStepNumber: true,
        exitTitle: 'Exit digital vault?',
        exitDescription: 'You can save your progress as a draft and continue later, or discard this account.',
        exitDiscardButtonText: 'Discard Account',
        onBack: () {
          context.pop();
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Closure or Transfer Instructions',
                            style: AppTextStyles.pageTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your credentials will be encrypted using AES-256 and accessible only to authorised executors after death verification',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 32),

                          // Radio options
                          RadioListOption(
                            isSelected: _selectedAction == ActionAfterDeath.closeAccount,
                            title: 'Close Account',
                            onTap: () => setState(() => _selectedAction = ActionAfterDeath.closeAccount),
                          ),
                          const SizedBox(height: 12),
                          RadioListOption(
                            isSelected: _selectedAction == ActionAfterDeath.transferOwnership,
                            title: 'Transfer ownership',
                            onTap: () => setState(() => _selectedAction = ActionAfterDeath.transferOwnership),
                          ),
                          const SizedBox(height: 12),
                          RadioListOption(
                            isSelected: _selectedAction == ActionAfterDeath.noAction,
                            title: 'No action needed',
                            onTap: () => setState(() => _selectedAction = ActionAfterDeath.noAction),
                          ),
                          const SizedBox(height: 32),

                          // Notes
                          AppTextArea(
                            controller: _notesController,
                            label: 'Notes',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 20),

                          // Executor notes
                          AppTextArea(
                            controller: _executorNotesController,
                            label: 'Executor notes',
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom button
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: AppPrimaryButton(
                        text: _isSaving ? 'Saving…' : 'Finish',
                        onPressed: (_selectedAction != null && !_isSaving)
                            ? _handleFinish
                            : null,
                        fullWidth: true,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

