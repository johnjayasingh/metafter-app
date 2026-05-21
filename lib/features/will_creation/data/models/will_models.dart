import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

// ==================== REQUESTS ====================

class InitialWillRequest {
  final String? willId; // Pass for update, omit for new
  final bool hasCapacity;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String dob;
  final String addressLine1;
  final String suburb;
  final String postcode;
  final String country;
  final String? state;
  final List<String>? otherNames;

  InitialWillRequest({
    this.willId,
    required this.hasCapacity,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dob,
    required this.addressLine1,
    required this.suburb,
    required this.postcode,
    required this.country,
    this.state,
    this.otherNames,
  });

  Map<String, dynamic> toJson() {
    return {
      if (willId != null) 'will_id': willId,
      'has_capacity': hasCapacity,
      'first_name': firstName,
      if (middleName != null && middleName!.isNotEmpty) 'middle_name': middleName,
      'last_name': lastName,
      'dob': dob,
      'address_line_1': addressLine1,
      'suburb': suburb,
      'postcode': postcode,
      'country': country,
      if (state != null) 'state': state,
      if (otherNames != null && otherNames!.isNotEmpty) 'other_names': otherNames,
    };
  }
}

class WillAssetRequest {
  final String willId;
  final String assetType;  // UUID of the asset type
  final String? assetName;
  final String institution; // UUID of the institution
  final String? location;
  final String description;
  final int? assetId; // Optional: for updating existing assets

  WillAssetRequest({
    required this.willId,
    required this.assetType,
    this.assetName,
    required this.institution,
    this.location,
    required this.description,
    this.assetId,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'asset_type': assetType,
      if (assetName != null && assetName!.isNotEmpty) 'asset_name': assetName,
      'institution': institution,
      if (location != null && location!.isNotEmpty) 'location': location,
      'description': description,
      if (assetId != null) 'asset_id': assetId,
    };
  }
}

/// Asset type from the catalog API (/will/assets)
class AssetTypeItem extends Equatable {
  final String id;
  final String name;
  final String identifier;

  const AssetTypeItem({
    required this.id,
    required this.name,
    required this.identifier,
  });

  factory AssetTypeItem.fromJson(Map<String, dynamic> json) {
    return AssetTypeItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, identifier];
}

/// Institution from the API (/will/asset-institutions)
class InstitutionItem extends Equatable {
  final String id;
  final String identifier;
  final String name;
  final String? country;

  const InstitutionItem({
    required this.id,
    required this.identifier,
    required this.name,
    this.country,
  });

  factory InstitutionItem.fromJson(Map<String, dynamic> json) {
    return InstitutionItem(
      id: json['id']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, identifier, name, country];
}

class BeneficiaryAllocationRequest {
  final String willId;
  final List<AllocationItem> allocation;
  final bool? isDivideEqually;

  BeneficiaryAllocationRequest({
    required this.willId,
    required this.allocation,
    this.isDivideEqually,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      if (isDivideEqually != null) 'is_divide_equally': isDivideEqually,
      'allocation': allocation.map((e) => e.toJson()).toList(),
    };
  }
}

/// Response model for GET /will/beneficiary/allocation
class BeneficiaryAllocationResponse {
  final String willId;
  final List<AllocationItem> allocation;
  final bool isDivideEqually;

  BeneficiaryAllocationResponse({
    required this.willId,
    required this.allocation,
    required this.isDivideEqually,
  });

  factory BeneficiaryAllocationResponse.fromJson(Map<String, dynamic> json) {
    final allocationJson = json['allocation'] as List<dynamic>? ?? [];
    return BeneficiaryAllocationResponse(
      willId: json['will_id']?.toString() ?? '',
      allocation: allocationJson
          .map((e) => AllocationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isDivideEqually: json['is_divide_equally'] as bool? ?? false,
    );
  }
}

/// Backup beneficiary reference inside a backup_detail
class BackupBeneficiary {
  final int beneficiaryId;
  final BeneficiaryType beneficiaryType;

