import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/mock_data.dart';
import '../../../../core/domain/models.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/peer_avatar.dart';
import '../widgets/invite_note_dialog.dart';
import 'nearby_person_profile_screen.dart';

/// Discover — "People You Crossed Paths" (DESIGN_SPEC §6).
///
/// Everything on this page comes from the local encounters ledger
/// ([AppServices.I.encounters]); the date band + calendar picker jump
/// between days that actually have encounters.
class DiscoverHistoryScreen extends StatefulWidget {
  const DiscoverHistoryScreen({
    super.key,
    this.embedded = false,
    this.fullChrome,
    this.gridMode,
  });

  /// When `true`, render the body only (no Scaffold/AppBar) so the screen can
  /// be hosted inside the swipeable [HomeShell] under its shared header.
  final bool embedded;

  /// Deck hosting only: reports `true` while the page is expanded to full
  /// screen, which unlocks the standalone chrome (view toggle + calendar,
  /// per the design's full Discover). `null` = standalone (always shown).
  final ValueListenable<bool>? fullChrome;

  /// List ⟷ card-deck view state. Deck hosting passes the notifier that its
  /// header toggle drives; standalone owns its own.
  final ValueNotifier<bool>? gridMode;

  @override
  State<DiscoverHistoryScreen> createState() => _DiscoverHistoryScreenState();
}

class _DiscoverHistoryScreenState extends State<DiscoverHistoryScreen> {
  late final ValueNotifier<bool> _gridMode =
      widget.gridMode ?? ValueNotifier<bool>(false);
  late DateTime _day;
  late Stream<List<Encounter>> _stream;
  int _page = 0;

  bool get _isToday {
    final now = DateTime.now();
    return _day.year == now.year &&
        _day.month == now.month &&
        _day.day == now.day;
  }

