import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpVerificationRequired,
  mfaSetupRequired,
  mfaChallengeRequired,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserInfo? user;
  final String? session;
  final String? sessionId;
  final String? email;
  final String? qrData;
  final ChallengeType? challengeType;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.session,
    this.sessionId,
    this.email,
    this.qrData,
    this.challengeType,
    this.errorMessage,
  });

  factory AuthState.initial() {
    return const AuthState(
      status: AuthStatus.initial,
    );
  }

  factory AuthState.loading() {
    return const AuthState(
      status: AuthStatus.loading,
    );
  }

  factory AuthState.authenticated({required UserInfo user}) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  factory AuthState.unauthenticated() {
    return const AuthState(
      status: AuthStatus.unauthenticated,
    );
  }

  factory AuthState.otpVerificationRequired({
    required String sessionId,
    required String email,
  }) {
    return AuthState(
      status: AuthStatus.otpVerificationRequired,
      sessionId: sessionId,
      email: email,
    );
  }

  factory AuthState.mfaSetupRequired({
    required String session,
    required String qrData,
  }) {
    return AuthState(
      status: AuthStatus.mfaSetupRequired,
      session: session,
      qrData: qrData,
    );
  }

  factory AuthState.mfaChallengeRequired({
    required String session,
    required ChallengeType challengeType,
  }) {
    return AuthState(
      status: AuthStatus.mfaChallengeRequired,
      session: session,
      challengeType: challengeType,
    );
  }

  factory AuthState.error({required String message}) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }

  AuthState copyWith({
    AuthStatus? status,
    UserInfo? user,
    String? session,
    String? sessionId,
    String? email,
    String? qrData,
    ChallengeType? challengeType,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      sessionId: sessionId ?? this.sessionId,
      email: email ?? this.email,
      qrData: qrData ?? this.qrData,
      challengeType: challengeType ?? this.challengeType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  @override
  List<Object?> get props => [
        status,
        user,
        session,
        sessionId,
        email,
        qrData,
        challengeType,
        errorMessage,
      ];
}
