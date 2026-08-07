import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart' as ble;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

import '../domain/models.dart';
import 'direction_estimator.dart';
import 'distance_estimator.dart';
import 'proximity_engine.dart';

/// Real-BLE [ProximityEngine] (ARCHITECTURE.md §2).
///
/// Dual role:
///  * **Peripheral** (`bluetooth_low_energy`): advertises *only* the MetAfter
///    service UUID — no service data, manufacturer data or local name — and
///    runs the GATT server (ProfileCard read + the three write
///    characteristics). Service-UUID-only is the single advertisement shape
///    that succeeds on both CoreBluetooth (iOS) and Android's 31-byte legacy
///    packet, so every MetAfter device looks identical over the air (strictly
///    more private than a rotating-EID payload). Skipped in incognito mode and
///    degraded to scan-only when the platform lacks peripheral support
///    (e.g. iOS simulator).
///  * **Central** (`flutter_blue_plus`): scans filtered by the service UUID,
///    estimates distance from the scan RSSI using a *fixed* assumed 1 m TX
///    power ([txPowerAt1m]) — TX power is no longer advertised — and reads
///    peer profile cards over GATT on first sighting (≤2 concurrent connects),
///    then delivers requests/responses/frames as chunked GATT writes.
///
/// Identity and mood are *not* carried in the advertisement: a peer is
/// anonymous until its ProfileCard is read over GATT. Mood-over-BLE is not
/// implemented this phase — [NearbyPeer.mood] stays [MoodRing.networking].
/// [CryptoService.currentEid] is left in place but is now unused by the BLE
/// layer.
///
/// Every platform call is guarded — BLE stacks fail in creative ways and the
/// engine must never take the app down with it.
class BleProximityEngine implements ProximityEngine {
  BleProximityEngine();

  // -- UUIDs (ARCHITECTURE.md §2.2/§2.3) ----------------------------------

  /// "META…" service UUID — the only thing carried in the advertisement.
  static const serviceUuid = '4D455441-0001-4653-5445-524D45544146';

  /// ProfileCard — read (length-prefixed, chunked); also accepts a 1-byte
  /// chunk-index write (see [_chunkSize] protocol below).
  static const profileCardUuid = '4D455441-0002-4653-5445-524D45544146';

  /// ConnectRequest — write, JSON [ConnectRequestPayload].
  static const connectRequestUuid = '4D455441-0003-4653-5445-524D45544146';

  /// ConnectResponse — write, JSON [ConnectResponsePayload].
  static const connectResponseUuid = '4D455441-0004-4653-5445-524D45544146';

  /// Frame — write, JSON `{senderSub, frame: base64}`.
  static const frameUuid = '4D455441-0005-4653-5445-524D45544146';

  /// Assumed calibrated RSSI at 1 m used to turn scan RSSI into meters. Because
  /// TX power is no longer advertised (service-UUID-only), this is a fixed
  /// reference rather than a per-device value: real TX power varies by ±6 dB,
  /// so absolute distance is coarser, but the estimate is still smoothed by the
  /// per-peer EMA and only used to gate the distance budget.
  static const int txPowerAt1m = -59;

  /// Chunk size of the length-prefixed chunked read/serve protocol: the central
  /// writes a single byte `i` to the ProfileCard characteristic and the next
  /// read is served from offset `i * _chunkSize` of the length-prefixed value.
  static const int _chunkSize = 180;

  /// Absolute ceiling for a single GATT write chunk (BLE spec attribute max).
  static const int _maxWriteChunk = 512;

  static const _peerTtl = Duration(seconds: 10);
  static const int _maxConcurrentCardReads = 2;

  // -- state ---------------------------------------------------------------

  final _nearbyCtrl = StreamController<List<NearbyPeer>>.broadcast();
  final _eventCtrl = StreamController<PeerEvent>.broadcast();

  SessionConfig? _config;
  bool _running = false;
  bool _disposed = false;
  int _generation = 0;

  ble.PeripheralManager? _peripheral;
  bool _peripheralAvailable = false;
  ble.GATTService? _gattService;

  /// Peers keyed by the scan result's device remote id.
  final Map<String, _BlePeer> _peers = {};

  /// sub → device remote id of the device that presented that card (routing
  /// for send*).
  final Map<String, String> _subToEid = {};

