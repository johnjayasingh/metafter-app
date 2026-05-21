/// Power of Attorney — data models
///
/// [AttorneyType] maps to the backend's AttorneyType enum.
/// [PoaPersonData] holds a single attorney / successive attorney / notify person.
/// [PoaFlowData] accumulates all wizard state and is passed through route extras.
/// [PoaData] is the API response model from GET /user/power-of-attorney.
/// [PoaResponse] is the generic API response wrapper.

import 'package:equatable/equatable.dart';

// ── Attorney type enum ───────────────────────────────────────────────────────

enum AttorneyType {
  PRIMARY,
  SUCCESSIVE,
  MEDICAL_DECISION_MAKER,
  PERSONAL_ASSISTANCE,
  ENDURING_GUARDIAN,
  SUBSTITUTE_ENDURING_GUARDIAN,
  SECOND_DONOR,
  ATTORNEY_DONEE,
  APPOINTED_ATTORNEY,
  SUBSTITUTE,
  FINANCIAL_DECISION_MAKER_PRIMARY,
  FINANCIAL_DECISION_MAKER_SECONDARY,
  FINANCIAL_DECISION_MAKER_TERTIARY,
  FINANCIAL_DECISION_MAKER_QUATERNARY,
  ADDITIONAL_AUTHORITY,
  ATTORNEY_DONOR;

  String get apiValue => name;

  static AttorneyType fromApi(String value) {
    return AttorneyType.values.firstWhere(
      (e) => e.name == value.toUpperCase().trim(),
      orElse: () => AttorneyType.PRIMARY,
    );
  }

  String get displayLabel {
    switch (this) {
      case AttorneyType.PRIMARY:
        return 'Attorney';
      case AttorneyType.SUCCESSIVE:
        return 'Successive Attorney';
      case AttorneyType.MEDICAL_DECISION_MAKER:
        return 'Medical Decision Maker';
      case AttorneyType.PERSONAL_ASSISTANCE:
        return 'Personal Assistance';
      case AttorneyType.ENDURING_GUARDIAN:
        return 'Enduring Guardian';
      case AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN:
        return 'Substitute Enduring Guardian';
      case AttorneyType.SECOND_DONOR:
        return 'Second Donor';
      case AttorneyType.ATTORNEY_DONEE:
        return 'Donee';
      case AttorneyType.APPOINTED_ATTORNEY:
        return 'Appointed Attorney';
      case AttorneyType.SUBSTITUTE:
        return 'Substitute Attorney';
      case AttorneyType.FINANCIAL_DECISION_MAKER_PRIMARY:
        return 'Financial Decision Maker (Primary)';
      case AttorneyType.FINANCIAL_DECISION_MAKER_SECONDARY:
        return 'Financial Decision Maker (Secondary)';
      case AttorneyType.FINANCIAL_DECISION_MAKER_TERTIARY:
        return 'Financial Decision Maker (Tertiary)';
      case AttorneyType.FINANCIAL_DECISION_MAKER_QUATERNARY:
        return 'Financial Decision Maker (Quaternary)';
      case AttorneyType.ADDITIONAL_AUTHORITY:
        return 'Benefits Person';
      case AttorneyType.ATTORNEY_DONOR:
        return 'Donor';
    }
  }
}

// ── Person data model ────────────────────────────────────────────────────────

class PoaPersonData {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String role; // e.g. 'Attorney', 'Successive Attorney'
  final String? email;
  final String? phone;
  final String? relation;
  final String? address;
  final String? dob;
  final String? attorneyId; // UUID from backend
  final int? attorneyPoaId; // Relationship ID from backend (used for DELETE)
  final AttorneyType? attorneyType;
  final bool isCorporation;
  final String? corporationType;
  final bool isBankrupt;

  const PoaPersonData({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.role = 'Attorney',
    this.email,
    this.phone,
    this.relation,
    this.address,
    this.dob,
    this.attorneyId,
    this.attorneyPoaId,
    this.attorneyType,
    this.isCorporation = false,
    this.corporationType,
    this.isBankrupt = false,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  /// Parse a full_name string into (firstName, middleName, lastName).
  static (String, String?, String) parseFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      return (
        parts.first,
        parts.sublist(1, parts.length - 1).join(' '),
        parts.last,
      );
    } else if (parts.length == 2) {
      return (parts.first, null, parts.last);
    } else {
      return (parts.first, null, '');
    }
  }

  /// Create from the backend GET /user/attorneys-for-poa response item.
  /// The API returns: { attorney_poa_id, type, attorney: { id, full_name, email, phone, address } }
  factory PoaPersonData.fromApiJson(Map<String, dynamic> json) {
    // Attorney data may be nested inside 'attorney' key or flat
    final attorney = json['attorney'] as Map<String, dynamic>? ?? json;

    final rawName = (attorney['full_name'] as String?) ?? '';
    final (first, middle, last) = parseFullName(rawName);

    // type is at top level, attorney_type may also appear
    final typeStr = (json['type'] as String?) ??
        (json['attorney_type'] as String?) ??
        (attorney['attorney_type'] as String?);
    final type = typeStr != null ? AttorneyType.fromApi(typeStr) : null;

    // Parse corporate/bankrupt fields from nested 'others' object
    final others = attorney['others'] as Map<String, dynamic>? ?? {};
    final isCorporation = others['is_attorney_corporate'] as bool? ?? false;
    final isBankrupt = others['is_attorney_declared_bankrupt'] as bool? ?? false;
    final corporationType = others['corporation_type'] as String?;

    return PoaPersonData(
      id: attorney['id']?.toString() ?? json['attorney_id']?.toString() ?? '',
      attorneyId: attorney['id']?.toString() ?? json['attorney_id']?.toString(),
      attorneyPoaId: json['attorney_poa_id'] is int
          ? json['attorney_poa_id'] as int
          : int.tryParse(json['attorney_poa_id']?.toString() ?? ''),
      firstName: first,
      middleName: middle,
      lastName: last,
      email: attorney['email'] as String?,
      phone: attorney['phone'] as String?,
      address: attorney['address'] as String?,
      dob: attorney['dob'] as String?,
      isCorporation: isCorporation,
      isBankrupt: isBankrupt,
      corporationType: corporationType,
      attorneyType: type,
      role: type?.displayLabel ?? 'Attorney',
    );
  }

  /// Convert to the API POST/PUT body for /user/attorney-for-poa.
  Map<String, dynamic> toApiJson({AttorneyType? typeOverride}) {
    final type = typeOverride ?? attorneyType ?? AttorneyType.PRIMARY;
    final json = <String, dynamic>{
      if (attorneyId != null) 'attorney_id': attorneyId,
      'full_name': fullName,
      'address': address,
      'email': email,
      'phone': phone,
      if (dob != null) 'dob': dob,
      'attorney_type': type.apiValue,
    };
    if (isCorporation || isBankrupt) {
      json['others'] = {
        'is_attorney_corporate': isCorporation,
        if (isCorporation && corporationType != null)
          'corporation_type': corporationType,
        'is_attorney_declared_bankrupt': isBankrupt,
      };
    }
    return json;
  }
}

// ── WA simple person entry ────────────────────────────────────────────────────

/// Lightweight name/address/email triplet for WA attorney & substitute forms.
class WaPersonEntry {
  final String name;
  final String address;
  final String email;

  const WaPersonEntry({
    this.name = '',
    this.address = '',
    this.email = '',
  });

  WaPersonEntry copyWith({String? name, String? address, String? email}) {
    return WaPersonEntry(
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }
}

// ── NT simple decision-maker entry ────────────────────────────────────────────

/// Lightweight name/address pair for NT financial decision-maker forms.
class NtDecisionMakerEntry {
  final String name;
  final String address;

  const NtDecisionMakerEntry({
    this.name = '',
    this.address = '',
  });

  NtDecisionMakerEntry copyWith({String? name, String? address}) {
    return NtDecisionMakerEntry(
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }
}

// ── ACT attorney entry ───────────────────────────────────────────────────────

/// Lightweight entry for ACT attorney inline forms.
class ActAttorneyEntry {
  final String firstName;
  final String lastName;
  final String address;
  final String? email;
  final String? phone;
  final String? dob;
  final bool isCorporation;
  final String? corporationType; // 'PUBLIC_TRUSTEE', 'TRUSTEE_COMPANY', 'OTHERS'
  final bool isBankrupt;

  const ActAttorneyEntry({
    this.firstName = '',
    this.lastName = '',
    this.address = '',
    this.email,
    this.phone,
    this.dob,
    this.isCorporation = false,
    this.corporationType,
    this.isBankrupt = false,
  });

  String get fullName {
    final parts = [firstName, lastName].where((s) => s.isNotEmpty);
    return parts.join(' ');
  }

  ActAttorneyEntry copyWith({
    String? firstName,
    String? lastName,
    String? address,
    String? email,
    String? phone,
    String? dob,
    bool? isCorporation,
    String? corporationType,
    bool? isBankrupt,
  }) {
    return ActAttorneyEntry(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      isCorporation: isCorporation ?? this.isCorporation,
      corporationType: corporationType ?? this.corporationType,
      isBankrupt: isBankrupt ?? this.isBankrupt,
    );
  }
}

// ── TAS attorney entry ───────────────────────────────────────────────────────

/// Lightweight name/address/email triplet for TAS attorney inline forms.
class TasAttorneyEntry {
  final String name;
  final String address;
  final String email;

  const TasAttorneyEntry({
    this.name = '',
    this.address = '',
    this.email = '',
  });

  TasAttorneyEntry copyWith({String? name, String? address, String? email}) {
    return TasAttorneyEntry(
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }
}

// ── Wizard flow data ─────────────────────────────────────────────────────────

class PoaFlowData {
  // ── Basic details (step 1) ─────────────────────────────────────────────────
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? phone;
  final String? dob;
  final String? addressLine1;
  final String? suburb;
  final String? postcode;
  final String? state;
  final String? country;

  /// Selected matter types: 'PERSONAL_HEALTH', 'FINANCIAL', or both.
  /// Victoria also supports 'SPECIFIC' (with specificMatters text).
  final List<String> matters;

  /// Free-text description when Victoria 'Specific matters' is selected.
  final String? specificMatters;

  /// Primary attorneys
  final List<PoaPersonData> attorneys;

