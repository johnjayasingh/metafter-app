import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:metafter/core/db/seen_message_store.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:metafter/core/repositories/repositories.dart';
import 'package:metafter/core/transport/envelope.dart';
import 'package:metafter/core/transport/transport_client.dart';

/// Hand-rolled in-memory fakes for the service-layer tests. They implement
/// the repository/engine/transport CONTRACTS only — no dependency on the
/// parallel sqflite/BLE/relay implementations.

ProfileCard card(
  String sub, {
  String name = 'Peer',
  String? edPub = 'ed-pub',
  String? xPub = 'x-pub',
}) =>
    ProfileCard(sub: sub, name: name, ed25519Pub: edPub, x25519Pub: xPub);

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({MyProfile? me, ProfileCard? myCard})
      : profile = ValueNotifier<MyProfile?>(me),
        _myCard = myCard ?? card('me', name: 'Me');

  final ProfileCard _myCard;

  @override
  final ValueNotifier<MyProfile?> profile;

  @override
  Future<ProfileCard> buildCard() async => _myCard;

  @override
  Future<void> clear() async => profile.value = null;

  @override
  Future<void> load() async {}

  @override
  Future<void> markVerified(String badgeSig) async {}

  @override
  Future<void> save(MyProfile p) async => profile.value = p;
}

class FakeEncounterRepository implements EncounterRepository {
  final List<NearbyPeer> sightings = [];
  final Map<String, String> requested = {}; // encounterId -> requestId

  @override
  Future<List<DateTime>> daysWithEncounters() async => const [];

  @override
  Future<void> markRequested(String encounterId, String requestId) async {
    requested[encounterId] = requestId;
  }

  @override
  Future<String> recordSighting(NearbyPeer peer,
      {Duration mergeWindow = const Duration(minutes: 30)}) async {
    sightings.add(peer);
    return 'enc-${sightings.length}';
  }

  @override
  Future<void> sweepOlderThan(Duration age) async {}

  @override
  Stream<List<Encounter>> watchDay(DateTime day) => Stream.value(const []);
}

class FakeRequestRepository implements RequestRepository {
  final Map<String, ConnectionRequest> rows = {};
  int outgoingToday = 0;
  int outgoingWithNote = 0;

  @override
  Future<ConnectionRequest?> byId(String id) async => rows[id];

  @override
  Future<int> countOutgoingSince(DateTime since) async => outgoingToday;

  @override
  Future<int> countOutgoingWithNote() async => outgoingWithNote;

  @override
  Future<void> setStatus(String id, RequestStatus status) async {
    final row = rows[id];
    if (row != null) rows[id] = row.copyWith(status: status);
  }

  @override
  Future<void> upsert(ConnectionRequest request) async {
    rows[request.id] = request;
  }

  @override
  Stream<List<ConnectionRequest>> watchIncomingPending() =>
      Stream.value(rows.values
          .where((r) =>
              r.direction == RequestDirection.incoming &&
              r.status == RequestStatus.pending)
          .toList());

  @override
  Stream<int> watchIncomingPendingCount() =>
      watchIncomingPending().map((l) => l.length);

  @override
  Stream<List<ConnectionRequest>> watchOutgoing() => Stream.value(
      rows.values.where((r) => r.direction == RequestDirection.outgoing).toList());
}

class FakeConnectionRepository implements ConnectionRepository {
  final Map<String, Connection> rows = {};

  @override
  Future<Connection?> byPeer(String peerSub) async => rows[peerSub];

  @override
  Future<void> remove(String peerSub) async => rows.remove(peerSub);

  @override
  Future<void> upsert(Connection connection) async {
    rows[connection.peerSub] = connection;
  }

  @override
  Stream<List<Connection>> watchAll() => Stream.value(rows.values.toList());
}

class FakeMessageRepository implements MessageRepository {
  final List<ChatMessage> rows = [];
  final Map<String, Duration?> ttls = {};
  final Map<String, ProfileCard> threadCards = {};
  final Set<String> readThreads = {};
  int sweepCalls = 0;

  @override
  Future<ChatMessage> append(ChatMessage message,
      {required ProfileCard card}) async {
    rows.add(message);
    threadCards[message.peerSub] = card;
    return message;
  }

