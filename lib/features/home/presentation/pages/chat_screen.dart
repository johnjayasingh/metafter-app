import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'call_screen.dart';

// ─── Mock chat data ───────────────────────────────────────────────────────────

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isMe,
    this.emoji,
    this.dateSeparator,
  });
  final String text;
  final bool isMe;
  final String? emoji;
  final String? dateSeparator;
}

const _mockMessages = <_ChatMessage>[
  _ChatMessage(text: 'Found a new brunch spot...', isMe: true, emoji: '😊'),
  _ChatMessage(text: 'are you free saturday?', isMe: true),
  _ChatMessage(text: 'Hi Asif', isMe: false),
  _ChatMessage(text: 'Amazing... How are you?', isMe: false),
  _ChatMessage(text: 'Nice Spot...', isMe: false),
  _ChatMessage(text: 'Sure, Lets meet Saturday...', isMe: false,
      dateSeparator: 'Mon, 10:38 am'),
  _ChatMessage(text: 'Definitely! What time?', isMe: true),
  _ChatMessage(text: '10:30am Works for you?', isMe: true),
  _ChatMessage(text: 'Yes works with me...', isMe: false),
  _ChatMessage(text: 'Where is it?', isMe: false),
  _ChatMessage(text: 'Its in Downtown', isMe: true),
  _ChatMessage(text: 'Will share you the location...', isMe: true),
  _ChatMessage(text: 'Do you want me to pick you up', isMe: true),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.dotColor,
    this.onInfoTap,
  });

  final String name;
  final String photoUrl;
  final Color dotColor;
  final VoidCallback? onInfoTap;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: const Color(0x1A000000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.brandRed, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                children: [
                  ClipOval(
                    child: Image.network(
                      widget.photoUrl,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _InitialCircle(name: widget.name, size: 38),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border:
                            Border.all(color: widget.dotColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined,
                color: Colors.black, size: 22),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CallScreen(
                  name: widget.name,
                  photoUrl: widget.photoUrl,
                  isVideo: true,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined,
                color: Colors.black, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CallScreen(
                  name: widget.name,
                  photoUrl: widget.photoUrl,
                  isVideo: false,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline,
                color: Colors.black, size: 22),
            onPressed: widget.onInfoTap,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _mockMessages.length,
              itemBuilder: (context, index) {
                final msg = _mockMessages[index];
                // Show received-avatar only on the FIRST message of a
                // received cluster.
                final isFirstInReceivedGroup = !msg.isMe &&
                    (index == 0 ||
                        _mockMessages[index - 1].isMe ||
                        msg.dateSeparator != null);
                return _MessageBubble(
                  message: msg,
                  photoUrl: widget.photoUrl,
                  name: widget.name,
                  showAvatar: isFirstInReceivedGroup,
                );
              },
            ),
          ),

          // ── Input bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.sentiment_satisfied_alt_outlined,
                    color: Color(0xFF8A8A8A), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFAAAAAA),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.mic_none_outlined,
                    color: Color(0xFF8A8A8A), size: 26),
                const SizedBox(width: 10),
                const Icon(Icons.image_outlined,
                    color: Color(0xFF8A8A8A), size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.photoUrl,
    required this.name,
    required this.showAvatar,
  });

  final _ChatMessage message;
  final String photoUrl;
  final String name;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    // Date separator
    if (message.dateSeparator != null) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              message.dateSeparator!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ),
        ),
      );
    }

    if (message.isMe) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.emoji != null) ...[
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: Text(message.emoji!, style: const TextStyle(fontSize: 28)),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4, left: 64),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar)
              ClipOval(
                child: Image.network(
                  photoUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _InitialCircle(name: name, size: 28),
                ),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4, right: 64),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF119BFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials =
        name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
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
