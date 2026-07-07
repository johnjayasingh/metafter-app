import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashlib;
import 'package:cryptography/cryptography.dart';

import '../domain/models.dart';
import '../transport/envelope.dart';
import 'proximity_engine.dart';

/// Fake-but-faithful [ProximityEngine] for the `local`/`dev` flavors,
/// emulators and UI development (iOS simulators cannot advertise BLE).
///
/// A pool of ~10 professional personas behaves like real phones would:
///
///  * 2–4 personas pop into range over the first ~8 s of a session, then
///    random-walk their distances inside the session's distance budget;
///    occasionally one drops out and returns later.
///  * ~10 s in, one persona sends a connect request (sometimes with a note).
///  * [sendRequest] is answered 2–5 s later with an accept — except one
///    persona who always declines.
///  * Personas hold **real** X25519/Ed25519 key material: frames sent with
///    [sendFrame] are actually decrypted with the persona's agreement key,
///    and the canned reply is sealed to the session card's X25519 key and
///    Ed25519-signed, so the app's full crypto path is exercised end-to-end.
///  * [range] emits a plausible converging distance + smoothly wandering
///    bearing for the Find Person screen.
///
/// Deterministic-ish: all randomness comes from a seeded [math.Random].
/// [timeScale] compresses every delay (tests use e.g. `0.02`).
class SimulatedProximityEngine implements ProximityEngine {
  SimulatedProximityEngine({int seed = 20260707, double timeScale = 1.0})
      : _rnd = math.Random(seed),
        _timeScale = timeScale;

  final math.Random _rnd;
  final double _timeScale;

  final _nearbyCtrl = StreamController<List<NearbyPeer>>.broadcast();
  final _eventCtrl = StreamController<PeerEvent>.broadcast();

  final Set<Timer> _timers = {};
  final Set<StreamController<RangeSample>> _rangeCtrls = {};

  /// Bumped on every start/stop so late timers from a previous session are
  /// inert even if a cancel raced.
  int _generation = 0;
  bool _running = false;
  bool _disposed = false;
  SessionConfig? _config;

  late final List<_SimPersona> _personas = _buildPersonas();
  bool _keysReady = false;

  /// Personas currently in the simulation (visible or in a temporary
  /// dropout), keyed by sub.
  final Map<String, _SimActive> _active = {};
  int _requestSeq = 0;

  static const _tickBase = Duration(milliseconds: 600);

  // ---------------------------------------------------------------------
  // ProximityEngine
  // ---------------------------------------------------------------------

  @override
  Stream<List<NearbyPeer>> get nearbyPeers => _nearbyCtrl.stream;

  @override
  Stream<PeerEvent> get events => _eventCtrl.stream;

  @override
  bool get isRunning => _running;

  @override
  Future<void> startSession(SessionConfig config) async {
    if (_disposed) return;
    if (_running) await stopSession();

    _config = config;
    _running = true;
    final gen = ++_generation;

    await _ensureKeys();
    if (!_running || gen != _generation) return;

    // 2–4 personas appear over the first ~8 s.
    final pool = List<_SimPersona>.of(_personas)..shuffle(_rnd);
    final count = 2 + _rnd.nextInt(3);
    for (var i = 0; i < count; i++) {
      final delayMs = i == 0 ? 1200 : 2000 + _rnd.nextInt(6000);
      final persona = pool[i];
      _after(Duration(milliseconds: delayMs), gen, () => _appear(persona));
    }

    // Distance random walk + dropout/return + membership emission.
    _periodic(_tickBase, gen, _tick);

    // ~10 s in, one persona reaches out with a connect request.
    _after(const Duration(seconds: 10), gen, () {
      final visible = _visiblePersonas();
      if (visible.isEmpty || _eventCtrl.isClosed) return;
      final persona = visible[_rnd.nextInt(visible.length)];
      final withNote = _rnd.nextBool();
      _eventCtrl.add(PeerRequestReceived(ConnectRequestPayload(
        requestId: 'sim-req-${++_requestSeq}',
        senderCard: persona.card,
        note: withNote
            ? 'We met near the ${persona.company} booth — would love to '
                'stay in touch!'
            : null,
      )));
    });
  }

  @override
  Future<void> stopSession() async {
    _generation++;
    _running = false;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    for (final c in List.of(_rangeCtrls)) {
      await c.close();
    }
    _rangeCtrls.clear();
    _active.clear();
    if (!_nearbyCtrl.isClosed) _nearbyCtrl.add(const []);
  }

