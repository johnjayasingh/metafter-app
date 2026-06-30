import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'connected_profile_screen.dart';

// ─── Mock data ────────────────────────────────────────────────────────────────

class _EncounteredPerson {
  const _EncounteredPerson({
    required this.name,
    required this.title,
    required this.company,
    required this.photoUrl,
    required this.time,
    this.bio = 'Passionate professional always looking to grow and connect.',
  });
  final String name;
  final String title;
  final String company;
  final String photoUrl;
  final String time;
  final String bio;
}

const _todayEncounters = <_EncounteredPerson>[
  _EncounteredPerson(name: 'Koby Stone', title: 'SVP Engineering', company: 'InnoVision', photoUrl: 'https://i.pravatar.cc/150?img=12', time: '4:28 PM', bio: 'Building scalable systems that power the next generation of products.'),
  _EncounteredPerson(name: 'Luna Ray', title: 'Head of Marketing', company: 'MarketVerse', photoUrl: 'https://i.pravatar.cc/150?img=47', time: '4:24 PM', bio: 'I am a brand sales person who focuses on clarity and emotional connections of clients'),
  _EncounteredPerson(name: 'Owen Hill', title: 'VP, Sales', company: 'SaleSail', photoUrl: 'https://i.pravatar.cc/150?img=49', time: '4:22 PM', bio: 'Driving revenue through strategic partnerships and authentic relationships.'),
  _EncounteredPerson(name: 'Koby Stone', title: 'SVP Engineering', company: 'InnoVision', photoUrl: 'https://i.pravatar.cc/150?img=12', time: '4:18 PM', bio: 'Building scalable systems that power the next generation of products.'),
  _EncounteredPerson(name: 'Luna Ray', title: 'Head of Marketing', company: 'MarketVerse', photoUrl: 'https://i.pravatar.cc/150?img=47', time: '4:12 PM', bio: 'I am a brand sales person who focuses on clarity and emotional connections of clients'),
  _EncounteredPerson(name: 'Owen Hill', title: 'VP, Sales', company: 'SaleSail', photoUrl: 'https://i.pravatar.cc/150?img=49', time: '4:10 PM', bio: 'Driving revenue through strategic partnerships and authentic relationships.'),
  _EncounteredPerson(name: 'Koby Stone', title: 'SVP Engineering', company: 'InnoVision', photoUrl: 'https://i.pravatar.cc/150?img=12', time: '4:04 PM', bio: 'Building scalable systems that power the next generation of products.'),
  _EncounteredPerson(name: 'Luna Ray', title: 'Head of Marketing', company: 'MarketVerse', photoUrl: 'https://i.pravatar.cc/150?img=47', time: '4:02 PM', bio: 'I am a brand sales person who focuses on clarity and emotional connections of clients'),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class DiscoverHistoryScreen extends StatefulWidget {
  const DiscoverHistoryScreen({super.key, this.embedded = false});

  /// When `true`, render the body only (no Scaffold/AppBar) so the screen can
  /// be hosted inside the swipeable [HomeShell] under its shared header.
  final bool embedded;

  @override
  State<DiscoverHistoryScreen> createState() => _DiscoverHistoryScreenState();
}

class _DiscoverHistoryScreenState extends State<DiscoverHistoryScreen> {
  bool _grid = false;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                const Expanded(child: Text('People You Crossed Paths', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black))),
                _ViewToggle(grid: _grid, onChanged: (v) => setState(() => _grid = v)),
                const SizedBox(width: 12),
                IconButton(icon: const Icon(Icons.calendar_today_outlined, color: Colors.black, size: 22), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFFCE4E1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Text('Today - 25 Jan, 2026', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brandRed)),
          ),
          Expanded(
            child: _grid
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: _todayEncounters.length,
                    itemBuilder: (context, index) => _EncounterTile(person: _todayEncounters[index], layout: _EncounterLayout.grid),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _todayEncounters.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 148, endIndent: 20, color: Color(0xFFF0F0F0)),
                    itemBuilder: (context, index) => _EncounterTile(person: _todayEncounters[index]),
                  ),
          ),
        ],
      );

    if (widget.embedded) return ColoredBox(color: Colors.white, child: body);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Discover', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
        centerTitle: true,
      ),
      body: body,
    );
  }
}

// ─── List ⟷ grid view toggle ──────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});
  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(icon: Icons.view_agenda_outlined, selected: !grid, onTap: () => onChanged(false)),
          _segment(icon: Icons.grid_view_rounded, selected: grid, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment({required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: selected ? AppColors.brandRed : const Color(0xFF8A8A8A)),
      ),
    );
  }
}

// ─── Encounter tile ───────────────────────────────────────────────────────────

enum _EncounterLayout { list, grid }

class _EncounterTile extends StatefulWidget {
  const _EncounterTile({required this.person, this.layout = _EncounterLayout.list});
  final _EncounteredPerson person;
  final _EncounterLayout layout;

  @override
  State<_EncounterTile> createState() => _EncounterTileState();
}

class _EncounterTileState extends State<_EncounterTile> {
  bool _connected = false;
  String _inviteNote = '';

  Future<void> _onConnect() async {
    final note = await showDialog<String?>(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => const _InviteNoteDialog(),
    );
    if (note == null || !mounted) return;
    setState(() { _connected = true; _inviteNote = note; });
  }

  void _openProfile() {
    final p = widget.person;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ConnectedProfileScreen(
        name: p.name, title: p.title, company: p.company,
        bio: p.bio, photoUrl: p.photoUrl,
        inviteNote: _inviteNote.isEmpty ? null : _inviteNote,
      ),
    ));
  }

  Widget _avatar(double size) => ClipOval(
        child: Image.network(widget.person.photoUrl, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => _InitialCircle(name: widget.person.name, size: size)),
      );

  Widget _connectButton({bool fullWidth = false}) {
    if (_connected) {
      return Container(
        width: fullWidth ? double.infinity : null,
        alignment: fullWidth ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
        child: const Text('Requested', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8A8A8A))),
      );
    }
    final button = FilledButton(
      onPressed: _onConnect,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandRed,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Connect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  @override
  Widget build(BuildContext context) {
    return widget.layout == _EncounterLayout.grid ? _buildGrid() : _buildList();
  }

  Widget _buildList() {
    final p = widget.person;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(p.time, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)))),
          const SizedBox(width: 8),
          GestureDetector(onTap: _openProfile, child: _avatar(52)),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _openProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
                  Text(p.title, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B))),
                  Text(p.company, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _connectButton(),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final p = widget.person;
    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(44),
                const Spacer(),
                Text(p.time, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A))),
              ],
            ),
            const SizedBox(height: 10),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 2),
            Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
            Text(p.company, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
            const Spacer(),
            _connectButton(fullWidth: true),
          ],
        ),
      ),
    );
  }
}

// ─── Invite note dialog ───────────────────────────────────────────────────────

class _InviteNoteDialog extends StatefulWidget {
  const _InviteNoteDialog();
  @override
  State<_InviteNoteDialog> createState() => _InviteNoteDialogState();
}

class _InviteNoteDialogState extends State<_InviteNoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add a note to your invitation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
            const SizedBox(height: 16),
            Container(
              height: 130,
              decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Ex: We met at the expo ....',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(''),
                    child: const Center(child: Text('Skip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B6B6B)))),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Send', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.name, this.size = 52});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE3C8B5)),
      child: Center(child: Text(initials.toUpperCase(), style: TextStyle(fontSize: size * 0.3, fontWeight: FontWeight.w700, color: Colors.white))),
    );
  }
}
