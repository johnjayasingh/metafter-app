import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/poa_models.dart';
import '../../data/models/poa_flow_config.dart';
import '../../data/services/poa_service.dart';
import '../widgets/poa_steps_sidebar.dart';

/// NSW Step 3 — Witness information review screen with Save & Download.
class PoaReviewNswScreen extends StatefulWidget {
  final PoaFlowData flowData;

  const PoaReviewNswScreen({super.key, required this.flowData});

  @override
  State<PoaReviewNswScreen> createState() => _PoaReviewNswScreenState();
}

class _PoaReviewNswScreenState extends State<PoaReviewNswScreen> {
  final PoaService _poaService = PoaService();
  bool _isSaving = false;

  Future<void> _handleSaveAndDownload() async {
    setState(() => _isSaving = true);
    try {
      // Save WA attorneys via the attorney endpoint
      if (widget.flowData.state?.toLowerCase() == 'western_australia') {
        await _saveWaAttorneys();
      }

      final result = await _poaService.createOrUpdatePoa(widget.flowData);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.isSuccess) {
        SnackBarUtils.showSuccess(
          context,
          'Power of attorney saved successfully.',
        );
        context.go(AppRouter.home, extra: 4);
      } else {
        SnackBarUtils.showError(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to save power of attorney. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackBarUtils.showError(
        context,
        'An error occurred. Please try again.',
      );
    }
  }

  Future<void> _saveWaAttorneys() async {
    final fd = widget.flowData;

    // Delete existing attorneys before re-creating to avoid duplicates
    await _poaService.deleteAttorneysByType(AttorneyType.PRIMARY);
    await _poaService.deleteAttorneysByType(AttorneyType.SUBSTITUTE);

    // Save primary attorneys
    for (final entry in fd.waAttorneys) {
      if (entry.name.trim().isEmpty) continue;
      final (first, middle, last) = PoaPersonData.parseFullName(entry.name);
      final person = PoaPersonData(
        id: '',
        firstName: first,
        middleName: middle,
        lastName: last,
        address: entry.address.trim().isNotEmpty ? entry.address.trim() : null,
        email: entry.email.trim().isNotEmpty ? entry.email.trim() : null,
      );
      await _poaService.createAttorneyForPoa(
        person,
        type: AttorneyType.PRIMARY,
      );
    }

    // Save substitute attorneys
    if (fd.waHasSubstitute == true) {
      for (final entry in fd.waSubstitutes) {
        if (entry.name.trim().isEmpty) continue;
        final (first, middle, last) = PoaPersonData.parseFullName(entry.name);
        final person = PoaPersonData(
          id: '',
          firstName: first,
          middleName: middle,
          lastName: last,
          address: entry.address.trim().isNotEmpty ? entry.address.trim() : null,
          email: entry.email.trim().isNotEmpty ? entry.email.trim() : null,
        );
        await _poaService.createAttorneyForPoa(
          person,
          type: AttorneyType.SUBSTITUTE,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = PoaFlowConfig.forState(widget.flowData.state);
    final reviewStep = config.totalSteps;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PoaStepsSidebar(
          currentStep: reviewStep, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: reviewStep,
        totalSteps: config.totalSteps,
        title: 'Review & Download',
        enableDrawer: true,
        exitTitle: 'Exit power of attorney?',
        exitDescription:
            'Your progress will be lost. You can start a new power of attorney at any time.',
        exitDiscardButtonText: 'Exit POA',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 4),
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
                    // ── Who Can Be a Witness ──
                    Text(
                      'Who Can Be a Witness',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 12),
                    _buildBulletItem(
                      'A witness must be at least 18 years old.',
                    ),
                    _buildBulletItem(
                      'A witness cannot be a person appointed as your attorney under the power of attorney.',
                    ),
                    _buildBulletItem(
                      'The witness should not be a relative of the principal or the attorney.',
                    ),
                    _buildBulletItem(
                      'Ideally, the witness should be someone who can be contacted in the future if there is any dispute about the document.',
                    ),
                    _buildBulletItem(
                      'A qualified legal practitioner, such as a Justice of the Peace (JP), solicitor, barrister, or licensed conveyancer, is generally the best choice as a witness.',
                    ),

                    const SizedBox(height: 28),

                    // ── How Many Witnesses Are Required ──
                    Text(
                      'How Many Witnesses Are Required',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 12),
                    _buildBulletItem(
                      'For an Enduring Power of Attorney in NSW, at least one witness is required for the principal\'s signature.',
                    ),
                    _buildBulletItem(
                      'The witness must be a prescribed witness (e.g., an Australian legal practitioner or a registrar of the Local Court).',
                    ),
                    _buildBulletItem(
                      'Each attorney\'s acceptance must also be witnessed by at least one prescribed witness.',
                    ),

                    const SizedBox(height: 28),

                    // ── The Witnessing Process ──
                    Text(
                      'The Witnessing Process',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 12),
                    _buildNumberedItem(
                      '1',
                      'The principal signs or marks the document in the presence of the witness.',
                    ),
                    _buildNumberedItem(
                      '2',
                      'The witness must observe the principal signing or making the mark.',
                    ),
                    _buildNumberedItem(
                      '3',
                      'The witness signs the document and provides their full name, address, and qualification (e.g., "solicitor" or "JP").',
                    ),
                    _buildNumberedItem(
                      '4',
                      'The witness must certify that the principal appeared to understand the effect of the power of attorney and that the principal signed freely and voluntarily.',
                    ),
                    _buildNumberedItem(
                      '5',
                      'Each attorney must also sign their acceptance clause in the presence of a prescribed witness.',
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Bottom bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
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
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Save & Download',
                        onPressed: _isSaving ? null : _handleSaveAndDownload,
                        isLoading: _isSaving,
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

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.stepNumberBadge,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
