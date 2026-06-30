import 'package:flutter/services.dart';

/// Thrown when the native Face Liveness flow is cancelled, errors, or is
/// unavailable on the current device/build (e.g. a simulator without a camera).
class FaceLivenessException implements Exception {
  FaceLivenessException(this.code, this.message);

  final String code;
  final String message;

  /// `true` when the platform plugin isn't present (simulator / unsupported).
  bool get isUnavailable => code == 'unavailable';

  @override
  String toString() => 'FaceLivenessException($code): $message';
}

/// Bridges to the native (iOS / Android) Amazon Rekognition Face Liveness UI.
///
/// The native side presents the official Amplify liveness component, streaming
/// the camera to Rekognition with the supplied temporary AWS credentials. The
/// pass/fail verdict is NOT decided here — it's resolved server-side via
/// `verify-identity` once the challenge completes.
class FaceLivenessChannel {
  FaceLivenessChannel._();

  static const MethodChannel _channel = MethodChannel('metafter/face_liveness');

  /// Presents the native liveness UI for [sessionId]. Completes when the user
  /// finishes the challenge; throws [FaceLivenessException] on cancel, error,
  /// or when the native plugin is unavailable.
  static Future<void> start({
    required String sessionId,
    required String region,
    required String accessKeyId,
    required String secretAccessKey,
    required String sessionToken,
  }) async {
    try {
      await _channel.invokeMethod<void>('startLiveness', <String, String>{
        'sessionId': sessionId,
        'region': region,
        'accessKeyId': accessKeyId,
        'secretAccessKey': secretAccessKey,
        'sessionToken': sessionToken,
      });
    } on MissingPluginException {
      throw FaceLivenessException(
        'unavailable',
        'Face Liveness is not available on this device.',
      );
    } on PlatformException catch (e) {
      throw FaceLivenessException(e.code, e.message ?? 'Face Liveness failed.');
    }
  }
}
