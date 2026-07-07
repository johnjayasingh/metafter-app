import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../proximity/proximity_engine.dart';
import '../repositories/repositories.dart';
import '../transport/envelope.dart';
import '../transport/transport_client.dart';
import 'envelope_codec.dart';
import 'services.dart';

/// Connect-request lifecycle: Pro gating, BLE-first delivery with relay
/// fallback, accept/decline, disconnect (DESIGN_SPEC §5–§7, §11.3).
class ConnectionServiceImpl implements ConnectionService {
  ConnectionServiceImpl({
    required ProximityEngine engine,
    required TransportClient transport,
    required ProfileRepository profile,
    required RequestRepository requests,
    required ConnectionRepository connections,
    required EncounterRepository encounters,
    required SettingsRepository settings,
    EnvelopeCodec? codec,
    String Function()? newId,
    DateTime Function()? now,
  })  : _engine = engine,
        _transport = transport,
        _profile = profile,
        _requests = requests,
        _connections = connections,
        _encounters = encounters,
        _settings = settings,
        _codec = codec ?? EnvelopeCodec(),
        _newId = newId ?? const Uuid().v4,
        _now = now ?? DateTime.now;

  final ProximityEngine _engine;
  final TransportClient _transport;
  final ProfileRepository _profile;
  final RequestRepository _requests;
  final ConnectionRepository _connections;
  final EncounterRepository _encounters;
  final SettingsRepository _settings;
  final EnvelopeCodec _codec;
  final String Function() _newId;
  final DateTime Function() _now;

  @override
  Future<SendRequestOutcome> sendRequest({
    required ProfileCard toCard,
    String? note,
    String? encounterId,
  }) async {
    // --- Pro gating (DESIGN_SPEC §11.3) -----------------------------------
    final isPro = _settings.isPro.value;
    if (!isPro) {
      final today = _now();
      final midnight = DateTime(today.year, today.month, today.day);
      if (await _requests.countOutgoingSince(midnight) >=
          ProLimits.freeRequestsPerDay) {
        return SendRequestOutcome.quotaExceeded;
      }
    }
    if (note != null &&
        !isPro &&
        await _requests.countOutgoingWithNote() >= ProLimits.freeInviteNotes) {
      return SendRequestOutcome.noteQuotaExceeded;
    }

    // --- Persist the outgoing row first (single source of truth) ----------
    final requestId = _newId();
    await _requests.upsert(ConnectionRequest(
      id: requestId,
      direction: RequestDirection.outgoing,
      peerSub: toCard.sub,
      card: toCard,
      note: note,
      status: RequestStatus.pending,
      createdAt: _now(),
    ));
    if (encounterId != null) {
      await _encounters.markRequested(encounterId, requestId);
    }

    final myCard = await _profile.buildCard();
    final payload =
        ConnectRequestPayload(requestId: requestId, senderCard: myCard, note: note);

    // --- BLE first ---------------------------------------------------------
    if (toCard.sub.isNotEmpty && _engine.isNearby(toCard.sub)) {
      try {
        if (await _engine.sendRequest(toCard.sub, payload)) {
          return SendRequestOutcome.sentNearby;
        }
      } catch (e) {
        debugPrint('ConnectionService: BLE request to ${toCard.sub} '
            'failed, trying relay: $e');
      }
    }

    // --- Relay fallback ----------------------------------------------------
    if (toCard.sub.isEmpty) return SendRequestOutcome.failed;
    final delivered = await _sendEnvelope(
      to: toCard.sub,
      knownXPub: toCard.x25519Pub,
      kind: EnvelopeKind.connectRequest,
      plain: {
        'from': myCard.sub,
        'requestId': requestId,
        'card': myCard.toJson(),
        if (note != null) 'note': note,
      },
    );
    // The pending row is kept either way — the user can retry from Discover.
    return delivered ? SendRequestOutcome.sentRelay : SendRequestOutcome.failed;
  }

  @override
  Future<void> accept(ConnectionRequest request) async {
    await _requests.setStatus(request.id, RequestStatus.accepted);
    await _connections.upsert(Connection(
      peerSub: request.peerSub,
      card: request.card,
      connectedAt: _now(),
      moodAtMeet: _settings.mood.value,
    ));
    await _deliverResponse(request, accepted: true);
  }

  @override
  Future<void> decline(ConnectionRequest request) async {
    // Silent by design: no response payload/envelope leaves the device
    // (DESIGN_SPEC §7.2).
    await _requests.setStatus(request.id, RequestStatus.declined);
  }

  @override
  Future<void> disconnect(String peerSub) async {
    final connection = await _connections.byPeer(peerSub);
    // Best-effort notify; removal happens regardless.
    if (connection != null) {
      try {
        final myCard = await _profile.buildCard();
        final plain = <String, dynamic>{'from': myCard.sub};
        final xPub = connection.card.x25519Pub;
        if (xPub != null) {
          final envelope = await _codec.sealSigned(
            to: peerSub,
            kind: EnvelopeKind.disconnect,
            plain: plain,
            recipientX25519PubB64: xPub,
          );
          var sent = false;
          if (_engine.isNearby(peerSub)) {
            sent = await _engine.sendFrame(
                peerSub, EnvelopeCodec.frameFromEnvelope(envelope));
          }
          if (!sent) await _transport.send(envelope);
        }
      } catch (e) {
        debugPrint('ConnectionService: disconnect notify to $peerSub '
            'failed: $e');
      }
    }
    await _connections.remove(peerSub);
  }

  Future<void> _deliverResponse(ConnectionRequest request,
      {required bool accepted}) async {
    final myCard = await _profile.buildCard();
    final payload = ConnectResponsePayload(
      requestId: request.id,
      accepted: accepted,
      responderCard: myCard,
    );

    if (_engine.isNearby(request.peerSub)) {
      try {
        if (await _engine.sendResponse(request.peerSub, payload)) return;
      } catch (e) {
        debugPrint('ConnectionService: BLE response to ${request.peerSub} '
            'failed, trying relay: $e');
      }
    }

    await _sendEnvelope(
      to: request.peerSub,
      knownXPub: request.card.x25519Pub,
      kind: EnvelopeKind.connectResponse,
      plain: {
        'from': myCard.sub,
        'requestId': request.id,
        'accepted': accepted,
        'card': myCard.toJson(),
      },
    );
  }

  /// Sign + seal [plain] to the peer and deposit it with the relay.
  /// Fetches the peer's keys from the directory when [knownXPub] is missing.
  Future<bool> _sendEnvelope({
    required String to,
    required String? knownXPub,
    required String kind,
    required Map<String, dynamic> plain,
  }) async {
    var xPub = knownXPub;
    if (xPub == null) {
      final entry = await _transport.fetchDirectory(to);
      xPub = entry?.x25519Pub;
    }
    if (xPub == null) {
      debugPrint('ConnectionService: no X25519 key for $to — cannot relay');
      return false;
    }
    try {
      final envelope = await _codec.sealSigned(
        to: to,
        kind: kind,
        plain: plain,
        recipientX25519PubB64: xPub,
      );
      return await _transport.send(envelope);
    } catch (e) {
      debugPrint('ConnectionService: relay $kind to $to failed: $e');
      return false;
    }
  }
}
