import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'pricing_screen.dart';
import 'privacy_security_screen.dart';

/// User's own profile + settings home.
///
/// Reached from the gear icon on the centre avatar in [DiscoveryHomeScreen].
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _mood = 'Networking';
  String _language = 'English';
  String _accessibility = 'Back Tap';
  String _discoverableTime = '4 hrs';
  String _proximityDistance = '2 mts';

  static const _moodOptions = <({String label, Color color})>[
    (label: 'Networking', color: AppColors.brandRed),
    (label: 'Social', color: Color(0xFFF59E0B)),
    (label: 'Dating', color: Color(0xFFEC4899)),
    (label: 'Do not disturb', color: Color(0xFF6B7280)),
  ];
  static const _languageOptions = <String>[
    'English',
    'Spanish',
    'French',
    'German',
    'Japanese',
  ];
  static const _accessibilityOptions = <String>[
    'Back Tap',
    'Voice Over',
    'Larger Text',
    'High Contrast',
  ];
  static const _timeOptions = <String>['1 hr', '2 hrs', '4 hrs', '8 hrs'];
  static const _distanceOptions = <String>['1 mt', '2 mts', '5 mts', '10 mts'];

  Future<String?> _pickFromList(String title, List<String> options,
      String current) async {
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
    final picked = await showModalBottomSheet<String>(
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Set Mood Ring',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            for (final m in _moodOptions)
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
                trailing: m.label == _mood
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.brandRed)
                    : null,
                onTap: () => Navigator.of(ctx).pop(m.label),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _mood = picked);
  }

  Color get _moodColor =>
      _moodOptions.firstWhere((m) => m.label == _mood).color;

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing profile (mock)')),
    );
  }

  void _openPro() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _UpgradeProDialog(),
    );
  }

  void _seeProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open public profile (mock)')),
    );
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _ProfileHeader(
            name: 'Luna Ray',
            title: 'VP, Sales',
            company: 'SaleSail',
            photoUrl: 'https://i.pravatar.cc/300?img=47',
            onSeeProfile: _seeProfile,
          ),
          const SizedBox(height: 18),
          _RowGroup(rows: [
            _ChevronRow(
              label: 'Set Mood Ring',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _moodColor, width: 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_mood,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF8A8A8A))),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFB0B0B0), size: 22),
                ],
              ),
              onTap: _pickMood,
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
            _ChevronRow(
              label: 'Language',
              trailingText: _language,
              onTap: () async {
                final v = await _pickFromList(
                    'Language', _languageOptions, _language);
                if (v != null) setState(() => _language = v);
              },
            ),
            _ChevronRow(
              label: 'Accessibility',
              trailingText: _accessibility,
              onTap: () async {
                final v = await _pickFromList('Accessibility',
                    _accessibilityOptions, _accessibility);
                if (v != null) setState(() => _accessibility = v);
              },
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
            _ChevronRow(
              label: 'Discoverable Time',
              trailingText: _discoverableTime,
              onTap: () async {
                final v = await _pickFromList('Discoverable Time',
                    _timeOptions, _discoverableTime);
                if (v != null) setState(() => _discoverableTime = v);
              },
            ),
            _ChevronRow(
              label: 'Proximity Distance',
              trailingText: _proximityDistance,
              onTap: () async {
                final v = await _pickFromList('Proximity Distance',
                    _distanceOptions, _proximityDistance);
                if (v != null) setState(() => _proximityDistance = v);
              },
            ),
          ]),
          const SizedBox(height: 18),
          _GetProButton(onTap: _openPro),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.title,
    required this.company,
    required this.photoUrl,
    required this.onSeeProfile,
  });
  final String name;
  final String title;
  final String company;
  final String photoUrl;
  final VoidCallback onSeeProfile;

  @override
  Widget build(BuildContext context) {
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
              child: Image.network(
                photoUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFE3C8B5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    )),
                const SizedBox(height: 2),
                Text('$title - $company',
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
                  'Access to all basic features &',
                  'Unlimited connection requests',
                  'Invitation note to 5 individual users',
                  'Priority chat and email support',
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
                            content: Text('Pro Plan checkout (mock)')),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
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
                  ? const Icon(Icons.check_rounded, color: AppColors.brandRed)
                  : null,
              onTap: () => Navigator.of(context).pop(o),
            ),
          const SizedBox(height: 8),
        ],
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
