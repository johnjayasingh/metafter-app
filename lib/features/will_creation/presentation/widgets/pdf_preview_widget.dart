/// Conditionally exports the correct PdfPreviewWidget implementation:
/// - Web:    browser-native rendering via HtmlElementView (no native plugins)
/// - Mobile: flutter_pdfview backed by iOS PDFKit / Android PdfRenderer
export 'pdf_preview_widget_mobile.dart'
    if (dart.library.html) 'pdf_preview_widget_web.dart';
