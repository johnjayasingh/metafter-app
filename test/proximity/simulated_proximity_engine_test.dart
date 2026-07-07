import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:metafter/core/proximity/simulated_proximity_engine.dart';
import 'package:metafter/core/transport/envelope.dart';

/// Test-side keypair + seal/open helpers, wire-compatible with
/// CryptoService (ephemeral-static X25519 → HKDF-SHA256 with info
/// `metafter/v1/seal` → ChaCha20-Poly1305, ct = cipherText ‖ mac).
/// We deliberately do not use CryptoService here — it requires
/// flutter_secure_storage, which has no platform channel in unit tests.
class _TestIdentity {
  _TestIdentity._(this.xPair, this.edPair, this.xPubB64, this.edPubB64);

  final SimpleKeyPair xPair;
  final SimpleKeyPair edPair;
  final String xPubB64;
  final String edPubB64;

  static final _x = X25519();
  static final _ed = Ed25519();
  static final _aead = Chacha20.poly1305Aead();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static const _info = 'metafter/v1/seal';

  static Future<_TestIdentity> generate() async {
    final xPair = await _x.newKeyPair();
    final edPair = await _ed.newKeyPair();
    return _TestIdentity._(
      xPair,
      edPair,
      base64Encode((await xPair.extractPublicKey()).bytes),
      base64Encode((await edPair.extractPublicKey()).bytes),
    );
  }

  static Future<SecretKey> _derive(
      SimpleKeyPair local, List<int> remotePub) async {
    final shared = await _x.sharedSecretKey(
      keyPair: local,
      remotePublicKey: SimplePublicKey(remotePub, type: KeyPairType.x25519),
    );
    return _hkdf.deriveKey(secretKey: shared, info: utf8.encode(_info));
  }

  /// Seal [plain] to [recipientXPubB64] and wrap it in a message envelope
  /// frame, exactly as EnvelopeCodec does on the app side.
  Future<Uint8List> sealMessageFrame({
    required String toSub,
    required String recipientXPubB64,
    required Map<String, dynamic> plain,
  }) async {
    final eph = await _x.newKeyPair();
    final key = await _derive(eph, base64Decode(recipientXPubB64));
    final nonce = _aead.newNonce();
    final box = await _aead.encrypt(
      utf8.encode(jsonEncode(plain)),
      secretKey: key,
      nonce: nonce,
    );
    final envelope = Envelope(
      id: 'test-env-1',
      to: toSub,
      kind: EnvelopeKind.message,
      ephPub: base64Encode((await eph.extractPublicKey()).bytes),
      nonce: base64Encode(nonce),
      ciphertext: base64Encode(box.cipherText + box.mac.bytes),
    );
    return Uint8List.fromList(utf8.encode(envelope.encode()));
  }

  /// Open an envelope frame sealed to my X25519 key.
  Future<Map<String, dynamic>> openFrame(Uint8List frame) async {
    final envelope = Envelope.decode(utf8.decode(frame));
    final key = await _derive(xPair, base64Decode(envelope.ephPub));
    final raw = base64Decode(envelope.ciphertext);
    const macLen = 16;
    final box = SecretBox(
      raw.sublist(0, raw.length - macLen),
      nonce: base64Decode(envelope.nonce),
      mac: Mac(raw.sublist(raw.length - macLen)),
    );
    final clear = await _aead.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  }

