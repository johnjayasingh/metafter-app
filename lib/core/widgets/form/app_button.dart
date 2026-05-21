import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_text_styles.dart';

/// A reusable primary button widget with consistent styling.
/// 
/// Usage:
/// ```dart
/// AppPrimaryButton(
///   text: 'Submit',
///   onPressed: _handleSubmit,
///   isLoading: _isSubmitting,
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  /// The button text
  final String text;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Whether the button is in loading state
  final bool isLoading;
  
  /// Whether the button is disabled
  final bool isDisabled;
  
  /// Whether the button should take full width
  final bool fullWidth;
  
  /// Optional icon to display before text
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && !isDisabled && onPressed != null;
    
    Widget buttonChild;
    if (isLoading) {
      buttonChild = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.backgroundWhite),
        ),
      );
    } else if (icon != null) {
      buttonChild = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.backgroundWhite),
            const SizedBox(width: 8),
            Text(text, style: AppTextStyles.buttonPrimary, maxLines: 1),
          ],
        ),
      );
    } else {
      buttonChild = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: AppTextStyles.buttonPrimary, maxLines: 1),
      );
    }
    
    Widget button = ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: isEnabled 
          ? AppDecorations.buttonPrimary 
          : AppDecorations.buttonDisabled,
      child: buttonChild,
    );
    
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
}

/// A reusable secondary/outlined button widget with consistent styling.
class AppSecondaryButton extends StatelessWidget {
  /// The button text
  final String text;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Whether the button is in loading state
  final bool isLoading;
  
  /// Whether the button is disabled
  final bool isDisabled;
  
  /// Whether the button should take full width
  final bool fullWidth;
  
  /// Optional icon to display before text
  final IconData? icon;
  
  /// Optional icon to display after text
  final IconData? trailingIcon;

  const AppSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = true,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && !isDisabled && onPressed != null;
    
    Widget buttonContent;
    if (isLoading) {
      buttonContent = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    } else if (icon != null || trailingIcon != null) {
      buttonContent = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
            ],
            Text(text, style: AppTextStyles.buttonSecondary, maxLines: 1),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 20, color: AppColors.primaryGreen),
            ],
          ],
        ),
      );
    } else {
      buttonContent = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: AppTextStyles.buttonSecondary, maxLines: 1),
      );
    }
    
    Widget button = OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: AppDecorations.buttonSecondary,
      child: buttonContent,
    );
    
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
}

/// A cancel/gray outlined button
class AppCancelButton extends StatelessWidget {
  /// The button text
  final String text;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Whether the button should take full width
  final bool fullWidth;

  const AppCancelButton({
    super.key,
    this.text = 'Cancel',
    this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = OutlinedButton(
      onPressed: onPressed,
      style: AppDecorations.buttonCancel,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: AppTextStyles.buttonSmall.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
        ),
      ),
    );
    
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
}

/// A text button for less prominent actions
class AppTextButton extends StatelessWidget {
  /// The button text
  final String text;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Optional icon to display before text
  final IconData? icon;
  
  /// Text color (defaults to primary green)
  final Color? color;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.primaryGreen;
    
    return TextButton(
      onPressed: onPressed,
      child: icon != null
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: AppTextStyles.buttonSecondary.copyWith(color: textColor),
                    maxLines: 1,
                  ),
                ],
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: AppTextStyles.buttonSecondary.copyWith(color: textColor),
                maxLines: 1,
              ),
            ),
    );
  }
}

/// A floating action button with consistent styling
class AppFloatingButton extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Optional tooltip text
  final String? tooltip;

  const AppFloatingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.backgroundWhite,
      child: Icon(icon),
    );
  }
}

/// A small icon button with consistent styling
class AppIconButton extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Icon size
  final double size;
  
  /// Icon color
  final Color? color;
  
  /// Optional tooltip
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size, color: color ?? AppColors.textPrimary),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

/// Bottom action bar container with shadow
class AppBottomActionBar extends StatelessWidget {
  /// The child widget (usually a button or row of buttons)
  final Widget child;
  
  /// Padding around the content
  final EdgeInsetsGeometry padding;

  const AppBottomActionBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: AppDecorations.shadowLight,
      ),
      child: child,
    );
  }
}
