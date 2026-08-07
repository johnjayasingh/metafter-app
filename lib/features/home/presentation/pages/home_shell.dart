import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

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
  /// Deck axis — one continuous value spanning five settled states:
  /// 0 = Discover full-screen · 1 = Discover parked (Home peeks right) ·
  /// 2 = Home hub · 3 = Messages parked (Home peeks left) · 4 = Messages full.
  static const _discoverFullIndex = 0;
  static const _discoverIndex = 1;
  static const _homeIndex = 2;
  static const _messagesIndex = 3;
  static const _messagesFullIndex = 4;

  /// Continuous carousel position — 0 = Discover, 1 = Home, 2 = Messages.
  final ValueNotifier<double> _pagePos = ValueNotifier<double>(
    _homeIndex.toDouble(),
  );
  late final AnimationController _pageAnim;
  int _page = _homeIndex;

  /// Live query for the Messages card's header search (empty = show everything).
  /// Owned here so the search icon in the Messages card header and the embedded
  /// [AllMessagesScreen] share a single source of truth.
  final ValueNotifier<String> _messagesQuery = ValueNotifier<String>('');

  /// Thread-row swipe-to-archive is only armed once the Messages page is
  /// (nearly) full-screen. While the page is parked, a horizontal drag on a
  /// row must page the DECK, as in the demo — a Dismissible would win the
  /// gesture arena and archive the thread instead.
  final ValueNotifier<bool> _messagesRowSwipe = ValueNotifier<bool>(false);

  /// True once the Discover page is (nearly) full-screen — unlocks its
  /// standalone chrome (view toggle, calendar button) per the design.
  final ValueNotifier<bool> _discoverFull = ValueNotifier<bool>(false);

  /// Discover's list ⟷ card-deck state; the header toggle drives it and the
  /// embedded body listens.
  final ValueNotifier<bool> _discoverGrid = ValueNotifier<bool>(false);

  void _syncRowSwipe() {
    final v = _pagePos.value >= 3.7;
    if (_messagesRowSwipe.value != v) _messagesRowSwipe.value = v;
    final d = _pagePos.value <= 0.3;
    if (_discoverFull.value != d) _discoverFull.value = d;
  }

  /// Stable embedded bodies — created once so the deck's per-tick side-card
  /// rebuilds never remount their subtrees (single-listener streams inside).
  late final Widget _discoverBody = DiscoverHistoryScreen(
    embedded: true,
    fullChrome: _discoverFull,
    gridMode: _discoverGrid,
  );
  late final Widget _messagesBody = AllMessagesScreen(
    embedded: true,
    searchQuery: _messagesQuery,
    rowSwipeEnabled: _messagesRowSwipe,
  );

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
      // Settle pace measured from the demo's release animations (~0.4-0.6 s
      // with a long ease-out tail).
      duration: const Duration(milliseconds: 420),
    );
    _pagePos.addListener(_syncRowSwipe);
    _pendingCount = AppServices.I.requests.watchIncomingPendingCount();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pagePos.removeListener(_syncRowSwipe);
    _pageAnim.dispose();
    _pagePos.dispose();
    _messagesQuery.dispose();
    _messagesRowSwipe.dispose();
    _discoverFull.dispose();
    _discoverGrid.dispose();
    super.dispose();
  }

  /// Deadline for the post-accept confirmation banner (see [_acceptRequest]).
  Timer? _bannerTimer;

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
    final t = target.clamp(0, 4).toDouble();
    // Leaving the Messages side entirely clears its header search. The search
    // field UI resets when the card unmounts, so the shared query must reset
    // in lockstep — otherwise a stale, invisible filter hides threads.
    if (t < _messagesIndex) _messagesQuery.value = '';
    final anim = Tween<double>(
      begin: _pagePos.value,
      end: t,
    ).animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic));
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
      SnackBar(backgroundColor: AppColors.brandRed, content: Text(error)),
    );
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End session?'),
        content: const Text(
          'You will stop being discoverable to people nearby.',
        ),
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
    final banner = messenger.showSnackBar(
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
    // With an accessibility service active (assistants, password managers —
    // near-universal on Samsung) Flutter ignores SnackBar durations entirely,
    // and this confirmation was observed parked over the chat input for 13
    // minutes. It is transient by design — close it after a hard deadline.
    // Tracked so tests (and dispose) don't leak a pending timer.
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 8), banner.close);
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            NearbyPersonProfileScreen(card: card, meters: peer.meters),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileSettingsScreen()),
    );
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
          // Fills the thin status-bar gap / corner triangles behind the cards —
          // black under the immersive Meet home, white otherwise.
          backgroundColor: immersive ? Colors.black : Colors.white,
          body: SafeArea(
            bottom: false,
            child: _CardDeck(
              position: _pagePos,
              immersive: immersive,
              homeTitle: active ? 'Meet' : 'Home',
              onDragStart: () {
                _detachPageListener();
                _pageAnim.stop();
              },
              onSnap: _goToPage,
              onHomeTap: () => _goToPage(_homeIndex),
              onExpandDiscover: () => _goToPage(_discoverFullIndex),
              onExpandMessages: () => _goToPage(_messagesFullIndex),
              // Home hub — the frontmost deck card. Carries its own header +
              // peeking neighbour-title preview over the Home/Meet gradient.
              home: _HomeCard(
                immersive: immersive,
                active: active,
                sessionState: sessionState,
                photoPath: hasPhoto ? photo : null,
                pendingCount: _pendingCount,
                onIncognito: _setIncognito,
                onPrev: () => _goToPage(_discoverIndex),
                onNext: () => _goToPage(_messagesIndex),
                onStart: _startSession,
                onEnd: _endSession,
                onGear: _openSettings,
                onPersonTap: _openProfile,
                onOpenSheet: () => _openConnectSheet(context),
              ),
              // Side pages slide in under the Home card; each lays out around
              // the parked Home peek and can expand to a true full screen.
              discoverBuilder: (expand) => _SideCard(
                chevron: _SideChevron.right,
                expand: expand,
                peekInsetFrac: _kDiscoverPeekInset,
                onBack: () => _goToPage(_homeIndex),
                trailing: DiscoverViewToggle(gridMode: _discoverGrid),
                child: _discoverBody,
              ),
              messagesBuilder: (expand) => _SideCard(
                chevron: _SideChevron.left,
                expand: expand,
                onBack: () => _goToPage(_homeIndex),
                child: _messagesBody,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared title geometry ───────────────────────────────────────────────────

// The Home card's title strip and a side page's big title are the SAME visual
// object across a transition: the neighbour ghost in the strip hands off to the
// page's own title, which starts life exactly on top of it (demo f0002→f0014 —
// the ghost never rides away with the Home card). Both sides resolve the band,
// size, colour and slot from these constants so the hand-off lands frame-exact.

/// Figma's "Home Page" frame measures y from the screen top; the SafeArea
/// already supplies this much of it, so every spec below is quoted absolute
/// and reduced by it.
const double _kSafeTop = 59;

/// Height of [_SharedHeader] — Padding(8, …, 2) around a 48pt icon row.
const double _kSharedHeaderHeight = 58;

/// Figma anchors the titles by CAP top, not by line box (vertical trim: cap
/// height), so they are placed through [_titleMetrics] rather than centred.
/// Nav titles: cap top 146, content ("Rectangle 3593") top 216 — the 39pt
/// between them is the breathing room the strip has to reserve.
const double _kTitleCapTop = 146 - _kSafeTop;
const double _kContentTop = 216 - _kSafeTop;
const double _kTitleStripHeight = _kContentTop - _kSharedHeaderHeight;

/// Figma: Instrument Sans SemiBold 600, 42.92px, line height 120%, letter
/// spacing 0. A 42.92px title measures 31px cap-to-baseline.
const double _kTitleSize = 42.92;
const double _kTitleLineHeight = 1.2;
const double _kCapHeightRatio = 31 / 42.92;
const Color _kGhostTitleColor = Color(0xFFBEC0C2);

/// Gap between adjacent titles — Figma lays them out as one centred row
/// ("Discover" ends 56 before "Home" starts), so the neighbours' slots fall
/// out of the centre title's width rather than a fixed fraction.
const double _kTitleGap = 56;

/// Parked page title: same 42.92 face, low on the page (Figma cap top 231).
/// Its left edge is the page's own content margin — the big title and the
/// section header below it read as one column, so they share the 16.
const double _kPageTitleCapTop = 231 - _kSafeTop;
const double _kPageTitleLeft = 16;

/// Full-screen page title: the compact `‹ Title` app-bar row — 18pt beside the
/// back chevron, cap top 70 absolute.
const double _kFullTitleSize = 18;
const double _kFullTitleCapTop = 70 - _kSafeTop;
const double _kFullTitleLeft = 56;

/// The deck's shared title face. Only the size and colour move.
TextStyle _titleStyle({required double size, required Color color}) => TextStyle(
  // Pin the BUNDLED family: the ambient DefaultTextStyle is a google_fonts
  // style whose family is a runtime *regular* variant, so inheriting it would
  // leave w600 to be faked instead of using the real SemiBold face (see the
  // note on AppTheme.lightTheme's fontFamily).
  fontFamily: 'InstrumentSans',
  fontSize: size,
  height: _kTitleLineHeight,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
  color: color,
);

/// Lays [text] out in [style] and returns its box plus the `top` that puts its
/// cap top on [capTop] — Figma's numbers are cap-top, Flutter's are box-top.
({Size size, double top}) _titleMetrics(
  BuildContext context,
  String text,
  TextStyle style,
  double capTop,
) {
  final painter =
      TextPainter(
          text: TextSpan(
            text: text,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )
        ..layout();
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  final capHeight = (style.fontSize ?? 0) * _kCapHeightRatio;
  return (size: painter.size, top: capTop - (baseline - capHeight));
}

/// The gradient card's copy, straight off Figma — all Instrument Sans, cap
/// trimmed, 120% line height, white. Headline 24 SemiBold; body and the
/// setting-row labels 16 Regular.
final TextStyle _kCardHeadlineStyle = _titleStyle(
  size: 24,
  color: Colors.white,
);
final TextStyle _kCardBodyStyle = _titleStyle(
  size: 16,
  color: Colors.white,
).copyWith(fontWeight: FontWeight.w400);

/// Fraction of the width each parked side page cedes to the Home peek stack
/// (measured from the demo — slightly wider on Messages than Discover).
const double _kDiscoverPeekInset = 0.26;
const double _kMessagesPeekInset = 0.36;

/// Side pages barely travel — they sit at their parked position with this
/// small parallax offset while the Home card does the full drag distance
/// (demo: the incoming page is revealed, not slid in).
const double _kSideParallax = 0.10;

// ─── Card deck ────────────────────────────────────────────────────────────────

/// The five-position card deck (axis on [_HomeShellState]). **Home is always
/// the frontmost card**: side pages slide in *underneath* it while Home
/// shrinks toward the opposite edge and parks there as a persistent peek —
/// backed by a grey "far page" ghost — the stacked-deck look of the demo.
/// Dragging past a parked side page (or tapping its big title) expands it to
/// a true full screen, sliding the peek stack away.
class _CardDeck extends StatefulWidget {
  const _CardDeck({
    required this.position,
    required this.immersive,
    required this.homeTitle,
    required this.home,
    required this.discoverBuilder,
    required this.messagesBuilder,
    required this.onExpandDiscover,
    required this.onExpandMessages,
    required this.onDragStart,
    required this.onSnap,
    required this.onHomeTap,
  });

  /// Continuous 0..4 deck axis (see [_HomeShellState]).
  final ValueNotifier<double> position;

  /// True while an active Meet session makes the settled Home immersive (dark).
  final bool immersive;

  /// The Home card's own title — the deck needs it to place the neighbour
  /// titles that flank it.
  final String homeTitle;
  final Widget home;

  /// Side pages are rebuilt each position tick with their current expansion
  /// (0 = parked next to the peek, 1 = full-screen); their bodies stay stable
  /// widget instances so subtree state is never remounted.
  final Widget Function(double expand) discoverBuilder;
  final Widget Function(double expand) messagesBuilder;

  /// Tap on a page's arrived title — takes that page full-screen.
  final VoidCallback onExpandDiscover;
  final VoidCallback onExpandMessages;
  final VoidCallback onDragStart;
  final ValueChanged<int> onSnap;

  /// Tap on the parked Home peek — returns the deck to Home.
  final VoidCallback onHomeTap;

  @override
  State<_CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<_CardDeck> {
  /// Rounded corner radius shared by every card in the deck.
  static const double _cardRadius = 28;

  /// Home card scale when parked as the edge peek (measured from the demo:
  /// the parked card is ~70% of the screen).
  static const double _peekScale = 0.72;

  /// Home card travel into its peek slot, as a fraction of width — parks the
  /// card's left edge at ~75% of the screen width (demo f0023).
  static const double _peekShift = 0.615;

  /// Side pages start this much ghosted and solidify as they are revealed
  /// (demo f0058: the incoming Messages list reads ~half strength mid-drag).
  static const double _sideFade = 0.45;

  /// Extra travel that slides the peek stack fully off-screen while a side
  /// page expands to full-screen.
  static const double _expandShift = 0.5;

  /// The grey far-page ghost peeks out from behind Home by this much.
  static const double _ghostShift = 0.09;

  /// Parked card top gap below the safe area (demo: the peek's top edge
  /// sits ~58pt under the status region — higher than centred scaling).
  static const double _peekTopGap = 58;

  /// Tight, downward-biased shadows — in the demo the stack's shadow reads
  /// only along the cards' sides, with no halo above the top edge.
  static const List<BoxShadow> _cardShadow = [
    BoxShadow(color: Color(0x16000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  double _startPos = 2;
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
            widget.position.value = (_startPos - dx / w).clamp(0.0, 4.0);
          },
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            final p = widget.position.value;
            final target = v < -350
                ? p.ceil()
                : (v > 350 ? p.floor() : p.round());
            widget.onSnap(target.clamp(0, 4));
          },
          child: ValueListenableBuilder<double>(
            valueListenable: widget.position,
            builder: (context, p, _) {
              // 0 at Home · 1 when a side page is parked with the peek ·
              // 2 when that side page has expanded to full-screen.
              final t = (p - 2).abs();
              final t1 = t.clamp(0.0, 1.0);
              final expand = (t - 1).clamp(0.0, 1.0);
              // Home parks right of Discover, left of Messages.
              final dir = p < 2 ? 1.0 : -1.0;
              final scale = 1.0 - (1.0 - _peekScale) * t1;
              final tx = dir * w * (_peekShift * t1 + _expandShift * expand);
              // The card scales down but its corners must READ as the same
              // radius as the full-screen card (demo peek stays round) —
              // compensate the layout radius for the visual scale.
              final vRadius = lerpDouble(_cardRadius, 36, t1)!;
              final radius = vRadius / scale;
              final ghostRadius = vRadius / (scale * 0.9);
              // Centred scaling would drop the parked card too low — lift it
              // so its top sits [_peekTopGap] below the deck top (demo).
              final ty = t1 * (_peekTopGap - (1.0 - scale) / 2.0 * c.maxHeight);
              // The ghost fades in late so it never flashes mid-drag.
              final ghostOpacity = ((t1 - 0.35) / 0.65).clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Backdrop behind every card — fills the corner notches.
                  // Every deck layer is keyed: the Stack's child list changes
                  // as layers toggle, and without keys Flutter's positional
                  // child matching would hand the Home element to a side page
                  // and remount Home (re-listening its single-listener
                  // streams → "Stream has already been listened to").
                  Positioned.fill(
                    key: const ValueKey('deck-backdrop'),
                    child: ColoredBox(
                      color: widget.immersive && t < 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  // Side pages are REVEALED under the Home card: they wait at
                  // their parked position (small parallax offset, ghosted)
                  // while the Home card does the full drag travel (demo
                  // f0012/f0058 — the incoming page barely moves and fades
                  // from ~half strength to solid as the card slides away).
                  if (p < 2)
                    Positioned(
                      key: const ValueKey('deck-discover'),
                      top: 0,
                      bottom: 0,
                      width: w,
                      left: -w * _kSideParallax * (p - 1).clamp(0.0, 1.0),
                      child: Opacity(
                        opacity: 1.0 - _sideFade * (p - 1).clamp(0.0, 1.0),
                        child: _frame(
                          widget.discoverBuilder((1 - p).clamp(0.0, 1.0)),
                          (1 - p).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  if (p > 2)
                    Positioned(
                      key: const ValueKey('deck-messages'),
                      top: 0,
                      bottom: 0,
                      width: w,
                      left: w * _kSideParallax * (3 - p).clamp(0.0, 1.0),
                      child: Opacity(
                        opacity: 1.0 - _sideFade * (3 - p).clamp(0.0, 1.0),
                        child: _frame(
                          widget.messagesBuilder((p - 3).clamp(0.0, 1.0)),
                          (p - 3).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  // Grey "far page" ghost — the deck's depth cue, peeking out
                  // from behind the Home card toward the screen centre.
                  if (ghostOpacity > 0)
                    Positioned.fill(
                      key: const ValueKey('deck-ghost'),
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: ghostOpacity,
                          child: Transform.translate(
                            offset: Offset(tx - dir * w * _ghostShift * t1, ty),
                            child: Transform.scale(
                              scale: scale * 0.9,
                              child: DecoratedBox(
                                // Figma "Rectangle 3593": #ACACAC at 50%,
                                // radius 36 — a translucent grey slab with
                                // no shadow of its own.
                                decoration: BoxDecoration(
                                  color: const Color(0x80ACACAC),
                                  borderRadius: BorderRadius.circular(
                                    ghostRadius,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Home — always the frontmost card. Parked as the peek it
                  // absorbs its own controls; a tap brings the deck Home.
                  Positioned.fill(
                    key: const ValueKey('deck-home'),
                    child: Transform.translate(
                      offset: Offset(tx, ty),
                      child: Transform.scale(
                        scale: scale,
                        child: GestureDetector(
                          onTap: t1 > 0.5 ? widget.onHomeTap : null,
                          child: AbsorbPointer(
                            absorbing: t1 > 0.15,
                            child: DecoratedBox(
                              // Card chrome (radius + shadow) exists only
                              // while carding — at rest the page is flat and
                              // flush with the top.
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  radius * t1,
                                ),
                                boxShadow: t1 > 0.01
                                    ? _cardShadow
                                    : const <BoxShadow>[],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  radius * t1,
                                ),
                                child: widget.home,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The side pages' titles ride ABOVE the deck so each is a
                  // single widget for its whole life — ghost in the Home
                  // strip, then travelling into its page — instead of one
                  // copy on the card being swapped for another on the page.
                  _DeckTitle(
                    key: const ValueKey('deck-title-discover'),
                    title: 'Discover',
                    homeTitle: widget.homeTitle,
                    chevron: _SideChevron.right,
                    reveal: (2 - p).clamp(0.0, 1.0),
                    expand: (1 - p).clamp(0.0, 1.0),
                    peekInsetFrac: _kDiscoverPeekInset,
                    deck: c.biggest,
                    homeShift: Offset(tx, ty),
                    homeScale: scale,
                    onExpand: widget.onExpandDiscover,
                  ),
                  _DeckTitle(
                    key: const ValueKey('deck-title-messages'),
                    title: 'Messages',
                    homeTitle: widget.homeTitle,
                    chevron: _SideChevron.left,
                    reveal: (p - 2).clamp(0.0, 1.0),
                    expand: (p - 3).clamp(0.0, 1.0),
                    peekInsetFrac: _kMessagesPeekInset,
                    deck: c.biggest,
                    homeShift: Offset(tx, ty),
                    homeScale: scale,
                    onExpand: widget.onExpandMessages,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Frame for the side pages: rounded top corners + shadow while parked /
  /// mid-transition, flattening to a plain full-bleed page at full screen.
  Widget _frame(Widget child, double expand) {
    final r = Radius.circular(_cardRadius * (1.0 - expand));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: r),
        boxShadow: expand > 0.99 ? const <BoxShadow>[] : _cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: r),
        child: child,
      ),
    );
  }
}

// ─── Home card ────────────────────────────────────────────────────────────────

/// The Home hub card: the shared header + its own big title sitting on the
/// white (or, mid-session, black) card top, over the Home/Meet gradient body.
/// The neighbour titles that flank it belong to the deck ([_DeckTitle]).
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.immersive,
    required this.active,
    required this.sessionState,
    required this.photoPath,
    required this.pendingCount,
    required this.onIncognito,
    required this.onPrev,
    required this.onNext,
    required this.onStart,
    required this.onEnd,
    required this.onGear,
    required this.onPersonTap,
    required this.onOpenSheet,
  });

  final bool immersive;
  final bool active;
  final SessionState sessionState;
  final String? photoPath;
  final Stream<int> pendingCount;
  final ValueChanged<bool> onIncognito;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onGear;
  final void Function(NearbyPeer) onPersonTap;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: immersive ? Colors.black : Colors.white,
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AppServices.I.settings.incognitoScan,
            builder: (context, incognito, _) => _SharedHeader(
              immersive: immersive,
              incognito: incognito,
              // Advertising can't be hot-restarted mid-session, so the
              // visibility toggle is locked while active to avoid a false
              // "they can't see you" confirmation (finding [17]).
              sessionActive: active,
              onIncognito: onIncognito,
              onPrev: onPrev,
              onNext: onNext,
            ),
          ),
          _PageTitleStrip(
            title: active ? 'Meet' : 'Home',
            immersive: immersive,
          ),
          Expanded(
            child: Stack(
              children: [
                // Stacked-deck depth cue: a light card peeking above the
                // gradient card, inset from both sides. Figma "Rectangle
                // 3593" — 345 wide at left 24, radius 36, #E8EAF2.
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: immersive
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE8EAF2),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _DiscoverCard(
                    photoPath: photoPath,
                    sessionState: sessionState,
                    pendingCount: pendingCount,
                    onStart: onStart,
                    onEnd: onEnd,
                    onGear: onGear,
                    onPersonTap: onPersonTap,
                    onOpenSheet: onOpenSheet,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Side cards (Discover / Messages) ────────────────────────────────────────

/// Which side the single "back to Home" chevron sits on / points toward.
enum _SideChevron { left, right }

/// A side page card. Parked beside the Home peek (`expand` 0) it cedes the
/// peek side of the screen to the stack — body inset away from it. Expanded
/// (`expand` 1) it is a true full-screen page.
///
/// Its big title is NOT here: it lives in [_DeckTitle], above the whole deck,
/// so the same widget can travel from the Home strip into this page's title
/// slot. The header still reserves the room the title lands in.
class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.chevron,
    required this.expand,
    required this.onBack,
    required this.child,
    this.peekInsetFrac = _kMessagesPeekInset,
    this.trailing,
  });

  final _SideChevron chevron;

  /// 0 = parked layout · 1 = full-screen layout (continuous mid-animation).
  final double expand;
  final VoidCallback onBack;
  final Widget child;

  /// Fraction of the width the parked layout cedes to the Home peek stack
  /// (measured from the demo — slightly wider on Messages than Discover).
  final double peekInsetFrac;

  /// Optional title-row action (design: Discover's list/grid toggle),
  /// shown only once the page has expanded to full screen.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final inset = c.maxWidth * peekInsetFrac * (1.0 - expand);
        final peekRight = chevron == _SideChevron.right;
        return ColoredBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SideHeader(
                chevron: chevron,
                expand: expand,
                onBack: onBack,
                trailing: trailing,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: peekRight ? 0 : inset,
                    right: peekRight ? inset : 0,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The side page's chrome — chevrons and the optional title-row action. The
/// title itself is [_DeckTitle]; this header only reserves the height it lands
/// in (parked: a tall band with the 43pt title low in it — Figma cap top ~231;
/// full: the compact `‹ Title` app-bar row).
class _SideHeader extends StatelessWidget {
  const _SideHeader({
    required this.chevron,
    required this.expand,
    required this.onBack,
    this.trailing,
  });

  final _SideChevron chevron;
  final double expand;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final e = expand;
    // Discover's parked chevron sits right and hands over to a left one as the
    // page fills the screen; Messages always has the left one.
    final left = chevron == _SideChevron.left;

    return SizedBox(
      height: lerpDouble(228, 50, e)!,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left back chevron: always present on the Messages side; on the
          // Discover side it fades in as the page expands.
          Positioned(
            // The 48pt icon box centres its glyph at 24; the compact title
            // centres at ~19 — lift the chevron so both align at full.
            top: lerpDouble(0, -5, e)!,
            left: 0,
            child: Opacity(
              opacity: left ? 1.0 : e,
              child: IgnorePointer(
                ignoring: !left && e < 0.5,
                child: IconButton(
                  onPressed: onBack,
                  iconSize: 22,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.brandRed,
                  ),
                ),
              ),
            ),
          ),
          // Right forward chevron (Discover parked) — fades out on expand.
          if (!left)
            Positioned(
              top: 0,
              right: 0,
              child: Opacity(
                opacity: 1.0 - e,
                child: IgnorePointer(
                  ignoring: e > 0.5,
                  child: IconButton(
                    onPressed: onBack,
                    iconSize: 22,
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.brandRed,
                    ),
                  ),
                ),
              ),
            ),
          if (trailing != null)
            Positioned(
              top: lerpDouble(0, 3, e)!,
              right: 12,
              child: Opacity(
                opacity: e,
                child: IgnorePointer(ignoring: e < 0.5, child: trailing),
              ),
            ),
        ],
      ),
    );
  }
}

/// A side page's big title — hoisted out of BOTH the Home card's title strip
/// and the page itself so that it is one widget the whole way, absolutely
/// positioned over the deck and moved as you swipe.
///
/// It starts as the grey ghost flanking "Home" in the strip, and travels into
/// its page's own title slot as the page is revealed, darkening from grey and
/// growing to 43pt late in the trip (demo f0002→f0014). While its page is away
/// it keeps the Home card's grip and rides off-screen with it — which is what
/// the far ghost does in the demo (f0004: "Mes…" leaves with the card).
class _DeckTitle extends StatelessWidget {
  const _DeckTitle({
    super.key,
    required this.title,
    required this.homeTitle,
    required this.chevron,
    required this.reveal,
    required this.expand,
    required this.peekInsetFrac,
    required this.deck,
    required this.homeShift,
    required this.homeScale,
    required this.onExpand,
  });

  final String title;

  /// The centre title this one flanks — its width decides the ghost slot.
  final String homeTitle;

  /// Which side of the deck this page lives on — Discover's ghost flanks
  /// "Home" on the left, Messages' on the right.
  final _SideChevron chevron;

  /// 0 = still the ghost in the Home strip · 1 = arrived in the page's slot.
  final double reveal;

  /// 0 = parked page layout · 1 = full-screen `‹ Title` app-bar row.
  final double expand;

  /// Width fraction the parked page cedes to the Home peek stack.
  final double peekInsetFrac;

  /// Deck size — every slot below is in deck (screen) coordinates.
  final Size deck;

  /// The Home card's current transform, so a ghost still owned by that card
  /// tracks it exactly.
  final Offset homeShift;
  final double homeScale;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final left = chevron == _SideChevron.left; // Messages
    final t = reveal.clamp(0.0, 1.0);
    final e = expand.clamp(0.0, 1.0);

    // Ghost and page titles are the same 42.92 face — only the ink changes on
    // the way in, and it lands late in the trip (demo f0010→f0014). The size
    // step happens later still, when the page goes full-screen.
    final ink = Curves.easeIn.transform(((t - 0.45) / 0.5).clamp(0.0, 1.0));
    final style = _titleStyle(
      size: lerpDouble(_kTitleSize, _kFullTitleSize, e)!,
      color: Color.lerp(
        Color.lerp(_kGhostTitleColor, Colors.black, ink)!,
        Colors.black,
        e,
      )!,
    );
    // Both slots anchor the text box, so it has to be measured at the size it
    // currently is — and the ghost slot also needs the centre title's width,
    // because Figma lays the three out as one row with a fixed gap.
    final metrics = _titleMetrics(
      context,
      title,
      style,
      lerpDouble(_kPageTitleCapTop, _kFullTitleCapTop, e)!,
    );
    final ghostMetrics = _titleMetrics(context, title, style, _kTitleCapTop);
    final homeWidth = _titleMetrics(
      context,
      homeTitle,
      style,
      _kTitleCapTop,
    ).size.width;

    // Ghost slot: flanking "Home" in the strip, on a settled Home card.
    final homeLeft = (deck.width - homeWidth) / 2;
    final ghost = Offset(
      left
          ? homeLeft + homeWidth + _kTitleGap
          : homeLeft - _kTitleGap - ghostMetrics.size.width,
      ghostMetrics.top,
    );
    // While the page is away the ghost belongs to the Home card and rides it;
    // that grip lets go quickly once the page starts coming in, so the title
    // stays put as the card slides on (demo f0002→f0004).
    final grip = (1.0 - t) * (1.0 - t) * (1.0 - t);
    final centre = deck.center(Offset.zero);
    final held = Offset.lerp(
      ghost,
      centre + (ghost - centre) * homeScale + homeShift,
      grip,
    )!;

    // Page slot: low on the parked page, then the compact app-bar row.
    final inset = deck.width * peekInsetFrac * (1.0 - e);
    final slot = Offset(
      lerpDouble(
        left ? inset + _kPageTitleLeft : _kPageTitleLeft,
        _kFullTitleLeft,
        e,
      )!,
      metrics.top,
    );

    final at = Offset.lerp(held, slot, t)!;
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: GestureDetector(
        // Tap the arrived title to take the page full-screen; while it is
        // still a ghost on the Home card the deck owns the gesture.
        onTap: t > 0.5 && e < 0.5 ? onExpand : null,
        child: Text(
          title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: style,
        ),
      ),
    );
  }
}

// ─── Shared header ───────────────────────────────────────────────────────────

class _SharedHeader extends StatelessWidget {
  const _SharedHeader({
    required this.immersive,
    required this.incognito,
    required this.sessionActive,
    required this.onIncognito,
    required this.onPrev,
    required this.onNext,
  });

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
      // Stack, not Row+Expanded: the trailing cluster (switch + gap + arrow) is
      // wider than the leading arrow, so centring the wordmark in the leftover
      // space parked it left of the card's true centre, as the demo doesn't.
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              _ArrowButton(
                icon: Icons.arrow_back_ios_new_rounded,
                enabled: true,
                onTap: onPrev,
              ),
              const Spacer(),
              _IncognitoSwitch(
                value: incognito,
                immersive: immersive,
                enabled: !sessionActive,
                onChanged: onIncognito,
              ),
              const SizedBox(width: 4),
              _ArrowButton(
                icon: Icons.arrow_forward_ios_rounded,
                enabled: true,
                onTap: onNext,
              ),
            ],
          ),
          const MetafterLogo(
            form: MetafterLogoForm.wordmark,
            variant: MetafterLogoVariant.red,
            height: 18,
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

/// The Home card's own big title. The neighbouring "…over" / "Mes…" ghosts
/// that flank it are NOT here — they are [_DeckTitle]s belonging to the side
/// pages, which travel out of this band as their page is revealed. This one
/// simply rides the card into its peek.
class _PageTitleStrip extends StatelessWidget {
  const _PageTitleStrip({required this.title, required this.immersive});

  final String title;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final style = _titleStyle(
      size: _kTitleSize,
      color: immersive ? Colors.white : Colors.black,
    );
    // Figma anchors the title by cap top (146 absolute); the strip runs on to
    // the content top (216) so the design's 39pt of air below it is real
    // layout, not slack in a centred box.
    final metrics = _titleMetrics(context, title, style, _kTitleCapTop);
    return SizedBox(
      height: _kTitleStripHeight,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(top: metrics.top - _kSharedHeaderHeight),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: style,
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

  // Sampled from the demo (f0001): essentially pure black through the top
  // quarter, warming through wine tones to a deep crimson — noticeably
  // cooler than brandRed, which stays the accent/CTA color only.
  static const _idleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    colors: [
      Colors.black,
      Color(0xFF0E0E0E),
      Color(0xFF390F16),
      Color(0xFF8A0E28),
      Color(0xFFD90E33),
    ],
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
            // A2: red ⇄ green gradient cross-fade (~600 ms). Rounded top so the
            // gradient reads as a card sitting below the white header zone.
            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: active ? _meetGradient : _idleGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: active
                  ? _buildActive(
                      context,
                      sessionState as SessionActive,
                      pending,
                      reduceMotion,
                    )
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
    // Scroll-safe: on very short viewports the fixed spacings exceed the
    // card, so the column clamps into a scrollable instead of overflowing.
    // At phone heights the scrollview has no extent and is inert.
    final column = Column(
      children: [
        // Figma: the avatar sits 60 below the card top and its cap-to-cap
        // gaps below are 69 (headline) and 17 (subtitle) — the old 26/6 read
        // as cramped because they were box gaps, not cap gaps.
        const SizedBox(height: 60),
        ValueListenableBuilder<MoodRing>(
          valueListenable: settings.mood,
          builder: (context, mood, _) => _CenterAvatar(
            photoPath: photoPath,
            ringColor: mood.color,
            onGear: onGear,
          ),
        ),
        const SizedBox(height: 69),
        _CapText('You are not discoverable', style: _kCardHeadlineStyle),
        const SizedBox(height: 17),
        _CapText(
          'Tap to connect with people nearby',
          style: _kCardBodyStyle,
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _LetsGoButton(
            label: starting ? 'Starting…' : 'Let’s Go!',
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
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(child: column),
        ),
      ),
    );
  }

  Widget _buildActive(
    BuildContext context,
    SessionActive state,
    int pending,
    bool reduceMotion,
  ) {
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
        _CapText(
          state.incognito
              ? 'You are in incognito mode'
              : 'You are discoverable',
          style: _kCardHeadlineStyle,
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
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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

class _MeetRadarState extends State<_MeetRadar> with TickerProviderStateMixin {
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
  ///
  /// The base radius must clear the centre avatar: it is 107.68 wide and
  /// painted on top of the bubbles, so the old 0.30 base parked a very close
  /// peer (≈64-wide bubble, plus its distance chip) underneath it, invisible.
  /// 0.70 keeps even a zero-distance bubble — chip included — orbiting outside
  /// the avatar's edge at every angle.
  Alignment _alignmentFor(NearbyPeer p) {
    final angle = (p.displayKey.hashCode % 360) * math.pi / 180.0;
    final frac = (p.meters / math.max(widget.maxMeters, 0.1)).clamp(0.0, 1.0);
    final r = 0.70 + 0.26 * frac;
    return Alignment(math.cos(angle) * r, math.sin(angle) * r * 0.85);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _RingsPainter())),
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
      child: _floating(
        peer,
        _NearbyAvatar(
          peer: peer,
          onTap: peer.card == null ? null : () => widget.onPersonTap(peer),
        ),
      ),
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
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white54,
                  size: 28,
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

  /// Figma "Ellipse 1": 107.68 across, 3pt inner ring, and a soft blue-grey
  /// drop shadow (0 / 12.91, blur 25.81, #4F5174 at 25%).
  static const double diameter = 107.68;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // The whole avatar opens settings, same as the gear: the 24pt disc
        // alone was far below the 48pt minimum touch target and users read
        // the avatar itself as "my profile → settings" anyway.
        GestureDetector(
          onTap: onGear,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 3),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x404F5174),
                  offset: Offset(0, 12.91),
                  blurRadius: 25.81,
                ),
              ],
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
        ),
        // 44pt hit box around the visually-unchanged 24 disc (Figma: a 24 blue
        // disc carrying an 18.86 × 20 gear at 1.5pt). Positioned so the disc
        // centre stays exactly where the old margin put it.
        Positioned(
          right: -6,
          bottom: -6,
          child: GestureDetector(
            onTap: onGear,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.discoverActive,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child:
                          Icon(Icons.settings, size: 19, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Text laid out on its CAP box, so the space above and below it in a column
/// is the space the design specifies. Figma trims every one of these to cap
/// height, and the font's line box is 8-12pt taller than that — stacking the
/// raw [Text] silently pads each gap by that leftover.
class _CapText extends StatelessWidget {
  const _CapText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final metrics = _titleMetrics(context, text, style, 0);
    return SizedBox(
      width: double.infinity,
      height: style.fontSize! * _kCapHeightRatio,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: metrics.top,
            left: 0,
            right: 0,
            child: Text(text, textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
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

/// The design's dropdown chevron: a 16-wide V drawn at 1.5pt. Material's
/// `keyboard_arrow_down` is a 2pt stroke on a 24 box, which reads far heavier
/// than the hairline in the design.
class _ChevronDown extends StatelessWidget {
  const _ChevronDown();

  static const double _width = 16;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      // The value and the chevron are two elements in the design, not one
      // glyph — they need air between them.
      padding: EdgeInsets.only(left: 8),
      child: CustomPaint(
        size: Size(_width, _width * 0.5),
        painter: _ChevronDownPainter(Colors.white),
      ),
    );
  }
}

class _ChevronDownPainter extends CustomPainter {
  const _ChevronDownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.08, h * 0.28)
        ..lineTo(w * 0.5, h * 0.76)
        ..lineTo(w * 0.92, h * 0.28),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChevronDownPainter oldDelegate) =>
      oldDelegate.color != color;
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
    // DropdownButton REPLACES the ambient DefaultTextStyle with its `style`,
    // so the brand font family must be re-stated or the value falls back to
    // the platform font.
    final family = DefaultTextStyle.of(context).style.fontFamily;
    return Row(
      children: [
        Expanded(child: Text(label, style: _kCardBodyStyle)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            // The button is as wide as the LONGEST option ('30 min'), so the
            // default centerStart alignment leaves the current value floating
            // left of the chevron instead of flush against it.
            alignment: AlignmentDirectional.centerEnd,
            dropdownColor: const Color(0xFF222222),
            icon: const _ChevronDown(),
            style: TextStyle(
              fontFamily: family,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
            items: items
                .map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(
                      o,
                      style: TextStyle(
                        fontFamily: family,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
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
  late final Stream<List<ConnectionRequest>> _requests = AppServices.I.requests
      .watchIncomingPending();

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
        ((media.size.height - media.padding.top - 8) / media.size.height).clamp(
          0.6,
          0.94,
        );

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
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final request = items[i];
                          return _SheetRequestTile(
                            request: request,
                            busy: _busy.contains(request.id),
                            onAccept: () => _run(request, widget.onAccept),
                            onDecline: () => _run(request, widget.onDecline),
                          );
                        }, childCount: items.length),
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
                Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (card.designation.isNotEmpty)
                  Text(
                    card.designation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                if (card.company.isNotEmpty)
                  Text(
                    card.company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B6B6B),
        ),
      ),
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
            // Track proportions taken from the demo header: a squatter pill
            // (~1.7:1) than Material's default switch, so the knob nearly
            // fills the height and the travel is short.
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Align(
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Center(
                  child: CustomPaint(
                    size: Size(16, 16),
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
      Offset(w * 0.43, h * 0.74),
      Offset(w * 0.57, h * 0.74),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _IncognitoHatPainter oldDelegate) => false;
}
