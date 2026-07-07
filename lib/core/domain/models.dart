import 'dart:convert';

import 'package:flutter/material.dart';

/// Domain models for the local-first MetAfter data layer.
///
/// Everything in this file is a plain value object with JSON round-tripping.
/// These are THE shared types — screens, repositories, the proximity engine
/// and the transport client all speak these. Do not create per-screen
/// person/request classes; extend these instead.

// ---------------------------------------------------------------------------
// Mood ring
// ---------------------------------------------------------------------------

enum MoodRing { networking, friends, catchup, justChecking }

extension MoodRingX on MoodRing {
  String get label => switch (this) {
        MoodRing.networking => 'Networking',
        MoodRing.friends => 'Friends',
        MoodRing.catchup => 'Catchup',
        MoodRing.justChecking => 'Just Checking',
      };

  /// Ring color broadcast meaning (DESIGN_SPEC §11.1).
  Color get color => switch (this) {
        MoodRing.networking => const Color(0xFFE32227),
        MoodRing.friends => const Color(0xFFF59E0B),
        MoodRing.catchup => const Color(0xFF22C55E),
        MoodRing.justChecking => const Color(0xFF3B82F6),
      };

  /// Single-byte wire value used in the BLE advertisement.
  int get wire => index;

  static MoodRing fromWire(int v) =>
      MoodRing.values[v.clamp(0, MoodRing.values.length - 1)];
}

// ---------------------------------------------------------------------------
// Profile card — what a peer learns about you (over BLE or inside envelopes)
// ---------------------------------------------------------------------------

class ProfileCard {
  const ProfileCard({
    required this.sub,
    required this.name,
    this.role = '',
    this.designation = '',
    this.company = '',
    this.intro = '',
    this.verified = false,
    this.photoBase64,
    this.ed25519Pub,
    this.x25519Pub,
  });

  /// Stable account id (Cognito sub). Empty for cards captured before any
  /// identity exchange (should not normally happen).
  final String sub;
  final String name;
  final String role;
  final String designation;
  final String company;
  final String intro;
  final bool verified;

  /// Small JPEG thumbnail (~≤16 KB), base64. Nullable — UI must fall back to
  /// initials.
  final String? photoBase64;

  /// Base64 public keys. Needed to verify signatures / encrypt to this peer.
  final String? ed25519Pub;
  final String? x25519Pub;

  /// "UI/UX Designer – Techinorm" style line used across the designs.
  String get titleLine => [
        if (designation.isNotEmpty) designation else if (role.isNotEmpty) role,
        if (company.isNotEmpty) company,
      ].join(' – ');

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  ProfileCard copyWith({
    String? sub,
    String? name,
    String? role,
    String? designation,
    String? company,
    String? intro,
    bool? verified,
    String? photoBase64,
    String? ed25519Pub,
    String? x25519Pub,
  }) =>
      ProfileCard(
        sub: sub ?? this.sub,
        name: name ?? this.name,
        role: role ?? this.role,
        designation: designation ?? this.designation,
        company: company ?? this.company,
        intro: intro ?? this.intro,
        verified: verified ?? this.verified,
        photoBase64: photoBase64 ?? this.photoBase64,
        ed25519Pub: ed25519Pub ?? this.ed25519Pub,
        x25519Pub: x25519Pub ?? this.x25519Pub,
      );

  Map<String, dynamic> toJson() => {
        'sub': sub,
        'name': name,
        'role': role,
        'designation': designation,
        'company': company,
        'intro': intro,
        'verified': verified,
        if (photoBase64 != null) 'photo': photoBase64,
        if (ed25519Pub != null) 'edPub': ed25519Pub,
        if (x25519Pub != null) 'xPub': x25519Pub,
      };

  static ProfileCard fromJson(Map<String, dynamic> j) => ProfileCard(
        sub: j['sub'] as String? ?? '',
        name: j['name'] as String? ?? '',
        role: j['role'] as String? ?? '',
        designation: j['designation'] as String? ?? '',
        company: j['company'] as String? ?? '',
        intro: j['intro'] as String? ?? '',
        verified: j['verified'] as bool? ?? false,
        photoBase64: j['photo'] as String?,
        ed25519Pub: j['edPub'] as String?,
        x25519Pub: j['xPub'] as String?,
      );

