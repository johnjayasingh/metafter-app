import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/environment_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../poa/data/models/poa_models.dart';
import '../../../poa/data/services/poa_service.dart';
import '../../../profile/data/models/profile_models.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../../core/constants/form_constants.dart';

class PoaTab extends StatefulWidget {
  const PoaTab({super.key});

  @override
  State<PoaTab> createState() => _PoaTabState();
}

class _PoaTabState extends State<PoaTab> {
  final PoaService _poaService = PoaService();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  PoaFlowData? _existingFlowData;
  PoaData? _existingPoaData;

  @override
  void initState() {
    super.initState();
    _loadExistingPoa();
  }

  Future<void> _loadExistingPoa() async {
    try {
      final results = await Future.wait([
        _poaService.getPoaDetails(),
        _profileService.getProfile(),
        _poaService.getPoaNotifications(),
        _poaService.getAttorneysForPoa(),
      ]);

      final poaResult = results[0] as PoaResponse<PoaData>;
      final profileResult = results[1] as ProfileResponse;
      final notifications = results[2] as List<Map<String, dynamic>>;
      final allAttorneys = results[3] as List<PoaPersonData>;

      print('📋 POA NOTIFICATIONS RAW: $notifications');
      print('📋 POA ATTORNEYS COUNT: ${allAttorneys.length}');

      if (!mounted) return;

      final profile = profileResult.isSuccess ? profileResult.data : null;

      setState(() {
        _isLoading = false;
        if (poaResult.isSuccess && poaResult.data != null) {
          _existingPoaData = poaResult.data;
          var flowData = PoaFlowData.fromPoaData(poaResult.data!);
          flowData = _applyNotifications(flowData, notifications, allAttorneys);
          flowData = _applyAttorneys(flowData, allAttorneys);
          flowData = _applyProfile(flowData, profile);
          // VIC commencement is stored in 'commencement' field, not 'financial_commencement'
          if (flowData.state?.toLowerCase() == 'victoria' && poaResult.data!.commencement != null) {
            flowData = flowData.copyWith(commencementType: poaResult.data!.commencement);
          }
          _existingFlowData = flowData;
          print('\ud83d\udd34 [PoaTab] _existingFlowData SET: notifyWho=${flowData.notifyWho}, notifyWhatOption=${flowData.notifyWhatOption}, notifyOther=${flowData.notifyWhatOtherText}, notifyInstr=${flowData.notifyInstructions}');
        } else {
          _existingFlowData = _applyProfile(const PoaFlowData(), profile);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Applies notification data from GET /user/poa-notification onto PoaFlowData.
  ///
  /// The API stores only ONE notification per POA (either HEALTH or FINANCIAL).
  /// We populate BOTH health and financial fields from that single record so
  /// whichever section the UI renders will have the data.
  PoaFlowData _applyNotifications(
      PoaFlowData base, List<Map<String, dynamic>> notifications, List<PoaPersonData> allAttorneys) {
    String? notifyWho;
    String? notifyOf;
    String? notifyInstructions;
    String? notifyOtherText;
    List<PoaPersonData> notifyPersons = [];

    // Collect MEDICAL_DECISION_MAKER attorneys from the separate endpoint
    final medicalDecisionMakers = allAttorneys
        .where((a) => a.attorneyType == AttorneyType.MEDICAL_DECISION_MAKER)
        .toList();

    // The API returns at most one notification record
    if (notifications.isNotEmpty) {
      final n = notifications.first;
      final notifyFor = n['notify_for'] as List<dynamic>?;
      final notifyOfApi = n['notify_of'] as String?;
      final rawDetail = n['notify_of_detail'] as String?;
      final attorneys = n['attorneys'] as List<dynamic>? ?? [];

      // Map API notify_of back to UI value
      if (notifyOfApi == 'WRITTEN_INTENTION_NOTICE') {
        notifyOf = 'WRITTEN_NOTICE';
      } else {
        notifyOf = notifyOfApi;
      }

      // Determine who to notify
      if (notifyFor != null && notifyFor.contains('NOMINATED_PERSON')) {
        notifyWho = 'NOMINATED_PERSON';
      } else if (notifyFor != null && notifyFor.contains('ME')) {
        notifyWho = 'ME';
      }

      // Route detail text based on option
      if (notifyOf == 'OTHER') {
        notifyOtherText = rawDetail;
      } else {
        notifyInstructions = rawDetail;
      }

      // Parse attorneys
      notifyPersons = attorneys.map((a) {
        final m = a as Map<String, dynamic>;
        final rawName = m['full_name'] as String? ?? '';
        final (first, middle, last) = PoaPersonData.parseFullName(rawName);
        return PoaPersonData(
          id: m['id']?.toString() ?? '',
          firstName: first,
          middleName: middle,
          lastName: last,
          role: 'Contact',
          email: m['email'] as String?,
          phone: m['phone'] as String?,
          address: m['address'] as String?,
        );
      }).toList();
    }

    // Merge MEDICAL_DECISION_MAKER attorneys into notification persons if empty
    if (notifyPersons.isEmpty && medicalDecisionMakers.isNotEmpty) {
      notifyPersons = medicalDecisionMakers
          .map((a) => PoaPersonData(
                id: a.id,
                firstName: a.firstName,
                middleName: a.middleName,
                lastName: a.lastName,
                role: 'Contact',
                email: a.email,
                phone: a.phone,
                address: a.address,
              ))
          .toList();
    }

    print('📋 NOTIFY PARSED → who=$notifyWho, of=$notifyOf, otherText=$notifyOtherText, instr=$notifyInstructions, persons=${notifyPersons.length}');

    // Populate BOTH health and financial fields from the single record,
    // so whichever section the UI renders will show the correct data.
    return base.copyWith(
      notifyWho: notifyWho,
      notifyWhatOption: notifyOf,
      notifyInstructions: notifyInstructions,
      notifyWhatOtherText: notifyOtherText,
      notifyPersons: notifyPersons,
      financialNotifyWho: notifyWho,
      financialNotifyWhatOption: notifyOf,
      financialNotifyInstructions: notifyInstructions,
      financialNotifyWhatOtherText: notifyOtherText,
      financialNotifyPersons: notifyPersons,
    );
  }

  /// Maps fetched attorneys from GET /user/attorneys-for-poa onto state-specific
  /// fields in [base]. Handles ACT APPOINTED_ATTORNEY and NT FINANCIAL_DECISION_MAKER attorneys.
  PoaFlowData _applyAttorneys(PoaFlowData base, List<PoaPersonData> allAttorneys) {
    // Map APPOINTED_ATTORNEY attorneys → ACT actAttorneys
    final appointedAttorneys = allAttorneys
        .where((a) => a.attorneyType == AttorneyType.APPOINTED_ATTORNEY)
        .toList();

    if (appointedAttorneys.isNotEmpty) {
      final actEntries = appointedAttorneys
          .map((a) => ActAttorneyEntry(
                firstName: a.firstName,
                lastName: a.lastName,
                address: a.address ?? '',
                email: a.email,
                phone: a.phone,
                dob: a.dob,
                isCorporation: a.isCorporation,
                corporationType: a.corporationType,
                isBankrupt: a.isBankrupt,
              ))
          .toList();
      base = base.copyWith(
        actAttorneys: actEntries,
        actAttorneyCount: actEntries.length,
      );
    }

    // Map FINANCIAL_DECISION_MAKER attorneys → NT ntFinancialDms
    const dmTypes = [
      AttorneyType.FINANCIAL_DECISION_MAKER_PRIMARY,
      AttorneyType.FINANCIAL_DECISION_MAKER_SECONDARY,
      AttorneyType.FINANCIAL_DECISION_MAKER_TERTIARY,
    ];
    final dmAttorneys = allAttorneys
        .where((a) => dmTypes.contains(a.attorneyType))
        .toList()
      ..sort((a, b) =>
          dmTypes.indexOf(a.attorneyType ?? AttorneyType.FINANCIAL_DECISION_MAKER_PRIMARY)
              .compareTo(dmTypes.indexOf(b.attorneyType ?? AttorneyType.FINANCIAL_DECISION_MAKER_PRIMARY)));

    if (dmAttorneys.isNotEmpty) {
      final ntEntries = dmAttorneys
          .map((a) => NtDecisionMakerEntry(
                name: a.fullName,
                address: a.address ?? '',
              ))
          .toList();
      base = base.copyWith(
        ntFinancialDms: ntEntries,
        ntFinancialDmCount: ntEntries.length,
      );
    }

    // Map MEDICAL_DECISION_MAKER attorneys → VIC medical DM fields
    final medicalDms = allAttorneys
        .where((a) => a.attorneyType == AttorneyType.MEDICAL_DECISION_MAKER)
        .toList();

    if (medicalDms.isNotEmpty) {
      base = base.copyWith(
        hasMedicalDecisionMaker: true,
        medicalDecisionMakerDetails: medicalDms.first.fullName,
      );
    }

    // Map SECOND_DONOR attorney → SA second donor fields
    final secondDonors = allAttorneys
        .where((a) => a.attorneyType == AttorneyType.SECOND_DONOR)
        .toList();

    if (secondDonors.isNotEmpty) {
      final sd = secondDonors.first;
      base = base.copyWith(
        saHasSecondDonor: true,
        saSecondDonorFullName: sd.fullName,
        saSecondDonorAddress: sd.address,
        saSecondDonorEmail: sd.email,
      );
    }

    // Map ATTORNEY_DONOR → NT donor details (name, address, DOB)
    final donors = allAttorneys
        .where((a) => a.attorneyType == AttorneyType.ATTORNEY_DONOR)
        .toList();

    if (donors.isNotEmpty) {
      final d = donors.first;
      // Convert API DOB (YYYY-MM-DD) to display format (DD/MM/YYYY)
      String? displayDob;
      if (d.dob != null && d.dob!.isNotEmpty) {
        final parsed = DateTime.tryParse(d.dob!);
        if (parsed != null) {
          displayDob = '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
        } else {
          displayDob = d.dob;
        }
      }
      base = base.copyWith(
        ntDonorFullName: d.fullName,
        ntDonorAddress: d.address,
        ntDonorDob: displayDob,
      );
    }

    // Map ATTORNEY_DONEE attorney → SA donee fields
    final attorneyDonees = allAttorneys
        .where((a) => a.attorneyType == AttorneyType.ATTORNEY_DONEE)
        .toList();

    if (attorneyDonees.isNotEmpty) {
      final d = attorneyDonees.first;
      base = base.copyWith(
        doneeName: d.fullName,
        doneeAddress: d.address,
        doneeEmail: d.email,
      );
    }

    return base;
  }

  /// Overlays user profile fields onto [base] for the basic details step.
  /// The POA API doesn't return personal details (name, phone, dob, address),
  /// so we source them from the user profile to pre-fill the wizard.
  PoaFlowData _applyProfile(PoaFlowData base, UserProfile? profile) {
    if (profile == null) return base;
    final normalizedState = FormConstants.toStateApiValue(profile.state);
    print('[PoaTab._applyProfile] Raw state: "${profile.state}"');
    print('[PoaTab._applyProfile] Normalized state: "$normalizedState"');
    return base.copyWith(
      firstName: profile.firstName.isNotEmpty ? profile.firstName : null,
      middleName: profile.middleName.isNotEmpty ? profile.middleName : null,
      lastName: profile.lastName,
      phone: profile.mobile.isNotEmpty ? profile.mobile : null,
      dob: profile.dob,
      addressLine1: profile.address,
      suburb: profile.suburb,
      state: normalizedState,
      postcode: profile.postcode,
      country: profile.country.isNotEmpty ? profile.country : null,
      userEmail: profile.email.isNotEmpty ? profile.email : null,
      userContactPreference: profile.contactPreference ?? [],
      // Pre-fill ACT principal email from user profile when not already set
      actPrincipalEmail: base.actPrincipalEmail ?? (profile.email.isNotEmpty ? profile.email : null),
    );
  }

  String _formatMatters(List<String> matters) {
    if (matters.contains('FINANCIAL') || matters.contains('FINANCE')) return 'Financial matters';
    if (matters.contains('PERSONAL')) return 'Personal (including health) matters';
    if (matters.isEmpty) return 'Not specified';
    return matters.map((m) => m.replaceAll('_', ' ').toLowerCase()).join(', ');
  }

  String _formatCommencement(String? commencement) {
    switch (commencement) {
      case 'UPON_ATTORNEY_RECEIVING_CONDITION':
        return 'Upon attorney receiving condition';
      case 'IMMEDIATELY':
        return 'Immediately';
      case 'DONT_HAVE_CAPACITY':
        return "When I don't have capacity";
      default:
        return commencement?.replaceAll('_', ' ').toLowerCase() ?? 'Not specified';
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
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
        title: Text('Power of attorney', style: AppTextStyles.pageTitle),
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
                  _existingPoaData != null
                      ? _buildExistingPoaCard()
                      : _buildCreatePoaCard(),
                ],
              ),
            ),
    );
  }

  /// Returns the PoaFlowData to pass to step 1.
  /// Mock data injection happens in step 1 based on the selected state.
  PoaFlowData _getFlowData() {
    return _existingFlowData ?? const PoaFlowData();
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

  /// Shown when a POA record already exists — displays a summary and Edit CTA.
  Widget _buildExistingPoaCard() {
    final poaData = _existingPoaData!;
    final isActive = poaData.isActive ?? false;
    final mattersLabel = _formatMatters(poaData.matters);
    final updatedLabel = _formatDate(poaData.updatedAt ?? poaData.createdAt);

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
          // ── White details card ────────────────────────────────────────────
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
                // Title row + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Power of attorney',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryGreen
                                  : AppColors.textGray,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isActive
                                  ? AppColors.primaryGreen
                                  : AppColors.textGray,
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

                // Matters type
                _buildDetailRow(
                  icon: Icons.gavel_outlined,
                  label: 'Matters',
                  value: mattersLabel,
                ),
                const SizedBox(height: 12),

                // Commencement
                if (poaData.commencement != null) ...[
                  _buildDetailRow(
                    icon: Icons.play_circle_outline,
                    label: 'Commencement',
                    value: _formatCommencement(poaData.commencement),
                  ),
                  const SizedBox(height: 12),
                ],

                // Signing assistance
                _buildDetailRow(
                  icon: Icons.accessibility_new_outlined,
                  label: 'Signing assistance',
                  value: poaData.needSigningAssistance == true ? 'Required' : 'Not required',
                ),
                const SizedBox(height: 12),

                // Conditions & limitations
                if (poaData.hasConditionsLimitations == true && poaData.conditionsLimitations != null) ...[
                  _buildDetailRow(
                    icon: Icons.rule_outlined,
                    label: 'Conditions & limitations',
                    value: poaData.conditionsLimitations!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Preferences
                if (poaData.hasPreference == true && poaData.preferences != null) ...[
                  _buildDetailRow(
                    icon: Icons.favorite_border_outlined,
                    label: 'Preferences',
                    value: poaData.preferences!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Attorney instructions
                if (poaData.hasAttorneyInstruction == true && poaData.attorneyInstruction != null) ...[
                  _buildDetailRow(
                    icon: Icons.description_outlined,
                    label: 'Attorney instructions',
                    value: poaData.attorneyInstruction!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Last updated
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

          // ── Action buttons ────────────────────────────────────────────────
          AppPrimaryButton(
            text: 'Edit preference',
            onPressed: () {
              context.push(
                AppRouter.poaBasicDetails,
                extra: _getFlowData(),
              );
            },
          ),
          const SizedBox(height: 12),
          AppSecondaryButton(
            text: 'Download',
            onPressed: () {
              // TODO: Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download functionality coming soon'),
                ),
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

  /// Shown when no POA exists — the original create prompt UI.
  Widget _buildCreatePoaCard() {
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
          // Inner white card
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
                  'Power of attorney',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a legally binding document that authorises a trusted person to manage your affairs.',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 20),
                // Banner illustration
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
          // CTA button
          AppPrimaryButton(
            text: 'Create power of attorney',
            onPressed: () {
              context.push(
                AppRouter.poaBasicDetails,
                extra: _getFlowData(),
              );
            },
          ),
        ],
      ),
    );
  }
}
