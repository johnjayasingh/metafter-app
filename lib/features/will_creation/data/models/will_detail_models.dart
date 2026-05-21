import 'package:equatable/equatable.dart';

// ==================== WILL COMPLETE DETAIL ====================

class WillCompleteDetail extends Equatable {
  final WillInfoDetail willInfo;
  final PersonName createdBy;
  final List<PersonName> witness;
  final List<PersonName> executors;
  final PersonName? lawyer;
  final String? willOriginal;
  final String? willWatermarked;
  final String? willCoverImage;

  const WillCompleteDetail({
    required this.willInfo,
    required this.createdBy,
    required this.witness,
    this.executors = const [],
    this.lawyer,
    this.willOriginal,
    this.willWatermarked,
    this.willCoverImage,
  });

  /// For backward compatibility - returns first executor or null
  PersonName? get executor => executors.isNotEmpty ? executors.first : null;

  factory WillCompleteDetail.fromJson(Map<String, dynamic> json) {
    // Parse executors - handle multiple response formats:
    // 1. 'executors' flat array of {first_name, last_name, middle_name}
    // 2. Legacy 'executor' single object
    // 3. Nested 'personal_executors' / 'professional_executors' arrays (from /will/executor format)
    List<PersonName> executorsList = [];
    if (json['executors'] != null && json['executors'] is List) {
      executorsList = (json['executors'] as List<dynamic>)
          .map((e) => PersonName.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['executor'] != null && json['executor'] is Map) {
      // Legacy support for single executor
      executorsList = [
        PersonName.fromJson(json['executor'] as Map<String, dynamic>),
      ];
    }

    // Also try nested format (personal_executors / professional_executors)
    if (executorsList.isEmpty) {
      if (json['personal_executors'] != null && json['personal_executors'] is List) {
        executorsList.addAll(
          (json['personal_executors'] as List<dynamic>)
              .map((e) => PersonName.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      if (json['professional_executors'] != null && json['professional_executors'] is List) {
        executorsList.addAll(
          (json['professional_executors'] as List<dynamic>)
              .map((e) => PersonName.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    }

    return WillCompleteDetail(
      willInfo: WillInfoDetail.fromJson(
        json['will_info'] as Map<String, dynamic>,
      ),
      createdBy: PersonName.fromJson(
        json['created_by'] as Map<String, dynamic>,
      ),
      witness:
          (json['witness'] as List<dynamic>?)
              ?.map((e) => PersonName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      executors: executorsList,
      lawyer: json['lawyer'] != null
          ? PersonName.fromJson(json['lawyer'] as Map<String, dynamic>)
          : null,
      willOriginal: json['will_original']?.toString(),
      willWatermarked: json['will_watermarked']?.toString(),
      willCoverImage: json['will_cover_image']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    willInfo,
    createdBy,
    witness,
    executors,
    lawyer,
    willOriginal,
    willWatermarked,
    willCoverImage,
  ];
}

class WillInfoDetail extends Equatable {
  final String id;
  final String status;
  final DateTime createdOn;
  final DateTime lastUpdate;

  const WillInfoDetail({
    required this.id,
    required this.status,
    required this.createdOn,
    required this.lastUpdate,
  });

  factory WillInfoDetail.fromJson(Map<String, dynamic> json) {
    return WillInfoDetail(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdOn: DateTime.parse(json['created_on']),
      lastUpdate: DateTime.parse(json['last_update']),
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'IN_LEGAL_REVIEW':
        return 'Sent for legal review';
      case 'DRAFT':
        return 'Draft';
      case 'COMPLETED':
        return 'Completed';
      case 'SIGNED':
        return 'Signed';
      default:
        return status.replaceAll('_', ' ').toLowerCase();
    }
  }

  @override
  List<Object?> get props => [id, status, createdOn, lastUpdate];
}

class PersonName extends Equatable {
  final String firstName;
  final String? middleName;
  final String lastName;

  const PersonName({
    required this.firstName,
    this.middleName,
    required this.lastName,
  });

  factory PersonName.fromJson(Map<String, dynamic> json) {
    final rawMiddle = json['middle_name'];
    // Guard against JSON null being converted to the string "null"
    final middleName = (rawMiddle != null && rawMiddle.toString() != 'null')
        ? rawMiddle.toString().trim()
        : null;
    return PersonName(
      firstName: (json['first_name']?.toString() ?? '').trim(),
      middleName: (middleName != null && middleName.isNotEmpty) ? middleName : null,
      lastName: (json['last_name']?.toString() ?? '').trim(),
    );
  }

  String get fullName {
    final parts = <String>[
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName!,
      lastName,
    ];
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  String get initials {
    String firstInitial = firstName.isNotEmpty
        ? firstName[0].toUpperCase()
        : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  @override
  List<Object?> get props => [firstName, middleName, lastName];
}

// ==================== COMMENTS ====================

class WillComment extends Equatable {
  final int id;
  final String willId;
  final String documentId;
  final String userId;
  final String name;
  final String comment;
  final DateTime createdAt;

  const WillComment({
    required this.id,
    required this.willId,
    required this.documentId,
    required this.userId,
    required this.name,
    required this.comment,
    required this.createdAt,
  });

  factory WillComment.fromJson(Map<String, dynamic> json) {
    return WillComment(
      id: json['id'] as int,
      willId: json['will_id']?.toString() ?? '',
      documentId: json['document_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    willId,
    documentId,
    userId,
    name,
    comment,
    createdAt,
  ];
}

class AddCommentRequest {
  final String willId;
  final String comment;

  AddCommentRequest({required this.willId, required this.comment});

  Map<String, dynamic> toJson() {
    return {'will_id': willId, 'comment': comment};
  }
}

class AddCommentResponse {
  final int commentId;

  AddCommentResponse({required this.commentId});

  factory AddCommentResponse.fromJson(Map<String, dynamic> json) {
    return AddCommentResponse(commentId: json['comment_id'] as int);
  }
}
