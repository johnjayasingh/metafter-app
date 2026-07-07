import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:metafter/core/repositories/repositories.dart';
import 'package:metafter/core/services/app_services.dart';
import 'package:metafter/core/services/services.dart';

import '../services/fakes.dart';

/// Messaging-UI test harness: a REACTIVE in-memory MessageRepository (the
/// shared FakeMessageRepository in ../services/fakes.dart emits a single
/// snapshot only) plus recording service fakes, installed as AppServices.I.

// ---------------------------------------------------------------------------
// Reactive message repository
// ---------------------------------------------------------------------------

class ThreadMeta {
  ThreadMeta(this.card);
  ProfileCard card;
  bool archived = false;
  Duration? ttl;
}

class ReactiveMessageRepository implements MessageRepository {
  final List<ChatMessage> messages = [];
  final Map<String, ThreadMeta> threads = {};
  final Set<String> readThreads = {};

  final _changes = StreamController<void>.broadcast();

  void _notify() => _changes.add(null);

  /// Each call returns a fresh single-listener stream that emits the current
  /// snapshot on listen and re-emits on every mutation — mirrors the sqflite
  /// repositories' contract.
  Stream<T> _watch<T>(T Function() snapshot) {
    late StreamController<T> ctrl;
    StreamSubscription<void>? sub;
    ctrl = StreamController<T>(
      onListen: () {
        ctrl.add(snapshot());
        sub = _changes.stream.listen((_) => ctrl.add(snapshot()));
      },
      onCancel: () => sub?.cancel(),
    );
    return ctrl.stream;
  }

  void seedThread(
    ProfileCard card, {
    List<ChatMessage> messages = const [],
    bool archived = false,
    Duration? ttl,
  }) {
    threads[card.sub] = ThreadMeta(card)
      ..archived = archived
      ..ttl = ttl;
    this.messages.addAll(messages);
    _notify();
  }

  List<ThreadSummary> _threadsSnapshot(bool archived) {
    final out = <ThreadSummary>[];
    for (final meta in threads.values) {
      if (meta.archived != archived) continue;
      final msgs =
          messages.where((m) => m.peerSub == meta.card.sub).toList();
      if (msgs.isEmpty) continue;
      final last = msgs.last;
      out.add(ThreadSummary(
        peerSub: meta.card.sub,
        card: meta.card,
        lastMessage: last.body,
        lastMessageAt: last.sentAt,
        lastFromMe: last.fromMe,
        unreadCount: msgs
            .where((m) => !m.fromMe && m.status != MessageStatus.read)
            .length,
        archived: meta.archived,
        disappearingTtl: meta.ttl,
      ));
    }
    out.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return out;
  }

  @override
  Stream<List<ThreadSummary>> watchThreads({required bool archived}) =>
      _watch(() => _threadsSnapshot(archived));

  @override
  Stream<List<ChatMessage>> watchThread(String peerSub) =>
      _watch(() => messages.where((m) => m.peerSub == peerSub).toList());

  @override
  Future<ChatMessage> append(ChatMessage message,
      {required ProfileCard card}) async {
    messages.add(message);
    threads.putIfAbsent(message.peerSub, () => ThreadMeta(card)).card = card;
    _notify();
    return message;
  }

  @override
  Future<void> setStatus(String messageId, MessageStatus status) async {
    final i = messages.indexWhere((m) => m.id == messageId);
    if (i >= 0) {
      messages[i] = messages[i].copyWith(status: status);
      _notify();
    }
  }

  @override
  Future<void> setReaction(String messageId, String? reaction) async {
    final i = messages.indexWhere((m) => m.id == messageId);
    if (i < 0) return;
    final m = messages[i];
    // copyWith can't null a reaction; rebuild instead.
    messages[i] = ChatMessage(
      id: m.id,
      peerSub: m.peerSub,
      fromMe: m.fromMe,
      body: m.body,
      sentAt: m.sentAt,
      status: m.status,
      reaction: reaction,
      expiresAt: m.expiresAt,
    );
    _notify();
  }

  @override
  Future<void> markThreadRead(String peerSub) async {
    readThreads.add(peerSub);
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m.peerSub == peerSub && !m.fromMe) {
        messages[i] = m.copyWith(status: MessageStatus.read);
      }
    }
    _notify();
  }

  @override
  Future<void> setArchived(String peerSub, bool archived) async {
    threads[peerSub]?.archived = archived;
    _notify();
  }

  @override
  Future<void> setDisappearingTtl(String peerSub, Duration? ttl) async {
    threads[peerSub]?.ttl = ttl;
    _notify();
  }

  @override
  Future<void> sweepExpired() async {}

  @override
  Future<void> deleteThread(String peerSub) async {
    messages.removeWhere((m) => m.peerSub == peerSub);
    threads.remove(peerSub);
    _notify();
  }
}

