import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Full profile screen for a connected person.
/// Shows bio, privacy preference toggles, and a Disconnect button.
class ConnectedProfileScreen extends StatefulWidget {
  const ConnectedProfileScreen({
    super.key,
    required this.name,
    required this.title,
    required this.company,
    required this.bio,
    required this.photoUrl,
    this.inviteNote,
  });

  final String name;
  final String title;
  final String company;
  final String bio;
  final String photoUrl;
  /// Optional note that was sent with the connection invite.
  final String? inviteNote;

  @override
  State<ConnectedProfileScreen> createState() =>
      _ConnectedProfileScreenState();
}

class _ConnectedProfileScreenState extends State<ConnectedProfileScreen> {
  bool _videoCall = true;
  bool _audioCall = true;
  bool _disappearingMessages = false;

  @override
  Widget build(BuildContext context) {
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

                // ── Avatar ──
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandRed, width: 3),
                    color: const Color(0xFFE3C8B5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      widget.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _InitialsAvatar(name: widget.name),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.title} \u2013 ${widget.company}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.bio,
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

                const SizedBox(height: 24),

                // ── Privacy preferences ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRIVACY PREFERENCES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A8A8A),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ToggleRow(
                        label: 'Video Call',
                        value: _videoCall,
                        onChanged: (v) => setState(() => _videoCall = v),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      _ToggleRow(
                        label: 'Audio Call',
                        value: _audioCall,
                        onChanged: (v) => setState(() => _audioCall = v),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      _ToggleRow(
                        label: 'Disappearing Messages',
                        value: _disappearingMessages,
                        onChanged: (v) =>
                            setState(() => _disappearingMessages = v),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'For added privacy, you can set who can call you and who can save your chats.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8A8A),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Disconnect button ──
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Disconnect',
                        style: TextStyle(
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.brandRed,
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials =
        name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return Container(
      color: const Color(0xFFE3C8B5),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
