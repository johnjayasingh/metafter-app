import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../signup/data/signup_draft.dart';

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
  bool _starting = false;
  String _durationLabel = '4 hrs';
  String _distanceLabel = '2 mts';

  Timer? _ticker;
  Duration _remaining = Duration.zero;

  StreamSubscription<List<ScanResult>>? _scanSub;
  final Map<String, _NearbyPerson> _nearby = <String, _NearbyPerson>{};
  final _rng = math.Random(7);

  @override
  void dispose() {
    _ticker?.cancel();
    _scanSub?.cancel();
    if (_discoverable) {
      FlutterBluePlus.stopScan();
    }
    super.dispose();
  }

  Color get _accent =>
      _discoverable ? AppColors.discoverActive : AppColors.brandRed;

  Future<void> _startSession() async {
    if (_starting || _discoverable) return;
    setState(() => _starting = true);

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
    _scanSub?.cancel();
    _scanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } on Exception {
      // ignore
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
                    onPressed: () {},
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
                    value: !_discoverable,
                    accent: accent,
                    onChanged: (v) {
                      if (_discoverable) {
                        _endSession();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline_rounded,
                        color: accent),
                    onPressed: () {},
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
                    _discoverable
                        ? 'You are discoverable'
                        : 'You are not discoverable',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _discoverable
                        ? 'Time Remaining: ${_format(_remaining)}'
                        : 'Tap to connect with people nearby',
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
  });

  final Color accent;
  final bool discoverable;
  final String? photoPath;
  final List<_NearbyPerson> nearby;

  @override
  State<_RadarArea> createState() => _RadarAreaState();
}

class _RadarAreaState extends State<_RadarArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

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

        // Animated pulse waves emanating from the centre avatar.
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _PulsePainter(
                accent: widget.accent,
                progress: _pulse.value,
              ),
            );
          },
        ),

        // Centre avatar.
        _CenterAvatar(accent: widget.accent, photoPath: widget.photoPath),

        // Nearby avatars (only when discoverable).
        if (widget.discoverable) ..._buildNearby(context),
      ],
    );
  }

  List<Widget> _buildNearby(BuildContext context) {
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
class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.accent, required this.progress});

  final Color accent;
  /// 0..1 looping progress driving the wave expansion.
  final double progress;

  /// How many concurrent pulse waves to draw, staggered evenly.
  static const int _waveCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    // Start each wave just outside the centre avatar (~55px radius).
    const minR = 55.0;

    for (var i = 0; i < _waveCount; i++) {
      // Stagger this wave's progress so they don't overlap exactly.
      final t = (progress + i / _waveCount) % 1.0;
      final r = minR + (maxR - minR) * t;
      // Fade out as the wave expands; also fade in at the very start.
      final fadeIn = (t * 4).clamp(0.0, 1.0);
      final fadeOut = 1.0 - t;
      final alpha = (fadeIn * fadeOut * 0.55).clamp(0.0, 0.55);

      // Stroke outline ring.
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = accent.withValues(alpha: alpha),
      );
      // Soft inner fill for the wave-front glow.
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.fill
          ..color = accent.withValues(alpha: alpha * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

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
  });

  final Color accent;
  final String initials;
  final Color bg;
  final double meters;

  @override
  Widget build(BuildContext context) {
    return Column(
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

  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 56,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE5C6B8) : accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFF8B6B5B) : accent,
            ),
            child: Icon(
              value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 14,
              color: Colors.white,
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