// ---------------------------------------------------------------------------
// Recording service fakes
// ---------------------------------------------------------------------------

class RecordingMessageService implements MessageService {
  RecordingMessageService(this.repo, this.connections);

  final ReactiveMessageRepository repo;
  final FakeConnectionRepository connections;

  final List<(String, String)> sent = [];
  final List<(String, String, String?)> reactions = [];
  final List<String> readCalls = [];
  final Set<String> nearbySubs = {};
  int _seq = 0;

  @override
  Future<void> send(String peerSub, String body) async {
    sent.add((peerSub, body));
    final conn = await connections.byPeer(peerSub);
    await repo.append(
      ChatMessage(
        id: 'sent-${_seq++}',
        peerSub: peerSub,
        fromMe: true,
        body: body,
        sentAt: DateTime.now(),
        status: MessageStatus.sent,
      ),
      card: conn?.card ?? repo.threads[peerSub]!.card,
    );
  }

  @override
  Future<void> react(String peerSub, String messageId, String? emoji) async {
    reactions.add((peerSub, messageId, emoji));
    await repo.setReaction(messageId, emoji);
  }

  @override
  Future<void> markRead(String peerSub) async {
    readCalls.add(peerSub);
    await repo.markThreadRead(peerSub);
  }

  @override
  bool isPeerNearby(String peerSub) => nearbySubs.contains(peerSub);
}

class FakeSessionService implements SessionService {
  @override
  final ValueNotifier<SessionState> state =
      ValueNotifier<SessionState>(const SessionIdle());

  @override
  final ValueNotifier<Duration> remaining =
      ValueNotifier<Duration>(Duration.zero);

  @override
  Stream<List<NearbyPeer>> get nearby => const Stream.empty();

  @override
  Future<String?> start() async => null;

  @override
  Future<void> end() async {}
}

class FakeConnectionService implements ConnectionService {
  final List<String> disconnected = [];

  @override
  Future<SendRequestOutcome> sendRequest({
    required ProfileCard toCard,
    String? note,
    String? encounterId,
  }) async =>
      SendRequestOutcome.sentNearby;

  @override
  Future<void> accept(ConnectionRequest request) async {}

  @override
  Future<void> decline(ConnectionRequest request) async {}

  @override
  Future<void> disconnect(String peerSub) async {
    disconnected.add(peerSub);
  }
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class MessagingHarness {
  MessagingHarness._({
    required this.messages,
    required this.messaging,
    required this.connections,
    required this.connection,
    required this.settings,
    required this.engine,
  });

  final ReactiveMessageRepository messages;
  final RecordingMessageService messaging;
  final FakeConnectionRepository connections;
  final FakeConnectionService connection;
  final FakeSettingsRepository settings;
  final FakeProximityEngine engine;

  /// Builds the full fake graph and installs it as [AppServices.I].
  static MessagingHarness install() {
    final messages = ReactiveMessageRepository();
    final connections = FakeConnectionRepository();
    final messaging = RecordingMessageService(messages, connections);
    final connection = FakeConnectionService();
    final settings = FakeSettingsRepository();
    final engine = FakeProximityEngine();

    AppServices.install(AppServices(
      profile: FakeProfileRepository(),
      encounters: FakeEncounterRepository(),
      requests: FakeRequestRepository(),
      connections: connections,
      messages: messages,
      settings: settings,
      engine: engine,
      transport: FakeTransportClient(),
      session: FakeSessionService(),
      connection: connection,
      messaging: messaging,
    ));

    return MessagingHarness._(
      messages: messages,
      messaging: messaging,
      connections: connections,
      connection: connection,
      settings: settings,
      engine: engine,
    );
  }
}

ChatMessage msg(
  String id,
  String peerSub,
  String body, {
  required bool fromMe,
  DateTime? sentAt,
  MessageStatus status = MessageStatus.read,
  String? reaction,
}) =>
    ChatMessage(
      id: id,
      peerSub: peerSub,
      fromMe: fromMe,
      body: body,
      sentAt: sentAt ?? DateTime.now().subtract(const Duration(minutes: 5)),
      status: status,
      reaction: reaction,
    );
