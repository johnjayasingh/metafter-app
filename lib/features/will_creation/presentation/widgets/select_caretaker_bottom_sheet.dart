import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/family_models.dart';

class CaretakerInfo {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String? dob;
  final String? relationship;

  CaretakerInfo({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    this.dob,
    this.relationship,
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

  // Create from PersonDetails (guardian/caretaker)
  factory CaretakerInfo.fromPersonDetails(String id, PersonDetails person) {
    return CaretakerInfo(
      id: id,
      firstName: person.firstName,
      middleName: person.middleName,
      lastName: person.lastName,
      email: person.email,
      mobile: person.mobile,
      dob: person.dob,
      relationship: person.relationship,
    );
  }
}

class SelectCaretakerBottomSheet extends StatefulWidget {
  final List<CaretakerInfo> caretakers;
  final bool isGuardian; // true for minor guardians, false for pet caretakers
  final String? title;
  final String? subtitle;
  final String? emptyMessage;
  final String? buttonText;
  
  const SelectCaretakerBottomSheet({
    super.key,
    this.caretakers = const [],
    this.isGuardian = false,
    this.title,
    this.subtitle,
    this.emptyMessage,
    this.buttonText,
  });

  @override
  State<SelectCaretakerBottomSheet> createState() => _SelectCaretakerBottomSheetState();
}

class _SelectCaretakerBottomSheetState extends State<SelectCaretakerBottomSheet> {
  CaretakerInfo? _selectedCaretaker;
  
  String get _title => widget.title ?? (widget.isGuardian ? 'Select Guardian (Minor)' : 'Select Guardian (Pet)');
  String get _subtitle => widget.subtitle ?? (widget.isGuardian 
      ? 'Select from previously added guardians' 
      : 'Select from previously added guardians');
  String get _emptyMessage => widget.emptyMessage ?? (widget.isGuardian
      ? 'No guardians added yet.\nPlease add a Guardian (Minor) manually.'
      : 'No guardians added yet.\nPlease add a Guardian (Pet) manually.');
  String get _buttonText => widget.buttonText ?? (widget.isGuardian ? 'Add Guardian (Minor)' : 'Add Guardian (Pet)');

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

          // Caretaker/Guardian List
          if (widget.caretakers.isEmpty)
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
                itemCount: widget.caretakers.length,
                itemBuilder: (context, index) {
                  final caretaker = widget.caretakers[index];
                  final isSelected = _selectedCaretaker?.id == caretaker.id;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCaretaker = caretaker;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.backgroundLightGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.borderLight,
                            child: Text(
                              caretaker.initials,
                              style: AppTextStyles.avatarInitials,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name
                          Expanded(
                            child: Text(
                              caretaker.fullName,
                              style: AppTextStyles.cardName,
                            ),
                          ),
                          // Radio button
                          Container(
                            width: 20,
                            height: 20,
                            decoration: isSelected 
                                ? AppDecorations.radioSelected
                                : AppDecorations.radioUnselected,
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: AppDecorations.radioInner,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderGray, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    text: 'Cancel',
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    text: _buttonText,
                    onPressed: _selectedCaretaker != null
                        ? () => context.pop(_selectedCaretaker)
                        : null,
                    isDisabled: _selectedCaretaker == null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