  /// Successive / backup attorneys (optional)
  final List<PoaPersonData> successiveAttorneys;

  /// Enduring guardians
  final List<PoaPersonData> enduringGuardians;

  /// Substitute enduring guardians
  final List<PoaPersonData> substituteEnduringGuardians;

  /// When a FINANCIAL matter is selected: commencement type
  /// Values: 'INCAPACITY', 'IMMEDIATELY', 'OTHER'
  final String? commencementType;
  final String? commencementOther;

  /// Views, wishes & preferences (optional)
  final bool? hasViewsWishes;
  final String? viewsWishes;

  // ── Expanded views/wishes fields (step 8) ─────────────────────────────────
  /// For API: has_preference (boolean) and preferences (string)
  final String? hasPreference; // 'yes' or 'no'
  final String? preferences;

  /// For API: has_attorney_instruction (boolean) and attorney_instruction (string)
  final String? hasAttorneyInstruction; // 'yes' or 'no'
  final String? directions;

  /// Terms & instructions
  final bool? hasTermsInstructions;
  final String? termsInstructions;

  /// Conditions and limitations (optional)
  final bool? hasConditionsLimitations;
  final String? conditionsLimitations;

  /// Notification for health matters
  /// Values: 'ME', 'NOMINATED_PERSON'
  final String? notifyWho;
  final String? notifyInstructions;
  final List<PoaPersonData> notifyPersons;

  /// What to notify — option key
  final String? notifyWhatOption;
  /// Free text when notifyWhatOption is 'OTHER'
  final String? notifyWhatOtherText;

  /// Notification for financial matters
  final String? financialNotifyWho;
  final String? financialNotifyInstructions;
  final List<PoaPersonData> financialNotifyPersons;
  final String? financialNotifyWhatOption;
  final String? financialNotifyWhatOtherText;

  /// Assistance with signing
  final bool? needsSigningAssistance;

  /// Personal assistance person (for signing assistance step)
  final PoaPersonData? personalAssistancePerson;

  /// Additional powers granted to attorneys (single-select).
  /// Values: 'REASONABLE_GIFTS', 'BENEFITS_TO_ATTORNEY', 'BENEFITS_TO_SELECTED_PERSON'
  final String? selectedAdditionalPower;
  final List<PoaPersonData> benefitsPersons;

  /// Enduring Guardian — Functions and Limits
  final bool? egCanDecideLivingPlace;
  final bool? egCanDecideHealthcare;
  final String? egHealthcareDetail;
  final bool? egCanDecideOtherPersonalService;
  final String? egOtherPersonalService;
  final bool? egCanConsentMedicalAndDental;
  final String? egMedicalDetail;
  final String? egOtherDetail;

  /// Enduring Guardian — Directions
  final bool? egHasDirections;
  final String? egDirectionsDetail;

  /// SA donee (attorney) simple form fields
  final String? doneeName;
  final String? doneeAddress;
  final String? doneeEmail;

  /// How donees (attorneys) should act: 'JOINTLY' or 'JOINTLY_AND_SEVERALLY'
  final String? doneeActingMethod;

  /// SA-specific donor fields
  final String? saDonorFullName;
  final String? saDonorAddress;
  final String? saDonorEmail;
  final bool? saHasSecondDonor;
  final String? saSecondDonorFullName;
  final String? saSecondDonorAddress;
  final String? saSecondDonorEmail;
  final String? saCommencementType;

  /// WA-specific fields
  /// EPA completion date
  final String? waEpaDate;
  /// Document-level full legal name (may differ from step 1)
  final String? waFullLegalName;
  /// Document-level residential address
  final String? waResidentialAddress;
  /// Document-level email for signatures/copies
  final String? waEmail;
  /// Attorney appointment type: 'SOLE', 'JOINT', 'JOINT_AND_SEVERAL'
  final String? waAttorneyAppointmentType;
  /// Attorneys list
  final List<WaPersonEntry> waAttorneys;
  /// Whether to appoint a substitute attorney
  final bool? waHasSubstitute;
  /// Substitute appointment type: 'SOLE', 'JOINT', 'JOINT_AND_SEVERAL'
  final String? waSubstituteAppointmentType;
  /// Substitute attorneys list
  final List<WaPersonEntry> waSubstitutes;
  /// Who will the substitute act in substitution of
  final String? waSubstituteActsFor;
  /// When the substitute should act (free text)
  final String? waSubstituteWhenToAct;
  /// Conditions or restrictions
  final bool? waHasConditions;
  final String? waConditions;

  /// NT-specific fields
  /// Eligibility: is over 18
  final bool? ntIsOver18;
  /// Eligibility: understands EPA nature and effect
  final bool? ntUnderstandsEpa;
  /// Donor details
  final String? ntDonorFullName;
  final String? ntDonorAddress;
  final String? ntDonorDob;
  /// Number of financial decision-makers (1-4)
  final int? ntFinancialDmCount;
  /// Financial decision-makers list
  final List<NtDecisionMakerEntry> ntFinancialDms;
  /// How decision-makers act: 'SEVERALLY' or 'JOINTLY'
  final String? ntFinancialDmActingMethod;
  /// Limits or instructions for financial decision-makers
  final String? ntFinancialLimits;
  /// Land dealings
  final bool? ntOwnsLand;
  final bool? ntDmCanDealLand;

  /// ACT-specific fields
  /// Eligibility: is over 18
  final bool? actIsOver18;
  /// Eligibility: understands EPA nature and effect
  final bool? actUnderstandsEpa;
  /// Principal details
  final String? actPrincipalFullName;
  final String? actPrincipalAddress;
  final String? actPrincipalEmail;
  /// Number of attorneys (1-3)
  final int? actAttorneyCount;
  /// Attorneys list
  final List<ActAttorneyEntry> actAttorneys;
  /// How attorneys act: 'JOINTLY' or 'JOINTLY_SEVERALLY'
  final String? actHowAttorneysAct;
  /// Delegation type: 'NO_DELEGATION', 'ALL_POWERS', 'SOME_POWERS'
  final String? actDelegationType;
  /// Free text when actDelegationType is 'SOME_POWERS'
  final String? actDelegationDescription;
  /// Multi-select matters: 'PROPERTY', 'PERSONAL_CARE', 'HEALTH_CARE', 'MEDICAL_RESEARCH'
  final List<String> actMatters;
  /// Step 4: Directions per matter
  final String? actDirectionsProperty;
  final String? actDirectionsPersonalCare;
  final String? actDirectionsHealthCare;
  final String? actDirectionsMedicalResearch;
  /// Step 4: Medical treatment refusal: 'NOT_ALLOWED', 'ALLOWED_GENERALLY', 'ALLOWED_SPECIFIC'
  final String? actMedicalTreatmentRefusal;
  final String? actSpecificTreatments;
  /// Step 4: Property commencement: 'IMMEDIATELY', 'FROM_DATE_EVENT', 'IMPAIRED_CAPACITY'
  final String? actPropertyCommencement;
  final String? actCommencementCircumstance;
  /// Step 4: Prior EPA: 'NONE', 'REVOKE_ALL_PREVIOUS', 'SOME_CONTINUE'
  final String? actPriorEpa;
  final String? actPriorEpaContinueWhich;
  final String? actPriorEpaDate;
  final String? actPriorEpaAttorneyName;
  /// Step 5: Signing
  final bool? actSigningSelf;
  final String? actDirectedSignerName;
  final String? actDirectedSignerAddress;

  /// TAS-specific fields
  final bool? tasIsAdult;
  final bool? tasUnderstandsEpa;
  final String? tasDonorFullName;
  final String? tasDonorAddress;
  final String? tasDonorEmail;
  final String? tasCompletionDate;
  final int? tasAttorneyCount;
  final List<TasAttorneyEntry> tasAttorneys;
  final String? tasHowAttorneysAct;

  /// Victoria-specific: commencement condition/instruction fields
  final String? ciConflictTransactions;
  final String? ciGifts;
  final String? ciDependentMaintenance;
  final String? ciPaymentToAttorney;
  final String? ciAdditionalCondition;

  /// Victoria-specific: medical treatment decision maker
  final bool? hasMedicalDecisionMaker;
  final String? medicalDecisionMakerDetails;

  /// Victoria-specific: revocation
  final bool? hasRevocation;
  final String? revocationDetails;

  /// Victoria-specific: limitations
  final bool? hasLimitations;
  final String? limitationsDetails;

  /// Internal: user's email and contact preferences, sourced from GET /user/me.
  /// Not shown in any POA form — used only to sync the profile on step 1 submit.
  final String? userEmail;
  final List<String>? userContactPreference;

