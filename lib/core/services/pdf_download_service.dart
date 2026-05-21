/// Conditionally exports the correct PdfDownloadService implementation:
/// - Web:    triggers browser download via dart:html
/// - Mobile: saves to local filesystem via path_provider + permission_handler
export 'pdf_download_service_mobile.dart'
    if (dart.library.html) 'pdf_download_service_web.dart';
