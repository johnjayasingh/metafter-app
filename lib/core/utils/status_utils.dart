import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Utility class for will status formatting and colors
class StatusUtils {
  StatusUtils._();

  /// Returns the appropriate color for a will status
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'WILL_SIGNED':
      case 'SIGNED':
        return AppColors.primaryGreen;
      case 'IN_PROGRESS':
      case 'DRAFT':
        return AppColors.warningOrange;
      case 'IN_LEGAL_REVIEW':
      case 'LEGAL_REVIEW':
      case 'UNDER_REVIEW':
        return Colors.blue;
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
        return Colors.red;
      case 'PENDING':
      case 'AWAITING_PAYMENT':
        return Colors.amber;
      case 'AWAITING_EXECUTION':
        return const Color(0xFF1B5E20); // dark green
      default:
        return AppColors.warningOrange;
    }
  }

  /// Formats the status string for display (e.g., IN_PROGRESS -> In Progress)
  static String formatStatus(String status) {
    // Status mapping for display labels
    const statusLabels = {
      'IN_PROGRESS': 'In Progress',
      'DRAFT': 'Draft',
      'COMPLETED': 'Completed',
      'WILL_SIGNED': 'Will Signed',
      'SIGNED': 'Signed',
      'IN_LEGAL_REVIEW': 'In Legal Review',
      'LEGAL_REVIEW': 'Legal Review',
      'UNDER_REVIEW': 'Under Review',
      'REJECTED': 'Rejected',
      'CANCELLED': 'Cancelled',
      'EXPIRED': 'Expired',
      'PENDING': 'Pending',
      'AWAITING_PAYMENT': 'Awaiting Payment',
      'AWAITING_EXECUTION': 'Awaiting Execution',
    };

    final upperStatus = status.toUpperCase();
    if (statusLabels.containsKey(upperStatus)) {
      return statusLabels[upperStatus]!;
    }

    // Fallback: Convert snake_case to Title Case
    return status
        .split('_')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}