  BackupBeneficiary({
    required this.beneficiaryId,
    required this.beneficiaryType,
  });

  Map<String, dynamic> toJson() => {
    'beneficiary_id': beneficiaryId,
    'beneficiary_type': beneficiaryType.value,
  };

  factory BackupBeneficiary.fromJson(Map<String, dynamic> json) {
    return BackupBeneficiary(
      beneficiaryId: json['beneficiary_id'] as int? ?? 0,
      beneficiaryType: BeneficiaryType.fromString(json['beneficiary_type'] as String?),
    );
  }
}

/// Backup detail for an allocation item — specifies who should receive
/// the allocation if the primary beneficiary cannot.
class BackupDetail {
  final AllocationNotifyFor allocationNotifyFor;
  final List<BackupBeneficiary> beneficiaries;

  BackupDetail({
    required this.allocationNotifyFor,
    required this.beneficiaries,
  });

  Map<String, dynamic> toJson() => {
    'allocation_notify_for': allocationNotifyFor.value,
    'beneficiaries': beneficiaries.map((e) => e.toJson()).toList(),
  };

  factory BackupDetail.fromJson(Map<String, dynamic> json) {
    final beneficiariesJson = json['beneficiaries'] as List<dynamic>? ?? [];
    return BackupDetail(
      allocationNotifyFor: AllocationNotifyFor.fromString(json['allocation_notify_for'] as String?),
      beneficiaries: beneficiariesJson
          .map((e) => BackupBeneficiary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AllocationItem {
  final String? allocationId; // UUID — null for new allocations
  final int beneficiaryId; // will_person_id for persons, charity_id for charities
  final BeneficiaryType beneficiaryType;
  final String percentage;
  final bool? enableAllocation;
  final BackupDetail? backupDetail;

  AllocationItem({
    this.allocationId,
    required this.beneficiaryId,
    required this.beneficiaryType,
    required this.percentage,
    this.enableAllocation,
    this.backupDetail,
  });

  Map<String, dynamic> toJson() {
    return {
      if (allocationId != null) 'allocation_id': allocationId,
      'beneficiary_id': beneficiaryId,
      'beneficiary_type': beneficiaryType.value,
      'percentage': percentage,
      if (backupDetail != null) 'backup_detail': backupDetail!.toJson(),
    };
  }

  factory AllocationItem.fromJson(Map<String, dynamic> json) {
    return AllocationItem(
      allocationId: json['allocation_id']?.toString(),
      beneficiaryId: json['beneficiary_id'] as int? ?? json['id'] as int? ?? 0,
      beneficiaryType: BeneficiaryType.fromString(json['beneficiary_type'] as String?),
      percentage: (json['percentage'] ?? 0).toString(),
      enableAllocation: json['enable_allocation'] as bool?,
      backupDetail: json['backup_detail'] != null
          ? BackupDetail.fromJson(json['backup_detail'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ==================== RESPONSES ====================

class WillResponse<T> extends Equatable {
  final String status;
  final String? message;
  final T? data;

  const WillResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory WillResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return WillResponse<T>(
      status: json['status'] as String,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailure => status == 'failure';

  @override
  List<Object?> get props => [status, message, data];
}

class InitialWillData extends Equatable {
  final String willId;
  final bool hasCapacity;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String dob;
  final String addressLine1;
  final String suburb;
  final String postcode;
  final String country;
  final String? state;
  final List<String>? otherNames;
  final bool isMedicalProofDocumentUploaded;
  final String? medicalProofDocumentFile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InitialWillData({
    required this.willId,
    this.hasCapacity = false,
    this.firstName = '',
    this.middleName,
    this.lastName = '',
    this.dob = '',
    this.addressLine1 = '',
    this.suburb = '',
    this.postcode = '',
    this.country = '',
    this.state,
    this.otherNames,
    this.isMedicalProofDocumentUploaded = false,
    this.medicalProofDocumentFile,
    this.createdAt,
    this.updatedAt,
  });

  factory InitialWillData.fromJson(Map<String, dynamic> json) {
    return InitialWillData(
      willId: json['will_id']?.toString() ?? json['id']?.toString() ?? '',
      hasCapacity: json['has_capacity'] as bool? ?? false,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      addressLine1: json['address_line_1']?.toString() ?? '',
      suburb: json['suburb']?.toString() ?? '',
      postcode: json['postcode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      state: json['state']?.toString(),
      otherNames: (json['other_names'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      isMedicalProofDocumentUploaded: json['is_medical_proof_document_uploaded'] as bool? ?? false,
      medicalProofDocumentFile: json['medical_proof_document_file']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  @override
  List<Object?> get props => [
        willId,
        hasCapacity,
        firstName,
        middleName,
        lastName,
        dob,
        addressLine1,
        suburb,
        postcode,
        country,
        state,
        otherNames,
        isMedicalProofDocumentUploaded,
        medicalProofDocumentFile,
        createdAt,
        updatedAt,
      ];
}

class WillAsset extends Equatable {
  final String id;
  final String willId;
  final String assetType;
  final String? assetTypeId;
  final String? assetName;
  final String institution;
  final String? institutionId;
  final String? location;
  final String description;
  final DateTime? createdAt;

  const WillAsset({
    required this.id,
    required this.willId,
    required this.assetType,
    this.assetTypeId,
    this.assetName,
    required this.institution,
    this.institutionId,
    this.location,
    required this.description,
    this.createdAt,
  });

  factory WillAsset.fromJson(Map<String, dynamic> json) {
    final assetId = (json['asset_id'] ?? json['id'])?.toString() ?? '';
    return WillAsset(
      id: assetId,
      willId: json['will_id']?.toString() ?? '',
      assetType: json['asset_type']?.toString() ?? '',
      assetTypeId: json['asset_type_id']?.toString(),
      assetName: json['asset_name']?.toString(),
      institution: json['institution']?.toString() ?? '',
      institutionId: json['institution_id']?.toString(),
      location: json['location']?.toString(),
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, willId, assetType, assetTypeId, assetName, institution, institutionId, location, description, createdAt];
}

class WillSummary extends Equatable {
  final String willId;
  final String status;
  final String fullName;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final String? invitedRole; // 'witness', 'executor', 'lawyer', etc.

  const WillSummary({
    required this.willId,
    required this.status,
    required this.fullName,
    required this.createdAt,
    this.lastUpdated,
    this.invitedRole,
  });

  factory WillSummary.fromJson(Map<String, dynamic> json) {
    final testatorDetail = json['testator_detail'] as Map<String, dynamic>?;
    final firstName = (testatorDetail?['first_name']?.toString() ?? '').trim();
    final rawMiddle = testatorDetail?['middle_name'];
    final middleName = (rawMiddle != null && rawMiddle.toString() != 'null')
        ? rawMiddle.toString().trim()
        : '';
    final lastName = (testatorDetail?['last_name']?.toString() ?? '').trim();
    final nameParts = [firstName, if (middleName.isNotEmpty) middleName, lastName]
        .where((p) => p.isNotEmpty)
        .toList();
    final fullName = nameParts.join(' ');

    return WillSummary(
      willId: json['will_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Draft',
      fullName: fullName.trim(),
      createdAt: DateTime.parse(json['created_at']),
      lastUpdated: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      invitedRole: (json['invited_role'] ?? json['role'])?.toString(),
    );
  }

  @override
  List<Object?> get props => [willId, status, fullName, createdAt, lastUpdated, invitedRole];
}

// ==================== MEDICAL PROOF ====================

class MedicalProofUploadData extends Equatable {
  final String file;

  const MedicalProofUploadData({
    required this.file,
  });

  factory MedicalProofUploadData.fromJson(Map<String, dynamic> json) {
    return MedicalProofUploadData(
      file: json['file']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [file];
}
