import 'dart:async';

import 'package:flutter/foundation.dart';

import '../crypto/crypto_service.dart';
import '../proximity/proximity_engine.dart';
import '../repositories/repositories.dart';
import '../transport/envelope.dart';
import '../transport/transport_client.dart';
import 'envelope_codec.dart';
import 'inbound_handler.dart';

/// Opens a sealed box to its plaintext JSON. Defaults to
/// [CryptoService.openJson]; tests inject fakes.
typedef JsonOpener = Future<Map<String, dynamic>> Function(SealedBox sealed);

/// Verifies the 'sig' of a JSON payload against an Ed25519 pub key (base64).
/// Defaults to [CryptoService.verifyJson]; tests inject fakes.
typedef JsonVerifier = Future<bool> Function(
    String ed25519PubB64, Map<String, dynamic> json);

/// Decrypts + authenticates inbound envelopes and dispatches them to
/// [InboundHandler].
///
/// Two entry points, one behaviour:
///  * [start] subscribes to [TransportClient.inbound] (relay);
///  * [handleFrame] is called by SessionService for BLE
///    [PeerFrameReceived] events (frames are envelope JSON — see
///    [EnvelopeCodec]).
///
/// Anything that fails to decrypt, parse, or verify is dropped with a log —
/// never surfaced to repositories.
class EnvelopeRouter {
  EnvelopeRouter({
    required TransportClient transport,
    required ConnectionRepository connections,
    required InboundHandler handler,
    JsonOpener? opener,
    JsonVerifier? verifier,
  })  : _transport = transport,
        _connections = connections,
        _handler = handler,
        _opener = opener ?? CryptoService.instance.openJson,
        _verifier = verifier ?? CryptoService.instance.verifyJson;

  final TransportClient _transport;
  final ConnectionRepository _connections;
  final InboundHandler _handler;
  final JsonOpener _opener;
  final JsonVerifier _verifier;

  StreamSubscription<Envelope>? _sub;

  /// Begin routing relay envelopes. Idempotent.
  void start() {
    _sub ??= _transport.inbound.listen(
      (e) => route(e, via: InboundVia.relay),
      onError: (Object e) => debugPrint('EnvelopeRouter: inbound error: $e'),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Entry point for BLE frames ([PeerFrameReceived]).
  Future<void> handleFrame(String senderSub, Uint8List frame) async {
    final envelope = EnvelopeCodec.envelopeFromFrame(frame);
    if (envelope == null) {
      debugPrint('EnvelopeRouter: undecodable BLE frame from $senderSub');
      return;
    }
    await route(envelope, via: InboundVia.ble);
  }

  /// Decrypt, verify and dispatch one envelope.
  @visibleForTesting
  Future<void> route(Envelope envelope, {required InboundVia via}) async {
    Map<String, dynamic> plain;
    try {
      plain = await _opener(SealedBox(
        ephPubB64: envelope.ephPub,
        nonceB64: envelope.nonce,
        ciphertextB64: envelope.ciphertext,
      ));
    } catch (e) {
      debugPrint('EnvelopeRouter: cannot open ${envelope.kind} '
          '${envelope.id}: $e — dropped');
      return;
    }

    final from = plain['from'] as String?;
    if (from == null || from.isEmpty) {
      debugPrint('EnvelopeRouter: ${envelope.kind} without from — dropped');
      return;
    }

    try {
      switch (envelope.kind) {
        case EnvelopeKind.connectRequest:
          await _routeRequest(from, plain, via);
        case EnvelopeKind.connectResponse:
          await _routeResponse(from, plain);
        case EnvelopeKind.message:
          if (!await _verifiedAgainstConnection(from, plain)) return;
          await _handler.handleMessage(
            from: from,
            messageId: plain['messageId'] as String,
            body: plain['body'] as String,
            sentAt: DateTime.parse(plain['sentAt'] as String),
            expiresInSec: plain['expiresInSec'] as int?,
          );
        case EnvelopeKind.receipt:
          if (!await _verifiedAgainstConnection(from, plain)) return;
          await _handler.handleReceipt(
            from: from,
            messageId: plain['messageId'] as String,
            status: plain['status'] as String?,
            reaction: plain['reaction'] as String?,
            hasReaction: plain.containsKey('reaction'),
          );
        case EnvelopeKind.disconnect:
          if (!await _verifiedAgainstConnection(from, plain)) return;
          await _handler.handleDisconnect(from);
        default:
          debugPrint('EnvelopeRouter: unknown kind "${envelope.kind}"');
      }
    } catch (e) {
      // Malformed payload shapes must never take the router down.
      debugPrint('EnvelopeRouter: malformed ${envelope.kind} from $from: $e');
    }
  }

  Future<void> _routeRequest(
      String from, Map<String, dynamic> plain, InboundVia via) async {
    final payload = ConnectRequestPayload.fromJson({
      'requestId': plain['requestId'],
      'card': plain['card'],
      if (plain['note'] != null) 'note': plain['note'],
    });
    // Requests carry the sender's card; its key is the trust anchor, so the
    // card must actually belong to the claimed sender.
    final edPub = payload.senderCard.ed25519Pub;
    if (payload.senderCard.sub != from || edPub == null) {
      debugPrint('EnvelopeRouter: request card/sub mismatch from $from');
      return;
    }
    if (!await _verifier(edPub, plain)) {
      debugPrint('EnvelopeRouter: bad signature on request from $from');
      return;
    }
    await _handler.handleRequest(payload, via: via);
  }

  Future<void> _routeResponse(String from, Map<String, dynamic> plain) async {
    final payload = ConnectResponsePayload.fromJson({
      'requestId': plain['requestId'],
      'accepted': plain['accepted'],
      'card': plain['card'],
    });
    final edPub = payload.responderCard.ed25519Pub;
    if (payload.responderCard.sub != from || edPub == null) {
      debugPrint('EnvelopeRouter: response card/sub mismatch from $from');
      return;
    }
    if (!await _verifier(edPub, plain)) {
      debugPrint('EnvelopeRouter: bad signature on response from $from');
      return;
    }
    await _handler.handleResponse(payload);
  }

  /// Verify the payload signature against the sender's known identity key —
  /// the connection's card, falling back to the key directory.
  Future<bool> _verifiedAgainstConnection(
      String from, Map<String, dynamic> plain) async {
    var edPub = (await _connections.byPeer(from))?.card.ed25519Pub;
    if (edPub == null) {
      final entry = await _transport.fetchDirectory(from);
      edPub = entry?.ed25519Pub;
    }
    if (edPub == null) {
      debugPrint('EnvelopeRouter: no identity key for $from — dropped');
      return false;
    }
    if (!await _verifier(edPub, plain)) {
      debugPrint('EnvelopeRouter: bad signature from $from — dropped');
      return false;
    }
    return true;
  }
}
