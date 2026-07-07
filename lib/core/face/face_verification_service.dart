import 'dart:io';

import '../auth/cognito_auth_service.dart';
import '../config/environment_config.dart';
import '../network/profile_api.dart';
import 'face_liveness_channel.dart';

/// Orchestrates signup identity verification against the stateless backend
/// (`/v1/verification/*`):
///   start (liveness session + presigned photo PUT) → upload reference photo
///   → run native liveness UI → resolve via `complete(sessionId, photoKey)`.
class FaceVerificationService {
  FaceVerificationService._();
  static final FaceVerificationService instance = FaceVerificationService._();

  final VerificationApi _api = VerificationApi();

  /// Opens a verification attempt, uploads the reference photo to the
  /// presigned URL, and presents the native liveness UI. Returns the session
  /// (id + photoKey) to later [resolve]. Throws [FaceLivenessException] if
  /// liveness can't run (unavailable devices stay skippable — callers catch
  /// `isUnavailable`).
  Future<VerificationSession> startLiveness({String? photoPath}) async {
    final creds = await CognitoAuthService.instance.awsCredentials();
    if (creds == null) {
      throw FaceLivenessException(
        'no_credentials',
        'Could not obtain AWS credentials. Please sign in again.',
      );
    }

    final session = await _api.start();

    // The backend matches the live frame against this reference photo, so it
    // must be uploaded before the session is completed. It lives only under
    // a tmp/ key and is deleted server-side after the comparison.
    if (photoPath != null && photoPath.isNotEmpty) {
      await _api.uploadPhoto(File(photoPath), session.photoUploadUrl);
    }

    await FaceLivenessChannel.start(
      sessionId: session.sessionId,
      region: EnvironmentConfig.region,
      accessKeyId: creds.accessKeyId,
      secretAccessKey: creds.secretAccessKey,
      sessionToken: creds.sessionToken,
    );
    return session;
  }

  /// Resolves the server-side verdict for a completed liveness session.
  Future<IdentityVerificationResult> resolve(
    String sessionId,
    String photoKey,
  ) {
    return _api.complete(sessionId, photoKey);
  }
}
