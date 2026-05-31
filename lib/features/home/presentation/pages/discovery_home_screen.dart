import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/config/environment_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../signup/data/signup_draft.dart';
import 'connect_screen.dart';
import 'discover_history_screen.dart';
import 'nearby_person_profile_screen.dart';
import 'profile_settings_screen.dart';

/// MetAfter discovery landing page.
///
/// Two visual states:
///  * **Idle** (red theme): "You are not discoverable". Tapping *Let's Go!*
///    requests Bluetooth permission, turns the adapter on if needed and
///    starts scanning for nearby BLE devices. Each device becomes a
///    "nearby person" avatar around the radar.
///  * **Active** (blue theme): scan running, countdown timer ticking,
///    nearby avatars shown around the centre photo.
class DiscoveryHomeScreen extends StatefulWidget {
  const DiscoveryHomeScreen({super.key});

  @override
  State<DiscoveryHomeScreen> createState() => _DiscoveryHomeScreenState();
}

class _DiscoveryHomeScreenState extends State<DiscoveryHomeScreen> {
  static const _sessionDurations = <String, Duration>{
    '1 hr': Duration(hours: 1),
    '2 hrs': Duration(hours: 2),
    '4 hrs': Duration(hours: 4),
    '8 hrs': Duration(hours: 8),
  };
  static const _distances = <String, double>{
    '1 mt': 1,
    '2 mts': 2,
    '5 mts': 5,
    '10 mts': 10,
  };

  bool _discoverable = false;
  bool _incognito = false; // false = public (visible to others); true = hidden
  bool _starting = false;
  String _durationLabel = '4 hrs';
  String _distanceLabel = '2 mts';

  Timer? _ticker;
  Duration _remaining = Duration.zero;

  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _mockTimer;
  Timer? _requestTimer;
  final Map<String, _NearbyPerson> _nearby = <String, _NearbyPerson>{};
  final _rng = math.Random(7);

  // Simulated incoming connection requests.
  final List<_IncomingRequest> _incomingRequests = [];
  int _requestIndex = 0;

  static const _mockRequestPool = <_IncomingRequest>[
    _IncomingRequest(
      id: 'req-001',
      name: 'Luna Ray',
      title: 'Head of Marketing',
      company: 'MarketVerse',
      photoUrl: 'https://i.pravatar.cc/150?img=47',
      avatarColor: Color(0xFFF3D9A4),
      initials: 'LR',
    ),
    _IncomingRequest(
      id: 'req-002',
      name: 'Marcus Reid',
      title: 'Lead Engineer',
      company: 'TechNova',
      photoUrl: 'https://i.pravatar.cc/150?img=11',
      avatarColor: Color(0xFFB7D9F2),
      initials: 'MR',
    ),
    _IncomingRequest(
      id: 'req-003',
      name: 'Koby Stone',
      title: 'SVP Engineering',
      company: 'InnoVision',
      photoUrl: 'https://i.pravatar.cc/150?img=12',
      avatarColor: Color(0xFFE3C8B5),
      initials: 'KS',
    ),
    _IncomingRequest(
      id: 'req-004',
      name: 'Nina Vo',
      title: 'Product Manager',
      company: 'GrowthLab',
      photoUrl: 'https://i.pravatar.cc/150?img=48',
      avatarColor: Color(0xFFD9CFEB),
      initials: 'NV',
    ),
    _IncomingRequest(
      id: 'req-005',
      name: 'Sam Shah',
      title: 'Founder',
      company: 'StartupXYZ',
      photoUrl: 'https://i.pravatar.cc/150?img=12',
      avatarColor: Color(0xFFEBC4D6),
      initials: 'SS',
    ),
  ];

  bool get _isMockMode =>
      EnvironmentConfig.isDev || EnvironmentConfig.isLocal;