  const PoaFlowData({
    this.firstName,
    this.middleName,
    this.lastName,
    this.phone,
    this.dob,
    this.addressLine1,
    this.suburb,
    this.postcode,
    this.state,
    this.country,
    this.matters = const [],
    this.specificMatters,
    this.attorneys = const [],
    this.successiveAttorneys = const [],
    this.enduringGuardians = const [],
    this.substituteEnduringGuardians = const [],
    this.commencementType,
    this.commencementOther,
    this.hasViewsWishes,
    this.viewsWishes,
    this.hasPreference,
    this.preferences,
    this.hasAttorneyInstruction,
    this.directions,
    this.hasTermsInstructions,
    this.termsInstructions,
    this.hasConditionsLimitations,
    this.conditionsLimitations,
    this.notifyWho,
    this.notifyInstructions,
    this.notifyPersons = const [],
    this.notifyWhatOption,
    this.notifyWhatOtherText,
    this.financialNotifyWho,
    this.financialNotifyInstructions,
    this.financialNotifyPersons = const [],
    this.financialNotifyWhatOption,
    this.financialNotifyWhatOtherText,
    this.needsSigningAssistance,
    this.personalAssistancePerson,
    this.selectedAdditionalPower,
    this.benefitsPersons = const [],
    this.egCanDecideLivingPlace,
    this.egCanDecideHealthcare,
    this.egHealthcareDetail,
    this.egCanDecideOtherPersonalService,
    this.egOtherPersonalService,
    this.egCanConsentMedicalAndDental,
    this.egMedicalDetail,
    this.egOtherDetail,
    this.egHasDirections,
    this.egDirectionsDetail,
    this.doneeName,
    this.doneeAddress,
    this.doneeEmail,
    this.doneeActingMethod,
    this.saDonorFullName,
    this.saDonorAddress,
    this.saDonorEmail,
    this.saHasSecondDonor,
    this.saSecondDonorFullName,
    this.saSecondDonorAddress,
    this.saSecondDonorEmail,
    this.saCommencementType,
    this.waEpaDate,
    this.waFullLegalName,
    this.waResidentialAddress,
    this.waEmail,
    this.waAttorneyAppointmentType,
    this.waAttorneys = const [],
    this.waHasSubstitute,
    this.waSubstituteAppointmentType,
    this.waSubstitutes = const [],
    this.waSubstituteActsFor,
    this.waSubstituteWhenToAct,
    this.waHasConditions,
    this.waConditions,
    this.ntIsOver18,
    this.ntUnderstandsEpa,
    this.ntDonorFullName,
    this.ntDonorAddress,
    this.ntDonorDob,
    this.ntFinancialDmCount,
    this.ntFinancialDms = const [],
    this.ntFinancialDmActingMethod,
    this.ntFinancialLimits,
    this.ntOwnsLand,
    this.ntDmCanDealLand,
    this.actIsOver18,
    this.actUnderstandsEpa,
    this.actPrincipalFullName,
    this.actPrincipalAddress,
    this.actPrincipalEmail,
    this.actAttorneyCount,
    this.actAttorneys = const [],
    this.actHowAttorneysAct,
    this.actDelegationType,
    this.actDelegationDescription,
    this.actMatters = const [],
    this.actDirectionsProperty,
    this.actDirectionsPersonalCare,
    this.actDirectionsHealthCare,
    this.actDirectionsMedicalResearch,
    this.actMedicalTreatmentRefusal,
    this.actSpecificTreatments,
    this.actPropertyCommencement,
    this.actCommencementCircumstance,
    this.actPriorEpa,
    this.actPriorEpaContinueWhich,
    this.actPriorEpaDate,
    this.actPriorEpaAttorneyName,
    this.actSigningSelf,
    this.actDirectedSignerName,
    this.actDirectedSignerAddress,
    this.tasIsAdult,
    this.tasUnderstandsEpa,
    this.tasDonorFullName,
    this.tasDonorAddress,
    this.tasDonorEmail,
    this.tasCompletionDate,
    this.tasAttorneyCount,
    this.tasAttorneys = const [],
    this.tasHowAttorneysAct,
    this.ciConflictTransactions,
    this.ciGifts,
    this.ciDependentMaintenance,
    this.ciPaymentToAttorney,
    this.ciAdditionalCondition,
    this.hasMedicalDecisionMaker,
    this.medicalDecisionMakerDetails,
    this.hasRevocation,
    this.revocationDetails,
    this.hasLimitations,
    this.limitationsDetails,
    this.userEmail,
    this.userContactPreference,
  });