  /// Cards cached per device remote id within the engine lifetime.
  final Map<String, ProfileCard> _cardByEid = {};

  int _cardReadsInFlight = 0;
  final List<String> _cardReadQueue = [];

  /// Reassembly buffers for inbound GATT writes, keyed by
  /// `centralUuid:charUuid`.
  final Map<String, _WriteBuffer> _writeBuffers = {};

  /// Chunked-read protocol: chunk index per central for ProfileCard reads.
  final Map<String, int> _readChunkIndex = {};

  final Set<Timer> _timers = {};
  final List<StreamSubscription<Object?>> _subs = [];

  // -------------------------------------------------------------------------
  // ProximityEngine
  // -------------------------------------------------------------------------

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
    // Fresh generation: clear the concurrency budget so any card read still
    // draining from a previous session (whose whenComplete decrement is now
    // generation-gated) can't corrupt this session's counter.
    _cardReadsInFlight = 0;

    final ready = await _ensureBluetoothReady();
    if (!ready) {
      _running = false;
      // Throw rather than return quietly: SessionService catches this and maps
      // it to a visible message. Returning normally let it move to
      // SessionActive and start the countdown with the radio never started —
      // the UI said "You are discoverable" while nothing was advertising or
      // scanning, which is what made this so hard to spot.
      throw StateError('Bluetooth permission or adapter unavailable');
    }
    // Session was cancelled (or superseded) while we awaited — that is a
    // normal race, not an error, so unwind silently.
    if (!_running || gen != _generation) {
      _running = false;
      return;
    }

