// Example of how to navigate to LegalReviewScreen

import 'package:flutter/material.dart';
import '../pages/legal_review_screen.dart';

/// Example navigation to Legal Review Screen
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => LegalReviewScreen(
///       willId: 'ea4ff952-fd9e-4cf1-abaf-f2d15d9dbcae',  // Required: The will ID from your backend
///       userName: 'Mary Wilson',  // Optional: defaults to 'Mary Wilson'
///     ),
///   ),
/// );
/// ```
///
/// The screen will:
/// 1. Automatically call the document generation API on load
/// 2. Display a loading indicator while generating the document
/// 3. Show the document details including:
///    - Document ID (from API response)
///    - Cover page preview (from cover_url in API)
///    - QR code/cover image
///    - Success message
/// 4. Handle errors with retry functionality
///
/// API Response Structure:
/// ```json
/// {
///   "status": "success",
///   "message": "",
///   "data": {
///     "url": "https://...",  // Main PDF URL
///     "watermarked_url": "https://...",  // Watermarked PDF URL
///     "cover_url": "https://...",  // Cover image URL (used for QR display)
///     "document_id": "WILL-000126"  // Generated document ID
///   }
/// }
/// ```
class LegalReviewScreenExample {
  static void navigateToLegalReview(BuildContext context, String willId, {String? userName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalReviewScreen(
          willId: willId,
          userName: userName ?? 'Mary Wilson',
        ),
      ),
    );
  }
}
