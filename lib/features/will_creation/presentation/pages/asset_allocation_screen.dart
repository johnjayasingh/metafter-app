import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/constants/form_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/family_models.dart';
import '../../data/models/will_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';
import '../widgets/percentage_input.dart';
import 'add_backup_beneficiary_screen.dart';

class AssetAllocationScreen extends StatefulWidget {
  const AssetAllocationScreen({super.key});

  @override
  State<AssetAllocationScreen> createState() => _AssetAllocationScreenState();
}

class _AssetAllocationScreenState extends State<AssetAllocationScreen> {
  // Track allocations for each beneficiary/charity
  final Map<String, double> _allocations = {};
  final Map<String, String> _allocationStrings = {};
  final Map<String, bool> _selectedItems = {};
  
  // Track allocation_ids from the GET response (keyed by 'person_<id>' or 'charity_<id>')
  final Map<String, String> _allocationIds = {};
  
  // Separate lists for beneficiaries, charities, and will persons
  List<BeneficiaryPersonData> _beneficiaries = [];
  List<BeneficiaryCharityData> _charities = [];
  List<WillPersonData> _allWillPersons = []; // Raw will persons from API
  List<WillPersonData> _extraWillPersons = []; // Will persons not in beneficiaries
  
  final SecureStorageService _storageService = SecureStorageService();
  String? _willId;
  
  // Track loading states separately to avoid race conditions
  bool _beneficiariesLoaded = false;
  bool _charitiesLoaded = false;
  bool _allocationLoaded = false;
  bool _willPersonsLoaded = false;
  bool _isInitialLoad = true;
  
  // Track divide equally state
  bool _isDivideEquallyActive = false;
  
  // Cached allocation items from GET response
  List<AllocationItem> _cachedAllocationItems = [];

  // Track backup details for each allocation item (keyed by 'person_<id>' or 'charity_<id>')
  final Map<String, BackupDetail> _backupDetails = {};

  @override
  void initState() {
    super.initState();
    _loadBeneficiariesAndCharities();
  }

