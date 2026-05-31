import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Voice or video call screen.
///
/// Driven by [isVideo] — switches between a full-bleed remote video preview
/// (with self-PIP) and a centered avatar voice-only layout. Both share the
/// same control bar (mute, speaker, camera toggle, end call).
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.isVideo,
  });

  final String name;
  final String photoUrl;
  final bool isVideo;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _muted = false;
  bool _speakerOn = false;
  bool _cameraOn = true;
  bool _connecting = true;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate "Connecting..." → connected after 1.5 s, then start ticking.
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _connecting = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background — for video call, a faux remote feed; for voice, a
            // soft gradient.
            Positioned.fill(
              child: widget.isVideo
                  ? _VideoStage(photoUrl: widget.photoUrl)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2A0A0B),
                            Color(0xFF7A1417),
                            Color(0xFFB81B20),
                          ],
                        ),
                      ),
                    ),
            ),

            // Top: name + status + close
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  if (widget.isVideo)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cameraswitch_outlined,
                          color: Colors.white, size: 22),
                    ),
                ],
              ),
            ),

            // Voice-only avatar block
            if (!widget.isVideo)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          widget.photoUrl,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 130,
                            height: 130,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(widget.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      _connecting ? 'Connecting…' : _fmt(_elapsed),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

            // Video: name + timer overlay near top
            if (widget.isVideo)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(widget.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ],
                        )),
                    const SizedBox(height: 4),
                    Text(
                      _connecting ? 'Connecting…' : _fmt(_elapsed),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 6, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallControl(
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        active: _muted,
                        label: 'Mute',
                        onTap: () => setState(() => _muted = !_muted),
                      ),
                      _CallControl(
                        icon: _speakerOn
                            ? Icons.volume_up
                            : Icons.volume_up_outlined,
                        active: _speakerOn,
                        label: 'Speaker',
                        onTap: () =>
                            setState(() => _speakerOn = !_speakerOn),
                      ),
                      if (widget.isVideo)
                        _CallControl(
                          icon: _cameraOn
                              ? Icons.videocam
                              : Icons.videocam_off,
                          active: !_cameraOn,
                          label: 'Camera',
                          onTap: () =>
                              setState(() => _cameraOn = !_cameraOn),
                        )
                      else
                        _CallControl(
                          icon: Icons.videocam_outlined,
                          active: false,
                          label: 'Video',
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => CallScreen(
                                  name: widget.name,
                                  photoUrl: widget.photoUrl,
                                  isVideo: true,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.brandRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({required this.photoUrl});
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Faux remote feed: blurred portrait
        Image.network(photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black87)),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        // Self preview PIP
        Positioned(
          top: 110,
          right: 16,
          child: Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white38, size: 48),
            ),
          ),
        ),
      ],
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.active,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: active ? Colors.black : Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
