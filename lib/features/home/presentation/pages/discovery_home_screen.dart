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
  final Map<String, _NearbyPerson> _nearby = <String, _NearbyPerson>{};
  final _rng = math.Random(7);

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
          if (_nearby.length >= 6) continue; // cap avatars
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
        child: Column(
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
          ],
        ),
      ),
    );
  }
}

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

/// Local placeholder avatars (deterministic colors with initials).
const List<({String initials, Color color})> _fallbackAvatars = [
  (initials: 'AJ', color: Color(0xFFE3C8B5)),
  (initials: 'MR', color: Color(0xFFB7D9F2)),
  (initials: 'KP', color: Color(0xFFC9E5C4)),
  (initials: 'SS', color: Color(0xFFEBC4D6)),
  (initials: 'NV', color: Color(0xFFD9CFEB)),
  (initials: 'LR', color: Color(0xFFF3D9A4)),
];

/// Concentric rings + animated pulse waves + centre avatar + nearby avatars.
class _RadarArea extends StatefulWidget {
  const _RadarArea({
    required this.accent,
    required this.discoverable,
    required this.photoPath,
    required this.nearby,
    this.onPersonTap,
  });

  final Color accent;
  final bool discoverable;
  final String? photoPath;
  final List<_NearbyPerson> nearby;
  final void Function(_NearbyPerson)? onPersonTap;

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
      ],
    );
  }

  List<Widget> _buildNearby(
    BuildContext context,
    void Function(_NearbyPerson)? onPersonTap,
  ) {
    if (widget.nearby.isEmpty) return const [];
    final positions = _fixedPositions(widget.nearby.length);
    final widgets = <Widget>[];
    for (var i = 0; i < widget.nearby.length && i < positions.length; i++) {
      final person = widget.nearby[i];
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
