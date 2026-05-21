import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/onboarding_page.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.scaleEdgeInsetsSymmetric(
        context,
        horizontal: 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ResponsiveUtils.scaledBox(context, height: 20),
          
          // Image
          Expanded(
            child: Center(
              child: page.imagePath.endsWith('.svg')
                  ? SvgPicture.asset(
                      page.imagePath,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      page.imagePath,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          
          ResponsiveUtils.scaledBox(context, height: 32),
          
          // Title
          Text(
            page.title,
            style: AppTextStyles.welcomeTitle.copyWith(
              fontSize: 24.scaled(context),
              letterSpacing: -0.48.scaled(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          ResponsiveUtils.scaledBox(context, height: 12),
          
          // Subtitle
          Padding(
            padding: ResponsiveUtils.scaleEdgeInsetsSymmetric(
              context,
              horizontal: 16,
            ),
            child: Text(
              page.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          ResponsiveUtils.scaledBox(context, height: 20),
        ],
      ),
    );
  }
}
