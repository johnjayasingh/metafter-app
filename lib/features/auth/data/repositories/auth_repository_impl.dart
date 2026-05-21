import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  @override
  Future<SignupResponse> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final request = SignupRequest(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      password: password,
    );

    final response = await _apiClient.post(
      ApiEndpoints.signupBasic,
      data: request.toJson(),
    );

    return SignupResponse.fromJson(response.data);
  }

  @override
  Future<OtpValidationResponse> validateOtp({
    required String sessionId,
    required String otp,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.otpValidate,
      queryParameters: {
        'session_id': sessionId,
        'otp': otp,
      },
    );

    return OtpValidationResponse.fromJson(response.data);
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
    );

    final response = await _apiClient.post(
      ApiEndpoints.loginBasic,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);

    if (loginResponse.isSuccess && loginResponse.data != null) {
      final data = loginResponse.data!;

      // Save user email
      await _storage.saveUserEmail(email);

      // Save session if present
      if (data.session != null) {
        await _storage.saveSession(data.session!);
      }

      // Save login step
      await _storage.saveLoginStep(data.loginStep.value);

      // Save tokens if login is completed or authenticated
      if (data.loginStep == LoginStep.completed || 
          data.loginStep == LoginStep.authenticated) {
        if (data.accessToken != null) {
          await _storage.saveAccessToken(data.accessToken!);
        }
        if (data.refreshToken != null) {
          await _storage.saveRefreshToken(data.refreshToken!);
        }
        if (data.user != null) {
          await _storage.saveUserId(data.user!.id);
        }
      }
    }

    return loginResponse;
  }

  @override
  Future<LoginResponse> confirmMfa({
    required String session,
    required String code,
  }) async {
    // Get email from storage
    final email = await _storage.getUserEmail();
    
    if (email == null || email.isEmpty) {
      throw Exception('User email not found. Please log in again.');
    }

    final request = MfaValidateRequest(
      session: session,
      otp: code,
      email: email,
    );

    // MFA validate uses the correct endpoint for MFA challenge
    final response = await _apiClient.post(
      ApiEndpoints.mfaValidate,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);

    if (loginResponse.isSuccess && loginResponse.data != null) {
      final data = loginResponse.data!;

      // Save tokens
      if (data.accessToken != null) {
        await _storage.saveAccessToken(data.accessToken!);
      }
      if (data.refreshToken != null) {
        await _storage.saveRefreshToken(data.refreshToken!);
      }
      if (data.user != null) {
        await _storage.saveUserId(data.user!.id);
        await _storage.saveUserEmail(data.user!.email);
      }

      // Update login step
      await _storage.saveLoginStep(LoginStep.completed.value);
    }

    return loginResponse;
  }

  @override
  Future<LoginResponse> validateMfa({
    required String session,
    required String otp,
    required String email,
  }) async {
    final request = MfaValidateRequest(
      session: session,
      otp: otp,
      email: email,
    );

    final response = await _apiClient.post(
      ApiEndpoints.mfaSetup,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    
    if (loginResponse.isSuccess && loginResponse.data != null) {
      final data = loginResponse.data!;
      
      // Save tokens if present (MFA challenge during login)
      if (data.accessToken != null) {
        await _storage.saveAccessToken(data.accessToken!);
      }
      if (data.refreshToken != null) {
        await _storage.saveRefreshToken(data.refreshToken!);
      }
      if (data.user != null) {
        await _storage.saveUserId(data.user!.id);
        await _storage.saveUserEmail(data.user!.email);
      }
      
      // Update login step
      await _storage.saveLoginStep(LoginStep.completed.value);
    }

    return loginResponse;
  }

  @override
  Future<void> logout() async {
    // No API endpoint available yet, just clear local session
    await clearSession();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  @override
  Future<bool> tryRefreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        if (data['access_token'] != null) {
          await _storage.saveAccessToken(data['access_token']);
        }
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

  @override
  Future<UserInfo?> validateSession() async {
    try {
      // Make a lightweight API call to verify the token is valid.
      // If the access token is expired, the Dio interceptor will
      // automatically attempt a refresh using the refresh token.
      final response = await _apiClient.get(ApiEndpoints.userProfile);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final responseData = data['data'] ?? data;

        // Update stored user info from the API response
        final userId = responseData['id'] as String?;
        final email = responseData['email'] as String?;

        if (userId != null) await _storage.saveUserId(userId);
        if (email != null) await _storage.saveUserEmail(email);

        return UserInfo(
          id: userId ?? '',
          email: email ?? '',
          isActive: responseData['is_active'] as bool? ?? true,
          isMfaEnabled: responseData['is_mfa_enabled'] as bool? ?? true,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserInfo?> getCurrentUser() async {
    try {
      final userId = await _storage.getUserId();
      final email = await _storage.getUserEmail();

      if (userId == null || email == null) {
        return null;
      }

      // In a real app, you might fetch full user data from API
      // For now, return basic info from storage
      return UserInfo(
        id: userId,
        email: email,
        isActive: true,
        isMfaEnabled: true,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await _storage.clearAll();
  }
}
