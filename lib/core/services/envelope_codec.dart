import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../crypto/crypto_service.dart';
import '../transport/envelope.dart';

/// Signs a JSON payload (canonical form, 'sig' excluded) and returns the
/// base64 Ed25519 signature. Defaults to [CryptoService.signJson]; tests
/// inject fakes.
typedef JsonSigner = Future<String> Function(Map<String, dynamic> json);

/// Seals a JSON payload to a recipient X25519 public key (base64). Defaults
/// to [CryptoService.sealJson]; tests inject fakes.
typedef JsonSealer = Future<SealedBox> Function(
    String recipientX25519PubB64, Map<String, dynamic> json);

/// Builds signed, sealed [Envelope]s and converts them to/from the opaque
/// byte frames carried over BLE.
///
/// BLE frames and relay envelopes share one wire shape on purpose: a frame is
/// simply the UTF-8 JSON of an [Envelope]. That lets [EnvelopeRouter] treat
/// both arrival paths identically.
class EnvelopeCodec {
  EnvelopeCodec({JsonSigner? signer, JsonSealer? sealer, String Function()? newId})
      : _signer = signer ?? CryptoService.instance.signJson,
        _sealer = sealer ?? CryptoService.instance.sealJson,
        _newId = newId ?? const Uuid().v4;

  final JsonSigner _signer;
  final JsonSealer _sealer;
  final String Function() _newId;

  /// Signs [plain] (adding its 'sig' key), seals it to
  /// [recipientX25519PubB64], and wraps the result in an [Envelope] addressed
  /// to [to].
  Future<Envelope> sealSigned({
    required String to,
    required String kind,
    required Map<String, dynamic> plain,
    required String recipientX25519PubB64,
  }) async {
    final signed = Map<String, dynamic>.from(plain)
      ..['sig'] = await _signer(plain);
    final box = await _sealer(recipientX25519PubB64, signed);
    return Envelope(
      id: _newId(),
      to: to,
      kind: kind,
      ephPub: box.ephPubB64,
      nonce: box.nonceB64,
      ciphertext: box.ciphertextB64,
    );
  }

  /// Serializes an [Envelope] into the opaque frame written to the BLE
  /// InRangeMessage characteristic.
  static Uint8List frameFromEnvelope(Envelope envelope) =>
      Uint8List.fromList(utf8.encode(envelope.encode()));

  /// Parses a BLE frame back into an [Envelope]. Returns null when the bytes
  /// are not a valid envelope (garbage from a misbehaving peer).
  static Envelope? envelopeFromFrame(Uint8List frame) {
    try {
      return Envelope.decode(utf8.decode(frame));
    } catch (_) {
      return null;
    }
  }
}
