import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/services/will_document_service.dart';
import '../../data/models/will_complete_detail_response.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/pdf_preview_widget.dart';
import '../widgets/legal_review_steps_sidebar.dart';

class LegalReviewScreen extends StatefulWidget {
  final String userName;
  final String willId;
  final bool regenerate;

  const LegalReviewScreen({
    super.key,
    this.userName = 'Mary Wilson',
    required this.willId,
    this.regenerate = false,
  });

  @override
  State<LegalReviewScreen> createState() => _LegalReviewScreenState();
}

class _LegalReviewScreenState extends State<LegalReviewScreen> {
  final WillDocumentService _documentService = WillDocumentService();
  WillCompleteDetailData? _willDetailData;
  Uint8List? _pdfData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWillDetails();
  }

  Future<void> _fetchWillDetails() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First fetch existing complete details
      WillCompleteDetailResponse? response = await _documentService.getWillCompleteDetail(widget.willId);
      
      // Regenerate if requested (coming from review/payment) or if document not yet generated
      final bool needsGeneration = widget.regenerate ||
          response == null ||
          !response.isSuccess ||
          response.data == null ||
          response.data!.willOriginal.isEmpty;
      
      if (needsGeneration) {
        print('📄 ${widget.regenerate ? "Regenerating" : "Generating"} document for will: ${widget.willId}');
        final generateResponse = await _documentService.generateWillDocument(widget.willId);
        
        if (generateResponse != null && generateResponse.isSuccess && generateResponse.data != null) {
          print('✅ Document generated successfully, fetching complete details...');
          // Wait a moment for the server to process
          await Future.delayed(const Duration(seconds: 2));
          // Re-fetch complete details with newly generated document URLs
          if (mounted) {
            response = await _documentService.getWillCompleteDetail(widget.willId);
          }
        } else {
          print('⚠️ Document generation returned no data, will try fetching existing details...');
        }
      }
      
      if (!mounted) return;
      
      if (!mounted) return;
      
      if (response != null && response.isSuccess && response.data != null) {
        final data = response.data!;
        // Fetch PDF data via document preview API
        final pdfData = await _documentService.fetchWillDocumentPreview(widget.willId);
        if (!mounted) return;
        setState(() {
          _willDetailData = data;
          _pdfData = pdfData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Your will document is being prepared. This may take a few moments. Please try again shortly.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error in _fetchWillDetails: $e');
      if (!mounted) return;
      
      setState(() {
        _error = 'Unable to load will details. The document may still be generating. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _showPdfPreview(BuildContext context) {
    if (_pdfData == null && _willDetailData?.willOriginal == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Will Document Preview',
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textPrimary,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.backgroundLight,
                      ),
                    ),
                  ],
                ),
              ),
              // PDF Viewer
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PdfPreviewWidget(
                    isLoading: false,
                    pdfData: _pdfData,
                    pdfUrl: _pdfData == null ? _willDetailData?.willOriginal : null,
                    height: MediaQuery.of(context).size.height * 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: LegalReviewStepsSidebar(
        currentStep: 1,
        willId: widget.willId,
      ),
      appBar: WillCreationAppBar(
        currentStep: 1,
        totalSteps: 3,
        title: 'Legal review',
        showStepNumber: true,
        skipExitConfirmation: true,
        onExitNavigate: () => context.go(AppRouter.home),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your will document...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Send for legal review',
                          style: AppTextStyles.pageTitle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review the Will with your lawyer',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Error Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Unable to load will document',
                                      style: AppTextStyles.sectionTitle.copyWith(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppPrimaryButton(
                                text: 'Retry',
                                onPressed: _fetchWillDetails,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Send for legal review',
                      style: AppTextStyles.pageTitle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review the Will with your lawyer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Success Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundMintLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Your will has been generated successfully',
                                  style: AppTextStyles.sectionTitle.copyWith(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'A unique ID and QR code have been assigned for easy access and verification',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Cover Page Preview - show if PDF data or cover image is available
                    if (_pdfData != null || _willDetailData?.willCoverImage.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      const Divider(thickness: .1),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundMintLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cover page preview',
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cover page preview — this will be the cover of your will',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Display PDF preview or cover image
                            GestureDetector(
                                  onTap: () => _showPdfPreview(context),
                                  child: Container(
                                    width: double.infinity,
                                    height: _pdfData != null ? 300 : 160,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: _pdfData != null
                                              ? PdfPreviewWidget(
                                                  isLoading: false,
                                                  pdfData: _pdfData,
                                                  height: 300,
                                                )
                                              : Image.network(
                                                  _willDetailData!.willCoverImage,
                                                  width: double.infinity,
                                                  height: 160,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      padding: const EdgeInsets.all(40),
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded /
                                                                  loadingProgress.expectedTotalBytes!
                                                              : null,
                                                          color: AppColors.primaryGreen,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      padding: const EdgeInsets.all(24),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.image_not_supported,
                                                            size: 48,
                                                            color: AppColors.textTertiary,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'Unable to load cover image',
                                                            style: AppTextStyles.bodySmall.copyWith(
                                                              color: AppColors.textTertiary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        // Overlay with tap hint
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.7),
                                                  Colors.transparent,
                                                ],
                                              ),
                                              borderRadius: const BorderRadius.only(
                                                bottomLeft: Radius.circular(12),
                                                bottomRight: Radius.circular(12),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.touch_app,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Tap to preview full document',
                                                  style: AppTextStyles.bodySmall.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
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
                          ],
                        ),
                      ),
                    ],
                    // QR Code Section - only show if documentId and watermarked URL are available
                    if (_willDetailData?.documentId != null && _willDetailData?.willWatermarked != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundMintLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Authentication QR Code',
                                    style: AppTextStyles.sectionTitle.copyWith(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This unique QR code allows verification of your will\'s authenticity',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 100,
                              height: 100,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: QrImageView(
                                data: _willDetailData!.willWatermarked,
                                version: QrVersions.auto,
                                size: 84,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Document ID - only show if documentId is available
                    if (_willDetailData?.documentId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundMintLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Document Identification',
                                    style: AppTextStyles.sectionTitle.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _willDetailData!.documentId,
                                    style: AppTextStyles.sectionTitle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            AppBottomActionBar(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      text: 'Previous',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Next step',
                      onPressed: () {
                        context.push(
                          AppRouter.assignLawyer,
                          extra: {'willId': widget.willId},
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
