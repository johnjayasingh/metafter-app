import 'package:equatable/equatable.dart';

// Enum for funeral preference (API contract — matches backend FuneralPreference)
enum FuneralPreference {
  burialReligious('BURIAL_RELIGIOUS'),
  cremationNonReligious('CREMATION_NON_RELIGIOUS'),
  cremationReligious('CREMATION_RELIGIOUS'),
  noPreference('NO_PREFERENCE'),
  greenBurial('GREEN_BURIAL'),
  scienceDonation('SCIENCE_DONATION');

  final String value;
  const FuneralPreference(this.value);

  static FuneralPreference fromString(String value) {
    return FuneralPreference.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FuneralPreference.noPreference,
    );
  }

  String get displayLabel {
    switch (this) {
      case FuneralPreference.cremationNonReligious:
        return 'Simple Cremation (Non-Religious)';
      case FuneralPreference.cremationReligious:
        return 'Cremation (Religious/Cultural)';
      case FuneralPreference.burialReligious:
        return 'Traditional Burial (Religious)';
      case FuneralPreference.greenBurial:
        return 'Green / Natural Burial';
      case FuneralPreference.scienceDonation:
        return 'Donation to Science';
      case FuneralPreference.noPreference:
        return 'No Preference / Trustee Discretion';
    }
  }
}

// Religion enum (API contract — matches backend Religion)
enum Religion {
  christianity('CHRISTIANITY'),
  islam('ISLAM'),
  hinduism('HINDUISM'),
  buddhism('BUDDHISM'),
  judaism('JUDAISM'),
  sikhism('SIKHISM'),
  catholic('CATHOLIC'),
  protestant('PROTESTANT'),
  orthodox('ORTHODOX'),
  other('OTHER');

  final String value;
  const Religion(this.value);

  static Religion fromString(String value) {
    return Religion.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Religion.other,
    );
  }

  String get displayLabel {
    switch (this) {
      case Religion.christianity:
        return 'Christianity';
      case Religion.islam:
        return 'Islam';
      case Religion.hinduism:
        return 'Hinduism';
      case Religion.buddhism:
        return 'Buddhism';
      case Religion.judaism:
        return 'Judaism';
      case Religion.sikhism:
        return 'Sikhism';
      case Religion.catholic:
        return 'Catholic';
      case Religion.protestant:
        return 'Protestant';
      case Religion.orthodox:
        return 'Orthodox';
      case Religion.other:
        return 'Other';
    }
  }
}

// Direction person model (reuses FuneralAttendeeDTO shape)
class DirectionPerson extends Equatable {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? relation;

  const DirectionPerson({
    this.firstName,
    this.lastName,
    this.email,
    this.relation,
  });

