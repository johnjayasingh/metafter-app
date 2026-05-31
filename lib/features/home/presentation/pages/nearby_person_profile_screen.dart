import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Profile data for a nearby discovered person.
class NearbyPersonProfile {
  const NearbyPersonProfile({
    required this.name,
    required this.title,
    required this.company,
    required this.bio,
    this.photoUrl,
    this.initials = '',
    this.avatarBg = const Color(0xFFB7D9F2),
  });

  final String name;
  final String title;
  final String company;
  final String bio;
  final String? photoUrl;
  final String initials;
  final Color avatarBg;
}

/// Full-screen profile card shown when a nearby person avatar is tapped.
class NearbyPersonProfileScreen extends StatelessWidget {
  const NearbyPersonProfileScreen({
    super.key,
    required this.profile,
  });

  final NearbyPersonProfile profile;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.discoverActive;

    return Scaffold(
      body: Stack(
        children: [
          // ---- Gradient background ----
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  accent,
                  Color(0xFF7DC8FD),
                  Colors.white,
                ],
              ),
            ),
          ),

          // ---- Content ----
          SafeArea(
            child: Column(
              children: [
                // ---- App bar ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      // Placeholder to balance the back button
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ---- Avatar ----
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 3),
                    color: profile.avatarBg,
                  ),
                  child: ClipOval(
                    child: profile.photoUrl != null
                        ? Image.network(
                            profile.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _InitialsAvatar(initials: profile.initials),
                          )
                        : _InitialsAvatar(initials: profile.initials),
                  ),
                ),

                const SizedBox(height: 20),

                // ---- Name + title ----
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.title} \u2013 ${profile.company}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                  ),
                ),

                const SizedBox(height: 28),

                // ---- Bio ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    profile.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                      height: 1.5,
                    ),
                  ),
                ),

                const Spacer(),

                // ---- Connect button ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Connect request sent to ${profile.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text(
                        'Connect',
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
