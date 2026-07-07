import 'package:flutter/material.dart';

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
  const DiscoverHistoryScreen({super.key, this.embedded = false});

  /// When `true`, render the body only (no Scaffold/AppBar) so the screen can
  /// be hosted inside the swipeable [HomeShell] under its shared header.
  final bool embedded;

  @override
  State<DiscoverHistoryScreen> createState() => _DiscoverHistoryScreenState();
}

class _DiscoverHistoryScreenState extends State<DiscoverHistoryScreen> {
  bool _grid = false;
  late DateTime _day;
  late Stream<List<Encounter>> _stream;
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _stream = AppServices.I.encounters.watchDay(_day);
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setDay(DateTime day) {
    setState(() {
      _day = DateTime(day.year, day.month, day.day);
      _stream = AppServices.I.encounters.watchDay(_day);
      _page = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
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
    await sendConnectRequestFlow(context, toCard: e.card, encounterId: e.id);
  }

  void _openProfile(Encounter e) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NearbyPersonProfileScreen(
        card: e.card,
        encounterId: e.id,
        meters: e.meters,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'People You Crossed Paths',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              _ViewToggle(
                grid: _grid,
                onChanged: (v) => setState(() => _grid = v),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined,
                    color: Colors.black, size: 22),
                onPressed: _pickDay,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: AppColors.brandRedSoft,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            TimeFormat.dateBand(_day),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.brandRed,
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: AppServices.I.settings.use24hTime,
            builder: (context, use24h, _) =>
                StreamBuilder<List<Encounter>>(
              stream: _stream,
              builder: (context, snapshot) {
                final rows = snapshot.data;
                if (rows == null) return const SizedBox.shrink();
                if (rows.isEmpty) return const _EmptyState();
                return _grid
                    ? _buildCarousel(rows, use24h)
                    : _buildList(rows, use24h);
              },
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }

  // ── List view (§6.2) ──────────────────────────────────────────────────────

  Widget _buildList(List<Encounter> rows, bool use24h) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(
          height: 1, indent: 148, endIndent: 20, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, index) {
        final e = rows[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  TimeFormat.clock(e.lastSeen, use24h: use24h),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openProfile(e),
                child:
                    PeerAvatar(card: e.card, size: 52, showVerified: true),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
                            fontSize: 13, color: Color(0xFF6B6B6B)),
                      ),
                      Text(
                        e.card.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B6B6B)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ConnectPill(encounter: e, onConnect: () => _connect(e)),
            ],
          ),
        );
      },
    );
  }

  // ── Card carousel (§6.1, A9) ──────────────────────────────────────────────

  Widget _buildCarousel(List<Encounter> rows, bool use24h) {
    final page = _page.clamp(0, rows.length - 1);
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: rows.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) =>
                _buildCard(rows[index], use24h),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < rows.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == page ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == page
                        ? AppColors.brandRed
                        : AppColors.brandRed.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Encounter e, bool use24h) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: GestureDetector(
        onTap: () => _openProfile(e),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppColors.brandRed.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandRed.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                TimeFormat.clock(e.lastSeen, use24h: use24h),
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
              ),
              const SizedBox(height: 12),
              PeerAvatar(card: e.card, size: 96, showVerified: true),
              const SizedBox(height: 14),
              Text(
                e.card.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                e.card.titleLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  e.card.intro,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ConnectPill(
                encounter: e,
                onConnect: () => _connect(e),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Connect / Requested pill ─────────────────────────────────────────────────

class _ConnectPill extends StatelessWidget {
  const _ConnectPill({
    required this.encounter,
    required this.onConnect,
    this.fullWidth = false,
  });

  final Encounter encounter;
  final VoidCallback onConnect;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (encounter.sentRequestId != null) {
      return Container(
        width: fullWidth ? double.infinity : null,
        alignment: fullWidth ? Alignment.center : null,
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
    final button = FilledButton(
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
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ─── List ⟷ card view toggle ─────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});
  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
              icon: Icons.view_agenda_outlined,
              selected: !grid,
              onTap: () => onChanged(false)),
          _segment(
              icon: Icons.grid_view_rounded,
              selected: grid,
              onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(
      {required IconData icon,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: selected ? AppColors.brandRed : const Color(0xFF8A8A8A)),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

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
            Icon(Icons.explore_outlined,
                size: 56, color: AppColors.brandRed.withValues(alpha: 0.35)),
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
