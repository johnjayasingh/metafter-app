import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/debug_config.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';
import '../widgets/empty_state_card.dart';

class WitnessScreen extends StatefulWidget {
  const WitnessScreen({super.key});

  @override
  State<WitnessScreen> createState() => _WitnessScreenState();
}

class _WitnessScreenState extends State<WitnessScreen> {
  String? _willId;
  final _secureStorage = SecureStorageService();
  List<WitnessData> _witnesses = [];
  bool _isSubmitting = false;


  @override
  void initState() {
    super.initState();
    _loadWitnesses();
  }

  Future<void> _loadWitnesses() async {
    _willId = await _secureStorage.getWillId();
    if (_willId != null && mounted) {
      context.read<WillBloc>().add(GetWitnessesEvent(_willId!));
    }
  }

  void _deleteWitness(String witnessId) {
    if (_willId != null) {
      setState(() => _isSubmitting = true);
      context.read<WillBloc>().add(DeleteWitnessEvent(_willId!, witnessId));
    }
  }

  void _navigateToAddWitness({WitnessData? existingWitness}) {
    context.push(AppRouter.addWitness, extra: existingWitness);
  }

  void _navigateNext() {
    // Navigate to review screen (final step)
    context.push(AppRouter.review);
  }

  void _navigateBackToExecutors() async {
    // Optionally reload executors from API before navigating back
    final willId = _willId ?? await _secureStorage.getWillId();
    if (willId != null) {
      context.read<WillBloc>().add(GetExecutorsEvent(willId));
    }
    context.go(AppRouter.executors);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listenWhen: (previous, current) =>
        current is WitnessesLoaded ||
        current is WitnessDeleted ||
        current is WillSuccess ||
        current is WillError,
      listener: (context, state) {
        if (state is WitnessesLoaded) {
          setState(() {
            _witnesses = state.witnesses;
            _isSubmitting = false;
          });
        } else if (state is WitnessDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Witness removed successfully'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        } else if (state is WillSuccess) {
          final msg = state.message?.toLowerCase() ?? '';
          if (msg.contains('witness_id') || msg.contains('witness added')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Witness added successfully'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
            if (_willId != null) {
              context.read<WillBloc>().add(GetWitnessesEvent(_willId!));
            }
          }
        } else if (state is WillError) {
          setState(() => _isSubmitting = false);
          // Only show error if message is not empty (skip network errors)
          if (state.message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: BlocBuilder<WillBloc, WillState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundWhite,
            drawer: WillStepsSidebar(currentStep: 10),
            appBar: WillCreationAppBar(
              title: 'Witness',
              currentStep: 10,
              totalSteps: 11,
              showBackButton: true,
              onBack: _navigateBackToExecutors,
            ),
            body: _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Witness',
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To make your will legally valid, it must be signed in front of two independent witnesses.',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Requirements in bordered container
                          Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            border: Border.all(
                              color: AppColors.accentGreen,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRequirement('Must be over 18 years old'),
                              _buildRequirement('Cannot be a beneficiary of your will'),
                              _buildRequirement('Should not be your executor or spouse/partner'),
                              _buildRequirement('Must be present at the time of signing'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Witness section styled like family_details_screen.dart
                        if (_witnesses.isEmpty)
                          EmptyStateCard(
                            buttonText: 'Add Witness',
                            onAddPressed: _navigateToAddWitness,
                            placeholderWidget: _buildWitnessPlaceholderCard(),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.borderGray),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._witnesses.map((witness) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildWitnessCardStyled(witness),
                                    )),
                                // Add Witness Button styled
                                AppPrimaryButton(
                                  text: 'Add Witness',
                                  onPressed: _navigateToAddWitness,
                                  icon: Icons.add,
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                AppBottomActionBar(
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            text: 'Previous',
                            onPressed: () => context.go(AppRouter.executors),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPrimaryButton(
                            text: 'Next step',
                            onPressed: _witnesses.length >= 2 ? _navigateNext : null,
                            isDisabled: _witnesses.length < 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWitnessCardStyled(WitnessData witness) {
    final name = '${witness.firstName} ${witness.lastName}'.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          // Avatar circle
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundLightGreen,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Witness',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _navigateToAddWitness(existingWitness: witness),
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _deleteWitness(witness.id),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.textGray3,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildWitnessPlaceholderCard() {
    return Opacity(
      opacity: 0.5,
      child: SizedBox(
        height: 72,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLightBlue, width: 0.6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Witness name',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Witness',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
