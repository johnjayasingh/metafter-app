import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    super.dispose();
  }

  List<ThreadSummary> _filter(List<ThreadSummary> threads, String query) {
    if (query.isEmpty) return threads;
    final q = query.toLowerCase();
    return threads
        .where((t) =>
            t.card.name.toLowerCase().contains(q) ||
            t.lastMessage.toLowerCase().contains(q))
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
            prefixIcon: const Icon(Icons.search_rounded,
                size: 20, color: Color(0xFFAAAAAA)),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFFAAAAAA)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );

  Widget _body(String query) => StreamBuilder<List<ThreadSummary>>(
        stream: _chats,
        builder: (context, chatsSnap) => StreamBuilder<List<ThreadSummary>>(
          stream: _archived,
          builder: (context, archivedSnap) {
            final chats = _filter(chatsSnap.data ?? const [], query);
            final archived = _filter(archivedSnap.data ?? const [], query);

            if (chats.isEmpty && archived.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      query.isEmpty
                          ? 'No messages yet'
                          : 'No results for "$query"',
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              children: [
                if (chats.isNotEmpty) ...[
                  const _SectionLabel('Chats'),
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
                    leading: const Icon(Icons.archive_outlined,
                        size: 22, color: Color(0xFF8A8A8A)),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            // Demo f0097: "Chats" is a large black sub-heading under the
            // page title, not a small grey caption.
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.black,
            ),
          ),
        ),
      );
}

// ─── Thread row ──────────────────────────────────────────────────────────────

class _ThreadRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final listenable = swipeEnabled;
    if (listenable == null) return _row(context, true);
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, enabled, _) => _row(context, enabled),
    );
  }

  Widget _row(BuildContext context, bool swipeArmed) {
    final unread = thread.unreadCount > 0;

    return Dismissible(
      key: ValueKey('thread-${thread.peerSub}-$archived'),
      direction:
          swipeArmed ? DismissDirection.endToStart : DismissDirection.none,
      // A10: red Archive action slides in; we archive via the repository and
      // return false so the row animates out through the stream update
      // rather than the dismissal itself.
      confirmDismiss: (_) async {
        await AppServices.I.messages.setArchived(thread.peerSub, !archived);
        return false;
      },
      background: Container(
        color: archived ? const Color(0xFF119BFB) : AppColors.brandRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              archived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              archived ? 'Unarchive' : 'Archive',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ChatScreen(peerSub: thread.peerSub),
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              PeerAvatar(card: thread.card, size: 56, showVerified: true),
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
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.w400,
                              color: unread
                                  ? const Color(0xFF4A4A4A)
                                  : const Color(0xFF8A8A8A),
                            ),
                          ),
                        ),
                        Text(
                          '  ·  ${TimeFormat.relativeAge(thread.lastMessageAt)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8A8A8A),
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
    );
  }
}
