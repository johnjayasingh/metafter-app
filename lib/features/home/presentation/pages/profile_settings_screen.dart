import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/mock_data.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/domain/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/services/bootstrap_services.dart';
import '../../../../core/theme/app_colors.dart';
import 'nearby_person_profile_screen.dart';
import 'pricing_screen.dart';
import 'privacy_security_screen.dart';

/// User's own profile + settings home (DESIGN_SPEC §11.1).
///
/// Every row is wired to [SettingsRepository] via [AppServices.I.settings] —
/// the same ValueListenables drive the Home shell, so changes here are live
/// everywhere.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  SettingsRepository get _settings => AppServices.I.settings;

  /// Guards the logout row while the wipe is in flight — it is not idempotent
  /// from the user's point of view and the taps are cheap to repeat.
  bool _loggingOut = false;

  static const _languageOptions = <String>[
    'English',
    'Spanish',
    'French',
    'German',
    'Japanese',
  ];
  static const _timeFormatOptions = <String>['12hr', '24hr'];

  // DESIGN_SPEC §11.1: 30 min / 1 hr / 2 hrs / 4 hrs / 8 hrs.
  static const _durationOptions = <Duration>[
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 8),
  ];

  // DESIGN_SPEC §11.1: 2 / 5 / 10 mts.
  static const _distanceOptions = <double>[2, 5, 10];

  static String _durationLabel(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    return d.inHours == 1 ? '1 hr' : '${d.inHours} hrs';
  }

  static String _distanceLabel(double meters) => '${meters.round()} mts';

  Future<String?> _pickFromList(
      String title, List<String> options, String current) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PickerSheet(
        title: title,
        options: options,
        current: current,
      ),
    );
  }

  Future<void> _pickMood() async {
    final picked = await showModalBottomSheet<MoodRing>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Set Mood Ring',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            for (final m in MoodRing.values)
              ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: m.color, width: 2),
                  ),
                ),
                title: Text(m.label),
                trailing: m == _settings.mood.value
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.brandRed)
                    : null,
                onTap: () => Navigator.of(ctx).pop(m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) await _settings.setMood(picked);
  }

  void _openAccessibility() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Accessibility',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _settings.reduceMotion,
              builder: (_, v, _) => SwitchListTile(
                title: const Text('Reduce Motion'),
                subtitle: const Text('Disable looping and idle animations'),
                value: v,
                activeTrackColor: AppColors.brandRed,
                onChanged: _settings.setReduceMotion,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _settings.largerText,
              builder: (_, v, _) => SwitchListTile(
                title: const Text('Larger Text'),
                value: v,
                activeTrackColor: AppColors.brandRed,
                onChanged: _settings.setLargerText,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile sharing is coming soon.')),
    );
  }

  /// Re-runs the face scan for a profile that never came back verified (the
  /// verdict resolves in the background, so a user can easily leave signup
  /// before it lands).
  void _verifyIdentity() {
    context.push(AppRouter.signupSelfie);
  }

  /// Log out — which, on a local-first app, means erase.
  ///
  /// There is no cloud copy of the user's profile, chats or connections to
  /// sign back into, so the confirmation spells out exactly what disappears
  /// rather than using the usual "you'll need to sign in again" wording.
  Future<void> _confirmLogout() async {
    if (_loggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out and delete everything?'),
        content: const Text(
          'MetAfter keeps your data on this device only — there is no cloud '
          'backup to restore from.\n\n'
          'Logging out permanently deletes:\n'
          '  •  Your profile and photo\n'
          '  •  All connections and requests\n'
          '  •  All messages and chat history\n'
          '  •  Everyone you have crossed paths with\n'
          '  •  Your encryption keys\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B6B6B))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete & Log Out',
                style: TextStyle(
                    color: AppColors.brandRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    await signOutAndWipe();
    if (!mounted) return;
    // go() (not push) so the wiped home/settings stack cannot be popped back
    // into — those screens now reference data that no longer exists.
    context.go(AppRouter.signupBasics);
  }

  void _openPro() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _UpgradeProDialog(),
    );
  }

  Future<void> _seeProfile() async {
    try {
      // Self-preview: exactly the card peers see over BLE.
      final card = await AppServices.I.profile.buildCard();
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            NearbyPersonProfileScreen(card: card, selfPreview: true),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete your profile to preview it.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.brandRed, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('MetAfter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.brandRed,
            )),
        centerTitle: true,
      ),
      body: ListView(
        // An explicit padding REPLACES the ListView's automatic safe-area
        // inset, so the system bar area has to be re-added by hand — without
        // it the last rows sit under Android's navigation bar.
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          ValueListenableBuilder<MyProfile?>(
            valueListenable: AppServices.I.profile.profile,
            builder: (_, profile, _) => _ProfileHeader(
              profile: profile,
              onSeeProfile: _seeProfile,
            ),
          ),
          const SizedBox(height: 18),
          _RowGroup(rows: [
            ValueListenableBuilder<MoodRing>(
              valueListenable: _settings.mood,
              builder: (_, mood, _) => _ChevronRow(
                label: 'Set Mood Ring',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: mood.color, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(mood.label,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF8A8A8A))),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFB0B0B0), size: 22),
                  ],
                ),
                onTap: _pickMood,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // The face-scan verdict lands asynchronously — often after the user
          // has already tapped through "Done" — so this is where they can
          // actually see how it came out, and re-run it if it didn't pass.
          _RowGroup(rows: [
            ValueListenableBuilder<MyProfile?>(
              valueListenable: AppServices.I.profile.profile,
              builder: (_, profile, _) {
                final verified = profile?.verified ?? false;
                return _ChevronRow(
                  label: 'Identity Verification',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        verified
                            ? Icons.verified_rounded
                            : Icons.error_outline_rounded,
                        size: 18,
                        color: verified
                            ? AppColors.discoverActive
                            : const Color(0xFF8A8A8A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        verified ? 'Verified' : 'Not verified',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: verified
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: verified
                              ? AppColors.discoverActive
                              : const Color(0xFF8A8A8A),
                        ),
                      ),
                      if (!verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFB0B0B0), size: 22),
                      ],
                    ],
                  ),
                  onTap: verified ? () {} : _verifyIdentity,
                );
              },
            ),
          ]),
          const SizedBox(height: 12),
          _RowGroup(rows: [
            _ChevronRow(
              label: 'Share Profile',
              trailing: const Icon(Icons.ios_share_rounded,
                  color: Colors.black, size: 20),
              onTap: _shareProfile,
            ),
          ]),
          const SizedBox(height: 12),
          _RowGroup(rows: [
            ValueListenableBuilder<bool>(
              valueListenable: MockData.demoContent,
              builder: (_, v, _) => SwitchListTile(
                title: const Text('Demo Content'),
                subtitle: const Text(
                  'Simulate nearby people and show sample rows in Discover & '
                  'Messages. Off = real Bluetooth discovery and real data.',
                ),
                value: v,
                activeTrackColor: AppColors.brandRed,
                onChanged: (on) => MockData.demoContent.value = on,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _RowGroup(rows: [
            ValueListenableBuilder<String>(
              valueListenable: _settings.language,
              builder: (_, language, _) => _ChevronRow(
                label: 'Language',
                trailingText: language,
                onTap: () async {
                  final v = await _pickFromList(
                      'Language', _languageOptions, language);
                  if (v != null) await _settings.setLanguage(v);
                },
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _settings.use24hTime,
              builder: (_, use24h, _) => _ChevronRow(
                label: 'Time Format',
                trailingText: use24h ? '24hr' : '12hr',
                onTap: () async {
                  final v = await _pickFromList('Time Format',
                      _timeFormatOptions, use24h ? '24hr' : '12hr');
                  if (v != null) await _settings.setUse24hTime(v == '24hr');
                },
              ),
            ),
            _ChevronRow(
              label: 'Accessibility',
              onTap: _openAccessibility,
            ),
            _ChevronRow(
              label: 'Privacy & Security',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacySecurityScreen(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _RowGroup(rows: [
            ValueListenableBuilder<Duration>(
              valueListenable: _settings.discoverableDuration,
              builder: (_, duration, _) => _ChevronRow(
                label: 'Discoverable Time',
                trailingText: _durationLabel(duration),
                onTap: () async {
                  final v = await _pickFromList(
                    'Discoverable Time',
                    _durationOptions.map(_durationLabel).toList(),
                    _durationLabel(duration),
                  );
                  if (v == null) return;
                  final picked = _durationOptions
                      .firstWhere((d) => _durationLabel(d) == v);
                  await _settings.setDiscoverableDuration(picked);
                },
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _settings.distanceBudget,
              builder: (_, distance, _) => _ChevronRow(
                label: 'Proximity Distance',
                trailingText: _distanceLabel(distance),
                onTap: () async {
                  final v = await _pickFromList(
                    'Proximity Distance',
                    _distanceOptions.map(_distanceLabel).toList(),
                    _distanceLabel(distance),
                  );
                  if (v == null) return;
                  final picked = _distanceOptions
                      .firstWhere((d) => _distanceLabel(d) == v);
                  await _settings.setDistanceBudget(picked);
                },
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _GetProButton(onTap: _openPro),
          const SizedBox(height: 18),
          _RowGroup(rows: [
            _LogOutRow(busy: _loggingOut, onTap: _confirmLogout),
          ]),
        ],
      ),
    );
  }
}

/// Destructive sign-out row. Red label rather than the usual black, and it
/// swaps to a spinner while [ProfileSettingsScreen] runs the wipe so the user
/// gets feedback during the (brief) DB + keychain teardown.
class _LogOutRow extends StatelessWidget {
  const _LogOutRow({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            const Expanded(
              child: Text('Log Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandRed,
                  )),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.brandRed),
              )
            else
              const Icon(Icons.logout_rounded,
                  color: AppColors.brandRed, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.onSeeProfile,
  });
  final MyProfile? profile;
  final VoidCallback onSeeProfile;

  String get _initials {
    final name = profile?.name.trim() ?? '';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = profile?.photoPath;
    final hasPhoto = photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandRed, width: 2.5),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? Image.file(
                      File(photoPath),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _initialsDisc(),
                    )
                  : _initialsDisc(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile?.name ?? 'Your Name',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    )),
                const SizedBox(height: 2),
                Text(profile?.titleLine ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    )),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onSeeProfile,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide.none,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('See Profile',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandRed,
                )),
          ),
        ],
      ),
    );
  }

  Widget _initialsDisc() => Container(
        width: 64,
        height: 64,
        color: AppColors.brandRed.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brandRed,
          ),
        ),
      );
}