  @override
  Future<void> deleteThread(String peerSub) async {
    rows.removeWhere((m) => m.peerSub == peerSub);
  }

  @override
  Future<void> markThreadRead(String peerSub) async {
    readThreads.add(peerSub);
  }

  @override
  Future<void> setArchived(String peerSub, bool archived) async {}

  @override
  Future<void> setDisappearingTtl(String peerSub, Duration? ttl) async {
    ttls[peerSub] = ttl;
  }

  @override
  Future<void> setReaction(String messageId, String? reaction) async {
    final i = rows.indexWhere((m) => m.id == messageId);
    if (i >= 0) {
      // copyWith can't null a reaction; rebuild instead.
      final m = rows[i];
      rows[i] = ChatMessage(
        id: m.id,
        peerSub: m.peerSub,
        fromMe: m.fromMe,
        body: m.body,
        sentAt: m.sentAt,
        status: m.status,
        reaction: reaction,
        expiresAt: m.expiresAt,
      );
    }
  }

  @override
  Future<void> setStatus(String messageId, MessageStatus status) async {
    final i = rows.indexWhere((m) => m.id == messageId);
    if (i >= 0) rows[i] = rows[i].copyWith(status: status);
  }

  @override
  Future<void> sweepExpired() async => sweepCalls++;

  @override
  Stream<List<ChatMessage>> watchThread(String peerSub) =>
      Stream.value(rows.where((m) => m.peerSub == peerSub).toList());

  @override
  Stream<List<ThreadSummary>> watchThreads({required bool archived}) {
    if (archived) return Stream.value(const []);
    final byPeer = <String, ChatMessage>{};
    for (final m in rows) {
      byPeer[m.peerSub] = m;
    }
    return Stream.value([
      for (final e in byPeer.entries)
        ThreadSummary(
          peerSub: e.key,
          card: threadCards[e.key] ?? card(e.key),
          lastMessage: e.value.body,
          lastMessageAt: e.value.sentAt,
          lastFromMe: e.value.fromMe,
          disappearingTtl: ttls[e.key],
        ),
    ]);
  }
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  final ValueNotifier<MoodRing> mood = ValueNotifier(MoodRing.networking);
  @override
  final ValueNotifier<Duration> discoverableDuration =
      ValueNotifier(const Duration(hours: 4));
  @override
  final ValueNotifier<double> distanceBudget = ValueNotifier(2);
  @override
  final ValueNotifier<bool> use24hTime = ValueNotifier(false);
  @override
  final ValueNotifier<String> language = ValueNotifier('English');
  @override
  final ValueNotifier<bool> reduceMotion = ValueNotifier(false);
  @override
  final ValueNotifier<bool> largerText = ValueNotifier(false);
  @override
  final ValueNotifier<bool> readReceipts = ValueNotifier(true);
  @override
  final ValueNotifier<bool> typingIndicator = ValueNotifier(true);
  @override
  final ValueNotifier<bool> allowVideoCall = ValueNotifier(true);
  @override
  final ValueNotifier<bool> allowAudioCall = ValueNotifier(true);
  @override
  final ValueNotifier<bool> disappearingDefault = ValueNotifier(false);
  @override
  final ValueNotifier<bool> showCompany = ValueNotifier(true);
  @override
  final ValueNotifier<bool> showDesignation = ValueNotifier(true);
  @override
  final ValueNotifier<bool> incognitoScan = ValueNotifier(false);
  @override
  final ValueNotifier<PrivacyVisibility> nameVisibility =
      ValueNotifier(PrivacyVisibility.visibleToAll);
  @override
  final ValueNotifier<PrivacyVisibility> companyVisibility =
      ValueNotifier(PrivacyVisibility.visibleToAll);
  @override
  final ValueNotifier<bool> isPro = ValueNotifier(false);

  @override
  Future<void> load() async {}

