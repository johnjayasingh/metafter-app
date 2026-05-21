import 'dart:developer' as developer;
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_models.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Get paginated notifications for the user
  /// [page] - Page number (1-based), default is 1
  /// Returns NotificationListResponse with data and pagination info
  Future<ApiResponse<NotificationListResponse>> getNotifications({int page = 1}) async {
    try {
      developer.log('Fetching notifications - page: $page', name: 'NotificationService');
      
      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page.toString()},
      );

      if (response.statusCode == 200 && response.data != null) {
        // The API returns: {status, message, data: {data: [...], page, per_page, total_pages, total_items}}
        // So we need to extract the nested 'data' object
        final responseData = response.data as Map<String, dynamic>;
        final notificationData = responseData['data'] as Map<String, dynamic>?;
        
        if (notificationData != null) {
          final notificationResponse = NotificationListResponse.fromJson(notificationData);
          developer.log(
            'Notifications fetched successfully: ${notificationResponse.data.length} items, page ${notificationResponse.page}/${notificationResponse.totalPages}',
            name: 'NotificationService',
          );
          return ApiResponse(
            isSuccess: true,
            message: 'Notifications loaded successfully',
            data: notificationResponse,
          );
        } else {
          developer.log('No notification data in response', name: 'NotificationService');
          return ApiResponse(
            isSuccess: false,
            message: 'No notification data in response',
          );
        }
      } else {
        developer.log('Failed to fetch notifications: ${response.statusMessage}', name: 'NotificationService');
        return ApiResponse(
          isSuccess: false,
          message: response.statusMessage ?? 'Failed to load notifications',
        );
      }
    } catch (e) {
      developer.log('Error fetching notifications: $e', name: 'NotificationService');
      return ApiResponse(
        isSuccess: false,
        message: 'Error loading notifications: ${e.toString()}',
      );
    }
  }
}