  static const _mockDevices =
      <({String id, double meters, int avatarIndex})>[
    (id: 'mock-001', meters: 1.2, avatarIndex: 0),
    (id: 'mock-002', meters: 2.5, avatarIndex: 1),
    (id: 'mock-003', meters: 4.1, avatarIndex: 2),
    (id: 'mock-004', meters: 1.8, avatarIndex: 3),
    (id: 'mock-005', meters: 3.0, avatarIndex: 4),
    (id: 'mock-006', meters: 0.9, avatarIndex: 5),
    (id: 'mock-007', meters: 5.2, avatarIndex: 1),
    (id: 'mock-008', meters: 2.1, avatarIndex: 3),
    (id: 'mock-009', meters: 3.7, avatarIndex: 0),
  ];

  static const _mockProfiles = <int, NearbyPersonProfile>{
    0: NearbyPersonProfile(
      name: 'Luna Ray',
      title: 'VP, Sales',
      company: 'SaleSail',
      bio:
          'I am a brand sales person who focuses on clarity and emotional connections of clients',
      photoUrl: 'https://i.pravatar.cc/300?img=47',
      initials: 'AJ',
      avatarBg: Color(0xFFE3C8B5),
    ),
    1: NearbyPersonProfile(
      name: 'Marcus Reid',
      title: 'Lead Engineer',
      company: 'TechNova',
      bio:
          'Building products that matter. Passionate about clean architecture and great developer experience.',
      photoUrl: 'https://i.pravatar.cc/300?img=11',
      initials: 'MR',
      avatarBg: Color(0xFFB7D9F2),
    ),
    2: NearbyPersonProfile(
      name: 'Kira Patel',
      title: 'UX Designer',
      company: 'Designly',
      bio:
          'Crafting intuitive experiences that bridge the gap between humans and technology.',
      photoUrl: 'https://i.pravatar.cc/300?img=49',
      initials: 'KP',
      avatarBg: Color(0xFFC9E5C4),
    ),
    3: NearbyPersonProfile(
      name: 'Sam Shah',
      title: 'Founder',
      company: 'StartupXYZ',
      bio:
          'Serial entrepreneur on a mission to democratise access to financial tools.',
      photoUrl: 'https://i.pravatar.cc/300?img=12',
      initials: 'SS',
      avatarBg: Color(0xFFEBC4D6),
    ),
    4: NearbyPersonProfile(
      name: 'Nina Vo',
      title: 'Product Manager',
      company: 'GrowthLab',
      bio:
          'Turning customer insights into product strategy. Love hiking and cold brew coffee.',
      photoUrl: 'https://i.pravatar.cc/300?img=48',
      initials: 'NV',
      avatarBg: Color(0xFFD9CFEB),
    ),
    5: NearbyPersonProfile(
      name: 'Liam Ross',
      title: 'Data Scientist',
      company: 'Analytix',
      bio:
          'Turning data into stories. Machine learning enthusiast and part-time skateboarder.',
      photoUrl: 'https://i.pravatar.cc/300?img=15',
      initials: 'LR',
      avatarBg: Color(0xFFF3D9A4),
    ),
  };

