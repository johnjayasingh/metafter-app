import 'package:digitalwill/core/theme/app_dimensions.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import 'subscription_models.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isActive;
  final VoidCallback onSelect;

  const SubscriptionCard({
    super.key,
    required this.plan,
    required this.isActive,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main card with top margin to accommodate badge
        Container(
          padding: EdgeInsets.only(
            top: plan.isPopular ? 14 : 14,
          ),
          margin: EdgeInsets.only(
            top: plan.isPopular ? 20 : 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: plan.isPopular
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.subscriptionBorderGradientStart,
                      AppColors.subscriptionBorderGradientEnd,
                    ],
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundWhite, // White at top
                  AppColors.backgroundMintLight3, // Light mint green at bottom
                ],
                stops: [0.0, 0.85],
              ),
              borderRadius: BorderRadius.circular(16),
              border: plan.isPopular
                  ? null
                  : Border.all(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
            ),
            child: Column(
              children: [
                // Card content (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 24,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plan name
                        Text(
                          plan.name,
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    plan.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.subscriptionDescription,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Price
                  if (plan.price != null)
                    Text(
                      plan.price!,
                      style: AppTextStyles.pageTitle.copyWith(
                        fontSize: 24,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    )
                  else
                    Text(
                      'Free',
                      style: AppTextStyles.pageTitle.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: AppColors.success,
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // CTA Button
                  AppPrimaryButton(
                    text: plan.buttonText,
                    onPressed: onSelect,
                  ),
                  const SizedBox(height: 32),
                  
                  // Features list
                  ...plan.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          
          // Perfect for section - Fixed at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Perfect for',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.subscriptionDescription,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.perfectFor,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
        ),
        
        // Popular badge positioned above card
        if (plan.isPopular)
          Positioned(
            top: 0,
            child: Container(
              width: AppDimensions.responsiveSize(context, 178),
              padding: EdgeInsets.symmetric(
                vertical: AppDimensions.paddingSmall,
                horizontal: 12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.subscriptionBadge,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Text(
                  'Chosen by 8/10 customers',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
