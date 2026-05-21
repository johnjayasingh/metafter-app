import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';

/// Profile card used by both the "Add Photo" and "Verifying" screens.
class SignupProfileCard extends StatelessWidget {
  const SignupProfileCard({
    super.key,
    required this.photoPath,
    required this.name,
    required this.subtitle,
    this.introduction,
    this.introBlurred = false,
  });

  final String? photoPath;
  final String name;
  final String subtitle;
  final String? introduction;
  final bool introBlurred;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEFEFEF),
            border: Border.all(color: AppColors.brandRed, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            image: photoPath != null
                ? DecorationImage(
                    image: FileImage(File(photoPath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: photoPath == null
              ? const Icon(Icons.person,
                  size: 64, color: AppColors.brandRed)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          name.isEmpty ? 'Your Name' : name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        if (introduction != null && introduction!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              introduction!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: introBlurred
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : AppColors.textSecondary,
                shadows: introBlurred
                    ? [
                        const Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 0),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SignupPhotoScreen extends StatefulWidget {
  const SignupPhotoScreen({super.key});

  @override
  State<SignupPhotoScreen> createState() => _SignupPhotoScreenState();
}

class _SignupPhotoScreenState extends State<SignupPhotoScreen> {
  final _draft = SignupDraft.instance;

  Future<void> _onAddPhoto() async {
    // TODO: integrate image_picker for gallery selection. For the prototype
    // we simply mark a photo as picked and advance to the selfie capture.
    _draft.update(() => _draft.photoPath = _draft.photoPath ?? '');
    if (!mounted) return;
    context.push(AppRouter.signupSelfie);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${_draft.designation.isEmpty ? 'Your role' : _draft.designation}'
        ' - ${_draft.company.isEmpty ? 'Company' : _draft.company}';
    return SignupScaffold(
      title: 'Let’s add a profile photo',
      bottomButton: MetafterPrimaryButton(
        label: 'Add Photo',
        onPressed: _onAddPhoto,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SignupProfileCard(
            photoPath: null, // empty placeholder per design
            name: _draft.name,
            subtitle: subtitle,
            introduction: _draft.introduction.isEmpty
                ? '${_draft.designation.isEmpty ? 'Professional' : _draft.designation} '
                    'focused on building simple, intuitive, and user-first digital experiences.'
                : _draft.introduction,
            introBlurred: true,
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'A clear photo helps people recognize and trust you during introductions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
