import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../data/models/business_models.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/legal_review_steps_sidebar.dart';

class AssignLawyerScreen extends StatefulWidget {
  final String willId;

  const AssignLawyerScreen({super.key, required this.willId});

  @override
  State<AssignLawyerScreen> createState() => _AssignLawyerScreenState();
}

class _AssignLawyerScreenState extends State<AssignLawyerScreen> {
  late final BusinessRepositoryImpl _businessRepository;

  String? _selectedOption; // 'willcloud' or 'personal'
  List<AssignedLawyer> _professionalLawyers = [];
  List<AssignedLawyer> _personalLawyers = [];

  bool _isLoading = true;
  bool _isAssigning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _businessRepository = BusinessRepositoryImpl(apiClient: ApiClient());
    _loadAssignedLawyers();
  }

  Future<void> _loadAssignedLawyers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _businessRepository.getAssignedLawyers(
        widget.willId,
      );
      if (response.isSuccess) {
        setState(() {
          _professionalLawyers = response.data?.professionalLawyers ?? [];
          _personalLawyers = response.data?.personalLawyers ?? [];
          _isLoading = false;

          // Set selected option if lawyers exist
          if (_professionalLawyers.isNotEmpty) {
            _selectedOption = 'willcloud';
          } else if (_personalLawyers.isNotEmpty) {
            _selectedOption = 'personal';
          }
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load assigned lawyers';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading assigned lawyers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignProfessionalLawyer(String lawyerId) async {
    setState(() {
      _isAssigning = true;
      _errorMessage = null;
    });

    try {
      final request = AssignProfessionalLawyerRequest(
        willId: widget.willId,
        userId: lawyerId,
      );

      final response = await _businessRepository.assignProfessionalLawyer(
        request,
      );

      if (response.isSuccess) {
        // Reload the lawyers list to get updated data
        await _loadAssignedLawyers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lawyer assigned successfully'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to assign lawyer';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error assigning lawyer: $e';
      });
    } finally {
      setState(() {
        _isAssigning = false;
      });
    }
  }

  void _navigateToWillcloudLawyers() async {
    final result = await context.push(AppRouter.addWillcloudLawyer);

    if (result != null && result is Map<String, dynamic>) {
      final lawyer = result['lawyer'] as Lawyer?;
      if (lawyer != null) {
        await _assignProfessionalLawyer(lawyer.id);
      }
    }
  }

  void _navigateToAddPersonalLawyer({AssignedLawyer? existingLawyer}) async {
    final result = await context.push(
      AppRouter.addPersonalLawyer,
      extra: {'willId': widget.willId, 'existingLawyer': existingLawyer},
    );

    if (result == true) {
      // Reload the lawyers list after successful add/edit
      await _loadAssignedLawyers();
    }
  }

  void _removeLawyer(AssignedLawyer lawyer) {
    // TODO: Implement delete lawyer API when available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remove lawyer feature coming soon'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _editPersonalLawyer(AssignedLawyer lawyer) {
    _navigateToAddPersonalLawyer(existingLawyer: lawyer);
  }

  void _editLawyer() {
    _navigateToWillcloudLawyers();
  }

  void _handleNextStep() {
    if (_selectedOption == 'willcloud') {
      if (_professionalLawyers.isEmpty) {
        // Navigate to add Willcloud lawyer if option selected but no lawyer added
        _navigateToWillcloudLawyers();
      } else {
        // Lawyer selected and ready to proceed
        context.go(
          AppRouter.notificationRecipient,
          extra: {
            'willId': widget.willId,
          },
        );
      }
    } else if (_selectedOption == 'personal') {
      if (_personalLawyers.isEmpty) {
        // Navigate to add personal lawyer
        _navigateToAddPersonalLawyer();
      } else {
        // Personal lawyer selected and ready to proceed
        context.go(
          AppRouter.notificationRecipient,
          extra: {
            'willId': widget.willId,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: LegalReviewStepsSidebar(
        currentStep: 2,
        willId: widget.willId,
      ),
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: 3,
        showStepNumber: true,
        title: 'Assign lawyer',
        skipExitConfirmation: true,
        onExitNavigate: () => context.go(AppRouter.home),
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
                    // Title and description
                    Text(
                      'Assign lawyer',
                      style: AppTextStyles.pageTitle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Have your will reviewed by a qualified lawyer to ensure it\'s legally sound and clearly worded',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Select a lawyer section
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
                            'Select a lawyer',
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Willcloud lawyer option
                          AppRadioListOption(
                            isSelected: _selectedOption == 'willcloud',
                            title: 'Get a professional Willcloud lawyer',
                            onTap: () => setState(() => _selectedOption = 'willcloud'),
                          ),
                          const SizedBox(height: 12),

                          // Show selected lawyer card if lawyer is selected
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            )
                          else if (_professionalLawyers.isNotEmpty)
                            ...List.generate(_professionalLawyers.length, (
                              index,
                            ) {
                              final lawyer = _professionalLawyers[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      index < _professionalLawyers.length - 1
                                      ? 12
                                      : 0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Lawyer avatar
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.lightGreen,
                                        child: Text(
                                          lawyer.firstName[0],
                                          style: const TextStyle(
                                            color: AppColors.primaryDarkGreen,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lawyer.fullName,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              lawyer.lawFirmName,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textTertiary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Edit button
                                      IconButton(
                                        onPressed: _editLawyer,
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                        color: AppColors.textPrimary,
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                      // TODO: Uncomment when delete API is available
                                      // const SizedBox(width: 4),
                                      // // Delete button
                                      // IconButton(
                                      //   onPressed: () => _removeLawyer(lawyer),
                                      //   icon: const Icon(
                                      //     Icons.delete_outline,
                                      //     size: 20,
                                      //   ),
                                      //   color: AppColors.textPrimary,
                                      //   style: IconButton.styleFrom(
                                      //     padding: const EdgeInsets.all(8),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              );
                            })
                          // Show Add button if no lawyer selected but option is selected
                          else if (_selectedOption == 'willcloud')
                            AppPrimaryButton(
                              text: _isAssigning
                                  ? 'Assigning...'
                                  : 'Add Willcloud lawyer',
                              onPressed: _navigateToWillcloudLawyers,
                              isLoading: _isAssigning,
                              icon: Icons.add,
                            ),

                          const SizedBox(height: 16),

                          // Personal lawyer option
                          AppRadioListOption(
                            isSelected: _selectedOption == 'personal',
                            title: 'Add my personal lawyer',
                            onTap: () {
                              setState(() => _selectedOption = 'personal');
                              // Navigate to add personal lawyer if none exist
                              if (_personalLawyers.isEmpty) {
                                _navigateToAddPersonalLawyer();
                              }
                            },
                          ),

                          // Show personal lawyers if they exist (always visible like professional lawyers)
                          const SizedBox(height: 12),
                          if (_personalLawyers.isNotEmpty)
                            ...List.generate(_personalLawyers.length, (index) {
                              final lawyer = _personalLawyers[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < _personalLawyers.length - 1
                                      ? 12
                                      : 0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.lightGreen,
                                        child: Text(
                                          lawyer.firstName[0],
                                          style: const TextStyle(
                                            color: AppColors.primaryDarkGreen,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lawyer.fullName,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              lawyer.lawFirmName.isNotEmpty
                                                  ? lawyer.lawFirmName
                                                  : lawyer.email,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textTertiary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Edit button
                                      IconButton(
                                        onPressed: () =>
                                            _editPersonalLawyer(lawyer),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                        color: AppColors.textPrimary,
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                      // TODO: Uncomment when delete API is available
                                      // const SizedBox(width: 4),
                                      // // Delete button
                                      // IconButton(
                                      //   onPressed: () => _removeLawyer(lawyer),
                                      //   icon: const Icon(
                                      //     Icons.delete_outline,
                                      //     size: 20,
                                      //   ),
                                      //   color: AppColors.textPrimary,
                                      //   style: IconButton.styleFrom(
                                      //     padding: const EdgeInsets.all(8),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              );
                            })
                          // Add personal lawyer button - show only if personal is selected and no lawyers exist
                          else if (_selectedOption == 'personal')
                            AppPrimaryButton(
                              text: 'Add my personal lawyer',
                              onPressed: () => _navigateToAddPersonalLawyer(),
                              icon: Icons.add,
                            ),
                        ],
                      ),
                    ),

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

            // Bottom navigation buttons
            AppBottomActionBar(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      text: 'Previous',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Next step',
                      onPressed: _selectedOption != null ? _handleNextStep : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
