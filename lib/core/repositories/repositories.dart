import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../proximity/proximity_engine.dart';

/// Repository contracts — the ONLY data access layer screens may use.
/// Concrete implementations live in `lib/core/db/` backed by sqflite
/// (`metafter.db`); repositories hold in-memory caches and expose broadcast
/// streams that re-emit on every mutation (sqflite has no reactivity).
///
/// All watch* streams emit the current value immediately on listen.

abstract class ProfileRepository {
  /// Null until signup completes.
  ValueListenable<MyProfile?> get profile;

  Future<void> load();
  Future<void> save(MyProfile profile);
  Future<void> markVerified(String badgeSig);

  /// Build the card broadcast to peers, honouring privacy settings
  /// (hide company/designation when configured) and attaching public keys +
  /// a downscaled photo thumbnail.
  Future<ProfileCard> buildCard();

  /// Wipe on sign-out / account deletion.
  Future<void> clear();
}

abstract class EncounterRepository {
  /// Encounters whose lastSeen falls on [day] (local time), newest first.
  Stream<List<Encounter>> watchDay(DateTime day);

  /// Distinct days (local midnight) that have encounters, newest first —
  /// feeds the Discover calendar picker.
  Future<List<DateTime>> daysWithEncounters();

  /// Record/refresh a sighting. Same peer (by card.sub, falling back to eid)
  /// within [mergeWindow] of lastSeen updates the row; otherwise a new
  /// encounter row is created. Returns the row id.
  Future<String> recordSighting(NearbyPeer peer,
      {Duration mergeWindow = const Duration(minutes: 30)});

  Future<void> markRequested(String encounterId, String requestId);

  /// Local retention sweep (default 30 days).
  Future<void> sweepOlderThan(Duration age);
}

abstract class RequestRepository {
  Stream<List<ConnectionRequest>> watchIncomingPending();
  Stream<int> watchIncomingPendingCount();
  Stream<List<ConnectionRequest>> watchOutgoing();

  Future<ConnectionRequest?> byId(String id);
  Future<void> upsert(ConnectionRequest request);
  Future<void> setStatus(String id, RequestStatus status);

  /// For Pro gating: outgoing requests created since [since].
  Future<int> countOutgoingSince(DateTime since);

  /// For Pro gating: outgoing requests that carried a note, all time.
  Future<int> countOutgoingWithNote();
}

abstract class ConnectionRepository {
  Stream<List<Connection>> watchAll();
  Future<Connection?> byPeer(String peerSub);
  Future<void> upsert(Connection connection);

  /// Remove the connection row (disconnect). Thread/messages are handled by
  /// MessageRepository separately.
  Future<void> remove(String peerSub);
}

abstract class MessageRepository {
  Stream<List<ThreadSummary>> watchThreads({required bool archived});
  Stream<List<ChatMessage>> watchThread(String peerSub);

  /// Insert a message and update the thread summary. Creates the thread on
  /// first message. Returns the stored message.
  Future<ChatMessage> append(ChatMessage message, {required ProfileCard card});

  Future<void> setStatus(String messageId, MessageStatus status);
  Future<void> setReaction(String messageId, String? reaction);
  Future<void> markThreadRead(String peerSub);
  Future<void> setArchived(String peerSub, bool archived);
  Future<void> setDisappearingTtl(String peerSub, Duration? ttl);

  /// Delete messages whose expiresAt has passed. Called periodically and on
  /// app start.
  Future<void> sweepExpired();

  Future<void> deleteThread(String peerSub);
}

/// Typed, persisted app settings (sqflite `settings` table, key/value).
/// Every value is exposed as a [ValueListenable] so both the Home shell and
/// the Settings screens observe the SAME state.
abstract class SettingsRepository {
  Future<void> load();

  ValueListenable<MoodRing> get mood;
  ValueListenable<Duration> get discoverableDuration; // default 4 h
  ValueListenable<double> get distanceBudget; // meters, default 2
  ValueListenable<bool> get use24hTime;
  ValueListenable<String> get language;
  ValueListenable<bool> get reduceMotion;
  ValueListenable<bool> get largerText;

  // Privacy & Security
  ValueListenable<bool> get readReceipts;
  ValueListenable<bool> get typingIndicator;
  ValueListenable<bool> get allowVideoCall;
  ValueListenable<bool> get allowAudioCall;
  ValueListenable<bool> get disappearingDefault;
  ValueListenable<bool> get showCompany;
  ValueListenable<bool> get showDesignation;
  ValueListenable<bool> get incognitoScan;
  ValueListenable<PrivacyVisibility> get nameVisibility;
  ValueListenable<PrivacyVisibility> get companyVisibility;

  // Pro
  ValueListenable<bool> get isPro;

  Future<void> setMood(MoodRing v);
  Future<void> setDiscoverableDuration(Duration v);
  Future<void> setDistanceBudget(double v);
  Future<void> setUse24hTime(bool v);
  Future<void> setLanguage(String v);
  Future<void> setReduceMotion(bool v);
  Future<void> setLargerText(bool v);
  Future<void> setReadReceipts(bool v);
  Future<void> setTypingIndicator(bool v);
  Future<void> setAllowVideoCall(bool v);
  Future<void> setAllowAudioCall(bool v);
  Future<void> setDisappearingDefault(bool v);
  Future<void> setShowCompany(bool v);
  Future<void> setShowDesignation(bool v);
  Future<void> setIncognitoScan(bool v);
  Future<void> setNameVisibility(PrivacyVisibility v);
  Future<void> setCompanyVisibility(PrivacyVisibility v);
  Future<void> setIsPro(bool v);
}
