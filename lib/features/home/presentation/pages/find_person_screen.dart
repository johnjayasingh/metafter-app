import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum _DistanceUnit { feet, meters }

extension on _DistanceUnit {
  String get label => this == _DistanceUnit.feet ? 'ft' : 'mts';
}

/// Live "find a connection" proximity screen.
///
/// Reached after a connection request is accepted (e.g. tapping the
/// `Find {Name}` button on the Connect screen, or `Connect` on the nearby
/// profile card). Shows a directional arrow and a live-updating distance in
/// the user's chosen unit.
class FindPersonScreen extends StatefulWidget {
  const FindPersonScreen({
    super.key,
    required this.name,
    required this.title,
    required this.company,
    required this.photoUrl,
  });

  final String name;
  final String title;
  final String company;
  final String? photoUrl;

  @override
  State<FindPersonScreen> createState() => _FindPersonScreenState();
}

class _FindPersonScreenState extends State<FindPersonScreen>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  // Live state — initial mock values.
  double _meters = 6.1; // ≈ 20 ft
  // Heading in radians, measured clockwise from "straight ahead" (up). 0 = up,
  // π/2 = right, -π/2 = left, π = behind.
  double _bearing = math.pi / 4; // 45° → "to your right"
  _DistanceUnit _unit = _DistanceUnit.feet;

  late final AnimationController _arrowAnim;

  @override
  void initState() {
    super.initState();
    _arrowAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Simulate the user closing in on the target — distance drifts down with
    // some noise; bearing wobbles a little.
    final rng = math.Random();
    _ticker = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      setState(() {
        _meters =
            (_meters - 0.15 + rng.nextDouble() * 0.1).clamp(0.5, 50.0);
        _bearing += (rng.nextDouble() - 0.5) * 0.2;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _arrowAnim.dispose();
    super.dispose();
  }

  String get _distanceValue {
    if (_unit == _DistanceUnit.feet) {
      return (_meters * 3.281).toStringAsFixed(0);
    }
    return _meters.toStringAsFixed(_meters < 10 ? 1 : 0);
  }

  String get _directionWord {
    // Bearing: -π..π, normalise to -π..π.
    var b = _bearing;
    while (b > math.pi) {
      b -= 2 * math.pi;
    }
    while (b < -math.pi) {
      b += 2 * math.pi;
    }
    final deg = b * 180 / math.pi;
    if (deg.abs() < 22) return 'ahead';
    if (deg >= 22 && deg < 67) return 'to your right';
    if (deg >= 67 && deg < 112) return 'to your right';
    if (deg >= 112) return 'behind you';
    if (deg <= -22 && deg > -67) return 'to your left';
    if (deg <= -67 && deg > -112) return 'to your left';
    return 'behind you';
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

                // ── Avatar ──
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: widget.photoUrl != null
                        ? Image.network(
                            widget.photoUrl!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(96),
                          )
                        : _placeholder(96),
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
                const SizedBox(height: 4),
                Text('${widget.title} - ${widget.company}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    )),

                // ── Arrow + distance ──
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _arrowAnim,
                        builder: (context, _) {
                          // Slight "breathing" pulse.
                          final scale = 1.0 + 0.05 * _arrowAnim.value;
                          return Transform.scale(
                            scale: scale,
                            child: Transform.rotate(
                              angle: _bearing,
                              child: SizedBox(
                                width: 200,
                                height: 200,
                                child: CustomPaint(
                                  painter: _ArrowPainter(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                          children: [
                            TextSpan(
                              text: '$_distanceValue ${_unit.label} ',
                              style: const TextStyle(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: 'to your '),
                            TextSpan(
                              text: _directionWord
                                  .replaceAll('to your ', '')
                                  .replaceAll('ahead', 'front'),
                              style: const TextStyle(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        color: const Color(0xFFE3C8B5),
        child: const Icon(Icons.person, color: Colors.white, size: 48),
      );

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
                title: Text(u == _DistanceUnit.feet ? 'Feet (ft)'
                    : 'Meters (mts)'),
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
    if (picked != null) setState(() => _unit = picked);
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