  bool get _chromeVisible =>
      !widget.embedded || (widget.fullChrome?.value ?? false);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _stream = AppServices.I.encounters.watchDay(_day);
    widget.fullChrome?.addListener(_onChrome);
  }

  void _onChrome() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.fullChrome?.removeListener(_onChrome);
    if (widget.gridMode == null) _gridMode.dispose();
    super.dispose();
  }

  void _setDay(DateTime day) {
    setState(() {
      _day = DateTime(day.year, day.month, day.day);
      _stream = AppServices.I.encounters.watchDay(_day);
      _page = 0;
    });
  }

  Future<void> _pickDay() async {
    final days = await AppServices.I.encounters.daysWithEncounters();
    if (!mounted) return;
    final allowed = <DateTime>{
      for (final d in days) DateTime(d.year, d.month, d.day),
      _day,
    };
    final sorted = allowed.toList()..sort();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: sorted.first,
      lastDate: sorted.last,
      selectableDayPredicate: (d) =>
          allowed.contains(DateTime(d.year, d.month, d.day)),
    );
    if (picked != null) _setDay(picked);
  }

  Future<void> _connect(Encounter e) async {
    // Demo sample rows have no real peer behind them.
    if (e.id.startsWith(MockData.demoPrefix)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Sample profile — demo content'),
        ),
      );
      return;
    }
    await sendConnectRequestFlow(context, toCard: e.card, encounterId: e.id);
  }

  void _openProfile(Encounter e) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NearbyPersonProfileScreen(
          card: e.card,
          encounterId: e.id,
          meters: e.meters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'People You Crossed Paths',
                  // Figma: Instrument Sans SemiBold 18 (also keeps a single
                  // line when parked beside the Home peek).
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              // Parked in the deck the chrome stays minimal; the calendar
              // appears once the page is full-screen or standalone. (The
              // list/grid toggle lives on the title row, in the header.)
              if (_chromeVisible)
                // Compact (no 48pt tap-box inflation — it was pushing the
                // band and deck ~22pt below the design).
                GestureDetector(
                  onTap: _pickDay,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    // Figma: 24pt calendar (mdi:calendar) at 60% opacity.
                    child: Icon(
                      Icons.event_rounded,
                      color: Color(0x99000000),
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _pickDay,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            color: AppColors.brandRedSoft,
            // Figma: 52pt-tall band (393×52 Hug).
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              TimeFormat.dateBand(_day),
              // Figma: Instrument Sans Medium 16, #C60013.
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFC60013),
              ),
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _gridMode,
            builder: (context, gridOn, _) => ValueListenableBuilder<bool>(
              valueListenable: AppServices.I.settings.use24hTime,
              builder: (context, use24h, _) => ValueListenableBuilder<bool>(
                valueListenable: MockData.demoContent,
                builder: (context, demo, _) => StreamBuilder<List<Encounter>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    var rows = snapshot.data;
                    if (rows == null) return const SizedBox.shrink();
                    // Demo content: prepend the prototype's sample timeline
                    // on today's page (display only — never persisted).
                    if (demo && _isToday) {
                      rows = [...MockData.demoEncounters(), ...rows];
                    }
                    if (rows.isEmpty) return const _EmptyState();
                    // The grid/carousel view needs the full-screen chrome.
                    final grid = gridOn && _chromeVisible;
                    return grid
                        ? _buildCarousel(rows, use24h)
                        : _buildList(rows, use24h);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) return ColoredBox(color: Colors.white, child: body);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DiscoverViewToggle(gridMode: _gridMode),
          ),
        ],
      ),
      body: body,
    );
  }

  // ── List view (§6.2) ──────────────────────────────────────────────────────

  Widget _buildList(List<Encounter> rows, bool use24h) {
    return ListView.separated(
      // Explicit padding replaces the ListView's automatic safe-area inset,
      // so the home-indicator area must be re-added — otherwise the last row
      // hides behind the bottom bar (unlike the design).
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: rows.length,
      // Whitespace-only separation, like the demo timeline.
      separatorBuilder: (_, _) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final e = rows[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: LayoutBuilder(
            builder: (context, c) {
              // Parked beside the Home peek the row is too narrow for the
              // Connect pill (and the design's parked timeline shows none) —
              // it appears once the page expands toward full width. Rows stay
              // tappable either way (profile view carries its own Connect).
              final showPill = c.maxWidth >= 300;
              return Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      TimeFormat.clock(e.lastSeen, use24h: use24h),
                      // Figma: Instrument Sans Medium 12, #000.
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openProfile(e),
                    child: PeerAvatar(
                      card: e.card,
                      size: 56,
                      showVerified: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openProfile(e),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.card.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // Figma: Instrument Sans Medium 14, #000.
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            e.card.designation.isNotEmpty
                                ? e.card.designation
                                : e.card.role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xB3000000),
                            ),
                          ),
                          Text(
                            e.card.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xB3000000),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showPill) ...[
                    const SizedBox(width: 8),
                    _ConnectPill(encounter: e, onConnect: () => _connect(e)),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ── Card carousel (§6.1, A9) ──────────────────────────────────────────────

  Widget _buildCarousel(List<Encounter> rows, bool use24h) {
    final front = _page % rows.length;
    final dotCount = rows.length < 3 ? rows.length : 3;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Time of the front card rides the left rail — RIGHT-anchored
              // at a fixed clearance so the gap to the deep slab stays
              // constant for any time string (design: time right ~61, slab
              // left ~65).
              Container(
                width: 88,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 32),
                child: Text(
                  TimeFormat.clock(rows[front].lastSeen, use24h: use24h),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: _SwipeDeck(
                  key: ValueKey('deck-${rows.length}'),
                  rows: rows,
                  front: front,
                  cardBuilder: _buildCard,
                  onFrontChanged: (i) => setState(() => _page = i),
                ),
              ),
            ],
          ),
        ),
        // Fixed three-dot indicator cycling with the deck (design).
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < dotCount; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == front % dotCount
                        ? const Color(0xFFED2839)
                        : const Color(0xFFF3B7BC),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Encounter e, double veil) {
    return GestureDetector(
      onTap: () => _openProfile(e),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE32227)),
        ),
        // Receding cards grey out into the design's stack slabs.
        foregroundDecoration: BoxDecoration(
          color: const Color(0xFFEFE1E1).withValues(alpha: veil),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            // Red wash bleeding down from the card's top edge, with the
            // blue-ring avatar overlapping it (design).
            SizedBox(
              height: 164,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 126,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.22, 1.0],
                          colors: [
                            Color(0xFFBF1E22),
                            Color(0xFFE32227),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 38),
                      child: PeerAvatar(
                        card: e.card,
                        size: 114,
                        ringColor: const Color(0xFF119BFB),
                        ringWidth: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                e.card.titleLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xB3000000)),
              ),
            ),
            // Figma: intro starts at 249 — a 33pt gap below the subtitle.
            const SizedBox(height: 33),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                e.card.intro,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                // Figma: Instrument Sans Regular 14, LH 145%, #000 @70%.
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xB3000000),
                  height: 1.45,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 34,
              child: e.sentRequestId != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Requested',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: () => _connect(e),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFED2839),
                        minimumSize: const Size(87, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            // Figma: Connect sits 33pt off the card's bottom edge.
            const SizedBox(height: 33),
          ],
        ),
      ),
    );
  }
}

// ─── Stacked swipe deck (design: real stacked cards) ─────────────────────────

/// A physical stacked-card deck: the front card can be thrown off with a
/// LEFT or RIGHT swipe (tilting like a real card); the two shaded cards
/// behind pull forward one level as it leaves, the next one un-veiling into
/// full view. Wraps around, so the deck is endless.
class _SwipeDeck extends StatefulWidget {
  const _SwipeDeck({
    super.key,
    required this.rows,
    required this.front,
    required this.cardBuilder,
    required this.onFrontChanged,
  });

  final List<Encounter> rows;
  final int front;
  final Widget Function(Encounter e, double veil) cardBuilder;
  final ValueChanged<int> onFrontChanged;

