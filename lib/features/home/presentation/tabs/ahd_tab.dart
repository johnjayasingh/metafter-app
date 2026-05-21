import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/environment_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../ahd/data/models/ahd_models.dart';
import '../../../ahd/data/services/ahd_service.dart';

class AhdTab extends StatefulWidget {
  const AhdTab({super.key});

  @override
  State<AhdTab> createState() => _AhdTabState();
}

class _AhdTabState extends State<AhdTab> {
  final AhdService _ahdService = AhdService();
  bool _isLoading = true;
  Map<String, dynamic>? _existingAhdData;
  AhdFlowData? _existingFlowData;

  @override
  void initState() {
    super.initState();
    _loadExistingAhd();
  }

  Future<void> _loadExistingAhd() async {
    try {
      final result = await _ahdService.getAhdDetails();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (result.isSuccess && result.data != null) {
          _existingAhdData = result.data;
          _existingFlowData = AhdFlowData.fromApiJson(result.data!);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: SvgPicture.asset(
            'assets/images/logo_icon.svg',
            width: 33,
            height: 25,
          ),
        ),
        title: Text('Advance Health Directive', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
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
              onPressed: () => context.push(AppRouter.notifications),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (EnvironmentConfig.isLocal) _buildDebugPrefillToggle(),
                  _existingAhdData != null
                      ? _buildExistingAhdCard()
                      : _buildCreateAhdCard(),
                ],
              ),
            ),
    );
  }

  /// Returns the AhdFlowData to pass to step 1.
  /// Mock data injection happens in step 1 based on the selected state.
  AhdFlowData _getFlowData() {
    return _existingFlowData ?? const AhdFlowData();
  }

  Widget _buildDebugPrefillToggle() {
    final isEnabled = EnvironmentConfig.useDebugPrefill;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFFFF3CD) : const Color(0xFFE2E3E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? const Color(0xFFFFD54F) : const Color(0xFFCED4DA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bug_report,
            size: 18,
            color: isEnabled ? const Color(0xFF856404) : const Color(0xFF6C757D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mock data prefill',
              style: AppTextStyles.bodySmall.copyWith(
                color: isEnabled ? const Color(0xFF856404) : const Color(0xFF6C757D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            isEnabled ? 'ON' : 'OFF',
            style: AppTextStyles.bodySmall.copyWith(
              color: isEnabled ? const Color(0xFF856404) : const Color(0xFF6C757D),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: isEnabled,
              activeTrackColor: const Color(0xFFFFD54F),
              activeThumbColor: const Color(0xFF856404),
              onChanged: (v) {
                setState(() => EnvironmentConfig.setDebugPrefill(v));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingAhdCard() {
    final data = _existingAhdData!;
    final isRevoked = data['is_acd_revoked'] == true;
    final updatedLabel = _formatDate(
        data['updated_at'] as String? ?? data['created_at'] as String?);
    final state = data['state'] as String?;
    final organDonor = data['is_registered_australian_organ_donor'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Advance Health Directive',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRevoked
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isRevoked
                                  ? AppColors.error
                                  : AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isRevoked ? 'Revoked' : 'Active',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isRevoked
                                  ? AppColors.error
                                  : AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (state != null && state.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'State',
                    value: state.replaceAll('_', ' '),
                  ),
                if (state != null && state.isNotEmpty)
                  const SizedBox(height: 12),

                _buildDetailRow(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Organ donor',
                  value: organDonor ? 'Registered' : 'Not registered',
                ),
                const SizedBox(height: 12),

                if (updatedLabel.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Last updated',
                    value: updatedLabel,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          AppPrimaryButton(
            text: 'Edit preference',
            onPressed: () {
              context.push(
                AppRouter.ahdPersonalDetails,
                extra: _getFlowData(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAhdCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advance Health Directive',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a legally binding document that outlines your healthcare preferences and treatment directions in case you are unable to communicate them yourself.',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/probate_banner.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                AppCancelButton(
                  text: 'Learn more',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            text: 'Create advance health directive',
            onPressed: () {
              context.push(
                AppRouter.ahdPersonalDetails,
                extra: _getFlowData(),
              );
            },
          ),
        ],
      ),
    );
  }
}
