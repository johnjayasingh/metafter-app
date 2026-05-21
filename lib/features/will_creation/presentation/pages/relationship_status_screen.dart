import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/debug_config.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';
import '../widgets/radio_option_widgets.dart';

class RelationshipStatusScreen extends StatefulWidget {
  const RelationshipStatusScreen({super.key});

  @override
  State<RelationshipStatusScreen> createState() =>
      _RelationshipStatusScreenState();
}

class _RelationshipStatusScreenState extends State<RelationshipStatusScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  String? _selectedRelationshipStatus;
  String? _hasBeenMarried;
  String? _includeFormerPartners;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final willId = await _storageService.getWillId();
    debugPrint('🔍 RelationshipStatus: Loading data for willId: $willId');
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetFamilyInitialEvent(willId));
    } else if (DebugConfig.usePrepopulatedData) {
      // Only use debug config if no will ID exists
      setState(() {
        _selectedRelationshipStatus =
            DebugConfig.testRelationshipStatus['relationshipStatus'] as String?;
        _hasBeenMarried =
            DebugConfig.testRelationshipStatus['hasBeenMarried'] as String?;
        _includeFormerPartners =
            DebugConfig.testRelationshipStatus['includeFormerPartners']
                as String?;
      });
    }
  }

  String _mapApiStatusToLocal(String apiStatus) {
    // Map API values to local UI values (uppercase to match radio button values)
    switch (apiStatus.toUpperCase()) {
      case 'SINGLE':
        return 'SINGLE';
      case 'MARRIED':
      case 'MARRIED_OR_ENGAGED':
        return 'MARRIED';
      case 'DE_FACTO':
      case 'DEFACTO':
        return 'DE_FACTO';
      default:
        return apiStatus.toUpperCase();
    }
  }

  Future<void> _saveFamilyData() async {
    // Validate required questions are answered
    if (_hasBeenMarried == null) {
      SnackBarUtils.showWarning(
        context,
        'Please answer whether you have been legally married or in a de facto relationship',
      );
      return;
    }
    
    if (_hasBeenMarried == 'yes' && _includeFormerPartners == null) {
      SnackBarUtils.showWarning(
        context,
        'Please answer whether you want to include former partners in your Will',
      );
      return;
    }
    
    final willId = await _storageService.getWillId();
    if (willId == null) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Will ID not found. Please start over.',
      );
      return;
    }

    final request = FamilyInitialRequest(
      willId: willId,
      relationshipStatus: _selectedRelationshipStatus!,
      hasPreviousRelationship: _hasBeenMarried == 'yes',
      canIncludeFormerPartner: _includeFormerPartners == 'yes',
    );

    if (!mounted) return;
    context.read<WillBloc>().add(CreateFamilyInitialEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listener: (context, state) {
        debugPrint('🔍 RelationshipStatus: State changed to ${state.runtimeType}');
        if (state is FamilyInitialLoaded && !_dataLoaded) {
          final data = state.familyData;
          debugPrint('🔍 RelationshipStatus: Received data - relationshipStatus: ${data.relationshipStatus}, hasPreviousRelationship: ${data.hasPreviousRelationship}');
          
          // Only mark as loaded if we have actual data from the API
          if (data.relationshipStatus != null) {
            _dataLoaded = true;
            setState(() {
              // Map API relationship status to local format
              _selectedRelationshipStatus = _mapApiStatusToLocal(
                data.relationshipStatus!,
              );
              debugPrint('🔍 RelationshipStatus: Mapped to $_selectedRelationshipStatus');
              _hasBeenMarried = data.hasPreviousRelationship == true
                  ? 'yes'
                  : data.hasPreviousRelationship == false
                  ? 'no'
                  : null;
              _includeFormerPartners = data.canIncludeFormerPartner == true
                  ? 'yes'
                  : data.canIncludeFormerPartner == false
                  ? 'no'
                  : null;
            });
          }
        } else if (state is WillSuccess) {
          SnackBarUtils.showSuccess(
            context,
            'Relationship status saved successfully',
          );
          // Navigate directly to family details page
          context.go(AppRouter.familyDetails);
        } else if (state is WillError) {
          SnackBarUtils.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is WillLoading;

        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          drawer: WillStepsSidebar(currentStep: 2),
          appBar: WillCreationAppBar(
            currentStep: 2,
            totalSteps: 11,
            title: 'Relationship Status',
            showBackButton: true,
            onBack: () {
              context.go(AppRouter.basicDetails);
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
                        // Title
                        Text(
                          'Tell us about your relationship status',
                          style: AppTextStyles.pageTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your relationship status helps us structure your Will legally and include the right people.',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 32),

                        // Relationship Status Options
                        RadioListOption(
                          isSelected: _selectedRelationshipStatus == 'SINGLE',
                          title: 'Single',
                          subtitle: 'Never married, separated, divorced, widowed',
                          onTap: () {
                            setState(() {
                              _selectedRelationshipStatus = 'SINGLE';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        RadioListOption(
                          isSelected: _selectedRelationshipStatus == 'MARRIED',
                          title: 'Married or Engaged',
                          subtitle: 'Legally married or committed to marry',
                          onTap: () {
                            setState(() {
                              _selectedRelationshipStatus = 'MARRIED';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        RadioListOption(
                          isSelected: _selectedRelationshipStatus == 'DE_FACTO',
                          title: 'De Facto Relationship',
                          subtitle: 'Living together on a genuine domestic basis — can be same or opposite sex',
                          onTap: () {
                            setState(() {
                              _selectedRelationshipStatus = 'DE_FACTO';
                            });
                          },
                        ),

                        // Conditional questions
                        if (_selectedRelationshipStatus != null) ...[
                          const SizedBox(height: 32),
                          Container(height: 1, color: AppColors.borderGray),
                          const SizedBox(height: 32),

                          // Question 1: About previous relationships
                          // Different question text based on current status
                          Text(
                            _selectedRelationshipStatus == 'SINGLE'
                                ? 'Have you ever been legally married or in a de facto relationship?'
                                : 'Have you had any previous marriages or de facto relationships?',
                            style: AppTextStyles.questionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This helps us understand if there are former partners to consider',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: RadioButtonOption(
                                  isSelected: _hasBeenMarried == 'yes',
                                  label: 'Yes',
                                  onTap: () {
                                    setState(() {
                                      _hasBeenMarried = 'yes';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RadioButtonOption(
                                  isSelected: _hasBeenMarried == 'no',
                                  label: 'No',
                                  onTap: () {
                                    setState(() {
                                      _hasBeenMarried = 'no';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (_hasBeenMarried == 'yes') ...[
                          const SizedBox(height: 32),
                          Container(height: 1, color: AppColors.borderGray),
                          const SizedBox(height: 32),

                          // Question 2: Include former partners
                          Text(
                            'Would you like to include any of your former partners in your Will?',
                            style: AppTextStyles.questionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please provide the individual\'s full legal name to ensure they are easily identifiable',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: RadioButtonOption(
                                  isSelected: _includeFormerPartners == 'yes',
                                  label: 'Yes',
                                  onTap: () {
                                    setState(() {
                                      _includeFormerPartners = 'yes';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RadioButtonOption(
                                  isSelected: _includeFormerPartners == 'no',
                                  label: 'No',
                                  onTap: () {
                                    setState(() {
                                      _includeFormerPartners = 'no';
                                    });
                                  },
                                ),
                              ),
                            ],
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
                            context.go(AppRouter.basicDetails);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Next step',
                          onPressed: _selectedRelationshipStatus != null
                              ? _saveFamilyData
                              : null,
                          isLoading: isLoading,
                        ),
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
  }
}
