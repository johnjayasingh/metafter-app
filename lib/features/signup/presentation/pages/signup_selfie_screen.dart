import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';

/// Captures a short live video selfie that will be matched against the
/// uploaded profile photo for identity verification.
class SignupSelfieScreen extends StatefulWidget {
  const SignupSelfieScreen({super.key});

  @override
  State<SignupSelfieScreen> createState() => _SignupSelfieScreenState();
}

class _SignupSelfieScreenState extends State<SignupSelfieScreen> {
  final _draft = SignupDraft.instance;
  final ImagePicker _picker = ImagePicker();

  bool _capturing = false;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _onCapture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxDuration: const Duration(seconds: 5),
      );
      if (!mounted) return;
      if (file == null) {
        setState(() => _capturing = false);
        return;
      }
      _draft.update(() => _draft.selfiePath = file.path);

      final controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      setState(() {
        _videoController?.dispose();
        _videoController = controller;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture video: $e')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _onContinue() {
    context.push(AppRouter.signupVerifying);
  }

  @override
  Widget build(BuildContext context) {
    final captured = _videoController?.value.isInitialized ?? false;
    return SignupScaffold(
      showBack: true,
      title: 'Record a quick video selfie',
      subtitle: const Text(
        'We’ll capture a 5-second video and match it with your profile '
        'photo to confirm it’s really you.',
      ),
      bottomButton: captured
          ? MetafterPrimaryButton(label: 'Continue', onPressed: _onContinue)
          : MetafterPrimaryButton(
              label: _capturing ? 'Opening camera…' : 'Capture Video Selfie',
              onPressed: _capturing ? null : _onCapture,
            ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth.clamp(0, 280).toDouble();
                  return SizedBox(
                    width: size,
                    height: size,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: captured
                              ? AppColors.brandRed
                              : Colors.black.withValues(alpha: 0.08),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: captured
                            ? FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width:
                                      _videoController!.value.size.width,
                                  height:
                                      _videoController!.value.size.height,
                                  child: VideoPlayer(_videoController!),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.videocam_rounded,
                                  color: AppColors.textSecondary,
                                  size: 56,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            captured
                ? 'Looks good — tap continue to verify.'
                : 'Hold your face inside the circle and tap capture to '
                    'record a 5-second video selfie.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