  String encode() => jsonEncode(toJson());
  static ProfileCard decode(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// The signed-in user's own profile (single local row).
class MyProfile {
  const MyProfile({
    required this.sub,
    required this.name,
    this.role = '',
    this.designation = '',
    this.company = '',
    this.intro = '',
    this.photoPath,
    this.verified = false,
    this.verifiedBadgeSig,
  });

  final String sub;
  final String name;
  final String role;
  final String designation;
  final String company;
  final String intro;

  /// Local file path of the full-size profile photo.
  final String? photoPath;
  final bool verified;

  /// Server-issued signature over `verified:<sub>:<photoHash>`.
  final String? verifiedBadgeSig;

  MyProfile copyWith({
    String? sub,
    String? name,
    String? role,
    String? designation,
    String? company,
    String? intro,
    String? photoPath,
    bool? verified,
    String? verifiedBadgeSig,
  }) =>
      MyProfile(
        sub: sub ?? this.sub,
        name: name ?? this.name,
        role: role ?? this.role,
        designation: designation ?? this.designation,
        company: company ?? this.company,
        intro: intro ?? this.intro,
        photoPath: photoPath ?? this.photoPath,
        verified: verified ?? this.verified,
        verifiedBadgeSig: verifiedBadgeSig ?? this.verifiedBadgeSig,
      );

  String get titleLine => [
        if (designation.isNotEmpty) designation else if (role.isNotEmpty) role,
        if (company.isNotEmpty) company,
      ].join(' – ');
}

// ---------------------------------------------------------------------------
// Encounters — the "People You Crossed Paths" ledger
// ---------------------------------------------------------------------------

class Encounter {
  const Encounter({
    required this.id,
    required this.peerEid,
    required this.card,
    required this.firstSeen,
    required this.lastSeen,
    required this.meters,
    this.sentRequestId,
  });

  final String id;

  /// Hex ephemeral id the peer advertised when sighted.
  final String peerEid;

  /// Snapshot of the peer's profile card at sighting time.
  final ProfileCard card;
  final DateTime firstSeen;
  final DateTime lastSeen;

  /// Closest smoothed distance observed during the encounter.
  final double meters;

  /// Non-null once a connect request was sent from this encounter.
  final String? sentRequestId;

  Encounter copyWith({
    DateTime? lastSeen,
    double? meters,
    ProfileCard? card,
    String? sentRequestId,
  }) =>
      Encounter(
        id: id,
        peerEid: peerEid,
        card: card ?? this.card,
        firstSeen: firstSeen,
        lastSeen: lastSeen ?? this.lastSeen,
        meters: meters ?? this.meters,
        sentRequestId: sentRequestId ?? this.sentRequestId,
      );
}

// ---------------------------------------------------------------------------
// Connection requests & connections
// ---------------------------------------------------------------------------

enum RequestDirection { incoming, outgoing }

enum RequestStatus { pending, accepted, declined, expired }

class ConnectionRequest {
  const ConnectionRequest({
    required this.id,
    required this.direction,
    required this.peerSub,
    required this.card,
    required this.createdAt,
    this.note,
    this.status = RequestStatus.pending,
  });

  final String id;
  final RequestDirection direction;
  final String peerSub;
  final ProfileCard card;
  final String? note;
  final RequestStatus status;
  final DateTime createdAt;

  ConnectionRequest copyWith({RequestStatus? status}) => ConnectionRequest(
        id: id,
        direction: direction,
        peerSub: peerSub,
        card: card,
        note: note,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

class Connection {
  const Connection({
    required this.peerSub,
    required this.card,
    required this.connectedAt,
    this.moodAtMeet,
  });

  final String peerSub;
  final ProfileCard card;
  final DateTime connectedAt;
  final MoodRing? moodAtMeet;
}

// ---------------------------------------------------------------------------
// Messaging
// ---------------------------------------------------------------------------

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.peerSub,
    required this.fromMe,
    required this.body,
    required this.sentAt,
    this.status = MessageStatus.sending,
    this.reaction,
    this.expiresAt,
  });

  final String id;

  /// Thread key — the peer's sub (threads are strictly 1:1).
  final String peerSub;
  final bool fromMe;
  final String body;
  final DateTime sentAt;
  final MessageStatus status;

  /// Single emoji reaction attached to this bubble (either side may set it).
  final String? reaction;

  /// Disappearing messages: local deletion deadline on both ends.
  final DateTime? expiresAt;

  ChatMessage copyWith({
    MessageStatus? status,
    String? reaction,
    DateTime? expiresAt,
  }) =>
      ChatMessage(
        id: id,
        peerSub: peerSub,
        fromMe: fromMe,
        body: body,
        sentAt: sentAt,
        status: status ?? this.status,
        reaction: reaction ?? this.reaction,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}

class ThreadSummary {
  const ThreadSummary({
    required this.peerSub,
    required this.card,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastFromMe,
    this.unreadCount = 0,
    this.archived = false,
    this.disappearingTtl,
  });

  final String peerSub;
  final ProfileCard card;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool lastFromMe;
  final int unreadCount;
  final bool archived;

  /// Null = off; otherwise messages in this thread expire after this TTL.
  final Duration? disappearingTtl;
}

// ---------------------------------------------------------------------------
// Privacy preferences (persisted via SettingsRepository)
// ---------------------------------------------------------------------------

enum PrivacyVisibility { visibleToAll, visibleToConnections, hidden }

extension PrivacyVisibilityX on PrivacyVisibility {
  String get label => switch (this) {
        PrivacyVisibility.visibleToAll => 'Visible to all',
        PrivacyVisibility.visibleToConnections => 'Visible to connections',
        PrivacyVisibility.hidden => 'Hidden',
      };
}
