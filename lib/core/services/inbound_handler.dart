import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../proximity/proximity_engine.dart';
import '../repositories/repositories.dart';

/// How an inbound protocol event reached this device.
enum InboundVia { ble, relay }

/// Sends a delivery/read receipt back to a peer. Wired to
/// `MessageServiceImpl.sendReceipt` in bootstrap so InboundHandler does not
/// depend on the service directly.
typedef ReceiptSender = Future<void> Function(
    String peerSub, String messageId, String status);

/// Applies inbound protocol events to the local repositories.
///
/// Both arrival paths funnel here — BLE GATT events surfaced by the
/// [ProximityEngine] and relay envelopes decrypted by `EnvelopeRouter` — so a
/// connect request received over Bluetooth behaves exactly like one that
/// arrived through the mailbox hours later.
class InboundHandler {
  InboundHandler({
    required RequestRepository requests,
    required ConnectionRepository connections,
    required MessageRepository messages,
    ReceiptSender? sendReceipt,
    DateTime Function()? now,
  })  : _requests = requests,
        _connections = connections,
        _messages = messages,
        _sendReceipt = sendReceipt,
        _now = now ?? DateTime.now;

  final RequestRepository _requests;
  final ConnectionRepository _connections;
  final MessageRepository _messages;
  final DateTime Function() _now;

  ReceiptSender? _sendReceipt;

  /// Late wiring hook for the delivered-receipt path (set once in bootstrap
  /// after MessageService is constructed).
  set sendReceipt(ReceiptSender sender) => _sendReceipt = sender;

  /// An incoming connect request: store it as a pending incoming row.
  /// Deduped by requestId — BLE and relay may both deliver the same request.
  Future<void> handleRequest(
    ConnectRequestPayload payload, {
    InboundVia via = InboundVia.ble,
  }) async {
    final existing = await _requests.byId(payload.requestId);
    if (existing != null) return; // duplicate (e.g. BLE first, relay later)
    await _requests.upsert(ConnectionRequest(
      id: payload.requestId,
      direction: RequestDirection.incoming,
      peerSub: payload.senderCard.sub,
      card: payload.senderCard,
      note: payload.note,
      status: RequestStatus.pending,
      createdAt: _now(),
    ));
  }

  /// A response to a request we sent: update its status, and on accept
  /// persist the new connection using the responder's card.
  Future<void> handleResponse(ConnectResponsePayload payload) async {
    final request = await _requests.byId(payload.requestId);
    if (request == null) {
      debugPrint('InboundHandler: response for unknown request '
          '${payload.requestId} — dropped');
      return;
    }
    await _requests.setStatus(
      payload.requestId,
      payload.accepted ? RequestStatus.accepted : RequestStatus.declined,
    );
    if (payload.accepted) {
      await _connections.upsert(Connection(
        peerSub: payload.responderCard.sub,
        card: payload.responderCard,
        connectedAt: _now(),
      ));
    }
  }

  /// An inbound chat message. Appends it to the thread (card resolved from
  /// the connection), honours the disappearing TTL, and fires a delivered
  /// receipt back through the message-service plumbing.
  Future<void> handleMessage({
    required String from,
    required String messageId,
    required String body,
    required DateTime sentAt,
    int? expiresInSec,
  }) async {
    final connection = await _connections.byPeer(from);
    if (connection == null) {
      debugPrint('InboundHandler: message from non-connection $from — dropped');
      return;
    }

    // Dedupe: the sender may have delivered over BLE and relay both.
    final thread = await _messages.watchThread(from).first;
    if (thread.any((m) => m.id == messageId)) return;

    final now = _now();
    DateTime? expiresAt;
    if (expiresInSec != null) {
      expiresAt = now.add(Duration(seconds: expiresInSec));
    } else {
      final ttl = await _threadTtl(from);
      if (ttl != null) expiresAt = now.add(ttl);
    }

    await _messages.append(
      ChatMessage(
        id: messageId,
        peerSub: from,
        fromMe: false,
        body: body,
        sentAt: sentAt,
        status: MessageStatus.delivered,
        expiresAt: expiresAt,
      ),
      card: connection.card,
    );

    final send = _sendReceipt;
    if (send != null) {
      try {
        await send(from, messageId, 'delivered');
      } catch (e) {
        debugPrint('InboundHandler: delivered receipt to $from failed: $e');
      }
    }
  }

  /// A receipt (delivered/read) or a reaction for a message we sent.
  /// [hasReaction] distinguishes "reaction key present but null" (clear the
  /// reaction) from a plain status receipt.
  Future<void> handleReceipt({
    required String from,
    required String messageId,
    String? status,
    String? reaction,
    bool hasReaction = false,
  }) async {
    if (hasReaction) {
      await _messages.setReaction(messageId, reaction);
      return;
    }
    switch (status) {
      case 'delivered':
        await _messages.setStatus(messageId, MessageStatus.delivered);
      case 'read':
        await _messages.setStatus(messageId, MessageStatus.read);
      default:
        debugPrint('InboundHandler: unknown receipt status "$status"');
    }
  }

  /// Peer removed the connection: drop our connection row. The thread stays
  /// locally until the user deletes it (DESIGN_SPEC §10).
  Future<void> handleDisconnect(String from) async {
    await _connections.remove(from);
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
}
