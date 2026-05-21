import 'package:digitalwill/core/theme/app_colors.dart';
import 'package:digitalwill/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class WillcloudTrustBanner extends StatelessWidget {
  final String? imagePath;
  final String title;
  final String? subtitle;
  final double height;

  const WillcloudTrustBanner({
    super.key,
    this.imagePath,
    this.title = 'Trusted by families',
    this.subtitle = 'across Australia',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.backgroundMintLight2, AppColors.backgroundMintLight5],
        ),
      ),
      child: Stack(
        children: [
          // Actual image filling container (if provided)
          if (imagePath != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) {
                    // Show placeholder icon if image fails to load
                    return _buildPlaceholderIcon();
                  },
                ),
              ),
            )
          else
            // Show placeholder icon when no image path provided
            _buildPlaceholderIcon(),

          // Text on top
          Positioned(
            left: 16,
            right: 100,
            top: -100,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.5,
                    letterSpacing: -0.4,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          // Text on bottom
          (subtitle != null)
              ? Positioned(
                  bottom: 24,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          height: 1,
                          letterSpacing: -0.3,
                          color: AppColors.textBrand,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(width: 0, height: 0),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.people_outline,
            size: 60,
            color: AppColors.primaryGreen.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
