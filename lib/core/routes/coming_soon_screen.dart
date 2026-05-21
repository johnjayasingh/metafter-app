import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/navigation_utils.dart';
import '../widgets/form/form_widgets.dart';

class ComingSoonScreen extends StatelessWidget {
  final String? featureName;

  const ComingSoonScreen({super.key, this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => NavigationUtils.goToHomeAndRefresh(context),
        ),
        title: Text(
          'Coming Soon',
          style: AppTextStyles.sectionTitle,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Coming Soon Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 60,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Coming Soon',
                style: AppTextStyles.welcomeTitle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                featureName != null
                    ? 'The $featureName feature is currently under development and will be available soon.'
                    : 'This feature is currently under development and will be available soon.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Go Home Button
              AppPrimaryButton(
                text: 'Go to Home',
                onPressed: () => NavigationUtils.goToHomeAndRefresh(context),
              ),
              const SizedBox(height: 12),
              // Go Back Button
              AppSecondaryButton(
                text: 'Go Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    NavigationUtils.goToHomeAndRefresh(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