  PoaFlowData copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? dob,
    String? addressLine1,
    String? suburb,
    String? postcode,
    String? state,
    String? country,
    List<String>? matters,
    String? specificMatters,
    List<PoaPersonData>? attorneys,
    List<PoaPersonData>? successiveAttorneys,
    List<PoaPersonData>? enduringGuardians,
    List<PoaPersonData>? substituteEnduringGuardians,
    String? commencementType,
    String? commencementOther,
    bool? hasViewsWishes,
    String? viewsWishes,
    String? hasPreference,
    String? preferences,
    String? hasAttorneyInstruction,
    String? directions,
    bool? hasTermsInstructions,
    String? termsInstructions,
    bool? hasConditionsLimitations,
    String? conditionsLimitations,
    String? notifyWho,
    String? notifyInstructions,
    List<PoaPersonData>? notifyPersons,
    String? notifyWhatOption,
    String? notifyWhatOtherText,
    String? financialNotifyWho,
    String? financialNotifyInstructions,
    List<PoaPersonData>? financialNotifyPersons,
    String? financialNotifyWhatOption,
    String? financialNotifyWhatOtherText,
    bool? needsSigningAssistance,
    PoaPersonData? personalAssistancePerson,
    String? selectedAdditionalPower,
    List<PoaPersonData>? benefitsPersons,
    bool? egCanDecideLivingPlace,
    bool? egCanDecideHealthcare,
    String? egHealthcareDetail,
    bool? egCanDecideOtherPersonalService,
    String? egOtherPersonalService,
    bool? egCanConsentMedicalAndDental,
    String? egMedicalDetail,
    String? egOtherDetail,
    bool? egHasDirections,
    String? egDirectionsDetail,
    String? doneeName,
    String? doneeAddress,
    String? doneeEmail,
    String? doneeActingMethod,
    String? saDonorFullName,
    String? saDonorAddress,
    String? saDonorEmail,
    bool? saHasSecondDonor,
    String? saSecondDonorFullName,
    String? saSecondDonorAddress,
    String? saSecondDonorEmail,
    String? saCommencementType,
    String? waEpaDate,
    String? waFullLegalName,
    String? waResidentialAddress,
    String? waEmail,
    String? waAttorneyAppointmentType,
    List<WaPersonEntry>? waAttorneys,
    bool? waHasSubstitute,
    String? waSubstituteAppointmentType,
    List<WaPersonEntry>? waSubstitutes,
    String? waSubstituteActsFor,
    String? waSubstituteWhenToAct,
    bool? waHasConditions,
    String? waConditions,
    bool? ntIsOver18,
    bool? ntUnderstandsEpa,
    String? ntDonorFullName,
    String? ntDonorAddress,
    String? ntDonorDob,
    int? ntFinancialDmCount,
    List<NtDecisionMakerEntry>? ntFinancialDms,
    String? ntFinancialDmActingMethod,
    String? ntFinancialLimits,
    bool? ntOwnsLand,
    bool? ntDmCanDealLand,
    bool? actIsOver18,
    bool? actUnderstandsEpa,
    String? actPrincipalFullName,
    String? actPrincipalAddress,
    String? actPrincipalEmail,
    int? actAttorneyCount,
    List<ActAttorneyEntry>? actAttorneys,
    String? actHowAttorneysAct,
    String? actDelegationType,
    String? actDelegationDescription,
    List<String>? actMatters,
    String? actDirectionsProperty,
    String? actDirectionsPersonalCare,
    String? actDirectionsHealthCare,
    String? actDirectionsMedicalResearch,
    String? actMedicalTreatmentRefusal,
    String? actSpecificTreatments,
    String? actPropertyCommencement,
    String? actCommencementCircumstance,
    String? actPriorEpa,
    String? actPriorEpaContinueWhich,
    String? actPriorEpaDate,
    String? actPriorEpaAttorneyName,
    bool? actSigningSelf,
    String? actDirectedSignerName,
    String? actDirectedSignerAddress,
    bool? tasIsAdult,
    bool? tasUnderstandsEpa,
    String? tasDonorFullName,
    String? tasDonorAddress,
    String? tasDonorEmail,
    String? tasCompletionDate,
    int? tasAttorneyCount,
    List<TasAttorneyEntry>? tasAttorneys,
    String? tasHowAttorneysAct,
    String? ciConflictTransactions,
    String? ciGifts,
    String? ciDependentMaintenance,
    String? ciPaymentToAttorney,
    String? ciAdditionalCondition,
    bool? hasMedicalDecisionMaker,
    String? medicalDecisionMakerDetails,
    bool? hasRevocation,
    String? revocationDetails,
    bool? hasLimitations,
    String? limitationsDetails,
    String? userEmail,
    List<String>? userContactPreference,
  }) {
    return PoaFlowData(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      addressLine1: addressLine1 ?? this.addressLine1,
      suburb: suburb ?? this.suburb,
      postcode: postcode ?? this.postcode,
      state: state ?? this.state,
      country: country ?? this.country,
      matters: matters ?? this.matters,
      specificMatters: specificMatters ?? this.specificMatters,
      attorneys: attorneys ?? this.attorneys,
      successiveAttorneys: successiveAttorneys ?? this.successiveAttorneys,
      enduringGuardians: enduringGuardians ?? this.enduringGuardians,
      substituteEnduringGuardians:
          substituteEnduringGuardians ?? this.substituteEnduringGuardians,
      commencementType: commencementType ?? this.commencementType,
      commencementOther: commencementOther ?? this.commencementOther,
      hasViewsWishes: hasViewsWishes ?? this.hasViewsWishes,
      viewsWishes: viewsWishes ?? this.viewsWishes,
      hasPreference: hasPreference ?? this.hasPreference,
      preferences: preferences ?? this.preferences,
      hasAttorneyInstruction: hasAttorneyInstruction ?? this.hasAttorneyInstruction,
      directions: directions ?? this.directions,
      hasTermsInstructions: hasTermsInstructions ?? this.hasTermsInstructions,
      termsInstructions: termsInstructions ?? this.termsInstructions,
      hasConditionsLimitations:
          hasConditionsLimitations ?? this.hasConditionsLimitations,
      conditionsLimitations:
          conditionsLimitations ?? this.conditionsLimitations,
      notifyWho: notifyWho ?? this.notifyWho,
      notifyInstructions: notifyInstructions ?? this.notifyInstructions,
      notifyPersons: notifyPersons ?? this.notifyPersons,
      notifyWhatOption: notifyWhatOption ?? this.notifyWhatOption,
      notifyWhatOtherText: notifyWhatOtherText ?? this.notifyWhatOtherText,
      financialNotifyWho: financialNotifyWho ?? this.financialNotifyWho,
      financialNotifyInstructions: financialNotifyInstructions ?? this.financialNotifyInstructions,
      financialNotifyPersons: financialNotifyPersons ?? this.financialNotifyPersons,
      financialNotifyWhatOption: financialNotifyWhatOption ?? this.financialNotifyWhatOption,
      financialNotifyWhatOtherText: financialNotifyWhatOtherText ?? this.financialNotifyWhatOtherText,
      needsSigningAssistance:
          needsSigningAssistance ?? this.needsSigningAssistance,
      personalAssistancePerson:
          personalAssistancePerson ?? this.personalAssistancePerson,
      selectedAdditionalPower:
          selectedAdditionalPower ?? this.selectedAdditionalPower,
      benefitsPersons: benefitsPersons ?? this.benefitsPersons,
      egCanDecideLivingPlace:
          egCanDecideLivingPlace ?? this.egCanDecideLivingPlace,
      egCanDecideHealthcare:
          egCanDecideHealthcare ?? this.egCanDecideHealthcare,
      egHealthcareDetail: egHealthcareDetail ?? this.egHealthcareDetail,
      egCanDecideOtherPersonalService: egCanDecideOtherPersonalService ??
          this.egCanDecideOtherPersonalService,
      egOtherPersonalService:
          egOtherPersonalService ?? this.egOtherPersonalService,
      egCanConsentMedicalAndDental:
          egCanConsentMedicalAndDental ?? this.egCanConsentMedicalAndDental,
      egMedicalDetail: egMedicalDetail ?? this.egMedicalDetail,
      egOtherDetail: egOtherDetail ?? this.egOtherDetail,
      egHasDirections: egHasDirections ?? this.egHasDirections,
      egDirectionsDetail: egDirectionsDetail ?? this.egDirectionsDetail,
      doneeName: doneeName ?? this.doneeName,
      doneeAddress: doneeAddress ?? this.doneeAddress,
      doneeEmail: doneeEmail ?? this.doneeEmail,
      doneeActingMethod: doneeActingMethod ?? this.doneeActingMethod,
      saDonorFullName: saDonorFullName ?? this.saDonorFullName,
      saDonorAddress: saDonorAddress ?? this.saDonorAddress,
      saDonorEmail: saDonorEmail ?? this.saDonorEmail,
      saHasSecondDonor: saHasSecondDonor ?? this.saHasSecondDonor,
      saSecondDonorFullName: saSecondDonorFullName ?? this.saSecondDonorFullName,
      saSecondDonorAddress: saSecondDonorAddress ?? this.saSecondDonorAddress,
      saSecondDonorEmail: saSecondDonorEmail ?? this.saSecondDonorEmail,
      saCommencementType: saCommencementType ?? this.saCommencementType,
      waEpaDate: waEpaDate ?? this.waEpaDate,
      waFullLegalName: waFullLegalName ?? this.waFullLegalName,
      waResidentialAddress: waResidentialAddress ?? this.waResidentialAddress,
      waEmail: waEmail ?? this.waEmail,
      waAttorneyAppointmentType:
          waAttorneyAppointmentType ?? this.waAttorneyAppointmentType,
      waAttorneys: waAttorneys ?? this.waAttorneys,
      waHasSubstitute: waHasSubstitute ?? this.waHasSubstitute,
      waSubstituteAppointmentType:
          waSubstituteAppointmentType ?? this.waSubstituteAppointmentType,
      waSubstitutes: waSubstitutes ?? this.waSubstitutes,
      waSubstituteActsFor: waSubstituteActsFor ?? this.waSubstituteActsFor,
      waSubstituteWhenToAct:
          waSubstituteWhenToAct ?? this.waSubstituteWhenToAct,
      waHasConditions: waHasConditions ?? this.waHasConditions,
      waConditions: waConditions ?? this.waConditions,
      ntIsOver18: ntIsOver18 ?? this.ntIsOver18,
      ntUnderstandsEpa: ntUnderstandsEpa ?? this.ntUnderstandsEpa,
      ntDonorFullName: ntDonorFullName ?? this.ntDonorFullName,
      ntDonorAddress: ntDonorAddress ?? this.ntDonorAddress,
      ntDonorDob: ntDonorDob ?? this.ntDonorDob,
      ntFinancialDmCount: ntFinancialDmCount ?? this.ntFinancialDmCount,
      ntFinancialDms: ntFinancialDms ?? this.ntFinancialDms,
      ntFinancialDmActingMethod:
          ntFinancialDmActingMethod ?? this.ntFinancialDmActingMethod,
      ntFinancialLimits: ntFinancialLimits ?? this.ntFinancialLimits,
      ntOwnsLand: ntOwnsLand ?? this.ntOwnsLand,
      ntDmCanDealLand: ntDmCanDealLand ?? this.ntDmCanDealLand,
      actIsOver18: actIsOver18 ?? this.actIsOver18,
      actUnderstandsEpa: actUnderstandsEpa ?? this.actUnderstandsEpa,
      actPrincipalFullName: actPrincipalFullName ?? this.actPrincipalFullName,
      actPrincipalAddress: actPrincipalAddress ?? this.actPrincipalAddress,
      actPrincipalEmail: actPrincipalEmail ?? this.actPrincipalEmail,
      actAttorneyCount: actAttorneyCount ?? this.actAttorneyCount,
      actAttorneys: actAttorneys ?? this.actAttorneys,
      actHowAttorneysAct: actHowAttorneysAct ?? this.actHowAttorneysAct,
      actDelegationType: actDelegationType ?? this.actDelegationType,
      actDelegationDescription: actDelegationDescription ?? this.actDelegationDescription,
      actMatters: actMatters ?? this.actMatters,
      actDirectionsProperty: actDirectionsProperty ?? this.actDirectionsProperty,
      actDirectionsPersonalCare: actDirectionsPersonalCare ?? this.actDirectionsPersonalCare,
      actDirectionsHealthCare: actDirectionsHealthCare ?? this.actDirectionsHealthCare,
      actDirectionsMedicalResearch: actDirectionsMedicalResearch ?? this.actDirectionsMedicalResearch,
      actMedicalTreatmentRefusal: actMedicalTreatmentRefusal ?? this.actMedicalTreatmentRefusal,
      actSpecificTreatments: actSpecificTreatments ?? this.actSpecificTreatments,
      actPropertyCommencement: actPropertyCommencement ?? this.actPropertyCommencement,
      actCommencementCircumstance: actCommencementCircumstance ?? this.actCommencementCircumstance,
      actPriorEpa: actPriorEpa ?? this.actPriorEpa,
      actPriorEpaContinueWhich: actPriorEpaContinueWhich ?? this.actPriorEpaContinueWhich,
      actPriorEpaDate: actPriorEpaDate ?? this.actPriorEpaDate,
      actPriorEpaAttorneyName: actPriorEpaAttorneyName ?? this.actPriorEpaAttorneyName,
      actSigningSelf: actSigningSelf ?? this.actSigningSelf,
      actDirectedSignerName: actDirectedSignerName ?? this.actDirectedSignerName,
      actDirectedSignerAddress: actDirectedSignerAddress ?? this.actDirectedSignerAddress,
      tasIsAdult: tasIsAdult ?? this.tasIsAdult,
      tasUnderstandsEpa: tasUnderstandsEpa ?? this.tasUnderstandsEpa,
      tasDonorFullName: tasDonorFullName ?? this.tasDonorFullName,
      tasDonorAddress: tasDonorAddress ?? this.tasDonorAddress,
      tasDonorEmail: tasDonorEmail ?? this.tasDonorEmail,
      tasCompletionDate: tasCompletionDate ?? this.tasCompletionDate,
      tasAttorneyCount: tasAttorneyCount ?? this.tasAttorneyCount,
      tasAttorneys: tasAttorneys ?? this.tasAttorneys,
      tasHowAttorneysAct: tasHowAttorneysAct ?? this.tasHowAttorneysAct,
      ciConflictTransactions: ciConflictTransactions ?? this.ciConflictTransactions,
      ciGifts: ciGifts ?? this.ciGifts,
      ciDependentMaintenance: ciDependentMaintenance ?? this.ciDependentMaintenance,
      ciPaymentToAttorney: ciPaymentToAttorney ?? this.ciPaymentToAttorney,
      ciAdditionalCondition: ciAdditionalCondition ?? this.ciAdditionalCondition,
      hasMedicalDecisionMaker: hasMedicalDecisionMaker ?? this.hasMedicalDecisionMaker,
      medicalDecisionMakerDetails: medicalDecisionMakerDetails ?? this.medicalDecisionMakerDetails,
      hasRevocation: hasRevocation ?? this.hasRevocation,
      revocationDetails: revocationDetails ?? this.revocationDetails,
      hasLimitations: hasLimitations ?? this.hasLimitations,
      limitationsDetails: limitationsDetails ?? this.limitationsDetails,
      userEmail: userEmail ?? this.userEmail,
      userContactPreference:
          userContactPreference ?? this.userContactPreference,
    );
  }

  /// Build the attorney_additional_powers value from the single selection.
  String? _buildAdditionalPowers() {
    return selectedAdditionalPower;
  }

  /// Convert a date string from display format (DD/MM/YYYY) to API format
  /// (YYYY-MM-DD). Returns as-is if already in API format or unparseable.
  static String _toApiDateFormat(String date) {
    // Already in YYYY-MM-DD format
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) return date;
    // Convert DD/MM/YYYY → YYYY-MM-DD
    final parts = date.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return date;
  }

  /// Map UI WA appointment type to API value.
  static String? _mapWaAppointmentType(String? type) {
    switch (type) {
      case 'SOLE':
        return 'SOLO';
      case 'JOINT':
        return 'JOINT';
      case 'JOINT_AND_SEVERAL':
        return 'JOINT_SEVERAL';
      default:
        return type;
    }
  }

  /// Reverse map API WA appointment type to UI value.
  static String? _unmapWaAppointmentType(String? type) {
    switch (type) {
      case 'SOLO':
        return 'SOLE';
      case 'JOINT_SEVERAL':
        return 'JOINT_AND_SEVERAL';
      default:
        return type;
    }
  }

  /// Map UI WA commencement to API epa_effect value.
  static String? _mapWaEpaEffect(String? type) {
    switch (type) {
      case 'IMMEDIATELY':
        return 'IMMEDIATELY';
      case 'SAT_DECLARATION':
        return 'DECLARATION_IN_FORCE';
      default:
        return type;
    }
  }

  /// Reverse map API epa_effect to UI commencement value.
  static String? _unmapWaEpaEffect(String? type) {
    switch (type) {
      case 'DECLARATION_IN_FORCE':
        return 'SAT_DECLARATION';
      case 'IMMEDIATELY':
        return 'IMMEDIATELY';
      default:
        return type;
    }
  }

  /// Check if a tagged section exists in the combined conditions_limitations text.
  /// Used by VIC which stores TERMS/SPECIFIC MATTERS/LIMITATIONS combined.
  static bool _hasTaggedSection(String? combined, String section) {
    if (combined == null) return false;
    return combined.contains('$section:');
  }