  @override
  Future<void> setMood(MoodRing v) async => mood.value = v;
  @override
  Future<void> setDiscoverableDuration(Duration v) async =>
      discoverableDuration.value = v;
  @override
  Future<void> setDistanceBudget(double v) async => distanceBudget.value = v;
  @override
  Future<void> setUse24hTime(bool v) async => use24hTime.value = v;
  @override
  Future<void> setLanguage(String v) async => language.value = v;
  @override
  Future<void> setReduceMotion(bool v) async => reduceMotion.value = v;
  @override
  Future<void> setLargerText(bool v) async => largerText.value = v;
  @override
  Future<void> setReadReceipts(bool v) async => readReceipts.value = v;
  @override
  Future<void> setTypingIndicator(bool v) async => typingIndicator.value = v;
  @override
  Future<void> setAllowVideoCall(bool v) async => allowVideoCall.value = v;
  @override
  Future<void> setAllowAudioCall(bool v) async => allowAudioCall.value = v;
  @override
  Future<void> setDisappearingDefault(bool v) async =>
      disappearingDefault.value = v;
  @override
  Future<void> setShowCompany(bool v) async => showCompany.value = v;
  @override
  Future<void> setShowDesignation(bool v) async => showDesignation.value = v;
  @override
  Future<void> setIncognitoScan(bool v) async => incognitoScan.value = v;
  @override
  Future<void> setNameVisibility(PrivacyVisibility v) async =>
      nameVisibility.value = v;
  @override
  Future<void> setCompanyVisibility(PrivacyVisibility v) async =>
      companyVisibility.value = v;
  @override
  Future<void> setIsPro(bool v) async => isPro.value = v;
}

/// In-memory [SeenMessageLedger] for InboundHandler replay tests (finding
/// [0]). [record] returns true only the first time an id is seen.
class FakeSeenMessageLedger implements SeenMessageLedger {
  final Set<String> seen = {};

  @override
  Future<bool> record(String messageId, DateTime seenAt) async =>
      seen.add(messageId);

  @override
  Future<void> pruneBefore(DateTime before) async {}
}

class FakeProximityEngine implements ProximityEngine {
  final Set<String> nearbySubs = {};
  final List<(String, ConnectRequestPayload)> sentRequests = [];
  final List<(String, ConnectResponsePayload)> sentResponses = [];
  final List<(String, Uint8List)> sentFrames = [];
  bool bleSendResult = true;

  final StreamController<List<NearbyPeer>> peersCtrl =
      StreamController.broadcast();
  final StreamController<PeerEvent> eventsCtrl = StreamController.broadcast();

  @override
  Stream<List<NearbyPeer>> get nearbyPeers => peersCtrl.stream;

  @override
  Stream<PeerEvent> get events => eventsCtrl.stream;

  @override
  bool isRunning = false;

  @override
  Future<void> startSession(SessionConfig config) async => isRunning = true;

  @override
  Future<void> stopSession() async => isRunning = false;

  @override
  bool isNearby(String peerSub) => nearbySubs.contains(peerSub);

  @override
  Stream<RangeSample> range(String peerSub) => const Stream.empty();

  @override
  Future<bool> sendFrame(String peerSub, Uint8List frame) async {
    sentFrames.add((peerSub, frame));
    return bleSendResult;
  }

  @override
  Future<bool> sendRequest(String peerSub, ConnectRequestPayload payload) async {
    sentRequests.add((peerSub, payload));
    return bleSendResult;
  }

  @override
  Future<bool> sendResponse(
      String peerSub, ConnectResponsePayload payload) async {
    sentResponses.add((peerSub, payload));
    return bleSendResult;
  }

  @override
  Future<void> dispose() async {
    await peersCtrl.close();
    await eventsCtrl.close();
  }
}

class FakeTransportClient implements TransportClient {
  final List<Envelope> sent = [];
  final Map<String, DirectoryEntry> directory = {};
  bool sendResult = true;
  final StreamController<Envelope> inboundCtrl = StreamController.broadcast();

  @override
  Stream<Envelope> get inbound => inboundCtrl.stream;

  @override
  bool isConnected = false;

  @override
  Future<void> connect() async => isConnected = true;

  @override
  Future<void> disconnect() async => isConnected = false;

  @override
  Future<void> drainMailbox() async {}

  @override
  Future<DirectoryEntry?> fetchDirectory(String sub) async => directory[sub];

  @override
  Future<bool> publishDirectory({
    required String ed25519Pub,
    required String x25519Pub,
    String? pushToken,
  }) async =>
      true;

  @override
  Future<bool> send(Envelope envelope) async {
    sent.add(envelope);
    return sendResult;
  }
}
