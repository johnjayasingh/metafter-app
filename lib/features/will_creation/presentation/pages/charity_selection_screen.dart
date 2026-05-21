import 'package:digitalwill/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';

class CharitySelectionScreen extends StatefulWidget {
  const CharitySelectionScreen({super.key});

  @override
  State<CharitySelectionScreen> createState() => _CharitySelectionScreenState();
}

class _CharitySelectionScreenState extends State<CharitySelectionScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  final TextEditingController _searchController = TextEditingController();
  
  List<CharityData> _allCharities = [];
  List<CharityData> _filteredCharities = [];
  Set<String> _selectedCharityIds = {};
  Map<String, CharityData> _selectedCharitiesMap = {}; // Store selected charity data from API
  String _selectedCategory = 'All charities';
  bool _isLoading = true;
  bool _justSavedCharities = false; // Track if we just saved charities

  final List<String> _categories = [
    'All charities',
    'Health',
    'Education',
    'Environment',
    'Animals',
    'Community',
  ];

  @override
  void initState() {
    super.initState();
    _loadCharities();
    _searchController.addListener(_filterCharities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCharities() async {
    setState(() {
      _isLoading = true;
      _justSavedCharities = false; // Reset the save flag when loading
    });
    context.read<WillBloc>().add(const GetCharitiesEvent());
    // Also load already selected charities
    final willId = await _storageService.getWillId();
    if (willId != null && mounted) {
      context.read<WillBloc>().add(GetBeneficiaryCharitiesEvent(willId));
    }
  }

  void _filterCharities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCharities = _allCharities.where((charity) {
        final matchesSearch = charity.name.toLowerCase().contains(query) ||
            charity.address.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  void _toggleCharity(String charityId) {
    setState(() {
      if (_selectedCharityIds.contains(charityId)) {
        _selectedCharityIds.remove(charityId);
      } else {
        _selectedCharityIds.add(charityId);
      }
    });
  }

  Future<void> _saveSelectedCharities() async {
    final willId = await _storageService.getWillId();
    if (willId == null) return;

    setState(() {
      _justSavedCharities = true; // Mark that we initiated a save
    });

    final request = BeneficiaryCharityRequest(
      willId: willId,
      charityIds: _selectedCharityIds.toList(),
    );
    if (mounted) {
      context.read<WillBloc>().add(AddBeneficiaryCharityEvent(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listener: (context, state) {
        if (state is CharitiesLoaded) {
          setState(() {
            _allCharities = state.charities;
            _filteredCharities = state.charities;
            _isLoading = false;
          });
        } else if (state is BeneficiaryCharitiesLoaded) {
          if (_justSavedCharities && mounted) {
            // After saving - navigate to next step (assets)
            setState(() {
              _justSavedCharities = false; // Reset the flag
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.push(AppRouter.listAssets);
              }
            });
          } else {
            // Always restore selected charities from API response (initial load or returning to screen)
            setState(() {
              _selectedCharityIds = state.charities.map((c) => c.charity.id).toSet();
              // Store charity data for display
              _selectedCharitiesMap = {
                for (var c in state.charities) c.charity.id: c.charity
              };
              _isLoading = false;
            });
          }
        } else if (state is WillError) {
          setState(() {
            _isLoading = false;
          });
          // Only show error if message is not empty (skip network errors)
          if (state.message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          drawer: WillStepsSidebar(currentStep: 5),
          appBar: const WillCreationAppBar(
            currentStep: 5,
            totalSteps: 11,
            title: 'Charity and Not-for-Profit',
          ),
          body: Column(
            children: [
              // Top description - not scrollable
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Add any number of people or not-for-profit organisations.\n',
                      ),
                      TextSpan(
                        text: 'You can decide the proportions in the next steps',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Green container with search, dropdown, and scrollable list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your selection will show up here',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search field
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: AppTextStyles.inputText,
                            decoration: InputDecoration(
                              hintText: 'Search charities',
                              hintStyle: AppTextStyles.inputHint,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category dropdown
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                              isExpanded: true,
                              items: _categories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: AppTextStyles.inputText,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Scrollable charities list
                        Expanded(
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                                )
                              : _filteredCharities.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No charities found',
                                        style: AppTextStyles.emptyState,
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _filteredCharities.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final charity = _filteredCharities[index];
                                        final isSelected = _selectedCharityIds.contains(charity.id);
                                        return _buildCharityItem(charity, isSelected);
                                      },
                                    ),
                        ),
                      ],
                    ),
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
                        onPressed: () => context.go(AppRouter.beneficiaries),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Next step',
                        onPressed: () {
                          if (_selectedCharityIds.isEmpty) {
                            context.push(AppRouter.listAssets);
                          } else {
                            _saveSelectedCharities();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharityItem(CharityData charity, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleCharity(charity.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightGreen : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGreen : AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.accentGreen : AppColors.borderGray,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: AppColors.textWhite, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Logo placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: charity.logo != null && charity.logo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        charity.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.volunteer_activism,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.volunteer_activism,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            
            // Charity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    charity.name,
                    style: AppTextStyles.itemLabel,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    charity.address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (charity.abn != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'ABN: ${charity.abn}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
