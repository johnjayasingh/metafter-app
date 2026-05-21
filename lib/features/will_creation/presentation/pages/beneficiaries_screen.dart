import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  List<BeneficiaryPersonData> _beneficiaries = [];

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetBeneficiaryPersonsEvent(willId));
    }
  }

  void _addBeneficiary() async {
    await context.push('/will-creation/add-beneficiary');
    // API call is handled by the add screen, just refresh the data
    if (mounted) {
      _loadBeneficiaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listenWhen: (previous, current) {
        return current is BeneficiaryPersonsLoaded ||
               current is WillError ||
               current is WillSuccess;
      },
      buildWhen: (previous, current) {
        return current is WillLoading ||
               current is BeneficiaryPersonsLoaded ||
               current is WillError;
      },
      listener: (context, state) {
        if (state is WillError) {
          if (state.message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        } else if (state is BeneficiaryPersonsLoaded) {
          setState(() {
            _beneficiaries = state.beneficiaries;
          });
        } else if (state is WillSuccess) {
          _loadBeneficiaries();
        }
      },
      builder: (context, state) {
        return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: WillStepsSidebar(currentStep: 4),
      appBar: WillCreationAppBar(
        currentStep: 4,
        totalSteps: 11,
        title: 'Beneficiaries',
        showBackButton: true,
        onBack: () {
          context.go(AppRouter.familyDetails);
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Text(
                    'Add beneficiary',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add someone special outside your immediate family',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Beneficiaries Section Card
                  if (_beneficiaries.isEmpty)
                    EmptyStateCard(
                      buttonText: 'Add Beneficiaries',
                      onAddPressed: _addBeneficiary,
                      placeholderWidget: _buildPlaceholderCards('Beneficiary name', 'Beneficiary'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _beneficiaries.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final beneficiary = _beneficiaries[index];
                              return _buildBeneficiaryCard(beneficiary, index);
                            },
                          ),
                          const SizedBox(height: 12),
                          AppPrimaryButton(
                            text: 'Add Beneficiaries',
                            onPressed: _addBeneficiary,
                            icon: Icons.add,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          AppBottomActionBar(
            child: Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    text: 'Previous',
                    onPressed: () => context.go(AppRouter.familyDetails),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    text: 'Next step',
                    onPressed: () {
                      // Navigate to charity selection
                      context.push('/will-creation/charities');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildBeneficiaryCard(BeneficiaryPersonData beneficiary, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundLightGreen,
            child: Text(
              beneficiary.firstName.isNotEmpty
                  ? beneficiary.firstName.substring(0, 1).toUpperCase()
                  : '?',
              style: AppTextStyles.avatarInitialsLarge.copyWith(color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(width: 12),
          // Name and Type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beneficiary.fullName,
                  style: AppTextStyles.itemLabel,
                ),
                const SizedBox(height: 2),
                Text(
                  'Beneficiary',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          // Edit Button
          GestureDetector(
            onTap: () async {
              await context.push(
                '/will-creation/add-beneficiary',
                extra: beneficiary, // Pass typed data for edit
              );
              if (mounted) {
                _loadBeneficiaries();
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button
          GestureDetector(
            onTap: () async {
              final willId = await _storageService.getWillId();
              if (willId != null && mounted) {
                context.read<WillBloc>().add(DeleteBeneficiaryPersonEvent(
                  willId: willId,
                  beneficiaryId: beneficiary.id,
                ));
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCards(String title, String subtitle) {
    return Opacity(
      opacity: 0.5,
      child: SizedBox(
        height: 90,
        child: Stack(
          children: [
            // Back card (offset and with opacity)
            Positioned(
              left: 10,
              top: 24,
              right: 0,
              child: Opacity(
                opacity: 0.5,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLightBlue, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // Small green checkbox
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.backgroundWhite,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Front card
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLightBlue, width: 0.6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Green checkbox
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.backgroundWhite,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
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
                          title,
                          style: AppTextStyles.itemLabel.copyWith(color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
