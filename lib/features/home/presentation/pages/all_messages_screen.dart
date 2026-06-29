import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'chat_screen.dart';
import 'connected_profile_screen.dart';

// ─── Public model ─────────────────────────────────────────────────────────────

class MessageItem {
  const MessageItem({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.timeAgo,
    required this.isFromMe,
    required this.dotColor,
  });
  final String id;
  final String name;
  final String photoUrl;
  final String lastMessage;
  final String timeAgo;
  final bool isFromMe;
  final Color dotColor;
}

/// Shared sample conversations used by the Messages tab / screen.
const List<MessageItem> kSampleMessages = <MessageItem>[
  MessageItem(id: 'm1', name: 'Candice Wue', photoUrl: 'https://i.pravatar.cc/150?img=45', lastMessage: "Okay, Let's Go.", timeAgo: '3h', isFromMe: true, dotColor: Color(0xFF119BFB)),
  MessageItem(id: 'm2', name: 'Zahir Mays', photoUrl: 'https://i.pravatar.cc/150?img=11', lastMessage: 'Whats the plan', timeAgo: '6h', isFromMe: true, dotColor: Color(0xFF7C3AED)),
  MessageItem(id: 'm3', name: 'Rane Wells', photoUrl: 'https://i.pravatar.cc/150?img=48', lastMessage: 'Meet you there at 7?', timeAgo: '12h', isFromMe: false, dotColor: AppColors.brandRed),
  MessageItem(id: 'm4', name: 'Sophia Ramirez', photoUrl: 'https://i.pravatar.cc/150?img=46', lastMessage: "Don't forget the keys", timeAgo: '18h', isFromMe: false, dotColor: AppColors.brandRed),
  MessageItem(id: 'm5', name: 'Jasmine', photoUrl: 'https://i.pravatar.cc/150?img=44', lastMessage: 'How are you?', timeAgo: '22h', isFromMe: false, dotColor: Color(0xFF119BFB)),
  MessageItem(id: 'm6', name: 'Liam Chen', photoUrl: 'https://i.pravatar.cc/150?img=15', lastMessage: 'See you soon!', timeAgo: '1d', isFromMe: false, dotColor: AppColors.brandRed),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class AllMessagesScreen extends StatefulWidget {
  const AllMessagesScreen({
    super.key,
    required this.messages,
    this.embedded = false,
  });

  final List<MessageItem> messages;

  /// When `true`, render the body only (no Scaffold/AppBar) so the screen can
  /// be hosted inside the swipeable [HomeShell] under its shared header.
  final bool embedded;

  @override
  State<AllMessagesScreen> createState() => _AllMessagesScreenState();
}

class _AllMessagesScreenState extends State<AllMessagesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MessageItem> get _filtered {
    if (_query.isEmpty) return widget.messages;
    final q = _query.toLowerCase();
    return widget.messages
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.lastMessage.toLowerCase().contains(q))
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

  Widget _listOrEmpty(List<MessageItem> filtered) => filtered.isEmpty
      ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                _query.isEmpty ? 'No messages yet' : 'No results for "$_query"',
                style: const TextStyle(fontSize: 15, color: Color(0xFF8A8A8A)),
              ),
            ],
          ),
        )
      : ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const Divider(
            height: 1,
            indent: 88,
            endIndent: 20,
            color: Color(0xFFF0F0F0),
          ),
          itemBuilder: (context, index) =>
              _MessageTile(message: filtered[index]),
        );

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    if (widget.embedded) {
      return ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            _searchField(),
            Expanded(child: _listOrEmpty(filtered)),
          ],
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
      body: _listOrEmpty(filtered),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});
  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          name: message.name,
          photoUrl: message.photoUrl,
          dotColor: message.dotColor,
          onInfoTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ConnectedProfileScreen(
              name: message.name,
              title: '',
              company: '',
              bio: '',
              photoUrl: message.photoUrl,
            ),
          )),
        ),
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar + online dot
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  ClipOval(
                    child: Image.network(
                      message.photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _InitialCircle(name: message.name),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: message.dotColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message.isFromMe
                        ? 'You: ${message.lastMessage}'
                        : message.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              message.timeAgo,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials =
        name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.discoverActive,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
