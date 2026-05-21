import '../../data/models/auth_models.dart';

abstract class AuthRepository {
  Future<SignupResponse> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<OtpValidationResponse> validateOtp({
    required String sessionId,
    required String otp,
  });

  Future<LoginResponse> login({
    required String email,
    required String password,
  });

  Future<LoginResponse> confirmMfa({
    required String session,
    required String code,
  });

  Future<LoginResponse> validateMfa({
    required String session,
    required String otp,
    required String email,
  });

  Future<void> logout();

  Future<bool> isLoggedIn();

  /// Attempts to refresh the access token using the stored refresh token.
  /// Returns true if token was refreshed successfully, false otherwise.
  Future<bool> tryRefreshToken();

  /// Validates the current session by making a lightweight API call.
  /// Returns the user info if the session is valid, null otherwise.
  /// If the access token is expired, the API client interceptor will
  /// automatically attempt a refresh before failing.
  Future<UserInfo?> validateSession();

  Future<UserInfo?> getCurrentUser();

  Future<void> clearSession();
}