  @override
  State<_SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<_SwipeDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  /// Front card's horizontal displacement (finger or animation driven).
  double _x = 0;
  Animation<double>? _slide;
  bool _committing = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_anim.isAnimating) return;
    setState(() => _x += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d, double w) {
    if (_anim.isAnimating) return;
    final v = d.primaryVelocity ?? 0;
    final shouldThrow =
        widget.rows.length > 1 && (_x.abs() > w * 0.35 || v.abs() > 700);
    final target = shouldThrow ? (_x >= 0 ? w * 1.3 : -w * 1.3) : 0.0;
    _committing = shouldThrow;
    _slide = Tween<double>(
      begin: _x,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim
      ..reset()
      ..addListener(_tick)
      ..forward().whenComplete(() {
        _anim.removeListener(_tick);
        if (!mounted) return;
        if (_committing) {
          _committing = false;
          _x = 0;
          widget.onFrontChanged((widget.front + 1) % widget.rows.length);
        }
        setState(() {});
      });
  }

  void _tick() => setState(() => _x = _slide!.value);

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final n = rows.length;
    return LayoutBuilder(
      builder: (context, c) {
        final cardW = c.maxWidth * 0.88;
        final cardH = (cardW * 1.5).clamp(0.0, c.maxHeight - 16.0);
        // How far the throw has progressed — pulls the stack forward.
        final reveal = (_x.abs() / (c.maxWidth * 0.6)).clamp(0.0, 1.0);

        // Design units scale with the card (Figma front card = 268×401).
        final kw = cardW / 268.0;
        final kh = cardH / 401.0;

        // Near slab = the NEXT card, veiled solid; it un-veils and slides
        // to the front as the top card is thrown (centre −44.5, scale .89
        // ≈ Figma's 235×360 slab).
        Widget nearCard() {
          final t = reveal;
          final index = (widget.front + 1) % n;
          return Align(
            alignment: const Alignment(0, -0.13),
            child: Transform.translate(
              offset: Offset(_lerp(-44.5, 0.0, t) * kw, 0),
              child: Transform.scale(
                scale: _lerp(0.89, 1.0, t),
                child: SizedBox(
                  width: cardW,
                  height: cardH,
                  child: IgnorePointer(
                    child: widget.cardBuilder(rows[index], 1.0 - t),
                  ),
                ),
              ),
            ),
          );
        }

        // Deep slab = a plain shape with the design's exact geometry
        // (235×308, centre −60.5, #E0E0E0 @50%, radius 36) — same WIDTH as
        // the near slab, shorter, one step further out. It morphs into the
        // near slab's geometry while the stack promotes.
        Widget deepSlab() {
          final t = reveal;
          return Align(
            alignment: const Alignment(0, -0.13),
            child: Transform.translate(
              offset: Offset(_lerp(-60.5, -44.5, t) * kw, 0),
              child: SizedBox(
                width: 235.0 * kw,
                height: _lerp(308.0, 360.0, t) * kh,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0x80E0E0E0),
                      const Color(0xFFEFE1E1),
                      t,
                    )!,
                    borderRadius: BorderRadius.circular(36 * kw),
                  ),
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: (d) => _onDragEnd(d, c.maxWidth),
          // Unclipped: the slabs overhang into the time rail (Figma: deep
          // slab left 65 / near 81, while the deck region starts at ~88).
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (n > 2) deepSlab(),
              if (n > 1) nearCard(),
              // Front card: rides the finger with a real-card tilt.
              Align(
                alignment: const Alignment(0, -0.13),
                child: Transform.translate(
                  offset: Offset(_x, 0),
                  child: Transform.rotate(
                    angle: _x / c.maxWidth * 0.12,
                    child: SizedBox(
                      width: cardW,
                      height: cardH,
                      child: widget.cardBuilder(rows[widget.front], 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Connect / Requested pill ─────────────────────────────────────────────────

class _ConnectPill extends StatelessWidget {
  const _ConnectPill({required this.encounter, required this.onConnect});

  final Encounter encounter;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    if (encounter.sentRequestId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Requested',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A8A8A),
          ),
        ),
      );
    }
    return FilledButton(
      onPressed: onConnect,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandRed,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        'Connect',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── List ⟷ card view toggle ─────────────────────────────────────────────────

/// List ⟷ card-deck view toggle, styled per the design: plain icons with a
/// hairline divider — hamburger list icon and four-square grid icon, the
/// active one red. Public so the deck header (HomeShell) can host it.
class DiscoverViewToggle extends StatelessWidget {
  const DiscoverViewToggle({super.key, required this.gridMode});

  final ValueNotifier<bool> gridMode;

  static const _active = Color(0xFFED2839);
  static const _inactive = Color(0xFFB0B0B0);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: gridMode,
      builder: (context, grid, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => gridMode.value = false,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.menu_rounded,
                size: 24,
                color: grid ? _inactive : _active,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0xFFDDDDDD),
          ),
          GestureDetector(
            onTap: () => gridMode.value = true,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.grid_view_rounded,
                size: 22,
                color: grid ? _active : _inactive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 56,
              color: AppColors.brandRed.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
            const Text(
              'No crossed paths yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Go say hi — people you meet nearby will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A8A8A),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
