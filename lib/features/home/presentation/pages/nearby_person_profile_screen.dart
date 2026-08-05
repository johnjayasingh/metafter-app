import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/peer_avatar.dart';
import '../widgets/invite_note_dialog.dart';

/// Nearby Person Profile — "Bubble Tap" (DESIGN_SPEC §5).
///
/// Full-screen brand-red gradient page shown when a peer bubble (Meet) or a
/// Discover row is tapped. Data comes from the peer's [ProfileCard] snapshot
/// already cached at sighting time; Connect runs the invite-note +
/// send-request flow and flips to a disabled "Request Sent".
class NearbyPersonProfileScreen extends StatefulWidget {
  const NearbyPersonProfileScreen({
    super.key,
    required this.card,
    this.encounterId,
    this.meters,
    this.selfPreview = false,
  });

  final ProfileCard card;

  /// Discover-ledger row to link the outgoing request back to.
  final String? encounterId;

  /// Last estimated distance — shows the "x.x mtr away" chip when known.
  final double? meters;

  /// True when this is the user looking at their OWN card as peers see it.
  /// Same layout, but the peer actions make no sense on yourself — you cannot
  /// send yourself a connect request.
  final bool selfPreview;

  @override
  State<NearbyPersonProfileScreen> createState() =>
      _NearbyPersonProfileScreenState();
}

class _NearbyPersonProfileScreenState extends State<NearbyPersonProfileScreen> {
  bool _sent = false;
  bool _sending = false;

  Future<void> _connect() async {
    if (_sent || _sending) return;
    setState(() => _sending = true);
    final sent = await sendConnectRequestFlow(
      context,
      toCard: widget.card,
      encounterId: widget.encounterId,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = sent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final meters = widget.meters;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandSunset),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar: back arrow + wordmark ──
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
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              PeerAvatar(
                card: card,
                size: 120,
                showVerified: true,
                ringColor: Colors.white,
                ringWidth: 3,
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  card.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  card.titleLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),

              if (meters != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${meters.toStringAsFixed(1)} mtr away',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  card.intro,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(),

              // ── Connect / Request Sent ──
              // Absent in self-preview: the point of that screen is to show
              // what peers see, and you are not a peer of yourself.
              if (!widget.selfPreview)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF03D33),
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _sent || _sending ? null : _connect,
                      child: Text(
                        _sent ? 'Request Sent' : 'Connect',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _sent
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Text(
                    'This is how your card looks to people nearby.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