  @override
  Future<bool> sendRequest(String peerSub, ConnectRequestPayload payload) async {
    final persona = _personaBySub(peerSub);
    if (persona == null || !_running) return false;
    final gen = _generation;
    final delayMs = 2000 + _rnd.nextInt(3000); // 2–5 s
    _after(Duration(milliseconds: delayMs), gen, () {
      if (_eventCtrl.isClosed) return;
      _eventCtrl.add(PeerResponseReceived(ConnectResponsePayload(
        requestId: payload.requestId,
        accepted: !persona.alwaysDeclines,
        responderCard: persona.card,
      )));
    });
    return true;
  }

  @override
  Future<bool> sendResponse(
      String peerSub, ConnectResponsePayload payload) async {
    final persona = _personaBySub(peerSub);
    if (persona == null || !_running) return false;
    // A freshly accepted persona says hello over the nearby channel, which
    // exercises the inbound chat path right after the key exchange.
    if (payload.accepted) {
      final myCard = _config?.myCard;
      final firstName = myCard == null || myCard.name.trim().isEmpty
          ? 'there'
          : myCard.name.trim().split(RegExp(r'\s+')).first;
      _scheduleFrameFrom(
        persona,
        'Great to connect, $firstName! Glad we crossed paths today.',
        Duration(milliseconds: 2000 + _rnd.nextInt(1500)),
      );
    }
    return true;
  }

  @override
  Future<bool> sendFrame(String peerSub, Uint8List frame) async {
    final persona = _personaBySub(peerSub);
    if (persona == null || !_running) return false;

    // The persona really decrypts the frame with its X25519 key — a wrong
    // recipient key or tampered ciphertext fails here, like on a real device.
    String body;
    try {
      final envelope = Envelope.decode(utf8.decode(frame));
      final plain = await _SimCrypto.openJson(
        persona.xPair!,
        envelope.ephPub,
        envelope.nonce,
        envelope.ciphertext,
      );
      body = plain['body'] as String? ?? '';
    } catch (_) {
      return false;
    }

    _scheduleFrameFrom(
      persona,
      _replyTo(body),
      Duration(milliseconds: 1500 + _rnd.nextInt(2500)), // 1.5–4 s
    );
    return true;
  }

  @override
  bool isNearby(String peerSub) {
    final entry = _active[peerSub];
    if (entry == null || !_running) return false;
    final budget = _config?.maxMeters ?? 10;
    return entry.visible && entry.meters <= budget;
  }

  @override
  Stream<RangeSample> range(String peerSub) {
    late StreamController<RangeSample> ctrl;
    Timer? timer;
    final gen = _generation;

    // Converge to a personal-conversation distance as if both were walking
    // toward each other; the bearing wanders smoothly like a real estimate.
    final target = 1.2 + _rnd.nextDouble() * 0.8; // 1.2–2.0 m
    var meters = _active[peerSub]?.meters ?? (_config?.maxMeters ?? 5.0);
    var bearing = (_rnd.nextDouble() - 0.5) * math.pi;
    var lostTicks = 0;

    ctrl = StreamController<RangeSample>(
      onListen: () {
        timer = Timer.periodic(_scaled(const Duration(milliseconds: 450)),
            (t) {
          if (!_running || gen != _generation || ctrl.isClosed) {
            t.cancel();
            _timers.remove(t);
            if (!ctrl.isClosed) ctrl.close();
            return;
          }
          final entry = _active[peerSub];
          if (entry == null || !entry.visible) {
            // Peer lost: keep the stream alive briefly, then complete.
            if (++lostTicks > 6) {
              t.cancel();
              _timers.remove(t);
              ctrl.close();
              return;
            }
          } else {
            lostTicks = 0;
            // Keep the simulation coherent: converging in Find Person also
            // pulls the bubble on the Meet screen closer.
            entry.meters = meters;
          }
          meters += (target - meters) * 0.07 + _gauss() * 0.06;
          meters = meters.clamp(0.4, (_config?.maxMeters ?? 10) + 2);
          bearing += _gauss() * 0.12;
          bearing = _wrap(bearing * 0.97); // slow pull back toward "ahead"
          ctrl.add(RangeSample(
            meters: double.parse(meters.toStringAsFixed(2)),
            bearing: bearing,
          ));
        });
        _timers.add(timer!);
        _rangeCtrls.add(ctrl);
      },
      onCancel: () {
        timer?.cancel();
        _timers.remove(timer);
        _rangeCtrls.remove(ctrl);
      },
    );
    return ctrl.stream;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopSession();
    await _nearbyCtrl.close();
    await _eventCtrl.close();
  }

