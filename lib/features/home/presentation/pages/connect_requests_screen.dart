import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// The request model is re-exported from connect_screen. To avoid
// duplicating it we make _ConnectionRequest public in the same feature
// directory. For now we forward-declare a minimal public version here.

enum RequestType { nearby, pending }

class ConnectionRequest {
  const ConnectionRequest({
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
  final RequestType type;
}

/// Full-screen list of all connection requests.
/// Opened when the user taps "See all" in the Connection Request section.
class ConnectRequestsScreen extends StatefulWidget {
  const ConnectRequestsScreen({
    super.key,
    required this.requests,
  });

  /// The requests to display. A copy is made so dismissals don't affect
  /// the parent list.
  final List<dynamic> requests; // accepts _ConnectionRequest instances

  @override
  State<ConnectRequestsScreen> createState() => _ConnectRequestsScreenState();
}

class _ConnectRequestsScreenState extends State<ConnectRequestsScreen> {
  // Mirror the parent's request list
  late final List<dynamic> _items = List.of(widget.requests);

  void _remove(dynamic item) => setState(() => _items.remove(item));

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
          'Connection Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(fontSize: 16, color: Color(0xFF8A8A8A)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 88,
                endIndent: 20,
                color: Color(0xFFF0F0F0),
              ),
              itemBuilder: (context, index) {
                final r = _items[index];
                return _FullRequestTile(
                  name: r.name,
                  title: r.title,
                  company: r.company,
                  photoUrl: r.photoUrl,
                  isNearby: r.type.toString().contains('nearby'),
                  onAccept: () => _remove(r),
                  onDecline: () => _remove(r),
                );
              },
            ),
    );
  }
}

class _FullRequestTile extends StatelessWidget {
  const _FullRequestTile({
    required this.name,
    required this.title,
    required this.company,
    required this.photoUrl,
    required this.isNearby,
    required this.onAccept,
    required this.onDecline,
  });

  final String name;
  final String title;
  final String company;
  final String photoUrl;
  final bool isNearby;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              photoUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialCircle(name: name),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                Text(
                  company,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isNearby)
            _Btn(
              label: 'Find ${name.split(' ').first}',
              filled: true,
              onPressed: onAccept,
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Btn(label: 'Accept', filled: true, onPressed: onAccept),
                const SizedBox(width: 8),
                _Btn(label: 'Decline', filled: false, onPressed: onDecline),
              ],
            ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.filled,
    required this.onPressed,
  });
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandRed,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFF0F0F0),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  const _InitialCircle({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials =
        name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFB7D9F2),
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
