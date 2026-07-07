import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_endpoints.dart';

/// Talks to the backend `/v1/verification/*` endpoints.
///
/// The backend is stateless with respect to user data: the reference photo is
/// uploaded to a presigned, TTL'd S3 key and deleted the moment the face
/// comparison finishes. The only durable outcome is `{verified, badgeSig}`
/// on the caller's directory row.
class VerificationApi {
  final ApiClient _api = ApiClient();

  /// POST /v1/verification/start — opens a Rekognition Face Liveness session
  /// and presigns a PUT for the reference photo.
  Future<VerificationSession> start() async {
    final res = await _api.post(ApiEndpoints.verificationStart, data: const {});
    final d = (res.data as Map).cast<String, dynamic>();
    final sessionId = d['sessionId'] as String?;
    final photoUploadUrl = d['photoUploadUrl'] as String?;
    final photoKey = d['photoKey'] as String?;
    if (sessionId == null || sessionId.isEmpty) {
      throw StateError('verification/start returned no sessionId');
    }
    if (photoUploadUrl == null || photoKey == null) {
      throw StateError('verification/start returned no photo upload target');
    }
    return VerificationSession(
      sessionId: sessionId,
      photoUploadUrl: photoUploadUrl,
      photoKey: photoKey,
    );
  }

  /// Uploads the reference photo bytes to the presigned S3 PUT URL from
  /// [start]. The upload must NOT carry our Authorization header (it would
  /// break the S3 signature), so it uses a bare Dio instance.
  Future<void> uploadPhoto(File file, String presignedUrl) async {
    final bytes = await file.readAsBytes();
    await Dio().put(
      presignedUrl,
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

  /// POST /v1/verification/complete — server resolves the liveness session,
  /// compares the captured frame with the uploaded photo, and (on success)
  /// signs the verified badge.
  Future<IdentityVerificationResult> complete(
    String sessionId,
    String photoKey,
  ) async {
    final res = await _api.post(
      ApiEndpoints.verificationComplete,
      data: {'sessionId': sessionId, 'photoKey': photoKey},
    );
    final d = (res.data as Map).cast<String, dynamic>();
    return IdentityVerificationResult(
      verified: d['verified'] as bool? ?? false,
      status: d['status'] as String? ?? 'failed',
      badgeSig: d['badgeSig'] as String?,
      reason: d['reason'] as String?,
      livenessConfidence: (d['livenessConfidence'] as num?)?.toDouble(),
      faceSimilarity: (d['faceSimilarity'] as num?)?.toDouble(),
    );
  }
}

/// One verification attempt opened by [VerificationApi.start].
class VerificationSession {
  const VerificationSession({
    required this.sessionId,
    required this.photoUploadUrl,
    required this.photoKey,
  });

  /// Rekognition Face Liveness session id for the native liveness UI.
  final String sessionId;

  /// Presigned S3 PUT URL for the reference photo (short TTL).
  final String photoUploadUrl;

  /// S3 key the photo lands under — echoed back to `complete`.
  final String photoKey;
}

/// Outcome of the backend identity-verification call.
class IdentityVerificationResult {
  const IdentityVerificationResult({
    required this.verified,
    required this.status,
    this.badgeSig,
    this.reason,
    this.livenessConfidence,
    this.faceSimilarity,
  });

  /// `true` only when the subject was live AND matched the profile photo.
  final bool verified;

  /// `'verified' | 'failed'`.
  final String status;

  /// Server-issued badge signature, present only when [verified].
  final String? badgeSig;

  /// `'liveness_failed' | 'face_mismatch'` when not verified.
  final String? reason;

  final double? livenessConfidence;
  final double? faceSimilarity;
}
