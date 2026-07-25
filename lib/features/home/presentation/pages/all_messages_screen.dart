import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/mock_data.dart';
import '../../../../core/domain/models.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/peer_avatar.dart';
import 'chat_screen.dart';

/// Messages page (DESIGN_SPEC §9): live thread list backed by
/// `AppServices.I.messages`, with search, swipe-to-archive (A10) and a
/// collapsible Archived section at the bottom.
class AllMessagesScreen extends StatefulWidget {
  const AllMessagesScreen({
    super.key,
    this.embedded = false,
    this.searchQuery,
    this.rowSwipeEnabled,
  });

  /// When `true`, render the body only (no Scaffold/AppBar) so the screen can
  /// be hosted inside the swipeable [HomeShell] as a self-contained card.
  final bool embedded;

  /// Embedded search source. When provided (the Messages card's header search
  /// icon drives it), the list filters on this and the screen renders no search
  /// field of its own.
  final ValueListenable<String>? searchQuery;

  /// When provided (deck hosting), thread-row swipe-to-archive is armed only
  /// while this reports `true` — i.e. once the page is full-screen. Parked in
  /// the deck, a horizontal drag on a row must page the deck instead, so the
  /// Dismissibles stand down. `null` (standalone) = always armed.
  final ValueListenable<bool>? rowSwipeEnabled;

  @override
  State<AllMessagesScreen> createState() => _AllMessagesScreenState();
}

