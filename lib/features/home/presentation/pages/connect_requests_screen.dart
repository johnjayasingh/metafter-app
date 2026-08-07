import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/peer_avatar.dart';
import 'find_person_screen.dart';

/// Full-page connection requests list (DESIGN_SPEC §7.2): the expanded
/// version of the Home pull-up sheet. Reads the pending incoming requests
/// straight from the repository; Accept/Decline go through
/// [AppServices.I.connection]. After accepting someone still in BLE range,
/// the SnackBar offers "Find them" (§8).
class ConnectRequestsScreen extends StatefulWidget {
  const ConnectRequestsScreen({super.key});

  @override
  State<ConnectRequestsScreen> createState() => _ConnectRequestsScreenState();
}

class _ConnectRequestsScreenState extends State<ConnectRequestsScreen> {
  late final Stream<List<ConnectionRequest>> _stream;

  /// Deadline for the post-accept confirmation banner (see [_accept]).
  Timer? _bannerTimer;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  /// Request ids with an accept/decline in flight (buttons disabled).
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _stream = AppServices.I.requests.watchIncomingPending();
  }

  Future<void> _accept(ConnectionRequest request) async {
    if (!_busy.add(request.id)) return;
    setState(() {});
    final navigator = Navigator.of(context);
    await AppServices.I.connection.accept(request);
    if (!mounted) return;
    setState(() => _busy.remove(request.id));

    final nearby = request.peerSub.isNotEmpty &&
        AppServices.I.engine.isNearby(request.peerSub);
    final banner = ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('You are now connected with ${request.card.name}'),
      behavior: SnackBarBehavior.floating,
      action: nearby
          ? SnackBarAction(
              label: 'Find them',
              textColor: AppColors.brandRed,
              onPressed: () => navigator.push(MaterialPageRoute<void>(
                builder: (_) => FindPersonScreen(card: request.card),
              )),
            )
          : null,
    ));
    // Accessibility services suspend SnackBar auto-dismiss (see the same
    // pattern in home_shell's accept flow) — enforce the transient intent.
    // Tracked so tests (and dispose) don't leak a pending timer.
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 8), banner.close);
  }

  Future<void> _decline(ConnectionRequest request) async {
    if (!_busy.add(request.id)) return;
    setState(() {});
    await AppServices.I.connection.decline(request);
    if (mounted) setState(() => _busy.remove(request.id));
  }

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Connection Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ConnectionRequest>>(
              stream: _stream,
              builder: (context, snapshot) {
                final rows = snapshot.data;
                if (rows == null) return const SizedBox.shrink();
                if (rows.isEmpty) {
                  return const Center(
                    child: Text(
                      'No new friend request',
                      style:
                          TextStyle(fontSize: 15, color: Color(0xFF8A8A8A)),
                    ),
                  );
                }
                return ListView.separated(
                  // Explicit padding replaces the automatic safe-area inset —
                  // re-add it so the last request clears the navigation bar.
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: 8 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 88,
                    endIndent: 20,
                    color: Color(0xFFF0F0F0),
                  ),
                  itemBuilder: (context, index) {
                    final r = rows[index];
                    return _RequestTile(
                      request: r,
                      busy: _busy.contains(r.id),
                      onAccept: () => _accept(r),
                      onDecline: () => _decline(r),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ConnectionRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final card = request.card;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          PeerAvatar(card: card, size: 56, showVerified: true),
          const SizedBox(width: 14),
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
                Text(
                  card.designation.isNotEmpty ? card.designation : card.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B6B6B)),
                ),
                Text(
                  card.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B6B6B)),
                ),
                if ((request.note ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '"${request.note}"',
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: busy ? null : onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: busy ? null : onDecline,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F0F0),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
