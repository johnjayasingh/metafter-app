import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
  
  /// Returns a user-friendly message for display
  String get userFriendlyMessage => message;
}

class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Network error. Please check your connection.',
          statusCode: null,
        );
  
  @override
  String get userFriendlyMessage => 'Please check your internet connection and try again.';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
      : super(
          message: message ?? 'Unauthorized. Please login again.',
          statusCode: 401,
        );
  
  @override
  String get userFriendlyMessage => 'Your session has expired. Please sign in again.';
}

class NotFoundException extends ApiException {
  NotFoundException({String? message})
      : super(
          message: message ?? 'Resource not found.',
          statusCode: 404,
        );
  
  @override
  String get userFriendlyMessage => 'The requested resource was not found.';
}

class ServerException extends ApiException {
  ServerException({String? message})
      : super(
          message: message ?? 'Server error. Please try again later.',
          statusCode: 500,
        );
  
  @override
  String get userFriendlyMessage => 'Something went wrong on our end. Please try again later.';
}

class ValidationException extends ApiException {
  ValidationException({String? message})
      : super(
          message: message ?? 'Validation failed.',
          statusCode: 400,
        );
}

class ForbiddenException extends ApiException {
  ForbiddenException({String? message})
      : super(
          message: message ?? 'Access forbidden.',
          statusCode: 403,
        );
}

class ConflictException extends ApiException {
  ConflictException({String? message})
      : super(
          message: message ?? 'Resource already exists.',
          statusCode: 409,
        );
}

class ConnectionException extends ApiException {
  ConnectionException({String? message})
      : super(
          message: message ?? 'Connection failed.',
          statusCode: null,
        );
  
  @override
  String get userFriendlyMessage => 'Unable to connect to the server. Please check your internet connection and try again.';
}

class ApiTimeoutException extends ApiException {
  ApiTimeoutException({String? message})
      : super(
          message: message ?? 'Request timeout.',
          statusCode: null,
        );
  
  @override
  String get userFriendlyMessage => 'The request timed out. Please check your connection and try again.';
}

class TimeoutException extends ApiException {
  TimeoutException({String? message})
      : super(
          message: message ?? 'Request timed out.',
          statusCode: null,
        );
  
  @override
  String get userFriendlyMessage => 'The request timed out. Please check your connection and try again.';
}

/// Helper function to get a user-friendly error message from any exception
String getErrorMessage(dynamic error) {
  if (error is DioException) {
    final responseData = error.response?.data;
    // Prefer API-provided detail when available (e.g., validation errors)
    if (responseData is Map && responseData['detail'] != null) {
      final detail = responseData['detail'];
      if (detail is List && detail.isNotEmpty) {
        // If there are multiple validation errors, combine them
        if (detail.length > 1) {
          final errors = <String>[];
          for (final item in detail) {
            if (item is Map && item['msg'] is String) {
              // Extract field name and message
              final loc = item['loc'];
              final msg = item['msg'] as String;
              if (loc is List && loc.length > 1) {
                final fieldName = loc.last.toString();
                errors.add('$fieldName: $msg');
              } else {
                errors.add(msg);
              }
            }
          }
          if (errors.isNotEmpty) {
            return errors.join('\n');
          }
        }
        // Single error - just return the message
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          final loc = first['loc'];
          final msg = first['msg'] as String;
          // If field name is available, include it for clarity
          if (loc is List && loc.length > 1) {
            final fieldName = loc.last.toString().replaceAll('_', ' ').capitalize();
            return '$fieldName is required';
          }
          return msg;
        }
      } else if (detail is String) {
        return detail;
      }
    }
    if (responseData is Map && responseData['message'] is String) {
      return responseData['message'] as String;
    }
    // Fallback to Dio's message
    return error.message ?? 'Something went wrong. Please try again.';
  }
  if (error is NetworkException || 
      error is ConnectionException || 
      error is ApiTimeoutException ||
      error is TimeoutException) {
    return (error as ApiException).userFriendlyMessage; // Returns empty string for network errors
  } else if (error is ServerException) {
    return error.userFriendlyMessage;
  } else if (error is ApiException) {
    // For other API exceptions, return the message if it's not too technical
    final message = error.message;
    if (message.contains('Exception') || 
        message.contains('Error:') ||
        message.contains('failed to') ||
        message.contains('cannot be solved')) {
      return 'Something went wrong. Please try again.';
    }
    return message;
  } else if (error is Exception) {
    final errorStr = error.toString();
    // Check for common network error patterns - suppress these
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Connection failed') ||
        errorStr.contains('Network is unreachable') ||
        errorStr.contains('HandshakeException') ||
        errorStr.contains('connection errored')) {
      return ''; // Suppress network errors
    }
    return 'Something went wrong. Please try again.';
  }
  return 'An unexpected error occurred. Please try again.';
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
