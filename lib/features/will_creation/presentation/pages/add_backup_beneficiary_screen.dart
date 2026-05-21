import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/models/family_models.dart';
import '../../data/models/will_models.dart';
import '../widgets/radio_option_widgets.dart';

/// Data passed to and returned from the AddBackupBeneficiaryScreen.
class BackupBeneficiaryArgs {
  /// The will ID needed to load persons/charities.
  final String willId;

  /// Display name of the primary beneficiary.
  final String primaryBeneficiaryName;

  /// Pre-existing backup detail to edit (null for new).
  final BackupDetail? existingBackupDetail;

  /// Complete list of beneficiary persons already loaded by the allocation
  /// screen so we don't have to reload them.
  final List<BeneficiaryPersonData> beneficiaries;

  /// Complete list of beneficiary charities already loaded.
  final List<BeneficiaryCharityData> charities;

  /// The will_person_id of the primary beneficiary, so we can exclude them
  /// from the selectable list.
  final int? primaryWillPersonId;

  BackupBeneficiaryArgs({
    required this.willId,
    required this.primaryBeneficiaryName,
    this.existingBackupDetail,
    required this.beneficiaries,
    required this.charities,
    this.primaryWillPersonId,
  });
}

class AddBackupBeneficiaryScreen extends StatefulWidget {
  final BackupBeneficiaryArgs args;

  const AddBackupBeneficiaryScreen({super.key, required this.args});

  @override
  State<AddBackupBeneficiaryScreen> createState() =>
      _AddBackupBeneficiaryScreenState();
}

