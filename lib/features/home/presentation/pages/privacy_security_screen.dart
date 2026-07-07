import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';

/// Privacy & Security configuration screen (DESIGN_SPEC §11.2).
///
/// Every toggle persists through [SettingsRepository]. The visibility rows
/// (Name / Company) shape the profile card broadcast to strangers over BLE;
/// the switches govern messaging/calling behavior and scanning mode.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  SettingsRepository get _settings => AppServices.I.settings;

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
            ValueListenableBuilder<PrivacyVisibility>(
              valueListenable: _settings.nameVisibility,
              builder: (_, v, _) => _ChevronRow(
                label: 'Name',
                value: v.label,
                onTap: () =>
                    _editVisibility('Name', v, _settings.setNameVisibility),
              ),
            ),
            ValueListenableBuilder<PrivacyVisibility>(
              valueListenable: _settings.companyVisibility,
              builder: (_, v, _) => _ChevronRow(
                label: 'Company Name',
                value: v.label,
                onTap: () => _editVisibility(
                    'Company Name', v, _settings.setCompanyVisibility),
              ),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text('PRIVACY PREFERENCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Color(0xFF8A8A8A),
                )),
          ),
          _RowGroup(rows: [
            _SwitchRow(
              label: 'Read Receipts',
              listenable: _settings.readReceipts,
              onChanged: _settings.setReadReceipts,
            ),
            _SwitchRow(
              label: 'Typing Indicator',
              listenable: _settings.typingIndicator,
              onChanged: _settings.setTypingIndicator,
            ),
            _SwitchRow(
              label: 'Video Call',
              listenable: _settings.allowVideoCall,
              onChanged: _settings.setAllowVideoCall,
            ),
            _SwitchRow(
              label: 'Audio Call',
              listenable: _settings.allowAudioCall,
              onChanged: _settings.setAllowAudioCall,
            ),
            _SwitchRow(
              label: 'Disappearing Messages',
              listenable: _settings.disappearingDefault,
              onChanged: _settings.setDisappearingDefault,
            ),
            _SwitchRow(
              label: 'Show Company Name',
              listenable: _settings.showCompany,
              onChanged: _settings.setShowCompany,
            ),
            _SwitchRow(
              label: 'Show Designation',
              listenable: _settings.showDesignation,
              onChanged: _settings.setShowDesignation,
            ),
            _SwitchRow(
              label: 'Incognito Scan',
              listenable: _settings.incognitoScan,
              onChanged: _settings.setIncognitoScan,
            ),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Text(
              'Visibility settings shape the profile card broadcast to people '
              'nearby over Bluetooth — hidden fields never leave your device. '
              'The switches control read receipts and typing indicators in '
              'chats, who can call you, the default for disappearing messages, '
              'and Incognito Scan (see others without being seen).',
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

// ─── Reusable row widgets ─────────────────────────────────────────────────────

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

/// A settings row with a real [Switch] bound to a persisted
/// [ValueListenable] from the settings repository.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.listenable,
    required this.onChanged,
  });
  final String label;
  final ValueListenable<bool> listenable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (_, value, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
            Switch(
              value: value,
              activeTrackColor: AppColors.brandRed,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
