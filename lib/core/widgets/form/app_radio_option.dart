import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Radio button for full-width list items with optional subtitle
/// Radio button positioned on the LEFT
/// 
/// Usage:
/// ```dart
/// AppRadioListOption(
///   isSelected: _selectedOption == 'option1',
///   title: 'Option Title',
///   subtitle: 'Optional description',
///   onTap: () => setState(() => _selectedOption = 'option1'),
/// )
/// ```
class AppRadioListOption extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const AppRadioListOption({
    super.key,
    required this.isSelected,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.backgroundLightGreen 
              : (enabled ? Colors.white : AppColors.backgroundGray),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _AppRadioButton(isSelected: isSelected, enabled: enabled),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.itemLabel.copyWith(
                      color: enabled ? null : AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.cardSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio button for side-by-side buttons (Yes/No, etc.)
/// Radio button positioned on the LEFT with centered content
/// 
/// Usage:
/// ```dart
/// Row(
///   children: [
///     Expanded(
///       child: AppRadioButton(
///         isSelected: _isMinor == 'yes',
///         label: 'Yes',
///         onTap: () => setState(() => _isMinor = 'yes'),
///       ),
///     ),
///     const SizedBox(width: 12),
///     Expanded(
///       child: AppRadioButton(
///         isSelected: _isMinor == 'no',
///         label: 'No',
///         onTap: () => setState(() => _isMinor = 'no'),
///       ),
///     ),
///   ],
/// )
/// ```
class AppRadioButton extends StatelessWidget {
  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const AppRadioButton({
    super.key,
    required this.isSelected,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.backgroundLightGreen 
              : (enabled ? Colors.white : AppColors.backgroundGray),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AppRadioButton(isSelected: isSelected, enabled: enabled),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.buttonSmall.copyWith(
                color: enabled ? null : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio button for list items with radio on the RIGHT
/// Used for asset selection and similar list views
/// 
/// Usage:
/// ```dart
/// AppRadioListOptionRight(
///   isSelected: _selectedAsset == asset.id,
///   title: asset.name,
///   subtitle: asset.description,
///   onTap: () => setState(() => _selectedAsset = asset.id),
/// )
/// ```
class AppRadioListOptionRight extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const AppRadioListOptionRight({
    super.key,
    required this.isSelected,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.backgroundLightGreen 
              : (enabled ? Colors.white : AppColors.backgroundGray),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.itemLabel.copyWith(
                      color: enabled ? null : AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.cardSecondary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _AppRadioButton(isSelected: isSelected, enabled: enabled),
          ],
        ),
      ),
    );
  }
}

/// Radio option card with icon, title, subtitle, and radio on right
/// Used for selection screens like lawyer type selection
/// 
/// Usage:
/// ```dart
/// AppRadioCard(
///   isSelected: _selectedOption == 'willcloud',
///   icon: Icons.business,
///   title: 'WillCloud Lawyer',
///   subtitle: 'Get matched with a certified lawyer',
///   onTap: () => setState(() => _selectedOption = 'willcloud'),
/// )
/// ```
class AppRadioCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const AppRadioCard({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.backgroundLightGreen 
              : (enabled ? Colors.white : AppColors.backgroundGray),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryGreen.withOpacity(0.1) 
                    : AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.itemLabel.copyWith(
                      color: enabled ? null : AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.cardSecondary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _AppRadioButton(isSelected: isSelected, enabled: enabled),
          ],
        ),
      ),
    );
  }
}

/// Yes/No radio button pair helper widget
/// 
/// Usage:
/// ```dart
/// AppYesNoRadio(
///   value: _isMinor,
///   onChanged: (value) => setState(() => _isMinor = value),
/// )
/// ```
class AppYesNoRadio extends StatelessWidget {
  final String? value; // 'yes', 'no', or null
  final ValueChanged<String> onChanged;
  final String yesLabel;
  final String noLabel;
  final bool enabled;

  const AppYesNoRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppRadioButton(
            isSelected: value == 'yes',
            label: yesLabel,
            onTap: () => onChanged('yes'),
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppRadioButton(
            isSelected: value == 'no',
            label: noLabel,
            onTap: () => onChanged('no'),
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}

/// Internal radio button circle widget
/// Matches Figma SVG design: outer 17px circle, inner 8px circle when selected
class _AppRadioButton extends StatelessWidget {
  final bool isSelected;
  final bool enabled;

  const _AppRadioButton({
    required this.isSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: enabled ? AppColors.borderLightGray2 : AppColors.borderGray,
          width: 1,
        ),
        boxShadow: !isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? AppColors.accentGreen3 : AppColors.textSecondary,
                ),
              ),
            )
          : null,
    );
  }
}
