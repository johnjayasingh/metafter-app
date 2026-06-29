import 'dart:math';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/environment_config.dart';
import '../storage/secure_storage_service.dart';
import 'secure_cognito_storage.dart';

/// AWS credentials (from the Cognito Identity Pool) used to SigV4-sign the
/// IoT MQTT WSS connection.
class AwsSessionCredentials {
  AwsSessionCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
  });

  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;
}

/// Passwordless phone-OTP auth against the Cognito User Pool using the
/// CUSTOM_AUTH flow (Define/Create/Verify challenge Lambdas on the backend).
///
/// The pool requires `email`, so we register each user with a deterministic
/// synthetic address derived from the phone number. The user never sees or
/// uses a password — a throwaway compliant one is generated at sign-up.
class CognitoAuthService {
  CognitoAuthService._();
  static final CognitoAuthService instance = CognitoAuthService._();

  final SecureStorageService _appStorage = SecureStorageService();

  CognitoUserPool? _pool;
  CognitoUser? _pendingUser; // held between startSignIn() and answerOtp()

  CognitoUserPool get _userPool {
    return _pool ??= CognitoUserPool(
      EnvironmentConfig.cognitoUserPoolId,
      EnvironmentConfig.cognitoClientId,
      storage: SecureCognitoStorage(const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      )),
    );
  }

  // --- Identity helpers ----------------------------------------------------

  /// Normalizes a phone number to E.164 digits and derives the Cognito
  /// username (never email- or phone-format, so it can't clash with aliases).
  String _digits(String e164) => e164.replaceAll(RegExp(r'[^0-9]'), '');
  String _usernameFor(String e164) => 'ph${_digits(e164)}';
  String _syntheticEmailFor(String e164) => 'ph${_digits(e164)}@phone.metafter.app';

  /// Generates a throwaway password that satisfies the pool policy
  /// (min 8, upper + lower + digit). It is immediately discarded.
  String _randomPassword() {
    const lower = 'abcdefghijkmnpqrstuvwxyz';
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const digits = '23456789';
    final rnd = Random.secure();
    String pick(String s, int n) =>
        List.generate(n, (_) => s[rnd.nextInt(s.length)]).join();
    return '${pick(upper, 3)}${pick(lower, 6)}${pick(digits, 4)}';
  }

  // --- Flow ----------------------------------------------------------------

  /// Registers the phone number if new. Safe to call before every sign-in:
  /// an already-registered number is treated as success.
  Future<void> signUpWithPhone(String e164) async {
    final e164Norm = '+${_digits(e164)}';
    try {
      await _userPool.signUp(
        _usernameFor(e164),
        _randomPassword(),
        userAttributes: [
          AttributeArg(name: 'phone_number', value: e164Norm),
          AttributeArg(name: 'email', value: _syntheticEmailFor(e164)),
        ],
      );
    } on CognitoClientException catch (e) {
      // Existing user → fine, proceed to sign-in.
      if (e.code == 'UsernameExistsException') return;
      rethrow;
    }
  }

  /// Begins CUSTOM_AUTH; the backend createAuthChallenge Lambda sends the SMS
  /// OTP. Returns once the challenge has been issued.
  Future<void> startSignIn(String e164) async {
    final user = CognitoUser(_usernameFor(e164), _userPool);
    _pendingUser = user;
    try {
      final session = await user.initiateAuth(AuthenticationDetails(authParameters: []));
      // CUSTOM_AUTH should always present a challenge; a direct session here
      // is unexpected but means we're already authed.
      if (session != null) {
        await _persistSession(session, e164);
        _pendingUser = null;
      }
    } on CognitoUserCustomChallengeException {
      // Expected: OTP SMS sent, await answerOtp().
    }
  }

  /// Submits the OTP. Returns true on success; throws on a wrong/expired code.
  Future<bool> answerOtp(String code) async {
    final user = _pendingUser;
    if (user == null) {
      throw StateError('answerOtp called before startSignIn');
    }
    final session = await user.sendCustomChallengeAnswer(code);
    if (session == null) return false;
    await _persistSession(session, null);
    _pendingUser = null;
    return true;
  }

  Future<void> _persistSession(CognitoUserSession session, String? e164) async {
    final sub = session.getIdToken().getSub();
    if (sub != null) await _appStorage.saveUserId(sub);
    if (e164 != null) await _appStorage.saveUserEmail(_syntheticEmailFor(e164));
  }

  // --- Token / credentials access -----------------------------------------

  /// Returns a valid Cognito **ID token** (the API Gateway authorizer + the
  /// handlers read `claims.sub` from it), refreshing silently if needed.
  Future<String?> idToken() async {
    final user = await _userPool.getCurrentUser();
    if (user == null) return null;
    final session = await user.getSession();
    if (session == null || !session.isValid()) return null;
    return session.getIdToken().getJwtToken();
  }

  Future<String?> currentSub() async {
    final user = await _userPool.getCurrentUser();
    final session = await user?.getSession();
    return session?.getIdToken().getSub();
  }

  Future<bool> isSignedIn() async => (await idToken()) != null;

  /// Exchanges the ID token for temporary AWS credentials from the Identity
  /// Pool, used to SigV4-sign the IoT MQTT WSS URL.
  Future<AwsSessionCredentials?> awsCredentials() async {
    final id = await idToken();
    if (id == null) return null;
    final creds = CognitoCredentials(
      EnvironmentConfig.cognitoIdentityPoolId,
      _userPool,
    );
    await creds.getAwsCredentials(id);
    if (creds.accessKeyId == null ||
        creds.secretAccessKey == null ||
        creds.sessionToken == null) {
      return null;
    }
    return AwsSessionCredentials(
      accessKeyId: creds.accessKeyId!,
      secretAccessKey: creds.secretAccessKey!,
      sessionToken: creds.sessionToken!,
    );
  }

  Future<void> signOut() async {
    final user = await _userPool.getCurrentUser();
    await user?.signOut();
    _pendingUser = null;
    await _appStorage.clearTokens();
  }
}