  // ---------------------------------------------------------------------
  // Simulation internals
  // ---------------------------------------------------------------------

  Duration _scaled(Duration d) => Duration(
      microseconds: math.max(1, (d.inMicroseconds * _timeScale).round()));

  void _after(Duration d, int gen, void Function() fn) {
    late final Timer t;
    t = Timer(_scaled(d), () {
      _timers.remove(t);
      if (_running && gen == _generation) fn();
    });
    _timers.add(t);
  }

  void _periodic(Duration d, int gen, void Function() fn) {
    late final Timer t;
    t = Timer.periodic(_scaled(d), (_) {
      if (!_running || gen != _generation) {
        t.cancel();
        _timers.remove(t);
        return;
      }
      fn();
    });
    _timers.add(t);
  }

  double _gauss() {
    // Box–Muller from the seeded generator.
    final u1 = math.max(_rnd.nextDouble(), 1e-9);
    final u2 = _rnd.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  static double _wrap(double a) {
    var r = a % (2 * math.pi);
    if (r > math.pi) r -= 2 * math.pi;
    if (r <= -math.pi) r += 2 * math.pi;
    return r;
  }

  _SimPersona? _personaBySub(String sub) {
    for (final p in _personas) {
      if (p.sub == sub) return p;
    }
    return null;
  }

  List<_SimPersona> _visiblePersonas() => [
        for (final e in _active.values)
          if (e.visible) e.persona,
      ];

  void _appear(_SimPersona persona) {
    final budget = _config?.maxMeters ?? 5.0;
    _active[persona.sub] = _SimActive(
      persona: persona,
      meters: 0.6 + _rnd.nextDouble() * (budget - 0.6).clamp(0.2, budget),
    );
    _emitNearby();
  }

  void _tick() {
    if (_active.isEmpty) return;
    final budget = _config?.maxMeters ?? 5.0;
    final now = DateTime.now();

    for (final entry in _active.values) {
      if (!entry.visible) {
        if (entry.returnAt != null && now.isAfter(entry.returnAt!)) {
          entry.visible = true;
          entry.returnAt = null;
          entry.meters = 0.6 + _rnd.nextDouble() * (budget - 0.6).clamp(0.2, budget);
        }
        continue;
      }
      // Random walk within [0.4, budget × 1.2]; beyond the budget the peer
      // is filtered from the emitted list (still tracked, may walk back).
      entry.meters =
          (entry.meters + (_rnd.nextDouble() - 0.5) * 0.5).clamp(0.4, budget * 1.2);

      // Occasionally someone wanders off entirely and comes back later.
      final visibleCount = _visiblePersonas().length;
      if (visibleCount > 1 && _rnd.nextDouble() < 0.012) {
        entry.visible = false;
        entry.returnAt =
            now.add(_scaled(Duration(seconds: 4 + _rnd.nextInt(7))));
      }
    }
    _emitNearby();
  }

  void _emitNearby() {
    if (_nearbyCtrl.isClosed) return;
    final budget = _config?.maxMeters ?? 5.0;
    final now = DateTime.now();
    final peers = <NearbyPeer>[
      for (final e in _active.values)
        if (e.visible && e.meters <= budget)
          NearbyPeer(
            eid: e.persona.eid,
            meters: double.parse(e.meters.toStringAsFixed(2)),
            mood: e.persona.mood,
            lastSeen: now,
            card: e.persona.card,
            rssi: _metersToRssi(e.meters),
          ),
    ]..sort((a, b) => a.meters.compareTo(b.meters));
    _nearbyCtrl.add(peers);
  }

  /// Inverse of the log-distance model so simulated RSSI looks plausible.
  static int _metersToRssi(double meters) =>
      (-59 - 20 * math.log(math.max(meters, 0.1)) / math.ln10).round();

  void _scheduleFrameFrom(_SimPersona persona, String body, Duration delay) {
    final myCard = _config?.myCard;
    final recipientXPub = myCard?.x25519Pub;
    final recipientSub = myCard?.sub ?? '';
    if (recipientXPub == null) return; // cannot seal without the app's key
    final gen = _generation;
    _after(delay, gen, () {
      // Sealing is async; re-check liveness when the ciphertext is ready.
      unawaited(() async {
        try {
          final frame = await _SimCrypto.buildMessageFrame(
            persona: persona,
            toSub: recipientSub,
            recipientXPubB64: recipientXPub,
            body: body,
          );
          if (!_running || gen != _generation || _eventCtrl.isClosed) return;
          _eventCtrl.add(PeerFrameReceived(persona.sub, frame));
        } catch (_) {
          // Never let a simulation hiccup crash the app.
        }
      }());
    });
  }

  String _replyTo(String inbound) {
    const canned = [
      'Absolutely — let me know when works for you.',
      'Nice! I was hoping we would run into each other here.',
      'Sounds good. I will send over the details later today.',
      "Great point. Let's grab a coffee before the next talk?",
      'Haha, agreed. This event has been surprisingly good.',
      'Sure thing — my calendar is open Thursday afternoon.',
      'Thanks for reaching out! Happy to chat more.',
      'Perfect, see you by the main stage in ten?',
    ];
    final idx =
        (inbound.hashCode.abs() + _rnd.nextInt(canned.length)) % canned.length;
    return canned[idx];
  }

  // ---------------------------------------------------------------------
  // Personas
  // ---------------------------------------------------------------------

  Future<void> _ensureKeys() async {
    if (_keysReady) return;
    final x = X25519();
    final ed = Ed25519();
    for (final p in _personas) {
      p.xPair = await x.newKeyPair();
      p.edPair = await ed.newKeyPair();
      p.xPubB64 = base64Encode((await p.xPair!.extractPublicKey()).bytes);
      p.edPubB64 = base64Encode((await p.edPair!.extractPublicKey()).bytes);
    }
    _keysReady = true;
  }

  static List<_SimPersona> _buildPersonas() {
    _SimPersona make(
      String name,
      String designation,
      String company,
      String intro,
      bool verified,
      MoodRing mood, {
      bool declines = false,
    }) {
      final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      return _SimPersona(
        sub: 'sim-$slug',
        name: name,
        designation: designation,
        company: company,
        intro: intro,
        verified: verified,
        mood: mood,
        alwaysDeclines: declines,
      );
    }

    return [
      make(
        'Koby Stone',
        'SVP Engineering',
        'InnoVision',
        'Engineering leader scaling platform teams; always keen to trade '
            'notes on shipping reliable products fast.',
        true,
        MoodRing.networking,
      ),
      make(
        'Owen Hill',
        'VP, Sales',
        'SaleSail',
        'I am a brand salesperson who focuses on clarity and emotional '
            'connections of clients.',
        false,
        MoodRing.networking,
      ),
      make(
        'Candice Wue',
        'Product Designer',
        'Northlight Studio',
        'Designing calm, human software. Ask me about design systems and '
            'why fewer screens beat more features.',
        true,
        MoodRing.friends,
      ),
      make(
        'Zahir Mays',
        'Marketing Lead',
        'BrightWave',
        'Growth storyteller — I turn products people need into products '
            'people want. Here mostly to listen.',
        false,
        MoodRing.justChecking,
        declines: true,
      ),
      make(
        'Rane Wells',
        'Data Scientist',
        'Quantifi',
        'ML for messy real-world data. Happiest when a model gets deleted '
            'because a heuristic won.',
        true,
        MoodRing.catchup,
      ),
      make(
        'Sophia Ramirez',
        'Engineering Manager',
        'CloudNest',
        'Building distributed systems and healthy on-call rotations. Let\'s '
            'talk platform teams and career ladders.',
        false,
        MoodRing.networking,
      ),
      make(
        'Jasmine Kaur',
        'Founder',
        'KairaLabs',
        'Second-time founder in developer tooling. Fundraising war stories '
            'traded for espresso recommendations.',
        true,
        MoodRing.networking,
      ),
      make(
        'Liam Smith',
        'CTO',
        'TechCorp',
        'CTO wrangling a monolith into services. Strong opinions, loosely '
            'held, about build vs buy.',
        false,
        MoodRing.catchup,
      ),
      make(
        'Olivia Rhye',
        'CEO',
        'Company',
        'Leading a team that believes small groups of focused people beat '
            'big ones every time.',
        true,
        MoodRing.networking,
      ),
      make(
        'Emma John',
        'CFO',
        'Finance Inc',
        'Finance for high-growth startups; I make runway conversations less '
            'scary. Recovering investment banker.',
        false,
        MoodRing.friends,
      ),
    ];
  }
}

/// One fake professional with real key material.
class _SimPersona {
  _SimPersona({
    required this.sub,
    required this.name,
    required this.designation,
    required this.company,
    required this.intro,
    required this.verified,
    required this.mood,
    required this.alwaysDeclines,
  });

