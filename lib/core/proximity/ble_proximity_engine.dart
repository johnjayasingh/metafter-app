import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart' as ble;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

import '../crypto/crypto_service.dart';
import '../domain/models.dart';
import 'direction_estimator.dart';
import 'distance_estimator.dart';
import 'proximity_engine.dart';

/// Real-BLE [ProximityEngine] (ARCHITECTURE.md §2).
///
/// Dual role:
///  * **Peripheral** (`bluetooth_low_energy`): advertises the MetAfter
///    service with `EID ‖ flags ‖ mood ‖ txPower` service data (EID rotates
///    every 15 min) and runs the GATT server (ProfileCard read + the three
///    write characteristics). Skipped entirely in incognito mode, and
///    degraded to scan-only when the platform lacks peripheral support
///    (e.g. iOS simulator).
///  * **Central** (`flutter_blue_plus`): scans filtered by the service UUID,
///    estimates distance from RSSI + advertised TX power ([DistanceEstimator]),
///    reads peer profile cards on first sighting (≤2 concurrent connects),
///    and delivers requests/responses/frames as GATT writes.
///
/// Every platform call is guarded — BLE stacks fail in creative ways and the
/// engine must never take the app down with it.
class BleProximityEngine implements ProximityEngine {
  BleProximityEngine();

  // -- UUIDs (ARCHITECTURE.md §2.2/§2.3) ----------------------------------

  /// "META…" service UUID carried in the advertisement.
  static const serviceUuid = '4D455441-0001-4653-5445-524D45544146';

  /// ProfileCard — read (chunked); also accepts a 1-byte chunk-index write
  /// (see [_chunkSize] protocol below).
  static const profileCardUuid = '4D455441-0002-4653-5445-524D45544146';

  /// ConnectRequest — write, JSON [ConnectRequestPayload].
  static const connectRequestUuid = '4D455441-0003-4653-5445-524D45544146';

  /// ConnectResponse — write, JSON [ConnectResponsePayload].
  static const connectResponseUuid = '4D455441-0004-4653-5445-524D45544146';

  /// Frame — write, JSON `{senderSub, frame: base64}`.
  static const frameUuid = '4D455441-0005-4653-5445-524D45544146';

  /// Calibrated TX power at 1 m advertised in byte 10 of the service data.
  static const int txPowerAt1m = -59;

  /// Chunk size of the explicit chunked-read fallback protocol: the central
  /// writes a single byte `i` to the ProfileCard characteristic and the next
  /// read is served from offset `i * _chunkSize`. Used when the platform's
  /// own long-read (offset) mechanism doesn't deliver the full card.
  static const int _chunkSize = 180;

  static const _peerTtl = Duration(seconds: 10);
  static const _eidRotation = Duration(minutes: 15);
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

  /// Peers keyed by advertised EID.
  final Map<String, _BlePeer> _peers = {};

  /// sub → EID of the device that presented that card (routing for send*).
  final Map<String, String> _subToEid = {};

  /// Cards cached across EID rotations within the engine lifetime.
  final Map<String, ProfileCard> _cardByEid = {};

  int _cardReadsInFlight = 0;
  final List<String> _cardReadQueue = [];

  /// Reassembly buffers for inbound GATT writes, keyed by
  /// `centralUuid:charUuid`.
  final Map<String, _WriteBuffer> _writeBuffers = {};

  /// Chunked-read fallback: chunk index per central for ProfileCard reads.
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

    final ready = await _ensureBluetoothReady();
    if (!ready || !_running || gen != _generation) {
      _running = false;
      return;
    }

    if (!config.incognito) {
      await _startPeripheral(gen);
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
    _cardReadsInFlight = 0;
    if (!_nearbyCtrl.isClosed) _nearbyCtrl.add(const []);
  }

  @override
  Future<bool> sendRequest(String peerSub, ConnectRequestPayload payload) =>
      _writeJsonTo(peerSub, connectRequestUuid, payload.toJson());

