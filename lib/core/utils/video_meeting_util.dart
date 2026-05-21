import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoMeetingScreen extends StatefulWidget {
  final String appId;
  final String token;
  final String channel;
  final int uid;

  final Future<void> Function()? onStartRecording;
  final Future<void> Function()? onStopRecording;
  final Future<void> Function()? onLeaveMeeting;

  const VideoMeetingScreen({
    super.key,
    required this.appId,
    required this.token,
    required this.channel,
    required this.uid,
    this.onStartRecording,
    this.onStopRecording,
    this.onLeaveMeeting,
  });

  @override
  State<VideoMeetingScreen> createState() => _VideoMeetingScreenState();
}

class _VideoMeetingScreenState extends State<VideoMeetingScreen> {
  late final RtcEngine _engine;
  bool _isInitialized = false;
  bool _isLeaving = false;
  bool _screenShareBusy = false; // guard against double-tap during async op

  /// All remote UIDs that have joined (camera participants).
  List<int> _remoteUsers = [];

  /// Remote UIDs whose primary video stream is currently ACTIVE
  Set<int> _remoteVideoActive = {};

  /// Remote UIDs that appear to be sharing their screen.
  /// Agora sends a second simultaneous video stream on a different source;
  /// we detect it via onRemoteVideoStateChanged fired right after join.
  /// Key heuristic: if any remote video becomes active BEFORE we have started
  /// our own screen share, we assume that user is already sharing their screen.
  Set<int> _remoteScreenSharers = {};

  bool isJoined = false;
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isScreenSharing = false;
  bool isRecording = false;
  bool _recordingPending = false;
  bool isMinimized = false;

