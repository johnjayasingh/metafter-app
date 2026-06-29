import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'all_messages_screen.dart';
import 'chat_screen.dart';
import 'connect_requests_screen.dart';
import 'connected_profile_screen.dart';
import 'find_person_screen.dart';

// ─── Mock data models ────────────────────────────────────────────────────────

enum _RequestType { nearby, pending }

class _ConnectionRequest {
  const _ConnectionRequest({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.photoUrl,
    required this.type,
  });
  final String id;
  final String name;
  final String title;
  final String company;
  final String photoUrl;
  final _RequestType type;
}

// Use the public MessageItem from all_messages_screen.dart

const _mockRequests = <_ConnectionRequest>[
  _ConnectionRequest(
    id: 'r1',
    name: 'Liam Smith',
    title: 'CTO',
    company: 'TechCorp',
    photoUrl: 'https://i.pravatar.cc/150?img=12',
    type: _RequestType.nearby,
  ),
  _ConnectionRequest(
    id: 'r2',
    name: 'Olivia Rhye',
    title: 'CEO',
    company: 'Company',
    photoUrl: 'https://i.pravatar.cc/150?img=47',
    type: _RequestType.pending,
  ),
  _ConnectionRequest(
    id: 'r3',
    name: 'Emma John',
    title: 'CFO',
    company: 'Finance Inc.',
    photoUrl: 'https://i.pravatar.cc/150?img=49',
    type: _RequestType.pending,
  ),
];

const _mockMessages = <MessageItem>[
  MessageItem(
    id: 'm1',
    name: 'Candice Wue',
    photoUrl: 'https://i.pravatar.cc/150?img=45',
    lastMessage: "Okay, Let's Go.",
    timeAgo: '3h',
    isFromMe: true,
    dotColor: Color(0xFF119BFB),
  ),
  MessageItem(
    id: 'm2',
    name: 'Zahir Mays',
    photoUrl: 'https://i.pravatar.cc/150?img=11',
    lastMessage: 'Whats the plan',
    timeAgo: '6h',
    isFromMe: true,
    dotColor: Color(0xFF7C3AED),
  ),
  MessageItem(
    id: 'm3',
    name: 'Rane Wells',
    photoUrl: 'https://i.pravatar.cc/150?img=48',
    lastMessage: 'Meet you there at 7?',
    timeAgo: '12h',
    isFromMe: false,
    dotColor: AppColors.brandRed,
  ),
  MessageItem(
    id: 'm4',
    name: 'Sophia Ramirez',
    photoUrl: 'https://i.pravatar.cc/150?img=46',
    lastMessage: "Don't forget the keys",
    timeAgo: '18h',
    isFromMe: false,
    dotColor: AppColors.brandRed,
  ),
  MessageItem(
    id: 'm5',
    name: 'Jasmine',
    photoUrl: 'https://i.pravatar.cc/150?img=44',
    lastMessage: 'How are you?',
    timeAgo: '22h',
    isFromMe: false,
    dotColor: Color(0xFF119BFB),
  ),
  MessageItem(
    id: 'm6',
    name: 'Liam Chen',
    photoUrl: 'https://i.pravatar.cc/150?img=15',
    lastMessage: 'See you soon!',
    timeAgo: '1d',
    isFromMe: false,
    dotColor: AppColors.brandRed,
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final List<_ConnectionRequest> _requests = List.of(_mockRequests);

  void _accept(String id) => setState(() => _requests.removeWhere((r) => r.id == id));
  void _decline(String id) => setState(() => _requests.removeWhere((r) => r.id == id));

  @override
  Widget build(BuildContext context) {
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
          'Connect',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Connection Requests ──
          _SectionHeader(
            title: 'Connection Request',
            onSeeAll: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ConnectRequestsScreen(
                  requests: _requests,
                  onAccept: (r) => _accept(r.id as String),
                  onDecline: (r) => _decline(r.id as String),
                ),
              ),
            ),
          ),
          if (_requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'No pending requests',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
              ),
            )
          else
            ..._requests.map((r) => _RequestTile(
                  request: r,
                  onAccept: () => _accept(r.id),
                  onDecline: () => _decline(r.id),
                )),

          const SizedBox(height: 8),

          // ── Messages ──
          _SectionHeader(
            title: 'Messages',
            onSeeAll: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AllMessagesScreen(messages: _mockMessages),
              ),
            ),
          ),
          ..._mockMessages.take(4).map((m) => _MessageTile(message: m)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Request tile ─────────────────────────────────────────────────────────────

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });
  final _ConnectionRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Avatar
          ClipOval(
            child: Image.network(
              request.photoUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialCircle(
                name: request.name,
                size: 56,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + info — tappable to open profile
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
                  Text(
                    request.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  Text(
                    request.company,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Button(s)
          if (request.type == _RequestType.nearby)
            _RedButton(
              label: 'Find ${request.name.split(' ').first}',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FindPersonScreen(
                    name: request.name,
                    title: request.title,
                    company: request.company,
                    photoUrl: request.photoUrl,
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RedButton(label: 'Accept', onPressed: onAccept),
                const SizedBox(width: 8),
                _GrayButton(label: 'Decline', onPressed: onDecline),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Message tile ─────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Avatar with dot indicator
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
                        _InitialCircle(name: message.name, size: 56),
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
                const SizedBox(height: 2),
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

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _RedButton extends StatelessWidget {
  const _RedButton({required this.label, required this.onPressed});
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

class _GrayButton extends StatelessWidget {
  const _GrayButton({required this.label, required this.onPressed});
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFB7D9F2),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