  void _openNearbyList(BuildContext context, Color accent) {
    final sorted = _nearby.values.toList()
      ..sort((a, b) => a.meters.compareTo(b.meters));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NearbyListSheet(
        nearby: sorted,
        profiles: _mockProfiles,
        accent: accent,
        onPersonTap: (p) {
          Navigator.of(context).pop();
          _openProfile(context, p);
        },
      ),
    );
  }

  void _openProfile(BuildContext context, _NearbyPerson person) {
    final profile = _isMockMode
        ? _mockProfiles[person.avatarIndex] ??
            const NearbyPersonProfile(
              name: 'Unknown',
              title: '',
              company: '',
              bio: '',
              initials: '?',
            )
        : NearbyPersonProfile(
            name: person.id,
            title: '',
            company: '',
            bio: '',
            initials: person.id.isNotEmpty
                ? person.id.substring(0, 1).toUpperCase()
                : '?',
          );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NearbyPersonProfileScreen(profile: profile),
      ),
    );
  }

  void _startMockRequests() {
    _requestTimer?.cancel();
    _requestIndex = 0;
    // First request arrives after 5 s, then one every 7 s.
    _requestTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      if (_requestIndex >= _mockRequestPool.length) {
        _requestTimer?.cancel();
        return;
      }
      final req = _mockRequestPool[_requestIndex++];
      // Avoid duplicates.
      if (_incomingRequests.any((r) => r.id == req.id)) return;
      setState(() => _incomingRequests.add(req));
    });
    // Also fire the first one after 5 s.
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || !_discoverable) return;
      if (_requestIndex < _mockRequestPool.length) {
        final req = _mockRequestPool[_requestIndex++];
        if (!_incomingRequests.any((r) => r.id == req.id)) {
          setState(() => _incomingRequests.add(req));
        }
      }
    });
  }

  void _startMockScan() {
    var index = 0;
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || index >= _mockDevices.length) {
        _mockTimer?.cancel();
        return;
      }
      final device = _mockDevices[index++];
      final maxMeters = _distances[_distanceLabel] ?? 2.0;
      if (device.meters <= maxMeters * 4) {
        setState(() {
          _nearby[device.id] = _NearbyPerson(
            id: device.id,
            meters: device.meters,
            avatarIndex: device.avatarIndex,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scanSub?.cancel();
    _mockTimer?.cancel();
    _requestTimer?.cancel();
    if (_discoverable && !_isMockMode) {
      FlutterBluePlus.stopScan();
    }
    super.dispose();
  }

  Color get _accent =>
      _discoverable ? AppColors.discoverActive : AppColors.brandRed;

  Future<void> _startSession() async {
    if (_starting || _discoverable) return;
    setState(() => _starting = true);

    if (!_isMockMode) {
      final ok = await _ensureBluetoothReady();
      if (!mounted) return;
      if (!ok) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bluetooth permission denied. Please enable Bluetooth to '
              'discover people nearby.',
            ),
          ),
        );
        return;
      }
    }

    final total = _sessionDurations[_durationLabel] ?? const Duration(hours: 4);
    setState(() {
      _discoverable = true;
      _starting = false;
      _remaining = total;
      _nearby.clear();
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 1) {
        _endSession();
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });

    if (_isMockMode) {
      _startMockScan();
      _startMockRequests();
      return;
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      final maxMeters = _distances[_distanceLabel] ?? 2.0;
      var changed = false;
      for (final r in results) {
        final id = r.device.remoteId.str;
        final meters = _rssiToMeters(r.rssi);
        if (meters > maxMeters * 4) continue; // ignore obvious outliers
        final existing = _nearby[id];
        if (existing == null) {
          if (_nearby.length >= 10) continue; // cap avatars
          _nearby[id] = _NearbyPerson(
            id: id,
            meters: meters,
            avatarIndex: _rng.nextInt(_fallbackAvatars.length),
          );
          changed = true;
        } else if ((existing.meters - meters).abs() > 0.3) {
          existing.meters = meters;
          changed = true;
        }
      }
      if (changed) setState(() {});
    });

    try {
      // On iOS this call is what triggers the native Bluetooth
      // permission dialog (the first time around). On Android perms
      // were already requested in [_ensureBluetoothReady].
      await FlutterBluePlus.startScan(
        timeout: total,
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
      _endSession();
    }
  }

  Future<void> _endSession() async {
    _ticker?.cancel();
    _mockTimer?.cancel();
    _mockTimer = null;
    _requestTimer?.cancel();
    _requestTimer = null;
    _scanSub?.cancel();
    _scanSub = null;
    if (!_isMockMode) {
      try {
        await FlutterBluePlus.stopScan();
      } on Exception {
        // ignore
      }
    }
    if (!mounted) return;
    setState(() {
      _discoverable = false;
      _remaining = Duration.zero;
      _nearby.clear();
      _incomingRequests.clear();
      _requestIndex = 0;
    });
  }

  Future<bool> _ensureBluetoothReady() async {
    try {
      if (!await FlutterBluePlus.isSupported) return false;
    } on Exception {
      // isSupported can throw on iOS Simulator etc. — just continue and
      // let startScan surface the real error.
    }

    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      final granted = statuses.values.every((s) => s.isGranted || s.isLimited);
      if (!granted) return false;

      // Best-effort — ask the OS to turn the radio on if it's off.
      try {
        await FlutterBluePlus.turnOn();
      } on Exception {
        // user may decline; scan will surface that.
      }

      // Wait up to 4s for the adapter to come ON.
      final state = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 4),
              onTimeout: () => BluetoothAdapterState.unknown);
      return state == BluetoothAdapterState.on;
    }

    // iOS: do NOT pre-request `Permission.bluetooth` — it returns
    // `.denied` until the user actually interacts with the native
    // prompt, which iOS only shows once we touch a CoreBluetooth API
    // (i.e. when we call startScan). Just proceed and let startScan
    // trigger the dialog.
    return true;
  }

  /// Very rough RSSI -> meters conversion (path-loss exponent 2.0,
  /// measured power -69 dBm at 1m).
  double _rssiToMeters(int rssi) {
    const measuredPower = -69;
    final ratio = (measuredPower - rssi) / (10 * 2.0);
    return math.pow(10, ratio).toDouble().clamp(0.1, 50);
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final photo = SignupDraft.instance.photoPath;
    final hasPhoto = (photo ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.history_rounded, color: accent),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiscoverHistoryScreen(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'MetAfter',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  _IncognitoSwitch(
                    value: _incognito,
                    accent: accent,
                    onChanged: (v) {
                      setState(() => _incognito = v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            v
                                ? 'Incognito on — you can discover others, but they can\'t see you'
                                : 'Public — you are visible to people nearby',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline_rounded,
                        color: accent),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ConnectScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Radar area ----
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Center(
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: _RadarArea(
                        accent: accent,
                        discoverable: _discoverable,
                        photoPath: hasPhoto ? photo : null,
                        nearby: _nearby.values.toList(growable: false),
                        onPersonTap: (p) => _openProfile(context, p),
                        onViewAll: () => _openNearbyList(context, accent),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ---- Status + CTA ----
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                children: [
                  Text(
                    !_discoverable
                        ? 'You are not discoverable'
                        : (_incognito
                            ? 'You are in incognito mode'
                            : 'You are discoverable'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !_discoverable
                        ? 'Tap to connect with people nearby'
                        : (_incognito
                            ? 'Time Remaining: ${_format(_remaining)}  ·  Hidden from others'
                            : 'Time Remaining: ${_format(_remaining)}'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        disabledBackgroundColor:
                            accent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _starting
                          ? null
                          : (_discoverable ? _endSession : _startSession),
                      child: Text(
                        _starting
                            ? 'Starting…'
                            : (_discoverable ? 'End Session' : "Let's Go!"),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // ---- Settings rows ----
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  _SettingRow(
                    label: 'Discoverable for the next',
                    value: _durationLabel,
                    options: _sessionDurations.keys.toList(),
                    accent: accent,
                    enabled: !_discoverable,
                    onChanged: (v) => setState(() => _durationLabel = v),
                  ),
                  const SizedBox(height: 12),
                  _SettingRow(
                    label: 'Set Distance',
                    value: _distanceLabel,
                    options: _distances.keys.toList(),
                    accent: accent,
                    enabled: !_discoverable,
                    onChanged: (v) => setState(() => _distanceLabel = v),
                  ),
                ],
              ),
            ),
          ], // Column children
        ), // Column

            // ---- Pull-up incoming requests bar ----
            if (_discoverable && _incomingRequests.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _PullUpBar(
                  count: _incomingRequests.length,
                  accent: accent,
                  onTap: () => _openIncomingRequests(context, accent),
                ),
              ),
          ], // Stack children
        ), // Stack
      ),
    );
  }

  void _openIncomingRequests(BuildContext context, Color accent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomingRequestsSheet(
        requests: List.unmodifiable(_incomingRequests),
        accent: accent,
        onAccept: (req) => setState(() => _incomingRequests.remove(req)),
        onDecline: (req) => setState(() => _incomingRequests.remove(req)),
      ),
    );
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

/// One discovered nearby person.
class _NearbyPerson {
  _NearbyPerson({
    required this.id,
    required this.meters,
    required this.avatarIndex,
  });

  final String id;
  double meters;
  final int avatarIndex;
}

/// An incoming connection request from another user.
class _IncomingRequest {
  const _IncomingRequest({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.photoUrl,
    required this.avatarColor,
    required this.initials,
  });

  final String id;
  final String name;
  final String title;
  final String company;
  final String photoUrl;
  final Color avatarColor;
  final String initials;
}

// ─── Pull-up requests indicator ───────────────────────────────────────────────

/// Floating bar at the bottom that pulses with the Lottie arrow animation
/// when there are pending incoming connection requests.
class _PullUpBar extends StatelessWidget {
  const _PullUpBar({
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Lottie "swipe up" arrows, tinted white via ColorFiltered.
            SizedBox(
              width: 36,
              height: 36,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                    Colors.white, BlendMode.srcIn),
                child: Lottie.asset(
                  'assets/animation/pull-up.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count incoming connection${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Tap to review',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Incoming requests bottom sheet ──────────────────────────────────────────

class _IncomingRequestsSheet extends StatefulWidget {
  const _IncomingRequestsSheet({
    required this.requests,
    required this.accent,
    required this.onAccept,
    required this.onDecline,
  });

  final List<_IncomingRequest> requests;
  final Color accent;
  final void Function(_IncomingRequest) onAccept;
  final void Function(_IncomingRequest) onDecline;

  @override
  State<_IncomingRequestsSheet> createState() =>
      _IncomingRequestsSheetState();
}

class _IncomingRequestsSheetState extends State<_IncomingRequestsSheet> {
  late final List<_IncomingRequest> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.requests);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle.
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Connection Requests (${_items.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 56,
                            color: widget.accent.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('All caught up!',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B6B6B))),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 84,
                        endIndent: 20,
                        color: Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) {
                      final req = _items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar.
                            ClipOval(
                              child: Image.network(
                                req.photoUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: req.avatarColor,
                                  child: Center(
                                    child: Text(req.initials,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name + title.
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req.name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black)),
                                  Text(
                                      '${req.title}  ·  ${req.company}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B6B6B))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Decline.
                            GestureDetector(
                              onTap: () {
                                widget.onDecline(req);
                                setState(() => _items.remove(req));
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFDDDDDD),
                                      width: 1.5),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF8A8A8A)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Accept.
                            GestureDetector(
                              onTap: () {
                                widget.onAccept(req);
                                setState(() => _items.remove(req));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    content: Text(
                                        'Connected with ${req.name}!'),
                                    backgroundColor: widget.accent,
                                  ),
                                );
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.accent,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Legacy placeholder removed — pulse is now Lottie ─────────────────────

/// Local placeholder avatars (deterministic colors with initials).
const List<({String initials, Color color})> _fallbackAvatars = [
  (initials: 'AJ', color: Color(0xFFE3C8B5)),
  (initials: 'MR', color: Color(0xFFB7D9F2)),
  (initials: 'KP', color: Color(0xFFC9E5C4)),
  (initials: 'SS', color: Color(0xFFEBC4D6)),
  (initials: 'NV', color: Color(0xFFD9CFEB)),
  (initials: 'LR', color: Color(0xFFF3D9A4)),
];

/// Max avatars shown on the radar before the "+N more" overflow badge kicks in.
const int _kMaxRadarAvatars = 5;

/// Concentric rings + animated ripple + centre avatar + nearby avatars.
class _RadarArea extends StatefulWidget {
  const _RadarArea({
    required this.accent,
    required this.discoverable,
    required this.photoPath,
    required this.nearby,
    this.onPersonTap,
    this.onViewAll,
  });

  final Color accent;
  final bool discoverable;
  final String? photoPath;
  final List<_NearbyPerson> nearby;
  final void Function(_NearbyPerson)? onPersonTap;
  /// Called when the user taps the "+N" overflow badge or the "View all" chip.
  final VoidCallback? onViewAll;

  @override
  State<_RadarArea> createState() => _RadarAreaState();
}

class _RadarAreaState extends State<_RadarArea> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Static background rings.
        CustomPaint(
          size: Size.infinite,
          painter: _RingsPainter(accent: widget.accent),
        ),

        // Animated ripple waves emanating from the centre, tinted to
        // the current accent (red while idle, blue while active).
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              widget.accent.withValues(alpha: 0.55),
              BlendMode.srcIn,
            ),
            child: Lottie.asset(
              'assets/animation/inward-ripple.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
        ),

        // Centre avatar.
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ProfileSettingsScreen(),
            ),
          ),
          child: _CenterAvatar(
              accent: widget.accent, photoPath: widget.photoPath),
        ),

        // Nearby avatars (only when discoverable).
        if (widget.discoverable) ..._buildNearby(context, widget.onPersonTap),

        // "View all N" chip — visible whenever there are more people than fit.
        if (widget.discoverable && widget.nearby.length > _kMaxRadarAvatars)
          Positioned(
            bottom: 8,
            child: GestureDetector(
              onTap: widget.onViewAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'View all ${widget.nearby.length} nearby',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildNearby(
    BuildContext context,
    void Function(_NearbyPerson)? onPersonTap,
  ) {
    if (widget.nearby.isEmpty) return const [];

    // Sort by proximity so the closest people are shown first on the radar.
    final sorted = [...widget.nearby]
      ..sort((a, b) => a.meters.compareTo(b.meters));

    final overflow = sorted.length - _kMaxRadarAvatars;
    final visible = sorted.take(_kMaxRadarAvatars).toList();
    // One extra slot for the "+N" badge when there are more people.
    final slotCount = overflow > 0 ? visible.length + 1 : visible.length;
    final positions = _fixedPositions(slotCount);
    final widgets = <Widget>[];

    for (var i = 0; i < visible.length && i < positions.length; i++) {
      final person = visible[i];
      final pos = positions[i];
      final avatar = _fallbackAvatars[
          person.avatarIndex.clamp(0, _fallbackAvatars.length - 1)];
      widgets.add(
        Align(
          alignment: pos,
          child: _NearbyAvatar(
            accent: widget.accent,
            initials: avatar.initials,
            bg: avatar.color,
            meters: person.meters,
            onTap: onPersonTap != null ? () => onPersonTap(person) : null,
          ),
        ),
      );
    }

    // "+N" overflow badge in the last slot.
    if (overflow > 0 && positions.length > visible.length) {
      widgets.add(
        Align(
          alignment: positions[visible.length],
          child: _OverflowBadge(
            count: overflow,
            accent: widget.accent,
            onTap: widget.onViewAll,
          ),
        ),
      );
    }

    return widgets;
  }

  /// Hand-picked alignment positions matching the design (4 corner-ish
  /// avatars and 2 above/below if needed).
  List<Alignment> _fixedPositions(int n) {
    const all = <Alignment>[
      Alignment(-0.85, -0.45), // upper-left
      Alignment(0.85, -0.65),  // upper-right
      Alignment(-0.85, 0.25),  // lower-left
      Alignment(0.85, 0.30),   // lower-right
      Alignment(0, -0.85),     // top
      Alignment(0, 0.75),      // bottom
    ];
    return all.take(n).toList();
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    const ringCount = 8;
    for (var i = ringCount; i >= 1; i--) {
      final r = maxR * (i / ringCount);
      final opacity = 0.05 + (ringCount - i) * 0.025;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = accent.withValues(alpha: opacity.clamp(0.04, 0.35));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

/// Animated pulse waves expanding outward from the centre — gives the
/// radar a "breathing" effect in both red (idle) and blue (active) modes.
// (Replaced by `Lottie.asset('assets/animation/ripple.json')` in `_RadarArea`.)

class _CenterAvatar extends StatelessWidget {
  const _CenterAvatar({required this.accent, required this.photoPath});
  final Color accent;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 4),
            color: Colors.white,
          ),
          child: ClipOval(
            child: photoPath != null
                ? Image.file(File(photoPath!), fit: BoxFit.cover)
                : Center(
                    child: Icon(Icons.person, size: 56, color: accent),
                  ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 2, bottom: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.discoverActive,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.settings, size: 14, color: Colors.white),
        ),
      ],
    );
  }
}

class _NearbyAvatar extends StatelessWidget {
  const _NearbyAvatar({
    required this.accent,
    required this.initials,
    required this.bg,
    required this.meters,
    this.onTap,
  });

  final Color accent;
  final String initials;
  final Color bg;
  final double meters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: accent, width: 3),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _formatMeters(meters),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    ),
    );
  }

  String _formatMeters(double m) {
    if (m < 1) return '${m.toStringAsFixed(1)} mtr';
    return '${m.toStringAsFixed(m < 10 ? 1 : 0)} mtr';
  }
}

