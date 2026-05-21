import 'package:digitalwill/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/exit_confirmation_sheet.dart';
import '../../data/models/gift_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';

class ListGiftBeneficiariesScreen extends StatefulWidget {
  const ListGiftBeneficiariesScreen({super.key});

  @override
  State<ListGiftBeneficiariesScreen> createState() => _ListGiftBeneficiariesScreenState();
}

class _ListGiftBeneficiariesScreenState extends State<ListGiftBeneficiariesScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  List<GiftBeneficiaryData> _giftBeneficiaries = [];
  String? _deletingBeneficiaryId;

  @override
  void initState() {
    super.initState();
    _loadGiftBeneficiaries();
  }

  Future<void> _loadGiftBeneficiaries() async {
    final willId = await _storageService.getWillId();
    if (willId != null) {
      context.read<WillBloc>().add(GetGiftBeneficiariesEvent(willId));
    }
  }

  void _showExitConfirmation() {
    showExitConfirmationSheet(context);
  }

  void _selectPreviouslyAdded() async {
    await context.push('/will-creation/select-gift-recipient');
    if (mounted) {
      _loadGiftBeneficiaries();
    }
  }

  Future<void> _showDeleteConfirmation(
    GiftBeneficiaryData beneficiary,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipient'),
        content: Text(
          'Are you sure you want to remove ${beneficiary.giftReceiver.firstName} ${beneficiary.giftReceiver.lastName} as a gift recipient?',
        ),
        actions: [
          AppTextButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppTextButton(
            text: 'Delete',
            onPressed: () => Navigator.pop(context, true),
            color: AppColors.error,
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _deletingBeneficiaryId = '${beneficiary.id}_$index';
      });
      
      final willId = await _storageService.getWillId();
      if (willId != null && mounted) {
        context.read<WillBloc>().add(
          DeleteGiftBeneficiaryEvent(
            willId: willId,
            beneficiaryId: beneficiary.id,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listenWhen: (previous, current) {
        return current is GiftBeneficiariesLoaded || current is WillError;
      },
      buildWhen: (previous, current) {
        return current is WillLoading || current is GiftBeneficiariesLoaded || current is WillError;
      },
      listener: (context, state) {
        if (state is WillError) {
          setState(() {
            _deletingBeneficiaryId = null;
          });
          // Only show error if message is not empty (skip network errors)
          if (state.message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        } else if (state is GiftBeneficiariesLoaded) {
          setState(() {
            _giftBeneficiaries = state.beneficiaries;
            _deletingBeneficiaryId = null;
          });
        } else if (state is WillSuccess) {
          // Reload list after successful deletion
          if (state.message.toLowerCase().contains('deleted') || 
              state.message.toLowerCase().contains('removed')) {
            _loadGiftBeneficiaries();
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: AppDecorations.closeButtonBordered,
                  child: const Center(
                    child: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5/9 steps',
                  style: AppTextStyles.subtitle,
                ),
                Text(
                  'Specific Gifts',
                  style: AppTextStyles.sectionTitle,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: _showExitConfirmation,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: AppDecorations.closeButtonBordered,
                    child: const Center(
                      child: Icon(Icons.close, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Who would you like to leave a specific gift to', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Gifts to underage beneficiaries will only vest when they reach the age of 18. Until that time, they will be held on trust by your executor.',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      
                      // Main content container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppDecorations.cardLightGreen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your selection will show up here',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 16),
                            
                            // Select previously added button
                            AppSecondaryButton(
                              text: 'Select previously added',
                              onPressed: _selectPreviouslyAdded,
                              trailingIcon: Icons.chevron_right,
                            ),
                            
                            if (_giftBeneficiaries.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              // Gift beneficiaries list
                              ..._giftBeneficiaries.asMap().entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRecipientCard(entry.value, entry.key),
                                );
                              }),
                            ],
                            
                            const SizedBox(height: 12),
                            
                            // Add asset button
                            AppPrimaryButton(
                              text: 'Add asset',
                              onPressed: () {
                                context.push(AppRouter.addAsset);
                              },
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
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Next step',
                        onPressed: () {
                          // Navigate to executors
                          context.push(AppRouter.executors);
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

  Widget _buildRecipientCard(GiftBeneficiaryData beneficiary, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundLightGreen,
            child: Text(
              beneficiary.giftReceiver.firstName.isNotEmpty 
                  ? beneficiary.giftReceiver.firstName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.avatarInitialsLarge,
            ),
          ),
          const SizedBox(width: 12),
          // Name and Type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${beneficiary.giftReceiver.firstName} ${beneficiary.giftReceiver.lastName}',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  'Recipient',
                  style: AppTextStyles.cardSecondary,
                ),
              ],
            ),
          ),
          // Delete Button
          GestureDetector(
            onTap: _deletingBeneficiaryId == '${beneficiary.id}_$index'
                ? null
                : () => _showDeleteConfirmation(beneficiary, index),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _deletingBeneficiaryId == '${beneficiary.id}_$index'
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.error,
                          ),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.error,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
