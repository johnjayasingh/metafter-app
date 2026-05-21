import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/will_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';

class ListAssetsScreen extends StatefulWidget {
  const ListAssetsScreen({super.key});

  @override
  State<ListAssetsScreen> createState() => _ListAssetsScreenState();
}

class _ListAssetsScreenState extends State<ListAssetsScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  List<WillAsset> _assets = [];
  bool _isLoading = true;
  String? _deletingAssetId;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  void _loadAssets() async {
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetAssetsEvent(willId));
    }
  }

  String _getAssetTypeDisplay(String assetType) {
    switch (assetType.toUpperCase()) {
      case 'PROPERTY':
        return 'Property';
      case 'FINANCIAL':
        return 'Financial assets';
      case 'VEHICLE':
        return 'Vehicle';
      case 'BUSINESS':
        return 'Business';
      case 'INVESTMENT':
        return 'Investment';
      case 'OTHER':
        return 'Other';
      default:
        return assetType;
    }
  }

  Future<void> _showDeleteConfirmation(WillAsset asset, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text(
          'Are you sure you want to remove ${_getAssetTypeDisplay(asset.assetType)} (${asset.institution})?',
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
        _deletingAssetId = '${asset.id}_$index';
      });

      final willId = await _storageService.getWillId();
      if (willId != null && mounted) {
        context.read<WillBloc>().add(
          DeleteAssetEvent(willId: willId, assetId: asset.id),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listener: (context, state) {
        if (state is WillLoading) {
          // Don't reset _deletingAssetId during loading
          return;
        } else if (state is AssetsLoaded) {
          setState(() {
            _assets = state.assets;
            _isLoading = false;
            _deletingAssetId = null;
          });
        } else if (state is WillError) {
          setState(() {
            _isLoading = false;
            _deletingAssetId = null;
          });
          // Only show error if message is not empty (skip network errors)
          if (state.message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
        } else if (state is WillSuccess) {
          // Reload list after successful deletion
          if (state.message.toLowerCase().contains('deleted') ||
              state.message.toLowerCase().contains('removed')) {
            _loadAssets();
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
          drawer: WillStepsSidebar(currentStep: 6),
          appBar: WillCreationAppBar(
            currentStep: 6,
            totalSteps: 11,
            title: 'Assets',
            showBackButton: true,
            onBack: () {
              context.go(AppRouter.charitySelection);
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
                      Text('List your assets', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Listing your assets ensures they\'re passed on the way you intend.',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        // Empty state or Asset list
                        if (_assets.isEmpty)
                          EmptyStateCard(
                            buttonText: 'Add Assets',
                            onAddPressed: () {
                              context.push('/will-creation/add-asset');
                            },
                          )
                        else
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
                                // Asset list
                                ..._assets.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final asset = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: AppDecorations.card,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  asset.assetName?.isNotEmpty == true
                                                      ? asset.assetName!
                                                      : _getAssetTypeDisplay(asset.assetType),
                                                  style:
                                                      AppTextStyles.cardTitle,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  asset.institution,
                                                  style: AppTextStyles
                                                      .cardSecondary,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color:
                                                      AppColors.textSecondary,
                                                  size: 20,
                                                ),
                                                color: AppColors.primaryGreen,
                                                onPressed: () {
                                                  context.push(
                                                    '/will-creation/add-asset',
                                                    extra: asset,
                                                  );
                                                },
                                              ),
                                              //   IconButton(
                                              //     icon:
                                              //         _deletingAssetId ==
                                              //             '${asset.id}_$index'
                                              //         ? const SizedBox(
                                              //             width: 20,
                                              //             height: 20,
                                              //             child: CircularProgressIndicator(
                                              //               strokeWidth: 2,
                                              //               valueColor:
                                              //                   AlwaysStoppedAnimation<
                                              //                     Color
                                              //                   >(
                                              //                     AppColors.error,
                                              //                   ),
                                              //             ),
                                              //           )
                                              //         : const Icon(
                                              //             Icons.delete_outline,
                                              //             color: AppColors
                                              //                 .textSecondary,
                                              //             size: 20,
                                              //           ),
                                              //     onPressed:
                                              //         _deletingAssetId ==
                                              //             '${asset.id}_$index'
                                              //         ? null
                                              //         : () =>
                                              //               _showDeleteConfirmation(
                                              //                 asset,
                                              //                 index,
                                              //               ),
                                              //   ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),

                                // Add Assets button
                                AppPrimaryButton(
                                  text: 'Add Assets',
                                  icon: Icons.add,
                                  onPressed: () {
                                    context.push('/will-creation/add-asset');
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
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
                        onPressed: () => context.go(AppRouter.charitySelection),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Next step',
                        onPressed: () {
                          // Navigate to allocation (new order: Assets → Allocation → Gifts)
                          context.push(AppRouter.assetAllocation);
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
}
