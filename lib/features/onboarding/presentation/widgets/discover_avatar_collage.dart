import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A floating cluster of circular avatars used at the top of the
/// onboarding screen. Avatars are pulled from the public `pravatar.cc`
/// service so the screen renders without bundled images; replace with
/// real assets/URLs once available.
class DiscoverAvatarCollage extends StatelessWidget {
  const DiscoverAvatarCollage({super.key});

  // (xFraction, yFraction, diameter, pravatarId)
  static const List<_Avatar> _avatars = [
    _Avatar(0.05, 0.78, 60, 11),
    _Avatar(0.06, 0.42, 78, 12),
    _Avatar(0.25, 0.70, 80, 13),
    _Avatar(0.24, 0.18, 70, 14),
    _Avatar(0.43, 0.48, 92, 15),
    _Avatar(0.42, 0.10, 60, 16),
    _Avatar(0.62, 0.30, 70, 17),
    _Avatar(0.60, 0.55, 90, 18),
    _Avatar(0.78, 0.18, 60, 19),
    _Avatar(0.81, 0.50, 78, 20),
    _Avatar(0.88, 0.40, 60, 21),
    _Avatar(0.53, 0.78, 72, 22),
    _Avatar(0.73, 0.78, 56, 23),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final a in _avatars)
              Positioned(
                left: a.x * w - a.size / 2,
                top: a.y * h - a.size / 2,
                child: _AvatarCircle(size: a.size, pravatarId: a.pravatarId),
              ),
          ],
        );
      },
    );
  }
}

class _Avatar {
  const _Avatar(this.x, this.y, this.size, this.pravatarId);
  final double x;
  final double y;
  final double size;
  final int pravatarId;
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.size, required this.pravatarId});

  final double size;
  final int pravatarId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _fallbackColor(pravatarId),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage('https://i.pravatar.cc/200?img=$pravatarId'),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
    );
  }

  Color _fallbackColor(int seed) {
    final palette = [
      AppColors.brandRed.withValues(alpha: 0.6),
      AppColors.brandRedSoft,
      AppColors.brandRedDeep.withValues(alpha: 0.5),
      Colors.white,
    ];
    return palette[seed % palette.length];
  }
}