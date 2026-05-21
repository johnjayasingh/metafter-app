import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/metafter_logo.dart';

/// Standard signup-flow scaffold: white background, centered logo at the
/// top, page title beneath, scrollable body and a sticky CTA at the bottom.
class SignupScaffold extends StatelessWidget {
  const SignupScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.bottomButton,
    this.scrollable = true,
    this.showBack = false,
  });

  final String title;
  final Widget? subtitle;
  final Widget child;
  final Widget bottomButton;
  final bool scrollable;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            child: subtitle!,
          ),
        ],
        const SizedBox(height: 28),
        child,
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: MetafterLogo(
                      variant: MetafterLogoVariant.red,
                      height: 26,
                    ),
                  ),
                  if (showBack)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _BackButton()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: scrollable
                    ? SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: body,
                      )
                    : body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: bottomButton,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      radius: 22,
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