  /// Extract a tagged section from the combined conditions_limitations text.
  /// Used by VIC which stores TERMS/SPECIFIC MATTERS/LIMITATIONS combined.
  static String? _extractTaggedSection(String? combined, String section) {
    if (combined == null) return null;
    // Split by ---
    final parts = combined.split('\n---\n');
    for (final part in parts) {
      if (part.startsWith('$section: ')) {
        return part.substring(section.length + 2);
      }
    }
    return null;
  }

  // ── ACT reverse-mappers (API lowercase → UI constants) ──

  static String? _unmapActAttorneyAction(String? v) {
    switch (v) {
      case 'together': return 'JOINTLY';
      case 'separately': return 'JOINTLY_SEVERALLY';
      default: return v;
    }
  }

  static String? _unmapActDelegationType(String? v) {
    switch (v) {
      case 'no_delegation': return 'NO_DELEGATION';
      case 'delegation_all_powers': return 'ALL_POWERS';
      case 'delegate_some_powers': return 'SOME_POWERS';
      default: return v;
    }
  }

  /// Convert API lowercase matters (e.g. ['property', 'personal_care']) to
  /// UI uppercase constants used by the ACT step 3 screen.
  static List<String> _unmapActMatters(List<String> apiMatters) {
    if (apiMatters.isEmpty) return [];
    return apiMatters.map((m) => m.toUpperCase()).toList();
  }

  static String? _unmapActMedicalRefusal(String? v) {
    switch (v) {
      case 'not_allowed': return 'NOT_ALLOWED';
      case 'allowed_generally': return 'ALLOWED_GENERALLY';
      case 'allowed_specific': return 'ALLOWED_SPECIFIC';
      default: return v;
    }
  }

  static String? _unmapActCommencement(String? v) {
    switch (v) {
      case 'immediately': return 'IMMEDIATELY';
      case 'from_date_or_event': return 'FROM_DATE_EVENT';
      case 'only_when_impaired_capacity': return 'IMPAIRED_CAPACITY';
      default: return v;
    }
  }

  static String? _unmapActPriorEpa(String? v) {
    switch (v) {
      case 'none_previous': return 'NONE';
      case 'revoke_all_previous': return 'REVOKE_ALL_PREVIOUS';
      case 'some_continue': return 'SOME_CONTINUE';
      default: return v;
    }
  }

  /// Map UI commencementType to the API commencement value.
  String _mapCommencement() {
    switch (commencementType) {
      case 'IMMEDIATELY':
        return 'IMMEDIATELY';
      case 'INCAPACITY':
      default:
        return 'UPON_ATTORNEY_RECEIVING_CONDITION';
    }
  }

  /// Convert wizard state to the API POST body for /user/power-of-attorney.
  /// State-specific states (WA, SA, TAS, ACT, NT) produce clean payloads
  /// with only their relevant fields — matching the web app's mapper approach.
  /// Universal states (QLD, NSW, VIC) use the full PowerOfAttorney structure.
  Map<String, dynamic> toApiJson() {
    final stateKey = state?.toLowerCase();

    // State-specific states return clean payloads with only relevant fields.
    switch (stateKey) {
      case 'western_australia':
        return _buildWaPayload();
      case 'south_australia':
        return _buildSaPayload();
      case 'tasmania':
        return _buildTasPayload();
      case 'act':
        return _buildActPayload();
      case 'northern_territory':
        return _buildNtPayload();
      default:
        return _buildUniversalPayload();
    }
  }

  /// WA-specific payload — matches web mapWesternAustraliaPOAToBackend()
  Map<String, dynamic> _buildWaPayload() {
    final json = <String, dynamic>{
      'full_legal_name': waFullLegalName,
      'residential_address': waResidentialAddress,
      'email_id': waEmail,
      'attorney_appointment_type': _mapWaAppointmentType(waAttorneyAppointmentType),
      'has_substitute_attorney': waHasSubstitute ?? false,
      'has_conditions_restrictions': waHasConditions ?? false,
      'epa_effect': _mapWaEpaEffect(commencementType),
    };
    if (waEpaDate != null && waEpaDate!.isNotEmpty) {
      json['enduring_poa_completion_date'] = _toApiDateFormat(waEpaDate!);
    }
    if (waSubstituteAppointmentType != null) {
      json['substitute_attorney_appointment_type'] =
          _mapWaAppointmentType(waSubstituteAppointmentType);
    }
    if (waSubstituteActsFor != null) {
      json['substitute_act_substitution'] = waSubstituteActsFor;
    }
    if (waSubstituteWhenToAct != null) {
      json['substitute_act_activation'] = waSubstituteWhenToAct;
    }
    if (waHasConditions == true && waConditions != null) {
      json['conditions_restrictions'] = waConditions!.trim();
    }
    return json;
  }

  /// SA-specific payload — matches web mapSouthAustraliaPOAToBackend()
  Map<String, dynamic> _buildSaPayload() {
    final json = <String, dynamic>{
      'full_legal_name': saDonorFullName,
      'residential_address': saDonorAddress,
      'email_id': saDonorEmail,
      'has_second_donor': saHasSecondDonor ?? false,
      'poa_start_rule': saCommencementType,
      'has_conditions_limitations': hasConditionsLimitations ?? false,
    };
    if (doneeActingMethod != null) {
      json['donees_act_rules'] = doneeActingMethod;
    }
    if (hasConditionsLimitations == true && conditionsLimitations != null) {
      json['conditions_limitations'] = conditionsLimitations!.trim();
    }
    return json;
  }

  /// TAS-specific payload — matches web mapTasmaniaPOAToBackend()
  Map<String, dynamic> _buildTasPayload() {
    final json = <String, dynamic>{
      'is_adult': tasIsAdult ?? true,
      'is_understand_effect_poa': tasUnderstandsEpa ?? true,
      'full_legal_name': tasDonorFullName,
      'residential_address': tasDonorAddress,
      'email_id': tasDonorEmail,
      'has_conditions_limitations': hasConditionsLimitations ?? false,
    };
    if (tasCompletionDate != null) {
      json['enduring_poa_completion_date'] = tasCompletionDate;
    }
    if (tasHowAttorneysAct != null) {
      json['attorney_act_rules'] = tasHowAttorneysAct;
    }
    if (hasConditionsLimitations == true && conditionsLimitations != null) {
      json['conditions_limitations'] = conditionsLimitations!.trim();
    }
    return json;
  }

  /// ACT-specific payload — matches web mapACTPOAToBackend()
  Map<String, dynamic> _buildActPayload() {
    final json = <String, dynamic>{
      'is_adult': actIsOver18 ?? true,
      'is_understand_effect_poa': actUnderstandsEpa ?? true,
      'full_legal_name': actPrincipalFullName,
      'residential_address': actPrincipalAddress,
      'email_id': actPrincipalEmail,
      'number_of_attorneys': actAttorneyCount ?? actAttorneys.length,
      'is_attorney_corporate':
          actAttorneys.isNotEmpty ? actAttorneys.first.isCorporation : false,
      'is_attorney_declared_bankrupt':
          actAttorneys.isNotEmpty ? actAttorneys.first.isBankrupt : false,
      'delegation_power_type': _mapActDelegationType(actDelegationType),
      'property_commencement_type': _mapActCommencement(actPropertyCommencement),
      'prior_epa_status': _mapActPriorEpa(actPriorEpa),
      'is_epoa_sign': actSigningSelf ?? true,
    };

    // Attorney 1 details
    if (actAttorneys.isNotEmpty) {
      json['attorney_name'] = actAttorneys[0].fullName;
      json['attorney_address'] = actAttorneys[0].address;
      if (actAttorneys[0].isCorporation) {
        json['corporation_type'] = actAttorneys[0].corporationType;
      }
    }

    // Attorney 2 details
    if (actAttorneys.length > 1) {
      json['attorney_2_name'] = actAttorneys[1].fullName;
      json['attorney_2_address'] = actAttorneys[1].address;
      json['is_attorney_2_corporate'] = actAttorneys[1].isCorporation;
      if (actAttorneys[1].isCorporation) {
        json['attorney_2_corporation_type'] = actAttorneys[1].corporationType;
      }
      json['is_attorney_2_declared_bankrupt'] = actAttorneys[1].isBankrupt;
    }

    // Attorney 3 details
    if (actAttorneys.length > 2) {
      json['attorney_3_name'] = actAttorneys[2].fullName;
      json['attorney_3_address'] = actAttorneys[2].address;
      json['is_attorney_3_corporate'] = actAttorneys[2].isCorporation;
      if (actAttorneys[2].isCorporation) {
        json['attorney_3_corporation_type'] = actAttorneys[2].corporationType;
      }
      json['is_attorney_3_declared_bankrupt'] = actAttorneys[2].isBankrupt;
    }

    if (actHowAttorneysAct != null) {
      json['attorney_action_type'] = _mapActAttorneyAction(actHowAttorneysAct!);
    }
    if (actDelegationType == 'SOME_POWERS' && actDelegationDescription != null) {
      json['delegation_powers_detail'] = actDelegationDescription;
    }
    if (actMatters.isNotEmpty) {
      json['matters_covered'] = actMatters.map((m) => m.toLowerCase()).toList();
    }
    if (actDirectionsProperty != null) {
      json['property_directions'] = actDirectionsProperty;
    }
    if (actDirectionsPersonalCare != null) {
      json['personal_care_directions'] = actDirectionsPersonalCare;
    }
    if (actDirectionsHealthCare != null) {
      json['health_care_directions'] = actDirectionsHealthCare;
    }
    if (actDirectionsMedicalResearch != null) {
      json['medical_research_directions'] = actDirectionsMedicalResearch;
    }
    if (actMedicalTreatmentRefusal != null) {
      json['medical_treatment_refusal'] = _mapActMedicalRefusal(actMedicalTreatmentRefusal!);
    }
    if (actSpecificTreatments != null) {
      json['specific_treatment'] = actSpecificTreatments;
    }
    if (actCommencementCircumstance != null) {
      json['property_commencement_circumstance'] = actCommencementCircumstance;
    }
    if (actPriorEpaContinueWhich != null) {
      json['prior_epa_continue_detail'] = actPriorEpaContinueWhich;
    }
    if (actPriorEpaDate != null) {
      json['date_poa'] = _toApiDateFormat(actPriorEpaDate!);
    }
    if (actPriorEpaAttorneyName != null) {
      json['attorney_name_poa'] = actPriorEpaAttorneyName;
    }
    if (actDirectedSignerName != null) {
      json['sign_person_full_name'] = actDirectedSignerName;
    }
    if (actDirectedSignerAddress != null) {
      json['sign_person_address'] = actDirectedSignerAddress;
    }
    return json;
  }

