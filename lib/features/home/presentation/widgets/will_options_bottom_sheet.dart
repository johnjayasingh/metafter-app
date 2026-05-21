import 'package:digitalwill/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/pdf_download_service.dart';
import '../../../../core/widgets/pdf_save_bottom_sheet.dart';
import '../../../will_creation/data/services/will_document_service.dart';

class WillOptionsBottomSheet extends StatefulWidget {
  final String willId;
  final String fullName;
  final String status;
  final bool isInvited;

  const WillOptionsBottomSheet({
    super.key,
    required this.willId,
    required this.fullName,
    required this.status,
    this.isInvited = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String willId,
    required String fullName,
    required String status,
    bool isInvited = false,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WillOptionsBottomSheet(
        willId: willId,
        fullName: fullName,
        status: status,
        isInvited: isInvited,
      ),
    );
  }

  @override
  State<WillOptionsBottomSheet> createState() => _WillOptionsBottomSheetState();
}

class _WillOptionsBottomSheetState extends State<WillOptionsBottomSheet> {
  final _willDocumentService = WillDocumentService();
  final _pdfDownloadService = PdfDownloadService();

  Future<void> _downloadPDF() async {
    // Get will details first to get PDF URL
    final response = await _willDocumentService.getWillCompleteDetail(
      widget.willId,
    );

    if (response?.data?.willWatermarked == null) {
      if (mounted) {
        SnackBarUtils.showError(context, 'No PDF available to download');
      }
      return;
    }

    // Show bottom sheet to get filename
    final defaultFileName =
        'Will_${widget.willId.substring(0, 6).toUpperCase()}';
    final fileName = await PdfSaveBottomSheet.showSaveDialog(
      context: context,
      defaultName: defaultFileName,
    );

    if (fileName == null) return; // User cancelled

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Download the file
      final filePath = await _pdfDownloadService.downloadPdf(
        url: response!.data!.willWatermarked!,
        fileName: fileName,
      );

      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (filePath != null && mounted) {
        // Show success with options
        PdfSaveBottomSheet.showSuccessDialog(
          context: context,
          filePath: filePath,
        );
      }
    } catch (e) {
      // Hide loading indicator if visible
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        SnackBarUtils.showError(
          context,
          e.toString().contains('permission')
              ? 'Storage permission is required to download PDF'
              : 'Failed to download PDF. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upperStatus = widget.status.toUpperCase();
    final isInLegalReview = upperStatus == 'IN_LEGAL_REVIEW' ||
        upperStatus == 'LEGAL_REVIEW' ||
        upperStatus == 'UNDER_REVIEW';
    final showTimeline = isInLegalReview ||
        upperStatus == 'REVIEW_COMPLETED' ||
        upperStatus == 'WILL_SIGNED';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            if (showTimeline) ...[
              _buildOption(
                context,
                icon: Icons.timeline_outlined,
                title: 'View timeline',
                onTap: () {
                  context.pop();
                  context.push(
                    AppRouter.willTimeline,
                    extra: {
                      'willId': widget.willId,
                      'fullName': widget.fullName,
                      'status': widget.status,
                    },
                  );
                },
              ),
              _buildDivider(),
            ],

            // Options
            if (isInLegalReview || showTimeline) ...[
              _buildOption(
                context,
                icon: Icons.gavel_outlined,
                title: 'View legal review',
                onTap: () {
                  context.pop();
                  context.push(
                    AppRouter.legalReview,
                    extra: {
                      'willId': widget.willId,
                      'fullName': widget.fullName,
                      'status': widget.status,
                    },
                  );
                },
              ),
              _buildDivider(),
            ],
            _buildOption(
              context,
              icon: Icons.edit_outlined,
              title: 'Edit will',
              onTap: () async {
                context.pop();
                await SecureStorageService().saveWillId(widget.willId);
                if (context.mounted) {
                  context.push(AppRouter.willOnboarding);
                }
              },
            ),
            _buildOption(
              context,
              icon: Icons.delete_outline,
              title: 'Delete will',
              color: AppColors.errorRed2,
              onTap: () {
                context.pop();
                // TODO: Show delete confirmation
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: optionColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyles.itemLabel.copyWith(
                color: optionColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Divider(height: 1, thickness: 1, color: AppColors.borderGray),
    );
  }
}
