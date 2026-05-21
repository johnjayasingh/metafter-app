import 'package:digitalwill/core/theme/app_text_styles.dart';
import 'package:digitalwill/core/theme/app_decorations.dart';
import 'package:digitalwill/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/gift_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';
import '../widgets/radio_option_widgets.dart';

class GiftsQuestionScreen extends StatefulWidget {
  const GiftsQuestionScreen({super.key});

  @override
  State<GiftsQuestionScreen> createState() => _GiftsQuestionScreenState();
}

class _GiftsQuestionScreenState extends State<GiftsQuestionScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  bool? _selectedAnswer;
  List<GiftData> _gifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGiftBeneficiaries();
  }

  Future<void> _loadGiftBeneficiaries() async {
    print('🎁 _loadGiftBeneficiaries called');
    final willId = await _storageService.getWillId();
    print('🎁 willId from storage: $willId');
    if (willId != null && mounted) {
      print('🎁 Dispatching GetGiftsEvent with willId: $willId');
      context.read<WillBloc>().add(GetGiftsEvent(willId));
    } else {
      print('🎁 willId is null or widget not mounted');
    }
  }

  Future<void> _handleSelection(bool leaveGift) async {
    setState(() {
      _selectedAnswer = leaveGift;
    });
  }

  Future<void> _proceedToNext() async {
    if (_selectedAnswer == true) {
      // User wants to leave a gift — navigate to gift beneficiary flow
      if (mounted) {
        context.push(AppRouter.executors);
      }
    } else {
      // No gift — navigate to executors
      if (mounted) {
        context.push(AppRouter.executors);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listener: (context, state) {
        print('🎁 GiftsQuestion State: ${state.runtimeType}');
        if (state is GiftsLoaded) {
          print('🎁 GiftsLoaded received with ${state.gifts.length} gifts');
          setState(() {
            _gifts = state.gifts;
            print('🎁 _gifts updated: ${_gifts.length} gifts');
            for (var gift in _gifts) {
              print('🎁 Gift: type=${gift.giftType}, receiver=${gift.giftReceiver?.firstName} ${gift.giftReceiver?.lastName}');
            }
            // Auto-select Yes if there are gifts, otherwise No
            if (_selectedAnswer == null) {
              _selectedAnswer = _gifts.isNotEmpty;
            }
            _isLoading = false;
          });
        } else if (state is GiftCreated) {
          // Gift created, reload the list
          print('🎁 GiftCreated received, reloading gifts');
          _loadGiftBeneficiaries();
        } else if (state is WillSuccess) {
          // Success state handled, reload the list
          print('🎁 WillSuccess received, reloading gifts');
          _loadGiftBeneficiaries();
        } else if (state is WillError) {
          print('🎁 WillError received: ${state.message}');
          setState(() => _isLoading = false);
          // If 404 error (gift not found), just refresh the list
          if (state.message.contains('404') || state.message.toLowerCase().contains('not found')) {
            _loadGiftBeneficiaries();
          } else if (state.message.trim().isNotEmpty) {
            // Show error for other errors (skip empty messages from network errors)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: WillStepsSidebar(currentStep: 8),
        appBar: WillCreationAppBar(
          currentStep: 8,
          totalSteps: 11,
          title: 'Specific Gifts',
          showBackButton: true,
          onBack: () {
            context.go(AppRouter.assetAllocation);
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
                      Text(
                        'Would you like to leave a specific gift ?',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can choose to give a specific possession or an amount of money.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 32),

                      // Yes and No Options (side by side)
                      Row(
                        children: [
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _selectedAnswer == true,
                              label: 'Yes',
                              onTap: () => _handleSelection(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RadioButtonOption(
                              isSelected: _selectedAnswer == false,
                              label: 'No',
                              onTap: () => _handleSelection(false),
                            ),
                          ),
                        ],
                      ),

                      // Show recipient selection when "Yes" is selected
                      if (_selectedAnswer == true) ...[
                        const SizedBox(height: 32),
                        AppDecorations.divider,
                        const SizedBox(height: 32),

                        Text(
                          'Who are you leaving this to?',
                          style: AppTextStyles.questionTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Specific gifts to underage beneficiaries will only vest when they reach the age of 18. Until that time, they will be held on trust by your executor.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 16),

                        // Main container with light green background
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
                                      'Your selection will show up here',
                                      style: AppTextStyles.subtitle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.push(AppRouter.addGiftRecipient).then((_) {
                                        _loadGiftBeneficiaries();
                                      });
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Specific Gifts'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryDarkGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),

                              if (_isLoading) ...[
                                const SizedBox(height: 8),
                                const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ],

                              // Gift beneficiaries list
                              if (_gifts.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ..._gifts.map((gift) {
                                  final receivers = gift.giftReceivers;
                                  if (receivers.isEmpty) return const SizedBox.shrink();

                                  // Build recipient summary
                                  final first = receivers.first;
                                  final firstNameStr = '${first.firstName} ${first.lastName}'.trim();

                                  // Subtitle: relation of first, plus count
                                  final relationStr = FormConstants.getRelationDisplayName(first.relationship);
                                  final recipientSubtitle = receivers.length == 1
                                      ? relationStr
                                      : '$relationStr · ${receivers.length} recipients';

                                  // Gift value info
                                  String giftInfo = '';
                                  if (gift.giftType == GiftType.money) {
                                    final currency = gift.currency ?? '';
                                    final amount = gift.amount ?? '';
                                    giftInfo = currency.isNotEmpty && amount.isNotEmpty
                                        ? 'Money · $currency $amount'
                                        : 'Money';
                                  } else if (gift.giftType == GiftType.specificItem) {
                                    final desc = gift.description ?? '';
                                    giftInfo = desc.isNotEmpty
                                        ? 'Specific Item · $desc'
                                        : 'Specific Item';
                                  }
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: AppDecorations.card,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: AppColors.backgroundLightGreen,
                                            child: Icon(
                                              gift.giftType == GiftType.money ? Icons.attach_money : Icons.card_giftcard,
                                              color: AppColors.primaryGreen,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (receivers.length == 1)
                                                  Text(
                                                    firstNameStr,
                                                    style: AppTextStyles.cardTitle,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  )
                                                else
                                                  RichText(
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: firstNameStr,
                                                          style: AppTextStyles.cardTitle,
                                                        ),
                                                        TextSpan(
                                                          text: ' + ${receivers.length - 1} more',
                                                          style: AppTextStyles.cardSecondary.copyWith(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  recipientSubtitle,
                                                  style: AppTextStyles.cardSecondary,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                if (giftInfo.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    giftInfo,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: AppColors.primaryGreen,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              context.push(
                                                AppRouter.addGiftRecipient,
                                                extra: gift, // Pass the gift data for editing
                                              ).then((_) {
                                                _loadGiftBeneficiaries();
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
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

              // Bottom buttons
              AppBottomActionBar(
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: () {
                          context.go(AppRouter.assetAllocation);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Next',
                        onPressed: _selectedAnswer != null
                            ? _proceedToNext
                            : null,
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
