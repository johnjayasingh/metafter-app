import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';
import 'family_models.dart';

// ==================== GIFT ====================

/// Matches the WillGiftCreate schema from the API spec.
/// The API requires will_id and gift_receiver as mandatory fields.
/// For the simple "leave a gift?" yes/no flow, use the local-only
/// flag on the screen — actual gift creation should include
/// a gift_receiver.
class GiftRequest {
  final String willId;
  final int? giftId;
  final GiftType? giftType;
  final int? assetId;
  final String? description;
  final String? currency;
  final String? amount;
  final List<GiftReceiverDetails> giftReceivers;

  GiftRequest({
    required this.willId,
    this.giftId,
    this.giftType,
    this.assetId,
    this.description,
    this.currency,
    this.amount,
    this.giftReceivers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      if (giftId != null) 'gift_id': giftId,
      if (giftType != null) 'gift_type': giftType!.value,
      if (assetId != null) 'asset_id': assetId,
      if (description != null) 'description': description,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (giftReceivers.isNotEmpty)
        'gift_receiver': giftReceivers.map((r) => r.toJson()).toList(),
    };
  }
}

class GiftData extends Equatable {
  final String id;
  final String willId;
  final GiftType? giftType;
  final int? assetId;
  final String? description;
  final String? currency;
  final String? amount;
  final List<GiftReceiverDetails> giftReceivers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GiftData({
    required this.id,
    required this.willId,
    this.giftType,
    this.assetId,
    this.description,
    this.currency,
    this.amount,
    this.giftReceivers = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Convenience getter — first receiver or null (for backward compat)
  GiftReceiverDetails? get giftReceiver =>
      giftReceivers.isNotEmpty ? giftReceivers.first : null;

  factory GiftData.fromJson(Map<String, dynamic> json) {
    List<GiftReceiverDetails> receivers = [];
    final raw = json['gift_receiver'];
    if (raw is List) {
      receivers = raw
          .map((item) => GiftReceiverDetails.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (raw is Map<String, dynamic>) {
      receivers = [GiftReceiverDetails.fromJson(raw)];
    }
    return GiftData(
      id: json['gift_id']?.toString() ?? json['id']?.toString() ?? '',
      willId: json['will_id']?.toString() ?? '',
      giftType: GiftType.fromString(json['gift_type']?.toString()),
      assetId: json['asset_id'] as int?,
      description: json['description']?.toString(),
      currency: json['currency']?.toString(),
      amount: json['amount']?.toString(),
      giftReceivers: receivers,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, willId, giftType, assetId, description, currency, amount, giftReceivers, createdAt, updatedAt];
}

// ==================== GIFT BENEFICIARY ====================

class GiftBeneficiaryRequest {
  final String willId;
  final GiftReceiverDetails giftReceiver;

  GiftBeneficiaryRequest({
    required this.willId,
    required this.giftReceiver,
  });

  Map<String, dynamic> toJson() {
    return {
      'will_id': willId,
      'gift_receiver': [giftReceiver.toJson()],
    };
  }
}

class GiftReceiverDetails extends Equatable {
  final int? id; // Optional id for updates
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? mobile;
  final String? email;
  final String? address;
  final String relationship;
  final bool isMinor;
  final String? dob;
  final int? willPersonId;
  final GuardianDetails? guardian;
  final GuardianDetails? backupGuardian;

  const GiftReceiverDetails({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.mobile,
    this.email,
    this.address,
    required this.relationship,
    required this.isMinor,
    this.dob,
    this.willPersonId,
    this.guardian,
    this.backupGuardian,
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
      'mobile': (mobile != null && mobile!.isNotEmpty) ? mobile : null,
      'email': (email != null && email!.isNotEmpty) ? email : null,
      if (address != null) 'address': address,
      'relationship': relationship,
      'is_minor': isMinor,
      if (convertedDob != null) 'dob': convertedDob,
      if (willPersonId != null) 'will_person_id': willPersonId,
      if (guardian != null) 'guardian': guardian!.toJson() else 'guardian': null,
      if (backupGuardian != null) 'backup_guardian': backupGuardian!.toJson() else 'backup_guardian': null,
    };
  }

  factory GiftReceiverDetails.fromJson(Map<String, dynamic> json) {
    final rawMobile = json['mobile']?.toString();
    final rawEmail = json['email']?.toString();
    return GiftReceiverDetails(
      id: json['id'] as int?,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      mobile: (rawMobile != null && rawMobile.isNotEmpty) ? rawMobile : null,
      email: (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : null,
      address: json['address']?.toString(),
      relationship: json['relationship']?.toString() ?? json['relation']?.toString() ?? 'OTHER',
      isMinor: json['is_minor'] as bool? ?? false,
      dob: json['dob']?.toString(),
      willPersonId: json['will_person_id'] as int?,
      guardian: json['guardian'] != null 
          ? GuardianDetails.fromJson(json['guardian'] as Map<String, dynamic>)
          : null,
      backupGuardian: json['backup_guardian'] != null 
          ? GuardianDetails.fromJson(json['backup_guardian'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, firstName, middleName, lastName, mobile, email, address, relationship, isMinor, dob, willPersonId, guardian, backupGuardian];
}

class GiftBeneficiaryData extends Equatable {
  final String id;
  final String willId;
  final GiftReceiverDetails giftReceiver;
  final DateTime? createdAt;

  const GiftBeneficiaryData({
    required this.id,
    required this.willId,
    required this.giftReceiver,
    this.createdAt,
  });

  factory GiftBeneficiaryData.fromJson(Map<String, dynamic> json) {
    // API returns flat structure with gift receiver fields at root level
    // Check if gift_receiver is nested or fields are at root
    final raw = json['gift_receiver'];
    final giftReceiverData = raw is List
        ? (raw.isNotEmpty ? raw.first as Map<String, dynamic> : json)
        : (raw is Map<String, dynamic> ? raw : json);
    
    return GiftBeneficiaryData(
      id: json['gift_beneficiary_id']?.toString() ?? json['id']?.toString() ?? '',
      willId: json['will_id']?.toString() ?? '',
      giftReceiver: GiftReceiverDetails.fromJson(giftReceiverData),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, willId, giftReceiver, createdAt];
}