  factory DirectionPerson.fromJson(Map<String, dynamic> json) {
    return DirectionPerson(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      relation: json['relation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (relation != null) 'relation': relation,
    };
  }

  String get fullName {
    final parts = [firstName, lastName]
        .where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [firstName, lastName, email, relation];
}

// Funeral preference data — polymorphic based on funeral_preference type
class FuneralPreferenceData extends Equatable {
  // Cremation Non-Religious / Cremation Religious / No Preference / Green Burial
  final List<DirectionPerson>? directionBy;

  // Cremation Non-Religious / Cremation Religious
  final String? ashDisposalInstruction;

  // Cremation Religious / Burial Religious
  final Religion? religion;

  // Cremation Religious
  final String? specificRite;

  // Burial Religious
  final String? placeOfWorship;
  final String? cemeteryName;

  // Science Donation
  final String? universityId;
  final String? donationNotAcceptedBackup;

  const FuneralPreferenceData({
    this.directionBy,
    this.ashDisposalInstruction,
    this.religion,
    this.specificRite,
    this.placeOfWorship,
    this.cemeteryName,
    this.universityId,
    this.donationNotAcceptedBackup,
  });

  factory FuneralPreferenceData.fromJson(Map<String, dynamic> json) {
    return FuneralPreferenceData(
      directionBy: json['direction_by'] != null
          ? (json['direction_by'] as List)
              .map((e) => DirectionPerson.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      ashDisposalInstruction: json['ash_disposal_instruction'] as String?,
      religion: json['religion'] != null
          ? Religion.fromString(json['religion'] as String)
          : null,
      specificRite: json['specific_rite'] as String?,
      placeOfWorship: json['place_of_worship'] as String?,
      cemeteryName: json['cemetery_name'] as String?,
      universityId: json['university_id'] as String?,
      donationNotAcceptedBackup:
          json['donation_not_accepted_backup'] as String?,
    );
  }

  /// Build JSON based on the funeral preference type
  Map<String, dynamic> toJson(FuneralPreference preference) {
    switch (preference) {
      case FuneralPreference.cremationNonReligious:
        return {
          if (ashDisposalInstruction != null)
            'ash_disposal_instruction': ashDisposalInstruction,
          if (directionBy != null)
            'direction_by': directionBy!.map((d) => d.toJson()).toList(),
        };
      case FuneralPreference.cremationReligious:
        return {
          if (religion != null) 'religion': religion!.value,
          if (specificRite != null) 'specific_rite': specificRite,
          if (ashDisposalInstruction != null)
            'ash_disposal_instruction': ashDisposalInstruction,
          if (directionBy != null)
            'direction_by': directionBy!.map((d) => d.toJson()).toList(),
        };
      case FuneralPreference.burialReligious:
        return {
          if (religion != null) 'religion': religion!.value,
          if (placeOfWorship != null) 'place_of_worship': placeOfWorship,
          if (cemeteryName != null) 'cemetery_name': cemeteryName,
        };
      case FuneralPreference.scienceDonation:
        return {
          if (universityId != null) 'university_id': universityId,
          if (donationNotAcceptedBackup != null)
            'donation_not_accepted_backup': donationNotAcceptedBackup,
        };
      case FuneralPreference.noPreference:
      case FuneralPreference.greenBurial:
        return {
          if (directionBy != null)
            'direction_by': directionBy!.map((d) => d.toJson()).toList(),
        };
    }
  }

  FuneralPreferenceData copyWith({
    List<DirectionPerson>? directionBy,
    String? ashDisposalInstruction,
    Religion? religion,
    String? specificRite,
    String? placeOfWorship,
    String? cemeteryName,
    String? universityId,
    String? donationNotAcceptedBackup,
  }) {
    return FuneralPreferenceData(
      directionBy: directionBy ?? this.directionBy,
      ashDisposalInstruction:
          ashDisposalInstruction ?? this.ashDisposalInstruction,
      religion: religion ?? this.religion,
      specificRite: specificRite ?? this.specificRite,
      placeOfWorship: placeOfWorship ?? this.placeOfWorship,
      cemeteryName: cemeteryName ?? this.cemeteryName,
      universityId: universityId ?? this.universityId,
      donationNotAcceptedBackup:
          donationNotAcceptedBackup ?? this.donationNotAcceptedBackup,
    );
  }

  @override
  List<Object?> get props => [
        directionBy,
        ashDisposalInstruction,
        religion,
        specificRite,
        placeOfWorship,
        cemeteryName,
        universityId,
        donationNotAcceptedBackup,
      ];
}

// Main funeral model
class FuneralModel extends Equatable {
  final dynamic id;
  final FuneralPreference funeralPreference;
  final FuneralPreferenceData? funeralPreferenceData;
  final String? serviceLocation;
  final DateTime? dateTimePreference;
  final int? musicId;
  final String? musicName;
  final String? specialInstruction;
  final String? legacyMessage;
  final String? legacyMessageVideoUrl;
  final List<FuneralAttendeeModel>? attendees;

  const FuneralModel({
    this.id,
    required this.funeralPreference,
    this.funeralPreferenceData,
    this.serviceLocation,
    this.dateTimePreference,
    this.musicId,
    this.musicName,
    this.specialInstruction,
    this.legacyMessage,
    this.legacyMessageVideoUrl,
    this.attendees,
  });

  factory FuneralModel.fromJson(Map<String, dynamic> json) {
    // Handle music as object {id, name} or as plain music_id int
    int? musicId;
    String? musicName;
    if (json['music'] != null && json['music'] is Map) {
      final musicObj = json['music'] as Map<String, dynamic>;
      musicId = musicObj['id'] as int?;
      musicName = musicObj['name'] as String?;
    } else {
      musicId = json['music_id'] as int?;
    }

    return FuneralModel(
      id: json['id'],
      funeralPreference: FuneralPreference.fromString(
        json['funeral_preference'] as String,
      ),
      funeralPreferenceData: json['funeral_preference_data'] != null
          ? FuneralPreferenceData.fromJson(
              json['funeral_preference_data'] as Map<String, dynamic>)
          : null,
      serviceLocation: json['service_location'] as String?,
      dateTimePreference: json['date_time_preference'] != null
          ? DateTime.tryParse(json['date_time_preference'] as String)
          : null,
      musicId: musicId,
      musicName: musicName,
      specialInstruction: json['special_instruction'] as String?,
      legacyMessage: json['legacy_message'] as String?,
      legacyMessageVideoUrl: json['legacy_message_video_url'] as String?,
      attendees: json['attendees'] != null
          ? (json['attendees'] as List)
              .map((e) =>
                  FuneralAttendeeModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'funeral_preference': funeralPreference.value,
      if (funeralPreferenceData != null)
        'funeral_preference_data':
            funeralPreferenceData!.toJson(funeralPreference),
      if (serviceLocation != null) 'service_location': serviceLocation,
      if (dateTimePreference != null)
        'date_time_preference': dateTimePreference!.toIso8601String(),
      if (musicId != null) 'music_id': musicId,
      if (specialInstruction != null) 'special_instruction': specialInstruction,
      if (legacyMessage != null) 'legacy_message': legacyMessage,
    };
  }

  FuneralModel copyWith({
    dynamic id,
    FuneralPreference? funeralPreference,
    FuneralPreferenceData? funeralPreferenceData,
    String? serviceLocation,
    DateTime? dateTimePreference,
    int? musicId,
    String? musicName,
    String? specialInstruction,
    String? legacyMessage,
    String? legacyMessageVideoUrl,
    List<FuneralAttendeeModel>? attendees,
  }) {
    return FuneralModel(
      id: id ?? this.id,
      funeralPreference: funeralPreference ?? this.funeralPreference,
      funeralPreferenceData:
          funeralPreferenceData ?? this.funeralPreferenceData,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      dateTimePreference: dateTimePreference ?? this.dateTimePreference,
      musicId: musicId ?? this.musicId,
      musicName: musicName ?? this.musicName,
      specialInstruction: specialInstruction ?? this.specialInstruction,
      legacyMessage: legacyMessage ?? this.legacyMessage,
      legacyMessageVideoUrl:
          legacyMessageVideoUrl ?? this.legacyMessageVideoUrl,
      attendees: attendees ?? this.attendees,
    );
  }

  @override
  List<Object?> get props => [
        id,
        funeralPreference,
        funeralPreferenceData,
        serviceLocation,
        dateTimePreference,
        musicId,
        musicName,
        specialInstruction,
        legacyMessage,
        legacyMessageVideoUrl,
        attendees,
      ];
}

// Funeral attendee model (recipients for legacy messages)
class FuneralAttendeeModel extends Equatable {
  final int? id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final String? relation;

  const FuneralAttendeeModel({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    this.mobile,
    this.relation,
  });

  factory FuneralAttendeeModel.fromJson(Map<String, dynamic> json) {
    return FuneralAttendeeModel(
      id: json['id'] as int?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      relation: json['relation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (relation != null) 'relation': relation,
    };
  }

  String get fullName {
    final parts = [
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName,
      lastName,
    ].where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  FuneralAttendeeModel copyWith({
    int? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? mobile,
    String? relation,
  }) {
    return FuneralAttendeeModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      relation: relation ?? this.relation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        middleName,
        lastName,
        email,
        mobile,
        relation,
      ];
}

// Music option model from /user/funeral/music API
class MusicOption extends Equatable {
  final int id;
  final String name;

  const MusicOption({required this.id, required this.name});

  factory MusicOption.fromJson(Map<String, dynamic> json) {
    return MusicOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

// Science donation institution model
class ScienceDonationInstitution extends Equatable {
  final String? id;
  final String name;
  final String? type;

  const ScienceDonationInstitution({
    this.id,
    required this.name,
    this.type,
  });

  factory ScienceDonationInstitution.fromJson(Map<String, dynamic> json) {
    return ScienceDonationInstitution(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (type != null) 'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, type];
}

// Will person model from /user/will-people API
class WillPerson extends Equatable {
  final int? id;
  final String? fullName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? address;
  final bool? isSelected;

  const WillPerson({
    this.id,
    this.fullName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    this.phone,
    this.address,
    this.isSelected,
  });

  factory WillPerson.fromJson(Map<String, dynamic> json) {
    return WillPerson(
      id: json['id'] as int?,
      fullName: json['full_name'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isSelected: json['is_selected'] as bool?,
    );
  }

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = [firstName, lastName]
        .where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  @override
  List<Object?> get props =>
      [id, fullName, firstName, middleName, lastName, email, phone, address, isSelected];
}

// Response wrapper for API calls
class FuneralResponse<T> extends Equatable {
  final String status;
  final String message;
  final T? data;

  const FuneralResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory FuneralResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return FuneralResponse(
      status: json['status'] as String? ?? 'success',
      message: json['message'] as String? ?? '',
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : null,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailure => status == 'failure' || status == 'error';

  @override
  List<Object?> get props => [status, message, data];
}
