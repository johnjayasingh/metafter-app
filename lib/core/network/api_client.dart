import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'api_exceptions.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  final SecureStorageService _storage = SecureStorageService();
  int _tokenRefreshAttempts = 0;
  static const int _maxRefreshAttempts = 3;
  Function()? onSessionTimeout;

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
        onResponse: _onResponse,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to requests if available
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
    print('🌐 BASE URL: ${options.baseUrl}');
    print('📍 FULL URL: ${options.uri}');
    print('📦 REQUEST BODY: ${options.data}');
    print('🔑 HEADERS: ${options.headers}');
    return handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    print('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    print('📦 RESPONSE DATA: ${response.data}');
    return handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    print('❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
    print('📄 ERROR TYPE: ${error.type}');
    print('💬 ERROR MESSAGE: ${error.message}');
    if (error.response?.data != null) {
      print('📦 ERROR DATA: ${error.response?.data}');
    }

    // Handle token refresh on 401
    if (error.response?.statusCode == 401) {
      // If no refresh token exists, immediately trigger session timeout
      // (no point retrying — the user must re-authenticate)
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No refresh token available. Session timeout.');
        _tokenRefreshAttempts = 0;
        await _storage.clearTokens();
        if (onSessionTimeout != null) {
          onSessionTimeout!();
        }
        return handler.next(error);
      }

      // Check if we've already tried too many times
      if (_tokenRefreshAttempts >= _maxRefreshAttempts) {
        print('❌ Max token refresh attempts reached. Session timeout.');
        _tokenRefreshAttempts = 0; // Reset counter
        await _storage.clearTokens();
        if (onSessionTimeout != null) {
          onSessionTimeout!();
        }
        return handler.next(error);
      }

      _tokenRefreshAttempts++;
      print('🔄 Token refresh attempt $_tokenRefreshAttempts of $_maxRefreshAttempts');

      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          _tokenRefreshAttempts = 0; // Reset on successful refresh
          // Retry the original request
          final response = await _dio.fetch(error.requestOptions);
          return handler.resolve(response);
        } else {
          // Refresh failed — trigger session timeout immediately
          print('❌ Token refresh failed. Session timeout.');
          _tokenRefreshAttempts = 0;
          await _storage.clearTokens();
          if (onSessionTimeout != null) {
            onSessionTimeout!();
          }
        }
      } catch (e) {
        // Refresh threw an exception — trigger session timeout immediately
        print('❌ Token refresh exception. Session timeout.');
        _tokenRefreshAttempts = 0;
        await _storage.clearTokens();
        if (onSessionTimeout != null) {
          onSessionTimeout!();
        }
      }
    }

    return handler.next(error);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        await _storage.saveAccessToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await _storage.saveRefreshToken(data['refresh_token']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    String? message;
    
    // Try to extract message from response
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String?;
    }

    // Print detailed error information
    print('🔍 HANDLING ERROR:');
    print('   Status Code: $statusCode');
    print('   Message: $message');
    print('   Error Type: ${error.type}');
    print('   Path: ${error.requestOptions.path}');
    print('   Method: ${error.requestOptions.method}');
    if (error.response?.data != null) {
      print('   Response Data: ${error.response?.data}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiTimeoutException(
          message: 'The request took too long to complete. Please check your connection and try again.',
        );
      
      case DioExceptionType.connectionError:
        return ConnectionException(
          message: 'Unable to connect to the server. Please check your internet connection and try again.',
        );
      
      case DioExceptionType.badResponse:
        switch (statusCode) {
          case 400:
            return ValidationException(message: message);
          case 422:
            // Extract validation errors from FastAPI-style detail array
            String? validationMessage;
            if (responseData is Map<String, dynamic> &&
                responseData['detail'] != null) {
              final detail = responseData['detail'];
              if (detail is List && detail.isNotEmpty) {
                final msgs = <String>[];
                for (final item in detail) {
                  if (item is Map && item['msg'] is String) {
                    msgs.add(item['msg'] as String);
                  }
                }
                if (msgs.isNotEmpty) validationMessage = msgs.join('. ');
              } else if (detail is String) {
                validationMessage = detail;
              }
            }
            return ValidationException(
              message: validationMessage ?? message ?? 'Validation failed',
            );
          case 401:
            return UnauthorizedException(message: message);
          case 403:
            return ForbiddenException(message: message);
          case 404:
            return NotFoundException(message: message);
          case 409:
            return ConflictException(message: message);
          case 500:
          case 502:
          case 503:
            return ServerException(message: message);
          default:
            return ApiException(
              message: message ?? 'An error occurred',
              statusCode: statusCode,
            );
        }
      
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled',
          statusCode: null,
        );
      
      case DioExceptionType.unknown:
      default:
        // Check if it's a connection-related error
        if (error.error != null) {
          final errorString = error.error.toString().toLowerCase();
          if (errorString.contains('socketexception') ||
              errorString.contains('connection refused') ||
              errorString.contains('network is unreachable') ||
              errorString.contains('no route to host') ||
              errorString.contains('connection failed') ||
              errorString.contains('handshake')) {
            return ConnectionException(
              message: 'Unable to connect to the server. Please check your internet connection and try again.',
            );
          }
        }
        return NetworkException(
          message: 'An unexpected error occurred. Please try again.',
        );
    }
  }
}
