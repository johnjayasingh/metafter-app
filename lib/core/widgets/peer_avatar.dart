import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/models.dart';

/// Circular avatar for a [ProfileCard]: decodes the card's base64 photo
/// thumbnail, falls back to initials on a tinted disc. Optionally draws a
/// mood ring and the verified badge. Used by the radar, Discover, requests,
/// messages and profile screens — do not hand-roll avatar rendering
/// elsewhere.
class PeerAvatar extends StatelessWidget {
  const PeerAvatar({
    super.key,
    required this.card,
    this.size = 48,
    this.mood,
    this.showVerified = false,
    this.ringWidth = 2.5,
    this.ringColor,
  });

  final ProfileCard card;
  final double size;

  /// When non-null, draws the mood ring color around the avatar.
  final MoodRing? mood;
  final bool showVerified;
  final double ringWidth;

  /// Overrides the ring color (defaults to [mood]'s color when set).
  final Color? ringColor;

  static final Map<String, Uint8List> _decodeCache = <String, Uint8List>{};

  Uint8List? get _photoBytes {
    final b64 = card.photoBase64;
    if (b64 == null || b64.isEmpty) return null;
    final cached = _decodeCache[b64];
    if (cached != null) return cached;
    try {
      final bytes = base64Decode(b64);
      if (_decodeCache.length > 64) _decodeCache.clear();
      _decodeCache[b64] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ring = ringColor ?? mood?.color;
    final bytes = _photoBytes;

    Widget avatar = ClipOval(
      child: bytes != null
          ? Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          : Container(
              width: size,
              height: size,
              color: _initialsBg,
              alignment: Alignment.center,
              child: Text(
                card.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.36,
                ),
              ),
            ),
    );

    if (ring != null) {
      avatar = Container(
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: ringWidth),
        ),
        child: avatar,
      );
    }

    if (showVerified && card.verified) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                size: size * 0.28,
                color: const Color(0xFF119BFB),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: size + (ring != null ? ringWidth * 4 : 0),
      height: size + (ring != null ? ringWidth * 4 : 0),
      child: Center(child: avatar),
    );
  }

  /// Stable per-person tint derived from the name.
  Color get _initialsBg {
    const palette = [
      Color(0xFF7C3AED),
      Color(0xFF0EA5E9),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFFDB2777),
      Color(0xFF475569),
    ];
    return palette[card.name.hashCode.abs() % palette.length];
  }
}
