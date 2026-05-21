import 'package:equatable/equatable.dart';

// ==================== PERSON MODEL ====================

class PersonDetails extends Equatable {
  final int? id; // Pass for update, omit for new
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String? relationship;
  final String? dob;

  const PersonDetails({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    this.relationship,
    this.dob,
  });

  // Convert DD/MM/YYYY to YYYY-MM-DD format for API
  String? _convertDobFormat(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dob;
  }

  Map<String, dynamic> toJson() {
    final convertedDob = _convertDobFormat(dob);
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'middle_name': middleName ?? '', // Always include, even if empty
      'last_name': lastName,
      'email': (email != null && email!.isNotEmpty) ? email : null,
      'mobile': (mobile != null && mobile!.isNotEmpty) ? mobile : null,
      if (relationship != null && relationship!.isNotEmpty) 'relationship': relationship,
      if (convertedDob != null) 'dob': convertedDob,
    };
  }

  factory PersonDetails.fromJson(Map<String, dynamic> json) {
    final rawMobile = json['mobile']?.toString();
    final rawEmail = json['email']?.toString();
    return PersonDetails(
      id: json['id'] as int?,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : null,
      mobile: (rawMobile != null && rawMobile.isNotEmpty) ? rawMobile : null,
      relationship: json['relationship']?.toString(),
      dob: json['dob']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, email, mobile, relationship, dob];
}

// ==================== CARETAKER MODEL ====================

class CareTaker extends Equatable {
  final int? id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String instruction;
  final String? relationship;
  final String? dob;
  final String? address;

  const CareTaker({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    required this.instruction,
    this.relationship,
    this.dob,
    this.address,
  });

  // Convert DD/MM/YYYY to YYYY-MM-DD format for API
  String? _convertDobFormat(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dob; // Return as-is if not in expected format
  }

  Map<String, dynamic> toJson() {
    final convertedDob = _convertDobFormat(dob);
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'middle_name': middleName ?? '',
      'last_name': lastName,
      'email': (email != null && email!.isNotEmpty) ? email : null,
      'mobile': (mobile != null && mobile!.isNotEmpty) ? mobile : null,
      'instruction': instruction,
      if (relationship != null && relationship!.isNotEmpty) 'relationship': relationship,
      if (convertedDob != null) 'dob': convertedDob,
      if (address != null) 'address': address,
    };
  }

  factory CareTaker.fromJson(Map<String, dynamic> json) {
    final rawMobile = json['mobile']?.toString();
    final rawEmail = json['email']?.toString();
    return CareTaker(
      id: json['id'] as int?,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : null,
      mobile: (rawMobile != null && rawMobile.isNotEmpty) ? rawMobile : null,
      instruction: json['instruction']?.toString() ?? '',
      relationship: json['relationship']?.toString(),
      dob: json['dob']?.toString(),
      address: json['address']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, email, mobile, instruction, relationship, dob, address];
}

// ==================== FAMILY INITIAL ====================

class FamilyInitialRequest {
  final String willId;
  final String relationshipStatus;
  final bool hasPreviousRelationship;
  final bool canIncludeFormerPartner;
  final bool? hasDependents;
  final int? willTestatorRelationshipId;

  FamilyInitialRequest({
    required this.willId,
    required this.relationshipStatus,
    required this.hasPreviousRelationship,
    required this.canIncludeFormerPartner,
    this.hasDependents,
    this.willTestatorRelationshipId,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'relationship_status': relationshipStatus,
      'has_previous_relationship': hasPreviousRelationship,
      'can_include_former_partner': canIncludeFormerPartner,
      if (hasDependents != null) 'has_dependents': hasDependents,
      if (willTestatorRelationshipId != null) 'will_testator_relationship_id': willTestatorRelationshipId,
    };
  }
}

