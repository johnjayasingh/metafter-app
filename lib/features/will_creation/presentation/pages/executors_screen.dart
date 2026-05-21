import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/form_constants.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/willcloud_trust_banner.dart';
import 'add_willcloud_executor_screen.dart';
import 'add_personal_executor_screen.dart';

enum AccessType { afterPassing, specificDateTime, immediately }

class ExecutorsScreen extends StatefulWidget {
  const ExecutorsScreen({super.key});

  @override
  State<ExecutorsScreen> createState() => _ExecutorsScreenState();
}

class _ExecutorsScreenState extends State<ExecutorsScreen> {
  String? _willId;
  final _secureStorage = SecureStorageService();
  List<WillPersonData> _availablePersons = [];
  List<String> _selectedExecutorIds = [];
  List<String> _backupExecutorIds = [];
  List<ExecutorData> _executors = [];
  // ignore: unused_field
  bool _isPersonsLoading = false;

  bool get _hasAnyExecutor =>
    _executors.isNotEmpty || _selectedExecutorIds.isNotEmpty;

  bool get _hasAvailablePersons {
    return _availablePersons.any((p) => 
      !_executors.where((e) => e.isPrimary).any((e) => e.executor.id?.toString() == p.willPersonId.toString())
    );
  }

  bool get _hasAvailablePersonsForBackup {
    return _availablePersons.any((p) =>
      !_executors.any((e) => e.executor.willPersonId == p.willPersonId)
    );
  }

  bool get _hasProfessionalPrimaryExecutor =>
    _executors.any((e) => e.isProfessional && e.isPrimary);

  AccessType _accessType = AccessType.afterPassing;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _understandEarlyAccess = false;

  @override
  void initState() {
    super.initState();
    _loadWillData();
  }

  void _loadExecutors() async {
    if (_willId != null && mounted) {
      context.read<WillBloc>().add(GetExecutorsEvent(_willId!));
    }
  }

