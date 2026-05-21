import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────
// VaultAssetType — the type discriminator for the unified API
// ─────────────────────────────────────────
enum VaultAssetType { message, contact, liability, asset }

extension VaultAssetTypeExt on VaultAssetType {
  String get apiValue {
    switch (this) {
      case VaultAssetType.message:
        return 'MESSAGE';
      case VaultAssetType.contact:
        return 'CONTACT';
      case VaultAssetType.liability:
        return 'LIABILITY';
      case VaultAssetType.asset:
        return 'ASSET';
    }
  }

  static VaultAssetType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MESSAGE':
        return VaultAssetType.message;
      case 'CONTACT':
        return VaultAssetType.contact;
      case 'LIABILITY':
        return VaultAssetType.liability;
      case 'ASSET':
        return VaultAssetType.asset;
      default:
        return VaultAssetType.asset;
    }
  }
}

// ─────────────────────────────────────────
// VaultItem — unified vault item from API
// ─────────────────────────────────────────
class VaultItem extends Equatable {
  final String id;
  final VaultAssetType type;
  final Map<String, dynamic> data;
  final List<VaultFile> files;
  final DateTime? createdAt;

  const VaultItem({
    required this.id,
    required this.type,
    required this.data,
    this.files = const [],
    this.createdAt,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    final rawFiles =
        (json['documents'] ?? json['files']) as List<dynamic>? ?? [];
    final filesList = rawFiles
        .map((f) => VaultFile.fromJson(f as Map<String, dynamic>))
        .toList();

    return VaultItem(
      id: json['id'] as String,
      type: VaultAssetTypeExt.fromString(json['type'] as String? ?? 'ASSET'),
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      files: filesList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.apiValue,
        'data': data,
      };

  // Convenience getters for typed data access
  MessageData get messageData => MessageData.fromMap(data);
  LiabilityData get liabilityData => LiabilityData.fromMap(data);
  AssetData get assetData => AssetData.fromMap(data);
  ContactData get contactData => ContactData.fromMap(data);

  /// Display title based on type
  String get displayTitle {
    switch (type) {
      case VaultAssetType.message:
        return messageData.title;
      case VaultAssetType.liability:
        return liabilityData.name;
      case VaultAssetType.asset:
        return assetData.name;
      case VaultAssetType.contact:
        return contactData.fullName;
    }
  }

  /// Display subtitle based on type
  String? get displaySubtitle {
    switch (type) {
      case VaultAssetType.message:
        return messageData.message;
      case VaultAssetType.liability:
        return liabilityData.location;
      case VaultAssetType.asset:
        return assetData.location;
      case VaultAssetType.contact:
        return contactData.email;
    }
  }

  @override
  List<Object?> get props => [id, type, data, files, createdAt];
}

// ─────────────────────────────────────────
// VaultItemCreate — POST /vault/assets body
// ─────────────────────────────────────────
class VaultItemCreate {
  final String? assetId;
  final VaultAssetType type;
  final Map<String, dynamic> data;

  const VaultItemCreate({
    this.assetId,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        if (assetId != null) 'asset_id': assetId,
        'type': type.apiValue,
        'data': data,
      };
}

// ─────────────────────────────────────────
// Type-specific data helpers
// ─────────────────────────────────────────

class MessageRecipient {
  final String fullName;
  final String? email;
  final String? phone;

  const MessageRecipient({
    required this.fullName,
    this.email,
    this.phone,
  });

  factory MessageRecipient.fromMap(Map<String, dynamic> map) =>
      MessageRecipient(
        fullName: map['full_name'] as String? ?? '',
        email: map['email'] as String?,
        phone: map['phone'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };
}

class MessageData {
  final String title;
  final String message;
  final List<String> fileIds;
  final List<MessageRecipient> recipients;

  const MessageData({
    required this.title,
    this.message = '',
    this.fileIds = const [],
    this.recipients = const [],
  });

  factory MessageData.fromMap(Map<String, dynamic> map) {
    final rawRecipients = map['recipients'] as List<dynamic>? ?? [];
    final recipients = rawRecipients.map((e) {
      if (e is Map<String, dynamic>) {
        return MessageRecipient.fromMap(e);
      }
      return MessageRecipient(fullName: e.toString());
    }).toList();

    return MessageData(
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      fileIds: (map['files'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recipients: recipients,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        if (fileIds.isNotEmpty) 'files': fileIds,
        if (recipients.isNotEmpty)
          'recipients': recipients.map((r) => r.toMap()).toList(),
      };
}

class LiabilityData {
  final String name;
  final String? assetType;
  final String? assetTypeId;
  final String? institution;
  final String? institutionId;
  final String location;
  final String detail;

  const LiabilityData({
    required this.name,
    this.assetType,
    this.assetTypeId,
    this.institution,
    this.institutionId,
    this.location = '',
    this.detail = '',
  });

  factory LiabilityData.fromMap(Map<String, dynamic> map) => LiabilityData(
        name: map['name'] as String? ?? '',
        assetType: map['asset_type'] as String?,
        assetTypeId: map['asset_type_id'] as String?,
        institution: map['institution'] as String?,
        institutionId: map['institution_id'] as String?,
        location: map['location'] as String? ?? '',
        detail: map['detail'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (assetType != null) 'asset_type': assetType,
        if (assetTypeId != null) 'asset_type_id': assetTypeId,
        if (institution != null && institution!.isNotEmpty) 'institution': institution,
        if (institutionId != null) 'institution_id': institutionId,
        if (location.isNotEmpty) 'location': location,
        if (detail.isNotEmpty) 'detail': detail,
      };
}

class AssetData {
  final String? willId;
  final String? assetId;
  final String name;
  final String? assetType;
  final String? assetTypeId;
  final String location;
  final String description;
  final String? institution;
  final String? institutionId;

  const AssetData({
    this.willId,
    this.assetId,
    required this.name,
    this.assetType,
    this.assetTypeId,
    this.location = '',
    this.description = '',
    this.institution,
    this.institutionId,
  });

  factory AssetData.fromMap(Map<String, dynamic> map) => AssetData(
        willId: map['will_id'] as String?,
        assetId: map['asset_id']?.toString(),
        name: map['asset_name'] as String? ?? map['name'] as String? ?? '',
        assetType: map['asset_type'] as String?,
        assetTypeId: map['asset_type_id'] as String?,
        location: map['location'] as String? ?? '',
        description: map['description'] as String? ?? map['detail'] as String? ?? '',
        institution: map['institution'] as String?,
        institutionId: map['institution_id'] as String?,
      );

  AssetData copyWith({
    String? willId,
    String? assetId,
    String? name,
    String? assetType,
    String? assetTypeId,
    String? location,
    String? description,
    String? institution,
    String? institutionId,
  }) =>
      AssetData(
        willId: willId ?? this.willId,
        assetId: assetId ?? this.assetId,
        name: name ?? this.name,
        assetType: assetType ?? this.assetType,
        assetTypeId: assetTypeId ?? this.assetTypeId,
        location: location ?? this.location,
        description: description ?? this.description,
        institution: institution ?? this.institution,
        institutionId: institutionId ?? this.institutionId,
      );

  Map<String, dynamic> toMap() => {
        if (willId != null) 'will_id': willId,
        if (assetId != null) 'asset_id': assetId,
        'asset_name': name,
        if (assetType != null) 'asset_type': assetType,
        if (assetTypeId != null) 'asset_type_id': assetTypeId,
        if (location.isNotEmpty) 'location': location,
        if (description.isNotEmpty) 'description': description,
        if (institution != null && institution!.isNotEmpty) 'institution': institution,
        if (institutionId != null) 'institution_id': institutionId,
      };
}

class ContactData {
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  const ContactData({
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ContactData.fromMap(Map<String, dynamic> map) {
    // Parse full_name into first/last if first_name is absent
    final firstName = map['first_name'] as String? ?? '';
    final lastName = map['last_name'] as String? ?? '';
    final fullName = map['full_name'] as String? ?? '';

    String parsedFirst = firstName;
    String parsedLast = lastName;
    if (parsedFirst.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      parsedFirst = parts.first;
      parsedLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return ContactData(
      firstName: parsedFirst,
      lastName: parsedLast,
      email: map['email'] as String?,
      phone: map['phone'] as String? ?? map['mobile'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };
}

// ─────────────────────────────────────────
// VaultFile — file attached to a vault item
// ─────────────────────────────────────────
class VaultFile {
  final String id;
  final String filename;
  final String? contentType;

  const VaultFile({
    required this.id,
    required this.filename,
    this.contentType,
  });

  factory VaultFile.fromJson(Map<String, dynamic> json) => VaultFile(
        id: json['id'] as String,
        filename:
            json['filename'] as String? ?? json['file_name'] as String? ?? 'file',
        contentType: json['content_type'] as String?,
      );
}

// ─────────────────────────────────────────
// VaultUploadResult — response from POST /vault/files/upload
// ─────────────────────────────────────────
class VaultUploadResult {
  final VaultFile file;
  final String? assetId;

  const VaultUploadResult({required this.file, this.assetId});
}

// ─────────────────────────────────────────
// VaultPreference — GET/POST /vault/preferences
// ─────────────────────────────────────────
enum ActionAfterDeath { closeAccount, transferOwnership, noAction }

extension ActionAfterDeathExt on ActionAfterDeath {
  String get apiValue {
    switch (this) {
      case ActionAfterDeath.closeAccount:
        return 'CLOSE_ACCOUNT';
      case ActionAfterDeath.transferOwnership:
        return 'TRANSFER_OWNERSHIP';
      case ActionAfterDeath.noAction:
        return 'NO_ACTION';
    }
  }

  static ActionAfterDeath fromString(String value) {
    switch (value) {
      case 'CLOSE_ACCOUNT':
        return ActionAfterDeath.closeAccount;
      case 'TRANSFER_OWNERSHIP':
        return ActionAfterDeath.transferOwnership;
      case 'NO_ACTION':
        return ActionAfterDeath.noAction;
      default:
        return ActionAfterDeath.noAction;
    }
  }
}

class VaultPreference {
  final ActionAfterDeath actionAfterDeath;
  final String? notes;
  final String? executorNotes;

  const VaultPreference({
    required this.actionAfterDeath,
    this.notes,
    this.executorNotes,
  });

  factory VaultPreference.fromJson(Map<String, dynamic> json) => VaultPreference(
        actionAfterDeath: ActionAfterDeathExt.fromString(
          json['action_after_death'] as String,
        ),
        notes: json['notes'] as String?,
        executorNotes: json['executor_notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'action_after_death': actionAfterDeath.apiValue,
        'notes': notes ?? '',
        'executor_notes': executorNotes ?? '',
      };
}

// ─────────────────────────────────────────
// Generic API wrapper matching CustomResponse
// ─────────────────────────────────────────
class VaultResponse<T> {
  final String status;
  final String? message;
  final T? data;

  const VaultResponse({
    required this.status,
    this.message,
    this.data,
  });

  bool get isSuccess => status == 'success';

  factory VaultResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return VaultResponse<T>(
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String?,
      data: fromData != null && json['data'] != null ? fromData(json['data']) : null,
    );
  }
}

// ─────────────────────────────────────────
// Will data models — for selecting from will
// ─────────────────────────────────────────
class WillPerson {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String? role;

  const WillPerson({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    this.role,
  });

  String get fullName {
    final parts = [firstName, if (middleName != null) middleName!, lastName];
    return parts.join(' ');
  }

  factory WillPerson.fromJson(Map<String, dynamic> json) => WillPerson(
        id: json['id'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        middleName: json['middle_name'] as String?,
        lastName: json['last_name'] as String? ?? '',
        email: json['email'] as String?,
        mobile: json['mobile'] as String?,
        role: json['role'] as String?,
      );
}

class WillAsset {
  final String? willId;
  final String id;
  final String name;
  final String? type;
  final String? typeId;
  final String? institution;
  final String? institutionId;
  final String? location;
  final String? description;

  const WillAsset({
    this.willId,
    required this.id,
    required this.name,
    this.type,
    this.typeId,
    this.institution,
    this.institutionId,
    this.location,
    this.description,
  });

  factory WillAsset.fromJson(Map<String, dynamic> json) => WillAsset(
        willId: json['will_id'] as String?,
        id: json['id']?.toString() ?? json['asset_id']?.toString() ?? '',
        name: json['asset_name'] as String? ??
            json['name'] as String? ??
            '',
        type: json['asset_type'] as String? ?? json['type'] as String?,
        typeId: json['asset_type_id'] as String?,
        institution: json['institution'] as String?,
        institutionId: json['institution_id'] as String?,
        location: json['location'] as String?,
        description: json['description'] as String? ?? json['details'] as String?,
      );

  /// Convert to AssetData for creating a vault item from this will asset.
  AssetData toAssetData() => AssetData(
        willId: willId,
        assetId: id,
        name: name,
        assetType: type,
        assetTypeId: typeId,
        location: location ?? '',
        description: description ?? '',
        institution: institution,
        institutionId: institutionId,
      );
}
