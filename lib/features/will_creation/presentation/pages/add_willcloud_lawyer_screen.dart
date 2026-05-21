import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../data/models/business_models.dart';
import '../widgets/willcloud_trust_banner.dart';

class AddWillcloudLawyerScreen extends StatefulWidget {
  const AddWillcloudLawyerScreen({super.key});

  @override
  State<AddWillcloudLawyerScreen> createState() =>
      _AddWillcloudLawyerScreenState();
}

class _AddWillcloudLawyerScreenState extends State<AddWillcloudLawyerScreen> {
  late final BusinessRepositoryImpl _businessRepository;
  
  LawFirm? _selectedLawFirm;
  int? _selectedLawyerIndex;
  
  List<LawFirm> _lawFirms = [];
  List<Lawyer> _lawyers = [];
  
  bool _isLoadingFirms = true;
  bool _isLoadingLawyers = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _businessRepository = BusinessRepositoryImpl(apiClient: ApiClient());
    _loadLawFirms();
  }

  Future<void> _loadLawFirms() async {
    setState(() {
      _isLoadingFirms = true;
      _errorMessage = null;
    });

    try {
      final response = await _businessRepository.getLawFirms();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _lawFirms = response.data!;
          _isLoadingFirms = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty 
              ? response.message 
              : 'Failed to load law firms';
          _isLoadingFirms = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading law firms: $e';
        _isLoadingFirms = false;
      });
    }
  }

  Future<void> _loadLawyers(String lawFirmId) async {
    setState(() {
      _isLoadingLawyers = true;
      _errorMessage = null;
      _lawyers = [];
      _selectedLawyerIndex = null;
    });

    try {
      final response = await _businessRepository.getLawyers(lawFirmId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _lawyers = response.data!;
          _isLoadingLawyers = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty 
              ? response.message 
              : 'Failed to load lawyers';
          _isLoadingLawyers = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading lawyers: $e';
        _isLoadingLawyers = false;
      });
    }
  }

  void _onLawFirmSelected(LawFirm? lawFirm) {
    if (lawFirm != null && lawFirm != _selectedLawFirm) {
      setState(() {
        _selectedLawFirm = lawFirm;
      });
      _loadLawyers(lawFirm.id);
    }
  }

  void _addLawyer() {
    if (_selectedLawyerIndex != null && _selectedLawFirm != null) {
      final selectedLawyer = _lawyers[_selectedLawyerIndex!];
      context.pop({
        'lawyer': selectedLawyer,
        'lawFirm': _selectedLawFirm,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => context.pop(),
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
          'Add professional Willcloud lawyer',
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
                      title: 'Willcloud Lawyers',
                      subtitle: 'Trusted by families \n across Australia',
                      height: 160,
                    ),
                    const SizedBox(height: 24),

                    // Law Firm Selection
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
                            'Select Law Firm',
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
                          else if (_lawFirms.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No law firms available',
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
                                  value: _selectedLawFirm,
                                  isExpanded: true,
                                  hint: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Choose a law firm',
                                      style: AppTextStyles.bodyMedium.copyWith(
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
                                  items: _lawFirms.map((firm) {
                                    return DropdownMenuItem<LawFirm>(
                                      value: firm,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              firm.firmName,
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              firm.address,
                                              style: AppTextStyles.bodySmall.copyWith(
                                                fontSize: 12,
                                                color: AppColors.textTertiary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onLawFirmSelected,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    if (_selectedLawFirm != null) ...[
                      const SizedBox(height: 24),

                      // Lawyers list section
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
                            // Section header
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Lawyers at ${_selectedLawFirm!.firmName}',
                                    style: AppTextStyles.sectionTitle.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Loading state
                            if (_isLoadingLawyers)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              )
                            // Empty state
                            else if (_lawyers.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No lawyers available for this firm',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            // Lawyers list
                            else
                              ...List.generate(_lawyers.length, (index) {
                                final lawyer = _lawyers[index];
                                final isSelected = _selectedLawyerIndex == index;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _lawyers.length - 1 ? 12 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedLawyerIndex = index;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundWhite,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryGreen
                                              : AppColors.borderLight,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Radio button
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primaryGreen
                                                    : AppColors.borderLight,
                                                width: 2,
                                              ),
                                              color: AppColors.backgroundWhite,
                                            ),
                                            child: isSelected
                                                ? Center(
                                                    child: Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration:
                                                          const BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: AppColors
                                                                .primaryGreen,
                                                          ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          // Lawyer avatar
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.lightGreen,
                                            child: Text(
                                              lawyer.firstName[0],
                                              style: const TextStyle(
                                                color: AppColors.primaryDarkGreen,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Lawyer details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lawyer.fullName,
                                                  style: AppTextStyles.bodyMedium
                                                      .copyWith(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color:
                                                            AppColors.textDark,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  lawyer.email,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        fontSize: 14,
                                                        color:
                                                            AppColors.textTertiary,
                                                      ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
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
              padding: const EdgeInsets.all(20),
              child: AppPrimaryButton(
                text: 'Add lawyer',
                onPressed: _selectedLawyerIndex != null ? _addLawyer : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
