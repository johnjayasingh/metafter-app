import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../digital_vault/data/models/vault_models.dart';
import '../../../digital_vault/presentation/cubit/vault_cubit.dart';
import '../../../digital_vault/presentation/cubit/vault_state.dart';
import '../../../digital_vault/presentation/widgets/vault_section_widget.dart';
import '../../../digital_vault/presentation/widgets/vault_item_card.dart';

class DigitalVaultTab extends StatefulWidget {
  const DigitalVaultTab({super.key});

  @override
  State<DigitalVaultTab> createState() => _DigitalVaultTabState();
}

class _DigitalVaultTabState extends State<DigitalVaultTab> {
  final Map<String, bool> _expandedSections = {
    'messages': false,
    'assets': false,
    'liabilities': false,
    'contacts': false,
  };

  @override
  void initState() {
    super.initState();
    context.read<VaultCubit>().loadAll();
  }

  void _toggleSection(String key) {
    setState(() {
      _expandedSections[key] = !(_expandedSections[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('Digital vault', style: AppTextStyles.sectionTitle),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => context.push(AppRouter.notifications),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => context.read<VaultCubit>().loadAll(),
          child: BlocConsumer<VaultCubit, VaultState>(
            listener: (context, state) {
              if (state is VaultOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
                context.read<VaultCubit>().acknowledgeSuccess();
              }
            },
            builder: (context, state) {
              final items = _itemsFromState(state);
              final messages = items
                  .where((i) => i.type == VaultAssetType.message)
                  .toList();
              final assets = items
                  .where((i) => i.type == VaultAssetType.asset)
                  .toList();
              final liabilities = items
                  .where((i) => i.type == VaultAssetType.liability)
                  .toList();
              final contacts = items
                  .where((i) => i.type == VaultAssetType.contact)
                  .toList();

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Securely store important information for your Executor and loved ones.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    _buildMessagesSection(messages),
                    _buildAssetsSection(assets),
                    _buildLiabilitiesSection(liabilities),
                    _buildContactsSection(contacts),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<VaultItem> _itemsFromState(VaultState state) {
    if (state is VaultLoaded) return state.items;
    if (state is VaultOperationLoading) return state.items;
    if (state is VaultOperationSuccess) return state.items;
    if (state is VaultError) return state.items;
    return const [];
  }

  // ─────────────────────────────────────────
  // Personal Messages Section
  // ─────────────────────────────────────────

  Widget _buildMessagesSection(List<VaultItem> messages) {
    return VaultSectionWidget(
      title: 'Personal Messages',
      description:
          'Leave personal messages for your loved ones. These can include text, photos, and videos.',
      icon: Icons.mail_outline,
      isExpanded: _expandedSections['messages'] ?? false,
      onToggle: () => _toggleSection('messages'),
      onAdd: () async {
        final saved = await context.push<bool?>(AppRouter.vaultAddMessage);
        if (saved == true && mounted) {
          context.read<VaultCubit>().loadAll();
        }
      },
      itemCount: messages.length,
      emptyStateText:
          'Click the ADD button to start leaving messages for your loved ones.',
      child: Column(
        children: messages
            .map((m) => VaultItemCard(
                  title: m.messageData.title,
                  subtitle: m.messageData.message.isNotEmpty
                      ? m.messageData.message
                      : '${m.messageData.recipients.length} recipient${m.messageData.recipients.length != 1 ? 's' : ''}',
                  onEdit: () async {
                    final saved = await context.push<bool?>(
                      AppRouter.vaultAddMessage,
                      extra: m,
                    );
                    if (saved == true && mounted) {
                      context.read<VaultCubit>().loadAll();
                    }
                  },
                  onDelete: () => _showDeleteDialog(
                    context,
                    m.messageData.title,
                    () => context.read<VaultCubit>().deleteItem(m.id),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Assets Section
  // ─────────────────────────────────────────

  Widget _buildAssetsSection(List<VaultItem> assets) {
    return VaultSectionWidget(
      title: 'Assets',
      description:
          'Listing your assets helps your Executor locate and manage your estate efficiently.',
      icon: Icons.account_balance_outlined,
      isExpanded: _expandedSections['assets'] ?? false,
      onToggle: () => _toggleSection('assets'),
      onAdd: () async {
        final saved = await context.push<bool?>(AppRouter.vaultAddPhysicalAsset);
        if (saved == true && mounted) {
          context.read<VaultCubit>().loadAll();
        }
      },
      itemCount: assets.length,
      emptyStateText: 'Click the ADD button to start listing your assets.',
      child: Column(
        children: assets
            .map((a) => VaultItemCard(
                  title: a.assetData.name,
                  subtitle: a.assetData.location.isNotEmpty
                      ? a.assetData.location
                      : null,
                  onEdit: () async {
                    final saved = await context.push<bool?>(
                      AppRouter.vaultAddPhysicalAsset,
                      extra: a,
                    );
                    if (saved == true && mounted) {
                      context.read<VaultCubit>().loadAll();
                    }
                  },
                  onDelete: () => _showDeleteDialog(
                    context,
                    a.assetData.name,
                    () => context.read<VaultCubit>().deleteItem(a.id),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Liabilities Section
  // ─────────────────────────────────────────

  Widget _buildLiabilitiesSection(List<VaultItem> liabilities) {
    return VaultSectionWidget(
      title: 'Liabilities',
      description:
          'Your Executor will need to ensure all liabilities are paid before distributing the estate.',
      icon: Icons.receipt_long_outlined,
      isExpanded: _expandedSections['liabilities'] ?? false,
      onToggle: () => _toggleSection('liabilities'),
      onAdd: () async {
        final saved = await context.push<bool?>(AppRouter.vaultAddLiability);
        if (saved == true && mounted) {
          context.read<VaultCubit>().loadAll();
        }
      },
      itemCount: liabilities.length,
      emptyStateText:
          'Click the ADD button on the right to start listing your liabilities.',
      child: Column(
        children: liabilities
            .map((l) => VaultItemCard(
                  title: l.liabilityData.name,
                  subtitle: l.liabilityData.location.isNotEmpty
                      ? l.liabilityData.location
                      : null,
                  onEdit: () async {
                    final saved = await context.push<bool?>(
                      AppRouter.vaultAddLiability,
                      extra: l,
                    );
                    if (saved == true && mounted) {
                      context.read<VaultCubit>().loadAll();
                    }
                  },
                  onDelete: () => _showDeleteDialog(
                    context,
                    l.liabilityData.name,
                    () => context.read<VaultCubit>().deleteItem(l.id),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Important Contacts Section
  // ─────────────────────────────────────────

  Widget _buildContactsSection(List<VaultItem> contacts) {
    return VaultSectionWidget(
      title: 'Important Contacts',
      description:
          'Keeping these details updated helps your Executor execute your wishes and notify key people.',
      icon: Icons.people_outline,
      isExpanded: _expandedSections['contacts'] ?? false,
      onToggle: () => _toggleSection('contacts'),
      onAdd: () async {
        final saved = await context.push<bool?>(AppRouter.vaultAddContact);
        if (saved == true && mounted) {
          context.read<VaultCubit>().loadAll();
        }
      },
      itemCount: contacts.length,
      emptyStateText:
          'Click the ADD button to start adding important contacts.',
      child: Column(
        children: contacts
            .map((c) => VaultItemCard(
                  title: c.contactData.fullName,
                  subtitle: c.contactData.email,
                  onEdit: () async {
                    final saved = await context.push<bool?>(
                      AppRouter.vaultAddContact,
                      extra: c,
                    );
                    if (saved == true && mounted) {
                      context.read<VaultCubit>().loadAll();
                    }
                  },
                  onDelete: () => _showDeleteDialog(
                    context,
                    c.contactData.fullName,
                    () => context.read<VaultCubit>().deleteItem(c.id),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Shared
  // ─────────────────────────────────────────

  void _showDeleteDialog(
      BuildContext context, String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
          'Are you sure you want to delete "$itemName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}
