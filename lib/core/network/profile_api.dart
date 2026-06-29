import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_endpoints.dart';

/// Talks to the backend `/v1/profile` endpoints.
class ProfileApi {
  final ApiClient _api = ApiClient();

  /// PUT /v1/profile — upserts the signed-in user's profile. The backend
  /// derives userId from the Cognito ID token, so we only send public fields.
  Future<void> putProfile({
    required String displayName,
    String? headline,
    String? company,
    String? bio,
  }) async {
    await _api.put(ApiEndpoints.profile, data: {
      'displayName': displayName,
      if (headline != null && headline.isNotEmpty) 'headline': headline,
      if (company != null && company.isNotEmpty) 'company': company,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
    });
  }

  /// Requests a presigned S3 PUT URL and uploads the avatar bytes directly.
  /// The upload itself must NOT carry our Authorization header (it would
  /// break the S3 signature), so it uses a bare Dio instance.
  Future<void> uploadPhoto(File file) async {
    final res = await _api.post(ApiEndpoints.photoUploadUrl);
    final uploadUrl = res.data['uploadUrl'] as String?;
    if (uploadUrl == null) return;

    final bytes = await file.readAsBytes();
    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: bytes.length,
          'Content-Type': 'image/jpeg',
        },
        contentType: 'image/jpeg',
      ),
    );
  }
}