  Future<void> _loadBeneficiariesAndCharities() async {
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      setState(() {
        _willId = willId;
        _beneficiariesLoaded = false;
        _charitiesLoaded = false;
        _allocationLoaded = false;
        _willPersonsLoaded = false;
        _isInitialLoad = true;
      });
      // Load beneficiaries, charities, will persons, and existing allocations
      context.read<WillBloc>().add(GetBeneficiaryPersonsEvent(willId));
      context.read<WillBloc>().add(GetBeneficiaryCharitiesEvent(willId));
      context.read<WillBloc>().add(GetBeneficiaryAllocationEvent(willId));
      context.read<WillBloc>().add(GetWillPersonsEvent(willId));
    }
  }

  /// Once beneficiaries, charities, AND allocation GET response are all loaded,
  /// merge the allocation data (percentages + allocation_ids) into the local maps.
  void _applyAllocationDataIfReady() {
    if (!_beneficiariesLoaded || !_charitiesLoaded || !_allocationLoaded || !_willPersonsLoaded) return;

    // Step 1 — Recompute _extraWillPersons first so the lookup map below is complete
    final beneficiaryWpIds = <int>{};
    for (final b in _beneficiaries) {
      if (b.willPersonId != null) {
        beneficiaryWpIds.add(b.willPersonId!);
      }
    }
    _extraWillPersons = _allWillPersons
        .where((p) => !beneficiaryWpIds.contains(p.willPersonId))
        .where((p) => p.relationship != null &&
            p.relationship != 'GUARDIAN' &&
            p.relationship != 'BACKUP_GUARDIAN' &&
            p.relationship != 'CARETAKER')
        .toList();

    // Initialize allocations for extra will persons
    for (final wp in _extraWillPersons) {
      final key = 'willperson_${wp.willPersonId}';
      if (!_allocations.containsKey(key)) {
        _allocations[key] = 0.0;
        _selectedItems[key] = false;
      }
    }

    // Step 2 — Build lookup maps: willPersonId -> local key and charityId -> local key
    final willPersonIdToKey = <int, String>{};
    for (final b in _beneficiaries) {
      if (b.willPersonId != null) {
        willPersonIdToKey[b.willPersonId!] = 'person_${b.id}';
      }
    }
    for (final wp in _extraWillPersons) {
      if (!willPersonIdToKey.containsKey(wp.willPersonId)) {
        willPersonIdToKey[wp.willPersonId] = 'willperson_${wp.willPersonId}';
      }
    }

    final charityIdToKey = <int, String>{};
    for (final c in _charities) {
      final cid = int.tryParse(c.charity.id);
      if (cid != null) {
        charityIdToKey[cid] = 'charity_${c.id}';
      }
    }

    // Step 3 — Apply allocation data from GET response
    for (final item in _cachedAllocationItems) {
      String? key;
      if (item.beneficiaryType == BeneficiaryType.beneficiary) {
        key = willPersonIdToKey[item.beneficiaryId];
      } else if (item.beneficiaryType == BeneficiaryType.charity) {
        key = charityIdToKey[item.beneficiaryId];
      }

      if (key != null) {
        final pct = _parsePercentageString(item.percentage);
        _allocations[key] = pct;
        _allocationStrings[key] = item.percentage;
        _selectedItems[key] = pct > 0;
        if (item.allocationId != null) {
          _allocationIds[key] = item.allocationId!;
        }
        if (item.backupDetail != null &&
            (item.backupDetail!.allocationNotifyFor == AllocationNotifyFor.myChildren ||
             item.backupDetail!.allocationNotifyFor == AllocationNotifyFor.divideEqually ||
             item.backupDetail!.beneficiaries.isNotEmpty)) {
          _backupDetails[key] = item.backupDetail!;
        }
      } else {
        print('⚠️ No key found for allocation item: beneficiary_id=${item.beneficiaryId}, type=${item.beneficiaryType}');
        print('   willPersonIdToKey keys: ${willPersonIdToKey.keys.toList()}');
      }
    }

    _isInitialLoad = false;
  }

  double get _totalAllocated {
    return _allocations.values.fold(0.0, (sum, value) => sum + value);
  }

  // Helper to check if total is effectively 100% (within tolerance for floating-point precision)
  bool get _isAllocationValid {
    return (_totalAllocated - 100.0).abs() < 0.1;
  }

  /// Check if all selected non-charity beneficiaries have a backup beneficiary assigned.
  bool get _allBackupsAssigned {
    for (final entry in _allocations.entries) {
      if (entry.value > 0 && (_selectedItems[entry.key] ?? false)) {
        // Only persons (not charities) require backup
        if (entry.key.startsWith('person_') || entry.key.startsWith('willperson_')) {
          if (!_backupDetails.containsKey(entry.key)) return false;
        }
      }
    }
    return true;
  }

  /// List of selected person names that are missing a backup beneficiary.
  List<String> get _missingBackupNames {
    final names = <String>[];
    for (final entry in _allocations.entries) {
      if (entry.value > 0 && (_selectedItems[entry.key] ?? false)) {
        if (entry.key.startsWith('person_') && !_backupDetails.containsKey(entry.key)) {
          final id = entry.key.replaceFirst('person_', '');
          final b = _beneficiaries.where((b) => b.id == id).firstOrNull;
          if (b != null) names.add(b.fullName);
        } else if (entry.key.startsWith('willperson_') && !_backupDetails.containsKey(entry.key)) {
          final wpId = int.tryParse(entry.key.replaceFirst('willperson_', ''));
          final wp = _extraWillPersons.where((w) => w.willPersonId == wpId).firstOrNull;
          if (wp != null) names.add(wp.fullName);
        }
      }
    }
    return names;
  }


  /// Returns the raw display string for the percentage field.
  /// Always uses the stored raw string (e.g. "1/2", "50.0", "10.5").
  /// Returns null when no value has been set yet (shows widget default).
  String? _getDisplayText(String id) {
    final raw = _allocationStrings[id];
    if (raw == null || raw == '0') return null;
    return raw;
  }

  /// Parses a percentage string that may be a plain decimal ("50.0", "10.5")
  /// or a fraction ("1/2", "1/3"). Fractions are interpreted as a fraction
  /// of 100 (e.g. "1/2" → 50.0). Returns 0.0 if the string cannot be parsed.
  double _parsePercentageString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0.0;
    // Plain decimal / integer
    final direct = double.tryParse(trimmed);
    if (direct != null) return direct;
    // Fraction notation "a/b"
    final parts = trimmed.split('/');
    if (parts.length == 2) {
      final numerator = double.tryParse(parts[0].trim());
      final denominator = double.tryParse(parts[1].trim());
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator * 100.0;
      }
    }
    return 0.0;
  }

  void _updateAllocation(String id, double value, {String? rawString}) {
    setState(() {
      // Cap the value at 100%
      final cappedValue = value.clamp(0.0, 100.0);
      _allocations[id] = cappedValue;
      // Preserve the raw string (e.g. "1/2") if provided, otherwise use decimal
      _allocationStrings[id] = rawString ?? cappedValue.toStringAsFixed(2);
      // Automatically select checkbox if allocation > 0
      if (cappedValue > 0) {
        _selectedItems[id] = true;
      } else {
        _selectedItems[id] = false;
      }
      // Reset divide equally state when user manually changes allocation
      _isDivideEquallyActive = false;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      final currentValue = _selectedItems[id] ?? false;
      _selectedItems[id] = !currentValue;

      if (currentValue) {
        // Deselecting — clear this item's allocation
        _allocations[id] = 0.0;
        _allocationStrings[id] = '0';

        if (_isDivideEquallyActive) {
          // Recompute divide equally among the remaining selected items
          final remaining = _allocations.keys
              .where((k) => k != id && (_selectedItems[k] ?? false))
              .toList();
          if (remaining.isEmpty) {
            _isDivideEquallyActive = false;
          } else {
            final count = remaining.length;
            final equalShare = 100.0 / count;
            for (final k in remaining) {
              _allocations[k] = double.parse(equalShare.toStringAsFixed(2));
              _allocationStrings[k] = '1/$count';
            }
          }
        }
      } else {
        // Selecting — if divide equally is active, recompute for all selected items
        if (_isDivideEquallyActive) {
          final selected = _allocations.keys
              .where((k) => _selectedItems[k] ?? false)
              .toList();
          final count = selected.length;
          final equalShare = 100.0 / count;
          for (final k in selected) {
            _allocations[k] = double.parse(equalShare.toStringAsFixed(2));
            _allocationStrings[k] = '1/$count';
          }
        }
      }
    });
  }

  void _divideEqually() {
    // Unfocus any focused input fields first
    FocusScope.of(context).unfocus();
    
    setState(() {
      // If divide equally is already active, just uncheck it (keep current values)
      if (_isDivideEquallyActive) {
        _isDivideEquallyActive = false;
        return;
      }
      
      // Get currently selected items
      final selectedIds = _allocations.keys
          .where((id) => _selectedItems[id] ?? false)
          .toList();
      
      // If no items selected, select all and divide equally
      if (selectedIds.isEmpty) {
        final allItems = _allocations.keys.toList();
        if (allItems.isEmpty) return;
        
        final count = allItems.length;
        final equalShare = 100.0 / count;
        for (final id in allItems) {
          _selectedItems[id] = true;
          _allocations[id] = double.parse(equalShare.toStringAsFixed(2));
          _allocationStrings[id] = '1/$count';
        }
      } else {
        // Divide equally only among selected items
        final count = selectedIds.length;
        final equalShare = 100.0 / count;
        for (final id in selectedIds) {
          _allocations[id] = double.parse(equalShare.toStringAsFixed(2));
          _allocationStrings[id] = '1/$count';
        }
      }
      
      // Mark divide equally as active
      _isDivideEquallyActive = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: WillStepsSidebar(currentStep: 7),
      appBar: WillCreationAppBar(
        title: 'Allocation',
        currentStep: 7,
        totalSteps: 11,
        showBackButton: true,
        onBack: () {
          context.go(AppRouter.giftsQuestion);
        },
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WillBloc, WillState>(
            listener: (context, state) {
              if (state is WillSuccess) {
                // Only navigate if this is an allocation save success
                if (state.message.toLowerCase().contains('allocation')) {
                  // Show success message and navigate to next screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message.isNotEmpty ? state.message : 'Allocation saved successfully'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                  context.push(AppRouter.giftsQuestion);
                }
              } else if (state is WillError) {
                // Only show error if message is not empty (skip network errors)
                if (state.message.trim().isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          BlocListener<WillBloc, WillState>(
            listener: (context, state) {
              if (state is BeneficiaryPersonsLoaded) {
                try {
                  setState(() {
                    _beneficiaries = state.beneficiaries;
                    _beneficiariesLoaded = true;
                    // Initialize default zero allocations for all beneficiaries
                    for (final beneficiary in _beneficiaries) {
                      final key = 'person_${beneficiary.id}';
                      if (!_allocations.containsKey(key)) {
                        _allocations[key] = 0.0;
                        _selectedItems[key] = false;
                      }
                    }
                    _applyAllocationDataIfReady();
                  });
                  print('✅ Loaded ${_beneficiaries.length} beneficiaries');
                } catch (e) {
                  print('❌ Error loading beneficiaries: $e');
                }
              } else if (state is BeneficiaryCharitiesLoaded) {
                try {
                  setState(() {
                    _charities = state.charities;
                    _charitiesLoaded = true;
                    // Initialize default zero allocations for all charities
                    for (final charity in _charities) {
                      final key = 'charity_${charity.id}';
                      if (!_allocations.containsKey(key)) {
                        _allocations[key] = 0.0;
                        _selectedItems[key] = false;
                      }
                    }
                    _applyAllocationDataIfReady();
                  });
                  print('✅ Loaded ${_charities.length} charities');
                } catch (e) {
                  print('❌ Error loading charities: $e');
                }
              } else if (state is BeneficiaryAllocationLoaded) {
                try {
                  setState(() {
                    _allocationLoaded = true;
                    _isDivideEquallyActive = state.allocation.isDivideEqually;

                    // Store the allocation items from the GET response
                    _cachedAllocationItems = state.allocation.allocation;
                    _applyAllocationDataIfReady();
                  });
                  print('✅ Loaded ${state.allocation.allocation.length} allocation items');
                } catch (e) {
                  print('❌ Error loading allocations: $e');
                }
              } else if (state is WillPersonsLoaded) {
                try {
                  setState(() {
                    _allWillPersons = state.persons;
                    _willPersonsLoaded = true;
                    _applyAllocationDataIfReady();
                  });
                  print('✅ Loaded ${state.persons.length} will persons');
                } catch (e) {
                  print('❌ Error loading will persons: $e');
                }
              }
            },
          ),
        ],
        child: BlocBuilder<WillBloc, WillState>(
          builder: (context, state) {
            // Only show loading on initial load before any data is received
            if (_isInitialLoad && state is WillLoading) {
              return const Center(child: CircularProgressIndicator());
            }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Who should inherit your assets?', style: AppTextStyles.pageTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Allocate your assets to beneficiaries below. Date of birth and address are mandatory for every beneficiary. A backup beneficiary must be assigned for each person.',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Validation banner when allocation exceeds 100%
                    if (_totalAllocated > 100.1) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Total allocation cannot exceed 100%. You are over by ${(_totalAllocated - 100).toStringAsFixed(1)}%. Currently allocated: ${_totalAllocated.toStringAsFixed(1)}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Validation banner when allocation is under 100%
                    if (_totalAllocated > 0 && _totalAllocated < 99.9 && (_beneficiaries.isNotEmpty || _extraWillPersons.isNotEmpty || _charities.isNotEmpty)) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.warning,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Total allocation must equal 100%. You need to allocate ${(100 - _totalAllocated).toStringAsFixed(1)}% more. Currently allocated: ${_totalAllocated.toStringAsFixed(1)}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Validation banner when backup beneficiaries are missing
                    if (_isAllocationValid && !_allBackupsAssigned) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Backup beneficiary is required for: ${_missingBackupNames.join(", ")}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Allocation progress section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Progress indicator with circular progress
                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: Stack(
                                  children: [
                                    // Background circle
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.borderGray,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    // Progress arc
                                    if (_totalAllocated > 0)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CustomPaint(
                                          size: const Size(16, 16),
                                          painter: _CircularProgressPainter(
                                            progress: _totalAllocated / 100,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_totalAllocated.toStringAsFixed(1)}% ',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              Text(
                                'allocated',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Divide equally - button with checkbox + text
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _divideEqually,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isDivideEquallyActive 
                                              ? AppColors.primaryGreen 
                                              : AppColors.borderGray,
                                          width: 2,
                                        ),
                                        color: _isDivideEquallyActive 
                                            ? AppColors.primaryGreen 
                                            : AppColors.backgroundWhite,
                                      ),
                                      child: _isDivideEquallyActive
                                          ? const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: AppColors.backgroundWhite,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Divide equally',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textDark,
                                        fontWeight: _isDivideEquallyActive 
                                            ? FontWeight.w600 
                                            : FontWeight.w500
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // const SizedBox(height: 12),
                    // Row(
                    //   children: [
                    //     Icon(
                    //       Icons.swipe,
                    //       size: 16,
                    //       color: AppColors.textSecondary,
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Text(
                    //       'Scroll to review all beneficiaries and charities',
                    //       style: AppTextStyles.bodySmall.copyWith(
                    //         color: AppColors.textSecondary,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Family & beneficiaries section
                      if (_beneficiaries.isNotEmpty || _extraWillPersons.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Family & beneficiaries',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._beneficiaries.map((beneficiary) {
                                try {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildBeneficiaryItem(
                                      id: 'person_${beneficiary.id}',
                                      name: beneficiary.fullName,
                                      subtitle: FormConstants.getRelationDisplayName(beneficiary.relationship ?? 'Beneficiary'),
                                      isSelected: _selectedItems['person_${beneficiary.id}'] ?? false,
                                      allocation: _allocations['person_${beneficiary.id}'] ?? 0.0,
                                      avatarColor: AppColors.primaryLightMint,
                                      avatarText: beneficiary.firstName.isNotEmpty
                                          ? beneficiary.firstName[0].toUpperCase()
                                          : 'B',
                                      displayText: _getDisplayText('person_${beneficiary.id}'),
                                    ),
                                  );
                                } catch (e) {
                                  print('❌ Error rendering beneficiary ${beneficiary.id}: $e');
                                  return const SizedBox.shrink();
                                }
                              }),
                              ..._extraWillPersons.map((wp) {
                                try {
                                  final key = 'willperson_${wp.willPersonId}';
                                  final firstName = wp.firstName ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildBeneficiaryItem(
                                      id: key,
                                      name: wp.fullName,
                                      subtitle: FormConstants.getRelationDisplayName(wp.relationship ?? 'Family'),
                                      isSelected: _selectedItems[key] ?? false,
                                      allocation: _allocations[key] ?? 0.0,
                                      avatarColor: AppColors.primaryLightMint,
                                      avatarText: firstName.isNotEmpty
                                          ? firstName[0].toUpperCase()
                                          : 'P',
                                      displayText: _getDisplayText(key),
                                    ),
                                  );
                                } catch (e) {
                                  print('❌ Error rendering will person ${wp.willPersonId}: $e');
                                  return const SizedBox.shrink();
                                }
                              }),
                            ],
                          ),
                        ),
                      ],
                      
                      // Charities section
                      if (_charities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
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
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._charities.map((charity) {
                                try {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildBeneficiaryItem(
                                      id: 'charity_${charity.id}',
                                      name: charity.charity.name,
                                      subtitle: charity.charity.address,
                                      isSelected: _selectedItems['charity_${charity.id}'] ?? false,
                                      allocation: _allocations['charity_${charity.id}'] ?? 0.0,
                                      avatarColor: AppColors.backgroundLightGreen,
                                      isCharity: true,
                                      charityLogo: charity.charity.logo,
                                      displayText: _getDisplayText('charity_${charity.id}'),
                                    ),
                                  );
                                } catch (e) {
                                  print('❌ Error rendering charity ${charity.id}: $e');
                                  return const SizedBox.shrink();
                                }
                              }),
                            ],
                          ),
                        ),
                      ],
                      
                      // Show message if no beneficiaries or charities have been added
                      if (!_isInitialLoad && _beneficiaries.isEmpty && _extraWillPersons.isEmpty && _charities.isEmpty) ...[
                        const SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.textSecondary.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No beneficiaries or charities added yet',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please add beneficiaries or charities in the previous steps',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom navigation
              AppBottomActionBar(
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          text: 'Previous',
                          onPressed: () => context.go(AppRouter.listAssets),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Next step',
                          onPressed: ((_isAllocationValid && _allBackupsAssigned) || (_totalAllocated == 0 && _beneficiaries.isEmpty && _extraWillPersons.isEmpty && _charities.isEmpty))
                              ? _saveAllocation 
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
          },
        ),
      ),
    );
  }

  String _getBackupLabel(BackupDetail detail) {
    switch (detail.allocationNotifyFor) {
      case AllocationNotifyFor.myChildren:
        return 'Backup: To your children';
      case AllocationNotifyFor.divideEqually:
        return 'Backup: Divided equally among others';
      case AllocationNotifyFor.specificBeneficiaries:
        return 'Backup: Specific beneficiaries';
      case AllocationNotifyFor.toCharities:
        return 'Backup: To charities';
    }
  }

  Widget _buildBeneficiaryItem({
    required String id,
    required String name,
    required String subtitle,
    required bool isSelected,
    required double allocation,
    required Color avatarColor,
    String? avatarText,
    bool isCharity = false,
    String? charityLogo,
    String? displayText,
  }) {
    final hasBackup = _backupDetails.containsKey(id);
    final backupLabel = hasBackup ? _getBackupLabel(_backupDetails[id]!) : 'Add backup beneficiary';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main row: checkbox + avatar + name + percentage
          Row(
            children: [
              // Checkbox with larger tap area
              GestureDetector(
                onTap: () => _toggleSelection(id),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentGreen : AppColors.backgroundWhite,
                      border: Border.all(
                        color: isSelected ? AppColors.accentGreen : AppColors.borderGray,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 12, color: AppColors.backgroundWhite)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              
              // Avatar and Name section - tappable to toggle checkbox
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleSelection(id),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: isCharity && charityLogo != null
                              ? Icon(Icons.favorite, size: 24, color: AppColors.primaryGreen)
                              : Text(
                                  avatarText ?? name[0].toUpperCase(),
                                  style: AppTextStyles.avatarInitialsLarge.copyWith(
                                    fontSize: 20,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Name and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: AppTextStyles.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Percentage control
              PercentageInput(
                value: allocation,
                onChanged: (newValue, {String? rawString}) => _updateAllocation(id, newValue, rawString: rawString),
                displayText: displayText,
              ),
            ],
          ),

          // Backup beneficiary row — only shown when checkbox is checked
          if (!isCharity && isSelected) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openBackupBeneficiaryScreen(id, name),
              child: Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Icon(
                      hasBackup ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 18,
                      color: hasBackup ? AppColors.primaryGreen : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasBackup ? backupLabel : 'Backup beneficiary required',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: hasBackup ? AppColors.primaryGreen : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openBackupBeneficiaryScreen(String id, String name) async {
    if (_willId == null) return;

    // Find the primary beneficiary's will_person_id
    int? primaryWillPersonId;
    if (id.startsWith('person_')) {
      final beneficiaryId = id.replaceFirst('person_', '');
      final idx = _beneficiaries.indexWhere((b) => b.id == beneficiaryId);
      if (idx != -1) {
        primaryWillPersonId = _beneficiaries[idx].willPersonId;
      }
    } else if (id.startsWith('willperson_')) {
      primaryWillPersonId = int.tryParse(id.replaceFirst('willperson_', ''));
    }

    final args = BackupBeneficiaryArgs(
      willId: _willId!,
      primaryBeneficiaryName: name,
      existingBackupDetail: _backupDetails[id],
      beneficiaries: _beneficiaries,
      charities: _charities,
      primaryWillPersonId: primaryWillPersonId,
    );

    final result = await context.push<dynamic>(
      AppRouter.addBackupBeneficiary,
      extra: args,
    );

    if (result != null && mounted) {
      setState(() {
        if (result is BackupDetail) {
          _backupDetails[id] = result;
        } else if (result == '__remove__') {
          _backupDetails.remove(id);
        }
      });
    }
  }

  void _saveAllocation() {
    if (_willId == null) return;
    
    print('💾 Starting allocation save...');
    print('   Will ID: $_willId');
    print('   Total allocated: ${_totalAllocated.toStringAsFixed(2)}%');
    print('   Beneficiaries count: ${_beneficiaries.length}');
    print('   Charities count: ${_charities.length}');
    
    // Build unified allocation list (new API structure)
    final allocationItems = <AllocationItem>[];
    
    // Build a map of allocation keys to charity data for lookup
    final charityMap = <String, BeneficiaryCharityData>{};
    for (final charity in _charities) {
      charityMap['charity_${charity.id}'] = charity;
    }
    
    for (final entry in _allocations.entries) {
      if (entry.value > 0 && (_selectedItems[entry.key] ?? false)) {
        if (entry.key.startsWith('person_')) {
          // Extract beneficiary id from 'person_<id>' and find the corresponding will_person_id
          final beneficiaryId = entry.key.replaceFirst('person_', '');
          final beneficiaryIndex = _beneficiaries.indexWhere((b) => b.id == beneficiaryId);
          
          if (beneficiaryIndex != -1) {
            final beneficiary = _beneficiaries[beneficiaryIndex];
            if (beneficiary.willPersonId != null) {
              print('   ✓ Adding beneficiary: ${beneficiary.firstName} ${beneficiary.lastName}');
              print('     - Will Person ID: ${beneficiary.willPersonId}');
              print('     - Allocation ID: ${_allocationIds[entry.key]}');
              print('     - Percentage: ${_allocationStrings[entry.key] ?? entry.value.toStringAsFixed(2)}%');
              print('     - Has backup: ${_backupDetails.containsKey(entry.key)}');
              
              allocationItems.add(AllocationItem(
                allocationId: _allocationIds[entry.key],
                beneficiaryId: beneficiary.willPersonId!,
                beneficiaryType: BeneficiaryType.beneficiary,
                percentage: _allocationStrings[entry.key] ?? entry.value.toStringAsFixed(2),
                backupDetail: _backupDetails[entry.key],
              ));
            } else {
              print('   ⚠️ Warning: Beneficiary ${beneficiary.id} (${beneficiary.firstName} ${beneficiary.lastName}) has no will_person_id');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${beneficiary.firstName} ${beneficiary.lastName} has no associated person ID'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          } else {
            print('   ❌ Error: Beneficiary not found for id: $beneficiaryId');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Selected beneficiary not found'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else if (entry.key.startsWith('charity_')) {
          final charity = charityMap[entry.key];
          if (charity != null) {
            final charityId = int.tryParse(charity.charity.id) ?? 0;
            print('   ✓ Adding charity: ${charity.charity.name}');
            print('     - Charity ID: $charityId');
            print('     - Allocation ID: ${_allocationIds[entry.key]}');
            print('     - Percentage: ${_allocationStrings[entry.key] ?? entry.value.toStringAsFixed(2)}%');

            allocationItems.add(AllocationItem(
              allocationId: _allocationIds[entry.key],
              beneficiaryId: charityId,
              beneficiaryType: BeneficiaryType.charity,
              percentage: _allocationStrings[entry.key] ?? entry.value.toStringAsFixed(2),
              backupDetail: _backupDetails[entry.key],
            ));
          } else {
            print('   ⚠️ Warning: Charity not found for key: ${entry.key}');
          }
        } else if (entry.key.startsWith('willperson_')) {
          // Extra will person (family/dependent not in beneficiaries list)
          final wpId = int.tryParse(entry.key.replaceFirst('willperson_', ''));
          if (wpId != null) {
            final wpIndex = _extraWillPersons.indexWhere((wp) => wp.willPersonId == wpId);
            if (wpIndex != -1) {
              final wp = _extraWillPersons[wpIndex];
              print('   ✓ Adding will person: ${wp.firstName} ${wp.lastName}');
              print('     - Will Person ID: $wpId');
              print('     - Allocation ID: ${_allocationIds[entry.key]}');
              print('     - Percentage: ${_allocationStrings[entry.key] ?? entry.value.toStringAsFixed(2)}%');
              print('     - Has backup: ${_backupDetails.containsKey(entry.key)}');

              allocationItems.add(AllocationItem(
                allocationId: _allocationIds[entry.key],
                beneficiaryId: wpId,
                beneficiaryType: BeneficiaryType.beneficiary,
                percentage: _allocationStrings[entry.key] ?? entry.value.toStringAsFixed(2),
                backupDetail: _backupDetails[entry.key],
              ));
            }
          }
        }
      }
    }
    
    print('📤 Sending allocation request:');
    print('   - Total allocation items: ${allocationItems.length}');
    print('   - Beneficiaries: ${allocationItems.where((a) => a.beneficiaryType == BeneficiaryType.beneficiary).length}');
    print('   - Charities: ${allocationItems.where((a) => a.beneficiaryType == BeneficiaryType.charity).length}');
    print('   - Divide equally: $_isDivideEquallyActive');
    
    final request = BeneficiaryAllocationRequest(
      willId: _willId!,
      allocation: allocationItems,
      isDivideEqually: _isDivideEquallyActive,
    );
    
    context.read<WillBloc>().add(SetBeneficiaryAllocationEvent(request));
  }
}

// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 2) / 2;

    // Draw arc from top (-90 degrees) clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      2 * 3.14159 * progress, // Sweep angle based on progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
