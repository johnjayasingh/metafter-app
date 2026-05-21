import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/funeral_flow_data.dart';
import '../../data/models/funeral_models.dart';
import '../../data/services/funeral_service.dart';

class FuneralRecipientsScreen extends StatefulWidget {
  final FuneralFlowData? flowData;

  const FuneralRecipientsScreen({super.key, this.flowData});

  @override
  State<FuneralRecipientsScreen> createState() => _FuneralRecipientsScreenState();
}

class _FuneralRecipientsScreenState extends State<FuneralRecipientsScreen> {
  final FuneralService _funeralService = FuneralService();
  List<WillPerson> _willPeople = [];
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWillPeople();
  }

  Future<void> _loadWillPeople() async {
    try {
      final people = await _funeralService.getWillPeople();
      if (!mounted) return;

      // Pre-select people who are already attendees
      final existingAttendees = widget.flowData?.attendees ?? [];

      setState(() {
        _willPeople = people;
        for (int i = 0; i < people.length; i++) {
          final person = people[i];
          final isExisting = existingAttendees.any((a) =>
              (a.email != null && a.email == person.email) ||
              (a.firstName == person.firstName && a.lastName == person.lastName));
          if (isExisting) {
            _selectedIndices.add(i);
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  Future<void> _handleSave() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one recipient'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert selected will people to attendees
      final attendees = _selectedIndices.map((index) {
        final person = _willPeople[index];
        return FuneralAttendeeModel(
          id: person.id,
          firstName: person.firstName,
          lastName: person.lastName,
          email: person.email,
          mobile: person.phone,
        );
      }).toList();

      // Save attendees to API
      final response = await _funeralService.updateAttendees(attendees);

      setState(() {
        _isSaving = false;
      });

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${attendees.length} recipient(s) saved successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        if (mounted) {
          int popCount = 4;
          for (int i = 0; i < popCount && context.canPop(); i++) {
            context.pop();
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recipients: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _exitAndRefresh() {
    int popCount = 4;
    for (int i = 0; i < popCount && context.canPop(); i++) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLightGreen,
      appBar: WillCreationAppBar(
        currentStep: 4,
        totalSteps: 4,
        title: 'Recipient',
        showBackButton: true,
        showStepNumber: true,
        exitTitle: 'Exit funeral preferences?',
        exitDescription: 'You can save your progress as a draft and continue later, or discard these preferences.',
        exitDiscardButtonText: 'Discard Preferences',
        onExitNavigate: _exitAndRefresh,
        onBack: () {
          context.pop();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Recipient',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add someone who will receive your legacy message. This person will get your personal goodbye, memories, or special instructions after your passing.',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 24),

                          // Will people list with checkboxes
                          if (_willPeople.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundMintLight4,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderGray,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'No family members found. Please add people to your will first.',
                                style: AppTextStyles.subtitle,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ..._willPeople.asMap().entries.map((entry) {
                              final index = entry.key;
                              final person = entry.value;
                              final isSelected = _selectedIndices.contains(index);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => _toggleSelection(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundWhite,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : AppColors.borderGray,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Checkbox
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryGreen
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primaryGreen
                                                  : AppColors.borderGray,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        // Avatar
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              AppColors.backgroundLightGreen,
                                          child: Text(
                                            _getInitials(person.displayName),
                                            style:
                                                AppTextStyles.itemLabel.copyWith(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.w600,
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
                                                person.displayName,
                                                style: AppTextStyles.itemLabel,
                                              ),
                                              if (person.email != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  person.email!,
                                                  style: AppTextStyles
                                                      .cardSecondary
                                                      .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: () {
                          context.pop();
                        },
                        fullWidth: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: _isSaving ? 'Saving...' : 'Save',
                        onPressed: (_selectedIndices.isNotEmpty && !_isSaving)
                            ? _handleSave
                            : null,
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
