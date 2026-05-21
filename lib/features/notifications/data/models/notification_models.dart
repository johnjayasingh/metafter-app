import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String message;
  final String timestamp;
  final String? type;
  final bool? isRead;

  const NotificationModel({
    required this.id,
    required this.message,
    required this.timestamp,
    this.type,
    this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? json['created_at'] as String? ?? '',
      type: json['type'] as String?,
      isRead: json['is_read'] as bool? ?? json['read'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'is_read': isRead,
    };
  }

  @override
  List<Object?> get props => [id, message, timestamp, type, isRead];
}

class NotificationListResponse extends Equatable {
  final List<NotificationModel> data;
  final int page;
  final int perPage;
  final int totalPages;
  final int totalItems;

  const NotificationListResponse({
    required this.data,
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.totalItems,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      totalPages: json['total_pages'] as int? ?? 0,
      totalItems: json['total_items'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [data, page, perPage, totalPages, totalItems];
}

class ApiResponse<T> {
  final bool isSuccess;
  final String message;
  final T? data;

  const ApiResponse({
    required this.isSuccess,
    required this.message,
    this.data,
  });
}