  @override
  Future<bool> sendResponse(String peerSub, ConnectResponsePayload payload) =>
      _writeJsonTo(peerSub, connectResponseUuid, payload.toJson());

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
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.locationWhenInUse,
        ].request();
        final granted =
            statuses.values.every((s) => s.isGranted || s.isLimited);
        if (!granted) return false;
      } catch (_) {
        return false;
      }

      try {
        await fbp.FlutterBluePlus.turnOn();
      } catch (_) {
        // user may decline; the adapter check below will surface that.
      }

      try {
        final state = await fbp.FlutterBluePlus.adapterState
            .where((s) => s == fbp.BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 4),
                onTimeout: () => fbp.BluetoothAdapterState.unknown);
        return state == fbp.BluetoothAdapterState.on;
      } catch (_) {
        return false;
      }
    }

    // iOS/macOS: permission prompts are raised by the system on first BLE
    // use (NSBluetoothAlwaysUsageDescription is in Info.plist).
    return true;
  }

  // -------------------------------------------------------------------------
  // Peripheral role — advertise + GATT server
  // -------------------------------------------------------------------------

  Future<void> _startPeripheral(int gen) async {
    _peripheralAvailable = false;
    try {
      final peripheral = _peripheral ??= ble.PeripheralManager();

      // Android needs its own runtime authorization path for the plugin.
      if (Platform.isAndroid) {
        try {
          await peripheral.authorize();
        } catch (_) {}
      }

      // Wait for the peripheral stack to power on (unavailable on iOS
      // simulators — we degrade to scan-only below).
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
      if (!_running || gen != _generation) return;

      _subs.add(peripheral.characteristicReadRequested
          .listen(_onCharacteristicRead, onError: (Object _) {}));
      _subs.add(peripheral.characteristicWriteRequested
          .listen(_onCharacteristicWrite, onError: (Object _) {}));

      await peripheral.removeAllServices();
      _gattService = _buildGattService();
      await peripheral.addService(_gattService!);
      await _advertise(peripheral);
      _peripheralAvailable = true;

      // Rotate the advertised EID every 15 minutes.
      _periodic(_eidRotation, gen, () {
        unawaited(_reAdvertise(peripheral));
      });

      // Sweep stale half-assembled writes.
      _periodic(const Duration(seconds: 5), gen, _sweepWriteBuffers);
    } catch (_) {
      // Peripheral role unavailable — keep the engine alive, scan-only.
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

  Uint8List _buildServiceData() {
    final data = Uint8List(11);
    // Bytes 0–7: rotating EID.
    var eidHex = '';
    try {
      eidHex = CryptoService.instance.currentEid();
    } catch (_) {
      // Keys not initialized (should not happen post-signup) — zero EID.
    }
    for (var i = 0; i < 8; i++) {
      data[i] = eidHex.length >= (i + 1) * 2
          ? int.parse(eidHex.substring(i * 2, i * 2 + 2), radix: 16)
          : 0;
    }
    // Byte 8: flags — bit0 discoverable, bit1 verified, bit2 pro.
    final card = _config?.myCard;
    data[8] = 0x01 |
        ((card?.verified ?? false) ? 0x02 : 0x00); // pro bit unset this phase
    // Byte 9: mood ring.
    data[9] = (_config?.mood ?? MoodRing.networking).wire;
    // Byte 10: calibrated TX power at 1 m (signed).
    data[10] = txPowerAt1m & 0xff;
    return data;
  }

  Future<void> _advertise(ble.PeripheralManager peripheral) async {
    final svc = ble.UUID.fromString(serviceUuid);
    try {
      await peripheral.startAdvertising(ble.Advertisement(
        serviceUUIDs: [svc],
        serviceData: {svc: _buildServiceData()},
      ));
    } catch (_) {
      // Service data in the advertisement is Android-only; iOS peers are
      // still discoverable by service UUID (EID/flags then arrive with the
      // profile card instead of the advertisement).
      await peripheral.startAdvertising(ble.Advertisement(
        name: 'MetAfter',
        serviceUUIDs: [svc],
      ));
    }
  }

  Future<void> _reAdvertise(ble.PeripheralManager peripheral) async {
    try {
      await peripheral.stopAdvertising();
    } catch (_) {}
    try {
      await _advertise(peripheral);
    } catch (_) {}
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
        final bytes =
            utf8.encode(_config?.myCard.encode() ?? '{}');
        final base = (_readChunkIndex[e.central.uuid.toString()] ?? 0) *
            _chunkSize;
        final start = math.min(base + e.request.offset, bytes.length);
        // Serve at most one fallback chunk per read; platform long reads
        // walk the value with increasing offsets from the same base.
        final end = math.min(start + _chunkSize, bytes.length);
        await peripheral.respondReadRequestWithValue(
          e.request,
          value: Uint8List.fromList(bytes.sublist(start, end)),
        );
      } catch (_) {}
    }());
  }

  void _onCharacteristicWrite(
      ble.GATTCharacteristicWriteRequestedEventArgs e) {
    final peripheral = _peripheral;
    if (peripheral == null) return;
    unawaited(() async {
      try {
        final charUuid = e.characteristic.uuid.toString().toUpperCase();
        final centralKey = e.central.uuid.toString();

        // ProfileCard chunk-index write (fallback chunked-read protocol).
        if (charUuid == profileCardUuid.toUpperCase()) {
          if (e.request.value.length == 1) {
            _readChunkIndex[centralKey] = e.request.value[0];
          }
          await peripheral.respondWriteRequest(e.request);
          return;
        }

        final key = '$centralKey:$charUuid';
        final buffer = _writeBuffers.putIfAbsent(key, _WriteBuffer.new);
        buffer.write(e.request.offset, e.request.value);
        await peripheral.respondWriteRequest(e.request);

        // A payload may arrive as one write or as several offset chunks —
        // try to parse after every write and emit once it goes valid.
        final json = buffer.tryParseJson();
        if (json != null) {
          _writeBuffers.remove(key);
          _dispatchInboundWrite(charUuid, json);
        }
      } catch (_) {}
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
    } catch (_) {
      // Scan failure leaves the engine running; the peripheral side may
      // still make us discoverable to others.
    }
  }

  void _onScanResults(int gen, List<fbp.ScanResult> results) {
    if (!_running || gen != _generation) return;
    final budget = _config?.maxMeters ?? 10.0;
    var changed = false;

    for (final r in results) {
      final parsed = _parseServiceData(r);
      if (parsed == null) continue;
      final (eid, flagsByte, moodByte, txPower) = parsed;
      // Only surface discoverable peers.
      if (flagsByte & 0x01 == 0) continue;

      final peer = _peers.putIfAbsent(
        eid,
        () => _BlePeer(eid: eid, device: r.device, card: _cardByEid[eid]),
      );
      peer.device = r.device;
      peer.rssi = r.rssi;
      peer.mood = MoodRingX.fromWire(moodByte);
      peer.verified = flagsByte & 0x02 != 0;
      peer.meters = peer.estimator.update(r.rssi, txPower);
      peer.lastSeen = DateTime.now();
      changed = true;

      if (peer.card == null &&
          !peer.cardReadInFlight &&
          peer.cardReadAttempts <= 1 && // initial try + one retry
          peer.meters <= budget) {
        _enqueueCardRead(eid, gen);
      }
    }

    if (changed) _emitNearby();
  }

  /// Parses `EID(8) ‖ flags ‖ mood ‖ txPower` out of the advertisement's
  /// service data. Returns null when our service data is absent/short.
  (String, int, int, int)? _parseServiceData(fbp.ScanResult r) {
    try {
      final data = r.advertisementData.serviceData[fbp.Guid(serviceUuid)];
      if (data == null || data.length < 11) return null;
      final eid = data
          .sublist(0, 8)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final tx = data[10] > 127 ? data[10] - 256 : data[10]; // int8
      return (eid, data[8], data[9], tx);
    } catch (_) {
      return null;
    }
  }

  void _sweepExpired() {
    final now = DateTime.now();
    final before = _peers.length;
    _peers.removeWhere((_, p) => now.difference(p.lastSeen) > _peerTtl);
    if (_peers.length != before) _emitNearby();
  }

  void _emitNearby() {
    if (_nearbyCtrl.isClosed) return;
    final budget = _config?.maxMeters ?? 10.0;
    final list = <NearbyPeer>[
      for (final p in _peers.values)
        if (p.meters <= budget)
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
        _cardReadsInFlight--;
        peer.cardReadInFlight = false;
        if (_running && gen == _generation) _pumpCardReads(gen);
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

      var bytes = <int>[...await chr.read()];
      var card = _tryDecodeCard(bytes);

      // Fallback chunked-read protocol: write chunk index, read, append.
      var chunk = 1;
      while (card == null && chunk <= 96) {
        await chr.write([chunk], withoutResponse: false);
        final part = await chr.read();
        if (part.isEmpty) break;
        bytes = [...bytes, ...part];
        card = _tryDecodeCard(bytes);
        chunk++;
      }

      if (card != null) {
        peer.card = card;
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

  Future<bool> _writeJsonTo(
      String peerSub, String charUuid, Map<String, dynamic> json) async {
    final eid = _subToEid[peerSub];
    final peer = eid == null ? null : _peers[eid];
    if (peer == null) return false;
    final bytes = utf8.encode(jsonEncode(json));

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final chr = await _connectAndFind(peer.device, charUuid);
        if (chr == null) continue;
        await chr.write(
          bytes,
          withoutResponse: false,
          allowLongWrite: bytes.length > 400,
        );
        return true;
      } catch (_) {
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
  MoodRing mood = MoodRing.networking;
  bool verified = false;
  DateTime lastSeen = DateTime.now();
  ProfileCard? card;
  bool cardReadInFlight = false;
  int cardReadAttempts = 0;
}

/// Accumulates (possibly chunked/offset) GATT writes until they parse as a
/// JSON object.
class _WriteBuffer {
  final List<int> _bytes = [];
  DateTime lastWrite = DateTime.now();

  void write(int offset, List<int> value) {
    lastWrite = DateTime.now();
    if (offset >= _bytes.length) {
      // Pad gaps defensively (shouldn't happen with well-behaved stacks).
      while (_bytes.length < offset) {
        _bytes.add(0);
      }
      _bytes.addAll(value);
    } else {
      // Overlapping rewrite — replace in place, extend as needed.
      for (var i = 0; i < value.length; i++) {
        final at = offset + i;
        if (at < _bytes.length) {
          _bytes[at] = value[i];
        } else {
          _bytes.add(value[i]);
        }
      }
    }
  }

  Map<String, dynamic>? tryParseJson() {
    try {
      final decoded = jsonDecode(utf8.decode(_bytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
