import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionKey = 'session';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _loginStepKey = 'login_step';
  static const String _willIdKey = 'will_id';

  // Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Session
  Future<void> saveSession(String session) async {
    await _storage.write(key: _sessionKey, value: session);
  }

  Future<String?> getSession() async {
    return await _storage.read(key: _sessionKey);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // User Email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  // Login Step
  Future<void> saveLoginStep(String step) async {
    await _storage.write(key: _loginStepKey, value: step);
  }

  Future<String?> getLoginStep() async {
    return await _storage.read(key: _loginStepKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear tokens only (for session timeout)
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _sessionKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Will ID
  Future<void> saveWillId(String willId) async {
    await _storage.write(key: _willIdKey, value: willId);
  }

  Future<String?> getWillId() async {
    return await _storage.read(key: _willIdKey);
  }

  Future<void> clearWillId() async {
    await _storage.delete(key: _willIdKey);
  }
}