  /// True when auto-start was skipped because a remote participant was already
  /// sharing.  Shown to the user as an info banner.
  bool _autoStartSkipped = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: widget.appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) {
            setState(() => isJoined = true);
            // Wait 2 s for existing remote participants' video-state events to
            // arrive before deciding whether to auto-start screen share/recording.
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _startScreenShareThenRecord();
            });
          }
        },

        onUserJoined: (connection, uid, elapsed) {
          if (!mounted) return;
          // Only skip our own UID echo. All other UIDs (including Agora
          // cloud-recording bots) are rendered — bots send no video so
          // their tile stays black but causes no harm. Filtering by a
          // numeric threshold was incorrectly blocking real participants.
          if (uid == widget.uid) return;
          debugPrint('[Agora] onUserJoined uid=$uid');
          setState(() {
            if (!_remoteUsers.contains(uid)) _remoteUsers.add(uid);
          });
        },

        onUserOffline: (connection, uid, reason) {
          if (!mounted) return;
          setState(() {
            _remoteUsers.remove(uid);
            _remoteVideoActive.remove(uid);
          });
        },

        onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
          if (!mounted) return;
          if (remoteUid == widget.uid) return;
          debugPrint('[Agora] onRemoteVideoStateChanged uid=$remoteUid state=$state reason=$reason');
          final active = state == RemoteVideoState.remoteVideoStateDecoding ||
              state == RemoteVideoState.remoteVideoStateStarting;
          setState(() {
            if (active) {
              _remoteVideoActive.add(remoteUid);
              // Safety: add to list in case onUserJoined was missed.
              if (!_remoteUsers.contains(remoteUid)) _remoteUsers.add(remoteUid);
              // If we have not yet started our own screen share, treat any
              // incoming remote video as a remote screen-share in progress.
              if (!isScreenSharing) {
                _remoteScreenSharers.add(remoteUid);
                debugPrint('[Agora] Remote screen share detected from uid=$remoteUid');
              }
            } else if (state == RemoteVideoState.remoteVideoStateStopped ||
                state == RemoteVideoState.remoteVideoStateFailed) {
              _remoteVideoActive.remove(remoteUid);
              _remoteScreenSharers.remove(remoteUid);
            }
          });
        },

        onError: (err, msg) {
          debugPrint('[Agora] Error $err: $msg');
        },

        onLocalVideoStateChanged: (source, state, error) {
          debugPrint('[Agora] localVideoState source=$source state=$state error=$error');
        },

        onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
          debugPrint('[Agora] remoteAudio uid=$remoteUid state=$state');
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.enableAudio();

    // Required in Agora 6.x: set encoder config so the local video track
    // is properly initialized before joining. Without this the camera feed
    // is never encoded and remote participants receive nothing.
    await _engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 800,
        orientationMode: OrientationMode.orientationModeAdaptive,
        mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
      ),
    );

    // Explicitly enable local video capture (enableVideo() enables the module
    // but enableLocalVideo(true) starts the actual camera capture pipeline).
    await _engine.enableLocalVideo(true);
    await _engine.startPreview();

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channel,
      uid: widget.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        publishScreenCaptureVideo: false,
        publishScreenCaptureAudio: false,
      ),
    );

    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _leaveMeeting() async {
    if (!_isInitialized || _isLeaving) return;
    _isLeaving = true;

    if (isRecording && widget.onStopRecording != null) {
      await Future.delayed(const Duration(seconds: 3));
      await widget.onStopRecording!();
      if (mounted) setState(() { isRecording = false; MeetingOverlay.recordingActive = false; });
    }

    if (isScreenSharing) {
      try {
        await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
        ));
        await _engine.stopScreenCapture();
      } catch (_) {}
      if (mounted) setState(() => isScreenSharing = false);
    }

    await _engine.leaveChannel();
    await _engine.release();

    await widget.onLeaveMeeting?.call();
  }

  Future<void> _toggleMic() async {
    if (!_isInitialized) return;
    setState(() => isMicOn = !isMicOn);
    await _engine.muteLocalAudioStream(!isMicOn);
  }

  Future<void> _toggleCamera() async {
    if (!_isInitialized) return;
    setState(() => isCameraOn = !isCameraOn);

    if (isScreenSharing) {
      // While screen sharing the camera track is not published.
      // But we keep the local preview pipeline alive so the mini strip
      // still shows the camera — just mute/unmute local video stream.
      await _engine.muteLocalVideoStream(!isCameraOn);
      return;
    }

    if (isCameraOn) {
      await _engine.enableLocalVideo(true);
      await _engine.muteLocalVideoStream(false);
      await _engine.startPreview();
    } else {
      await _engine.muteLocalVideoStream(true);
      await _engine.enableLocalVideo(false);
      await _engine.stopPreview();
    }
  }

  Future<void> _toggleScreenShare() async {
    if (!_isInitialized || _screenShareBusy) return;
    setState(() => _screenShareBusy = true);

    try {
      if (!isScreenSharing) {
        // ── START ─────────────────────────────────────────────────────────
        // Clear skip flag — user is manually starting, always allow.
        if (mounted) setState(() { _autoStartSkipped = false; _remoteScreenSharers.clear(); });

        // Step 1: Stop PUBLISHING the camera track (keep preview alive so
        //         the mini-strip camera tile still works).
        await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
          publishCameraTrack: false,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));

        // Step 2: Start screen capture — triggers system permission dialog on
        //         Android. captureAudio:false avoids extra permission prompts.
        await _engine.startScreenCapture(
          const ScreenCaptureParameters2(captureVideo: true, captureAudio: false),
        );

        // Step 3: Wait for the MediaProjection surface to attach.
        //         500 ms is safer than 300 ms for slower devices.
        await Future.delayed(const Duration(milliseconds: 500));

        // Step 4: Publish the screen track.
        await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
          publishScreenCaptureVideo: true,
          publishScreenCaptureAudio: false,
          publishCameraTrack: false,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));

        if (mounted) setState(() => isScreenSharing = true);
      } else {
        // ── STOP ──────────────────────────────────────────────────────────
        // Step 1: Stop publishing the screen track.
        await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
          publishCameraTrack: false,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));

        // Step 2: Stop the screen capture pipeline.
        await _engine.stopScreenCapture();

        // Step 3: Re-enable local video BEFORE publishing so Android re-attaches
        //         the camera to the pipeline. Wait for it to stabilise.
        if (isCameraOn) {
          await _engine.enableLocalVideo(true);
          await _engine.muteLocalVideoStream(false);
          await _engine.startPreview();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Step 4: Resume publishing camera.
        await _engine.updateChannelMediaOptions(ChannelMediaOptions(
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
          publishCameraTrack: isCameraOn,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));

        if (mounted) setState(() => isScreenSharing = false);
      }
    } finally {
      if (mounted) setState(() => _screenShareBusy = false);
    }
  }

  /// Called automatically once we join the channel (after a 2 s settle delay).
  /// Step 1 — triggers the system screen-share picker (user selects what to share).
  /// Step 2 — once the screen capture is confirmed active, starts cloud recording.
  /// Skipped entirely if a remote participant is already sharing their screen.
  Future<void> _startScreenShareThenRecord() async {
    if (!_isInitialized || _screenShareBusy) return;

    // ── Guard: skip if someone else is already sharing ───────────────────
    if (_remoteScreenSharers.isNotEmpty) {
      debugPrint('[Agora] Skipping auto screen-share/recording — remote screen share active from: $_remoteScreenSharers');
      if (mounted) setState(() => _autoStartSkipped = true);
      return;
    }

    setState(() => _screenShareBusy = true);

    try {
      // ── Step 1: Start screen sharing ──────────────────────────────────
      // Unpublish camera so the screen track is the primary stream.
      await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ));

      // Launch system screen-capture picker. The user selects which screen /
      // app to share — this returns after the picker is dismissed.
      await _engine.startScreenCapture(
        const ScreenCaptureParameters2(captureVideo: true, captureAudio: false),
      );

      // Give Android's MediaProjection surface time to attach.
      await Future.delayed(const Duration(milliseconds: 800));

      // Publish the screen track.
      await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
        publishScreenCaptureVideo: true,
        publishScreenCaptureAudio: false,
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ));

      if (mounted) setState(() => isScreenSharing = true);

      // ── Step 2: Start cloud recording ─────────────────────────────────
      // Wait a moment so the Agora cloud bot joins and picks up the stream.
      if (mounted) setState(() => _recordingPending = true);
      await Future.delayed(const Duration(seconds: 2));
      await widget.onStartRecording?.call();
      if (mounted) setState(() { _recordingPending = false; isRecording = true; MeetingOverlay.recordingActive = true; });
    } catch (e) {
      debugPrint('[Agora] _startScreenShareThenRecord error: $e');
      if (mounted) setState(() { _screenShareBusy = false; _recordingPending = false; });
    } finally {
      if (mounted) setState(() => _screenShareBusy = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized || !isJoined || _recordingPending) return;
    if (!isRecording) {
      if (mounted) setState(() => _recordingPending = true);
      await Future.delayed(const Duration(seconds: 2));
      await widget.onStartRecording?.call();
      if (mounted) setState(() { _recordingPending = false; isRecording = true; MeetingOverlay.recordingActive = true; });
    } else {
      if (mounted) setState(() => _recordingPending = true);
      await Future.delayed(const Duration(seconds: 3));
      await widget.onStopRecording?.call();
      if (mounted) setState(() { _recordingPending = false; isRecording = false; MeetingOverlay.recordingActive = false; });
    }
  }

  // ---------------------------------------------------------------------------
  // Video tile builders
  // ---------------------------------------------------------------------------

  /// Local camera tile.
  /// The camera preview pipeline is ALWAYS running (we only stop publishing
  /// to the channel, never stop the local capture). So always show the live
  /// AgoraVideoView — only fall back to placeholder if camera is truly off.
  Widget _buildLocalCamera({bool mini = false}) {
    return _VideoTile(
      label: mini ? null : 'You',
      child: isCameraOn
          ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          : const _CameraOffPlaceholder(),
    );
  }

  /// Remote participant camera (or screen share — same primary stream).
  Widget _buildRemoteVideo(int uid, {String? label}) {
    return _VideoTile(
      label: label ?? 'Participant',
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: widget.channel),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Camera row — local + remote participants (max 3 total)
  // ---------------------------------------------------------------------------
  Widget _buildCameraRow() {
    final tiles = <Widget>[
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: _buildLocalCamera(),
        ),
      ),
      ..._remoteUsers.take(2).map(
        (uid) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: _buildRemoteVideo(uid),
          ),
        ),
      ),
    ];
    return Row(children: tiles);
  }

  // ---------------------------------------------------------------------------
  // Controls bar
  // ---------------------------------------------------------------------------
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlBtn(
            icon: isMicOn ? Icons.mic : Icons.mic_off,
            color: isMicOn ? Colors.white : Colors.red,
            tooltip: isMicOn ? 'Mute' : 'Unmute',
            onTap: _toggleMic,
          ),
          _ControlBtn(
            icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
            color: isCameraOn ? Colors.white : Colors.red,
            tooltip: isCameraOn ? 'Camera off' : 'Camera on',
            onTap: _toggleCamera,
          ),
          // Screen share button with busy indicator
          GestureDetector(
            onTap: _screenShareBusy ? null : _toggleScreenShare,
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Center(
                child: _screenShareBusy
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.amber),
                      )
                    : Icon(
                        isScreenSharing
                            ? Icons.stop_screen_share
                            : Icons.screen_share,
                        color: isScreenSharing ? Colors.amber : Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
          // Recording
          GestureDetector(
            onTap: _recordingPending ? null : _toggleRecording,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isRecording ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _recordingPending
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                        color: isRecording ? Colors.red : Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
          _ControlBtn(
            icon: Icons.call_end,
            color: Colors.white,
            backgroundColor: Colors.red,
            tooltip: 'End call',
            onTap: _leaveMeeting,
          ),
          _ControlBtn(
            icon: Icons.keyboard_arrow_down,
            color: Colors.white,
            tooltip: 'Minimize',
            onTap: () => setState(() => isMinimized = true),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Minimized strip
  // ---------------------------------------------------------------------------
  Widget _buildMinimizedStrip() {
    return Container(
      height: 64,
      color: Colors.black,
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Local camera — always show AgoraVideoView when camera is on,
          // even during screen share (preview pipeline stays alive).
          _miniTile(
            child: isCameraOn
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : const _CameraOffPlaceholder(),
          ),
          // Remote cameras
          ..._remoteUsers.take(2).map(
            (uid) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _miniTile(
                child: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: uid),
                    connection: RtcConnection(channelId: widget.channel),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (isRecording)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
            ),
          if (isScreenSharing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.screen_share, color: Colors.amber, size: 16),
            ),
          GestureDetector(
            onTap: () => setState(() => isMinimized = false),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 24),
            ),
          ),
          GestureDetector(
            onTap: _leaveMeeting,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.call_end, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTile({required Widget child}) {
    return SizedBox(
      width: 60, height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle & build
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    if (_isInitialized && !_isLeaving) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (isMinimized) {
      return _buildMinimizedStrip();
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            color: Colors.black87,
            child: Row(
              children: [
                const Icon(Icons.videocam, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Meeting${_remoteUsers.isNotEmpty ? ' (${_remoteUsers.length + 1})' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                if (isScreenSharing)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.screen_share, color: Colors.white, size: 10),
                      SizedBox(width: 3),
                      Text('Sharing', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ]),
                  ),
                if (isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                      SizedBox(width: 3),
                      Text('REC', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ]),
                  ),
              ],
            ),
          ),

          // Info banner when auto-start was skipped due to remote screen share
          if (_autoStartSkipped)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.orange.shade800,
              child: const Text(
                'Participant is already sharing. Tap share to start your own.',
                style: TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Video area ───────────────────────────────────────────────────
          Expanded(
            child: isScreenSharing
                ? _buildScreenShareLayout()
                : _buildCameraRow(),
          ),

          // ── Controls ─────────────────────────────────────────────────────
          _buildControls(),
        ],
      ),
    );
  }

  /// When I am sharing my screen:
  /// - Show the local screen capture as the main view (2/3)
  /// - Show local camera PiP + remote camera tiles in a small row (1/3)
  Widget _buildScreenShareLayout() {
    return Column(
      children: [
        // Screen share preview (local) — takes 2/3
        Expanded(
          flex: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Local screen share view
              AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(
                    uid: 0,
                    sourceType: VideoSourceType.videoSourceScreen,
                  ),
                ),
              ),
              // Small camera PiP in corner
              Positioned(
                right: 6, bottom: 6,
                width: 64, height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildLocalCamera(mini: true),
                ),
              ),
            ],
          ),
        ),
        // Remote participants row — 1/3
        SizedBox(
          height: 70,
          child: _remoteUsers.isEmpty
              ? const Center(
                  child: Text('Waiting for others...',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                )
              : Row(
                  children: _remoteUsers.take(2).map((uid) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _buildRemoteVideo(uid),
                    ),
                  )).toList(),
                ),
        ),
      ],
    );
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _VideoTile extends StatelessWidget {
  final Widget child;
  final String? label;

  const _VideoTile({required this.child, this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (label != null)
            Positioned(
              bottom: 4, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(label!,
                    style: const TextStyle(color: Colors.white, fontSize: 9)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraOffPlaceholder extends StatelessWidget {
  const _CameraOffPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey[900],
    child: const Center(
      child: Icon(Icons.videocam_off, color: Colors.white38, size: 28),
    ),
  );
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final String tooltip;
  final VoidCallback? onTap;

  const _ControlBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

// =============================================================================
// MeetingOverlay — inserts the meeting panel into the ROOT overlay so it
// floats above every pushed route (including the DocuSign webview).
// =============================================================================

class MeetingOverlay {
  static OverlayEntry? _entry;

  /// True while the panel is temporarily collapsed (e.g. a bottom sheet is open).
  static final ValueNotifier<bool> _collapsed = ValueNotifier(false);

  /// Mirrors the recording state of the active VideoMeetingScreen so callers
  /// outside the widget tree can check whether recording is currently running.
  static bool recordingActive = false;

  static void show(BuildContext context, Widget child) {
    hide();
    _collapsed.value = false;
    _entry = OverlayEntry(
      builder: (ctx) => _BottomMeetingOverlay(
        child: child,
        collapsed: _collapsed,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
    _collapsed.value = false;
    recordingActive = false;
  }

  static void markDirty() {
    _entry?.markNeedsBuild();
  }

  /// Shrink the panel to a thin strip so bottom sheets / dialogs are visible.
  static void collapse() {
    _collapsed.value = true;
  }

  /// Restore the panel to its full height.
  static void expand() {
    _collapsed.value = false;
  }

  static bool get isActive => _entry != null;
}

class _BottomMeetingOverlay extends StatelessWidget {
  final Widget child;
  final ValueNotifier<bool> collapsed;
  const _BottomMeetingOverlay({required this.child, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final fullHeight = screenHeight * 0.25;
    return ValueListenableBuilder<bool>(
      valueListenable: collapsed,
      builder: (ctx, isCollapsed, _) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                // When collapsed: move 95 % of the panel off-screen downward
                // so only a tiny visible strip peeks at the bottom edge.
                bottom: isCollapsed ? -(fullHeight * 0.92) + safeBottom : safeBottom,
                height: fullHeight,
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
