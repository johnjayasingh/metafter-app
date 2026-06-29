import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/config/environment_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/metafter_logo.dart';
import '../../../signup/data/signup_draft.dart';
import 'all_messages_screen.dart';
import 'connected_profile_screen.dart';
import 'discover_history_screen.dart';
import 'profile_settings_screen.dart';

/// Swipeable host for the three primary tabs — Discover · Home/Meet · Messages —
/// shown as a peeking card carousel under a shared header.
///
/// The middle tab is the discovery control panel. Idle it reads **Home**
/// (dark→red); once a session starts it becomes an immersive **Meet** radar
/// (dark→green) showing the people nearby.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  static const _homeIndex = 1;

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

  // Mock nearby people shown on the radar in dev/local builds.
  static const _mockNearby = <_NearbyPerson>[
    _NearbyPerson(id: 'n1', meters: 1.0, photoUrl: 'https://i.pravatar.cc/150?img=14', name: 'Owen Hill'),
    _NearbyPerson(id: 'n2', meters: 2.0, photoUrl: 'https://i.pravatar.cc/150?img=44', name: 'Jasmine Lee'),
    _NearbyPerson(id: 'n3', meters: 0.7, photoUrl: 'https://i.pravatar.cc/150?img=13', name: 'Marcus Reid'),
    _NearbyPerson(id: 'n4', meters: 0.5, photoUrl: 'https://i.pravatar.cc/150?img=49', name: 'Kira Patel'),
  ];

  /// Continuous carousel position — 0 = Discover, 1 = Home, 2 = Messages.
  final ValueNotifier<double> _pagePos =
      ValueNotifier<double>(_homeIndex.toDouble());
  late final AnimationController _pageAnim;
  int _page = _homeIndex;

  bool _discoverable = false;
  bool _incognito = false;
  bool _starting = false;
  String _durationLabel = '4 hrs';
  String _distanceLabel = '2 mts';

  Timer? _ticker;
  Duration _remaining = Duration.zero;

  StreamSubscription<List<ScanResult>>? _scanSub;
  final Map<String, _NearbyPerson> _nearby = <String, _NearbyPerson>{};
  final _rng = math.Random(7);

  final List<_ConnReq> _requests = List.of(_seedRequests);

  bool get _isMockMode =>
      EnvironmentConfig.isDev || EnvironmentConfig.isLocal;

  bool get _immersive => _page == _homeIndex && _discoverable;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scanSub?.cancel();
    if (_discoverable && !_isMockMode) {
      FlutterBluePlus.stopScan();
    }
    _pageAnim.dispose();
    _pagePos.dispose();
    super.dispose();
  }

  /// Animates the carousel to [target] (0..2) and updates the settled page.
  void _goToPage(int target) {
    final t = target.clamp(0, 2).toDouble();
    final anim = Tween<double>(begin: _pagePos.value, end: t).animate(
      CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic),
    );
    void listener() => _pagePos.value = anim.value;
    anim.addListener(listener);
    _pageAnim
      ..stop()
      ..reset();
    _pageAnim.forward().whenComplete(() {
      anim.removeListener(listener);
      if (mounted && _page != t.round()) setState(() => _page = t.round());
    });
  }

  void _setIncognito(bool v) {
    setState(() => _incognito = v);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          v
              ? "Incognito on — you can discover others, but they can't see you"
              : 'Public — you are visible to people nearby',
        ),
      ),
    );
  }

  void _accept(_ConnReq r) {
    setState(() => _requests.remove(r));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.brandRed,
        content: Text('Connected with ${r.name}!'),
      ),
    );
  }

  void _decline(_ConnReq r) => setState(() => _requests.remove(r));

  /// Opens the connection-request sheet as a modal. Only reachable when there
  /// are pending requests (the pull-up indicator drives it).
  void _openConnectSheet(BuildContext context) {
    if (_requests.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x40000000),
      builder: (_) => _ConnectSheetModal(
        requests: _requests,
        onAccept: _accept,
        onDecline: _decline,
      ),
    );
  }

  void _openProfile(_NearbyPerson p) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ConnectedProfileScreen(
        name: p.name,
        title: '',
        company: '',
        bio: '',
        photoUrl: p.photoUrl,
      ),
    ));
  }

  // ── Discovery session ──
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
      if (_isMockMode) {
        for (final p in _mockNearby) {
          _nearby[p.id] = p;
        }
      }
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

    if (_isMockMode) return;

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      final maxMeters = _distances[_distanceLabel] ?? 2.0;
      var changed = false;
      for (final r in results) {
        final id = r.device.remoteId.str;
        final meters = _rssiToMeters(r.rssi);
        if (meters > maxMeters * 4) continue;
        if (!_nearby.containsKey(id)) {
          if (_nearby.length >= 6) continue;
          _nearby[id] = _NearbyPerson(
            id: id,
            meters: meters,
            photoUrl: 'https://i.pravatar.cc/150?img=${12 + _rng.nextInt(40)}',
            name: 'Nearby',
          );
          changed = true;
        }
      }
      if (changed) setState(() {});
    });

    try {
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
      // isSupported can throw on the iOS Simulator — continue.
    }

    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      final granted = statuses.values.every((s) => s.isGranted || s.isLimited);
      if (!granted) return false;

      try {
        await FlutterBluePlus.turnOn();
      } on Exception {
        // user may decline; scan will surface that.
      }

      final state = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 4),
              onTimeout: () => BluetoothAdapterState.unknown);
      return state == BluetoothAdapterState.on;
    }

    return true;
  }

  double _rssiToMeters(int rssi) {
    const measuredPower = -69;
    final ratio = (measuredPower - rssi) / (10 * 2.0);
    return math.pow(10, ratio).toDouble().clamp(0.1, 50);
  }

  @override
  Widget build(BuildContext context) {
    final photo = SignupDraft.instance.photoPath;
    final hasPhoto = (photo ?? '').isNotEmpty;
    final immersive = _immersive;

    return Scaffold(
      backgroundColor: immersive ? Colors.black : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SharedHeader(
              page: _page,
              immersive: immersive,
              incognito: _incognito,
              onIncognito: _setIncognito,
              onPrev: () => _goToPage(_page - 1),
              onNext: () => _goToPage(_page + 1),
            ),
            _PageTitleStrip(
              position: _pagePos,
              titles: ['Discover', _discoverable ? 'Meet' : 'Home', 'Messages'],
              immersive: immersive,
            ),
            Expanded(
              child: _PeekCarousel(
                position: _pagePos,
                onDragStart: () => _pageAnim.stop(),
                onSnap: _goToPage,
                home: _DiscoverCard(
                  photoPath: hasPhoto ? photo : null,
                  discoverable: _discoverable,
                  incognito: _incognito,
                  starting: _starting,
                  remaining: _remaining,
                  durationLabel: _durationLabel,
                  distanceLabel: _distanceLabel,
                  durations: _sessionDurations.keys.toList(),
                  distances: _distances.keys.toList(),
                  nearby: _nearby.values.toList(growable: false),
                  hasRequests: _requests.isNotEmpty,
                  onStart: _startSession,
                  onEnd: _endSession,
                  onDurationChanged: (v) =>
                      setState(() => _durationLabel = v),
                  onDistanceChanged: (v) =>
                      setState(() => _distanceLabel = v),
                  onGear: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileSettingsScreen(),
                    ),
                  ),
                  onPersonTap: _openProfile,
                  onOpenSheet: () => _openConnectSheet(context),
                ),
                discover: const DiscoverHistoryScreen(embedded: true),
                messages: const AllMessagesScreen(
                  embedded: true,
                  messages: kSampleMessages,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Peek carousel ───────────────────────────────────────────────────────────

/// A three-page carousel where **Home** is a full-screen hub. Swiping slides
/// the Discover (left) / Messages (right) panels over it — each filling ~80%
/// of the width — leaving ~20% of Home peeking on the far edge.
class _PeekCarousel extends StatefulWidget {
  const _PeekCarousel({
    required this.position,
    required this.home,
    required this.discover,
    required this.messages,
    required this.onDragStart,
    required this.onSnap,
  });

  final ValueNotifier<double> position; // 0 = Discover, 1 = Home, 2 = Messages
  final Widget home;
  final Widget discover;
  final Widget messages;
  final VoidCallback onDragStart;
  final ValueChanged<int> onSnap;

  @override
  State<_PeekCarousel> createState() => _PeekCarouselState();
}

class _PeekCarouselState extends State<_PeekCarousel> {
  /// Fraction of Home left peeking when a side panel is fully open.
  static const double _peek = 0.2;

  double _startPos = 1;
  double _startDx = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final panelW = w * (1 - _peek); // 80%
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            widget.onDragStart();
            _startPos = widget.position.value;
            _startDx = d.globalPosition.dx;
          },
          onHorizontalDragUpdate: (d) {
            final dx = d.globalPosition.dx - _startDx;
            widget.position.value = (_startPos - dx / w).clamp(0.0, 2.0);
          },
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            final p = widget.position.value;
            final target = v < -350
                ? p.ceil()
                : (v > 350 ? p.floor() : p.round());
            widget.onSnap(target.clamp(0, 2));
          },
          child: ValueListenableBuilder<double>(
            valueListenable: widget.position,
            builder: (context, p, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Home hub — full-width base, recedes slightly off-centre.
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1.0 - 0.04 * (p - 1).abs().clamp(0.0, 1.0),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        child: widget.home,
                      ),
                    ),
                  ),
                  // Discover slides over from the left.
                  if (p < 1.0)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: -panelW * p,
                      width: panelW,
                      child: _panel(widget.discover, roundRight: true),
                    ),
                  // Messages slides over from the right.
                  if (p > 1.0)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: w - panelW * (p - 1),
                      width: panelW,
                      child: _panel(widget.messages, roundRight: false),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _panel(Widget child, {required bool roundRight}) {
    final radius = roundRight
        ? const BorderRadius.horizontal(right: Radius.circular(28))
        : const BorderRadius.horizontal(left: Radius.circular(28));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 22,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

// ─── Shared header ───────────────────────────────────────────────────────────

class _SharedHeader extends StatelessWidget {
  const _SharedHeader({
    required this.page,
    required this.immersive,
    required this.incognito,
    required this.onIncognito,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final bool immersive;
  final bool incognito;
  final ValueChanged<bool> onIncognito;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
      child: Row(
        children: [
          _ArrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: page > 0,
            onTap: onPrev,
          ),
          const Expanded(
            child: Center(
              child: MetafterLogo(
                form: MetafterLogoForm.wordmark,
                variant: MetafterLogoVariant.red,
                height: 18,
              ),
            ),
          ),
          _IncognitoSwitch(
            value: incognito,
            immersive: immersive,
            onChanged: onIncognito,
          ),
          const SizedBox(width: 4),
          _ArrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: page < 2,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      iconSize: 18,
      icon: Icon(
        icon,
        color: enabled ? AppColors.brandRed : const Color(0xFFEBB9BB),
      ),
    );
  }
}

/// Big animated "Discover · Home/Meet · Messages" indicator that peeks the
/// neighbouring tab titles and tracks the carousel position.
class _PageTitleStrip extends StatelessWidget {
  const _PageTitleStrip({
    required this.position,
    required this.titles,
    required this.immersive,
  });

  final ValueListenable<double> position;
  final List<String> titles;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ValueListenableBuilder<double>(
        valueListenable: position,
        builder: (context, page, _) {
          return LayoutBuilder(
            builder: (context, c) {
              final spacing = c.maxWidth * 0.46;
              return ClipRect(
                child: Stack(
                  children: [
                    for (var i = 0; i < titles.length; i++)
                      _buildTitle(i, page, spacing),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTitle(int i, double page, double spacing) {
    final dist = (i - page).abs().clamp(0.0, 1.0);
    // Active title contrasts with the surface; neighbours fade to grey.
    final active = immersive ? Colors.white : Colors.black;
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset((i - page) * spacing, 0),
        child: Center(
          child: Opacity(
            opacity: (1.0 - 0.5 * dist).clamp(0.0, 1.0),
            child: Text(
              titles[i],
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 32.0 - 9.0 * dist,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Color.lerp(active, const Color(0xFF8A9096), dist),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Home / Meet card ────────────────────────────────────────────────────────

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.photoPath,
    required this.discoverable,
    required this.incognito,
    required this.starting,
    required this.remaining,
    required this.durationLabel,
    required this.distanceLabel,
    required this.durations,
    required this.distances,
    required this.nearby,
    required this.hasRequests,
    required this.onStart,
    required this.onEnd,
    required this.onDurationChanged,
    required this.onDistanceChanged,
    required this.onGear,
    required this.onPersonTap,
    required this.onOpenSheet,
  });

  final String? photoPath;
  final bool discoverable;
  final bool incognito;
  final bool starting;
  final Duration remaining;
  final String durationLabel;
  final String distanceLabel;
  final List<String> durations;
  final List<String> distances;
  final List<_NearbyPerson> nearby;
  final bool hasRequests;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<String> onDistanceChanged;
  final VoidCallback onGear;
  final void Function(_NearbyPerson) onPersonTap;
  final VoidCallback onOpenSheet;

  static const _idleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.42, 1.0],
    colors: [Colors.black, Color(0xFF5E0F13), AppColors.brandRed],
  );
  static const _meetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 1.0],
    colors: [Colors.black, Color(0xFF0E3B21), Color(0xFF3BA55C)],
  );

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: discoverable ? _meetGradient : _idleGradient,
      ),
      child: discoverable ? _buildActive(context) : _buildIdle(context),
    );
  }

  Widget _buildIdle(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        _CenterAvatar(photoPath: photoPath, onGear: onGear),
        const SizedBox(height: 26),
        const Text(
          'You are not discoverable',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap to connect with people nearby',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFFE7D2D3)),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _LetsGoButton(
            label: starting ? 'Starting…' : "Let's Go!",
            onPressed: starting ? null : onStart,
          ),
        ),
        const SizedBox(height: 34),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _DarkSettingRow(
            label: 'Discoverable for the next',
            value: durationLabel,
            options: durations,
            onChanged: onDurationChanged,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _DarkSettingRow(
            label: 'Set Distance',
            value: distanceLabel,
            options: distances,
            onChanged: onDistanceChanged,
          ),
        ),
        const Spacer(),
        _PullUpIndicator(active: hasRequests, onOpen: onOpenSheet),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildActive(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _MeetRadar(
            photoPath: photoPath,
            nearby: nearby,
            onGear: onGear,
            onPersonTap: onPersonTap,
          ),
        ),
        Text(
          incognito ? 'You are in incognito mode' : 'You are discoverable',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'Time Remaining: ${_format(remaining)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Color(0xFFD7ECDC)),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _LetsGoButton(label: 'End Session', onPressed: onEnd),
        ),
        const SizedBox(height: 12),
        _PullUpIndicator(active: hasRequests, onOpen: onOpenSheet),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 14),
      ],
    );
  }
}

