import 'envelope.dart';

/// Cloud relay client — the ONLY code path that talks to the backend after
/// signup. Combines:
///  * live channel: MQTT over WSS (AWS IoT Core; mosquitto in local flavor),
///    subscribed to `metafter/<stage>/u/<mySub>/inbox`;
///  * durable channel: REST mailbox (`GET/POST/DELETE /v1/mailbox`) with 72 h
///    TTL server-side;
///  * key directory: `POST /v1/directory`, `GET /v1/directory/{sub}`.
///
/// Envelopes are opaque to this layer — encryption/decryption happens in the
/// services above it.
abstract class TransportClient {
  /// Emits every inbound envelope exactly once (live MQTT deliveries and
  /// mailbox drains are deduped by envelope id). Implementations ACK the
  /// mailbox copy after the event is delivered to listeners.
  Stream<Envelope> get inbound;

  /// Connection state of the live channel (mailbox polling still works when
  /// false).
  bool get isConnected;

  /// Connect MQTT, subscribe to my inbox, then drain the mailbox.
  /// Reconnects with backoff until [disconnect] is called.
  Future<void> connect();

  Future<void> disconnect();

  /// Deposit an envelope for its recipient (POST /v1/mailbox). The server
  /// forwards it to the recipient's live inbox topic and stores it (TTL 72 h)
  /// until ACKed. Returns false on network failure — callers queue and retry.
  Future<bool> send(Envelope envelope);

  /// Force a mailbox drain (e.g. on app foreground or push wake-up).
  Future<void> drainMailbox();

  /// Publish my public key bundle + push token to the directory.
  Future<bool> publishDirectory({
    required String ed25519Pub,
    required String x25519Pub,
    String? pushToken,
  });

  /// Fetch a peer's key bundle. Returns null when unknown.
  Future<DirectoryEntry?> fetchDirectory(String sub);
}

class DirectoryEntry {
  const DirectoryEntry({
    required this.sub,
    required this.ed25519Pub,
    required this.x25519Pub,
    this.verified = false,
    this.verifiedBadgeSig,
  });

  final String sub;
  final String ed25519Pub;
  final String x25519Pub;
  final bool verified;
  final String? verifiedBadgeSig;

  static DirectoryEntry fromJson(Map<String, dynamic> j) => DirectoryEntry(
        sub: j['sub'] as String,
        ed25519Pub: j['edPub'] as String,
        x25519Pub: j['xPub'] as String,
        verified: j['verified'] as bool? ?? false,
        verifiedBadgeSig: j['badgeSig'] as String?,
      );
}
