import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';

class FamilyDetailsScreen extends StatefulWidget {
  const FamilyDetailsScreen({super.key});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  List<FormerPartnerData> _formerPartners = [];
  List<DependentPersonData> _dependents = [];
  List<PetData> _pets = [];
  bool _hasShownError = false;
  bool _canIncludeFormerPartner = false;
  String? _relationshipStatus; // To track if user is married/de facto

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    final willId = await _storageService.getWillId();
    if (willId != null) {
      context.read<WillBloc>().add(GetFamilyInitialEvent(willId));
      context.read<WillBloc>().add(GetFormerPartnersEvent(willId));
      context.read<WillBloc>().add(GetDependentPersonsEvent(willId));
      context.read<WillBloc>().add(GetPetsEvent(willId));
    }
  }

  void _showAddFormerPartnerDialog() async {
    await context.push(
      '/will-creation/add-former-partner',
    );
    // API call is handled by the add screen, just refresh the data
    if (mounted) {
      _loadFamilyData();
    }
  }

  void _showAddDependentDialog() async {
    await context.push('/will-creation/add-dependent');
    // API call is handled by the add screen, just refresh the data
    if (mounted) {
      _loadFamilyData();
    }
  }

  void _showDeletePartnerConfirmation(PartnerData partner) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text('Are you sure you want to remove ${partner.partner.firstName} ${partner.partner.lastName} as a partner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final willId = await _storageService.getWillId();
              if (willId != null && mounted) {
                context.read<WillBloc>().add(DeletePartnerEvent(
                  willId: willId,
                  partnerId: partner.id,
                ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listenWhen: (previous, current) {
        // Always listen to relevant state changes
        return current is WillError || 
               current is WillSuccess ||
               current is FamilyInitialLoaded ||
               current is FormerPartnersLoaded || 
               current is DependentPersonsLoaded || 
               current is PetsLoaded;
      },
      buildWhen: (previous, current) {
        // Rebuild on loading or relevant state changes
        return current is WillLoading || 
               current is WillError || 
               current is FamilyInitialLoaded ||
               current is FormerPartnersLoaded || 
               current is DependentPersonsLoaded || 
               current is PetsLoaded;
      },
      listener: (context, state) {
        if (state is WillSuccess) {
          SnackBarUtils.showSuccess(context, state.message);
        } else if (state is WillError && !_hasShownError) {
          _hasShownError = true;
          SnackBarUtils.showError(context, state.message);
        } else if (state is FamilyInitialLoaded) {
          setState(() {
            _canIncludeFormerPartner = state.familyData.canIncludeFormerPartner ?? false;
            _relationshipStatus = state.familyData.relationshipStatus;
          });
          _hasShownError = false;
        } else if (state is FormerPartnersLoaded) {
          setState(() {
            _formerPartners = state.partners;
          });
          _hasShownError = false; // Reset error flag on successful load
        } else if (state is DependentPersonsLoaded) {
          setState(() {
            _dependents = state.dependents;
          });
          _hasShownError = false; // Reset error flag on successful load
        } else if (state is PetsLoaded) {
          setState(() {
            _pets = state.pets;
          });
          _hasShownError = false; // Reset error flag on successful load
        }
      },
      builder: (context, state) {
        // Note: We don't use WillLoading for the Next button - it's for navigation only
        // The button should always be clickable unless we're in a submitting state

        return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: WillStepsSidebar(currentStep: 3),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: 11,
        title: 'Family',
        showBackButton: true,
        onBack: () {
          context.go(AppRouter.relationshipStatus);
        },
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
                    // Former Partners Section - only show if user selected to include former partners
                    // Partners Section - show if married/de facto OR if former partners enabled
                    if (_relationshipStatus == 'MARRIED' || 
                        _relationshipStatus == 'MARRIED_OR_ENGAGED' ||
                        _relationshipStatus == 'DE_FACTO' ||
                        _relationshipStatus == 'DEFACTO' ||
                        _canIncludeFormerPartner) ...[
                      if (_formerPartners.isEmpty)
                        EmptyStateCard(
                          buttonText: 'Add partners',
                          onAddPressed: _showAddFormerPartnerDialog,
                          placeholderWidget: _buildPlaceholderCards('Partners name', 'Partner'),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._formerPartners.map((partner) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildPersonCard(
                                  name: '${partner.partner.firstName} ${partner.partner.middleName ?? ''} ${partner.partner.lastName}'.trim(),
                                  subtitle: PartnerType.getDisplayName(partner.partner.partnerType),
                                  onEdit: () async {
                                    await context.push(
                                      '/will-creation/add-former-partner',
                                      extra: partner, // Pass typed data for edit
                                    );
                                    if (mounted) _loadFamilyData();
                                  },
                                  onDelete: () => _showDeletePartnerConfirmation(partner),
                                ),
                              )),
                              
                              // Add partners button
                              AppPrimaryButton(
                                text: 'Add partners',
                                icon: Icons.add,
                                onPressed: _showAddFormerPartnerDialog,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],

                    // Dependents Section
                    if (_dependents.isEmpty && _pets.isEmpty)
                      EmptyStateCard(
                        buttonText: 'Add dependants',
                        onAddPressed: _showAddDependentDialog,
                        placeholderWidget: _buildPlaceholderCards('Dependants name', 'Dependant'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_dependents.isNotEmpty) ...[
                              ..._dependents.map((dependent) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildPersonCard(
                                      name: '${dependent.dependent.firstName} ${dependent.dependent.middleName ?? ''} ${dependent.dependent.lastName}'.trim().replaceAll(RegExp(r'\s+'), ' '),
                                      subtitle: '${dependent.dependent.isMinor ? 'Minor' : 'Adult'} - ${FormConstants.getRelationDisplayName(dependent.dependent.relationship)}',
                                      onEdit: () async {
                                        await context.push(
                                          '/will-creation/add-dependent',
                                          extra: dependent, // Pass typed data for edit
                                        );
                                        if (mounted) _loadFamilyData();
                                      },
                                      onDelete: () async {
                                        // TODO: Implement delete dependent
                                        final willId = await _storageService.getWillId();
                                        if (willId != null) {
                                          context.read<WillBloc>().add(DeleteDependentPersonEvent(
                                            willId: willId,
                                            dependentId: dependent.id,
                                          ));
                                        }
                                      },
                                    ),
                                  )),
                            ],
                            if (_pets.isNotEmpty) ...[
                              // if (_dependents.isNotEmpty) const SizedBox(height: 16),
                              ..._pets.map((pet) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildPersonCard(
                                      name: pet.animalName.isNotEmpty ? pet.animalName : FormConstants.getAnimalDisplayName(pet.animalCategory),
                                      subtitle: 'Pet - ${FormConstants.getAnimalDisplayName(pet.animalCategory)}',
                                      onEdit: () async {
                                        await context.push(
                                          '/will-creation/add-dependent',
                                          extra: pet, // Pass typed data for edit
                                        );
                                        if (mounted) _loadFamilyData();
                                      },
                                      onDelete: () async {
                                        final willId = await _storageService.getWillId();
                                        if (willId != null) {
                                          if (pet.caretakerId == null) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Cannot delete pet: Caretaker ID is missing')),
                                              );
                                            }
                                            return;
                                          }
                                          context.read<WillBloc>().add(DeletePetEvent(
                                            willId: willId,
                                            petId: pet.id,
                                            caretakerId: pet.caretakerId!,
                                          ));
                                        }
                                      },
                                    ),
                                  )),
                            ],
                            
                            // Add dependants button
                            AppPrimaryButton(
                              text: 'Add dependants',
                              icon: Icons.add,
                              onPressed: _showAddDependentDialog,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            AppBottomActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      text: 'Previous',
                      onPressed: () {
                        context.go(AppRouter.relationshipStatus);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Next step',
                      onPressed: () {
                        context.push('/will-creation/beneficiaries');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildPersonCard({
    required String name,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundLightGreen,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.avatarInitialsLarge.copyWith(color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.cardName,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.cardSecondary,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
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
                  color: Colors.white,
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
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
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
                color: Colors.white,
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
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
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
                          style: AppTextStyles.cardName.copyWith(color: AppColors.textDark),
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

