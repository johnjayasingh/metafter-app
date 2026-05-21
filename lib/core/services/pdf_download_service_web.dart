// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PdfDownloadService {
  /// On web, downloads the PDF via browser's native download mechanism.
  /// Returns null since there is no local file path on the web.
  Future<String?> downloadPdf({
    required String url,
    required String fileName,
  }) async {
    try {
      final finalFileName =
          fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';

      // Fetch the bytes via Dio (respects auth headers if needed)
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
                'Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      if (response.data == null) {
        throw Exception('Empty response when downloading PDF');
      }

      // Create a Blob and trigger browser download
      final blob = html.Blob([response.data!], 'application/pdf');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: blobUrl)
        ..setAttribute('download', finalFileName)
        ..click();

      html.Url.revokeObjectUrl(blobUrl);

      // No local file path on web — return null to indicate browser download
      return null;
    } catch (e) {
      debugPrint('❌ Error downloading PDF on web: $e');
      rethrow;
    }
  }
}
