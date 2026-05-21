// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';

/// PDF preview for web — uses browser's native PDF renderer via an <iframe>.
/// For byte data, a Blob URL is created and revoked on dispose.
/// For URL data, the iframe src is set directly.
class PdfPreviewWidget extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final Uint8List? pdfData;
  final String? pdfUrl;
  final VoidCallback? onRetry;
  final double height;

  const PdfPreviewWidget({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.pdfData,
    this.pdfUrl,
    this.onRetry,
    this.height = 650,
  }) : assert(
          pdfData != null || pdfUrl != null || isLoading || errorMessage != null,
          'Either pdfData or pdfUrl must be provided when not loading or in error state',
        );

  @override
  State<PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<PdfPreviewWidget> {
  String? _blobUrl;
  String? _viewId;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(PdfPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pdfData != oldWidget.pdfData ||
        widget.pdfUrl != oldWidget.pdfUrl) {
      _revokeBlobUrl();
      _setup();
    }
  }

  void _setup() {
    if (widget.pdfData != null) {
      final blob = html.Blob([widget.pdfData!], 'application/pdf');
      _blobUrl = html.Url.createObjectUrlFromBlob(blob);
    }
    final src = _blobUrl ?? widget.pdfUrl;
    if (src == null) return;

    _viewId = 'pdf-iframe-${src.hashCode.abs()}';
    // Register the factory — safe to register multiple times for same viewId.
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int id) => html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
    if (mounted) setState(() {});
  }

  void _revokeBlobUrl() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }

  @override
  void dispose() {
    _revokeBlobUrl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }
    if (widget.errorMessage != null ||
        (widget.pdfData == null && widget.pdfUrl == null)) {
      return _buildErrorState(widget.errorMessage);
    }
    return _buildPdfViewer();
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGray4,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String? message) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGray4,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              size: 48, color: AppColors.textGray),
          const SizedBox(height: 12),
          Text(
            message ?? 'Failed to load document',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed2),
            textAlign: TextAlign.center,
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 16),
            AppPrimaryButton(
              text: 'Retry',
              onPressed: widget.onRetry,
              icon: Icons.refresh,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_viewId == null) return _buildLoadingState();
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGray4,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            HtmlElementView(viewType: _viewId!),
            // Full-screen button — opens PDF in a new browser tab
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  final src = _blobUrl ?? widget.pdfUrl;
                  if (src != null) {
                    html.window.open(src, '_blank');
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.open_in_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
