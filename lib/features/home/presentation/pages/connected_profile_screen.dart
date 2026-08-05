import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/peer_avatar.dart';
import 'chat_screen.dart';
import 'find_person_screen.dart';

/// Full profile screen for an existing connection: bio, the invite note that
/// came with the connection (when any), Find Person while the peer is in BLE
/// range, and Disconnect (DESIGN_SPEC §5/§10 kebab profile summary).
class ConnectedProfileScreen extends StatefulWidget {
  const ConnectedProfileScreen({
    super.key,
    required this.card,
    this.inviteNote,
  });

  final ProfileCard card;

  /// Optional note that was sent with the connection invite.
  final String? inviteNote;

  @override
  State<ConnectedProfileScreen> createState() =>
      _ConnectedProfileScreenState();
}

class _ConnectedProfileScreenState extends State<ConnectedProfileScreen> {
  bool _disconnecting = false;

  Future<void> _confirmDisconnect() async {
    if (_disconnecting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Disconnect from ${widget.card.name}?'),
        content: const Text(
          'This removes your connection and the shared keys. Your chat '
          'history stays on this device until you delete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B6B6B))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect',
                style: TextStyle(
                    color: AppColors.brandRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _disconnecting = true);
    await AppServices.I.connection.disconnect(widget.card.sub);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openFindPerson() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FindPersonScreen(card: widget.card),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final isNearby =
        card.sub.isNotEmpty && AppServices.I.engine.isNearby(card.sub);

    return Scaffold(
      body: Stack(
        children: [
          // ── Red gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.40, 1.0],
                colors: [
                  AppColors.brandRed,
                  Color(0xFFF08080),
                  Colors.white,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── App bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'MetAfter',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                PeerAvatar(
                  card: card,
                  size: 110,
                  showVerified: true,
                  ringColor: Colors.white,
                  ringWidth: 3,
                ),

                const SizedBox(height: 14),

                Text(
                  card.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.titleLine,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    card.intro,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                      height: 1.5,
                    ),
                  ),
                ),

                // ── Invite note (if any) ──
                if ((widget.inviteNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.brandRed.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '"${widget.inviteNote}"',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B6B6B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // ── Message ──
                // The one guaranteed entry into a conversation with this
                // connection: ChatScreen is otherwise only reachable from a
                // thread row, and no thread exists until a first message.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ChatScreen(peerSub: widget.card.sub),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Find Person (only while in BLE range) ──
                if (isNearby)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.brandRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _openFindPerson,
                        icon: const Icon(Icons.near_me_outlined,
                            color: AppColors.brandRed),
                        label: const Text(
                          'Find Person',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Disconnect ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _disconnecting ? null : _confirmDisconnect,
                      child: Text(
                        _disconnecting ? 'Disconnecting…' : 'Disconnect',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