  static String? _mapActDelegationType(String? v) {
    switch (v) {
      case 'NO_DELEGATION': return 'no_delegation';
      case 'ALL_POWERS': return 'delegation_all_powers';
      case 'SOME_POWERS': return 'delegate_some_powers';
      default: return v?.toLowerCase();
    }
  }

  static String? _mapActCommencement(String? v) {
    switch (v) {
      case 'IMMEDIATELY': return 'immediately';
      case 'FROM_DATE_EVENT': return 'from_date_or_event';
      case 'IMPAIRED_CAPACITY': return 'only_when_impaired_capacity';
      default: return v?.toLowerCase();
    }
  }

  static String? _mapActPriorEpa(String? v) {
    switch (v) {
      case 'NONE': return 'none_previous';
      case 'REVOKE_ALL_PREVIOUS': return 'revoke_all_previous';
      case 'SOME_CONTINUE': return 'some_continue';
      default: return v?.toLowerCase();
    }
  }

  static String _mapActAttorneyAction(String v) {
    switch (v) {
      case 'JOINTLY': return 'together';
      case 'JOINTLY_SEVERALLY': return 'separately';
      default: return v.toLowerCase();
    }
  }

  static String _mapActMedicalRefusal(String v) {
    switch (v) {
      case 'NOT_ALLOWED': return 'not_allowed';
      case 'ALLOWED_GENERALLY': return 'allowed_generally';
      case 'ALLOWED_SPECIFIC': return 'allowed_specific';
      default: return v.toLowerCase();
    }
  }

  /// NT-specific payload — matches web mapNorthernTerritoryPOAToBackend()
  Map<String, dynamic> _buildNtPayload() {
    final json = <String, dynamic>{
      'is_adult': ntIsOver18 ?? true,
      'is_doing_voluntarily': ntUnderstandsEpa ?? true,
      'full_legal_name': ntDonorFullName,
      'residential_address': ntDonorAddress,
      // DOB is now saved via /user/attorney-for-poa with ATTORNEY_DONOR type
      'number_of_decision_makers': ntFinancialDmCount ?? 1,
      'has_land_northern_territory': ntOwnsLand ?? false,
    };
    if (ntFinancialDmActingMethod != null) {
      // UI uses SEVERALLY / JOINTLY; backend expects JOINTLY_SEVERALLY / JOINTLY
      json['attorney_act_rules'] = ntFinancialDmActingMethod == 'SEVERALLY'
          ? 'JOINTLY_SEVERALLY'
          : ntFinancialDmActingMethod;
    }
    if (ntFinancialLimits != null && ntFinancialLimits!.isNotEmpty) {
      json['instruction_decision_makers'] = ntFinancialLimits;
    }
    if (ntOwnsLand == true) {
      json['need_financial_decision_for_land'] = ntDmCanDealLand ?? false;
    }
    return json;
  }

  /// Universal payload for QLD, NSW, VIC — full PowerOfAttorney structure.
  Map<String, dynamic> _buildUniversalPayload() {
    // Map UI matters to API list format.
    // Backend enum: PERSONAL, HEALTH, FINANCE, SPECIFIC
    // UI uses PERSONAL_HEALTH (combined) and FINANCIAL.
    List<String> apiMatters;
    if (matters.contains('SPECIFIC')) {
      apiMatters = ['SPECIFIC'];
    } else {
      apiMatters = <String>[];
      if (matters.contains('PERSONAL_HEALTH')) {
        apiMatters.addAll(['PERSONAL', 'HEALTH']);
      }
      if (matters.contains('FINANCIAL')) {
        apiMatters.add('FINANCE');
      }
      if (apiMatters.isEmpty) {
        apiMatters = ['PERSONAL'];
      }
    }

    // Map UI commencement to API financial_commencement value.
    final isVic = state?.toLowerCase() == 'victoria';
    final isNsw = state?.toLowerCase() == 'new_south_wales';

    String? apiFinancialCommencement;
    if (isVic) {
      apiFinancialCommencement = 'DONT_HAVE_CAPACITY';
    } else {
      if (commencementType == 'INCAPACITY') {
        apiFinancialCommencement = 'DONT_HAVE_CAPACITY';
      } else if (commencementType == 'IMMEDIATELY') {
        apiFinancialCommencement = 'IMMEDIATELY_OTHERS';
      } else if (commencementType == 'OTHER') {
        apiFinancialCommencement = 'IMMEDIATELY_OTHERS';
      }
    }

    // Build preferences from UI fields
    final hasAnyPreference = hasPreference == 'yes' &&
        preferences != null &&
        preferences!.trim().isNotEmpty;
    final preferencesText = hasAnyPreference ? preferences!.trim() : null;

    final hasDirections =
        directions != null && directions!.trim().isNotEmpty;
    final hasTerms = hasTermsInstructions == true &&
        termsInstructions != null &&
        termsInstructions!.trim().isNotEmpty;
    final effectiveAttorneyInstruction = hasDirections
        ? directions!.trim()
        : hasTerms
            ? termsInstructions!.trim()
            : null;
    final hasEffectiveDirections = effectiveAttorneyInstruction != null;

    // VIC: send limitations as plain text; specific_matters sent separately.
    bool effectiveHasConditions;
    String? effectiveConditionsText;
    if (isVic) {
      effectiveHasConditions = (hasLimitations == true && (limitationsDetails ?? '').trim().isNotEmpty);
      effectiveConditionsText = effectiveHasConditions ? limitationsDetails!.trim() : null;
    } else {
      effectiveHasConditions = (hasConditionsLimitations ?? false) || (hasTermsInstructions ?? false);
      effectiveConditionsText = hasConditionsLimitations == true
          ? conditionsLimitations?.trim()
          : hasTermsInstructions == true
              ? termsInstructions?.trim()
              : null;
    }

    final json = <String, dynamic>{
      'state': state,
      'matters': apiMatters,
      'financial_commencement': apiFinancialCommencement,
      'financial_decision_for_attorney': commencementOther,
      'has_preference': hasAnyPreference,
      'preferences': preferencesText,
      'has_attorney_instruction': hasEffectiveDirections,
      'attorney_instruction': effectiveAttorneyInstruction,
      'need_signing_assistance': needsSigningAssistance ?? false,
      'has_previous_valid_poa': hasRevocation ?? false,
      'need_revocation': hasRevocation ?? false,
      'previous_poa_detail': hasRevocation == true
          ? revocationDetails?.trim()
          : null,
      // API only stores ci_* prefix — send ci_* for both VIC and NSW
      if (isVic) 'commencement': _mapCommencement(),
      if (isVic || isNsw) 'ci_conflict_transactions': ciConflictTransactions?.trim(),
      if (isVic || isNsw) 'ci_gifts': ciGifts?.trim(),
      if (isVic || isNsw) 'ci_dependent_maintenance': ciDependentMaintenance?.trim(),
      if (isVic || isNsw) 'ci_payment_to_attorney': ciPaymentToAttorney?.trim(),
      if (isVic || isNsw) 'ci_additional_condition': ciAdditionalCondition?.trim(),
      'has_conditions_limitations': effectiveHasConditions,
      'conditions_limitations': effectiveConditionsText,
      if (matters.contains('SPECIFIC') && (specificMatters ?? '').trim().isNotEmpty)
        'specific_matters': specificMatters!.trim(),
      'attorney_additional_powers': _buildAdditionalPowers(),
      'eg_can_decide_living_place': egCanDecideLivingPlace ?? false,
      'eg_living_place_detail': null,
      'eg_can_decide_healthcare': egCanDecideHealthcare ?? false,
      'eg_healthcare_detail': egCanDecideHealthcare == true
          ? egHealthcareDetail?.trim()
          : null,
      'eg_can_decide_other_personal_service':
          egCanDecideOtherPersonalService ?? false,
      'eg_other_personal_service': egCanDecideOtherPersonalService == true
          ? egOtherPersonalService?.trim()
          : null,
      'eg_other_detail': egOtherDetail?.trim(),
      'eg_can_consent_medical_and_dental':
          egCanConsentMedicalAndDental ?? false,
      'eg_medical_detail_detail': egCanConsentMedicalAndDental == true
          ? egMedicalDetail?.trim()
          : null,
      'eg_has_directions': egHasDirections ?? false,
      'eg_directions_detail':
          egHasDirections == true ? egDirectionsDetail?.trim() : null,
    };

    return json;
  }

