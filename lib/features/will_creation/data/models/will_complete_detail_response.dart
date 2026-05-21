class WillCompleteDetailResponse {
  final String status;
  final String message;
  final WillCompleteDetailData? data;

  WillCompleteDetailResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory WillCompleteDetailResponse.fromJson(Map<String, dynamic> json) {
    return WillCompleteDetailResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? WillCompleteDetailData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class WillCompleteDetailData {
  final WillInfo willInfo;
  final PersonName createdBy;
  final List<PersonName> witness;
  final PersonName? lawyer;
  final String willOriginal;
  final String willWatermarked;
  final String willCoverImage;

  WillCompleteDetailData({
    required this.willInfo,
    required this.createdBy,
    required this.witness,
    this.lawyer,
    required this.willOriginal,
    required this.willWatermarked,
    required this.willCoverImage,
  });

  factory WillCompleteDetailData.fromJson(Map<String, dynamic> json) {
    return WillCompleteDetailData(
      willInfo: WillInfo.fromJson(json['will_info'] as Map<String, dynamic>),
      createdBy: PersonName.fromJson(json['created_by'] as Map<String, dynamic>),
      witness: (json['witness'] as List<dynamic>?)
              ?.map((e) => PersonName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lawyer: json['lawyer'] != null
          ? PersonName.fromJson(json['lawyer'] as Map<String, dynamic>)
          : null,
      willOriginal: json['will_original'] as String? ?? '',
      willWatermarked: json['will_watermarked'] as String? ?? '',
      willCoverImage: json['will_cover_image'] as String? ?? '',
    );
  }

  String get documentId {
    // Extract document ID from will original URL
    // Format: WILL-000127.pdf
    final match = RegExp(r'(WILL-\d+)\.pdf').firstMatch(willOriginal);
    return match?.group(1) ?? 'WILL-UNKNOWN';
  }

  String get fullName {
    final parts = [
      createdBy.firstName,
      if (createdBy.middleName.isNotEmpty) createdBy.middleName,
      createdBy.lastName,
    ];
    return parts.join(' ');
  }
}

class WillInfo {
  final String id;
  final String status;
  final String createdOn;
  final String lastUpdate;

  WillInfo({
    required this.id,
    required this.status,
    required this.createdOn,
    required this.lastUpdate,
  });

  factory WillInfo.fromJson(Map<String, dynamic> json) {
    return WillInfo(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdOn: json['created_on'] as String? ?? '',
      lastUpdate: json['last_update'] as String? ?? '',
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'IN_LEGAL_REVIEW':
        return 'In Legal Review';
      case 'DRAFT':
        return 'Draft';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }
}

class PersonName {
  final String firstName;
  final String middleName;
  final String lastName;

  PersonName({
    required this.firstName,
    required this.middleName,
    required this.lastName,
  });

  factory PersonName.fromJson(Map<String, dynamic> json) {
    return PersonName(
      firstName: json['first_name'] as String? ?? '',
      middleName: json['middle_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
    );
  }

  String get fullName {
    final parts = [
      firstName,
      if (middleName.isNotEmpty) middleName,
      lastName,
    ];
    return parts.join(' ');
  }

  bool get isEmpty => firstName.isEmpty && middleName.isEmpty && lastName.isEmpty;
}