/// White CTA with red label used on the dark card.
class _LetsGoButton extends StatelessWidget {
  const _LetsGoButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.brandRed,
          ),
        ),
      ),
    );
  }
}

/// Pull-up affordance for the connection-request sheet.
///
/// When [active] (a request is pending) the chevron animation plays and a
/// tap / swipe-up opens the sheet. Otherwise it sits static and inert.
class _PullUpIndicator extends StatelessWidget {
  const _PullUpIndicator({required this.active, required this.onOpen});

  final bool active;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final chevron = SizedBox(
      width: 54,
      height: 34,
      child: Opacity(
        opacity: active ? 1.0 : 0.4,
        child: ColorFiltered(
          colorFilter:
              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Lottie.asset(
            'assets/animation/pull-up.json',
            repeat: active,
            animate: active,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    if (!active) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 4),
        child: chevron,
      );
    }

    return GestureDetector(
      onTap: onOpen,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -80) onOpen();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 4),
        child: chevron,
      ),
    );
  }
}

// ─── Radar (active "Meet" state) ─────────────────────────────────────────────

class _MeetRadar extends StatefulWidget {
  const _MeetRadar({
    required this.photoPath,
    required this.nearby,
    required this.onGear,
    required this.onPersonTap,
  });

  final String? photoPath;
  final List<_NearbyPerson> nearby;
  final VoidCallback onGear;
  final void Function(_NearbyPerson) onPersonTap;

