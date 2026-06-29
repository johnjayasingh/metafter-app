import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/metafter_logo.dart';
import '../widgets/discover_avatar_collage.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.brandBlack,
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.brandSunset),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const MetafterLogo(
                  form: MetafterLogoForm.wordmark,
                  variant: MetafterLogoVariant.white,
                  height: 24,
                ),

                // Floating cluster of nearby-people avatars.
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: DiscoverAvatarCollage(),
                  ),
                ),

                // CTA section over the dark lower portion of the gradient.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Discover who’s\naround you!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.6,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Awkward Intros,\nNo Missed Connections',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: AppColors.textOnDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandCoral,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => context.push(AppRouter.signupBasics),
                          child: Text(
                            'Get Started',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
