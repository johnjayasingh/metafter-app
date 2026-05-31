import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum PrivacyVisibility { visibleToAll, visibleToConnections, hidden }

extension on PrivacyVisibility {
  String get label {
    switch (this) {
      case PrivacyVisibility.visibleToAll:
        return 'Visible to all';
      case PrivacyVisibility.visibleToConnections:
        return 'Visible to connections';
      case PrivacyVisibility.hidden:
        return 'Hidden';
    }
  }
}

/// Privacy & Security configuration screen.
///
/// Lets the user control which fields of their profile are visible to whom,
/// and toggle call / disappearing-message features that are reused for the
/// per-contact privacy block in [ConnectedProfileScreen].
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  PrivacyVisibility _name = PrivacyVisibility.visibleToAll;
  PrivacyVisibility _company = PrivacyVisibility.hidden;
  bool _videoCall = false;
  bool _audioCall = true;
  bool _disappearingMessages = false;

  Future<void> _editVisibility(
    String title,
    PrivacyVisibility current,
    ValueChanged<PrivacyVisibility> onPicked,
  ) async {
    final picked = await showModalBottomSheet<PrivacyVisibility>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(height: 8),
              for (final option in PrivacyVisibility.values)
                ListTile(
                  title: Text(option.label),
                  trailing: option == current
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.brandRed)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(option),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) onPicked(picked);
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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Privacy & Security',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                )),
          ),
          _RowGroup(rows: [
            _ChevronRow(
              label: 'Name',
              value: _name.label,
              onTap: () => _editVisibility('Name', _name,
                  (v) => setState(() => _name = v)),
            ),
            _ChevronRow(
              label: 'Company Name',
              value: _company.label,
              onTap: () => _editVisibility('Company Name', _company,
                  (v) => setState(() => _company = v)),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text('PRIVACY PREFERNCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Color(0xFF8A8A8A),
                )),
          ),
          _RowGroup(rows: [
            _ChevronRow(
              label: 'Video Call',
              value: _videoCall ? 'Enabled' : 'Disabled',
              onTap: () => setState(() => _videoCall = !_videoCall),
            ),
            _ChevronRow(
              label: 'Audio Call',
              value: _audioCall ? 'Enabled' : 'Disabled',
              onTap: () => setState(() => _audioCall = !_audioCall),
            ),
            _ChevronRow(
              label: 'Disappearing Messages',
              value: _disappearingMessages ? 'Enabled' : 'Disabled',
              onTap: () => setState(
                  () => _disappearingMessages = !_disappearingMessages),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Text(
              'For added privacy, you can set who can call you and who can save your chats.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8A8A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable row widgets (also used by profile_settings_screen) ──────────────

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
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            Text(value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8A8A),
                )),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB0B0B0), size: 22),
          ],
        ),
      ),
    );
  }
}