  final String sub;
  final String name;
  final String designation;
  final String company;
  final String intro;
  final bool verified;
  final MoodRing mood;
  final bool alwaysDeclines;

  SimpleKeyPair? xPair;
  SimpleKeyPair? edPair;
  String? xPubB64;
  String? edPubB64;

  /// Stable fake ephemeral id: first 8 bytes of SHA-256(sub), hex.
  late final String eid = hashlib.sha256
      .convert(utf8.encode(sub))
      .bytes
      .sublist(0, 8)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  ProfileCard get card => ProfileCard(
        sub: sub,
        name: name,
        role: 'Working Professional',
        designation: designation,
        company: company,
        intro: intro,
        verified: verified,
        ed25519Pub: edPubB64,
        x25519Pub: xPubB64,
      );
}

class _SimActive {
  _SimActive({required this.persona, required this.meters});

  final _SimPersona persona;
  double meters;
  bool visible = true;
  DateTime? returnAt;
}

/// Persona-side crypto, wire-compatible with [CryptoService]:
/// ephemeral-static X25519 → HKDF-SHA256 (info `metafter/v1/seal`) →
/// ChaCha20-Poly1305, ciphertext = ct ‖ mac.
abstract final class _SimCrypto {
  static final _x = X25519();
  static final _ed = Ed25519();
  static final _aead = Chacha20.poly1305Aead();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static const _hkdfInfo = 'metafter/v1/seal';