  @override
  State<_MeetRadar> createState() => _MeetRadarState();
}

class _MeetRadarState extends State<_MeetRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  static const _slots = <Alignment>[
    Alignment(-0.66, -0.18),
    Alignment(0.66, -0.48),
    Alignment(-0.66, 0.42),
    Alignment(0.66, 0.42),
  ];

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.nearby]
      ..sort((a, b) => a.meters.compareTo(b.meters));
    final visible = sorted.take(_slots.length).toList();

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _RingsPainter()),
        ),
        // Continuous pulse emanating from the centre while the session runs.
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) =>
                CustomPaint(painter: _PulsePainter(_pulse.value)),
          ),
        ),
        for (var i = 0; i < visible.length; i++)
          Align(
            alignment: _slots[i],
            child: _NearbyAvatar(
              person: visible[i],
              onTap: () => widget.onPersonTap(visible[i]),
            ),
          ),
        _CenterAvatar(photoPath: widget.photoPath, onGear: widget.onGear),
      ],
    );
  }
}

/// Two expanding/fading rings that ripple out from the centre of the radar.
class _PulsePainter extends CustomPainter {
  const _PulsePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.46;
    for (final phase in const [0.0, 0.5]) {
      final t = (progress + phase) % 1.0;
      final r = maxR * (0.18 + 0.82 * t);
      final opacity = (1.0 - t) * 0.5;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.46;
    const ringCount = 6;
    for (var i = ringCount; i >= 1; i--) {
      final r = maxR * (i / ringCount);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.06 + (ringCount - i) * 0.02);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}

class _NearbyAvatar extends StatelessWidget {
  const _NearbyAvatar({required this.person, required this.onTap});

