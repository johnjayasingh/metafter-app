import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/peer_avatar.dart';
import 'call_screen.dart';
import 'connected_profile_screen.dart';

const _kReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// 1:1 chat (DESIGN_SPEC §10, A11) — live messages from
/// `AppServices.I.messages.watchThread`, sends through
/// `AppServices.I.messaging`.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.peerSub});

  final String peerSub;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  ProfileCard? _card;
  Duration? _ttl;
  bool _nearby = false;
  bool _hasText = false;

  /// Whether a connection row still exists for this peer. Goes false when the
  /// peer disconnects us (the thread + this screen outlive the connection),
  /// which locks the composer so a send can't silently throw (finding [18]).
  bool _connected = true;

  /// Message count last handled by [_onSnapshot] — drives autoscroll off the
  /// same snapshot the StreamBuilder renders (finding [21]).
  int _lastCount = 0;

  late final Stream<List<ChatMessage>> _thread;
  StreamSubscription<dynamic>? _nearbySub;
  final List<StreamSubscription<List<ThreadSummary>>> _threadInfoSubs = [];
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    final services = AppServices.I;

    // Single rendering stream — the StreamBuilder is the only listener, and
    // read-marking + autoscroll are driven from that same snapshot (finding
    // [21]) rather than a second racing subscription.
    _thread = services.messages.watchThread(widget.peerSub);

    // Header card: prefer the connection row, fall back to the thread card.
    services.connections.byPeer(widget.peerSub).then((c) {
      if (!mounted) return;
      setState(() {
        if (c != null) _card = c.card;
        _connected = c != null;
      });
    });
    for (final archived in const [false, true]) {
      _threadInfoSubs.add(
        services.messages.watchThreads(archived: archived).listen((threads) {
          for (final t in threads) {
            if (t.peerSub != widget.peerSub) continue;
            if (!mounted) return;
            setState(() {
              _card ??= t.card;
              _ttl = t.disappearingTtl;
            });
          }
        }),
      );
    }

    // Presence: engine stream + 3 s poll.
    _nearby = services.messaging.isPeerNearby(widget.peerSub);
    _nearbySub = services.engine.nearbyPeers.listen((_) => _refreshPresence());
    _presenceTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _refreshPresence());

    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });

    unawaited(services.messaging.markRead(widget.peerSub));
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _nearbySub?.cancel();
    for (final s in _threadInfoSubs) {
      s.cancel();
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _reduceMotion => AppServices.I.settings.reduceMotion.value;

  Future<void> _refreshPresence() async {
    if (!mounted) return;
    final nearby = AppServices.I.messaging.isPeerNearby(widget.peerSub);
    final connected =
        await AppServices.I.connections.byPeer(widget.peerSub) != null;
    if (!mounted) return;
    if (nearby != _nearby || connected != _connected) {
      setState(() {
        _nearby = nearby;
        _connected = connected;
      });
    }
  }

  /// Drives read-marking + autoscroll from the exact snapshot the
  /// StreamBuilder renders, so the scroll is measured against the list that
  /// is actually being laid out this frame (finding [21]).
  void _onSnapshot(List<ChatMessage> messages) {
    // A received message that is not yet read while the chat is visible →
    // mark the thread read. markThreadRead also flips received statuses to
    // `read`, so the re-emitted snapshot fails this guard and the mark cannot
    // loop (coordination with the data agent's markThreadRead change).
    if (messages.any((m) => !m.fromMe && m.status != MessageStatus.read)) {
      unawaited(AppServices.I.messaging.markRead(widget.peerSub));
    }
    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (_reduceMotion) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ProfileCard get _headerCard =>
      _card ?? ProfileCard(sub: widget.peerSub, name: '');

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      // Keep the typed text until the send actually resolves — if the peer
      // disconnected us, send() throws StateError and nothing must be lost
      // (finding [18]).
      await AppServices.I.messaging.send(widget.peerSub, text);
      _controller.clear();
    } on StateError {
      if (!mounted) return;
      setState(() => _connected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are no longer connected')),
      );
    }
  }

  void _openCall({required bool isVideo}) {
    final card = _headerCard;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CallScreen(
        name: card.name,
        card: card,
        isVideo: isVideo,
      ),
    ));
  }

  // ── Long-press reaction picker (A11) ──────────────────────────────────────

  void _showReactionPicker(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final emoji in _kReactionEmojis)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    // Tapping the current reaction again clears it.
                    final next = message.reaction == emoji ? null : emoji;
                    unawaited(AppServices.I.messaging
                        .react(widget.peerSub, message.id, next));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: message.reaction == emoji
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AppColors.brandRed.withValues(alpha: 0.12),
                          )
                        : null,
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Kebab menu (§10 "Message Chat Page" variant) ──────────────────────────

  void _showMenu() {
    final settings = AppServices.I.settings;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final card = _headerCard;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red gradient profile-summary header.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.brandRed, AppColors.brandRedDeep],
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    PeerAvatar(
                      card: card,
                      size: 64,
                      showVerified: true,
                      ringColor: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      card.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (card.titleLine.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        card.titleLine,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (settings.allowVideoCall.value)
                ListTile(
                  leading: const Icon(Icons.videocam_outlined,
                      color: Colors.black87),
                  title: const Text('Video Call'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openCall(isVideo: true);
                  },
                ),
              if (settings.allowAudioCall.value)
                ListTile(
                  leading:
                      const Icon(Icons.phone_outlined, color: Colors.black87),
                  title: const Text('Audio Call'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openCall(isVideo: false);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.black87),
                title: const Text('Disappearing Messages'),
                subtitle: Text(_ttlLabel(_ttl)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showDisappearingPicker();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.person_outline, color: Colors.black87),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ConnectedProfileScreen(card: card),
                  ));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.link_off_rounded, color: AppColors.brandRed),
                title: const Text(
                  'Disconnect',
                  style: TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDisconnect();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static String _ttlLabel(Duration? ttl) {
    if (ttl == null) return 'Off';
    if (ttl == const Duration(hours: 24)) return '24 hours';
    if (ttl == const Duration(days: 7)) return '7 days';
    return '${ttl.inHours} hours';
  }

  void _showDisappearingPicker() {
    const options = <(String, Duration?)>[
      ('Off', null),
      ('24 hours', Duration(hours: 24)),
      ('7 days', Duration(days: 7)),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                'Disappearing Messages',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            for (final (label, ttl) in options)
              ListTile(
                title: Text(label),
                trailing: _ttl == ttl
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.brandRed)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(AppServices.I.messages
                      .setDisappearingTtl(widget.peerSub, ttl));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect() async {
    final card = _headerCard;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect?'),
        content: Text(
          'This removes your connection with ${card.name} and wipes your '
          'shared keys. The chat stays on this device until you delete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Disconnect',
              style: TextStyle(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppServices.I.connection.disconnect(widget.peerSub);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = AppServices.I.settings;
    final card = _headerCard;

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
            PeerAvatar(card: card, size: 38, showVerified: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (_ttl != null) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.timer_outlined,
                            size: 14, color: Color(0xFF8A8A8A)),
                      ],
                    ],
                  ),
                  if (_nearby) const _NearbyChip(),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: settings.allowVideoCall,
            builder: (_, allowed, _) => allowed
                ? IconButton(
                    icon: const Icon(Icons.videocam_outlined,
                        color: Colors.black, size: 22),
                    onPressed: () => _openCall(isVideo: true),
                  )
                : const SizedBox.shrink(),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.allowAudioCall,
            builder: (_, allowed, _) => allowed
                ? IconButton(
                    icon: const Icon(Icons.phone_outlined,
                        color: Colors.black, size: 20),
                    onPressed: () => _openCall(isVideo: false),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.black, size: 22),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _thread,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessage>[];
                _onSnapshot(messages);
                final use24h = settings.use24hTime.value;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final prev = index > 0 ? messages[index - 1] : null;
                    final showSeparator = prev == null ||
                        msg.sentAt.difference(prev.sentAt) >
                            const Duration(hours: 1) ||
                        msg.sentAt.day != prev.sentAt.day;
                    // Show received-avatar only on the FIRST message of a
                    // received cluster.
                    final showAvatar = !msg.fromMe &&
                        (prev == null || prev.fromMe || showSeparator);
                    final isNewest = index == messages.length - 1;
                    Widget bubble = _MessageBubble(
                      message: msg,
                      card: card,
                      showAvatar: showAvatar,
                      reduceMotion: _reduceMotion,
                      onLongPress: () => _showReactionPicker(msg),
                    );
                    // A11: new-message slide-up + fade (newest bubble only).
                    if (isNewest && !_reduceMotion) {
                      bubble = TweenAnimationBuilder<double>(
                        key: ValueKey('enter-${msg.id}'),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        builder: (_, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: bubble,
                      );
                    }
                    return Column(
                      crossAxisAlignment: msg.fromMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                TimeFormat.chatSeparator(msg.sentAt,
                                    use24h: use24h),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                            ),
                          ),
                        bubble,
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Inline state when the peer has disconnected us — the composer is
          // still usable (BLE/relay may recover), but sends will fail until
          // the connection is re-established (finding [18]).
          if (!_connected)
            Container(
              width: double.infinity,
              color: const Color(0xFFFDECEC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'You are no longer connected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandRed,
                ),
              ),
            ),

          // ── Input bar ──
          Container(
            color: Colors.white,
            // Last thing in the column, so it owns the system-bar inset —
            // without it the composer sits under Android's navigation bar.
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              10 + MediaQuery.paddingOf(context).bottom,
            ),
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
                      onSubmitted: (_) => _send(),
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
                if (_hasText)
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.brandRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  )
                else ...[
                  const Icon(Icons.mic_none_outlined,
                      color: Color(0xFF8A8A8A), size: 26),
                  const SizedBox(width: 10),
                  const Icon(Icons.image_outlined,
                      color: Color(0xFF8A8A8A), size: 26),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Presence chip ────────────────────────────────────────────────────────────

class _NearbyChip extends StatelessWidget {
  const _NearbyChip();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF34C759),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'nearby',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF34C759),
          ),
        ),
      ],
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.card,
    required this.showAvatar,
    required this.reduceMotion,
    required this.onLongPress,
  });

  final ChatMessage message;
  final ProfileCard card;
  final bool showAvatar;
  final bool reduceMotion;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    final hasReaction = message.reaction != null;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.brandRed : const Color(0xFF119BFB),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              message.body,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          if (mine) ...[
            const SizedBox(width: 6),
            _StatusTicks(status: message.status),
          ],
        ],
      ),
    );

    // Reaction chip overlaps the bubble's bottom corner, with a pop
    // animation on change (A11: scale overshoot ~1.2).
    Widget content = bubble;
    if (hasReaction) {
      Widget chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(message.reaction!, style: const TextStyle(fontSize: 13)),
      );
      if (!reduceMotion) {
        chip = TweenAnimationBuilder<double>(
          key: ValueKey('reaction-${message.id}-${message.reaction}'),
          tween: Tween(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack, // overshoots to ~1.2 then settles
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: chip,
        );
      }
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            bottom: -9,
            left: mine ? 8 : null,
            right: mine ? null : 8,
            child: chip,
          ),
        ],
      );
    }

    content = GestureDetector(
      onLongPress: onLongPress,
      child: content,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: hasReaction ? 13 : 4),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            if (showAvatar)
              PeerAvatar(card: card, size: 28)
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                left: mine ? 64 : 0,
                right: mine ? 0 : 64,
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small, subtle delivery ticks on my bubbles: ✓ sent, ✓✓ delivered,
/// ✓✓ tinted when read.
class _StatusTicks extends StatelessWidget {
  const _StatusTicks({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sending => Icon(
          Icons.schedule_rounded,
          size: 13,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      MessageStatus.sent => Icon(
          Icons.done_rounded,
          size: 13,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      MessageStatus.delivered => Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      MessageStatus.read => const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Color(0xFFAEE6FF),
        ),
    };
  }
}
