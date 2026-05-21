import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignupRequested extends AuthEvent {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String password;

  const AuthSignupRequested({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [firstName, middleName, lastName, email, password];
}

class AuthOtpValidateRequested extends AuthEvent {
  final String sessionId;
  final String otp;

  const AuthOtpValidateRequested({
    required this.sessionId,
    required this.otp,
  });

  @override
  List<Object?> get props => [sessionId, otp];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthMfaConfirmRequested extends AuthEvent {
  final String session;
  final String code;

  const AuthMfaConfirmRequested({
    required this.session,
    required this.code,
  });

  @override
  List<Object?> get props => [session, code];
}

class AuthMfaValidateRequested extends AuthEvent {
  final String session;
  final String otp;
  final String email;

  const AuthMfaValidateRequested({
    required this.session,
    required this.otp,
    required this.email,
  });

  @override
  List<Object?> get props => [session, otp, email];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionCleared extends AuthEvent {
  const AuthSessionCleared();
}
