import 'dart:convert';

/// E2E-encrypted relay envelope (ARCHITECTURE.md §4.1).
///
/// The only routing metadata the server can read is [to]. Sender identity and
/// the actual payload live inside [ciphertext], sealed to the recipient's
/// X25519 key.
class Envelope {
  const Envelope({
    this.v = 1,
    required this.id,
    required this.to,
    required this.kind,
    required this.ephPub,
    required this.nonce,
    required this.ciphertext,
  });

  final int v;

  /// Unique envelope id (uuid v4) — used for mailbox ACK/dedup.
  final String id;

  /// Recipient account id (Cognito sub).
  final String to;

  /// One of [EnvelopeKind].
  final String kind;

  /// Sender's ephemeral X25519 public key, base64.
  final String ephPub;

  /// AEAD nonce, base64.
  final String nonce;

  /// base64 ciphertext. Plaintext is a JSON object; see [EnvelopeKind] docs.
  final String ciphertext;

  Map<String, dynamic> toJson() => {
        'v': v,
        'id': id,
        'to': to,
        'kind': kind,
        'eph': ephPub,
        'n': nonce,
        'ct': ciphertext,
      };

  static Envelope fromJson(Map<String, dynamic> j) => Envelope(
        v: j['v'] as int? ?? 1,
        id: j['id'] as String,
        to: j['to'] as String,
        kind: j['kind'] as String,
        ephPub: j['eph'] as String,
        nonce: j['n'] as String,
        ciphertext: j['ct'] as String,
      );

  String encode() => jsonEncode(toJson());
  static Envelope decode(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// Envelope kinds and their decrypted plaintext shapes.
///
/// Every plaintext JSON includes `from` (sender sub) and `sig` (base64
/// Ed25519 signature by the sender over the canonical payload) so recipients
/// authenticate senders end-to-end.
abstract final class EnvelopeKind {
  /// {from, sig, requestId, card: ProfileCard.toJson(), note?}
  static const connectRequest = 'connect.request';

  /// {from, sig, requestId, accepted: bool, card: ProfileCard.toJson()}
  static const connectResponse = 'connect.response';

  /// {from, sig, messageId, body, sentAt: iso8601, expiresInSec?}
  static const message = 'message';

  /// {from, sig, messageId, status: 'delivered'|'read'} — receipts.
  /// Also used for reactions: `{from, sig, messageId, reaction: '😊'}`.
  static const receipt = 'receipt';

  /// {from, sig} — peer removed the connection; wipe keys, mark thread.
  static const disconnect = 'disconnect';
}
