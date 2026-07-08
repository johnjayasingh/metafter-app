import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/proximity/proximity_engine.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/services/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/metafter_logo.dart';
import '../../../../core/widgets/peer_avatar.dart';
import '../../../signup/data/signup_draft.dart';
import 'all_messages_screen.dart';
import 'connect_requests_screen.dart';
import 'discover_history_screen.dart';
import 'find_person_screen.dart';
import 'nearby_person_profile_screen.dart';
import 'profile_settings_screen.dart';

/// Swipeable host for the three primary tabs — Discover · Home/Meet · Messages —
/// shown as a peeking card carousel under a shared header.
///
/// The middle tab is the discovery control panel. Idle it reads **Home**
/// (dark→red); once a session starts it becomes an immersive **Meet** radar
/// (dark→green) showing the people nearby. All state comes from
/// [AppServices.I] — the session service drives the countdown/radar and the
/// request repository drives the pull-up sheet.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  static const _homeIndex = 1;

  /// Continuous carousel position — 0 = Discover, 1 = Home, 2 = Messages.
  final ValueNotifier<double> _pagePos =
      ValueNotifier<double>(_homeIndex.toDouble());
  late final AnimationController _pageAnim;
  int _page = _homeIndex;

  /// The listener attached to [_pageAnim] for the in-flight snap animation.
  /// Kept so it can be removed deterministically the moment the animation is
  /// interrupted — [AnimationController.stop] cancels the TickerFuture, so
  /// `forward().whenComplete` never runs on interruption and cannot be relied
  /// on to detach it.
  VoidCallback? _pageListener;

  /// Single-listener repo stream — created once for the shell's lifetime and
  /// consumed by exactly one StreamBuilder (in _DiscoverCard's stable root).
  late final Stream<int> _pendingCount;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _pendingCount = AppServices.I.requests.watchIncomingPendingCount();
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    _pagePos.dispose();
    super.dispose();
  }

  /// Detaches the current snap-animation listener, if any. Called before
  /// every new animation and on drag start so a stopped/interrupted animation
  /// never leaves its listener writing stale values to [_pagePos].
  void _detachPageListener() {
    final listener = _pageListener;
    if (listener != null) {
      _pageAnim.removeListener(listener);
      _pageListener = null;
    }
  }

  /// Animates the carousel to [target] (0..2) and updates the settled page.
  void _goToPage(int target) {
    _detachPageListener();
    _pageAnim
      ..stop()
      ..reset();
    final t = target.clamp(0, 2).toDouble();
    final anim = Tween<double>(begin: _pagePos.value, end: t).animate(
      CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic),
    );
    // Drive from the controller (not the tween) so the listener can be
    // removed later without holding the tween instance.
    void listener() => _pagePos.value = anim.value;
    _pageListener = listener;
    _pageAnim.addListener(listener);
    _pageAnim.forward().whenComplete(() {
      if (mounted && _page != t.round()) setState(() => _page = t.round());
    });
  }

  Future<void> _setIncognito(bool v) async {
    await AppServices.I.settings.setIncognitoScan(v);
    if (!mounted) return;
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

  // ── Discovery session ──

  Future<void> _startSession() async {
    final error = await AppServices.I.session.start();
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.brandRed,
        content: Text(error),
      ),
    );
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End session?'),
        content:
            const Text('You will stop being discoverable to people nearby.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirmed == true) await AppServices.I.session.end();
  }

  // ── Requests (pull-up sheet) ──

  Future<void> _acceptRequest(ConnectionRequest request) async {
    final services = AppServices.I;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // The pull-up sheet lives on the root navigator; it stays open over
    // HomeShell's Scaffold and would hide the confirmation SnackBar (and its
    // 'Find them' action) that renders at the bottom. Close it first so the
    // primary post-accept affordance is actually visible (finding [19]).
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    await services.connection.accept(request);
    if (rootNavigator.canPop()) rootNavigator.pop();
    final stillNearby = services.engine.isNearby(request.peerSub);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.brandRed,
        content: Text('Connected with ${request.card.name}!'),
        action: stillNearby
            ? SnackBarAction(
                label: 'Find them',
                textColor: Colors.white,
                onPressed: () => navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => FindPersonScreen(card: request.card),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _declineRequest(ConnectionRequest request) =>
      AppServices.I.connection.decline(request);

  void _openFullRequests() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ConnectRequestsScreen()),
    );
  }

  void _openConnectSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x40000000),
      builder: (_) => _ConnectSheetModal(
        onAccept: _acceptRequest,
        onDecline: _declineRequest,
        onExpand: _openFullRequests,
      ),
    );
  }

  void _openProfile(NearbyPeer peer) {
    final card = peer.card;
    if (card == null) return; // card not read yet — nothing to show
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NearbyPersonProfileScreen(card: card, meters: peer.meters),
    ));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const ProfileSettingsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final photo = SignupDraft.instance.photoPath;
    final hasPhoto = (photo ?? '').isNotEmpty;

    return ValueListenableBuilder<SessionState>(
      valueListenable: AppServices.I.session.state,
      builder: (context, sessionState, _) {
        final active = sessionState is SessionActive;
        final immersive = _page == _homeIndex && active;
        return Scaffold(
          backgroundColor: immersive ? Colors.black : Colors.white,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: AppServices.I.settings.incognitoScan,
                  builder: (context, incognito, _) => _SharedHeader(
                    page: _page,
                    immersive: immersive,
                    incognito: incognito,
                    // Advertising can't be hot-restarted mid-session, so the
                    // visibility toggle is locked while active to avoid a
                    // false "they can't see you" confirmation (finding [17]).
                    sessionActive: active,
                    onIncognito: _setIncognito,
                    onPrev: () => _goToPage(_page - 1),
                    onNext: () => _goToPage(_page + 1),
                  ),
                ),
                _PageTitleStrip(
                  position: _pagePos,
                  titles: ['Discover', active ? 'Meet' : 'Home', 'Messages'],
                  immersive: immersive,
                ),
                Expanded(
                  child: _PeekCarousel(
                    position: _pagePos,
                    onDragStart: () {
                      _detachPageListener();
                      _pageAnim.stop();
                    },
                    onSnap: _goToPage,
                    home: _DiscoverCard(
                      photoPath: hasPhoto ? photo : null,
                      sessionState: sessionState,
                      pendingCount: _pendingCount,
                      onStart: _startSession,
                      onEnd: _endSession,
                      onGear: _openSettings,
                      onPersonTap: _openProfile,
                      onOpenSheet: () => _openConnectSheet(context),
                    ),
                    discover: const DiscoverHistoryScreen(embedded: true),
                    messages: const AllMessagesScreen(embedded: true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Peek carousel ───────────────────────────────────────────────────────────

/// A three-page carousel where **Home** is a full-screen hub. Each tab is
/// full-screen when settled; swiping slides the Discover (left) / Messages
/// (right) panel fully over Home as a shadowed card while Home recedes behind
/// it (scale + parallax + dim), so the neighbour only *peeks* mid-drag and
/// commits to a full view once released past threshold.
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
  /// Inner-edge corner radius of a side panel while it is mid-slide.
  static const double _cardRadius = 28;

  double _startPos = 1;
  double _startDx = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
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
              // 0 at Home, 1 when a side panel fully covers it.
              final t = (p - 1).abs().clamp(0.0, 1.0);
              // Home drifts away from the entering panel for parallax depth.
              final dir = p < 1.0 ? -1.0 : 1.0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Home hub — full-screen base that recedes as a card behind
                  // the sliding panel (scale + parallax + dim).
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(dir * w * 0.06 * t, 0),
                      child: Transform.scale(
                        scale: 1.0 - 0.05 * t,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              widget.home,
                              if (t > 0)
                                IgnorePointer(
                                  child: ColoredBox(
                                    color: Color.fromRGBO(0, 0, 0, 0.25 * t),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Discover slides fully over from the left; its inner (right)
                  // edge rounds mid-slide and squares off once it fully covers.
                  if (p < 1.0)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: -w * p,
                      width: w,
                      child: _panel(
                        widget.discover,
                        roundRight: true,
                        radius: _cardRadius * p,
                      ),
                    ),
                  // Messages slides fully over from the right.
                  if (p > 1.0)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: w * (2 - p),
                      width: w,
                      child: _panel(
                        widget.messages,
                        roundRight: false,
                        radius: _cardRadius * (2 - p),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _panel(
    Widget child, {
    required bool roundRight,
    required double radius,
  }) {
    final br = roundRight
        ? BorderRadius.horizontal(right: Radius.circular(radius))
        : BorderRadius.horizontal(left: Radius.circular(radius));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: br,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 22,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: br, child: child),
    );
  }
}

// ─── Shared header ───────────────────────────────────────────────────────────

class _SharedHeader extends StatelessWidget {
  const _SharedHeader({
    required this.page,
    required this.immersive,
    required this.incognito,
    required this.sessionActive,
    required this.onIncognito,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final bool immersive;
  final bool incognito;

  /// While true the incognito switch is locked (see finding [17]).
  final bool sessionActive;
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
            enabled: !sessionActive,
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
    required this.sessionState,
    required this.pendingCount,
    required this.onStart,
    required this.onEnd,
    required this.onGear,
    required this.onPersonTap,
    required this.onOpenSheet,
  });

  final String? photoPath;
  final SessionState sessionState;

  /// Shared pull-up badge stream — subscribed once at this widget's stable
  /// root so switching Home ⇄ Meet never re-listens the single-listener
  /// repo stream.
  final Stream<int> pendingCount;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onGear;
  final void Function(NearbyPeer) onPersonTap;
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

  /// Duration picker options (DESIGN_SPEC §4.1).
  static const _durationOptions = <String, Duration>{
    '30 min': Duration(minutes: 30),
    '1 hr': Duration(hours: 1),
    '2 hrs': Duration(hours: 2),
    '4 hrs': Duration(hours: 4),
    '8 hrs': Duration(hours: 8),
  };

  /// Distance budget options (DESIGN_SPEC §4.1).
  static const _distanceOptions = <String, double>{
    '2 mts': 2,
    '5 mts': 5,
    '10 mts': 10,
  };

  static String _durationLabel(Duration d) {
    for (final e in _durationOptions.entries) {
      if (e.value == d) return e.key;
    }
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    return d.inHours == 1 ? '1 hr' : '${d.inHours} hrs';
  }

  static String _distanceLabel(double m) {
    for (final e in _distanceOptions.entries) {
      if (e.value == m) return e.key;
    }
    return m == m.roundToDouble() ? '${m.round()} mts' : '$m mts';
  }

  @override
  Widget build(BuildContext context) {
    final active = sessionState is SessionActive;
    return StreamBuilder<int>(
      stream: pendingCount,
      builder: (context, snap) {
        final pending = snap.data ?? 0;
        return ValueListenableBuilder<bool>(
          valueListenable: AppServices.I.settings.reduceMotion,
          builder: (context, reduceMotion, _) {
            // A2: red ⇄ green gradient cross-fade (~600 ms).
            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: active ? _meetGradient : _idleGradient,
              ),
              child: active
                  ? _buildActive(context, sessionState as SessionActive,
                      pending, reduceMotion)
                  : _buildIdle(context, pending, reduceMotion),
            );
          },
        );
      },
    );
  }

  Widget _buildIdle(BuildContext context, int pending, bool reduceMotion) {
    final settings = AppServices.I.settings;
    final starting = sessionState is SessionStarting;
    return Column(
      children: [
        const SizedBox(height: 40),
        ValueListenableBuilder<MoodRing>(
          valueListenable: settings.mood,
          builder: (context, mood, _) => _CenterAvatar(
            photoPath: photoPath,
            ringColor: mood.color,
            onGear: onGear,
          ),
        ),
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
          child: ValueListenableBuilder<Duration>(
            valueListenable: settings.discoverableDuration,
            builder: (context, duration, _) => _DarkSettingRow(
              label: 'Discoverable for the next',
              value: _durationLabel(duration),
              options: _durationOptions.keys.toList(),
              onChanged: (v) {
                final picked = _durationOptions[v];
                if (picked != null) settings.setDiscoverableDuration(picked);
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ValueListenableBuilder<double>(
            valueListenable: settings.distanceBudget,
            builder: (context, meters, _) => _DarkSettingRow(
              label: 'Set Distance',
              value: _distanceLabel(meters),
              options: _distanceOptions.keys.toList(),
              onChanged: (v) {
                final picked = _distanceOptions[v];
                if (picked != null) settings.setDistanceBudget(picked);
              },
            ),
          ),
        ),
        const Spacer(),
        _PullUpIndicator(
          pending: pending,
          reduceMotion: reduceMotion,
          onOpen: onOpenSheet,
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildActive(BuildContext context, SessionActive state, int pending,
      bool reduceMotion) {
    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: AppServices.I.settings.distanceBudget,
            builder: (context, maxMeters, _) => _MeetRadar(
              photoPath: photoPath,
              maxMeters: maxMeters,
              reduceMotion: reduceMotion,
              onGear: onGear,
              onPersonTap: onPersonTap,
            ),
          ),
        ),
        Text(
          state.incognito
              ? 'You are in incognito mode'
              : 'You are discoverable',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        _CountdownText(
          remaining: AppServices.I.session.remaining,
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _LetsGoButton(label: 'End Session', onPressed: onEnd),
        ),
        const SizedBox(height: 12),
        _PullUpIndicator(
          pending: pending,
          reduceMotion: reduceMotion,
          onOpen: onOpenSheet,
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 14),
      ],
    );
  }
}

/// "Time Remaining: 04:00" — live tick from the session service; the final
/// 30 s pulse red (A14). At reduced motion the text turns red without pulsing.
class _CountdownText extends StatefulWidget {
  const _CountdownText({required this.remaining, required this.reduceMotion});

  final ValueListenable<Duration> remaining;
  final bool reduceMotion;

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText>
    with SingleTickerProviderStateMixin {
  static const _base = Color(0xFFD7ECDC);
  static const _urgentWindow = Duration(seconds: 30);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.remaining,
      builder: (context, d, _) {
        final urgent = d > Duration.zero && d <= _urgentWindow;
        if (urgent && !widget.reduceMotion) {
          if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
        } else if (_pulse.isAnimating) {
          _pulse
            ..stop()
            ..value = 0;
        }
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final color = !urgent
                ? _base
                : widget.reduceMotion
                    ? AppColors.brandRed
                    : Color.lerp(_base, AppColors.brandRed, _pulse.value)!;
            return Text(
              'Time Remaining: ${TimeFormat.countdown(d)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: urgent ? FontWeight.w700 : FontWeight.w400,
              ),
            );
          },
        );
      },
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
/// With pending requests the chevron animation plays (A7 — static at reduced
/// motion) and a badge shows the count. Tapping / swiping up always opens the
/// sheet (its empty state explains when there is nothing).
class _PullUpIndicator extends StatelessWidget {
  const _PullUpIndicator({
    required this.pending,
    required this.reduceMotion,
    required this.onOpen,
  });

  final int pending;
  final bool reduceMotion;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final active = pending > 0;
    final animate = active && !reduceMotion;
    Widget chevron = SizedBox(
      width: 54,
      height: 34,
      child: Opacity(
        opacity: active ? 1.0 : 0.4,
        child: ColorFiltered(
          colorFilter:
              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Lottie.asset(
            'assets/animation/pull-up.json',
            repeat: animate,
            animate: animate,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    if (active) {
      chevron = Stack(
        clipBehavior: Clip.none,
        children: [
          chevron,
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandRed,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$pending',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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
    required this.maxMeters,
    required this.reduceMotion,
    required this.onGear,
    required this.onPersonTap,
  });

  final String? photoPath;
  final double maxMeters;
  final bool reduceMotion;
  final VoidCallback onGear;
  final void Function(NearbyPeer) onPersonTap;

  @override
  State<_MeetRadar> createState() => _MeetRadarState();
}

class _MeetRadarState extends State<_MeetRadar>
    with TickerProviderStateMixin {
  static const _maxBubbles = 5;

  /// Fresh single-listener stream per radar mount (a new _MeetRadar is
  /// created for every session, so re-listening is always safe).
  StreamSubscription<List<NearbyPeer>>? _sub;

  /// Visible peers keyed by displayKey, plus peers currently fading out.
  final Map<String, NearbyPeer> _peers = {};
  final Map<String, NearbyPeer> _leaving = {};

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    _sub = AppServices.I.session.nearby.listen(_onPeers);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _MeetRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) _syncMotion();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    _float.dispose();
    super.dispose();
  }

  /// A3/A5 loops run only when motion is allowed.
  void _syncMotion() {
    if (widget.reduceMotion) {
      _pulse.stop();
      _float
        ..stop()
        ..value = 0;
    } else {
      if (!_pulse.isAnimating) _pulse.repeat();
      if (!_float.isAnimating) _float.repeat();
    }
  }

  void _onPeers(List<NearbyPeer> peers) {
    if (!mounted) return;
    setState(() {
      final next = <String, NearbyPeer>{
        // Engine emits nearest-first — keep the ~5 closest.
        for (final p in peers.take(_maxBubbles)) p.displayKey: p,
      };
      for (final entry in _peers.entries) {
        if (!next.containsKey(entry.key)) _leaving[entry.key] = entry.value;
      }
      _leaving.removeWhere((key, _) => next.containsKey(key));
      _peers
        ..clear()
        ..addAll(next);
    });
  }

  /// Radial placement ∝ estimated distance; angle stable per peer.
  Alignment _alignmentFor(NearbyPeer p) {
    final angle = (p.displayKey.hashCode % 360) * math.pi / 180.0;
    final frac =
        (p.meters / math.max(widget.maxMeters, 0.1)).clamp(0.12, 1.0);
    final r = 0.30 + 0.55 * frac;
    return Alignment(math.cos(angle) * r, math.sin(angle) * r * 0.85);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _RingsPainter()),
        ),
        // Continuous pulse emanating from the centre while the session runs
        // (A3; suppressed at reduced motion).
        if (!widget.reduceMotion)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) =>
                  CustomPaint(painter: _PulsePainter(_pulse.value)),
            ),
          ),
        for (final peer in _leaving.values)
          AnimatedAlign(
            key: ValueKey('leave-${peer.displayKey}'),
            alignment: _alignmentFor(peer),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: _exitBubble(peer),
          ),
        for (final peer in _peers.values)
          AnimatedAlign(
            key: ValueKey('peer-${peer.displayKey}'),
            alignment: _alignmentFor(peer),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: _enterBubble(peer),
          ),
        ValueListenableBuilder<MoodRing>(
          valueListenable: AppServices.I.settings.mood,
          builder: (context, mood, _) => _CenterAvatar(
            photoPath: widget.photoPath,
            ringColor: mood.color,
            onGear: widget.onGear,
          ),
        ),
      ],
    );
  }

  /// A4 enter: scale 0.6→1 + fade (~350 ms) with a soft overshoot.
  Widget _enterBubble(NearbyPeer peer) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('in-${peer.displayKey}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: _floating(peer, _NearbyAvatar(
        peer: peer,
        onTap: peer.card == null ? null : () => widget.onPersonTap(peer),
      )),
    );
  }

  /// A4 exit: fade out (~250 ms), then drop from the overlay.
  Widget _exitBubble(NearbyPeer peer) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('out-${peer.displayKey}'),
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 250),
      onEnd: () {
        if (mounted) setState(() => _leaving.remove(peer.displayKey));
      },
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: IgnorePointer(child: _floating(peer, _NearbyAvatar(peer: peer))),
    );
  }

  /// A5 idle float: gentle per-peer sine drift ±6 px off one shared loop.
  Widget _floating(NearbyPeer peer, Widget child) {
    if (widget.reduceMotion) return child;
    final phase = (peer.displayKey.hashCode % 628) / 100.0;
    return AnimatedBuilder(
      animation: _float,
      builder: (context, inner) {
        final dy = math.sin(2 * math.pi * _float.value + phase) * 6.0;
        return Transform.translate(offset: Offset(0, dy), child: inner);
      },
      child: child,
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

/// One floating peer bubble: card avatar (or a dashed placeholder while the
/// GATT card read is still in flight) plus the white distance chip.
class _NearbyAvatar extends StatelessWidget {
  const _NearbyAvatar({required this.peer, this.onTap});

  final NearbyPeer peer;
  final VoidCallback? onTap;

  String _fmt(double m) => m < 1
      ? '${m.toStringAsFixed(1)} mtr'
      : '${m.toStringAsFixed(m < 10 ? 1 : 0)} mtr';

  @override
  Widget build(BuildContext context) {
    final card = peer.card;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (card != null)
            PeerAvatar(
              card: card,
              size: 58,
              ringColor: peer.mood.color,
              ringWidth: 3,
              showVerified: true,
            )
          else
            const SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _DashedRingPainter(),
                child: Icon(Icons.person_outline,
                    color: Colors.white54, size: 28),
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
              _fmt(peer.meters),
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

/// Neutral dashed ring shown before a peer's profile card has been read.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.65);
    const dashes = 14;
    const gapFrac = 0.45;
    final sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        i * sweep,
        sweep * (1 - gapFrac),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => false;
}

class _CenterAvatar extends StatelessWidget {
  const _CenterAvatar({
    required this.photoPath,
    required this.ringColor,
    required this.onGear,
  });

  final String? photoPath;

  /// Mood ring color (DESIGN_SPEC §11.1) — mirrors what peers see in the
  /// BLE advertisement.
  final Color ringColor;
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
            border: Border.all(color: ringColor, width: 4),
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
    // A persisted value outside the preset list must still render.
    final items = options.contains(value) ? options : [value, ...options];
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
            items: items
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
    required this.onAccept,
    required this.onDecline,
    required this.onExpand,
  });

  final Future<void> Function(ConnectionRequest) onAccept;
  final Future<void> Function(ConnectionRequest) onDecline;

  /// Invoked after the sheet closes itself because it was dragged to its
  /// full extent (or "See all" was tapped) — pushes the full-page list.
  final VoidCallback onExpand;

  @override
  State<_ConnectSheetModal> createState() => _ConnectSheetModalState();
}

class _ConnectSheetModalState extends State<_ConnectSheetModal> {
  /// Fresh single-listener stream per sheet opening.
  late final Stream<List<ConnectionRequest>> _requests =
      AppServices.I.requests.watchIncomingPending();

  bool _expanded = false;

  /// Request ids with an accept/decline in flight — mirrors
  /// ConnectRequestsScreen._busy so a double-tap can't fire the async action
  /// twice before the row disappears (finding [20]).
  final Set<String> _busy = {};

  Future<void> _run(
    ConnectionRequest request,
    Future<void> Function(ConnectionRequest) action,
  ) async {
    if (!_busy.add(request.id)) return;
    setState(() {});
    try {
      await action(request);
    } finally {
      if (mounted) setState(() => _busy.remove(request.id));
    }
  }

  void _goFull() {
    if (_expanded) return;
    _expanded = true;
    Navigator.of(context).pop();
    widget.onExpand();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Cap the full height so the sheet never rises above the camera pill.
    final maxFrac =
        ((media.size.height - media.padding.top - 8) / media.size.height)
            .clamp(0.6, 0.94);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        // Dragged all the way up → hand off to the full page (§7.2).
        if (n.extent >= n.maxExtent - 0.005) _goFull();
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.45,
        maxChildSize: maxFrac,
        snap: true,
        snapSizes: const [0.6],
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
            child: StreamBuilder<List<ConnectionRequest>>(
              stream: _requests,
              builder: (context, snap) {
                final items = snap.data ?? const <ConnectionRequest>[];
                return CustomScrollView(
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
                    if (items.isEmpty)
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Connection Request',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _goFull,
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final request = items[i];
                            return _SheetRequestTile(
                              request: request,
                              busy: _busy.contains(request.id),
                              onAccept: () =>
                                  _run(request, widget.onAccept),
                              onDecline: () =>
                                  _run(request, widget.onDecline),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 24 + media.padding.bottom),
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SheetRequestTile extends StatelessWidget {
  const _SheetRequestTile({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ConnectionRequest request;

  /// While true an accept/decline is in flight and the buttons are disabled.
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final card = request.card;
    final note = request.note;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          PeerAvatar(card: card, size: 52, showVerified: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                if (card.designation.isNotEmpty)
                  Text(card.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B6B6B))),
                if (card.company.isNotEmpty)
                  Text(card.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B6B6B))),
                if (note != null && note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '“$note”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RedBtn(label: 'Accept', onPressed: busy ? null : onAccept),
          const SizedBox(width: 8),
          _GrayBtn(label: 'Decline', onPressed: busy ? null : onDecline),
        ],
      ),
    );
  }
}

class _RedBtn extends StatelessWidget {
  const _RedBtn({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

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
  final VoidCallback? onPressed;

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

// ─── Incognito switch (hat glyph) ────────────────────────────────────────────

class _IncognitoSwitch extends StatelessWidget {
  const _IncognitoSwitch({
    required this.value,
    required this.immersive,
    required this.enabled,
    required this.onChanged,
  });

  /// `true` = incognito (hidden from others), `false` = public (visible).
  final bool value;
  final bool immersive;

  /// When false the switch is locked (an active session can't hot-restart
  /// advertising) and a tap explains why instead of flipping the value.
  final bool enabled;
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
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: GestureDetector(
          onTap: () {
            if (!enabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 2),
                  content: Text('End your session to change visibility.'),
                ),
              );
              return;
            }
            onChanged(!value);
          },
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
