import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../data/models/business_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/willcloud_trust_banner.dart';

class AddWillcloudExecutorScreen extends StatefulWidget {
  // ignore: avoid_positional_boolean_parameters
  final bool? isPrimary;

  const AddWillcloudExecutorScreen({super.key, this.isPrimary});

  @override
  State<AddWillcloudExecutorScreen> createState() =>
      _AddWillcloudExecutorScreenState();
}

class _AddWillcloudExecutorScreenState
    extends State<AddWillcloudExecutorScreen> {
  late final BusinessRepositoryImpl _businessRepository;
  final _secureStorage = SecureStorageService();

  LawFirm? _selectedExecutorFirm;
  int? _selectedExecutorIndex;

  List<LawFirm> _executorFirms = [];
  List<Lawyer> _executors = [];

  bool _isLoadingFirms = true;
  bool _isLoadingExecutors = false;
  bool _isAddingExecutor = false;
  String? _errorMessage;
  String? _willId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _businessRepository = BusinessRepositoryImpl(apiClient: ApiClient());
    _loadUserData();
    _loadExecutorFirms();
  }

  Future<void> _loadUserData() async {
    _willId = await _secureStorage.getWillId();
    _userId = await _secureStorage.getUserId();
  }

  Future<void> _loadExecutorFirms() async {
    setState(() {
      _isLoadingFirms = true;
      _errorMessage = null;
    });

    try {
      final response = await _businessRepository.getLawFirms();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _executorFirms = response.data!;
          _isLoadingFirms = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load executor firms';
          _isLoadingFirms = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading executor firms: $e';
        _isLoadingFirms = false;
      });
    }
  }

  Future<void> _loadExecutors(String executorFirmId) async {
    setState(() {
      _isLoadingExecutors = true;
      _errorMessage = null;
      _executors = [];
      _selectedExecutorIndex = null;
    });

    try {
      final response = await _businessRepository.getLawyers(executorFirmId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _executors = response.data!;
          _isLoadingExecutors = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load executors';
          _isLoadingExecutors = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading executors: $e';
        _isLoadingExecutors = false;
      });
    }
  }

  void _onExecutorFirmSelected(LawFirm? executorFirm) {
    if (executorFirm != null && executorFirm != _selectedExecutorFirm) {
      setState(() {
        _selectedExecutorFirm = executorFirm;
        _selectedExecutorIndex = null;
      });
      _loadExecutors(executorFirm.id);
    }
  }

  Future<void> _addExecutor() async {
    if (_userId == null || _willId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User or Will ID not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedExecutorFirm == null || _executors.isEmpty) {
      return;
    }

    setState(() {
      _isAddingExecutor = true;
      _errorMessage = null;
    });

    // Auto-select the first executor from the firm
    final selectedExecutor = _selectedExecutorIndex != null 
        ? _executors[_selectedExecutorIndex!]
        : _executors.first;

    // Use BLoC to add professional executor via the repository layer
    context.read<WillBloc>().add(
      AddProfessionalExecutorEvent(
        userId: selectedExecutor.id,
        willId: _willId!,
        isPrimary: widget.isPrimary ?? true,
      ),
    );
  }

  void _handleBlocState(BuildContext context, WillState state) {
    if (state is ProfessionalExecutorAdded) {
      if (!mounted) return;
      setState(() {
        _isAddingExecutor = false;
      });

      Navigator.of(context).pop({
        'executorFirm': _selectedExecutorFirm,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professional executor added successfully'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else if (state is WillError) {
      if (!mounted) return;
      setState(() {
        _errorMessage = state.message;
        _isAddingExecutor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listener: _handleBlocState,
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'Add professional Willcloud executor',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner section
                      const WillcloudTrustBanner(
                        imagePath: 'assets/images/willcloud_executor.png',
                        title: 'Willcloud Executors',
                        subtitle: 'Trusted by families \n across Australia',
                        height: 160,
                      ),
                      const SizedBox(height: 24),

                      // Executor Firm Selection
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Executor Firm',
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_isLoadingFirms)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              )
                            else if (_executorFirms.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No executor firms available',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<LawFirm>(
                                    value: _selectedExecutorFirm,
                                    isExpanded: true,
                                    hint: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'Choose an executor firm',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                    icon: const Padding(
                                      padding: EdgeInsets.only(right: 16),
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    items: _executorFirms.map((firm) {
                                      return DropdownMenuItem<LawFirm>(
                                        value: firm,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                firm.firmName,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                firm.address,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _onExecutorFirmSelected,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (_selectedExecutorFirm != null) ...[
                        const SizedBox(height: 24),

                        // Firm summary card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.lightGreen,
                                    child: Text(
                                      _selectedExecutorFirm!.firmName.isNotEmpty
                                          ? _selectedExecutorFirm!.firmName[0].toUpperCase()
                                          : 'F',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedExecutorFirm!.firmName,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedExecutorFirm!.address,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryGreen,
                                    size: 24,
                                  ),
                                ],
                              ),
                              if (_isLoadingExecutors) ...[
                                const SizedBox(height: 12),
                                const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
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
                  text: 'Add executor',
                  onPressed:
                      (_selectedExecutorFirm != null && _executors.isNotEmpty && !_isAddingExecutor)
                      ? _addExecutor
                      : null,
                  isLoading: _isAddingExecutor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
