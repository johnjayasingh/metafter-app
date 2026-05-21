import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/gift_models.dart';
import '../../data/models/will_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/radio_option_widgets.dart';
import '../../../../core/theme/app_decorations.dart';
import 'add_gift_receiver_form_screen.dart';

/// Screen for creating / editing a gift.
///
/// The user:
///  1. Picks a gift type (Specific Item or Money) and fills in details.
///  2. Adds one or more recipients via [AddGiftReceiverFormScreen].
///  3. Submits the gift with all receivers in a single API call.
class AddGiftRecipientScreen extends StatefulWidget {
  final dynamic existingData; // GiftData for editing, or null for new gift

  const AddGiftRecipientScreen({super.key, this.existingData});

  @override
  State<AddGiftRecipientScreen> createState() => _AddGiftRecipientScreenState();
}

class _AddGiftRecipientScreenState extends State<AddGiftRecipientScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  bool _isSubmitting = false;

  // Gift details
  GiftType? _giftType;
  String? _selectedAssetId;
  String? _selectedAssetName;
  List<WillAsset> _availableAssets = [];
  final _currencyController = TextEditingController();
  final _amountController = TextEditingController();
  String? _existingGiftId;

  // Recipients list (local, sent in batch on submit)
  List<GiftReceiverDetails> _recipients = [];

  bool get _isEditMode => widget.existingData is GiftData;

  // ---------- Lifecycle ----------

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadAssets();
  }

  void _initializeData() {
    final data = widget.existingData;
    if (data is GiftData) {
      _existingGiftId = data.id;
      _giftType = data.giftType;
      if (data.giftType == GiftType.money) {
        _currencyController.text = data.currency ?? '';
        _amountController.text = data.amount ?? '';
      } else if (data.giftType == GiftType.specificItem &&
          data.assetId != null) {
        _selectedAssetId = data.assetId.toString();
      }
      _recipients = List<GiftReceiverDetails>.from(data.giftReceivers);
    }
  }

  Future<void> _loadAssets() async {
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetAssetsEvent(willId));
    }
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ---------- Recipient CRUD ----------

  Future<void> _addNewRecipient() async {
    final result = await Navigator.push<GiftReceiverDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddGiftReceiverFormScreen(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _recipients.add(result));
    }
  }

  Future<void> _editRecipient(int index) async {
    final result = await Navigator.push<GiftReceiverDetails>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddGiftReceiverFormScreen(existingReceiver: _recipients[index]),
      ),
    );
    if (result != null && mounted) {
      setState(() => _recipients[index] = result);
    }
  }

  void _removeRecipient(int index) {
    setState(() => _recipients.removeAt(index));
  }

  // ---------- Asset selection ----------

  void _showSelectAssetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      Text('Select asset', style: AppTextStyles.sectionTitle),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Select from previously added asset',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ..._availableAssets.map((asset) {
              return RadioListOptionRight(
                isSelected: _selectedAssetId == asset.id,
                title: asset.assetType,
                subtitle:
                    asset.institution.isNotEmpty ? asset.institution : null,
                onTap: () {
                  setState(() {
                    _selectedAssetId = asset.id;
                    _selectedAssetName = asset.assetType;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
            AppPrimaryButton(
              text: 'Add asset',
              icon: Icons.add,
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRouter.addAsset).then((_) => _loadAssets());
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Submit ----------

  Future<void> _submitForm() async {
    if (_giftType == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please select gift type');
      return;
    }
    if (_giftType == GiftType.specificItem && _selectedAssetId == null) {
      SnackBarUtils.showTopSnackBar(context, 'Please select an asset');
      return;
    }
    if (_giftType == GiftType.money) {
      if (_currencyController.text.trim().isEmpty) {
        SnackBarUtils.showTopSnackBar(context, 'Please select currency');
        return;
      }
      if (_amountController.text.trim().isEmpty) {
        SnackBarUtils.showTopSnackBar(context, 'Please enter amount');
        return;
      }
    }
    if (_recipients.isEmpty) {
      SnackBarUtils.showTopSnackBar(
          context, 'Please add at least one recipient');
      return;
    }

    final willId = await _storageService.getWillId();
    if (willId == null) {
      SnackBarUtils.showTopSnackBar(context, 'Will ID not found');
      return;
    }

    setState(() => _isSubmitting = true);

    final request = GiftRequest(
      willId: willId,
      giftId: _isEditMode && _existingGiftId != null
          ? int.tryParse(_existingGiftId!)
          : null,
      giftType: _giftType,
      assetId: _giftType == GiftType.specificItem
          ? int.tryParse(_selectedAssetId ?? '')
          : null,
      description: '',
      currency:
          _giftType == GiftType.money ? _currencyController.text.trim() : null,
      amount:
          _giftType == GiftType.money ? _amountController.text.trim() : null,
      giftReceivers: _recipients,
    );

    context.read<WillBloc>().add(CreateGiftEvent(request));
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listener: (context, state) {
        if (state is AssetsLoaded) {
          setState(() {
            _availableAssets = state.assets;
            if (_selectedAssetId != null && _selectedAssetId!.isNotEmpty) {
              try {
                final asset = state.assets
                    .firstWhere((a) => a.id == _selectedAssetId);
                _selectedAssetName = asset.description.isNotEmpty
                    ? asset.description
                    : 'Asset ${asset.id}';
              } catch (_) {}
            }
          });
        } else if (state is GiftCreated && _isSubmitting) {
          setState(() => _isSubmitting = false);
          SnackBarUtils.showSuccess(
            context,
            _isEditMode
                ? 'Gift updated successfully'
                : 'Gift added successfully',
          );
          context.pop();
        } else if (state is WillSuccess && _isSubmitting) {
          setState(() => _isSubmitting = false);
          SnackBarUtils.showSuccess(
            context,
            state.message.isNotEmpty
                ? state.message
                : (_isEditMode
                    ? 'Gift updated successfully'
                    : 'Gift added successfully'),
          );
          context.pop();
        } else if (state is WillError && _isSubmitting) {
          setState(() => _isSubmitting = false);
          SnackBarUtils.showError(context, 'Error: ${state.message}');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back,
                      color: AppColors.textBrand, size: 20),
                ),
              ),
            ),
          ),
          title: Text(
            _isEditMode ? 'Edit gift' : 'Add gift',
            style: AppTextStyles.questionTitle,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== GIFT SECTION =====
                    Text('What gift would you like to leave?',
                        style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Text(
                      'You can choose to give a specific possession or an amount of money.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Gift type radio
                    Row(
                      children: [
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _giftType == GiftType.specificItem,
                            label: 'Specific Item',
                            onTap: () => setState(
                                () => _giftType = GiftType.specificItem),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RadioButtonOption(
                            isSelected: _giftType == GiftType.money,
                            label: 'Money',
                            onTap: () =>
                                setState(() => _giftType = GiftType.money),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Gift detail fields
                    if (_giftType == GiftType.specificItem) ...[
                      GestureDetector(
                        onTap: _showSelectAssetSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedAssetName ?? 'Select from asset',
                                  style: _selectedAssetName != null
                                      ? AppTextStyles.inputText
                                      : AppTextStyles.inputHint,
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_giftType == GiftType.money) ...[
                      AppDropdownFormField<String>(
                        value: _currencyController.text.isEmpty
                            ? null
                            : _currencyController.text,
                        label: 'Currency',
                        items: const ['AUD', 'USD', 'EUR', 'GBP'],
                        displayName: (value) {
                          switch (value) {
                            case 'AUD':
                              return 'AUD - Australian Dollar';
                            case 'USD':
                              return 'USD - US Dollar';
                            case 'EUR':
                              return 'EUR - Euro';
                            case 'GBP':
                              return 'GBP - British Pound';
                            default:
                              return value;
                          }
                        },
                        onChanged: (value) {
                          if (value != null) _currencyController.text = value;
                        },
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _amountController,
                        label: 'Amount',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null) {
                            return 'Please enter a valid amount';
                          }
                          if (amount <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],

                    // ===== RECIPIENTS SECTION =====
                    if (_giftType != null) ...[
                      const SizedBox(height: 32),
                      Divider(color: AppColors.borderLight),
                      const SizedBox(height: 24),

                      Text('Who are you leaving this to?',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Specific gifts to underage recipients will only vest when they reach the age of 18. '
                        'Until that time, they will be held on trust by your executor.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Recipient container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppDecorations.cardLightGreen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _recipients.isEmpty
                                        ? 'Your selection will show up here'
                                        : '${_recipients.length} recipient${_recipients.length > 1 ? 's' : ''} added',
                                    style: AppTextStyles.subtitle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _addNewRecipient,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Recipient'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primaryDarkGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),

                            // Recipient cards
                            if (_recipients.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ..._recipients.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final r = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: AppDecorations.card,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              AppColors.backgroundLightGreen,
                                          child: Text(
                                            '${r.firstName.isNotEmpty ? r.firstName[0].toUpperCase() : '?'}'
                                            '${r.lastName.isNotEmpty ? r.lastName[0].toUpperCase() : ''}',
                                            style: AppTextStyles
                                                .avatarInitialsLarge
                                                .copyWith(
                                                    color:
                                                        AppColors.primaryGreen),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${r.firstName} ${r.lastName}'
                                                    .trim(),
                                                style:
                                                    AppTextStyles.cardTitle,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                FormConstants
                                                    .getRelationDisplayName(
                                                        r.relationship),
                                                style: AppTextStyles
                                                    .cardSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.textSecondary,
                                              size: 20),
                                          onPressed: () =>
                                              _editRecipient(idx),
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20),
                                          onPressed: () =>
                                              _removeRecipient(idx),
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom button
            AppBottomActionBar(
              child: AppPrimaryButton(
                text: _isEditMode ? 'Update gift' : 'Add gift',
                onPressed: _submitForm,
                isLoading: _isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
