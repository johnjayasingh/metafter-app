import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/family_models.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_event.dart';
import '../bloc/will_state.dart';

class SelectGiftRecipientScreen extends StatefulWidget {
  const SelectGiftRecipientScreen({super.key});

  @override
  State<SelectGiftRecipientScreen> createState() => _SelectGiftRecipientScreenState();
}

class _SelectGiftRecipientScreenState extends State<SelectGiftRecipientScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  List<dynamic> _allPeople = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final willId = await _storageService.getWillId();
    if (willId != null) {
      // Load all previously added people
      context.read<WillBloc>().add(GetDependentPersonsEvent(willId));
      context.read<WillBloc>().add(GetBeneficiaryPersonsEvent(willId));
      context.read<WillBloc>().add(GetFormerPartnersEvent(willId));
    }
  }

  String _getRelationLabel(String relation) {
    switch (relation.toUpperCase()) {
      case 'SON': return 'Son';
      case 'DAUGHTER': return 'Daughter';
      case 'STEP_SON': return 'Step Son';
      case 'STEP_DAUGHTER': return 'Step Daughter';
      case 'NEPHEW': return 'Nephew';
      case 'NIECE': return 'Niece';
      case 'FATHER': return 'Father';
      case 'MOTHER': return 'Mother';
      case 'GUARDIAN': return 'Guardian';
      case 'CARETAKER': return 'Guardian';
      case 'FORMER_PARTNER': return 'Former partner';
      case 'FRIEND': return 'Friend';
      default: return relation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WillBloc, WillState>(
      listener: (context, state) {
        if (state is DependentPersonsLoaded) {
          setState(() {
            // Clear and rebuild the list to avoid duplicates
            _allPeople.removeWhere((person) => person is DependentPersonData);
            _allPeople.addAll(state.dependents);
            _isLoading = false;
          });
        } else if (state is BeneficiaryPersonsLoaded) {
          setState(() {
            // Clear and rebuild the list to avoid duplicates
            _allPeople.removeWhere((person) => person is BeneficiaryPersonData);
            _allPeople.addAll(state.beneficiaries);
            _isLoading = false;
          });
        } else if (state is FormerPartnersLoaded) {
          setState(() {
            // Clear and rebuild the list to avoid duplicates
            _allPeople.removeWhere((person) => person is FormerPartnerData);
            for (var partner in state.partners) {
              _allPeople.add(partner);
            }
            _isLoading = false;
          });
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderGray, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select recipient',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      )
                    : _allPeople.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No previously added people found',
                                  style: AppTextStyles.emptyState,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                AppPrimaryButton(
                                  text: 'Add new recipient',
                                  onPressed: () {
                                    context.pop();
                                    context.push('/will-creation/add-gift-recipient');
                                  },
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                'Select from previously added',
                                style: AppTextStyles.subtitle,
                              ),
                              const SizedBox(height: 16),
                              ..._allPeople.map((person) {
                                String firstName = '';
                                String lastName = '';
                                String relation = '';
                                
                                if (person is DependentPersonData) {
                                  firstName = person.dependent.firstName;
                                  lastName = person.dependent.lastName;
                                  relation = 'Child';
                                } else if (person is BeneficiaryPersonData) {
                                  firstName = person.firstName;
                                  lastName = person.lastName;
                                  relation = _getRelationLabel(person.relationship ?? '');
                                } else if (person is FormerPartnerData) {
                                  firstName = person.partner.firstName;
                                  lastName = person.partner.lastName;
                                  relation = 'Former partner';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildPersonCard(firstName, lastName, relation, person),
                                );
                              }),
                              const SizedBox(height: 16),
                              // Add new recipient button
                              AppSecondaryButton(
                                text: 'Add new recipient',
                                onPressed: () {
                                  context.pop();
                                  context.push('/will-creation/add-gift-recipient');
                                },
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

  Widget _buildPersonCard(String firstName, String lastName, String relation, dynamic personData) {
    return GestureDetector(
      onTap: () {
        // Navigate to add gift recipient screen with selected person data
        context.pop();
        context.push('/will-creation/add-gift-recipient', extra: personData);
      },
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
                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: AppTextStyles.avatarInitials.copyWith(color: AppColors.primaryDarkGreen),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: AppTextStyles.cardName,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relation,
                    style: AppTextStyles.cardSecondary,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
