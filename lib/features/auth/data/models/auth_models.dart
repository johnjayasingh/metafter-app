import 'package:equatable/equatable.dart';

class SignupRequest {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String password;
  final String loginType;
  final String role;

  SignupRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.password,
    this.loginType = 'email',
    this.role = 'user',
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName ?? '',
      'last_name': lastName,
      'email': email,
      'password': password,
      'login_type': loginType,
      'role': role,
    };
  }
}

class SignupResponse extends Equatable {
  final String status;
  final String message;
  final SignupData? data;

  const SignupResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? SignupData.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailure => status == 'failure';

  @override
  List<Object?> get props => [status, message, data];
}

class SignupData extends Equatable {
  final String sessionId;

  const SignupData({
    required this.sessionId,
  });

  factory SignupData.fromJson(Map<String, dynamic> json) {
    return SignupData(
      sessionId: json['session_id'] as String,
    );
  }

  @override
  List<Object?> get props => [sessionId];
}

class OtpValidationResponse extends Equatable {
  final String status;
  final String message;
  final OtpValidationData? data;

  const OtpValidationResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OtpValidationResponse.fromJson(Map<String, dynamic> json) {
    return OtpValidationResponse(
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? OtpValidationData.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailure => status == 'failure';

  @override
  List<Object?> get props => [status, message, data];
}

class OtpValidationData extends Equatable {
  final UserInfo userInfo;

  const OtpValidationData({
    required this.userInfo,
  });

  factory OtpValidationData.fromJson(Map<String, dynamic> json) {
    return OtpValidationData(
      userInfo: UserInfo.fromJson(json['user_info']),
    );
  }

  @override
  List<Object?> get props => [userInfo];
}

enum LoginStep {
  mfaSetup('MFA_SETUP'),
  mfaChallenge('MFA_CHALLENGE'),
  authenticated('AUTHENTICATED'),
  completed('COMPLETED');

  final String value;
  const LoginStep(this.value);

  static LoginStep fromString(String value) {
    return LoginStep.values.firstWhere(
      (step) => step.value == value,
      orElse: () => LoginStep.completed,
    );
  }
}

enum ChallengeType {
  softwareTokenMfa('SOFTWARE_TOKEN_MFA'),
  smsMfa('SMS_MFA');

  final String value;
  const ChallengeType(this.value);

  static ChallengeType fromString(String value) {
    return ChallengeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChallengeType.softwareTokenMfa,
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class MfaConfirmRequest {
  final String session;
  final String code;

  MfaConfirmRequest({
    required this.session,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'session': session,
      'code': code,
    };
  }
}

class MfaValidateRequest {
  final String session;
  final String otp;
  final String email;

  MfaValidateRequest({
    required this.session,
    required this.otp,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'session': session,
      'otp': otp,
      'email': email,
    };
  }
}

class LoginResponse extends Equatable {
  final String status;
  final String message;
  final LoginData? data;

  const LoginResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    LoginData? loginData;
    
    // Check if data exists and is not an empty object
    if (dataJson != null && dataJson is Map<String, dynamic> && dataJson.isNotEmpty) {
      loginData = LoginData.fromJson(dataJson);
    }
    
    return LoginResponse(
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
      data: loginData,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailure => status == 'failure';

  @override
  List<Object?> get props => [status, message, data];
}

class LoginData extends Equatable {
  final LoginStep loginStep;
  final String? session;
  final String? qrData;
  final ChallengeType? challengeType;
  final String? accessToken;
  final String? refreshToken;
  final UserInfo? user;

  const LoginData({
    required this.loginStep,
    this.session,
    this.qrData,
    this.challengeType,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      loginStep: LoginStep.fromString(json['login_step'] as String),
      session: json['session'] as String?,
      qrData: json['qr_data'] as String?,
      challengeType: json['challenge_type'] != null
          ? ChallengeType.fromString(json['challenge_type'] as String)
          : null,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      user: json['user_info'] != null
          ? UserInfo.fromJson(json['user_info'])
          : (json['user'] != null ? UserInfo.fromJson(json['user']) : null),
    );
  }

  @override
  List<Object?> get props => [
        loginStep,
        session,
        qrData,
        challengeType,
        accessToken,
        refreshToken,
        user,
      ];
}

class UserInfo extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final bool isActive;
  final bool isMfaEnabled;

  const UserInfo({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.isActive,
    required this.isMfaEnabled,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['user_id'] as String? ?? json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isMfaEnabled: json['is_mfa_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'is_active': isActive,
      'is_mfa_enabled': isMfaEnabled,
    };
  }

  @override
  List<Object?> get props => [id, email, fullName, phoneNumber, isActive, isMfaEnabled];
}
