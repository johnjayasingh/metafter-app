import 'dart:io';

import '../auth/cognito_auth_service.dart';
import '../config/environment_config.dart';
import '../network/profile_api.dart';
import 'face_liveness_channel.dart';

/// Orchestrates signup identity verification:
///   upload profile photo → open liveness session → run native liveness UI
///   → (later) resolve the server-side verdict.
class FaceVerificationService {
  FaceVerificationService._();
  static final FaceVerificationService instance = FaceVerificationService._();

  final ProfileApi _profile = ProfileApi();

  /// Ensures the profile photo is uploaded, opens a Rekognition liveness
  /// session, and presents the native liveness UI. Returns the session id to
  /// later [resolve]. Throws [FaceLivenessException] if liveness can't run.
  Future<String> startLiveness({String? photoPath}) async {
    final creds = await CognitoAuthService.instance.awsCredentials();
    if (creds == null) {
      throw FaceLivenessException(
        'no_credentials',
        'Could not obtain AWS credentials. Please sign in again.',
      );
    }

    // The backend matches the live frame against the stored profile photo, so
    // make sure it's uploaded before the session is verified.
    if (photoPath != null && photoPath.isNotEmpty) {
      await _profile.uploadPhoto(File(photoPath));
    }

    final sessionId = await _profile.createLivenessSession();
    await FaceLivenessChannel.start(
      sessionId: sessionId,
      region: EnvironmentConfig.region,
      accessKeyId: creds.accessKeyId,
      secretAccessKey: creds.secretAccessKey,
      sessionToken: creds.sessionToken,
    );
    return sessionId;
  }

  /// Resolves the server-side verdict for a completed liveness [sessionId].
  Future<IdentityVerificationResult> resolve(String sessionId) {
    return _profile.verifyIdentity(sessionId);
  }
}