  final _NearbyPerson person;
  final VoidCallback onTap;

  String _fmt(double m) =>
      m < 1 ? '${m.toStringAsFixed(1)} mtr' : '${m.toStringAsFixed(m < 10 ? 1 : 0)} mtr';

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
              border: Border.all(color: AppColors.discoverActive, width: 3),
            ),
            child: ClipOval(
              child: Image.network(
                person.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.discoverActive.withValues(alpha: 0.4),
                  child: const Icon(Icons.person, color: Colors.white),
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
            ),
            child: Text(
              _fmt(person.meters),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.discoverActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterAvatar extends StatelessWidget {
  const _CenterAvatar({required this.photoPath, required this.onGear});

  final String? photoPath;
  final VoidCallback onGear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brandRed, width: 4),
            color: Colors.white,
          ),
          child: ClipOval(
            child: photoPath != null
                ? Image.file(
                    File(photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _AvatarFallback(),
                  )
                : const _AvatarFallback(),
          ),
        ),
        GestureDetector(
          onTap: onGear,
          child: Container(
            margin: const EdgeInsets.only(right: 2, bottom: 2),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.discoverActive,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.settings, size: 15, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.person, size: 56, color: AppColors.brandRed),
    );
  }
}

/// A "label … value ⌄" row styled for the dark card (white label + value).
class _DarkSettingRow extends StatelessWidget {
  const _DarkSettingRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
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
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            dropdownColor: const Color(0xFF222222),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
            items: options
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Connect bottom sheet (modal — opened from the pull-up indicator) ────────

class _ConnectSheetModal extends StatefulWidget {
  const _ConnectSheetModal({
    required this.requests,
    required this.onAccept,
    required this.onDecline,
  });

