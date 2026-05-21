import 'package:flutter/material.dart';
import '../../../../core/widgets/form/form_widgets.dart';

/// Reusable bottom bar for POA screens.
///
/// Shows Previous + Next (or custom label) buttons in a row with shadow.
class PoaBottomBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final String nextText;
  final bool isLoading;

  const PoaBottomBar({
    super.key,
    required this.onPrevious,
    required this.onNext,
    this.nextText = 'Next step',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                text: 'Previous',
                onPressed: onPrevious,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                text: nextText,
                onPressed: isLoading ? null : onNext,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
