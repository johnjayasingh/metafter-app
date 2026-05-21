import 'package:equatable/equatable.dart';

// ==================== LAW FIRM MODEL ====================

class LawFirm extends Equatable {
  final String id;
  final String firmName;
  final String registrationNumber;
  final String legalPractitionerReference;
  final String email;
  final String phone;
  final String address;

  const LawFirm({
    required this.id,
    required this.firmName,
    required this.registrationNumber,
    required this.legalPractitionerReference,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory LawFirm.fromJson(Map<String, dynamic> json) {
    return LawFirm(
      id: json['id']?.toString() ?? '',
      firmName: json['firm_name']?.toString() ?? '',
      registrationNumber: json['registration_number']?.toString() ?? '',
      legalPractitionerReference: json['legal_practitioner_reference']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_name': firmName,
      'registration_number': registrationNumber,
      'legal_practitioner_reference': legalPractitionerReference,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firmName,
        registrationNumber,
        legalPractitionerReference,
        email,
        phone,
        address,
      ];
}

// ==================== LAWYER MODEL ====================

class Lawyer extends Equatable {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String mobile;
  final String role;

  const Lawyer({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.role,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  factory Lawyer.fromJson(Map<String, dynamic> json) {
    return Lawyer(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        middleName,
        lastName,
        email,
        mobile,
        role,
      ];
}

// ==================== RESPONSE MODELS ====================

class BusinessResponse<T> {
  final String status;
  final String message;
  final T? data;

  const BusinessResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory BusinessResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) dataParser,
  ) {
    return BusinessResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? dataParser(json['data']) : null,
    );
  }

  bool get isSuccess => status == 'success';
}

// Response for list of law firms
class LawFirmsResponse extends BusinessResponse<List<LawFirm>> {
  const LawFirmsResponse({
    required super.status,
    required super.message,
    super.data,
  });

  factory LawFirmsResponse.fromJson(Map<String, dynamic> json) {
    return LawFirmsResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => LawFirm.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

// Response for list of lawyers
class LawyersResponse extends BusinessResponse<List<Lawyer>> {
  const LawyersResponse({
    required super.status,
    required super.message,
    super.data,
  });

  factory LawyersResponse.fromJson(Map<String, dynamic> json) {
    return LawyersResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => Lawyer.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

// ==================== ASSIGNED LAWYER MODEL ====================

class AssignedLawyer extends Equatable {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? mobile;
  final String? country;
  final dynamic extra;
  final bool isActive;
  final String lawFirmId;
  final String lawFirmName;
  final String? address;

  const AssignedLawyer({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.mobile,
    this.country,
    this.extra,
    required this.isActive,
    required this.lawFirmId,
    required this.lawFirmName,
    required this.address,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  factory AssignedLawyer.fromJson(Map<String, dynamic> json) {
    // Handle both professional lawyer (law_firm_name) and personal lawyer (firm_name) fields
    final lawFirmName = json['law_firm_name']?.toString() ?? 
                        json['firm_name']?.toString() ?? '';
    
    return AssignedLawyer(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      country: json['country']?.toString(),
      extra: json['extra'],
      isActive: json['is_active'] as bool? ?? true,
      lawFirmId: json['law_firm_id']?.toString() ?? '',
      lawFirmName: lawFirmName,
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'country': country,
      'extra': extra,
      'is_active': isActive,
      'law_firm_id': lawFirmId,
      'law_firm_name': lawFirmName,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        middleName,
        lastName,
        email,
        mobile,
        country,
        extra,
        isActive,
        lawFirmId,
        lawFirmName,
      ];
}

// ==================== ASSIGN LAWYER REQUEST ====================

class AssignProfessionalLawyerRequest extends Equatable {
  final String willId;
  final String userId;

  const AssignProfessionalLawyerRequest({
    required this.willId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'user_id': userId,
    };
  }

  @override
  List<Object?> get props => [willId, userId];
}

// ==================== LAWYERS LIST RESPONSE ====================

class LawyersListData extends Equatable {
  final List<AssignedLawyer> personalLawyers;
  final List<AssignedLawyer> professionalLawyers;

  const LawyersListData({
    required this.personalLawyers,
    required this.professionalLawyers,
  });

  factory LawyersListData.fromJson(Map<String, dynamic> json) {
    return LawyersListData(
      personalLawyers: json['personal_lawyers'] != null
          ? (json['personal_lawyers'] as List)
              .map((item) => AssignedLawyer.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      professionalLawyers: json['professional_lawyers'] != null
          ? (json['professional_lawyers'] as List)
              .map((item) => AssignedLawyer.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  @override
  List<Object?> get props => [personalLawyers, professionalLawyers];
}

class LawyersListResponse extends BusinessResponse<LawyersListData> {
  const LawyersListResponse({
    required super.status,
    required super.message,
    super.data,
  });

  factory LawyersListResponse.fromJson(Map<String, dynamic> json) {
    return LawyersListResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? LawyersListData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ==================== PERSONAL LAWYER REQUEST ====================

class PersonalLawyerRequest extends Equatable {
  final String willId;
  final int? id; // Optional - used for update
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String mobile;
  final String? firmName;
  final String? address;

  const PersonalLawyerRequest({
    required this.willId,
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.mobile,
    this.firmName,
    this.address,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'will_id': willId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
    };
    
    if (id != null) {
      data['id'] = id;
    }
    if (middleName != null && middleName!.isNotEmpty) {
      data['middle_name'] = middleName;
    }
    if (firmName != null && firmName!.isNotEmpty) {
      data['firm_name'] = firmName;
    }
    if (address != null && address!.isNotEmpty) {
      data['address'] = address;
    }
    
    return data;
  }

  @override
  List<Object?> get props => [
        willId,
        id,
        firstName,
        middleName,
        lastName,
        email,
        mobile,
        firmName,
        address,
      ];
}

// ==================== PERSONAL LAWYER MODEL ====================

class PersonalLawyer extends Equatable {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? mobile;
  final String? address;
  final String? dob;
  final String? firmName;

  const PersonalLawyer({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.mobile,
    this.address,
    this.dob,
    this.firmName,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  factory PersonalLawyer.fromJson(Map<String, dynamic> json) {
    return PersonalLawyer(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      address: json['address']?.toString(),
      dob: json['dob']?.toString(),
      firmName: json['firm_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'address': address,
      'dob': dob,
      'firm_name': firmName,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        middleName,
        lastName,
        email,
        mobile,
        address,
        dob,
        firmName,
      ];
}
