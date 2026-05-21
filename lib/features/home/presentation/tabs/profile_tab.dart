import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/data/models/profile_models.dart';
import '../../../profile/data/services/profile_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    final response = await _profileService.getProfile();
    
    if (response.isSuccess && response.data != null) {
      setState(() {
        _userProfile = response.data;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty 
                ? response.message 
                : 'Failed to load profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getInitials() {
    if (_userProfile == null) return '';
    final firstName = _userProfile!.firstName;
    final lastName = _userProfile!.lastName;
    
    String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.pageTitle),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () {
                context.push(AppRouter.notifications);
              },
            ),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            context.go(AppRouter.splash);
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Error banner when profile fails to load
                      if (_userProfile == null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'We are having some issues loading your profile.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loadProfile,
                                child: Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Profile Header with Avatar and Name
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundMintLight4,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Center(
                              child: _userProfile != null
                                  ? Text(
                                      _getInitials(),
                                      style: TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_outline,
                                      color: AppColors.primaryGreen,
                                      size: 40,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userProfile != null
                                      ? _userProfile!.firstName + (_userProfile!.middleName.isNotEmpty ? " ${_userProfile!.middleName}" : "")
                                      : '—',
                                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 24),
                                ),
                                if (_userProfile?.lastName != null && _userProfile!.lastName!.isNotEmpty)
                                  Text(
                                    _userProfile!.lastName!,
                                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 24),
                                  ),
                              ],
                            ),
                          ),
                          if (_userProfile != null)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderGray,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: AppColors.textPrimary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  final result = await context.push(
                                    AppRouter.editProfile,
                                    extra: _userProfile,
                                  );
                                  // Reload profile if edit was successful
                                  if (result == true) {
                                    _loadProfile();
                                  }
                                },
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // User Details
                      _buildDetailRow(
                        'Phone',
                        _userProfile != null && _userProfile!.mobile.isNotEmpty
                            ? _userProfile!.mobile
                            : '—',
                      ),
                      const SizedBox(height: 24),
                      _buildDetailRow('Email', _userProfile?.email ?? '—'),
                      const SizedBox(height: 24),
                      _buildDetailRow(
                        'DOB',
                        (_userProfile?.dob != null && _userProfile!.dob!.isNotEmpty)
                            ? _userProfile!.dob!
                            : '—',
                      ),
                      const SizedBox(height: 24),
                      _buildDetailRow(
                        'Address',
                        _userProfile != null ? _buildAddressString() : '—',
                      ),

                      const SizedBox(height: 40),

                      // Logout Button
                      AppSecondaryButton(
                        text: 'Logout',
                        icon: Icons.logout,
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _buildAddressString() {
    if (_userProfile == null) return 'Not provided';
    
    final address = _userProfile!.address;
    final suburb = _userProfile!.suburb;
    final postcode = _userProfile!.postcode;
    final country = _userProfile!.country;

    if (address == null || address.isEmpty) {
      return 'Not provided';
    }

    final parts = <String>[address];
    
    // Add suburb and postcode on same line if available
    final cityLine = <String>[];
    if (suburb != null && suburb.isNotEmpty) {
      cityLine.add(suburb);
    }
    if (postcode != null && postcode.isNotEmpty) {
      cityLine.add(postcode);
    }
    if (cityLine.isNotEmpty) {
      parts.add(cityLine.join(', '));
    }
    
    // Add country if available
    if (country.isNotEmpty) {
      parts.add(country);
    }
    
    return parts.join('\n');
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Logout', style: AppTextStyles.sectionTitle),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          AppTextButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(dialogContext),
            color: AppColors.textSecondary,
          ),
          AppTextButton(
            text: 'Logout',
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