  /// Create a [PoaFlowData] from the API GET response.
  factory PoaFlowData.fromPoaData(PoaData data) {
    List<String> uiMatters = [];
    if (data.matters.contains('SPECIFIC')) {
      uiMatters = ['SPECIFIC'];
    } else {
      if (data.matters.contains('PERSONAL') || data.matters.contains('HEALTH')) {
        uiMatters.add('PERSONAL_HEALTH');
      }
      if (data.matters.contains('FINANCIAL') || data.matters.contains('FINANCE')) {
        uiMatters.add('FINANCIAL');
      }
    }

    String? uiCommencement;
    if (data.financialCommencement == 'DONT_HAVE_CAPACITY') {
      uiCommencement = 'INCAPACITY';
    } else if (data.financialCommencement == 'IMMEDIATELY_OTHERS') {
      // If there's detail text, it was the "Others" option; otherwise "Immediately"
      if (data.financialDecisionForAttorney != null &&
          data.financialDecisionForAttorney!.isNotEmpty) {
        uiCommencement = 'OTHER';
      } else {
        uiCommencement = 'IMMEDIATELY';
      }
    }

    // WA uses epa_effect for commencement instead of financial_commencement
    if (uiCommencement == null && data.epaEffect != null) {
      uiCommencement = _unmapWaEpaEffect(data.epaEffect);
    }

    return PoaFlowData(
      matters: uiMatters,
      commencementType: uiCommencement,
      commencementOther: data.financialDecisionForAttorney,
      hasViewsWishes: data.hasPreference,
      viewsWishes: data.preferences,
      hasPreference: data.hasPreference == true ? 'yes' : 'no',
      preferences: data.preferences,
      hasAttorneyInstruction: data.hasAttorneyInstruction == true ? 'yes' : 'no',
      directions: data.attorneyInstruction,
      hasConditionsLimitations: data.hasConditionsLimitations,
      conditionsLimitations: data.conditionsLimitations,
      needsSigningAssistance: data.needSigningAssistance,
      selectedAdditionalPower: data.attorneyAdditionalPowers,
      egCanDecideLivingPlace: data.egCanDecideLivingPlace,
      egCanDecideHealthcare: data.egCanDecideHealthcare,
      egHealthcareDetail: data.egHealthcareDetail,
      egCanDecideOtherPersonalService: data.egCanDecideOtherPersonalService,
      egOtherPersonalService: data.egOtherPersonalService,
      egCanConsentMedicalAndDental: data.egCanConsentMedicalAndDental,
      egMedicalDetail: data.egMedicalDetailDetail,
      egOtherDetail: data.egOtherDetail,
      egHasDirections: data.egHasDirections,
      egDirectionsDetail: data.egDirectionsDetail,
      // ── Victoria-specific fields ──
      ciConflictTransactions: data.ciConflictTransactions,
      ciGifts: data.ciGifts,
      ciDependentMaintenance: data.ciDependentMaintenance,
      ciPaymentToAttorney: data.ciPaymentToAttorney,
      ciAdditionalCondition: data.ciAdditionalCondition,
      hasMedicalDecisionMaker: data.hasMedicalDecisionMaker,
      medicalDecisionMakerDetails: data.medicalDecisionMakerDetails,
      // VIC limitations: read directly from conditions_limitations (plain text).
      // Fall back to tagged extraction for legacy data.
      hasLimitations: data.hasConditionsLimitations ??
          _hasTaggedSection(data.conditionsLimitations, 'LIMITATIONS'),
      limitationsDetails: data.specificMatters == null
          ? (_extractTaggedSection(data.conditionsLimitations, 'LIMITATIONS') ??
              data.conditionsLimitations)
          : data.conditionsLimitations,
      specificMatters: data.specificMatters ??
          _extractTaggedSection(data.conditionsLimitations, 'SPECIFIC MATTERS'),
      hasRevocation: data.needRevocation,
      revocationDetails: data.previousPoaDetail,
      // ── ACT-specific fields (restored from shared API fields) ──
      actIsOver18: data.isAdult,
      actUnderstandsEpa: data.isUnderstandEffectPoa,
      actPrincipalFullName: data.fullLegalName,
      actPrincipalAddress: data.residentialAddress,
      actPrincipalEmail: data.emailId,
      // ACT attorneys are loaded via GET /user/attorneys-for-poa (not inline)
      actHowAttorneysAct: _unmapActAttorneyAction(data.attorneyActRules),
      actDelegationType: _unmapActDelegationType(data.attorneyPowers),
      actDelegationDescription: data.attorneyPowerDetail,
      actMatters: _unmapActMatters(data.attorneyPowerMatters),
      actDirectionsProperty: data.directionProperty,
      actDirectionsPersonalCare: data.directionPersonalCare,
      actDirectionsHealthCare: data.directionHealthCare,
      actDirectionsMedicalResearch: data.directionMedicalResearch,
      actMedicalTreatmentRefusal: _unmapActMedicalRefusal(data.medicalTreatmentWithdraw),
      actSpecificTreatments: data.specificTreatment,
      actPropertyCommencement: _unmapActCommencement(data.attorneyPowerCommencement),
      actCommencementCircumstance: data.attorneyPowerCommencementCircumstance,
      actPriorEpa: _unmapActPriorEpa(data.enduringPoa),
      actPriorEpaContinueWhich: data.previousPoaDetail,
      actPriorEpaDate: data.datePoa,
      actPriorEpaAttorneyName: data.attorneyNamePoa,
      actSigningSelf: data.isEpoaSign,
      actDirectedSignerName: data.signPersonFullName,
      actDirectedSignerAddress: data.signPersonAddress,
      // ── TAS-specific fields (restored from shared API fields) ──
      tasIsAdult: data.isAdult,
      tasUnderstandsEpa: data.isUnderstandEffectPoa,
      tasDonorFullName: data.fullLegalName,
      tasDonorAddress: data.residentialAddress,
      tasDonorEmail: data.emailId,
      tasCompletionDate: data.enduringPoaCompletionDate,
      tasHowAttorneysAct: data.attorneyActRules,
      // ── SA-specific fields ──
      saDonorFullName: data.fullLegalName,
      saDonorAddress: data.residentialAddress,
      saDonorEmail: data.emailId,
      saHasSecondDonor: data.hasSecondDonor,
      doneeActingMethod: data.doneesActRules,
      saCommencementType: data.poaStartRule,
      // ── WA-specific fields ──
      waEpaDate: data.epaDate,
      waFullLegalName: data.fullLegalName,
      waResidentialAddress: data.residentialAddress,
      waEmail: data.emailId,
      waAttorneyAppointmentType: _unmapWaAppointmentType(data.attorneyAppointmentType),
      waHasSubstitute: data.hasSubstitute,
      waSubstituteAppointmentType: _unmapWaAppointmentType(data.substituteAppointmentType),
      waSubstituteActsFor: data.substituteActsFor,
      waSubstituteWhenToAct: data.substituteWhenToAct,
      waHasConditions: data.hasConditionsRestrictions,
      waConditions: data.conditionsRestrictions,
      // ── NT-specific fields ──
      ntIsOver18: data.isAdult,
      ntUnderstandsEpa: data.isDoingVoluntarily ?? data.isUnderstandEffectPoa,
      ntDonorFullName: data.fullLegalName,
      ntDonorAddress: data.residentialAddress,
      // DOB is now loaded from ATTORNEY_DONOR via _applyAttorneys()
      ntDonorDob: null,
      ntFinancialDmCount: data.numberOfDecisionMakers,
      // Backend returns JOINTLY_SEVERALLY / JOINTLY; UI expects SEVERALLY / JOINTLY
      ntFinancialDmActingMethod: data.attorneyActRules == 'JOINTLY_SEVERALLY'
          ? 'SEVERALLY'
          : data.attorneyActRules,
      ntFinancialLimits: data.instructionDecisionMakers,
      ntOwnsLand: data.hasLandNorthernTerritory,
      ntDmCanDealLand: data.needFinancialDecisionForLand,
      // ── Notification fields ──
      notifyWho: data.notifyWho,
      notifyInstructions: data.notifyInstructions,
      notifyWhatOption: data.notifyWhatOption,
      notifyWhatOtherText: data.notifyWhatOtherText,
      // ── Terms & instructions ──
      // Backend has no terms_instructions field. For VIC, terms are stored in
      // conditions_limitations with TERMS: prefix. For QLD, fall back to
      // attorney_instruction or conditions_limitations.
      hasTermsInstructions: _hasTaggedSection(data.conditionsLimitations, 'TERMS')
          ? true
          : (data.hasAttorneyInstruction ?? data.hasConditionsLimitations),
      termsInstructions: _extractTaggedSection(data.conditionsLimitations, 'TERMS')
          ?? data.attorneyInstruction
          ?? data.conditionsLimitations,
    );
  }
}

// ── API response model ───────────────────────────────────────────────────────

/// Data model for the GET /user/power-of-attorney response.
class PoaData {
  final dynamic id;
  final List<String> matters;
  final String? financialCommencement;
  final String? financialDecisionForAttorney;
  final bool? hasPreference;
  final String? preferences;
  final bool? hasAttorneyInstruction;
  final String? attorneyInstruction;
  final bool? needSigningAssistance;
  final bool? hasPreviousValidPoa;
  final bool? needRevocation;
  final String? previousPoaDetail;
  final String? commencement;
  final String? ciConflictTransactions;
  final String? ciGifts;
  final String? ciDependentMaintenance;
  final String? ciPaymentToAttorney;
  final String? ciAdditionalCondition;
  final bool? hasConditionsLimitations;
  final String? conditionsLimitations;
  final bool? hasMedicalDecisionMaker;
  final String? medicalDecisionMakerDetails;
  final String? specificMatters;
  final String? attorneyAdditionalPowers;
  final bool? egCanDecideLivingPlace;
  final String? egLivingPlaceDetail;
  final bool? egCanDecideHealthcare;
  final String? egHealthcareDetail;
  final bool? egCanDecideOtherPersonalService;
  final String? egOtherPersonalService;
  final String? egOtherDetail;
  final bool? egCanConsentMedicalAndDental;
  final String? egMedicalDetailDetail;
  final bool? egHasDirections;
  final String? egDirectionsDetail;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  // ── Shared fields used across states (ACT, NT, WA, SA, etc.) ──
  final String? fullLegalName;
  final String? residentialAddress;
  final String? emailId;
  final bool? isAdult;
  final bool? isUnderstandEffectPoa;
  final bool? isAttorneyCorporate;
  final String? corporationType;
  final bool? isAttorneyDeclaredBankrupt;
  final String? attorneyActRules;
  final String? attorneyPowers;
  final String? attorneyPowerDetail;
  final List<String> attorneyPowerMatters;
  final String? directionProperty;
  final String? directionPersonalCare;
  final String? directionHealthCare;
  final String? directionMedicalResearch;
  final String? medicalTreatmentWithdraw;
  final String? specificTreatment;
  final String? attorneyPowerCommencement;
  final String? attorneyPowerCommencementCircumstance;
  final String? enduringPoa;
  final String? datePoa;
  final String? attorneyNamePoa;
  final bool? isEpoaSign;
  final String? signPersonFullName;
  final String? signPersonAddress;
  final String? enduringPoaCompletionDate;

  // ── SA-specific fields ──
  final bool? hasSecondDonor;
  final String? doneesActRules;
  final String? poaStartRule;

  // ── Terms & instructions (separate from attorney instructions) ──
  final bool? hasTermsInstructions;
  final String? termsInstructions;

  // ── Notification fields ──
  final String? notifyWho;
  final String? notifyInstructions;
  final String? notifyWhatOption;
  final String? notifyWhatOtherText;

  // ── WA-specific fields ──
  final String? epaDate;
  final String? attorneyAppointmentType;
  final bool? hasSubstitute;
  final String? substituteAppointmentType;
  final String? substituteActsFor;
  final String? substituteWhenToAct;
  final bool? hasConditionsRestrictions;
  final String? conditionsRestrictions;
  final String? epaEffect;

