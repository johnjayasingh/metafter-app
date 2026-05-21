import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../data/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
    on<AuthOtpValidateRequested>(_onAuthOtpValidateRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthMfaConfirmRequested>(_onAuthMfaConfirmRequested);
    on<AuthMfaValidateRequested>(_onAuthMfaValidateRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthSessionCleared>(_onAuthSessionCleared);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        // Validate the session by calling the API with the existing token.
        // If the access token is expired, the Dio interceptor will
        // automatically try to refresh it before returning a failure.
        final user = await _authRepository.validateSession();

        if (user != null) {
          emit(AuthState.authenticated(user: user));
        } else {
          // Token invalid and refresh also failed — log out
          await _authRepository.clearSession();
          emit(AuthState.unauthenticated());
        }
      } else {
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      // On any error, clear session and log out
      await _authRepository.clearSession();
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final response = await _authRepository.signup(
        firstName: event.firstName,
        middleName: event.middleName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
      );

      if (response.isSuccess) {
        // Signup successful - navigate to OTP verification
        if (response.data != null) {
          emit(
            AuthState.otpVerificationRequired(
              sessionId: response.data!.sessionId,
              email: event.email,
            ),
          );
        } else {
          emit(AuthState.error(message: 'Invalid response from server'));
        }
      } else {
        // Emit error with the message from API
        emit(
          AuthState.error(
            message: response.message.isNotEmpty
                ? response.message
                : 'Signup failed',
          ),
        );
      }
    } on ConflictException catch (e) {
      // 409 Conflict - User already exists
      emit(AuthState.error(message: e.message.isNotEmpty ? e.message : 'User already exists.'));
    } on ApiException catch (e) {
      emit(AuthState.error(message: e.userFriendlyMessage));
    } catch (e) {
      emit(
        AuthState.error(
          message: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> _onAuthOtpValidateRequested(
    AuthOtpValidateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final response = await _authRepository.validateOtp(
        sessionId: event.sessionId,
        otp: event.otp,
      );

      if (response.isSuccess) {
        // OTP validated - navigate to sign in
        emit(AuthState.unauthenticated());
      } else {
        emit(
          AuthState.error(
            message: response.message.isNotEmpty
                ? response.message
                : 'OTP validation failed',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(AuthState.error(message: e.userFriendlyMessage));
    } catch (e) {
      emit(
        AuthState.error(
          message: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        switch (data.loginStep) {
          case LoginStep.mfaSetup:
            if (data.session != null && data.qrData != null) {
              emit(
                AuthState.mfaSetupRequired(
                  session: data.session!,
                  qrData: data.qrData!,
                ),
              );
            } else {
              emit(AuthState.error(message: 'Invalid MFA setup data received'));
            }
            break;

          case LoginStep.mfaChallenge:
            if (data.session != null && data.challengeType != null) {
              emit(
                AuthState.mfaChallengeRequired(
                  session: data.session!,
                  challengeType: data.challengeType!,
                ),
              );
            } else {
              emit(
                AuthState.error(message: 'Invalid MFA challenge data received'),
              );
            }
            break;

          case LoginStep.authenticated:
          case LoginStep.completed:
            if (data.user != null) {
              emit(AuthState.authenticated(user: data.user!));
            } else {
              // Fetch user info
              final user = await _authRepository.getCurrentUser();
              if (user != null) {
                emit(AuthState.authenticated(user: user));
              } else {
                emit(AuthState.error(message: 'Failed to retrieve user info'));
              }
            }
            break;
        }
      } else {
        emit(
          AuthState.error(
            message: response.message.isNotEmpty
                ? response.message
                : 'Login failed',
          ),
        );
      }
    } on UnauthorizedException catch (e) {
      emit(AuthState.error(message: e.message));
    } on NotFoundException catch (e) {
      emit(AuthState.error(message: e.message));
    } on ForbiddenException catch (e) {
      // Check if this is "User not active" error - need OTP verification
      if (e.message.contains('User not active') ||
          e.message.contains('Please activate your account')) {
        // Navigate to OTP verification with the email
        // Note: We don't have a session_id here, user will need to use "Resend OTP" button
        emit(
          AuthState.otpVerificationRequired(
            sessionId: '', // Empty session - user needs to resend OTP
            email: event.email,
          ),
        );
      } else {
        emit(AuthState.error(message: e.message));
      }
    } on NetworkException catch (e) {
      emit(AuthState.error(message: e.userFriendlyMessage));
    } on ApiException catch (e) {
      emit(AuthState.error(message: e.userFriendlyMessage));
    } catch (e) {
      emit(
        AuthState.error(
          message: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> _onAuthMfaConfirmRequested(
    AuthMfaConfirmRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final response = await _authRepository.confirmMfa(
        session: event.session,
        code: event.code,
      );

      if (response.isSuccess) {
        // MFA challenge successful - authenticate user
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthState.authenticated(user: user));
        } else {
          emit(AuthState.error(message: 'Failed to retrieve user info'));
        }
      } else {
        emit(
          AuthState.error(
            message: response.message.isNotEmpty
                ? response.message
                : 'MFA verification failed',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(AuthState.error(message: e.userFriendlyMessage));
    } catch (e) {
      emit(
        AuthState.error(
          message: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> _onAuthMfaValidateRequested(
    AuthMfaValidateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final response = await _authRepository.validateMfa(
        session: event.session,
        otp: event.otp,
        email: event.email,
      );

      if (response.isSuccess) {
        // Check if this is MFA setup (data is null/empty) or MFA challenge (has tokens)
        if (response.data != null && response.data!.accessToken != null) {
          // MFA challenge successful - user is authenticated
          final user = await _authRepository.getCurrentUser();
          if (user != null) {
            emit(AuthState.authenticated(user: user));
          } else {
            emit(AuthState.error(message: 'Failed to retrieve user info'));
          }
        } else {
          // MFA setup successful - redirect to sign-in
          emit(AuthState.unauthenticated());
        }
      } else {
        emit(
          AuthState.error(
            message: response.message.isNotEmpty
                ? response.message
                : 'MFA validation failed',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(AuthState.error(message: e.userFriendlyMessage));
    } catch (e) {
      emit(
        AuthState.error(
          message: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      await _authRepository.logout();
      emit(AuthState.unauthenticated());
    } catch (e) {
      // Even if logout fails, clear session locally
      await _authRepository.clearSession();
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthSessionCleared(
    AuthSessionCleared event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.clearSession();
    emit(AuthState.unauthenticated());
  }
}
