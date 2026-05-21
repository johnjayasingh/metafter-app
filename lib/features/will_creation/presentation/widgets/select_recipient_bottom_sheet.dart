import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RecipientInfo {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String? relation; // e.g., 'SON', 'DAUGHTER', 'FRIEND', 'FORMER_PARTNER'
  final String? displayType; // e.g., 'Child', 'Friend', 'Former partner'
  final int? willPersonId; // Person ID for linking to existing person
  final String? dob; // Date of birth for auto-population
  final String? address; // Address for auto-population

  RecipientInfo({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    this.relation,
    this.displayType,
    this.willPersonId,
    this.dob,
    this.address,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }
}

class SelectRecipientBottomSheet extends StatefulWidget {
  final List<RecipientInfo> recipients;
  final String? title;
  final String? subtitle;
  final String? emptyMessage;
  
  const SelectRecipientBottomSheet({
    super.key,
    this.recipients = const [],
    this.title,
    this.subtitle,
    this.emptyMessage,
  });

  @override
  State<SelectRecipientBottomSheet> createState() => _SelectRecipientBottomSheetState();
}

class _SelectRecipientBottomSheetState extends State<SelectRecipientBottomSheet> {
  String get _title => widget.title ?? 'Select recipient';
  String get _subtitle => widget.subtitle ?? 'Select from previously added beneficiaries';
  String get _emptyMessage => widget.emptyMessage ?? 'No beneficiaries added yet.\nPlease add a beneficiary manually.';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderGray, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        style: AppTextStyles.subtitleSmall,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recipient List
          if (widget.recipients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  _emptyMessage,
                  style: AppTextStyles.emptyState,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: widget.recipients.length,
                itemBuilder: (context, index) {
                  final recipient = widget.recipients[index];
                  
                  return GestureDetector(
                    onTap: () {
                      // Immediately close and return selected recipient
                      context.pop(recipient);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderGray,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.borderLight,
                            child: Text(
                              recipient.initials,
                              style: AppTextStyles.avatarInitials,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name and Type
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipient.fullName,
                                  style: AppTextStyles.cardName,
                                ),
                                if (recipient.displayType != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    recipient.displayType!,
                                    style: AppTextStyles.cardSecondary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Chevron
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Add bottom padding for better spacing
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
