import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists Cognito sessions (id/access/refresh tokens) in the platform
/// secure store so `getCurrentUser()` / `getSession()` survive app restarts
/// and can refresh silently.
class SecureCognitoStorage extends CognitoStorage {
  SecureCognitoStorage(this._storage);

  final FlutterSecureStorage _storage;

  // Namespacing avoids colliding with the app's own secure-storage keys.
  String _k(String key) => 'cognito.$key';

  @override
  Future<String?> getItem(String key) => _storage.read(key: _k(key));

  @override
  Future<String> setItem(String key, dynamic value) async {
    await _storage.write(key: _k(key), value: value.toString());
    return value.toString();
  }

  @override
  Future<String?> removeItem(String key) async {
    final existing = await _storage.read(key: _k(key));
    await _storage.delete(key: _k(key));
    return existing;
  }

  @override
  Future<void> clear() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith('cognito.')) {
        await _storage.delete(key: key);
      }
    }
  }
}
