import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/onboarding_data.dart';
import '../widgets/onboarding_page_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
    if (!mounted) return;
    context.go(AppRouter.signIn);
  }

  // Uncomment these methods if you want to add Next/Skip buttons
  // void _nextPage() {
  //   if (_currentPage < OnboardingData.pages.length - 1) {
  //     _pageController.nextPage(
  //       duration: AppConstants.animationDuration,
  //       curve: Curves.easeInOut,
  //     );
  //   } else {
  //     _completeOnboarding();
  //   }
  // }

  // void _skipOnboarding() {
  //   _completeOnboarding();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/onboarding.png'),
              fit: BoxFit.cover,
              opacity: 1.0,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Logo, tagline, and description at top (persistent)
                Padding(
                  padding: ResponsiveUtils.scaleEdgeInsets(
                    context,
                    top: 32,
                    left: 24,
                    right: 24,
                    bottom: 16,
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 134.92.scaled(context),
                        height: 24.scaled(context),
                      ),
                      ResponsiveUtils.scaledBox(context, height: 16),
                      Text(
                        'Trusted by families\nacross Australia',
                        style: AppTextStyles.onboardingTitle.copyWith(
                          fontSize: 30.scaled(context),
                          letterSpacing: -0.3.scaled(context),
                          color: AppColors.textBrand,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      ResponsiveUtils.scaledBox(context, height: 12),
                      Text(
                        'Protect what matters most with an easy,\nguided will-creation experience.',
                        style: AppTextStyles.instructionSmall.copyWith(
                          fontSize: 12.scaled(context),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.18.scaled(context),
                          color: AppColors.subscriptionDescription,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      // Page changed - could be used for analytics or state tracking
                    },
                    itemCount: OnboardingData.pages.length,
                    itemBuilder: (context, index) {
                      return OnboardingPageWidget(
                        page: OnboardingData.pages[index],
                      );
                    },
                  ),
                ),
                
                // Page indicator, Sign In button, and Sign Up link
                Padding(
                  padding: ResponsiveUtils.scaleEdgeInsetsAll(context, 24),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: OnboardingData.pages.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 8.scaled(context),
                          dotWidth: 8.scaled(context),
                          activeDotColor: AppColors.primaryGreen,
                          dotColor: AppColors.primaryMint,
                          expansionFactor: 3,
                        ),
                      ),
                      ResponsiveUtils.scaledBox(context, height: 32),
                      AppPrimaryButton(
                        text: 'Sign In',
                        onPressed: _completeOnboarding,
                      ),
                      ResponsiveUtils.scaledBox(context, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New to Willcloud? ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                          AppTextButton(
                            text: 'Sign up',
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
                              if (!mounted) return;
                              context.go(AppRouter.signUp);
                            },
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