  final List<_ConnReq> requests;
  final void Function(_ConnReq) onAccept;
  final void Function(_ConnReq) onDecline;

  @override
  State<_ConnectSheetModal> createState() => _ConnectSheetModalState();
}

class _ConnectSheetModalState extends State<_ConnectSheetModal> {
  late final List<_ConnReq> _items = List.of(widget.requests);

  void _accept(_ConnReq r) {
    widget.onAccept(r);
    setState(() => _items.remove(r));
  }

  void _decline(_ConnReq r) {
    widget.onDecline(r);
    setState(() => _items.remove(r));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Cap the full height so the sheet never rises above the camera pill.
    final maxFrac =
        ((media.size.height - media.padding.top - 8) / media.size.height)
            .clamp(0.6, 0.94);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.45,
      maxChildSize: maxFrac,
      snap: true,
      snapSizes: [0.6],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDADADA),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Connect',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              if (_items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Center(
                      child: Text(
                        'No new friend request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Connection Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _SheetRequestTile(
                      request: _items[i],
                      onAccept: () => _accept(_items[i]),
                      onDecline: () => _decline(_items[i]),
                    ),
                    childCount: _items.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24 + media.padding.bottom),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SheetRequestTile extends StatelessWidget {
  const _SheetRequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final _ConnReq request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              request.photoUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialAvatar(name: request.name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ConnectedProfileScreen(
                  name: request.name,
                  title: request.title,
                  company: request.company,
                  bio: '${request.title} at ${request.company}.',
                  photoUrl: request.photoUrl,
                ),
              )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  Text(request.title,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B6B6B))),
                  Text(request.company,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B6B6B))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RedBtn(label: 'Accept', onPressed: onAccept),
          const SizedBox(width: 8),
          _GrayBtn(label: 'Decline', onPressed: onDecline),
        ],
      ),
    );
  }
}

