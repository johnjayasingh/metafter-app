import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';

/// PDF preview backed by flutter_pdfview (native iOS PDFKit / Android PdfRenderer).
/// Renders annotations, digital signatures, and overlays exactly as the OS would
/// — no re-encoding or compression applied.
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
  String? _tempFilePath;
  bool _fileReady = false;
  String? _fileError;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _prepareTempFile();
  }

  @override
  void didUpdateWidget(PdfPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dataChanged = widget.pdfData != oldWidget.pdfData && widget.pdfData != null;
    final urlChanged = widget.pdfUrl != oldWidget.pdfUrl && widget.pdfUrl != null;
    if (dataChanged || urlChanged) {
      setState(() {
        _fileReady = false;
        _fileError = null;
        _tempFilePath = null;
        _totalPages = 0;
      });
      _prepareTempFile();
    }
  }

  Future<void> _prepareTempFile() async {
    if (widget.pdfData == null && widget.pdfUrl == null) return;
    try {
      final dir = await getTemporaryDirectory();
      Uint8List bytes;
      if (widget.pdfData != null) {
        bytes = widget.pdfData!;
      } else {
        final response = await http.get(Uri.parse(widget.pdfUrl!));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        bytes = response.bodyBytes;
      }
      final hash = bytes.hashCode.abs();
      final path = '${dir.path}/pdf_preview_$hash.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          _tempFilePath = path;
          _fileReady = true;
        });
      }
    } catch (e) {
      debugPrint('❌ PdfPreviewWidget: failed to prepare PDF: $e');
      if (mounted) {
        setState(() => _fileError = 'Failed to load PDF document');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading ||
        (!_fileReady && (widget.pdfData != null || widget.pdfUrl != null) && _fileError == null)) {
      return _buildLoadingState();
    }
    if (widget.errorMessage != null ||
        _fileError != null ||
        (widget.pdfData == null && widget.pdfUrl == null)) {
      return _buildErrorState(widget.errorMessage ?? _fileError);
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

  void _openFullScreen(BuildContext context, String filePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PdfFullScreenViewer(
          filePath: filePath,
          totalPages: _totalPages,
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    final filePath = _tempFilePath;
    if (filePath == null) return _buildLoadingState();

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
            PDFView(
              key: ValueKey(filePath),
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: false,
              pageSnap: false,
              fitPolicy: FitPolicy.WIDTH,
              preventLinkNavigation: false,
              gestureRecognizers: {
                Factory<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              onRender: (pages) {
                if (mounted) setState(() => _totalPages = pages ?? 0);
                debugPrint('✅ PDF rendered — $pages pages');
              },
              onError: (error) {
                debugPrint('❌ PDFView error: $error');
                if (mounted) {
                  setState(() => _fileError = 'Error rendering PDF: $error');
                }
              },
              onPageError: (page, error) {
                debugPrint('❌ PDFView page $page error: $error');
              },
            ),
            // Page count badge — bottom left
            if (_totalPages > 0)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_totalPages ${_totalPages == 1 ? 'page' : 'pages'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // Full-screen button — bottom right
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _openFullScreen(context, filePath),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 22,
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

// ---------------------------------------------------------------------------
// Full-screen PDF viewer (mobile)
// ---------------------------------------------------------------------------

class _PdfFullScreenViewer extends StatefulWidget {
  final String filePath;
  final int totalPages;

  const _PdfFullScreenViewer({
    required this.filePath,
    required this.totalPages,
  });

  @override
  State<_PdfFullScreenViewer> createState() => _PdfFullScreenViewerState();
}

class _PdfFullScreenViewerState extends State<_PdfFullScreenViewer> {
  int _currentPage = 1;
  int _totalPages = 0;
  PDFViewController? _controller;

  @override
  void initState() {
    super.initState();
    _totalPages = widget.totalPages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _totalPages > 0
            ? Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        centerTitle: true,
        actions: [
          if (_totalPages > 1) ...[
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Previous page',
              onPressed: _currentPage > 1
                  ? () => _controller?.setPage(_currentPage - 2)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Next page',
              onPressed: _currentPage < _totalPages
                  ? () => _controller?.setPage(_currentPage)
                  : null,
            ),
          ],
        ],
      ),
      body: PDFView(
        key: ValueKey('fullscreen_${widget.filePath}'),
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        gestureRecognizers: {
          Factory<EagerGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
        onViewCreated: (controller) {
          setState(() => _controller = controller);
        },
        onRender: (pages) {
          if (mounted) setState(() => _totalPages = pages ?? 0);
        },
        onPageChanged: (page, total) {
          if (mounted) {
            setState(() {
              _currentPage = (page ?? 0) + 1;
              _totalPages = total ?? _totalPages;
            });
          }
        },
        onError: (error) => debugPrint('❌ FullScreen PDFView error: $error'),
        onPageError: (page, error) =>
            debugPrint('❌ FullScreen PDFView page $page error: $error'),
      ),
    );
  }
}