class _AllMessagesScreenState extends State<AllMessagesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  // Embedded (deck) search: the design puts the search icon on the "Chats"
  // row; tapping it opens an inline field bound to the shared header query.
  final _embSearchController = TextEditingController();
  bool _embSearchOpen = false;

  void _setEmbQuery(String v) {
    final q = widget.searchQuery;
    if (q is ValueNotifier<String>) q.value = v;
  }

  void _toggleEmbSearch() {
    setState(() {
      _embSearchOpen = !_embSearchOpen;
      if (!_embSearchOpen) {
        _embSearchController.clear();
        _setEmbQuery('');
      }
    });
  }

  // watch* streams are fresh single-listener streams — create once, keep for
  // the widget's lifetime so the StreamBuilders subscribe exactly once.
  late final Stream<List<ThreadSummary>> _chats;
  late final Stream<List<ThreadSummary>> _archived;

  @override
  void initState() {
    super.initState();
    _chats = AppServices.I.messages.watchThreads(archived: false);
    _archived = AppServices.I.messages.watchThreads(archived: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _embSearchController.dispose();
    super.dispose();
  }

  List<ThreadSummary> _filter(List<ThreadSummary> threads, String query) {
    if (query.isEmpty) return threads;
    final q = query.toLowerCase();
    return threads
        .where(
          (t) =>
              t.card.name.toLowerCase().contains(q) ||
              t.lastMessage.toLowerCase().contains(q),
        )
        .toList();
  }

  Widget _searchField() => Padding(
    padding: EdgeInsets.fromLTRB(20, widget.embedded ? 8 : 0, 20, 12),
    child: TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search messages…',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: Color(0xFFAAAAAA),
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFFAAAAAA),
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _body(String query) => ValueListenableBuilder<bool>(
    valueListenable: MockData.demoContent,
    builder: (context, demo, _) => StreamBuilder<List<ThreadSummary>>(
      stream: _chats,
      builder: (context, chatsSnap) => StreamBuilder<List<ThreadSummary>>(
        stream: _archived,
        builder: (context, archivedSnap) {
          // Demo content: prepend the prototype's sample chat list
          // (display only — never persisted).
          final chats = _filter([
            if (demo) ...MockData.demoThreads(),
            ...chatsSnap.data ?? const <ThreadSummary>[],
          ], query);
          final archived = _filter(archivedSnap.data ?? const [], query);

          if (chats.isEmpty && archived.isEmpty && !_embSearchOpen) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    query.isEmpty
                        ? 'No messages yet'
                        : 'No results for "$query"',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            );
          }

          final embSearchable = widget.embedded && widget.searchQuery != null;
          return ListView(
            children: [
              if (chats.isNotEmpty || _embSearchOpen) ...[
                // Design: the search icon rides the "Chats" row.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 8, 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chats',
                          // Figma: Instrument Sans SemiBold 18.
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (embSearchable)
                        IconButton(
                          onPressed: _toggleEmbSearch,
                          iconSize: 24,
                          icon: Icon(
                            _embSearchOpen
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_embSearchOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TextField(
                      controller: _embSearchController,
                      autofocus: true,
                      onChanged: _setEmbQuery,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search messages…',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFAAAAAA),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFFAAAAAA),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                if (chats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Text(
                      'No results',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
                    ),
                  ),
                // No divider between rows — the demo list separates rows
                // with whitespace only.
                for (final t in chats)
                  _ThreadRow(
                    thread: t,
                    archived: false,
                    swipeEnabled: widget.rowSwipeEnabled,
                  ),
              ],
              if (archived.isNotEmpty)
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: const Icon(
                    Icons.archive_outlined,
                    size: 22,
                    color: Color(0xFF8A8A8A),
                  ),
                  title: Text(
                    'Archived (${archived.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF555555),
                    ),
                  ),
                  children: [
                    for (final t in archived)
                      _ThreadRow(
                        thread: t,
                        archived: true,
                        swipeEnabled: widget.rowSwipeEnabled,
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Search lives in the Messages card header (HomeShell); filter on the
      // query it drives, and render no field of our own.
      final query = widget.searchQuery;
      return ColoredBox(
        color: Colors.white,
        child: query == null
            ? _body(_query)
            : ValueListenableBuilder<String>(
                valueListenable: query,
                builder: (context, q, _) => _body(q),
              ),
      );
    }

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
          'Messages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _searchField(),
        ),
      ),
      body: _body(_query),
    );
  }
}

// ─── Section label ───────────────────────────────────────────────────────────

// ─── Thread row ──────────────────────────────────────────────────────────────

/// Status-ring palette from the design (Ellipse 4 borders: blue / purple /
/// red). Demo rows use the prototype's exact per-person colors; real threads
/// get a stable pick so a peer's ring never changes between builds.
const List<Color> _statusRingPalette = [
  Color(0xFF2F80ED),
  Color(0xFF9B51E0),
  Color(0xFFED2839),
];

Color _statusRingColor(String peerSub) {
  if (peerSub.startsWith(MockData.demoPrefix)) {
    const bySuffix = {
      'p1': 0,
      'p2': 1,
      'p3': 2,
      'p4': 2,
      'p5': 0,
      'p6': 0,
      'p7': 1,
      'p8': 2,
    };
    final i = bySuffix[peerSub.substring(MockData.demoPrefix.length)];
    if (i != null) return _statusRingPalette[i];
  }
  var h = 0;
  for (final c in peerSub.codeUnits) {
    h = (h + c) % 0xFFFF;
  }
  return _statusRingPalette[h % _statusRingPalette.length];
}

class _ThreadRow extends StatefulWidget {
  const _ThreadRow({
    required this.thread,
    required this.archived,
    this.swipeEnabled,
  });

  final ThreadSummary thread;
  final bool archived;

  /// See [AllMessagesScreen.rowSwipeEnabled]; `null` = always armed.
  final ValueListenable<bool>? swipeEnabled;

  @override
  State<_ThreadRow> createState() => _ThreadRowState();
}

class _ThreadRowState extends State<_ThreadRow> {
  /// True while the row is mid swipe — the design lifts the sliding row onto
  /// a grey rounded panel while the detached action button shows behind it.
  bool _swiping = false;

  @override
  Widget build(BuildContext context) {
    final listenable = widget.swipeEnabled;
    if (listenable == null) return _row(context, true);
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, enabled, _) => _row(context, enabled),
    );
  }

  Widget _row(BuildContext context, bool swipeArmed) {
    final thread = widget.thread;
    final archived = widget.archived;
    final unread = thread.unreadCount > 0;

    return Dismissible(
      key: ValueKey('thread-${thread.peerSub}-$archived'),
      direction: swipeArmed
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onUpdate: (d) {
        final active = d.progress > 0.02;
        if (active != _swiping) setState(() => _swiping = active);
      },
      // A10: the Archive action; we archive via the repository and return
      // false so the row animates out through the stream update rather than
      // the dismissal itself.
      confirmDismiss: (_) async {
        await AppServices.I.messages.setArchived(thread.peerSub, !archived);
        return false;
      },
      // Design: a detached rounded action button with an icon over its
      // label, inset from the screen edge — not a full-bleed backdrop.
      background: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 108,
          margin: const EdgeInsets.fromLTRB(8, 5, 16, 5),
          decoration: BoxDecoration(
            color: archived ? const Color(0xFF119BFB) : const Color(0xFFED2839),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                archived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                archived ? 'Unarchive' : 'Archive',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _swiping ? const Color(0xFFF1F1F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // Demo sample rows have no real thread behind them.
            if (thread.peerSub.startsWith(MockData.demoPrefix)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 2),
                  content: Text('Sample chat — demo content'),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(peerSub: thread.peerSub),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Figma: 51pt avatar with a 15pt status ring (white fill,
                // 2pt colored border) sitting flush on its bottom-right.
                SizedBox(
                  width: 51,
                  height: 51,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PeerAvatar(
                        card: thread.card,
                        size: 51,
                        showVerified: true,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: _statusRingColor(thread.peerSub),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              thread.card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              // Figma: Instrument Sans Medium 14.
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Demo layout: "preview · 3h" on one line, the age
                      // trailing the (ellipsised) preview text.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              thread.lastFromMe
                                  ? 'You: ${thread.lastMessage}'
                                  : thread.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              // Figma: Instrument Sans Medium 12.
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: unread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: unread
                                    ? const Color(0xE0000000)
                                    : const Color(0xB3000000),
                              ),
                            ),
                          ),
                          Text(
                            '  ·  ${TimeFormat.relativeAge(thread.lastMessageAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xB3000000),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