/// "+N" circle shown in the last radar slot when more people are nearby.
class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({
    required this.count,
    required this.accent,
    this.onTap,
  });

  final int count;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.15),
              border: Border.all(color: accent, width: 2.5),
            ),
            child: Center(
              child: Text(
                '+$count',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'more',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nearby list bottom sheet ──────────────────────────────────────────────

class _NearbyListSheet extends StatelessWidget {
  const _NearbyListSheet({
    required this.nearby,
    required this.profiles,
    required this.accent,
    required this.onPersonTap,
  });

  final List<_NearbyPerson> nearby;
  final Map<int, NearbyPersonProfile> profiles;
  final Color accent;
  final void Function(_NearbyPerson) onPersonTap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar.
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nearby People (${nearby.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List.
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: nearby.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 84,
                    endIndent: 20,
                    color: Color(0xFFF0F0F0),
                  ),
                  itemBuilder: (_, i) {
                    final person = nearby[i];
                    final avatar = _fallbackAvatars[
                        person.avatarIndex.clamp(
                            0, _fallbackAvatars.length - 1)];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avatar.color,
                          border: Border.all(color: accent, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            avatar.initials,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        profiles[person.avatarIndex]?.name ?? avatar.initials,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        profiles[person.avatarIndex] != null
                            ? '${profiles[person.avatarIndex]!.title}  ·  ${profiles[person.avatarIndex]!.company}'
                            : '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _fmt(person.meters),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      onTap: () => onPersonTap(person),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double m) =>
      m < 1 ? '${m.toStringAsFixed(1)} m' : '${m.toStringAsFixed(1)} m';
}

class _IncognitoSwitch extends StatelessWidget {
  const _IncognitoSwitch({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  /// `true` = incognito (hidden from others), `false` = public (visible).
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Incognito state uses a soft-rose pill; public uses the accent tint.
    final trackColor = value
        ? const Color(0xFFEAD0CB)
        : accent.withValues(alpha: 0.20);
    final knobColor =
        value ? AppColors.brandRed : accent;
    return Semantics(
      label: value ? 'Incognito mode on' : 'Public mode on',
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 58,
          height: 30,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Align(
            alignment:
                value ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                value
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 16,
                color: knobColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.options,
    required this.accent,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final Color accent;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        if (enabled)
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              isDense: true,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accent,
                decoration: TextDecoration.underline,
                decorationColor: accent,
              ),
              items: options
                  .map((o) => DropdownMenuItem(
                        value: o,
                        child: Text(o),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          )
        else
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  decoration: TextDecoration.underline,
                  decorationColor: accent,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 16, color: accent),
            ],
          ),
      ],
    );
  }
}