class _AddBackupBeneficiaryScreenState
    extends State<AddBackupBeneficiaryScreen> {
  AllocationNotifyFor? _selectedOption;

  // For specific beneficiaries selection
  final Set<int> _selectedBeneficiaryIds = {}; // will_person_ids
  final Set<int> _selectedCharityIds = {}; // charity ids

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final existing = widget.args.existingBackupDetail;
    if (existing != null) {
      _selectedOption = existing.allocationNotifyFor;
      for (final b in existing.beneficiaries) {
        if (b.beneficiaryType == BeneficiaryType.beneficiary) {
          _selectedBeneficiaryIds.add(b.beneficiaryId);
        } else if (b.beneficiaryType == BeneficiaryType.charity) {
          _selectedCharityIds.add(b.beneficiaryId);
        }
      }
    }
  }

  bool get _canSave {
    if (_selectedOption == null) return false;
    if (_selectedOption == AllocationNotifyFor.specificBeneficiaries) {
      return _selectedBeneficiaryIds.isNotEmpty;
    }
    if (_selectedOption == AllocationNotifyFor.toCharities) {
      return _selectedCharityIds.isNotEmpty;
    }
    return true;
  }

  void _save() {
    if (!_canSave) return;

    List<BackupBeneficiary> beneficiaries = [];

    if (_selectedOption == AllocationNotifyFor.specificBeneficiaries) {
      for (final id in _selectedBeneficiaryIds) {
        beneficiaries.add(BackupBeneficiary(
          beneficiaryId: id,
          beneficiaryType: BeneficiaryType.beneficiary,
        ));
      }
    } else if (_selectedOption == AllocationNotifyFor.toCharities) {
      for (final id in _selectedCharityIds) {
        beneficiaries.add(BackupBeneficiary(
          beneficiaryId: id,
          beneficiaryType: BeneficiaryType.charity,
        ));
      }
    }

    final backupDetail = BackupDetail(
      allocationNotifyFor: _selectedOption!,
      beneficiaries: beneficiaries,
    );

    context.pop(backupDetail);
  }

  void _removeBackup() {
    // Return a special null marker to indicate removal
    context.pop('__remove__');
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add backup beneficiary',
          style: AppTextStyles.stepTitle,
        ),
        centerTitle: false,
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
                      'Backup beneficiary for ${args.primaryBeneficiaryName}',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add the person who will receive the allocation if so ${args.primaryBeneficiaryName} is deceased at the time of will',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Who would you like to notify?',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 16),

                    // Option 1: To your children
                    RadioListOption(
                      isSelected:
                          _selectedOption == AllocationNotifyFor.myChildren,
                      title: 'To your children',
                      onTap: () {
                        setState(() {
                          _selectedOption = AllocationNotifyFor.myChildren;
                          _selectedBeneficiaryIds.clear();
                          _selectedCharityIds.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Option 2: Equally divide among other beneficiaries
                    RadioListOption(
                      isSelected:
                          _selectedOption == AllocationNotifyFor.divideEqually,
                      title: 'Equally divide among other beneficiaries',
                      onTap: () {
                        setState(() {
                          _selectedOption = AllocationNotifyFor.divideEqually;
                          _selectedBeneficiaryIds.clear();
                          _selectedCharityIds.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Option 3: Specific beneficiaries
                    RadioListOption(
                      isSelected: _selectedOption ==
                          AllocationNotifyFor.specificBeneficiaries,
                      title: 'Specific beneficiaries',
                      onTap: () {
                        setState(() {
                          _selectedOption =
                              AllocationNotifyFor.specificBeneficiaries;
                          _selectedCharityIds.clear();
                        });
                      },
                    ),

                    // Show beneficiary selection when specific beneficiaries is chosen
                    if (_selectedOption ==
                        AllocationNotifyFor.specificBeneficiaries) ...[
                      const SizedBox(height: 16),
                      _buildBeneficiarySelection(),
                    ],

                    const SizedBox(height: 12),

                    // Option 4: To charities
                    RadioListOption(
                      isSelected:
                          _selectedOption == AllocationNotifyFor.toCharities,
                      title: 'To charities',
                      onTap: () {
                        setState(() {
                          _selectedOption = AllocationNotifyFor.toCharities;
                          _selectedBeneficiaryIds.clear();
                        });
                      },
                    ),

                    // Show charity selection when to charities is chosen
                    if (_selectedOption ==
                        AllocationNotifyFor.toCharities) ...[
                      const SizedBox(height: 16),
                      _buildCharitySelection(),
                    ],

                    // Remove backup option when editing
                    if (widget.args.existingBackupDetail != null) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: _removeBackup,
                          child: Text(
                            'Remove backup beneficiary',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.red,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: AppPrimaryButton(
                  text: 'Add backup',
                  onPressed: _canSave ? _save : null,
                  fullWidth: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the beneficiary selection section
  Widget _buildBeneficiarySelection() {
    // Filter out the primary beneficiary from the list
    final availableBeneficiaries = widget.args.beneficiaries.where((b) {
      return b.willPersonId != null &&
          b.willPersonId != widget.args.primaryWillPersonId;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beneficiaries',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 12),

          // Select previously added
          GestureDetector(
            onTap: () => _showBeneficiarySelectionSheet(availableBeneficiaries),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select previously added',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Show selected beneficiaries
          ...availableBeneficiaries
              .where((b) => _selectedBeneficiaryIds.contains(b.willPersonId))
              .map((b) => _buildSelectedPersonTile(b)),

          // Add Beneficiaries button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showBeneficiarySelectionSheet(availableBeneficiaries),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Beneficiaries'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the charity selection section
  Widget _buildCharitySelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Charities and Not-for-Profits',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 12),

          // Select previously added
          GestureDetector(
            onTap: _showCharitySelectionSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select previously added',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Show selected charities
          ...widget.args.charities
              .where((c) {
                final cid = int.tryParse(c.charity.id);
                return cid != null && _selectedCharityIds.contains(cid);
              })
              .map((c) => _buildSelectedCharityTile(c)),

          // Add Charity button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCharitySelectionSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Charity and Not-for-Profit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPersonTile(BeneficiaryPersonData b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLightMint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  b.firstName.isNotEmpty
                      ? b.firstName[0].toUpperCase()
                      : 'B',
                  style: AppTextStyles.avatarInitialsLarge.copyWith(
                    fontSize: 16,
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.fullName,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    FormConstants.getRelationDisplayName(
                        b.relationship ?? 'Beneficiary'),
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBeneficiaryIds.remove(b.willPersonId);
                });
              },
              child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCharityTile(BeneficiaryCharityData c) {
    final charityId = int.tryParse(c.charity.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child:
                    Icon(Icons.favorite, size: 20, color: AppColors.primaryGreen),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.charity.name,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    c.charity.address,
                    style: AppTextStyles.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (charityId != null) _selectedCharityIds.remove(charityId);
                });
              },
              child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showBeneficiarySelectionSheet(
      List<BeneficiaryPersonData> availableBeneficiaries) {
    // Use a local copy of selections for the sheet
    final tempSelected = Set<int>.from(_selectedBeneficiaryIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Beneficiaries',
                            style: AppTextStyles.sectionTitle),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedBeneficiaryIds
                                ..clear()
                                ..addAll(tempSelected);
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Text(
                            'Done',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: availableBeneficiaries.length,
                      itemBuilder: (context, index) {
                        final b = availableBeneficiaries[index];
                        final isSelected =
                            tempSelected.contains(b.willPersonId);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLightMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                b.firstName.isNotEmpty
                                    ? b.firstName[0].toUpperCase()
                                    : 'B',
                                style:
                                    AppTextStyles.avatarInitialsLarge.copyWith(
                                  fontSize: 18,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                            ),
                          ),
                          title: Text(b.fullName,
                              style: AppTextStyles.itemLabel),
                          subtitle: Text(
                            FormConstants.getRelationDisplayName(
                                b.relationship ?? 'Beneficiary'),
                            style: AppTextStyles.subtitle,
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: AppColors.accentGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  tempSelected.add(b.willPersonId!);
                                } else {
                                  tempSelected.remove(b.willPersonId);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                tempSelected.remove(b.willPersonId);
                              } else {
                                if (b.willPersonId != null) {
                                  tempSelected.add(b.willPersonId!);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCharitySelectionSheet() {
    final tempSelected = Set<int>.from(_selectedCharityIds);
    final charities = widget.args.charities;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Charities',
                            style: AppTextStyles.sectionTitle),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCharityIds
                                ..clear()
                                ..addAll(tempSelected);
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Text(
                            'Done',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: charities.length,
                      itemBuilder: (context, index) {
                        final c = charities[index];
                        final charityId = int.tryParse(c.charity.id);
                        final isSelected = charityId != null &&
                            tempSelected.contains(charityId);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLightGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.favorite,
                                  size: 20, color: AppColors.primaryGreen),
                            ),
                          ),
                          title: Text(c.charity.name,
                              style: AppTextStyles.itemLabel),
                          subtitle: Text(
                            c.charity.address,
                            style: AppTextStyles.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: AppColors.accentGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              if (charityId == null) return;
                              setSheetState(() {
                                if (val == true) {
                                  tempSelected.add(charityId);
                                } else {
                                  tempSelected.remove(charityId);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            if (charityId == null) return;
                            setSheetState(() {
                              if (isSelected) {
                                tempSelected.remove(charityId);
                              } else {
                                tempSelected.add(charityId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
