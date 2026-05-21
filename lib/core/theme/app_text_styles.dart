import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles for the application
/// Usage: Text('Hello', style: AppTextStyles.pageTitle)
class AppTextStyles {
  // ==================== Page Titles ====================
  
  /// Main page title (24px, w600, -0.4 spacing)
  /// Used for: Screen headings, main questions
  static TextStyle get pageTitle => GoogleFonts.instrumentSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      );

  /// Page title with custom color
  static TextStyle pageTitleWithColor(Color color) => GoogleFonts.instrumentSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.4,
        color: color,
      );

  // ==================== Section Titles ====================
  
  /// Section header (18px, w700)
  /// Used for: Bottom sheet titles, modal headers
  static TextStyle get sectionTitle => GoogleFonts.instrumentSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Question title (16px, w600)
  /// Used for: Form questions, card titles
  static TextStyle get questionTitle => GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  /// Card title (16px, w600)
  /// Used for: Asset cards, item names
  static TextStyle get cardTitle => GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ==================== Body Text ====================
  
  /// Primary subtitle (12px, w600, 0.18 spacing)
  /// Used for: Page descriptions, help text under titles
  static TextStyle get subtitle => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.18,
        color: AppColors.textSecondary,
      );

  /// Secondary subtitle (13px, w400)
  /// Used for: Bottom sheet subtitles, smaller descriptions
  static TextStyle get subtitleSmall => GoogleFonts.instrumentSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Body text medium (14px, w400)
  /// Used for: General content, descriptions
  static TextStyle get bodyMedium => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Body text small (12px, w400)
  /// Used for: Helper text, hints
  static TextStyle get bodySmall => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Card subtitle (14px, w400)
  /// Used for: Secondary information in cards
  static TextStyle get cardSubtitle => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Bottom navigation tab label - active (12px, w600)
  /// Used for: Active bottom navigation labels
  static TextStyle get tabLabelActive => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryGreen,
      );

  /// Bottom navigation tab label - inactive (12px, w500)
  /// Used for: Inactive bottom navigation labels
  static TextStyle get tabLabelInactive => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textGray,
      );

  // ==================== Labels ====================
  
  /// Item label (14px, w600)
  /// Used for: List items, selectable options
  static TextStyle get itemLabel => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Small label (12px, w600)
  /// Used for: Tags, badges, small indicators
  static TextStyle get labelSmall => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  /// Avatar initials (14px, w600)
  /// Used for: Avatar text, initials
  static TextStyle get avatarInitials => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Avatar initials large (16px, w600)
  static TextStyle get avatarInitialsLarge => GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ==================== Button Text ====================
  
  /// Primary button text (16px, w600)
  /// Used for: Main action buttons
  static TextStyle get buttonPrimary => GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.backgroundWhite,
      );

  /// Secondary button text (14px, w500)
  /// Used for: Secondary action buttons, Cancel buttons
  static TextStyle get buttonSecondary => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryGreen,
      );

  /// Small button text (14px, w600)
  /// Used for: Compact buttons, Yes/No options
  static TextStyle get buttonSmall => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Button text with custom color
  static TextStyle buttonWithColor(Color color) => GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Button text disabled
  static TextStyle get buttonDisabled => GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDisabled,
      );

  // ==================== Progress/Steps ====================
  
  /// Step counter (14px, w600)
  /// Used for: "1/5 steps" counter
  static TextStyle get stepCounter => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.07,
        color: AppColors.textPrimary,
      );

  /// Step label (14px, w500)
  /// Used for: "steps" text
  static TextStyle get stepLabel => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0.07,
        color: AppColors.textSecondary,
      );

  /// Step title (16px, w600)
  /// Used for: Current step title in app bar
  static TextStyle get stepTitle => GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  // ==================== Special Cases ====================
  
  /// Empty state text (14px, w400, center aligned)
  /// Used for: Empty lists, no data messages
  static TextStyle get emptyState => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Error text (12px, w400)
  /// Used for: Form validation, error messages
  static TextStyle get error => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.error,
      );

  /// Link text (14px, w600)
  /// Used for: Clickable text, hyperlinks
  static TextStyle get link => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryGreen,
      );

  // ==================== Form/Input Styles ====================
  
  /// Text field input style (14px, w500)
  /// Used for: Text input values
  static TextStyle get inputText => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Text field label (14px, w400)
  /// Used for: Input labels, floating labels
  static TextStyle get inputLabel => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
      );

  /// Text field external label (14px, w500)
  /// Used for: Labels displayed above input fields
  static TextStyle get inputLabelExternal => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Text field floating label (12px, w500)
  /// Used for: Elevated/floating labels
  static TextStyle get inputLabelFloating => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryGreen,
      );

  /// Text field hint (14px, w400)
  /// Used for: Placeholder text
  static TextStyle get inputHint => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
      );

  // ==================== Auth/Onboarding Styles ====================
  
  /// Large welcome title (24px, w600, -0.3 spacing)
  /// Used for: Auth screens, welcome screens
  static TextStyle get welcomeTitle => GoogleFonts.instrumentSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: -0.3,
        color: AppColors.primaryDarkGreen,
      );

  /// Onboarding large title (30px, w600, -0.3 spacing)
  /// Used for: Large hero text
  static TextStyle get onboardingTitle => GoogleFonts.instrumentSans(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: -0.3,
        color: AppColors.primaryDarkGreen,
      );

  /// Auth description text (14px, w500, 1.5 height)
  /// Used for: Auth screen descriptions
  static TextStyle authDescription(BuildContext context) => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0.5,
        color: AppColors.subscriptionDescription,
      );

  // ==================== Card Detail Styles ====================
  
  /// Card name/title (14px, w600)
  /// Used for: Name in person cards, asset names
  static TextStyle get cardName => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Card secondary text (12px, w500)
  /// Used for: Secondary info in cards
  static TextStyle get cardSecondary => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Small instructional text (12px, w600)
  /// Used for: Instructions, small headings in containers
  static TextStyle get instructionSmall => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.18,
        color: AppColors.textSecondary,
      );

  /// Date/timestamp text (12px, w600)
  /// Used for: Dates, timestamps
  static TextStyle get timestamp => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Timestamp label (12px, w500)
  /// Used for: Date labels like "Created on"
  static TextStyle get timestampLabel => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textGray3,
      );

  /// Disclaimer/small meta text (10px, w400)
  /// Used for: Disclaimers, IDs, very small text
  static TextStyle get disclaimer => GoogleFonts.instrumentSans(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ==================== Instruction/Step Number Styles ====================
  
  /// Step number badge (12px, w600, white)
  /// Used for: Numbered steps in circles
  static TextStyle get stepNumberBadge => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.backgroundWhite,
      );

  /// Step instruction text (14px, w500)
  /// Used for: Instruction step descriptions
  static TextStyle get stepInstruction => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // ==================== Special Auth Styles ====================
  
  /// Resend link text (12px, w600, underlined)
  /// Used for: Resend OTP, small action links
  static TextStyle resendLink(BuildContext context) => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryGreen,
        decoration: TextDecoration.underline,
      );
}

/// Extension for scaled text (responsive)
extension TextStyleScaling on TextStyle {
  TextStyle scaled(BuildContext context, double factor) {
    return copyWith(fontSize: (fontSize ?? 14) * factor);
  }
}
