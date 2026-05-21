import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String userId;
  final String firstName;
  final String middleName;
  final String? lastName;
  final String email;
  final String mobile;
  final String? dob;
  final String country;
  final String? address;
  final String? suburb;
  final String? state;
  final String? postcode;
  final List<String>? contactPreference;

  const UserProfile({
    required this.userId,
    required this.firstName,
    required this.middleName,
    this.lastName,
    required this.email,
    required this.mobile,
    this.dob,
    required this.country,
    this.address,
    this.suburb,
    this.state,
    this.postcode,
    this.contactPreference,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // contact_preference may be at the top level or nested inside addon_detail
    final addonDetail = json['addon_detail'] as Map<String, dynamic>?;
    final rawContactPref = json['contact_preference'] ?? addonDetail?['contact_preference'];

    return UserProfile(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['first_name'] as String? ?? '',
      middleName: json['middle_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      dob: json['dob'] as String?,
      country: json['country'] as String? ?? '',
      address: json['address'] as String?,
      suburb: json['suburb'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      contactPreference: rawContactPref != null
          ? List<String>.from(rawContactPref)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'dob': dob,
      'country': country,
      'address': address,
      'suburb': suburb,
      'state': state,
      'postcode': postcode,
      'contact_preference': contactPreference,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        firstName,
        middleName,
        lastName,
        email,
        mobile,
        dob,
        country,
        address,
        suburb,
        state,
        postcode,
        contactPreference,
      ];
}

class UserProfileUpdateRequest {
  final String firstName;
  final String middleName;
  final String? lastName;
  final String email;
  final String mobile;
  final String? dob;
  final String? state;
  final String? address;
  final String? suburb;
  final String? postcode;
  final String country;
  final List<String> contactPreference;

  UserProfileUpdateRequest({
    required this.firstName,
    required this.middleName,
    this.lastName,
    required this.email,
    required this.mobile,
    this.dob,
    this.state,
    this.address,
    this.suburb,
    this.postcode,
    required this.country,
    required this.contactPreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'dob': dob,
      'state': state,
      'address': address,
      'suburb': suburb,
      'postcode': postcode,
      'country': country,
      'contact_preference': contactPreference,
    };
  }
}

class ProfileResponse extends Equatable {
  final String status;
  final String message;
  final UserProfile? data;

  const ProfileResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      status: json['status'] as String? ?? 'failure',
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? UserProfile.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailure => status == 'failure';

  @override
  List<Object?> get props => [status, message, data];
}