  // ── NT-specific fields ──
  final bool? isDoingVoluntarily;
  final int? numberOfDecisionMakers;
  final String? instructionDecisionMakers;
  final bool? hasLandNorthernTerritory;
  final bool? needFinancialDecisionForLand;

  const PoaData({
    this.id,
    this.matters = const [],
    this.financialCommencement,
    this.financialDecisionForAttorney,
    this.hasPreference,
    this.preferences,
    this.hasAttorneyInstruction,
    this.attorneyInstruction,
    this.needSigningAssistance,
    this.hasPreviousValidPoa,
    this.needRevocation,
    this.previousPoaDetail,
    this.commencement,
    this.ciConflictTransactions,
    this.ciGifts,
    this.ciDependentMaintenance,
    this.ciPaymentToAttorney,
    this.ciAdditionalCondition,
    this.hasConditionsLimitations,
    this.conditionsLimitations,
    this.hasMedicalDecisionMaker,
    this.medicalDecisionMakerDetails,
    this.specificMatters,
    this.attorneyAdditionalPowers,
    this.egCanDecideLivingPlace,
    this.egLivingPlaceDetail,
    this.egCanDecideHealthcare,
    this.egHealthcareDetail,
    this.egCanDecideOtherPersonalService,
    this.egOtherPersonalService,
    this.egOtherDetail,
    this.egCanConsentMedicalAndDental,
    this.egMedicalDetailDetail,
    this.egHasDirections,
    this.egDirectionsDetail,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.fullLegalName,
    this.residentialAddress,
    this.emailId,
    this.isAdult,
    this.isUnderstandEffectPoa,
    this.isAttorneyCorporate,
    this.corporationType,
    this.isAttorneyDeclaredBankrupt,
    this.attorneyActRules,
    this.attorneyPowers,
    this.attorneyPowerDetail,
    this.attorneyPowerMatters = const [],
    this.directionProperty,
    this.directionPersonalCare,
    this.directionHealthCare,
    this.directionMedicalResearch,
    this.medicalTreatmentWithdraw,
    this.specificTreatment,
    this.attorneyPowerCommencement,
    this.attorneyPowerCommencementCircumstance,
    this.enduringPoa,
    this.datePoa,
    this.attorneyNamePoa,
    this.isEpoaSign,
    this.signPersonFullName,
    this.signPersonAddress,
    this.enduringPoaCompletionDate,
    this.hasSecondDonor,
    this.doneesActRules,
    this.poaStartRule,
    this.hasTermsInstructions,
    this.termsInstructions,
    this.notifyWho,
    this.notifyInstructions,
    this.notifyWhatOption,
    this.notifyWhatOtherText,
    this.epaDate,
    this.attorneyAppointmentType,
    this.hasSubstitute,
    this.substituteAppointmentType,
    this.substituteActsFor,
    this.substituteWhenToAct,
    this.hasConditionsRestrictions,
    this.conditionsRestrictions,
    this.epaEffect,
    this.isDoingVoluntarily,
    this.numberOfDecisionMakers,
    this.instructionDecisionMakers,
    this.hasLandNorthernTerritory,
    this.needFinancialDecisionForLand,
  });

  factory PoaData.fromJson(Map<String, dynamic> json) {
    return PoaData(
      id: json['id'],
      matters: (json['matters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      financialCommencement: json['financial_commencement'] as String?,
      financialDecisionForAttorney:
          json['financial_decision_for_attorney'] as String?,
      hasPreference: json['has_preference'] as bool?,
      preferences: json['preferences'] as String?,
      hasAttorneyInstruction: json['has_attorney_instruction'] as bool?,
      attorneyInstruction: json['attorney_instruction'] as String?,
      needSigningAssistance: json['need_signing_assistance'] as bool?,
      hasPreviousValidPoa: json['has_previous_valid_poa'] as bool?,
      needRevocation: json['need_revocation'] as bool?,
      previousPoaDetail: (json['previous_poa_detail'] ?? json['prior_epa_continue_detail']) as String?,
      commencement: json['commencement'] as String?,
      ciConflictTransactions: (json['ci_conflict_transactions'] ?? json['cl_conflict_transactions']) as String?,
      ciGifts: (json['ci_gifts'] ?? json['cl_gifts']) as String?,
      ciDependentMaintenance: (json['ci_dependent_maintenance'] ?? json['cl_dependent_maintenance']) as String?,
      ciPaymentToAttorney: (json['ci_payment_to_attorney'] ?? json['cl_payments_to_attorney']) as String?,
      ciAdditionalCondition: (json['ci_additional_condition'] ?? json['cl_advise_to_agents']) as String?,
      hasConditionsLimitations: json['has_conditions_limitations'] as bool?,
      conditionsLimitations: json['conditions_limitations'] as String?,
      hasMedicalDecisionMaker: json['has_medical_decision_maker'] as bool?,
      medicalDecisionMakerDetails: json['medical_decision_maker_details'] as String?,
      specificMatters: json['specific_matters'] as String?,
      attorneyAdditionalPowers:
          json['attorney_additional_powers'] as String?,
      egCanDecideLivingPlace: json['eg_can_decide_living_place'] as bool?,
      egLivingPlaceDetail: json['eg_living_place_detail'] as String?,
      egCanDecideHealthcare: json['eg_can_decide_healthcare'] as bool?,
      egHealthcareDetail: json['eg_healthcare_detail'] as String?,
      egCanDecideOtherPersonalService:
          json['eg_can_decide_other_personal_service'] as bool?,
      egOtherPersonalService: json['eg_other_personal_service'] as String?,
      egOtherDetail: json['eg_other_detail'] as String?,
      egCanConsentMedicalAndDental:
          json['eg_can_consent_medical_and_dental'] as bool?,
      egMedicalDetailDetail: json['eg_medical_detail_detail'] as String?,
      egHasDirections: json['eg_has_directions'] as bool?,
      egDirectionsDetail: json['eg_directions_detail'] as String?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      // ── Shared fields (ACT, NT, WA, SA, etc.) ──
      fullLegalName: json['full_legal_name'] as String?,
      residentialAddress: json['residential_address'] as String?,
      emailId: json['email_id'] as String?,
      isAdult: json['is_adult'] as bool?,
      isUnderstandEffectPoa: json['is_understand_effect_poa'] as bool?,
      isAttorneyCorporate: json['is_attorney_corporate'] as bool?,
      corporationType: json['corporation_type'] as String?,
      isAttorneyDeclaredBankrupt:
          json['is_attorney_declared_bankrupt'] as bool?,
      attorneyActRules: (json['attorney_act_rules'] ?? json['attorney_action_type']) as String?,
      attorneyPowers: (json['attorney_powers'] ?? json['delegation_power_type']) as String?,
      attorneyPowerDetail: (json['attorney_power_detail'] ?? json['delegation_powers_detail']) as String?,
      attorneyPowerMatters: (json['attorney_power_matters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['matters_covered'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      directionProperty: (json['direction_property'] ?? json['property_directions']) as String?,
      directionPersonalCare: (json['direction_personal_care'] ?? json['personal_care_directions']) as String?,
      directionHealthCare: (json['direction_health_care'] ?? json['health_care_directions']) as String?,
      directionMedicalResearch: (json['direction_medical_research'] ?? json['medical_research_directions']) as String?,
      medicalTreatmentWithdraw:
          (json['medical_treatment_withdraw'] ?? json['medical_treatment_refusal']) as String?,
      specificTreatment: json['specific_treatment'] as String?,
      attorneyPowerCommencement:
          (json['attorney_power_commencement'] ?? json['property_commencement_type']) as String?,
      attorneyPowerCommencementCircumstance:
          (json['attorney_power_commencement_circumstance'] ?? json['property_commencement_circumstance']) as String?,
      enduringPoa: (json['enduring_poa'] ?? json['prior_epa_status']) as String?,
      datePoa: json['date_poa'] as String?,
      attorneyNamePoa: json['attorney_name_poa'] as String?,
      isEpoaSign: json['is_epoa_sign'] as bool?,
      signPersonFullName: json['sign_person_full_name'] as String?,
      signPersonAddress: json['sign_person_address'] as String?,
      enduringPoaCompletionDate:
          json['enduring_poa_completion_date'] as String?,
      hasSecondDonor: json['has_second_donor'] as bool?,
      doneesActRules: json['donees_act_rules'] as String?,
      poaStartRule: json['poa_start_rule'] as String?,
      // ── Terms & instructions ──
      hasTermsInstructions: json['has_terms_instructions'] as bool?,
      termsInstructions: json['terms_instructions'] as String?,
      // ── Notification fields ──
      notifyWho: json['notify_who'] as String?,
      notifyInstructions: json['notify_instructions'] as String?,
      notifyWhatOption: json['notify_what_option'] as String?,
      notifyWhatOtherText: json['notify_what_other_text'] as String?,
      // ── WA-specific fields ──
      epaDate: (json['enduring_poa_completion_date'] ?? json['epa_date']) as String?,
      attorneyAppointmentType: json['attorney_appointment_type'] as String?,
      hasSubstitute: (json['has_substitute_attorney'] ?? json['has_substitute']) as bool?,
      substituteAppointmentType:
          (json['substitute_attorney_appointment_type'] ?? json['substitute_appointment_type']) as String?,
      substituteActsFor:
          (json['substitute_act_substitution'] ?? json['substitute_acts_for']) as String?,
      substituteWhenToAct:
          (json['substitute_act_activation'] ?? json['substitute_when_to_act']) as String?,
      hasConditionsRestrictions: json['has_conditions_restrictions'] as bool?,
      conditionsRestrictions: json['conditions_restrictions'] as String?,
      epaEffect: json['epa_effect'] as String?,
      // ── NT-specific fields ──
      isDoingVoluntarily: json['is_doing_voluntarily'] as bool?,
      numberOfDecisionMakers: json['number_of_decision_makers'] as int?,
      instructionDecisionMakers: json['instruction_decision_makers'] as String?,
      hasLandNorthernTerritory: json['has_land_northern_territory'] as bool?,
      needFinancialDecisionForLand: json['need_financial_decision_for_land'] as bool?,
    );
  }
}

// ── Generic API response wrapper ─────────────────────────────────────────────

class PoaResponse<T> extends Equatable {
  final String status;
  final String message;
  final T? data;

  const PoaResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PoaResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return PoaResponse(
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