  static Future<bool> verify(
      String edPubB64, String sigB64, List<int> data) async {
    try {
      return await _ed.verify(
        data,
        signature: Signature(
          base64Decode(sigB64),
          publicKey: SimplePublicKey(
            base64Decode(edPubB64),
            type: KeyPairType.ed25519,
          ),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Canonical form matching CryptoService.signJson.
  static String canonical(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json)..remove('sig');
    final sorted = Map.fromEntries(
        copy.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return jsonEncode(sorted);
  }
}

void main() {
  // 0.02 compresses the simulation clock 50× (10 s → 200 ms).
  const scale = 0.02;

  late _TestIdentity me;
  late ProfileCard myCard;

  setUpAll(() async {
    me = await _TestIdentity.generate();
    myCard = ProfileCard(
      sub: 'test-me',
      name: 'Luna Ray',
      role: 'Working Professional',
      designation: 'UI / UX Designer',
      company: 'Techinorm',
      x25519Pub: me.xPubB64,
      ed25519Pub: me.edPubB64,
    );
  });

  SessionConfig config({double maxMeters = 5}) => SessionConfig(
        duration: const Duration(hours: 1),
        maxMeters: maxMeters,
        mood: MoodRing.networking,
        myCard: myCard,
      );

  SimulatedProximityEngine makeEngine() =>
      SimulatedProximityEngine(seed: 7, timeScale: scale);

  /// Waits for the first nearby list that satisfies [predicate].
  Future<List<NearbyPeer>> firstNearbyWhere(
    SimulatedProximityEngine engine,
    bool Function(List<NearbyPeer>) predicate,
  ) =>
      engine.nearbyPeers
          .firstWhere(predicate)
          .timeout(const Duration(seconds: 10));

  test('session lifecycle: peers appear, respect budget, stop clears', () async {
    final engine = makeEngine();
    final appeared =
        firstNearbyWhere(engine, (peers) => peers.length >= 2);

    await engine.startSession(config(maxMeters: 5));
    expect(engine.isRunning, isTrue);

    final peers = await appeared;
    expect(peers.length, inInclusiveRange(2, 4));
    for (final p in peers) {
      expect(p.meters, lessThanOrEqualTo(5.0));
      expect(p.meters, greaterThanOrEqualTo(0.4));
      expect(p.card, isNotNull);
      expect(p.card!.sub, startsWith('sim-'));
      expect(p.card!.role, 'Working Professional');
      expect(p.card!.x25519Pub, isNotNull);
      expect(p.card!.ed25519Pub, isNotNull);
      expect(engine.isNearby(p.card!.sub), isTrue);
    }
    // Sorted nearest-first.
    for (var i = 1; i < peers.length; i++) {
      expect(peers[i].meters, greaterThanOrEqualTo(peers[i - 1].meters));
    }

    final sub = peers.first.card!.sub;
    await engine.stopSession();
    expect(engine.isRunning, isFalse);
    expect(engine.isNearby(sub), isFalse);
    await engine.dispose();
  });

  test('a persona sends an incoming connect request ~10s in', () async {
    final engine = makeEngine();
    final request = engine.events
        .firstWhere((e) => e is PeerRequestReceived)
        .timeout(const Duration(seconds: 10));

    await engine.startSession(config());
    final event = await request as PeerRequestReceived;
    expect(event.payload.requestId, isNotEmpty);
    expect(event.payload.senderCard.sub, startsWith('sim-'));
    expect(event.payload.senderCard.name, isNotEmpty);
    await engine.dispose();
  });

  test('sendRequest → accepted response round-trip (and one decliner)',
      () async {
    final engine = makeEngine();
    await engine.startSession(config());
    await firstNearbyWhere(engine, (peers) => peers.isNotEmpty);

    // Accepting persona (anyone but Zahir Mays, the standing decliner).
    final accepter = (await firstNearbyWhere(engine, (peers) => peers
            .any((p) => p.card!.sub != 'sim-zahir-mays')))
        .firstWhere((p) => p.card!.sub != 'sim-zahir-mays');

    final responses = StreamQueue(engine.events
        .where((e) => e is PeerResponseReceived)
        .cast<PeerResponseReceived>());

    final ok = await engine.sendRequest(
      accepter.card!.sub,
      ConnectRequestPayload(requestId: 'req-accept', senderCard: myCard),
    );
    expect(ok, isTrue);
    final accepted =
        await responses.next.timeout(const Duration(seconds: 10));
    expect(accepted.payload.requestId, 'req-accept');
    expect(accepted.payload.accepted, isTrue);
    expect(accepted.payload.responderCard.sub, accepter.card!.sub);

    // The decliner always declines (even if not currently visible, the
    // engine routes by persona sub).
    final ok2 = await engine.sendRequest(
      'sim-zahir-mays',
      ConnectRequestPayload(requestId: 'req-decline', senderCard: myCard),
    );
    expect(ok2, isTrue);
    final declined =
        await responses.next.timeout(const Duration(seconds: 10));
    expect(declined.payload.requestId, 'req-decline');
    expect(declined.payload.accepted, isFalse);

    // Unknown peers are not deliverable.
    expect(
      await engine.sendRequest(
        'sim-nobody',
        ConnectRequestPayload(requestId: 'req-x', senderCard: myCard),
      ),
      isFalse,
    );
    await engine.dispose();
  });

  test('sendFrame: persona decrypts, reply arrives sealed to my key + signed',
      () async {
    final engine = makeEngine();
    await engine.startSession(config());
    final peers = await firstNearbyWhere(engine, (p) => p.isNotEmpty);
    final persona = peers.first.card!;

    final frame = await me.sealMessageFrame(
      toSub: persona.sub,
      recipientXPubB64: persona.x25519Pub!,
      plain: {
        'from': myCard.sub,
        'messageId': 'm1',
        'body': 'Hey! Great talk earlier.',
        'sentAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    final replyFuture = engine.events
        .firstWhere((e) => e is PeerFrameReceived)
        .timeout(const Duration(seconds: 10));

    expect(await engine.sendFrame(persona.sub, frame), isTrue);

    final reply = await replyFuture as PeerFrameReceived;
    expect(reply.senderSub, persona.sub);

    // The reply must be openable with MY X25519 key…
    final plain = await me.openFrame(reply.frame);
    expect(plain['from'], persona.sub);
    expect(plain['body'], isNotEmpty);

    // …and carry a valid Ed25519 signature from the persona.
    final sig = plain['sig'] as String;
    final verified = await _TestIdentity.verify(
      persona.ed25519Pub!,
      sig,
      utf8.encode(_TestIdentity.canonical(plain)),
    );
    expect(verified, isTrue);
    await engine.dispose();
  });

  test('sendFrame with a frame sealed to the WRONG key is rejected', () async {
    final engine = makeEngine();
    await engine.startSession(config());
    final peers = await firstNearbyWhere(engine, (p) => p.isNotEmpty);
    final persona = peers.first.card!;

    // Sealed to my own key instead of the persona's — must not decrypt.
    final bad = await me.sealMessageFrame(
      toSub: persona.sub,
      recipientXPubB64: me.xPubB64,
      plain: {'from': myCard.sub, 'messageId': 'm2', 'body': 'oops'},
    );
    expect(await engine.sendFrame(persona.sub, bad), isFalse);
    await engine.dispose();
  });

  test('range() converges toward 1–2 m and bearing stays in (−π, π]',
      () async {
    final engine = makeEngine();
    await engine.startSession(config());
    final peers = await firstNearbyWhere(engine, (p) => p.isNotEmpty);
    final sub = peers.first.card!.sub;

    final samples = await engine
        .range(sub)
        .take(40)
        .toList()
        .timeout(const Duration(seconds: 10));
    expect(samples.length, 40);
    for (final s in samples) {
      expect(s.meters, greaterThan(0));
      expect(s.bearing, greaterThan(-3.15));
      expect(s.bearing, lessThanOrEqualTo(3.15));
    }
    // Later samples should be meaningfully closer to the 1–2 m target zone.
    final early = samples.take(5).map((s) => s.meters).reduce((a, b) => a + b) / 5;
    final late_ = samples.skip(35).map((s) => s.meters).reduce((a, b) => a + b) / 5;
    expect((late_ - 1.6).abs(), lessThanOrEqualTo((early - 1.6).abs() + 0.6));
    await engine.dispose();
  });

  test('no events or peer emissions leak after stopSession', () async {
    final engine = makeEngine();
    await engine.startSession(config());
    await firstNearbyWhere(engine, (p) => p.isNotEmpty);
    await engine.stopSession();

    final leaked = <Object>[];
    final sub1 = engine.events.listen(leaked.add);
    final sub2 = engine.nearbyPeers.listen((peers) {
      if (peers.isNotEmpty) leaked.add(peers);
    });
    // Long enough (scaled) for any stray timer to have fired.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(leaked, isEmpty);
    await sub1.cancel();
    await sub2.cancel();
    await engine.dispose();
  });
}

/// Minimal single-consumer queue over a broadcast stream (avoids adding a
/// package:async dependency for tests).
class StreamQueue<T> {
  StreamQueue(Stream<T> stream) {
    _sub = stream.listen((event) {
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete(event);
      } else {
        _buffer.add(event);
      }
    });
  }

  late final StreamSubscription<T> _sub;
  final List<T> _buffer = [];
  final List<Completer<T>> _waiters = [];

  Future<T> get next {
    if (_buffer.isNotEmpty) {
      return Future.value(_buffer.removeAt(0));
    }
    final c = Completer<T>();
    _waiters.add(c);
    return c.future;
  }

  Future<void> cancel() => _sub.cancel();
}
