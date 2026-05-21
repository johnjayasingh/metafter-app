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
  });

  final String title;
  final Widget? subtitle;
  final Widget child;
  final Widget bottomButton;
  final bool scrollable;

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
            const MetafterLogo(
              variant: MetafterLogoVariant.red,
              height: 26,
            ),
            const SizedBox(height: 24),
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
