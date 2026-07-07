import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/proximity/proximity_engine.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/peer_avatar.dart';

enum _DistanceUnit { feet, meters }

extension on _DistanceUnit {
  String get label => this == _DistanceUnit.feet ? 'ft' : 'mts';
}

/// Find Person — "Find Directions" (DESIGN_SPEC §8, A12).
///
/// Live ranging comes from [ProximityEngine.range]: smoothed distance plus a
/// coarse RSSI-gradient/compass bearing. The arrow eases toward the new
/// bearing (~400 ms) and the distance text count-tweens; when the stream
/// completes the peer was lost and a Retry re-subscribes.
class FindPersonScreen extends StatefulWidget {
  const FindPersonScreen({super.key, required this.card});

  final ProfileCard card;

  @override
  State<FindPersonScreen> createState() => _FindPersonScreenState();
}

class _FindPersonScreenState extends State<FindPersonScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<RangeSample>? _sub;

  double? _meters;

  /// Accumulated bearing in radians (unwrapped so the eased rotation always
  /// takes the short way instead of spinning through a full turn).
  double _bearing = 0;
  bool _lost = false;
  _DistanceUnit _unit = _DistanceUnit.feet;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (!AppServices.I.settings.reduceMotion.value) {
      _pulse.repeat(reverse: true);
    }
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
    setState(() => _lost = false);
    _sub = AppServices.I.engine.range(widget.card.sub).listen(
      (sample) {
        if (!mounted) return;
        setState(() {
          _meters = sample.meters;
          _bearing = _unwrap(from: _bearing, to: sample.bearing);
        });
      },
      onError: (Object _) {
        if (mounted) setState(() => _lost = true);
      },
      onDone: () {
        if (mounted) setState(() => _lost = true);
      },
    );
  }

  /// Returns the angle equivalent to [to] that is closest to [from].
  static double _unwrap({required double from, required double to}) {
    var t = to;
    while (t - from > math.pi) {
      t -= 2 * math.pi;
    }
    while (t - from < -math.pi) {
      t += 2 * math.pi;
    }
    return t;
  }

  String _distanceValue(double meters) {
    if (_unit == _DistanceUnit.feet) {
      return (meters * 3.281).toStringAsFixed(0);
    }
    return meters.toStringAsFixed(meters < 10 ? 1 : 0);
  }

  String get _directionWord {
    // Normalise the accumulated bearing back to -π..π.
    var b = _bearing % (2 * math.pi);
    if (b > math.pi) b -= 2 * math.pi;
    if (b <= -math.pi) b += 2 * math.pi;
    final deg = b * 180 / math.pi;
    if (deg.abs() < 22) return 'front';
    if (deg >= 22 && deg < 112) return 'right';
    if (deg <= -22 && deg > -112) return 'left';
    return 'back';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Red gradient top fading to white
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 1.0],
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
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text('MetAfter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              )),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 22),
                        onPressed: _pickUnit,
                      ),
                    ],
                  ),
                ),

                // ── Person chip ──
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PeerAvatar(
                          card: widget.card, size: 44, showVerified: true),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.card.titleLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Arrow + distance / lost state ──
                Expanded(
                  child: _lost ? _buildLost() : _buildRanging(),
                ),

                // ── Done ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
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

  Widget _buildRanging() {
    final meters = _meters;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // Slight "breathing" pulse (disabled under reduce-motion —
            // the controller simply never runs).
            final scale = 1.0 + 0.05 * _pulse.value;
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedRotation(
            turns: _bearing / (2 * math.pi),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(painter: _ArrowPainter()),
            ),
          ),
        ),
        const SizedBox(height: 28),
        if (meters == null)
          const Text(
            'Locating…',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: meters),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
                children: [
                  TextSpan(
                    text: '${_distanceValue(value)} ${_unit.label} ',
                    style: const TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: 'to your '),
                  TextSpan(
                    text: _directionWord,
                    style: const TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLost() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_tethering_off_rounded,
            size: 64, color: AppColors.brandRed.withValues(alpha: 0.5)),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Signal lost — they may have moved away',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.brandRed),
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _subscribe,
          child: const Text(
            'Retry',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.brandRed,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickUnit() async {
    final picked = await showModalBottomSheet<_DistanceUnit>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Distance unit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ),
            for (final u in _DistanceUnit.values)
              ListTile(
                title: Text(
                    u == _DistanceUnit.feet ? 'Feet (ft)' : 'Meters (mts)'),
                trailing: u == _unit
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.brandRed)
                    : null,
                onTap: () => Navigator.of(ctx).pop(u),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _unit = picked);
  }
}

/// Big rounded arrow pointing "up" (the rotation of the parent transform
/// orients it relative to the user's heading).
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandRed
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.brandRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Shaft
    final shaft = Path()
      ..moveTo(cx, h * 0.85)
      ..lineTo(cx, h * 0.30);
    canvas.drawPath(shaft, stroke);

    // Arrow head (filled triangle)
    final head = Path()
      ..moveTo(cx, h * 0.10)
      ..lineTo(cx - w * 0.18, h * 0.35)
      ..lineTo(cx + w * 0.18, h * 0.35)
      ..close();
    canvas.drawPath(head, paint);

    // Decorative pulse arc (top right)
    final arcPaint = Paint()
      ..color = AppColors.brandRed.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final arcRect = Rect.fromCircle(
      center: Offset(cx + w * 0.05, h * 0.18),
      radius: w * 0.22,
    );
    canvas.drawArc(arcRect, -math.pi / 2, math.pi / 3, false, arcPaint);

    final dotPaint = Paint()..color = AppColors.brandRed;
    canvas.drawCircle(
      Offset(cx + w * 0.27, h * 0.18),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => false;
}