  Future<void> _loadWillData() async {
    _willId = await _secureStorage.getWillId();
    if (_willId != null && mounted) {
      setState(() => _isPersonsLoading = true);
      context.read<WillBloc>().add(GetWillPersonsEvent(_willId!));
      context.read<WillBloc>().add(GetExecutorsEvent(_willId!));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: AppColors.textWhite,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: AppColors.textWhite,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveExecutors() {
    if (_willId == null) return;

    // Allocate each selected primary executor
    if (_selectedExecutorIds.isNotEmpty) {
      for (final beneficiaryId in _selectedExecutorIds) {
        final int? parsedId = int.tryParse(beneficiaryId);
        if (parsedId != null) {
          context.read<WillBloc>().add(
            AllocateExecutorEvent(
              ExecutorRequest(willId: _willId!, beneficiaryId: parsedId, isPrimary: true),
            ),
          );
        }
      }
    }

    // Allocate each selected backup executor
    if (_backupExecutorIds.isNotEmpty) {
      for (final beneficiaryId in _backupExecutorIds) {
        final int? parsedId = int.tryParse(beneficiaryId);
        if (parsedId != null) {
          context.read<WillBloc>().add(
            AllocateExecutorEvent(
              ExecutorRequest(willId: _willId!, beneficiaryId: parsedId, isPrimary: false),
            ),
          );
        }
      }
    }

    // Save execution rule
    final ExecutionRuleData ruleData;
    if (_accessType == AccessType.afterPassing) {
      ruleData = ExecutionRuleData(
        ruleName: 'AFTER_PASSING',
        grantAccess: true,
      );
    } else if (_accessType == AccessType.specificDateTime) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      ruleData = ExecutionRuleData(
        ruleName: 'SPECIFIC_DATE',
        ruleValue: dateTime,
        grantAccess: true,
      );
    } else {
      ruleData = ExecutionRuleData(ruleName: 'IMMEDIATELY', grantAccess: true);
    }
    context.read<WillBloc>().add(
      AddExecutionRulesEvent(
        ExecutionRuleRequest(willId: _willId!, rules: ruleData),
      ),
    );

    // Navigate to witness screen
    context.push(AppRouter.witness);
  }

  void _deleteExecutor(ExecutorData executor) {
    final willBloc = context.read<WillBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Executor'),
        content: Text(
          'Are you sure you want to remove ${executor.executor.firstName} ${executor.executor.lastName} as an executor?',
        ),
        actions: [
          AppTextButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          AppTextButton(
            text: 'Delete',
            color: Colors.red,
            onPressed: () {
              Navigator.pop(dialogContext);
              if (_willId != null) {
                willBloc.add(
                  DeallocateExecutorEvent(
                    willId: _willId!,
                    executorId: executor.id,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _editExecutor(ExecutorData executor) {
    print('🔧 _editExecutor called with: ${executor.executor.firstName} ${executor.executor.lastName} (ID: ${executor.executor.id})');
    final executorId = executor.executor.id?.toString() ?? executor.id;
    context.push(
      '${AppRouter.addPersonalExecutor}?executorId=$executorId',
    ).then((_) {
      _loadExecutors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: WillStepsSidebar(currentStep: 9),
      appBar: WillCreationAppBar(
        title: 'Executors',
        currentStep: 9,
        totalSteps: 11,
        showBackButton: true,
        onBack: () {
          context.go(AppRouter.giftsQuestion);
        },
      ),
      body: BlocListener<WillBloc, WillState>(
        listener: (context, state) {
          if (state is WillPersonsLoaded) {
            print('👥 WillPersonsLoaded: ${state.persons.length} persons');
            setState(() {
              _availablePersons = state.persons;
              _isPersonsLoading = false;
            });
            print('👥 Available persons loaded: ${_availablePersons.length}');
          }
          if (state is ExecutorsLoaded) {
            print('🎯 ExecutorsLoaded state received with ${state.executors.length} executors');
            for (var executor in state.executors) {
              print('  - ${executor.executor.firstName} ${executor.executor.lastName} (isProfessional: ${executor.isProfessional}, firmName: ${executor.lawFirmName})');
            }
            setState(() {
              _executors = state.executors;
            });
            print('🎯 After setState, _executors.length = ${_executors.length}');
          }
          if (state is ExecutorAllocated) {
            // Silently reload executors without showing notification
            _loadExecutors();
          }
          if (state is WillSuccess) {
            if (state.message.contains('Executor removed successfully')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Executor removed successfully'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
              _loadExecutors();
            } else if (state.message.contains('Execution rules added successfully')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            }
          }
        },
        child: BlocBuilder<WillBloc, WillState>(
          builder: (context, state) {
            print('🔨 Building UI - _executors.length = ${_executors.length}');
            // Don't show full page loading when just reloading executors list
            final isInitialLoading = state is WillLoading && _executors.isEmpty && _availablePersons.isEmpty;
            if (isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary Executors Section
                        Text(
                          'Primary Executors',
                          style: AppTextStyles.pageTitleWithColor(AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Executor will be responsible for following your instructions and performing the legal and financial actions required.',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 16),

                        // Responsibilities list with background
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildBulletPoint(
                                'Identifying your assets, debts and possessions',
                              ),
                              _buildBulletPoint(
                                'Distributing your estate and gifts!',
                              ),
                              _buildBulletPoint(
                                'Managing related accounting and tax obligations',
                              ),
                              _buildBulletPoint(
                                'Legal and financial paperwork',
                              ),
                              _buildBulletPoint(
                                'Keeping relevant people and organisations informed',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Executor Access Settings
                        Text(
                          'Executor Access Settings',
                          style: AppTextStyles.questionTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose when your executor will be allowed to access this will',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 16),

                        // Access Type Radio Buttons
                        AppRadioListOption(
                          isSelected: _accessType == AccessType.afterPassing,
                          title: 'After my passing (default)',
                          onTap: () => setState(() => _accessType = AccessType.afterPassing),
                        ),
                        const SizedBox(height: 12),
                        AppRadioListOption(
                          isSelected: _accessType == AccessType.specificDateTime,
                          title: 'After a specific date/time',
                          onTap: () => setState(() => _accessType = AccessType.specificDateTime),
                        ),

                        // Date and Time Pickers (shown when specific date/time is selected)
                        if (_accessType == AccessType.specificDateTime) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundWhite,
                              border: Border.all(color: AppColors.borderGray),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select date and time',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Date Picker
                                InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundWhite,
                                      border: Border.all(
                                        color: AppColors.borderGray,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_selectedDate),
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Time Picker
                                InkWell(
                                  onTap: _selectTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundWhite,
                                      border: Border.all(
                                        color: AppColors.borderGray,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        AppRadioListOption(
                          isSelected: _accessType == AccessType.immediately,
                          title: 'Immediately',
                          onTap: () => setState(() => _accessType = AccessType.immediately),
                        ),

                        const SizedBox(height: 16),

                        // Understanding checkbox
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLightGreen.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _understandEarlyAccess,
                                  onChanged: (value) {
                                    setState(() {
                                      _understandEarlyAccess = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.primaryGreen,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: _understandEarlyAccess ? AppColors.primaryGreen : AppColors.textSecondary,
                                    width: 2.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'I understand that granting early access allows the executor to view the contents of my will based on the option I selected.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Add Executors Section
                        Text(
                          'Add Executors',
                          style: AppTextStyles.questionTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please provide the individual\'s full legal name to ensure they are easily identifiable',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 16),

                        // Executors Container with light green background
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Executors heading
                              Text(
                                'Executors',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Select previously added (only show if there are available persons)
                              if (_hasAvailablePersons) ...[                              
                                InkWell(
                                  onTap: () {
                                    _showSelectExecutorBottomSheet();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundWhite,
                                      border: Border.all(
                                        color: AppColors.borderGray,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Select previously added',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Show only personal executors from API
                              if (_executors.where((e) => !e.isProfessional && e.isPrimary).isNotEmpty)
                                ...List.generate(
                                  _executors.where((e) => !e.isProfessional && e.isPrimary).length,
                                  (index) {
                                    final executor = _executors.where((e) => !e.isProfessional && e.isPrimary).toList()[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Container(
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
                                                executor.executor.firstName.isNotEmpty
                                                    ? executor.executor.firstName[0].toUpperCase()
                                                    : '?',
                                                style: AppTextStyles.avatarInitialsLarge.copyWith(
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${executor.executor.firstName} ${executor.executor.lastName}',
                                                    style: AppTextStyles.itemLabel,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    executor.isProfessional && executor.lawFirmName != null
                                                        ? executor.lawFirmName!
                                                        : executor.executor.email,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: executor.isProfessional
                                                          ? AppColors.accentGreen
                                                          : AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Only show edit for personal executors
                                            if (!executor.isProfessional)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit_outlined,
                                                  color: AppColors.textSecondary,
                                                  size: 20,
                                                ),
                                                onPressed: () => _editExecutor(executor),
                                              ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: AppColors.textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: () => _deleteExecutor(executor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              else if (_selectedExecutorIds.isNotEmpty)
                                // Show selected persons as executors
                                ..._availablePersons
                                    .where((p) => _selectedExecutorIds.contains(p.willPersonId.toString()))
                                    .map((person) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
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
                                              (person.firstName?.isNotEmpty == true
                                                  ? person.firstName![0].toUpperCase()
                                                  : '?'),
                                              style: AppTextStyles.avatarInitialsLarge.copyWith(
                                                color: AppColors.primaryGreen,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${person.firstName ?? ''} ${person.lastName ?? ''}'.trim(),
                                                  style: AppTextStyles.itemLabel,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Executor',
                                                  style: AppTextStyles.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              
                              if (_executors.where((e) => !e.isProfessional && e.isPrimary).isEmpty && _selectedExecutorIds.isEmpty)
                                // Empty state using EmptyStateCard
                                EmptyStateCard(
                                  buttonText: 'Add Executor',
                                  onAddPressed: () {
                                      context.push(AppRouter.addPersonalExecutor).then((_) {
                                        _loadExecutors();
                                      });
                                  },
                                  placeholderWidget: Opacity(
                                    opacity: 0.3,
                                    child: Row(
                                      children: [
                                        // Checkbox placeholder
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentGreen.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Avatar placeholder
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.borderGray,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Text placeholder
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Sophie James',
                                                style: AppTextStyles.itemLabel.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Executor',
                                                style: AppTextStyles.subtitle.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Only show standalone button when not in empty state
                              if (!(_executors.where((e) => !e.isProfessional && e.isPrimary).isEmpty && _selectedExecutorIds.isEmpty)) ...[
                                const SizedBox(height: 16),

                                AppPrimaryButton(
                                  text: 'Add Executor',
                                  icon: Icons.add,
                                  onPressed: () {
                                    context.push(AppRouter.addPersonalExecutor).then((_) {
                                      _loadExecutors();
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Willcloud Executors Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Willcloud Executors Section
                              Text(
                                'Willcloud Executors',
                                style: AppTextStyles.questionTitle,
                              ),
                              const SizedBox(height: 16),

                              // Show professional executors
                              if (_executors.where((e) => e.isProfessional && e.isPrimary).isNotEmpty)
                                ...List.generate(
                                  _executors.where((e) => e.isProfessional && e.isPrimary).length,
                                  (index) {
                                    final executor = _executors.where((e) => e.isProfessional && e.isPrimary).toList()[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Container(
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
                                                executor.executor.firstName.isNotEmpty
                                                    ? executor.executor.firstName[0].toUpperCase()
                                                    : '?',
                                                style: AppTextStyles.avatarInitialsLarge.copyWith(
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${executor.executor.firstName} ${executor.executor.lastName}',
                                                    style: AppTextStyles.itemLabel,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    executor.lawFirmName ?? '',
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: AppColors.accentGreen,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: AppColors.textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: () => _deleteExecutor(executor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              const SizedBox(height: 16),

                              // Willcloud Add Executor Button
                              AppPrimaryButton(
                                text: 'Add Executor',
                                icon: Icons.add,
                                onPressed: () {
                                  context.push(AppRouter.addWillcloudExecutor).then((_) {
                                    _loadExecutors();
                                  });
                                },
                              ),

                              const SizedBox(height: 24),

                              // Trust Banner with image
                              const WillcloudTrustBanner(
                                imagePath: 'assets/images/willcloud_executor.png',
                                height: 200,
                                title: 'Willcloud Executors',
                                subtitle: 'Trusted by families \n across Australia',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Add Backup executors (hidden when primary is professional) ─────
                        if (!_hasProfessionalPrimaryExecutor) ...[
                        Text(
                          'Add Backup executors',
                          style: AppTextStyles.questionTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adding a backup executor will ensure that your will be executed in absence of primary executor',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_hasAvailablePersonsForBackup) ...[
                                InkWell(
                                  onTap: _showSelectBackupExecutorBottomSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundWhite,
                                      border: Border.all(color: AppColors.borderGray),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Select previously added',
                                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                                        ),
                                        Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              // Backup personal executors
                              if (_executors.where((e) => !e.isProfessional && !e.isPrimary).isNotEmpty)
                                ...List.generate(
                                  _executors.where((e) => !e.isProfessional && !e.isPrimary).length,
                                  (index) {
                                    final executor = _executors.where((e) => !e.isProfessional && !e.isPrimary).toList()[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Container(
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
                                                executor.executor.firstName.isNotEmpty ? executor.executor.firstName[0].toUpperCase() : '?',
                                                style: AppTextStyles.avatarInitialsLarge.copyWith(color: AppColors.primaryGreen),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('${executor.executor.firstName} ${executor.executor.lastName}', style: AppTextStyles.itemLabel),
                                                  const SizedBox(height: 2),
                                                  Text(executor.executor.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                              onPressed: () => _editExecutor(executor),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                                              onPressed: () => _deleteExecutor(executor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              // Backup professional executors
                              if (_executors.where((e) => e.isProfessional && !e.isPrimary).isNotEmpty)
                                ...List.generate(
                                  _executors.where((e) => e.isProfessional && !e.isPrimary).length,
                                  (index) {
                                    final executor = _executors.where((e) => e.isProfessional && !e.isPrimary).toList()[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Container(
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
                                                executor.executor.firstName.isNotEmpty ? executor.executor.firstName[0].toUpperCase() : '?',
                                                style: AppTextStyles.avatarInitialsLarge.copyWith(color: AppColors.primaryGreen),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('${executor.executor.firstName} ${executor.executor.lastName}', style: AppTextStyles.itemLabel),
                                                  const SizedBox(height: 2),
                                                  Text(executor.lawFirmName ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentGreen)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                                              onPressed: () => _deleteExecutor(executor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 16),
                              const WillcloudTrustBanner(
                                imagePath: 'assets/images/willcloud_executor.png',
                                height: 180,
                                title: 'Add personal or\nprofessional WillCloud\nexecutor as backup',
                                subtitle: 'Trusted by families \n across Australia',
                              ),
                              const SizedBox(height: 16),
                              AppPrimaryButton(
                                text: 'Add Executor',
                                icon: Icons.add,
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddPersonalExecutorScreen(isPrimary: false),
                                    ),
                                  );
                                  _loadExecutors();
                                },
                              ),
                              const SizedBox(height: 12),
                              AppSecondaryButton(
                                text: 'Add WillCloud Executor',
                                icon: Icons.add,
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddWillcloudExecutorScreen(isPrimary: false),
                                    ),
                                  );
                                  _loadExecutors();
                                },
                              ),
                            ],
                          ),
                        ),
                        ], // End of backup executor conditional

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                AppBottomActionBar(
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            text: 'Previous',
                            onPressed: () => context.go(AppRouter.giftsQuestion),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPrimaryButton(
                            text: 'Next step',
                            onPressed: _hasAnyExecutor && _understandEarlyAccess
                                ? _saveExecutors
                                : null,
                            isDisabled: !(_hasAnyExecutor && _understandEarlyAccess),
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

  void _showSelectExecutorBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderGray,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppTextButton(
                          text: 'Cancel',
                          color: AppColors.textSecondary,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Select Executors',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppTextButton(
                          text: 'Done',
                          color: AppColors.primaryGreen,
                          onPressed: () {
                            print('👥 SELECTED EXECUTOR IDs: $_selectedExecutorIds');
                            // Allocate each newly selected executor
                            for (final personIdStr in _selectedExecutorIds) {
                              // Find the person details
                              final person = _availablePersons.firstWhere(
                                (p) => p.willPersonId.toString() == personIdStr,
                                orElse: () => _availablePersons.first,
                              );
                              print('👥 Allocating: ${person.firstName} ${person.lastName} (will_person_id: ${person.willPersonId})');
                              
                              // Create executor details with will_person_id
                              final executorDetails = ExecutorDetails(
                                firstName: person.firstName ?? '',
                                middleName: person.middleName,
                                lastName: person.lastName ?? '',
                                email: person.email ?? '',
                                mobile: person.mobile ?? '+61000000000', // Fallback if no mobile
                                willPersonId: person.willPersonId,
                              );
                              
                              context.read<WillBloc>().add(
                                AllocateExecutorEvent(
                                  ExecutorRequest(
                                    willId: _willId!,
                                    executorDetails: executorDetails,
                                    isPrimary: true,
                                  ),
                                ),
                              );
                            }
                            // Clear selected IDs after allocation
                            setState(() {
                              _selectedExecutorIds.clear();
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final availablePersons = _availablePersons.where((p) {
                          // Filter out persons who are already executors
                          final isAlreadyExecutor = _executors.any((e) => 
                            e.executor.id?.toString() == p.willPersonId.toString()
                          );
                          print('🔍 Person ${p.firstName} ${p.lastName} (will_person_id: ${p.willPersonId}) - isAlreadyExecutor: $isAlreadyExecutor');
                          return !isAlreadyExecutor;
                        }).toList();
                        
                        print('🔍 Total persons: ${_availablePersons.length}, Available: ${availablePersons.length}');
                        
                        if (availablePersons.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'All persons have already been added as executors',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: availablePersons.length,
                          itemBuilder: (context, index) {
                            final person = availablePersons[index];
                            final personIdStr = person.willPersonId.toString();
                            print('👥 LIST ITEM: ${person.firstName} ${person.lastName} (will_person_id: $personIdStr)');
                        final isSelected = _selectedExecutorIds.contains(
                          personIdStr,
                        );

                        return InkWell(
                          onTap: () {
                            print('👥 TAPPED: ${person.firstName} ${person.lastName} (will_person_id: $personIdStr)');
                            setModalState(() {
                              if (isSelected) {
                                _selectedExecutorIds.remove(personIdStr);
                                print('👥 DESELECTED: $personIdStr');
                              } else {
                                _selectedExecutorIds.add(personIdStr);
                                print('👥 SELECTED: $personIdStr');
                              }
                              print('👥 CURRENT SELECTION: $_selectedExecutorIds');
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.backgroundLightGreen
                                  : AppColors.backgroundWhite,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentGreen
                                    : AppColors.borderGray,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentGreen
                                        : AppColors.backgroundWhite,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentGreen
                                          : AppColors.borderGray,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppColors.textWhite,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // Avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (person.firstName?.isNotEmpty == true ? person.firstName![0].toUpperCase() : '?') +
                                          (person.lastName?.isNotEmpty == true ? person.lastName![0].toUpperCase() : ''),
                                      style: AppTextStyles.avatarInitials
                                          .copyWith(
                                            color: AppColors.accentGreen,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Name and relation
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${person.firstName ?? ''} ${person.lastName ?? ''}'.trim(),
                                        style: AppTextStyles.itemLabel,
                                      ),
                                      Text(
                                        person.isMinor == true
                                            ? 'Minor'
                                            : (person.relationship != null && person.relationship!.isNotEmpty
                                                ? FormConstants.getRelationDisplayName(person.relationship!)
                                                : 'Person'),
                                        style: AppTextStyles.subtitle,
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
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectBackupExecutorBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderGray, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppTextButton(
                          text: 'Cancel',
                          color: AppColors.textSecondary,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text('Select Backup Executor', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        AppTextButton(
                          text: 'Done',
                          color: AppColors.primaryGreen,
                          onPressed: () {
                            for (final personIdStr in _backupExecutorIds) {
                              final person = _availablePersons.firstWhere(
                                (p) => p.willPersonId.toString() == personIdStr,
                                orElse: () => _availablePersons.first,
                              );
                              final executorDetails = ExecutorDetails(
                                firstName: person.firstName ?? '',
                                middleName: person.middleName,
                                lastName: person.lastName ?? '',
                                email: person.email ?? '',
                                mobile: person.mobile ?? '+61000000000',
                                willPersonId: person.willPersonId,
                              );
                              context.read<WillBloc>().add(
                                AllocateExecutorEvent(
                                  ExecutorRequest(
                                    willId: _willId!,
                                    executorDetails: executorDetails,
                                    isPrimary: false,
                                  ),
                                ),
                              );
                            }
                            setState(() => _backupExecutorIds.clear());
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final available = _availablePersons.where((p) {
                          return !_executors.any((e) => e.executor.willPersonId == p.willPersonId);
                        }).toList();

                        if (available.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'All persons have already been added as executors',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: available.length,
                          itemBuilder: (context, index) {
                            final person = available[index];
                            final personIdStr = person.willPersonId.toString();
                            final isSelected = _backupExecutorIds.contains(personIdStr);

                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    _backupExecutorIds.remove(personIdStr);
                                  } else {
                                    _backupExecutorIds.add(personIdStr);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.backgroundLightGreen : AppColors.backgroundWhite,
                                  border: Border.all(
                                    color: isSelected ? AppColors.accentGreen : AppColors.borderGray,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.accentGreen : AppColors.backgroundWhite,
                                        border: Border.all(
                                          color: isSelected ? AppColors.accentGreen : AppColors.borderGray,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: isSelected ? Icon(Icons.check, size: 14, color: AppColors.textWhite) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGreen.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (person.firstName?.isNotEmpty == true ? person.firstName![0].toUpperCase() : '') +
                                              (person.lastName?.isNotEmpty == true ? person.lastName![0].toUpperCase() : ''),
                                          style: AppTextStyles.avatarInitials.copyWith(color: AppColors.accentGreen),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${person.firstName ?? ''} ${person.lastName ?? ''}'.trim(),
                                            style: AppTextStyles.itemLabel,
                                          ),
                                          Text(
                                            person.isMinor == true
                                                ? 'Minor'
                                                : (person.relationship != null && person.relationship!.isNotEmpty
                                                    ? FormConstants.getRelationDisplayName(person.relationship!)
                                                    : 'Person'),
                                            style: AppTextStyles.subtitle,
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
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