class FamilyInitialData extends Equatable {
  final String? willId;
  final int? willTestatorRelationshipId;
  final String? relationshipStatus;
  final bool? hasPreviousRelationship;
  final bool? canIncludeFormerPartner;
  final bool? hasDependents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyInitialData({
    this.willId,
    this.willTestatorRelationshipId,
    this.relationshipStatus,
    this.hasPreviousRelationship,
    this.canIncludeFormerPartner,
    this.hasDependents,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyInitialData.fromJson(Map<String, dynamic> json) {
    return FamilyInitialData(
      willId: json['will_id'] as String?,
      willTestatorRelationshipId: json['will_testator_relationship_id'] as int?,
      relationshipStatus: json['relationship_status'] as String?,
      hasPreviousRelationship: json['has_previous_relationship'] as bool?,
      canIncludeFormerPartner: json['can_include_former_partner'] as bool?,
      hasDependents: json['has_dependents'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  @override
  List<Object?> get props => [
        willId,
        willTestatorRelationshipId,
        relationshipStatus,
        hasPreviousRelationship,
        canIncludeFormerPartner,
        hasDependents,
        createdAt,
        updatedAt,
      ];
}

// ==================== PARTNER (CURRENT/DEFACTO/FORMER) ====================

// Partner types enum
class PartnerType {
  static const String current = 'CURRENT';
  static const String defacto = 'DEFACTO';
  static const String former = 'FORMER';
  
  static String getDisplayName(String type) {
    switch (type.toUpperCase()) {
      case 'CURRENT':
        return 'Current Partner';
      case 'DEFACTO':
        return 'De Facto Partner';
      case 'FORMER':
        return 'Former Partner';
      default:
        return type;
    }
  }
}

class PartnerRequest {
  final String willId;
  final PartnerDetails partner;

  PartnerRequest({
    required this.willId,
    required this.partner,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'partner': partner.toJson(),
    };
  }
}

class PartnerDetails extends Equatable {
  final int? id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String mobile;
  final String partnerType; // CURRENT, DEFACTO, FORMER
  final String? relationship; // HUSBAND, WIFE, EX_HUSBAND, EX_WIFE, OTHER
  final int? willPersonId;
  final String? dob;
  final String? address;

  const PartnerDetails({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.partnerType,
    this.relationship,
    this.willPersonId,
    this.dob,
    this.address,
  });

  // Convert DD/MM/YYYY to YYYY-MM-DD format for API
  String? _convertDobFormat(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dob; // Return as-is if not in expected format
  }

  Map<String, dynamic> toJson() {
    final convertedDob = _convertDobFormat(dob);
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'middle_name': middleName ?? '',
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'partner_type': partnerType,
      if (relationship != null && relationship!.isNotEmpty) 'relationship': relationship,
      if (willPersonId != null) 'will_person_id': willPersonId,
      if (convertedDob != null) 'dob': convertedDob,
      if (address != null) 'address': address,
    };
  }

  factory PartnerDetails.fromJson(Map<String, dynamic> json) {
    return PartnerDetails(
      id: json['id'] as int?,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      partnerType: json['partner_type']?.toString() ?? PartnerType.former,
      relationship: json['relationship']?.toString(),
      willPersonId: json['will_person_id'] as int?,
      dob: json['dob']?.toString(),
      address: json['address']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, email, mobile, partnerType, relationship, willPersonId, dob, address];
}

class PartnerData extends Equatable {
  final String id;
  final String willId;
  final PartnerDetails partner;
  final DateTime? createdAt;

  const PartnerData({
    required this.id,
    required this.willId,
    required this.partner,
    this.createdAt,
  });

  factory PartnerData.fromJson(Map<String, dynamic> json) {
    return PartnerData(
      id: json['id']?.toString() ?? '',
      willId: json['will_id']?.toString() ?? '',
      partner: PartnerDetails.fromJson(json),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, willId, partner, createdAt];
}

// Legacy alias for backward compatibility
typedef FormerPartnerRequest = PartnerRequest;
typedef FormerPartnerData = PartnerData;

// ==================== DEPENDENT (PERSON) ====================

class DependentPersonRequest {
  final String willId;
  final DependentDetails dependent;
  final PersonDetails? guardian;
  final PersonDetails? backupGuardian;

  DependentPersonRequest({
    required this.willId,
    required this.dependent,
    this.guardian,
    this.backupGuardian,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'dependent': dependent.toJson(),
      if (guardian != null) 'guardian': guardian!.toJson(),
      if (backupGuardian != null) 'backup_guardian': backupGuardian!.toJson(),
    };
  }
}

class DependentDetails extends Equatable {
  final int? id; // Pass for update, omit for new
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? mobile;
  final String? email;
  final String relationship;
  final bool isMinor;
  final int? willPersonId;
  final String? dob;
  final String? address;

  const DependentDetails({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.mobile,
    this.email,
    required this.relationship,
    required this.isMinor,
    this.willPersonId,
    this.dob,
    this.address,
  });

  // Convert DD/MM/YYYY to YYYY-MM-DD format for API
  String? _convertDobFormat(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dob; // Return as-is if not in expected format
  }

  Map<String, dynamic> toJson() {
    final convertedDob = _convertDobFormat(dob);
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'middle_name': middleName ?? '', // Always include, even if empty
      'last_name': lastName,
      'mobile': (mobile != null && mobile!.isNotEmpty) ? mobile : null,
      'email': (email != null && email!.isNotEmpty) ? email : null,
      'relationship': relationship,
      'is_minor': isMinor,
      if (willPersonId != null) 'will_person_id': willPersonId,
      if (convertedDob != null) 'dob': convertedDob,
      if (address != null) 'address': address,
    };
  }

  factory DependentDetails.fromJson(Map<String, dynamic> json) {
    final rawMobile = json['mobile']?.toString();
    final rawEmail = json['email']?.toString();
    return DependentDetails(
      id: json['id'] as int?,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      mobile: (rawMobile != null && rawMobile.isNotEmpty) ? rawMobile : null,
      email: (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : null,
      relationship: json['relationship']?.toString() ?? json['relation']?.toString() ?? '',
      isMinor: json['is_minor'] as bool? ?? false,
      willPersonId: json['will_person_id'] as int?,
      dob: json['dob']?.toString(),
      address: json['address']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, mobile, email, relationship, isMinor, willPersonId, dob, address];
}

class DependentPersonData extends Equatable {
  final String id;
  final String willId;
  final DependentDetails dependent;
  final PersonDetails? guardian;
  final String? guardianId;
  final PersonDetails? backupGuardian;
  final String? backupGuardianId;
  final DateTime? createdAt;

  const DependentPersonData({
    required this.id,
    required this.willId,
    required this.dependent,
    this.guardian,
    this.guardianId,
    this.backupGuardian,
    this.backupGuardianId,
    this.createdAt,
  });

  factory DependentPersonData.fromJson(Map<String, dynamic> json) {
    final guardianJson = json['guardian'] as Map<String, dynamic>?;
    final backupGuardianJson = json['backup_guardian'] as Map<String, dynamic>?;
    final dependentJson = json['dependent'] as Map<String, dynamic>?;
    // Get ID from dependent.id first, then fallback to root level
    final dependentId = dependentJson?['id']?.toString() ?? 
                        json['dependent_id']?.toString() ?? 
                        json['id']?.toString() ?? '';
    return DependentPersonData(
      id: dependentId,
      willId: json['will_id']?.toString() ?? '',
      dependent: DependentDetails.fromJson(json['dependent'] ?? json),
      guardian: guardianJson != null ? PersonDetails.fromJson(guardianJson) : null,
      guardianId: guardianJson?['id']?.toString() ?? json['guardian_id']?.toString(),
      backupGuardian: backupGuardianJson != null ? PersonDetails.fromJson(backupGuardianJson) : null,
      backupGuardianId: backupGuardianJson?['id']?.toString() ?? json['backup_guardian_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, willId, dependent, guardian, guardianId, backupGuardian, backupGuardianId, createdAt];
}

// ==================== PET ====================

class PetRequest {
  final int? willPetId; // Pass for update, omit for new
  final String willId;
  final String animalName;
  final String animalCategory;
  final CareTaker? caretaker; // Optional - only sent when user selects "Yes" for caretaker
  final bool removeCaretaker; // When true, explicitly removes the caretaker
  final String? breed;
  final String? registration;
  final String? vetName;
  final String? vetContact;
  final bool? addAllowance; // Enable allowance for pet maintenance
  final double? allowanceAmount; // Amount for pet maintenance

  PetRequest({
    this.willPetId,
    required this.willId,
    required this.animalName,
    required this.animalCategory,
    this.caretaker,
    this.removeCaretaker = false,
    this.breed,
    this.registration,
    this.vetName,
    this.vetContact,
    this.addAllowance,
    this.allowanceAmount,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (willPetId != null) 'will_pet_id': willPetId,
      'will_id': willId,
      'animal_name': animalName,
      'animal_category': animalCategory,
      if (breed != null) 'breed': breed,
      if (registration != null) 'registration': registration,
      if (vetName != null) 'vet_name': vetName,
      if (vetContact != null) 'vet_contact': vetContact,
      if (addAllowance != null) 'add_allowance': addAllowance,
      if (addAllowance == true && allowanceAmount != null) 'allowance_amount': allowanceAmount,
    };
    
    // Include caretaker if provided, or explicitly set to null to remove
    if (caretaker != null) {
      json['caretaker'] = caretaker!.toJson();
    } else if (removeCaretaker) {
      json['caretaker'] = null;
    }
    
    return json;
  }
}

class PetData extends Equatable {
  final String id;
  final String willId;
  final String animalName;
  final String animalCategory;
  final CareTaker? caretaker;
  final String? caretakerId;
  final String? breed;
  final String? registration;
  final String? vetName;
  final String? vetContact;
  final bool? addAllowance;
  final double? allowanceAmount;
  final DateTime? createdAt;

  const PetData({
    required this.id,
    required this.willId,
    required this.animalName,
    required this.animalCategory,
    this.caretaker,
    this.caretakerId,
    this.breed,
    this.registration,
    this.vetName,
    this.vetContact,
    this.addAllowance,
    this.allowanceAmount,
    this.createdAt,
  });

  factory PetData.fromJson(Map<String, dynamic> json) {
    final caretaker = json['caretaker'] != null ? CareTaker.fromJson(json['caretaker']) : null;
    return PetData(
      id: json['will_pet_id']?.toString() ?? json['id']?.toString() ?? '',
      willId: json['will_id']?.toString() ?? '',
      animalName: json['animal_name']?.toString() ?? '',
      animalCategory: json['animal_category']?.toString() ?? '',
      caretaker: caretaker,
      caretakerId: json['care_taker_id']?.toString() ?? 
                   json['caretaker_id']?.toString() ?? 
                   caretaker?.id.toString(),
      breed: json['breed']?.toString(),
      registration: json['registration']?.toString(),
      vetName: json['vet_name']?.toString(),
      vetContact: json['vet_contact']?.toString(),
      addAllowance: json['add_allowance'] is bool 
          ? json['add_allowance'] as bool 
          : (json['add_allowance']?.toString() == 'true'),
      allowanceAmount: json['allowance_amount'] != null 
          ? double.tryParse(json['allowance_amount'].toString())
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, willId, animalName, animalCategory, caretaker, caretakerId, breed, registration, vetName, vetContact, addAllowance, allowanceAmount, createdAt];
}

// ==================== BENEFICIARY (PERSON) ====================

class BeneficiaryDetails {
  final int? id; // Pass for update, omit for new
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String relationship;
  final bool isMinor;
  final String? dob;
  final String? address;
  final String? includeReason;
  final int? willPersonId;

  BeneficiaryDetails({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    required this.relationship,
    required this.isMinor,
    this.dob,
    this.address,
    this.includeReason,
    this.willPersonId,
  });

  // Convert DD/MM/YYYY to YYYY-MM-DD format for API
  String? _convertDobFormat(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dob; // Return as-is if not in expected format
  }

  Map<String, dynamic> toJson() {
    final convertedDob = _convertDobFormat(dob);
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'middle_name': middleName ?? '', // Always include, even if empty
      'last_name': lastName,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (mobile != null && mobile!.isNotEmpty) 'mobile': mobile,
      'relationship': relationship,
      'is_minor': isMinor,
      if (convertedDob != null) 'dob': convertedDob,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (includeReason != null && includeReason!.isNotEmpty) 'include_reason': includeReason,
      if (willPersonId != null) 'will_person_id': willPersonId,
    };
  }
}

class GuardianDetails {
  final int? id; // Pass for update, omit for new
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String? relationship;
  final String? dob;
  final String? address;
  final int? willPersonId;

  GuardianDetails({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    this.relationship,
    this.dob,
    this.address,
    this.willPersonId,
  });

  // Convert DD/MM/YYYY to YYYY-MM-DD format for API
  String? _convertDobFormat(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dob;
  }

  Map<String, dynamic> toJson() {
    final convertedDob = _convertDobFormat(dob);
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'middle_name': middleName ?? '', // Always include, even if empty
      'last_name': lastName,
      'email': (email != null && email!.isNotEmpty) ? email : null,
      'mobile': (mobile != null && mobile!.isNotEmpty) ? mobile : null,
      if (relationship != null && relationship!.isNotEmpty) 'relationship': relationship,
      if (convertedDob != null) 'dob': convertedDob,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (willPersonId != null) 'will_person_id': willPersonId,
    };
  }

  factory GuardianDetails.fromJson(Map<String, dynamic> json) {
    final rawMobile = json['mobile']?.toString();
    final rawEmail = json['email']?.toString();
    return GuardianDetails(
      id: json['id'] as int?,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : null,
      mobile: (rawMobile != null && rawMobile.isNotEmpty) ? rawMobile : null,
      relationship: json['relationship']?.toString(),
      dob: json['dob']?.toString(),
      address: json['address']?.toString(),
      willPersonId: json['will_person_id'] as int?,
    );
  }
}

class BeneficiaryPersonRequest {
  final String willId;
  final BeneficiaryDetails beneficiary;
  final GuardianDetails? guardian;
  final GuardianDetails? backupGuardian;

  BeneficiaryPersonRequest({
    required this.willId,
    required this.beneficiary,
    this.guardian,
    this.backupGuardian,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'beneficiary': beneficiary.toJson(),
      if (guardian != null) 'guardian': guardian!.toJson(),
      if (backupGuardian != null) 'backup_guardian': backupGuardian!.toJson(),
    };
  }
}

class BeneficiaryPersonData extends Equatable {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? dob;
  final String? relationship;
  final String? mobile;
  final String? email;
  final bool isMinor;
  final String? includeReason;
  final String? allocation;
  final bool enableAllocation;
  final int? willPersonId;
  final String? address;
  final BeneficiaryGuardianData? guardian;
  final BeneficiaryGuardianData? backupGuardian;

  const BeneficiaryPersonData({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.dob,
    this.relationship,
    this.mobile,
    this.email,
    required this.isMinor,
    this.includeReason,
    this.allocation,
    required this.enableAllocation,
    this.willPersonId,
    this.address,
    this.guardian,
    this.backupGuardian,
  });

  factory BeneficiaryPersonData.fromJson(Map<String, dynamic> json) {
    return BeneficiaryPersonData(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] as String? ?? '',
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String? ?? '',
      dob: json['dob'] as String?,
      relationship: json['relationship'] as String? ?? json['relation'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      isMinor: json['is_minor'] as bool? ?? false,
      includeReason: json['include_reason'] as String?,
      allocation: json['allocation']?.toString(),
      enableAllocation: json['enable_allocation'] as bool? ?? false,
      willPersonId: json['will_person_id'] as int?,
      address: json['address'] as String?,
      guardian: json['guardian'] != null 
          ? BeneficiaryGuardianData.fromJson(json['guardian'] as Map<String, dynamic>)
          : null,
      backupGuardian: json['backup_guardian'] != null
          ? BeneficiaryGuardianData.fromJson(json['backup_guardian'] as Map<String, dynamic>)
          : null,
    );
  }

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        middleName,
        lastName,
        dob,
        relationship,
        mobile,
        email,
        isMinor,
        includeReason,
        allocation,
        enableAllocation,
        willPersonId,
        address,
        guardian,
        backupGuardian,
      ];
}

// Guardian data from beneficiary response
class BeneficiaryGuardianData extends Equatable {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? mobile;
  final String? dob;
  final String? relationship;

  const BeneficiaryGuardianData({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.mobile,
    this.dob,
    this.relationship,
  });

  factory BeneficiaryGuardianData.fromJson(Map<String, dynamic> json) {
    return BeneficiaryGuardianData(
      id: json['id']?.toString() ?? json['guardian_id']?.toString() ?? '',
      firstName: json['first_name'] as String? ?? '',
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      dob: json['dob'] as String?,
      relationship: json['relationship'] as String?,
    );
  }

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, email, mobile, dob, relationship];
}

// ==================== CHARITY ====================

class CharityRequest {
  final String name;
  final String address;
  final String? abn;

  CharityRequest({
    required this.name,
    required this.address,
    this.abn,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      if (abn != null && abn!.isNotEmpty) 'abn': abn,
    };
  }
}

class CharityData extends Equatable {
  final String id;
  final String name;
  final String? logo;
  final String address;
  final String? abn;

  const CharityData({
    required this.id,
    required this.name,
    this.logo,
    required this.address,
    this.abn,
  });

  factory CharityData.fromJson(Map<String, dynamic> json) {
    return CharityData(
      id: (json['charity_id'] ?? json['id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      address: json['address']?.toString() ?? '',
      abn: json['abn']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, logo, address, abn];
}

// ==================== BENEFICIARY CHARITY ====================

class BeneficiaryCharityRequest {
  final String willId;
  final List<String> charityIds;

  BeneficiaryCharityRequest({
    required this.willId,
    required this.charityIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      // API expects integers, convert strings to int
      'charity_ids': charityIds.map((id) => int.tryParse(id) ?? 0).toList(),
    };
  }
}

class BeneficiaryCharityData extends Equatable {
  final String id;
  final String willId;
  final CharityData charity;
  final String? allocation;
  final bool enableAllocation;
  final DateTime? createdAt;

  const BeneficiaryCharityData({
    required this.id,
    required this.willId,
    required this.charity,
    this.allocation,
    required this.enableAllocation,
    this.createdAt,
  });

  factory BeneficiaryCharityData.fromJson(Map<String, dynamic> json) {
    return BeneficiaryCharityData(
      id: json['will_beneficiary_charity_id']?.toString() ?? json['beneficiary_charity_id']?.toString() ?? json['id']?.toString() ?? '',
      willId: json['will_id']?.toString() ?? '',
      charity: CharityData.fromJson(json),
      allocation: json['allocation']?.toString(),
      enableAllocation: json['enable_allocation'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, willId, charity, allocation, enableAllocation, createdAt];
}

// ==================== WITNESS MODEL ====================

class WitnessRequest {
  final String willId;
  final WitnessData witness;

  WitnessRequest({
    required this.willId,
    required this.witness,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'witness': witness.toJson(),
    };
  }
}

class WitnessData extends Equatable {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? mobile;
  final String? notes;
  final String? relationship;
  final String? address;

  const WitnessData({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.mobile,
    this.notes,
    this.relationship,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id),
      'first_name': firstName,
      'middle_name': middleName ?? '',
      'last_name': lastName,
      'email': email,
      if (mobile != null && mobile!.isNotEmpty) 'mobile': mobile,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (address != null && address!.isNotEmpty) 'address': address,
    };
  }

  factory WitnessData.fromJson(Map<String, dynamic> json) {
    return WitnessData(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      notes: json['notes']?.toString() ?? json['note']?.toString(),
      relationship: json['relationship']?.toString() ?? json['relation']?.toString(),
      address: json['address']?.toString(),
    );
  }

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }
  
  // For compatibility with existing code
  String? get note => notes;
  String? get relation => relationship;

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, email, mobile, notes, relationship, address];
}

// ==================== EXECUTOR MODEL ====================

class ExecutorRequest {
  final String willId;
  final ExecutorDetails? executorDetails;
  final int? beneficiaryId;
  final bool isPrimary;

  ExecutorRequest({
    required this.willId,
    this.executorDetails,
    this.beneficiaryId,
    this.isPrimary = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      if (executorDetails != null) 'executor_details': executorDetails!.toJson(),
      if (beneficiaryId != null) 'beneficiary_id': beneficiaryId,
      'is_primary': isPrimary,
    };
  }
}

class ExecutorDetails extends Equatable {
  final int? id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String mobile;
  final String? relationship;
  final String? address;
  final String? dob;
  final int? willPersonId;

  const ExecutorDetails({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.mobile,
    this.relationship,
    this.address,
    this.dob,
    this.willPersonId,
  });

  // Convert DD/MM/YYYY to YYYY-MM-DD format for API
  String? _convertDobFormat(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dob;
  }

  Map<String, dynamic> toJson() {
    final convertedDob = _convertDobFormat(dob);
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'middle_name': middleName ?? '',
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      if (relationship != null && relationship!.isNotEmpty) 'relationship': relationship,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (convertedDob != null) 'dob': convertedDob,
      if (willPersonId != null) 'will_person_id': willPersonId,
    };
  }

  factory ExecutorDetails.fromJson(Map<String, dynamic> json) {
    // Handle both int and String IDs (personal executors use int, professional use UUID string)
    int? parsedId;
    if (json['id'] != null) {
      if (json['id'] is int) {
        parsedId = json['id'] as int;
      } else if (json['id'] is String) {
        // For professional executors with UUID strings, we can't convert to int
        // Just ignore the id field for now as it's not critical
        parsedId = null;
      }
    }
    
    return ExecutorDetails(
      id: parsedId,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? json['relation']?.toString(),
      address: json['address']?.toString(),
      dob: json['dob']?.toString(),
      willPersonId: json['will_person_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, email, mobile, relationship, address, dob, willPersonId];
}

class ExecutorData extends Equatable {
  final String id;
  final String willId;
  final ExecutorDetails executor;
  final DateTime? createdAt;
  final bool isPrimary;
  final bool isProfessional;
  final String? lawFirmId;
  final String? lawFirmName;

  const ExecutorData({
    required this.id,
    required this.willId,
    required this.executor,
    this.createdAt,
    this.isPrimary = true,
    this.isProfessional = false,
    this.lawFirmId,
    this.lawFirmName,
  });

  factory ExecutorData.fromJson(Map<String, dynamic> json) {
    final lawFirmId = json['law_firm_id']?.toString();
    final isProfessional = lawFirmId != null && lawFirmId.isNotEmpty;
    
    return ExecutorData(
      id: json['id']?.toString() ?? '',
      willId: json['will_id']?.toString() ?? '',
      executor: ExecutorDetails.fromJson(json),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      isPrimary: json['is_primary'] as bool? ?? true,
      isProfessional: isProfessional,
      lawFirmId: lawFirmId,
      lawFirmName: json['law_firm_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, willId, executor, createdAt, isPrimary, isProfessional, lawFirmId, lawFirmName];
}

// ==================== EXECUTION RULE MODEL ====================

class ExecutionRuleRequest {
  final String willId;
  final ExecutionRuleData rules;

  ExecutionRuleRequest({
    required this.willId,
    required this.rules,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'rules': rules.toJson(),
    };
  }
}

class ExecutionRuleData extends Equatable {
  final String ruleName; // AFTER_PASSING, SPECIFIC_DATE, IMMEDIATELY
  final DateTime? ruleValue;
  final bool grantAccess;

  const ExecutionRuleData({
    required this.ruleName,
    this.ruleValue,
    this.grantAccess = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'rule_name': ruleName,
      if (ruleValue != null) 'rule_value': ruleValue!.toIso8601String(),
      'grant_access': grantAccess,
    };
  }

  factory ExecutionRuleData.fromJson(Map<String, dynamic> json) {
    return ExecutionRuleData(
      ruleName: json['rule_name']?.toString() ?? 'AFTER_PASSING',
      ruleValue: json['rule_value'] != null ? DateTime.parse(json['rule_value']) : null,
      grantAccess: json['grant_access'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [ruleName, ruleValue, grantAccess];
}

// ==================== WILL PERSON (from /will/persons) ====================

class WillPersonData extends Equatable {
  final int willPersonId;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? dob;
  final String? email;
  final String? mobile;
  final bool? isMinor;
  final String? address;
  final String? relationship;

  const WillPersonData({
    required this.willPersonId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.dob,
    this.email,
    this.mobile,
    this.isMinor,
    this.address,
    this.relationship,
  });

  factory WillPersonData.fromJson(Map<String, dynamic> json) {
    return WillPersonData(
      willPersonId: json['will_person_id'] as int,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      dob: json['dob'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      isMinor: json['is_minor'] as bool?,
      address: json['address'] as String?,
      relationship: json['relationship'] as String?,
    );
  }

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [willPersonId, firstName, middleName, lastName, dob, email, mobile, isMinor, address, relationship];
}

// ==================== WILL USER (FOR NOTIFICATION RECIPIENTS) ====================

class WillUserData extends Equatable {
  final int id;
  final int willPersonId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? dob;
  final String role;
  final Map<String, dynamic>? extra;

  const WillUserData({
    required this.id,
    required this.willPersonId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.phone,
    this.dob,
    required this.role,
    this.extra,
  });

  factory WillUserData.fromJson(Map<String, dynamic> json) {
    return WillUserData(
      id: json['id'] as int,
      willPersonId: json['will_person_id'] as int,
      firstName: json['first_name'] as String? ?? '',
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dob: json['dob'] as String?,
      role: json['role'] as String? ?? '',
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [id, willPersonId, firstName, middleName, lastName, email, phone, dob, role, extra];
}
