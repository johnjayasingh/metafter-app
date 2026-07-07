import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashlib;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// On-device identity + E2E encryption (ARCHITECTURE.md §3).
///
/// Key material:
///  * Ed25519 identity keypair — signs cards, requests, messages.
///  * X25519 agreement keypair — peers seal payloads to its public half.
///  * bleSeed (32 random bytes) — derives rotating BLE ephemeral ids.
/// All three live in the platform keychain/keystore and never leave the
/// device (public halves excepted).
///
/// Sealing uses ephemeral-static X25519 → HKDF-SHA256 → ChaCha20-Poly1305:
/// a fresh ephemeral keypair per payload, so the wire format is
/// (ephPub, nonce, ct) — matching `Envelope` and BLE frames alike.
class CryptoService {
  CryptoService._();

  static final CryptoService instance = CryptoService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kEdKey = 'crypto.ed25519';
  static const _kXKey = 'crypto.x25519';
  static const _kSeedKey = 'crypto.bleSeed';

  final _ed = Ed25519();
  final _x = X25519();
  final _aead = Chacha20.poly1305Aead();

  SimpleKeyPair? _edPair;
  SimpleKeyPair? _xPair;
  List<int>? _bleSeed;

  String? _edPubB64;
  String? _xPubB64;

  bool get isInitialized => _edPair != null;

  /// Base64 public halves — published to the directory and embedded in the
  /// profile card. Only valid after [init].
  String get ed25519PubB64 => _edPubB64!;
  String get x25519PubB64 => _xPubB64!;

  /// Load persisted keys or generate them on first run.
  Future<void> init() async {
    if (isInitialized) return;

    final edSeed = await _loadOrCreate(_kEdKey);
    final xSeed = await _loadOrCreate(_kXKey);
    _bleSeed = await _loadOrCreate(_kSeedKey);

    _edPair = await _ed.newKeyPairFromSeed(edSeed);
    _xPair = await _x.newKeyPairFromSeed(xSeed);

    _edPubB64 =
        base64Encode((await _edPair!.extractPublicKey()).bytes);
    _xPubB64 = base64Encode((await _xPair!.extractPublicKey()).bytes);
  }

  Future<List<int>> _loadOrCreate(String key) async {
    final existing = await _storage.read(key: key);
    if (existing != null) return base64Decode(existing);
    final rng = math.Random.secure();
    final fresh = List<int>.generate(32, (_) => rng.nextInt(256));
    await _storage.write(key: key, value: base64Encode(fresh));
    return fresh;
  }

  /// Wipe all key material (sign-out / account deletion).
  Future<void> wipe() async {
    await _storage.delete(key: _kEdKey);
    await _storage.delete(key: _kXKey);
    await _storage.delete(key: _kSeedKey);
    _edPair = null;
    _xPair = null;
    _bleSeed = null;
    _edPubB64 = null;
    _xPubB64 = null;
  }

  // -------------------------------------------------------------------------
  // BLE ephemeral id
  // -------------------------------------------------------------------------

  /// Rotating ephemeral id: first 8 bytes of HMAC-SHA256(bleSeed, epoch/15min)
  /// as lowercase hex. Rotates every 15 minutes.
  String currentEid([DateTime? now]) {
    final t = (now ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    final window = t ~/ (15 * 60 * 1000);
    final mac = hashlib.Hmac(hashlib.sha256, _bleSeed!)
        .convert(utf8.encode(window.toString()));
    return mac.bytes
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  // -------------------------------------------------------------------------
  // Seal / open (ephemeral-static X25519 + HKDF + ChaCha20-Poly1305)
  // -------------------------------------------------------------------------

  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static const _hkdfInfo = 'metafter/v1/seal';

  /// Encrypt [plaintext] so only the holder of [recipientX25519PubB64] can
  /// read it. Returns (ephPub, nonce, ciphertext) — all base64.
  Future<SealedBox> seal(
      String recipientX25519PubB64, List<int> plaintext) async {
    final eph = await _x.newKeyPair();
    final shared = await _x.sharedSecretKey(
      keyPair: eph,
      remotePublicKey: SimplePublicKey(
        base64Decode(recipientX25519PubB64),
        type: KeyPairType.x25519,
      ),
    );
    final key = await _hkdf.deriveKey(
      secretKey: shared,
      info: utf8.encode(_hkdfInfo),
    );
    final nonce = _aead.newNonce();
    final box = await _aead.encrypt(plaintext, secretKey: key, nonce: nonce);
    return SealedBox(
      ephPubB64:
          base64Encode((await eph.extractPublicKey()).bytes),
      nonceB64: base64Encode(nonce),
      ciphertextB64: base64Encode(box.cipherText + box.mac.bytes),
    );
  }

  /// Decrypt a box sealed to our static X25519 key. Throws on tamper.
  Future<Uint8List> open(SealedBox sealed) async {
    final shared = await _x.sharedSecretKey(
      keyPair: _xPair!,
      remotePublicKey: SimplePublicKey(
        base64Decode(sealed.ephPubB64),
        type: KeyPairType.x25519,
      ),
    );
    final key = await _hkdf.deriveKey(
      secretKey: shared,
      info: utf8.encode(_hkdfInfo),
    );
    final raw = base64Decode(sealed.ciphertextB64);
    const macLen = 16;
    final box = SecretBox(
      raw.sublist(0, raw.length - macLen),
      nonce: base64Decode(sealed.nonceB64),
      mac: Mac(raw.sublist(raw.length - macLen)),
    );
    final clear = await _aead.decrypt(box, secretKey: key);
    return Uint8List.fromList(clear);
  }

  /// Convenience: seal a JSON object.
  Future<SealedBox> sealJson(
          String recipientX25519PubB64, Map<String, dynamic> json) =>
      seal(recipientX25519PubB64, utf8.encode(jsonEncode(json)));

  /// Convenience: open to a JSON object.
  Future<Map<String, dynamic>> openJson(SealedBox sealed) async =>
      jsonDecode(utf8.decode(await open(sealed))) as Map<String, dynamic>;

  // -------------------------------------------------------------------------
  // Signatures
  // -------------------------------------------------------------------------

  /// Ed25519 signature over [data], base64.
  Future<String> sign(List<int> data) async {
    final sig = await _ed.sign(data, keyPair: _edPair!);
    return base64Encode(sig.bytes);
  }

  /// Canonical signing helper for JSON payloads: signs the UTF-8 of the JSON
  /// with its 'sig' key removed and keys sorted.
  Future<String> signJson(Map<String, dynamic> json) =>
      sign(utf8.encode(_canonical(json)));

  Future<bool> verify(
      String ed25519PubB64, String sigB64, List<int> data) async {
    try {
      return await _ed.verify(
        data,
        signature: Signature(
          base64Decode(sigB64),
          publicKey: SimplePublicKey(
            base64Decode(ed25519PubB64),
            type: KeyPairType.ed25519,
          ),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyJson(String ed25519PubB64, Map<String, dynamic> json) {
    final sig = json['sig'] as String?;
    if (sig == null) return Future.value(false);
    return verify(ed25519PubB64, sig, utf8.encode(_canonical(json)));
  }

  static String _canonical(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json)..remove('sig');
    final sorted = Map.fromEntries(
        copy.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return jsonEncode(sorted);
  }
}

class SealedBox {
  const SealedBox({
    required this.ephPubB64,
    required this.nonceB64,
    required this.ciphertextB64,
  });

  final String ephPubB64;
  final String nonceB64;
  final String ciphertextB64;
}
