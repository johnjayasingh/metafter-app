import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../proximity/proximity_engine.dart';
import '../repositories/repositories.dart';
import '../transport/envelope.dart';
import '../transport/transport_client.dart';
import 'envelope_codec.dart';
import 'services.dart';

/// E2E chat delivery: BLE frames when the peer is in range, sealed relay
/// envelopes otherwise (DESIGN_SPEC §9–§10).
class MessageServiceImpl implements MessageService {
  MessageServiceImpl({
    required ProximityEngine engine,
    required TransportClient transport,
    required ProfileRepository profile,
    required ConnectionRepository connections,
    required MessageRepository messages,
    required SettingsRepository settings,
    EnvelopeCodec? codec,
    String Function()? newId,
    DateTime Function()? now,
  })  : _engine = engine,
        _transport = transport,
        _profile = profile,
        _connections = connections,
        _messages = messages,
        _settings = settings,
        _codec = codec ?? EnvelopeCodec(),
        _newId = newId ?? const Uuid().v4,
        _now = now ?? DateTime.now;

  final ProximityEngine _engine;
  final TransportClient _transport;
  final ProfileRepository _profile;
  final ConnectionRepository _connections;
  final MessageRepository _messages;
  final SettingsRepository _settings;
  final EnvelopeCodec _codec;
  final String Function() _newId;
  final DateTime Function() _now;

  Timer? _sweepTimer;

  /// Kick off the disappearing-messages sweep (once at start, then every
  /// minute). Called from bootstrap; safe to call more than once.
  void start() {
    if (_sweepTimer != null) return;
    unawaited(_messages.sweepExpired());
    _sweepTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_messages.sweepExpired()),
    );
  }

  void dispose() {
    _sweepTimer?.cancel();
    _sweepTimer = null;
  }

  @override
  Future<void> send(String peerSub, String body) async {
    final connection = await _connections.byPeer(peerSub);
    if (connection == null) {
      throw StateError('No connection with $peerSub');
    }

    final now = _now();
    final ttl = await _threadTtl(peerSub);
    final message = ChatMessage(
      id: _newId(),
      peerSub: peerSub,
      fromMe: true,
      body: body,
      sentAt: now,
      status: MessageStatus.sending,
      expiresAt: ttl == null ? null : now.add(ttl),
    );
    await _messages.append(message, card: connection.card);

    final delivered = await _deliver(
      peerSub: peerSub,
      knownXPub: connection.card.x25519Pub,
      kind: EnvelopeKind.message,
      plain: {
        'from': _mySub(),
        'messageId': message.id,
        'body': body,
        'sentAt': now.toUtc().toIso8601String(),
        if (ttl != null) 'expiresInSec': ttl.inSeconds,
      },
    );
    // On failure the bubble stays in `sending` — visible to the user and
    // eligible for a future retry pass.
    if (delivered) await _messages.setStatus(message.id, MessageStatus.sent);
  }

  @override
  Future<void> react(String peerSub, String messageId, String? emoji) async {
    await _messages.setReaction(messageId, emoji);
    await _sendReceiptPayload(peerSub, {
      'from': _mySub(),
      'messageId': messageId,
      'reaction': emoji, // null clears the reaction on the peer's side too
    });
  }

  @override
  Future<void> markRead(String peerSub) async {
    List<ChatMessage> unread = const [];
    if (_settings.readReceipts.value) {
      final thread = await _messages.watchThread(peerSub).first;
      unread = thread
          .where((m) => !m.fromMe && m.status != MessageStatus.read)
          .toList();
    }
    await _messages.markThreadRead(peerSub);
    for (final message in unread) {
      await sendReceipt(peerSub, message.id, 'read');
    }
  }

  @override
  bool isPeerNearby(String peerSub) => _engine.isNearby(peerSub);

  /// Send a delivery/read receipt. Also the [InboundHandler] plumbing for
  /// delivered receipts on inbound messages.
  Future<void> sendReceipt(
      String peerSub, String messageId, String status) async {
    await _sendReceiptPayload(peerSub, {
      'from': _mySub(),
      'messageId': messageId,
      'status': status,
    });
  }

  Future<void> _sendReceiptPayload(
      String peerSub, Map<String, dynamic> plain) async {
    final connection = await _connections.byPeer(peerSub);
    if (connection == null) return; // disconnected meanwhile — nothing to do
    await _deliver(
      peerSub: peerSub,
      knownXPub: connection.card.x25519Pub,
      kind: EnvelopeKind.receipt,
      plain: plain,
    );
  }

  /// Sign + seal + deliver: BLE frame when in range (relay as fallback),
  /// relay envelope otherwise. Returns whether any channel accepted it.
  Future<bool> _deliver({
    required String peerSub,
    required String? knownXPub,
    required String kind,
    required Map<String, dynamic> plain,
  }) async {
    var xPub = knownXPub;
    if (xPub == null) {
      final entry = await _transport.fetchDirectory(peerSub);
      xPub = entry?.x25519Pub;
    }
    if (xPub == null) {
      debugPrint('MessageService: no X25519 key for $peerSub — cannot send');
      return false;
    }

    try {
      final envelope = await _codec.sealSigned(
        to: peerSub,
        kind: kind,
        plain: plain,
        recipientX25519PubB64: xPub,
      );
      if (_engine.isNearby(peerSub)) {
        try {
          if (await _engine.sendFrame(
              peerSub, EnvelopeCodec.frameFromEnvelope(envelope))) {
            return true;
          }
        } catch (e) {
          debugPrint('MessageService: BLE frame to $peerSub failed, '
              'trying relay: $e');
        }
      }
      return await _transport.send(envelope);
    } catch (e) {
      debugPrint('MessageService: $kind to $peerSub failed: $e');
      return false;
    }
  }

  Future<Duration?> _threadTtl(String peerSub) async {
    for (final archived in const [false, true]) {
      final threads = await _messages.watchThreads(archived: archived).first;
      for (final t in threads) {
        if (t.peerSub == peerSub) return t.disappearingTtl;
      }
    }
    return null;
  }

  String _mySub() => _profile.profile.value?.sub ?? '';
}