class _RedBtn extends StatelessWidget {
  const _RedBtn({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandRed,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _GrayBtn extends StatelessWidget {
  const _GrayBtn({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFF0F0F0),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B))),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials =
        name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFB7D9F2),
      ),
      child: Center(
        child: Text(initials.toUpperCase(),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

// ─── Incognito switch (hat glyph) ────────────────────────────────────────────

class _IncognitoSwitch extends StatelessWidget {
  const _IncognitoSwitch({
    required this.value,
    required this.immersive,
    required this.onChanged,
  });

  /// `true` = incognito (hidden from others), `false` = public (visible).
  final bool value;
  final bool immersive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final trackColor = value
        ? const Color(0xFFEAD0CB)
        : (immersive
            ? Colors.white.withValues(alpha: 0.22)
            : AppColors.brandRed.withValues(alpha: 0.18));
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
            alignment: value ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Center(
                child: CustomPaint(
                  size: Size(18, 18),
                  painter: _IncognitoHatPainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal "incognito" glyph — a fedora hat over a pair of glasses.
class _IncognitoHatPainter extends CustomPainter {
  const _IncognitoHatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.brandRed
      ..style = PaintingStyle.fill;
    final w = size.width, h = size.height;

    // Hat brim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.42, w * 0.9, h * 0.12),
        Radius.circular(h * 0.06),
      ),
      p,
    );
    // Hat crown.
    final crown = Path()
      ..moveTo(w * 0.24, h * 0.44)
      ..lineTo(w * 0.30, h * 0.14)
      ..quadraticBezierTo(w * 0.5, h * 0.06, w * 0.70, h * 0.14)
      ..lineTo(w * 0.76, h * 0.44)
      ..close();
    canvas.drawPath(crown, p);

    // Glasses.
    final stroke = Paint()
      ..color = AppColors.brandRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.07;
    canvas.drawCircle(Offset(w * 0.30, h * 0.74), h * 0.13, stroke);
    canvas.drawCircle(Offset(w * 0.70, h * 0.74), h * 0.13, stroke);
    canvas.drawLine(
        Offset(w * 0.43, h * 0.74), Offset(w * 0.57, h * 0.74), stroke);
  }

  @override
  bool shouldRepaint(covariant _IncognitoHatPainter oldDelegate) => false;
}

// ─── Data models + seed ──────────────────────────────────────────────────────

class _NearbyPerson {
  const _NearbyPerson({
    required this.id,
    required this.meters,
    required this.photoUrl,
    required this.name,
  });

  final String id;
  final double meters;
  final String photoUrl;
  final String name;
}

class _ConnReq {
  const _ConnReq({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String title;
  final String company;
  final String photoUrl;
}

const _seedRequests = <_ConnReq>[
  _ConnReq(id: 'c1', name: 'Liam Smith', title: 'CTO', company: 'TechCorp', photoUrl: 'https://i.pravatar.cc/150?img=12'),
  _ConnReq(id: 'c2', name: 'Olivia Rhye', title: 'CEO', company: 'Company', photoUrl: 'https://i.pravatar.cc/150?img=47'),
  _ConnReq(id: 'c3', name: 'Emma John', title: 'CFO', company: 'Finance Inc.', photoUrl: 'https://i.pravatar.cc/150?img=49'),
  _ConnReq(id: 'c4', name: 'Liam Smith', title: 'CTO', company: 'TechCorp', photoUrl: 'https://i.pravatar.cc/150?img=13'),
  _ConnReq(id: 'c5', name: 'Olivia Rhye', title: 'CEO', company: 'Company', photoUrl: 'https://i.pravatar.cc/150?img=45'),
  _ConnReq(id: 'c6', name: 'Emma John', title: 'CFO', company: 'Finance Inc.', photoUrl: 'https://i.pravatar.cc/150?img=44'),
  _ConnReq(id: 'c7', name: 'Liam Smith', title: 'CTO', company: 'TechCorp', photoUrl: 'https://i.pravatar.cc/150?img=14'),
  _ConnReq(id: 'c8', name: 'Olivia Rhye', title: 'CEO', company: 'Company', photoUrl: 'https://i.pravatar.cc/150?img=46'),
];
