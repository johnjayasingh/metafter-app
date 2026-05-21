import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../funeral/data/models/funeral_flow_data.dart';
import '../../../funeral/data/models/funeral_models.dart';
import '../../../funeral/data/services/funeral_service.dart';
import 'package:intl/intl.dart';

class FuneralTab extends StatefulWidget {
  const FuneralTab({super.key});

  @override
  State<FuneralTab> createState() => _FuneralTabState();
}

class _FuneralTabState extends State<FuneralTab> {
  final FuneralService _funeralService = FuneralService();
  FuneralModel? _funeralData;
  List<MusicOption> _musicOptions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFuneralData();
  }

  Future<void> _loadFuneralData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _funeralService.getFuneralDetails(),
        _funeralService.getMusicOptions(),
      ]);

      final funeralResponse = results[0] as FuneralResponse<FuneralModel>;
      final musicResponse = results[1] as FuneralResponse<List<MusicOption>>;

      if (funeralResponse.isSuccess) {
        setState(() {
          _funeralData = funeralResponse.data;
          _musicOptions = musicResponse.data ?? [];
          _isLoading = false;
        });
      } else {
        // GET failed — treat as new entry (no existing preferences)
        setState(() {
          _funeralData = null;
          _musicOptions = musicResponse.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      // GET failed — treat as new entry
      setState(() {
        _funeralData = null;
        _isLoading = false;
      });
    }
  }

  String _getMusicName(int? musicId) {
    if (musicId == null) return '';
    final match = _musicOptions.where((m) => m.id == musicId).toList();
    return match.isNotEmpty ? match.first.name : 'Music #$musicId';
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
        title: Row(
          children: [Text('Funeral', style: AppTextStyles.pageTitle)],
        ),
        centerTitle: true,
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
              onPressed: () {
                context.push(AppRouter.notifications);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Empty state or Funeral Preferences Card
                    if (_funeralData == null)
                      _buildEmptyState()
                    else
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderGray),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // WillCloud logo watermark (background)
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Opacity(
                                    opacity: 0.05,
                                    child: SvgPicture.asset(
                                      'assets/images/logo.svg',
                                      width: 280,
                                      height: 240,
                                    ),
                                  ),
                                ),
                              ),
                              // Card content
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title row with 3-dot menu
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'My Funeral Preferences',
                                            style: AppTextStyles.sectionTitle,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: AppColors.textPrimary,
                                            size: 22,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              await context.push(
                                                AppRouter.funeralPreferences,
                                                extra: FuneralFlowData
                                                    .fromFuneralModel(
                                                        _funeralData!),
                                              );
                                              _loadFuneralData();
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined,
                                                      size: 18),
                                                  SizedBox(width: 10),
                                                  Text('Edit preferences'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: AppTextStyles.subtitle.copyWith(
                                          color: AppColors.errorRed,
                                        ),
                                      ),
                                    ],

                                    if (_funeralData != null) ...[
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        'Funeral Preference',
                                        _funeralData!.funeralPreference
                                            .displayLabel,
                                      ),
                                      // Show preference-specific data
                                      ..._buildPreferenceDataRows(),
                                      if (_funeralData!.serviceLocation != null)
                                        _buildInfoRow(
                                          'Service Location',
                                          _funeralData!.serviceLocation!,
                                        ),
                                      if (_funeralData!.dateTimePreference != null)
                                        _buildInfoRow(
                                          'Date/Time Preference',
                                          DateFormat('dd MMM yyyy · hh:mm a')
                                              .format(_funeralData!.dateTimePreference!),
                                        ),
                                      if (_funeralData!.musicId != null ||
                                          _funeralData!.musicName != null)
                                        _buildInfoRow(
                                          'Music Choice',
                                          _funeralData!.musicName ??
                                              _getMusicName(_funeralData!.musicId),
                                        ),
                                      if (_funeralData!.specialInstruction != null)
                                        _buildInfoRow(
                                          'Readings/Eulogies',
                                          _funeralData!.specialInstruction!,
                                        ),
                                      if (_funeralData!.legacyMessage != null)
                                        _buildInfoRow(
                                          'Legacy Message',
                                          _funeralData!.legacyMessage!,
                                        ),
                                      if (_funeralData!.legacyMessageVideoUrl != null)
                                        _buildInfoRow(
                                          'Legacy Video',
                                          'Video message attached',
                                        ),
                                      if (_funeralData!.attendees != null &&
                                          _funeralData!.attendees!.isNotEmpty)
                                        _buildInfoRow(
                                          'Recipients',
                                          '${_funeralData!.attendees!.length} recipient(s)',
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildPreferenceDataRows() {
    final prefData = _funeralData?.funeralPreferenceData;
    if (prefData == null) return [];

    final rows = <Widget>[];

    if (prefData.religion != null) {
      rows.add(_buildInfoRow('Religion', prefData.religion!.displayLabel));
    }
    if (prefData.cemeteryName != null) {
      rows.add(_buildInfoRow('Cemetery', prefData.cemeteryName!));
    }
    if (prefData.placeOfWorship != null) {
      rows.add(_buildInfoRow('Place of Worship', prefData.placeOfWorship!));
    }
    if (prefData.specificRite != null) {
      rows.add(_buildInfoRow('Specific Rites', prefData.specificRite!));
    }
    if (prefData.ashDisposalInstruction != null) {
      rows.add(_buildInfoRow(
          'Ashes Disposal', prefData.ashDisposalInstruction!));
    }
    if (prefData.directionBy != null && prefData.directionBy!.isNotEmpty) {
      final names =
          prefData.directionBy!.map((d) => d.fullName).join(', ');
      rows.add(_buildInfoRow('Direction By', names));
    }

    return rows;
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Funeral Preferences',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 16),
          // WillCloud logo watermark
          Center(
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                width: 280,
                height: 240,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Add funeral preference button
          AppPrimaryButton(
            text: 'Add funeral preference',
            onPressed: () async {
              await context.push(
                AppRouter.funeralPreferences,
                extra: _funeralData != null
                    ? FuneralFlowData.fromFuneralModel(_funeralData!)
                    : null,
              );
              // Reload data when returning from funeral flow
              _loadFuneralData();
            },
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.cardSecondary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.itemLabel,
          ),
        ],
      ),
    );
  }
}