    if (!config.incognito) {
      // Bounded on purpose. _startPeripheral's own awaits are individually
      // capped, but the vendor BLE stack can wedge *inside* a single call —
      // observed on Android 16, where the GATT server registers and then
      // addService/startAdvertising never returns. Unbounded, that leaves
      // startSession() hung forever: the UI sits on "Starting…" and, worse,
      // _startScanning() below is never reached, so the radio stays deaf even
      // though this class already supports scan-only degradation. Cap it and
      // fall through — advertising is best-effort, scanning is not.
      await _startPeripheral(gen).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint('BLE: peripheral start timed out — continuing scan-only');
          _peripheralAvailable = false;
        },
      );
      if (!_running || gen != _generation) return;

      // The very first bring-up in a process routinely wedges while the
      // manager is still settling (both test devices reproduced it); the next
      // attempt succeeds. Without this retry the device silently spends the
      // whole session scan-only — it can see peers but no peer can see it,
      // which presents to users as one-way discovery.
      if (!_peripheralAvailable) {
        unawaited(Future<void>.delayed(const Duration(seconds: 3), () async {
          if (!_running || gen != _generation || _peripheralAvailable) return;
          debugPrint('BLE: retrying peripheral start');
          await _startPeripheral(gen).timeout(
            const Duration(seconds: 12),
            onTimeout: () => _peripheralAvailable = false,
          );
        }));
      }
    }
    await _startScanning(gen);

    // Expire peers not seen for a while.
    _periodic(const Duration(seconds: 1), gen, _sweepExpired);
  }

  @override
  Future<void> stopSession() async {
    _generation++;
    _running = false;

    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();

    try {
      await fbp.FlutterBluePlus.stopScan();
    } catch (_) {}
    final peripheral = _peripheral;
    if (peripheral != null) {
      try {
        await peripheral.stopAdvertising();
      } catch (_) {}
      try {
        await peripheral.removeAllServices();
      } catch (_) {}
    }
    _gattService = null;

    _peers.clear();
    _writeBuffers.clear();
    _readChunkIndex.clear();
    _cardReadQueue.clear();
    // NOTE: do not reset _cardReadsInFlight here — reads still in flight will
    // run their (generation-gated) whenComplete after this returns. The
    // counter is instead reset at the start of the next session.
    if (!_nearbyCtrl.isClosed) _nearbyCtrl.add(const []);
  }

  @override
  Future<bool> sendRequest(String peerSub, ConnectRequestPayload payload) {
    final json = payload.toJson();
    _stripCardPhoto(json);
    return _writeJsonTo(peerSub, connectRequestUuid, json);
  }

  @override
  Future<bool> sendResponse(String peerSub, ConnectResponsePayload payload) {
    final json = payload.toJson();
    _stripCardPhoto(json);
    return _writeJsonTo(peerSub, connectResponseUuid, json);
  }

  @override
  Future<bool> sendFrame(String peerSub, Uint8List frame) =>
      _writeJsonTo(peerSub, frameUuid, {
        'senderSub': _config?.myCard.sub ?? '',
        'frame': base64Encode(frame),
      });

  @override
  bool isNearby(String peerSub) {
    final eid = _subToEid[peerSub];
    if (eid == null) return false;
    final peer = _peers[eid];
    if (peer == null) return false;
    return DateTime.now().difference(peer.lastSeen) < _peerTtl;
  }

  @override
  Stream<RangeSample> range(String peerSub) {
    // Per-sighting meters for this peer, ending when the peer drops out of
    // the nearby list for good.
    final meters = _nearbyCtrl.stream
        .map((peers) {
          for (final p in peers) {
            if (p.card?.sub == peerSub) return p.meters;
          }
          return null;
        })
        .where((m) => m != null)
        .cast<double>();
    return DirectionEstimator(meters: meters).stream;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopSession();
    await _nearbyCtrl.close();
    await _eventCtrl.close();
  }

  // -------------------------------------------------------------------------
  // Permissions / adapter readiness
  // -------------------------------------------------------------------------

  /// Mirrors the app's existing Bluetooth bootstrap (home_shell.dart):
  /// permission_handler runtime permissions on Android, system prompts on
  /// iOS, then wait for the adapter to be on.
  Future<bool> _ensureBluetoothReady() async {
    try {
      if (!await fbp.FlutterBluePlus.isSupported) return false;
    } catch (_) {
      // isSupported can throw on the iOS Simulator — continue.
    }

    if (Platform.isAndroid) {
      try {
        // ONLY the BLE trio may gate the session. ACCESS_FINE_LOCATION is
        // declared `maxSdkVersion="30"` in the manifest (BLUETOOTH_SCAN
        // carries `neverForLocation`), so from API 31 on it is not part of the
        // merged manifest at all — requesting it can only ever come back
        // denied. Including it here meant `granted` was false on every modern
        // Android device, so _startScanning() was never reached and discovery
        // was dead while the UI still counted down "You are discoverable".
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();
        final granted =
            statuses.values.every((s) => s.isGranted || s.isLimited);
        if (!granted) return false;
      } catch (_) {
        return false;
      }

      // API ≤30 still needs location to see scan results (there the trio is
      // auto-granted by permission_handler and this is the permission that
      // actually matters). Best-effort: it must never gate a modern session.
      try {
        await Permission.locationWhenInUse.request();
      } catch (_) {
        // Irrelevant on API 31+, where the permission no longer exists.
      }

      try {
        await fbp.FlutterBluePlus.turnOn();
      } catch (_) {
        // user may decline; the adapter check below will surface that.
      }

      return _waitForAdapterOn();
    }

    // iOS/macOS: CBCentralManager is created lazily on the first fbp call and
    // reports .unknown for a short window — and until the first-run Bluetooth
    // permission dialog is answered. fbp's darwin startScan hard-errors unless
    // the adapter is poweredOn, so wait for it here (bounded) exactly like the
    // Android branch, otherwise a cold start / permission-prompt race leaves
    // scanning silently dead for the whole session.
    return _waitForAdapterOn();
  }

  /// Waits (bounded) for the fbp adapter to report [fbp.BluetoothAdapterState.on].
  Future<bool> _waitForAdapterOn() async {
    try {
      final state = await fbp.FlutterBluePlus.adapterState
          .where((s) => s == fbp.BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 6),
              onTimeout: () => fbp.BluetoothAdapterState.unknown);
      return state == fbp.BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Peripheral role — advertise + GATT server
  // -------------------------------------------------------------------------

  Future<void> _startPeripheral(int gen) async {
    _peripheralAvailable = false;
    try {
      final peripheral = _peripheral ??= ble.PeripheralManager();

      // Wait for the peripheral stack to power on BEFORE authorizing.
      //
      // Order matters and used to be the other way round. A freshly built
      // PeripheralManager reports `unknown` for a moment, and calling
      // authorize() inside that window never returns on Android 16 (observed
      // on both a vivo V2515 and a Samsung SM-M176B) — the future simply never
      // completes, wedging the whole peripheral role. The device then scans
      // happily while advertising nothing, so it is undiscoverable and two
      // phones sitting next to each other never see one another.
      //
      // (unavailable on iOS simulators — we degrade to scan-only below.)
      if (peripheral.state != ble.BluetoothLowEnergyState.poweredOn) {
        try {
          await peripheral.stateChanged
              .map((e) => e.state)
              .where((s) => s == ble.BluetoothLowEnergyState.poweredOn)
              .first
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          if (peripheral.state != ble.BluetoothLowEnergyState.poweredOn) {
            return; // scan-only degradation
          }
        }
      }

      // Android needs its own runtime authorization path for the plugin. Still
      // bounded as a backstop — _ensureBluetoothReady() has already secured
      // BLUETOOTH_ADVERTISE/CONNECT, so continuing on timeout is safe.
      if (Platform.isAndroid) {
        try {
          await peripheral.authorize().timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
      if (!_running || gen != _generation) return;

      _subs.add(peripheral.characteristicReadRequested
          .listen(_onCharacteristicRead, onError: (Object _) {}));
      _subs.add(peripheral.characteristicWriteRequested
          .listen(_onCharacteristicWrite, onError: (Object _) {}));

      await peripheral.removeAllServices();
      _gattService = _buildGattService();
      await peripheral.addService(_gattService!);
      await _advertise(peripheral);
      debugPrint('BLE: advertising up');
      _peripheralAvailable = true;

      // Sweep stale half-assembled writes.
      _periodic(const Duration(seconds: 5), gen, _sweepWriteBuffers);
    } catch (e) {
      // Peripheral role unavailable — keep the engine alive, scan-only.
      // Never silent: an invisible-but-scanning device is the hardest field
      // failure to diagnose (it looks like the OTHER device is broken).
      debugPrint('BLE: peripheral start failed ($e) — scan-only');
      _peripheralAvailable = false;
    }
  }

  ble.GATTService _buildGattService() {
    ble.GATTCharacteristic writable(String uuid) =>
        ble.GATTCharacteristic.mutable(
          uuid: ble.UUID.fromString(uuid),
          properties: const [
            ble.GATTCharacteristicProperty.write,
            ble.GATTCharacteristicProperty.writeWithoutResponse,
          ],
          permissions: const [ble.GATTCharacteristicPermission.write],
          descriptors: const [],
        );

    return ble.GATTService(
      uuid: ble.UUID.fromString(serviceUuid),
      isPrimary: true,
      includedServices: const [],
      characteristics: [
        // ProfileCard: read (offset-aware) + 1-byte chunk-index write.
        ble.GATTCharacteristic.mutable(
          uuid: ble.UUID.fromString(profileCardUuid),
          properties: const [
            ble.GATTCharacteristicProperty.read,
            ble.GATTCharacteristicProperty.write,
          ],
          permissions: const [
            ble.GATTCharacteristicPermission.read,
            ble.GATTCharacteristicPermission.write,
          ],
          descriptors: const [],
        ),
        writable(connectRequestUuid),
        writable(connectResponseUuid),
        writable(frameUuid),
      ],
    );
  }

  /// Advertises the service UUID only. This is the one advertisement shape that
  /// succeeds on both CoreBluetooth and Android's 31-byte legacy packet; no
  /// service data / manufacturer data / local name is included (a local name
  /// on Android would persistently rename the system Bluetooth adapter).
  Future<void> _advertise(ble.PeripheralManager peripheral) async {
    final svc = ble.UUID.fromString(serviceUuid);
    await peripheral.startAdvertising(ble.Advertisement(
      serviceUUIDs: [svc],
    ));
  }

  void _onCharacteristicRead(ble.GATTCharacteristicReadRequestedEventArgs e) {
    final peripheral = _peripheral;
    if (peripheral == null) return;
    unawaited(() async {
      try {
        if (e.characteristic.uuid != ble.UUID.fromString(profileCardUuid)) {
          await peripheral.respondReadRequestWithError(
            e.request,
            error: ble.GATTError.readNotPermitted,
          );
          return;
        }
        final bytes = _servedCardBytes();
        final base =
            (_readChunkIndex[e.central.uuid.toString()] ?? 0) * _chunkSize;
        final start = math.min(base + e.request.offset, bytes.length);
        // Serve at most one fallback chunk per read; platform long reads walk
        // the value with increasing offsets from the same base.
        final end = math.min(start + _chunkSize, bytes.length);
        await peripheral.respondReadRequestWithValue(
          e.request,
          value: Uint8List.fromList(bytes.sublist(start, end)),
        );
      } catch (_) {}
    }());
  }

  /// The ProfileCard value served over GATT: a 4-byte big-endian length header
  /// followed by the JSON card with [ProfileCard.photoBase64] omitted. The
  /// photo thumbnail is 15–60 KB and must never traverse GATT; BLE-discovered
  /// peers render initials (acceptable — they are physically present). The
  /// length prefix lets the reader know the exact size and stop correctly.
  Uint8List _servedCardBytes() {
    final card = _config?.myCard;
    final jsonStr = card == null ? '{}' : _cardJsonWithoutPhoto(card);
    final payload = utf8.encode(jsonStr);
    final out = Uint8List(4 + payload.length);
    final len = payload.length;
    out[0] = (len >> 24) & 0xff;
    out[1] = (len >> 16) & 0xff;
    out[2] = (len >> 8) & 0xff;
    out[3] = len & 0xff;
    out.setRange(4, out.length, payload);
    return out;
  }

  void _onCharacteristicWrite(
      ble.GATTCharacteristicWriteRequestedEventArgs e) {
    final peripheral = _peripheral;
    if (peripheral == null) return;
    unawaited(() async {
      try {
        final charUuid = e.characteristic.uuid.toString().toUpperCase();
        final centralKey = e.central.uuid.toString();

        // ProfileCard chunk-index write (chunked-read protocol).
        if (charUuid == profileCardUuid.toUpperCase()) {
          if (e.request.value.length == 1) {
            _readChunkIndex[centralKey] = e.request.value[0];
          }
          await peripheral.respondWriteRequest(e.request);
          return;
        }

        final key = '$centralKey:$charUuid';
        final buffer = _writeBuffers.putIfAbsent(key, _WriteBuffer.new);
        // Outbound writes are length-prefixed and chunked into mtu-3 pieces
        // written sequentially, so append in arrival order (offset is 0 for
        // each application-level chunk).
        buffer.add(e.request.value);
        await peripheral.respondWriteRequest(e.request);

        final json = buffer.takeComplete();
        if (json != null) {
          _writeBuffers.remove(key);
          debugPrint('BLE-recv: complete write on $charUuid '
              '(${json.keys.join(",")})');
          _dispatchInboundWrite(charUuid, json);
        }
      } catch (e) {
        debugPrint('BLE-recv: write handling failed: $e');
      }
    }());
  }

  void _dispatchInboundWrite(String charUuid, Map<String, dynamic> json) {
    if (_eventCtrl.isClosed) return;
    try {
      if (charUuid == connectRequestUuid.toUpperCase()) {
        _eventCtrl.add(PeerRequestReceived(ConnectRequestPayload.fromJson(json)));
      } else if (charUuid == connectResponseUuid.toUpperCase()) {
        _eventCtrl
            .add(PeerResponseReceived(ConnectResponsePayload.fromJson(json)));
      } else if (charUuid == frameUuid.toUpperCase()) {
        final sub = json['senderSub'] as String? ?? '';
        final b64 = json['frame'] as String? ?? '';
        if (sub.isNotEmpty && b64.isNotEmpty) {
          _eventCtrl.add(PeerFrameReceived(sub, base64Decode(b64)));
        }
      }
    } catch (_) {
      // Malformed payload from a misbehaving peer — drop it.
    }
  }

  void _sweepWriteBuffers() {
    final now = DateTime.now();
    _writeBuffers.removeWhere(
        (_, b) => now.difference(b.lastWrite) > const Duration(seconds: 15));
  }

  // -------------------------------------------------------------------------
  // Central role — scan / distance / card reads
  // -------------------------------------------------------------------------

  Future<void> _startScanning(int gen) async {
    try {
      _subs.add(fbp.FlutterBluePlus.scanResults.listen(
        (results) => _onScanResults(gen, results),
        onError: (Object _) {},
      ));
      await fbp.FlutterBluePlus.startScan(
        withServices: [fbp.Guid(serviceUuid)],
        continuousUpdates: true,
        androidScanMode: fbp.AndroidScanMode.lowLatency,
      );
    } catch (e) {
      // Scan failure leaves the engine running; the peripheral side may
      // still make us discoverable to others.
      debugPrint('BLE: scan start failed: $e');
    }
  }

  void _onScanResults(int gen, List<fbp.ScanResult> results) {
    if (!_running || gen != _generation) return;
    final budget = _config?.maxMeters ?? 10.0;
    final svcGuid = fbp.Guid(serviceUuid);
    var changed = false;

    for (final r in results) {
      // The scan filter already restricts to our service UUID, but some
      // Android stacks surface unrelated devices — drop anything that lists
      // service UUIDs without ours.
      final advUuids = r.advertisementData.serviceUuids;
      if (advUuids.isNotEmpty && !advUuids.contains(svcGuid)) continue;

      final id = r.device.remoteId.str;
      if (id.isEmpty) continue;

      final peer = _peers.putIfAbsent(
        id,
        () => _BlePeer(eid: id, device: r.device, card: _cardByEid[id]),
      );

      // fbp re-emits its whole cumulative scan list on every advertisement, so
      // skip entries whose sighting time hasn't advanced — otherwise a
      // departed peer's stale result would keep getting its lastSeen refreshed
      // and its stale RSSI re-fed into the estimator, pinning ghosts forever.
      if (peer.lastResultAt != null &&
          !r.timeStamp.isAfter(peer.lastResultAt!)) {
        continue;
      }
      peer.lastResultAt = r.timeStamp;
      peer.device = r.device;
      peer.rssi = r.rssi;
      peer.meters = peer.estimator.update(r.rssi, txPowerAt1m);
      peer.lastSeen = r.timeStamp;
      if (peer.card != null) peer.verified = peer.card!.verified;
      changed = true;

      if (peer.card == null &&
          !peer.cardReadInFlight &&
          peer.cardReadAttempts <= 1 && // initial try + one retry
          peer.meters <= budget * _budgetExitFactor) {
        // Pre-fetch out to the exit threshold so the card is already loaded by
        // the time the peer is admitted — the bubble appears as a person, not
        // a dashed ring.
        _enqueueCardRead(id, gen);
      }
    }

    if (changed) _emitNearby();
  }

  void _sweepExpired() {
    final now = DateTime.now();
    final before = _peers.length;
    _peers.removeWhere((_, p) => now.difference(p.lastSeen) > _peerTtl);
    if (_peers.length != before) _emitNearby();
  }

  /// Hysteresis width of the distance budget: a peer is admitted at
  /// `<= budget` and only evicted again beyond `budget × this`. RSSI is noisy
  /// (±10 dB swings at a fixed half-meter are routine — a hand or torso in the
  /// path doubles the log-distance estimate), so a hard cutoff at the budget
  /// made peers standing still at 1–2 ft flicker in and out of the radar
  /// whenever a dip pushed the estimate past the (tight, 2 m default) budget.
  static const double _budgetExitFactor = 1.6;

  void _emitNearby() {
    if (_nearbyCtrl.isClosed) return;
    final budget = _config?.maxMeters ?? 10.0;
    final exit = budget * _budgetExitFactor;
    final list = <NearbyPeer>[
      for (final p in _peers.values)
        if (_gateInRange(p, budget, exit))
          NearbyPeer(
            eid: p.eid,
            meters: double.parse(p.meters.toStringAsFixed(2)),
            mood: p.mood,
            lastSeen: p.lastSeen,
            card: p.card,
            rssi: p.rssi,
          ),
    ]..sort((a, b) => a.meters.compareTo(b.meters));
    _nearbyCtrl.add(list);
  }

  /// Enter/exit gating for one peer (see [_budgetExitFactor]).
  static bool _gateInRange(_BlePeer p, double budget, double exit) {
    if (p.inRange) {
      if (p.meters > exit) p.inRange = false;
    } else {
      if (p.meters <= budget) p.inRange = true;
    }
    return p.inRange;
  }

  void _enqueueCardRead(String eid, int gen) {
    final peer = _peers[eid];
    if (peer == null || peer.cardReadInFlight) return;
    peer.cardReadInFlight = true;
    _cardReadQueue.add(eid);
    _pumpCardReads(gen);
  }

  void _pumpCardReads(int gen) {
    while (_cardReadsInFlight < _maxConcurrentCardReads &&
        _cardReadQueue.isNotEmpty) {
      final eid = _cardReadQueue.removeAt(0);
      final peer = _peers[eid];
      if (peer == null) continue;
      _cardReadsInFlight++;
      unawaited(_readCard(peer, gen).whenComplete(() {
        // Guard the decrement with the same generation check the rest of the
        // callback uses: a read that outlived its session must not touch this
        // session's counter (the counter was reset at session start instead).
        if (gen != _generation) return;
        _cardReadsInFlight--;
        peer.cardReadInFlight = false;
        if (_running) _pumpCardReads(gen);
      }));
    }
  }

  Future<void> _readCard(_BlePeer peer, int gen) async {
    peer.cardReadAttempts++;
    try {
      final chr = await _connectAndFind(peer.device, profileCardUuid);
      if (chr == null) return;

      // Reset the server-side chunk index in case a previous chunked read by
      // this central left it non-zero (best-effort — plain read still works
      // against servers that ignore the write).
      try {
        await chr.write(const [0], withoutResponse: false);
      } catch (_) {}

      final buf = <int>[...await chr.read()];
      int? total = _framedTotal(buf);

      // Length-prefixed chunked read: write the next chunk index, read the
      // served window from that offset, append, until the declared length is
      // satisfied. The 1-byte chunk index caps the walk at 255 windows, which
      // is far more than a photo-stripped card ever needs.
      var chunk = 1;
      while ((total == null || buf.length < total) && chunk <= 255) {
        try {
          await chr.write([chunk], withoutResponse: false);
        } catch (_) {
          break;
        }
        final part = await chr.read();
        if (part.isEmpty) break;
        buf.addAll(part);
        total ??= _framedTotal(buf);
        chunk++;
      }

      ProfileCard? card;
      if (total != null && buf.length >= total) {
        card = _tryDecodeCard(buf.sublist(4, total));
      }

      if (card != null) {
        peer.card = card;
        peer.verified = card.verified;
        _cardByEid[peer.eid] = card;
        if (card.sub.isNotEmpty) _subToEid[card.sub] = peer.eid;
        if (_running && gen == _generation) _emitNearby();
      }
    } catch (_) {
      // connect/read failed — the scan handler retries once (attempts ≤ 1).
    } finally {
      try {
        await peer.device.disconnect();
      } catch (_) {}
    }
  }

  /// Total framed length (4-byte header + declared payload) once the header has
  /// arrived, else null.
  int? _framedTotal(List<int> bytes) {
    if (bytes.length < 4) return null;
    final len =
        (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    if (len < 0) return null;
    return 4 + len;
  }

  ProfileCard? _tryDecodeCard(List<int> bytes) {
    try {
      final card = ProfileCard.decode(utf8.decode(bytes));
      return card.name.isEmpty && card.sub.isEmpty ? null : card;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Outbound writes
  // -------------------------------------------------------------------------

  /// JSON of [card] with the photo thumbnail omitted (never sent over BLE).
  static String _cardJsonWithoutPhoto(ProfileCard card) {
    final map = card.toJson()..remove('photo');
    return jsonEncode(map);
  }

  /// Strips the embedded card's photo thumbnail from a request/response
  /// payload JSON in place (the card lives under the `'card'` key).
  static void _stripCardPhoto(Map<String, dynamic> json) {
    final card = json['card'];
    if (card is Map) card.remove('photo');
  }

  Future<bool> _writeJsonTo(
      String peerSub, String charUuid, Map<String, dynamic> json) async {
    final eid = _subToEid[peerSub];
    final peer = eid == null ? null : _peers[eid];
    if (peer == null) return false;

    // Length-prefixed frame so the receiver's reassembly knows the exact size.
    final payload = utf8.encode(jsonEncode(json));
    final framed = Uint8List(4 + payload.length);
    final len = payload.length;
    framed[0] = (len >> 24) & 0xff;
    framed[1] = (len >> 16) & 0xff;
    framed[2] = (len >> 8) & 0xff;
    framed[3] = len & 0xff;
    framed.setRange(4, framed.length, payload);

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final chr = await _connectAndFind(peer.device, charUuid);
        if (chr == null) continue;

        // Base the chunk size on the negotiated MTU (request a larger one on
        // Android where the API allows) so payloads over the iOS ~185-byte MTU
        // are split into sequential mtu-3 writes instead of failing.
        var mtu = peer.device.mtuNow;
        if (Platform.isAndroid) {
          try {
            mtu = await peer.device.requestMtu(_maxWriteChunk);
          } catch (_) {}
        }
        final chunkSize =
            math.max(20, math.min(mtu - 3, _maxWriteChunk));

        for (var off = 0; off < framed.length; off += chunkSize) {
          final end = math.min(off + chunkSize, framed.length);
          await chr.write(
            framed.sublist(off, end),
            withoutResponse: false,
          );
        }
        debugPrint('BLE-write: ${framed.length}B to $charUuid OK '
            '(chunk=$chunkSize)');
        return true;
      } catch (e) {
        debugPrint('BLE-write: attempt $attempt to $charUuid failed: $e');
        // retry once
      } finally {
        try {
          await peer.device.disconnect();
        } catch (_) {}
      }
    }
    return false;
  }

  /// Connect to [device], discover services and return the characteristic
  /// with [charUuid] under our service, or null when absent.
  Future<fbp.BluetoothCharacteristic?> _connectAndFind(
      fbp.BluetoothDevice device, String charUuid) async {
    if (device.isDisconnected) {
      await device.connect(
        license: fbp.License.free,
        timeout: const Duration(seconds: 10),
      );
    }
    final services = await device.discoverServices();
    final svcGuid = fbp.Guid(serviceUuid);
    final chrGuid = fbp.Guid(charUuid);
    for (final s in services) {
      if (s.serviceUuid != svcGuid) continue;
      for (final c in s.characteristics) {
        if (c.characteristicUuid == chrGuid) return c;
      }
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _periodic(Duration d, int gen, void Function() fn) {
    late final Timer t;
    t = Timer.periodic(d, (_) {
      if (!_running || gen != _generation) {
        t.cancel();
        _timers.remove(t);
        return;
      }
      fn();
    });
    _timers.add(t);
  }

  /// Whether the advertise/GATT-server side came up (false on platforms
  /// without peripheral support — the engine then runs scan-only).
  bool get isAdvertising => _peripheralAvailable;
}

class _BlePeer {
  _BlePeer({required this.eid, required this.device, this.card});

  final String eid;
  fbp.BluetoothDevice device;
  final DistanceEstimator estimator = DistanceEstimator();
  double meters = double.infinity;
  int? rssi;

  /// Mood-over-BLE is not implemented this phase — peers default to networking
  /// and the ProfileCard read does not carry mood.
  MoodRing mood = MoodRing.networking;
  bool verified = false;
  DateTime lastSeen = DateTime.now();

  /// Sighting time of the last scan result actually processed for this peer,
  /// used to ignore fbp's cumulative re-emissions of unchanged results.
  DateTime? lastResultAt;
  ProfileCard? card;
  bool cardReadInFlight = false;
  int cardReadAttempts = 0;

  /// Distance-budget hysteresis state (see [_emitNearby]). Admitted when the
  /// smoothed estimate first dips inside the budget; only evicted again once
  /// it exceeds the wider exit threshold.
  bool inRange = false;
}

/// Accumulates length-prefixed, chunked GATT writes (4-byte big-endian length
/// header + JSON payload) until the full frame has arrived.
class _WriteBuffer {
  final List<int> _bytes = [];
  DateTime lastWrite = DateTime.now();

  void add(List<int> value) {
    lastWrite = DateTime.now();
    _bytes.addAll(value);
  }

  /// Returns the decoded JSON object once the declared length has fully
  /// arrived, otherwise null (more chunks still expected).
  Map<String, dynamic>? takeComplete() {
    if (_bytes.length < 4) return null;
    final len =
        (_bytes[0] << 24) | (_bytes[1] << 16) | (_bytes[2] << 8) | _bytes[3];
    if (len < 0 || _bytes.length < 4 + len) return null;
    try {
      final decoded = jsonDecode(utf8.decode(_bytes.sublist(4, 4 + len)));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