// ─── Get Pro CTA ──────────────────────────────────────────────────────────────

class _GetProButton extends StatelessWidget {
  const _GetProButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE4E1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandRed, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: AppColors.brandRed, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Get MetAfter Pro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandRed,
                  )),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.brandRed, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Pro upgrade dialog ───────────────────────────────────────────────────────

class _UpgradeProDialog extends StatelessWidget {
  const _UpgradeProDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFCE4E1),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Center(
              child: Text('Upgrade to Pro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: [
                const Text(r'$10/mth',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    )),
                const SizedBox(height: 8),
                const Text('Pro Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                const Text('Billed annually.',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF6B6B6B))),
                const SizedBox(height: 18),
                ...const [
                  'Access to all basic features',
                  'Unlimited connection requests',
                  'Invitation notes to individual users',
                  'Priority chat & email support',
                ].map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD7F1D9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 14, color: Color(0xFF2BA84A)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(f,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4F4F4F),
                                )),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Purchases are coming soon.')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Continue with Pro',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const PricingScreen(),
                    ));
                  },
                  child: const Text('See other plans',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generic picker sheet ─────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.current,
  });
  final String title;
  final List<String> options;
  final String current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            for (final o in options)
              ListTile(
                title: Text(o),
                trailing: o == current
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.brandRed)
                    : null,
                onTap: () => Navigator.of(context).pop(o),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable rows ────────────────────────────────────────────────────────────

class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: Color(0xFFEFEFEF),
              ),
          ]
        ],
      ),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  const _ChevronRow({
    required this.label,
    required this.onTap,
    this.trailingText,
    this.trailing,
  });
  final String label;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final right = trailing ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(trailingText!,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF8A8A8A))),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB0B0B0), size: 22),
          ],
        );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  )),
            ),
            right,
          ],
        ),
      ),
    );
  }
}