  static Future<SecretKey> _deriveKey(
      SimpleKeyPair local, List<int> remotePub) async {
    final shared = await _x.sharedSecretKey(
      keyPair: local,
      remotePublicKey: SimplePublicKey(remotePub, type: KeyPairType.x25519),
    );
    return _hkdf.deriveKey(secretKey: shared, info: utf8.encode(_hkdfInfo));
  }

  /// Open a box sealed to [xPair]'s public key.
  static Future<Map<String, dynamic>> openJson(
    SimpleKeyPair xPair,
    String ephPubB64,
    String nonceB64,
    String ciphertextB64,
  ) async {
    final key = await _deriveKey(xPair, base64Decode(ephPubB64));
    final raw = base64Decode(ciphertextB64);
    const macLen = 16;
    final box = SecretBox(
      raw.sublist(0, raw.length - macLen),
      nonce: base64Decode(nonceB64),
      mac: Mac(raw.sublist(raw.length - macLen)),
    );
    final clear = await _aead.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  }

  /// Build a signed `message`-kind envelope frame from [persona] to the app.
  static Future<Uint8List> buildMessageFrame({
    required _SimPersona persona,
    required String toSub,
    required String recipientXPubB64,
    required String body,
  }) async {
    final plain = <String, dynamic>{
      'from': persona.sub,
      'messageId':
          'sim-msg-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}',
      'body': body,
      'sentAt': DateTime.now().toUtc().toIso8601String(),
    };
    final sig = await _ed.sign(
      utf8.encode(_canonical(plain)),
      keyPair: persona.edPair!,
    );
    plain['sig'] = base64Encode(sig.bytes);

    final eph = await _x.newKeyPair();
    final key = await _deriveKey(eph, base64Decode(recipientXPubB64));
    final nonce = _aead.newNonce();
    final box = await _aead.encrypt(
      utf8.encode(jsonEncode(plain)),
      secretKey: key,
      nonce: nonce,
    );
    final envelope = Envelope(
      id: 'sim-env-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}',
      to: toSub,
      kind: EnvelopeKind.message,
      ephPub: base64Encode((await eph.extractPublicKey()).bytes),
      nonce: base64Encode(nonce),
      ciphertext: base64Encode(box.cipherText + box.mac.bytes),
    );
    return Uint8List.fromList(utf8.encode(envelope.encode()));
  }

  /// Canonical form matching CryptoService.signJson: 'sig' removed, keys
  /// sorted, JSON-encoded.
  static String _canonical(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json)..remove('sig');
    final sorted = Map.fromEntries(
        copy.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return jsonEncode(sorted);
  }
}
