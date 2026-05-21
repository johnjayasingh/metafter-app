// POA DTOs — mirrors web's src/dto/poa.dto.ts exactly.
//
// Each class maps 1:1 to a backend JSON object.
// toJson() produces snake_case keys matching the API contract.
// fromJson() parses the API response back into typed Dart objects.
//
// The PowerOfAttorneyDto is the universal backend structure that all
// state-specific forms map into before sending to the API.

// ---------------------------------------------------------------------------
// Helper: only add non-null, non-empty values to JSON
// ---------------------------------------------------------------------------
void _put(Map<String, dynamic> json, String key, dynamic value) {
  if (value == null) return;
  if (value is String && value.isEmpty) return;
  json[key] = value;
}

void _putBool(Map<String, dynamic> json, String key, bool? value) {
  if (value == null) return;
  json[key] = value;
}

void _putList(Map<String, dynamic> json, String key, List<dynamic>? value) {
  if (value == null || value.isEmpty) return;
  json[key] = value;
}

// ---------------------------------------------------------------------------
// AttorneyForPoaDto (POST /user/attorney-for-poa)
// ---------------------------------------------------------------------------
class AttorneyForPoaDto {
  final String? id;
  final String fullName;
  final String address;
  final String? email;
  final String? phone;
  final String? dob;
  final String? attorneyType;
  final dynamic attorneyPoaId;
  final AttorneyOthersDto? others;

  const AttorneyForPoaDto({
    this.id,
    required this.fullName,
    required this.address,
    this.email,
    this.phone,
    this.dob,
    this.attorneyType,
    this.attorneyPoaId,
    this.others,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'id', id);
    json['full_name'] = fullName;
    json['address'] = address;
    _put(json, 'email', email);
    _put(json, 'phone', phone);
    _put(json, 'dob', dob);
    _put(json, 'attorney_type', attorneyType);
    _put(json, 'attorney_poa_id', attorneyPoaId);
    if (others != null) json['others'] = others!.toJson();
    return json;
  }

  factory AttorneyForPoaDto.fromJson(Map<String, dynamic> json) {
    return AttorneyForPoaDto(
      id: json['id']?.toString(),
      fullName: json['full_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dob: json['dob'] as String?,
      attorneyType: json['attorney_type'] as String?,
      attorneyPoaId: json['attorney_poa_id'],
      others: json['others'] != null
          ? AttorneyOthersDto.fromJson(json['others'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// AttorneyOthersDto (nested in AttorneyForPoaDto)
// ---------------------------------------------------------------------------
class AttorneyOthersDto {
  final bool? isAttorneyCorporate;
  final String? corporationType;
  final bool? isAttorneyDeclaredBankrupt;

  const AttorneyOthersDto({
    this.isAttorneyCorporate,
    this.corporationType,
    this.isAttorneyDeclaredBankrupt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _putBool(json, 'is_attorney_corporate', isAttorneyCorporate);
    _put(json, 'corporation_type', corporationType);
    _putBool(json, 'is_attorney_declared_bankrupt', isAttorneyDeclaredBankrupt);
    return json;
  }

  factory AttorneyOthersDto.fromJson(Map<String, dynamic> json) {
    return AttorneyOthersDto(
      isAttorneyCorporate: json['is_attorney_corporate'] as bool?,
      corporationType: json['corporation_type'] as String?,
      isAttorneyDeclaredBankrupt:
          json['is_attorney_declared_bankrupt'] as bool?,
    );
  }
}

// ---------------------------------------------------------------------------
// AttorneyForPoaResponseDto (GET /user/attorney-for-poa response)
// ---------------------------------------------------------------------------
class AttorneyForPoaResponseDto {
  final int attorneyPoaId;
  final String type;
  final AttorneyResponseDetailDto attorney;
  final String createdAt;

  const AttorneyForPoaResponseDto({
    required this.attorneyPoaId,
    required this.type,
    required this.attorney,
    required this.createdAt,
  });

  factory AttorneyForPoaResponseDto.fromJson(Map<String, dynamic> json) {
    return AttorneyForPoaResponseDto(
      attorneyPoaId: json['attorney_poa_id'] as int,
      type: json['type'] as String,
      attorney: AttorneyResponseDetailDto.fromJson(
          json['attorney'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String,
    );
  }
}

class AttorneyResponseDetailDto {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? dob;
  final AttorneyOthersDto? others;
  final String createdAt;

  const AttorneyResponseDetailDto({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.dob,
    this.others,
    required this.createdAt,
  });

  factory AttorneyResponseDetailDto.fromJson(Map<String, dynamic> json) {
    return AttorneyResponseDetailDto(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      dob: json['dob'] as String?,
      others: json['others'] != null
          ? AttorneyOthersDto.fromJson(json['others'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String,
    );
  }
}

// ---------------------------------------------------------------------------
// PoaNotificationDto (POST /user/poa-notification)
// ---------------------------------------------------------------------------
class PoaNotificationDto {
  final dynamic id;
  final List<String>? notifyFor;
  final String? notificationType;
  final List<Map<String, dynamic>>? attorneys;
  final String? notifyOf;
  final String? notifyOfDetail;

  const PoaNotificationDto({
    this.id,
    this.notifyFor,
    this.notificationType,
    this.attorneys,
    this.notifyOf,
    this.notifyOfDetail,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'id', id);
    _putList(json, 'notify_for', notifyFor);
    _put(json, 'notification_type', notificationType);
    _putList(json, 'attorneys', attorneys);
    _put(json, 'notify_of', notifyOf);
    _put(json, 'notify_of_detail', notifyOfDetail);
    return json;
  }

  factory PoaNotificationDto.fromJson(Map<String, dynamic> json) {
    return PoaNotificationDto(
      id: json['id'],
      notifyFor: (json['notify_for'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notificationType: json['notification_type'] as String?,
      attorneys: (json['attorneys'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      notifyOf: json['notify_of'] as String?,
      notifyOfDetail: json['notify_of_detail'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// PowerOfAttorneyDto — Universal backend structure (all states)
//
// Mirrors web's PowerOfAttorney interface exactly.
// All state-specific mappers produce this single shape.
// ---------------------------------------------------------------------------
class PowerOfAttorneyDto {
  final dynamic id;

  // --- Universal fields (NSW/QLD/VIC) ---
  final List<String>? matters;
  final String? financialCommencement;
  final String? financialDecisionForAttorney;
  final bool? hasPreference;
  final String? preferences;
  final bool? hasAttorneyInstruction;
  final String? attorneyInstruction;
  final bool? needSigningAssistance;
  final bool? hasPreviousValidPoa;
  final bool? appointSuccessiveAttorneys;
  final bool? needRevocation;
  final String? previousPoaDetail;
  final String? commencement;
  final String? specificMatters;

  // --- Conditions/Instructions (VIC) ---
  final String? clConflictTransactions;
  final String? clGifts;
  final String? clDependentMaintenance;
  final String? clPaymentsToAttorney;
  final String? clAdviseToAgents;
  final String? ciConflictTransactions;
  final String? ciGifts;
  final String? ciDependentMaintenance;
  final String? ciPaymentToAttorney;
  final String? ciAdditionalCondition;
  final bool? hasConditionsLimitations;
  final String? conditionsLimitations;
  final String? attorneyAdditionalPowers;

  // --- Enduring Guardian fields (NSW/VIC) ---
  final bool? egCanDecideLivingPlace;
  final String? egLivingPlaceDetail;
  final bool? egCanDecideServices;
  final bool? egCanDecideHealthcare;
  final String? egHealthcareDetail;
  final bool? egCanDecideOtherPersonalService;
  final String? egOtherPersonalService;
  final String? egOtherDetail;
  final bool? egCanConsentMedicalAndDental;
  final String? egMedicalDetailDetail;
  final bool? egHasDirections;
  final String? egDirectionsDetail;

  // --- South Australia specific ---
  final String? fullLegalName;
  final String? residentialAddress;
  final String? emailId;
  final bool? hasSecondDonor;
  final String? secondDonorFullName;
  final String? secondDonorResidentialAddress;
  final String? secondDonorEmail;
  final String? doneeFullName;
  final String? doneeAddress;
  final String? doneeEmail;
  final String? doneesActRules;
  final String? poaStartRule;
  final String? enduringPoaCompletionDate;

  // --- Western Australia specific ---
  final String? attorneyAppointmentType;
  final bool? hasSubstituteAttorney;
  final String? substituteAttorneyAppointmentType;
  final String? substituteActSubstitution;
  final String? substituteActActivation;
  final bool? hasConditionsRestrictions;
  final String? conditionsRestrictions;
  final String? epaEffect;

  // --- Tasmania specific ---
  final bool? isAdult;
  final bool? isUnderstandEffectPoa;
  final String? attorneyActRules;

  // --- Northern Territory specific ---
  final bool? isDoingVoluntarily;
  final int? numberOfDecisionMakers;
  final String? instructionDecisionMakers;
  final bool? hasLandNorthernTerritory;
  final bool? needFinancialDecisionForLand;

  // --- ACT specific ---
  final int? numberOfAttorneys;
  // Attorney 1
  final String? attorneyName;
  final String? attorneyAddress;
  final bool? isAttorneyCorporate;
  final String? corporationType;
  final bool? isAttorneyDeclaredBankrupt;
  // Attorney 2
  final String? attorney2Name;
  final String? attorney2Address;
  final bool? isAttorney2Corporate;
  final String? attorney2CorporationType;
  final bool? isAttorney2DeclaredBankrupt;
  // Attorney 3
  final String? attorney3Name;
  final String? attorney3Address;
  final bool? isAttorney3Corporate;
  final String? attorney3CorporationType;
  final bool? isAttorney3DeclaredBankrupt;
  final String? attorneyPowers;
  final String? attorneyPowerDetail;
  final List<String>? attorneyPowerMatters;
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

  const PowerOfAttorneyDto({
    this.id,
    // Universal
    this.matters,
    this.financialCommencement,
    this.financialDecisionForAttorney,
    this.hasPreference,
    this.preferences,
    this.hasAttorneyInstruction,
    this.attorneyInstruction,
    this.needSigningAssistance,
    this.hasPreviousValidPoa,
    this.appointSuccessiveAttorneys,
    this.needRevocation,
    this.previousPoaDetail,
    this.commencement,
    this.specificMatters,
    // VIC conditions
    this.clConflictTransactions,
    this.clGifts,
    this.clDependentMaintenance,
    this.clPaymentsToAttorney,
    this.clAdviseToAgents,
    this.ciConflictTransactions,
    this.ciGifts,
    this.ciDependentMaintenance,
    this.ciPaymentToAttorney,
    this.ciAdditionalCondition,
    this.hasConditionsLimitations,
    this.conditionsLimitations,
    this.attorneyAdditionalPowers,
    // Enduring guardian
    this.egCanDecideLivingPlace,
    this.egLivingPlaceDetail,
    this.egCanDecideServices,
    this.egCanDecideHealthcare,
    this.egHealthcareDetail,
    this.egCanDecideOtherPersonalService,
    this.egOtherPersonalService,
    this.egOtherDetail,
    this.egCanConsentMedicalAndDental,
    this.egMedicalDetailDetail,
    this.egHasDirections,
    this.egDirectionsDetail,
    // SA
    this.fullLegalName,
    this.residentialAddress,
    this.emailId,
    this.hasSecondDonor,
    this.secondDonorFullName,
    this.secondDonorResidentialAddress,
    this.secondDonorEmail,
    this.doneeFullName,
    this.doneeAddress,
    this.doneeEmail,
    this.doneesActRules,
    this.poaStartRule,
    this.enduringPoaCompletionDate,
    // WA
    this.attorneyAppointmentType,
    this.hasSubstituteAttorney,
    this.substituteAttorneyAppointmentType,
    this.substituteActSubstitution,
    this.substituteActActivation,
    this.hasConditionsRestrictions,
    this.conditionsRestrictions,
    this.epaEffect,
    // TAS
    this.isAdult,
    this.isUnderstandEffectPoa,
    this.attorneyActRules,
    // NT
    this.isDoingVoluntarily,
    this.numberOfDecisionMakers,
    this.instructionDecisionMakers,
    this.hasLandNorthernTerritory,
    this.needFinancialDecisionForLand,
    // ACT
    this.numberOfAttorneys,
    this.attorneyName,
    this.attorneyAddress,
    this.isAttorneyCorporate,
    this.corporationType,
    this.isAttorneyDeclaredBankrupt,
    this.attorney2Name,
    this.attorney2Address,
    this.isAttorney2Corporate,
    this.attorney2CorporationType,
    this.isAttorney2DeclaredBankrupt,
    this.attorney3Name,
    this.attorney3Address,
    this.isAttorney3Corporate,
    this.attorney3CorporationType,
    this.isAttorney3DeclaredBankrupt,
    this.attorneyPowers,
    this.attorneyPowerDetail,
    this.attorneyPowerMatters,
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
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    _put(json, 'id', id);

    // Universal
    _putList(json, 'matters', matters);
    _put(json, 'financial_commencement', financialCommencement);
    _put(json, 'financial_decision_for_attorney', financialDecisionForAttorney);
    _putBool(json, 'has_preference', hasPreference);
    _put(json, 'preferences', preferences);
    _putBool(json, 'has_attorney_instruction', hasAttorneyInstruction);
    _put(json, 'attorney_instruction', attorneyInstruction);
    _putBool(json, 'need_signing_assistance', needSigningAssistance);
    _putBool(json, 'has_previous_valid_poa', hasPreviousValidPoa);
    _putBool(json, 'appoint_successive_attorneys', appointSuccessiveAttorneys);
    _putBool(json, 'need_revocation', needRevocation);
    _put(json, 'previous_poa_detail', previousPoaDetail);
    _put(json, 'commencement', commencement);
    _put(json, 'specific_matters', specificMatters);

    // VIC conditions
    _put(json, 'cl_conflict_transactions', clConflictTransactions);
    _put(json, 'cl_gifts', clGifts);
    _put(json, 'cl_dependent_maintenance', clDependentMaintenance);
    _put(json, 'cl_payments_to_attorney', clPaymentsToAttorney);
    _put(json, 'cl_advise_to_agents', clAdviseToAgents);
    _put(json, 'ci_conflict_transactions', ciConflictTransactions);
    _put(json, 'ci_gifts', ciGifts);
    _put(json, 'ci_dependent_maintenance', ciDependentMaintenance);
    _put(json, 'ci_payment_to_attorney', ciPaymentToAttorney);
    _put(json, 'ci_additional_condition', ciAdditionalCondition);
    _putBool(json, 'has_conditions_limitations', hasConditionsLimitations);
    _put(json, 'conditions_limitations', conditionsLimitations);
    _put(json, 'attorney_additional_powers', attorneyAdditionalPowers);

    // Enduring guardian
    _putBool(json, 'eg_can_decide_living_place', egCanDecideLivingPlace);
    _put(json, 'eg_living_place_detail', egLivingPlaceDetail);
    _putBool(json, 'eg_can_decide_services', egCanDecideServices);
    _putBool(json, 'eg_can_decide_healthcare', egCanDecideHealthcare);
    _put(json, 'eg_healthcare_detail', egHealthcareDetail);
    _putBool(json, 'eg_can_decide_other_personal_service',
        egCanDecideOtherPersonalService);
    _put(json, 'eg_other_personal_service', egOtherPersonalService);
    _put(json, 'eg_other_detail', egOtherDetail);
    _putBool(
        json, 'eg_can_consent_medical_and_dental', egCanConsentMedicalAndDental);
    _put(json, 'eg_medical_detail_detail', egMedicalDetailDetail);
    _putBool(json, 'eg_has_directions', egHasDirections);
    _put(json, 'eg_directions_detail', egDirectionsDetail);

    // SA
    _put(json, 'full_legal_name', fullLegalName);
    _put(json, 'residential_address', residentialAddress);
    _put(json, 'email_id', emailId);
    _putBool(json, 'has_second_donor', hasSecondDonor);
    _put(json, 'second_donor_full_name', secondDonorFullName);
    _put(json, 'second_donor_residential_address',
        secondDonorResidentialAddress);
    _put(json, 'second_donor_email', secondDonorEmail);
    _put(json, 'donee_full_name', doneeFullName);
    _put(json, 'donee_address', doneeAddress);
    _put(json, 'donee_email', doneeEmail);
    _put(json, 'donees_act_rules', doneesActRules);
    _put(json, 'poa_start_rule', poaStartRule);
    _put(json, 'enduring_poa_completion_date', enduringPoaCompletionDate);

    // WA
    _put(json, 'attorney_appointment_type', attorneyAppointmentType);
    _putBool(json, 'has_substitute_attorney', hasSubstituteAttorney);
    _put(json, 'substitute_attorney_appointment_type',
        substituteAttorneyAppointmentType);
    _put(json, 'substitute_act_substitution', substituteActSubstitution);
    _put(json, 'substitute_act_activation', substituteActActivation);
    _putBool(json, 'has_conditions_restrictions', hasConditionsRestrictions);
    _put(json, 'conditions_restrictions', conditionsRestrictions);
    _put(json, 'epa_effect', epaEffect);

    // TAS
    _putBool(json, 'is_adult', isAdult);
    _putBool(json, 'is_understand_effect_poa', isUnderstandEffectPoa);
    _put(json, 'attorney_act_rules', attorneyActRules);

    // NT
    _putBool(json, 'is_doing_voluntarily', isDoingVoluntarily);
    _put(json, 'number_of_decision_makers', numberOfDecisionMakers);
    _put(json, 'instruction_decision_makers', instructionDecisionMakers);
    _putBool(json, 'has_land_northern_territory', hasLandNorthernTerritory);
    _putBool(
        json, 'need_financial_decision_for_land', needFinancialDecisionForLand);

    // ACT
    _put(json, 'number_of_attorneys', numberOfAttorneys);
    _put(json, 'attorney_name', attorneyName);
    _put(json, 'attorney_address', attorneyAddress);
    _putBool(json, 'is_attorney_corporate', isAttorneyCorporate);
    _put(json, 'corporation_type', corporationType);
    _putBool(json, 'is_attorney_declared_bankrupt', isAttorneyDeclaredBankrupt);
    _put(json, 'attorney_2_name', attorney2Name);
    _put(json, 'attorney_2_address', attorney2Address);
    _putBool(json, 'is_attorney_2_corporate', isAttorney2Corporate);
    _put(json, 'attorney_2_corporation_type', attorney2CorporationType);
    _putBool(
        json, 'is_attorney_2_declared_bankrupt', isAttorney2DeclaredBankrupt);
    _put(json, 'attorney_3_name', attorney3Name);
    _put(json, 'attorney_3_address', attorney3Address);
    _putBool(json, 'is_attorney_3_corporate', isAttorney3Corporate);
    _put(json, 'attorney_3_corporation_type', attorney3CorporationType);
    _putBool(
        json, 'is_attorney_3_declared_bankrupt', isAttorney3DeclaredBankrupt);
    _put(json, 'attorney_powers', attorneyPowers);
    _put(json, 'attorney_power_detail', attorneyPowerDetail);
    _putList(json, 'attorney_power_matters', attorneyPowerMatters);
    _put(json, 'direction_property', directionProperty);
    _put(json, 'direction_personal_care', directionPersonalCare);
    _put(json, 'direction_health_care', directionHealthCare);
    _put(json, 'direction_medical_research', directionMedicalResearch);
    _put(json, 'medical_treatment_withdraw', medicalTreatmentWithdraw);
    _put(json, 'specific_treatment', specificTreatment);
    _put(json, 'attorney_power_commencement', attorneyPowerCommencement);
    _put(json, 'attorney_power_commencement_circumstance',
        attorneyPowerCommencementCircumstance);
    _put(json, 'enduring_poa', enduringPoa);
    _put(json, 'date_poa', datePoa);
    _put(json, 'attorney_name_poa', attorneyNamePoa);
    _putBool(json, 'is_epoa_sign', isEpoaSign);
    _put(json, 'sign_person_full_name', signPersonFullName);
    _put(json, 'sign_person_address', signPersonAddress);

    return json;
  }

  factory PowerOfAttorneyDto.fromJson(Map<String, dynamic> json) {
    return PowerOfAttorneyDto(
      id: json['id'],
      // Universal
      matters: (json['matters'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      financialCommencement: json['financial_commencement'] as String?,
      financialDecisionForAttorney:
          json['financial_decision_for_attorney'] as String?,
      hasPreference: json['has_preference'] as bool?,
      preferences: json['preferences'] as String?,
      hasAttorneyInstruction: json['has_attorney_instruction'] as bool?,
      attorneyInstruction: json['attorney_instruction'] as String?,
      needSigningAssistance: json['need_signing_assistance'] as bool?,
      hasPreviousValidPoa: json['has_previous_valid_poa'] as bool?,
      appointSuccessiveAttorneys:
          json['appoint_successive_attorneys'] as bool?,
      needRevocation: json['need_revocation'] as bool?,
      previousPoaDetail: json['previous_poa_detail'] as String?,
      commencement: json['commencement'] as String?,
      specificMatters: json['specific_matters'] as String?,
      // VIC conditions
      clConflictTransactions: json['cl_conflict_transactions'] as String?,
      clGifts: json['cl_gifts'] as String?,
      clDependentMaintenance: json['cl_dependent_maintenance'] as String?,
      clPaymentsToAttorney: json['cl_payments_to_attorney'] as String?,
      clAdviseToAgents: json['cl_advise_to_agents'] as String?,
      ciConflictTransactions: json['ci_conflict_transactions'] as String?,
      ciGifts: json['ci_gifts'] as String?,
      ciDependentMaintenance: json['ci_dependent_maintenance'] as String?,
      ciPaymentToAttorney: json['ci_payment_to_attorney'] as String?,
      ciAdditionalCondition: json['ci_additional_condition'] as String?,
      hasConditionsLimitations: json['has_conditions_limitations'] as bool?,
      conditionsLimitations: json['conditions_limitations'] as String?,
      attorneyAdditionalPowers:
          json['attorney_additional_powers'] as String?,
      // Enduring guardian
      egCanDecideLivingPlace:
          json['eg_can_decide_living_place'] as bool?,
      egLivingPlaceDetail: json['eg_living_place_detail'] as String?,
      egCanDecideServices: json['eg_can_decide_services'] as bool?,
      egCanDecideHealthcare: json['eg_can_decide_healthcare'] as bool?,
      egHealthcareDetail: json['eg_healthcare_detail'] as String?,
      egCanDecideOtherPersonalService:
          json['eg_can_decide_other_personal_service'] as bool?,
      egOtherPersonalService:
          json['eg_other_personal_service'] as String?,
      egOtherDetail: json['eg_other_detail'] as String?,
      egCanConsentMedicalAndDental:
          json['eg_can_consent_medical_and_dental'] as bool?,
      egMedicalDetailDetail:
          json['eg_medical_detail_detail'] as String?,
      egHasDirections: json['eg_has_directions'] as bool?,
      egDirectionsDetail: json['eg_directions_detail'] as String?,
      // SA
      fullLegalName: json['full_legal_name'] as String?,
      residentialAddress: json['residential_address'] as String?,
      emailId: json['email_id'] as String?,
      hasSecondDonor: json['has_second_donor'] as bool?,
      secondDonorFullName: json['second_donor_full_name'] as String?,
      secondDonorResidentialAddress:
          json['second_donor_residential_address'] as String?,
      secondDonorEmail: json['second_donor_email'] as String?,
      doneeFullName: json['donee_full_name'] as String?,
      doneeAddress: json['donee_address'] as String?,
      doneeEmail: json['donee_email'] as String?,
      doneesActRules: json['donees_act_rules'] as String?,
      poaStartRule: json['poa_start_rule'] as String?,
      enduringPoaCompletionDate:
          json['enduring_poa_completion_date'] as String?,
      // WA
      attorneyAppointmentType:
          json['attorney_appointment_type'] as String?,
      hasSubstituteAttorney: json['has_substitute_attorney'] as bool?,
      substituteAttorneyAppointmentType:
          json['substitute_attorney_appointment_type'] as String?,
      substituteActSubstitution:
          json['substitute_act_substitution'] as String?,
      substituteActActivation:
          json['substitute_act_activation'] as String?,
      hasConditionsRestrictions:
          json['has_conditions_restrictions'] as bool?,
      conditionsRestrictions: json['conditions_restrictions'] as String?,
      epaEffect: json['epa_effect'] as String?,
      // TAS
      isAdult: json['is_adult'] as bool?,
      isUnderstandEffectPoa: json['is_understand_effect_poa'] as bool?,
      attorneyActRules: json['attorney_act_rules'] as String?,
      // NT
      isDoingVoluntarily: json['is_doing_voluntarily'] as bool?,
      numberOfDecisionMakers: json['number_of_decision_makers'] as int?,
      instructionDecisionMakers:
          json['instruction_decision_makers'] as String?,
      hasLandNorthernTerritory:
          json['has_land_northern_territory'] as bool?,
      needFinancialDecisionForLand:
          json['need_financial_decision_for_land'] as bool?,
      // ACT
      numberOfAttorneys: json['number_of_attorneys'] as int?,
      attorneyName: json['attorney_name'] as String?,
      attorneyAddress: json['attorney_address'] as String?,
      isAttorneyCorporate: json['is_attorney_corporate'] as bool?,
      corporationType: json['corporation_type'] as String?,
      isAttorneyDeclaredBankrupt:
          json['is_attorney_declared_bankrupt'] as bool?,
      attorney2Name: json['attorney_2_name'] as String?,
      attorney2Address: json['attorney_2_address'] as String?,
      isAttorney2Corporate: json['is_attorney_2_corporate'] as bool?,
      attorney2CorporationType:
          json['attorney_2_corporation_type'] as String?,
      isAttorney2DeclaredBankrupt:
          json['is_attorney_2_declared_bankrupt'] as bool?,
      attorney3Name: json['attorney_3_name'] as String?,
      attorney3Address: json['attorney_3_address'] as String?,
      isAttorney3Corporate: json['is_attorney_3_corporate'] as bool?,
      attorney3CorporationType:
          json['attorney_3_corporation_type'] as String?,
      isAttorney3DeclaredBankrupt:
          json['is_attorney_3_declared_bankrupt'] as bool?,
      attorneyPowers: json['attorney_powers'] as String?,
      attorneyPowerDetail: json['attorney_power_detail'] as String?,
      attorneyPowerMatters: (json['attorney_power_matters'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      directionProperty: json['direction_property'] as String?,
      directionPersonalCare: json['direction_personal_care'] as String?,
      directionHealthCare: json['direction_health_care'] as String?,
      directionMedicalResearch:
          json['direction_medical_research'] as String?,
      medicalTreatmentWithdraw:
          json['medical_treatment_withdraw'] as String?,
      specificTreatment: json['specific_treatment'] as String?,
      attorneyPowerCommencement:
          json['attorney_power_commencement'] as String?,
      attorneyPowerCommencementCircumstance:
          json['attorney_power_commencement_circumstance'] as String?,
      enduringPoa: json['enduring_poa'] as String?,
      datePoa: json['date_poa'] as String?,
      attorneyNamePoa: json['attorney_name_poa'] as String?,
      isEpoaSign: json['is_epoa_sign'] as bool?,
      signPersonFullName: json['sign_person_full_name'] as String?,
      signPersonAddress: json['sign_person_address'] as String?,
    );
  }
}

// ===========================================================================
// State-specific mapper factories
//
// These mirror the web's poaMapper.ts functions exactly.
// Each takes state-specific UI data and produces a PowerOfAttorneyDto
// with the correct backend field mappings.
// ===========================================================================

// ---------------------------------------------------------------------------
// ACT mapper — mirrors mapACTPOAToBackend()
// ---------------------------------------------------------------------------
class ActPoaMapper {
  static PowerOfAttorneyDto toBackend({
    required bool? is18OrOlder,
    required bool? understandsSigningFreely,
    required String fullName,
    required String address,
    required String email,
    required int numberOfAttorneys,
    required String attorneyName,
    required String attorneyAddress,
    bool? isAttorneyCorporation,
    String? corporationType,
    bool? isAttorneyBankrupt,
    String? attorney2Name,
    String? attorney2Address,
    bool? isAttorney2Corporation,
    String? attorney2CorporationType,
    bool? isAttorney2Bankrupt,
    String? attorney3Name,
    String? attorney3Address,
    bool? isAttorney3Corporation,
    String? attorney3CorporationType,
    bool? isAttorney3Bankrupt,
    String? attorneyActionType,
    required String delegationPowerType,
    String? delegationPowersDetail,
    required List<String> mattersCovered,
    String? propertyDirections,
    String? personalCareDirections,
    String? healthCareDirections,
    String? medicalResearchDirections,
    String? medicalTreatmentRefusal,
    String? medicalTreatmentSpecific,
    required String propertyCommencementType,
    String? propertyCommencementCircumstance,
    required String priorEpaStatus,
    String? priorEpaContinueDetail,
    String? priorEpaDate,
    String? priorEpaAttorneyName,
    bool? signingMyself,
    String? directedSignerName,
    String? directedSignerAddress,
  }) {
    return PowerOfAttorneyDto(
      isAdult: is18OrOlder,
      isUnderstandEffectPoa: understandsSigningFreely,
      fullLegalName: fullName,
      residentialAddress: address,
      emailId: email,
      numberOfAttorneys: numberOfAttorneys,
      // Attorney 1
      attorneyName: attorneyName,
      attorneyAddress: attorneyAddress,
      isAttorneyCorporate: isAttorneyCorporation,
      corporationType: isAttorneyCorporation == true && corporationType != null
          ? _mapActCorporationType(corporationType)
          : null,
      isAttorneyDeclaredBankrupt: isAttorneyBankrupt,
      // Attorney 2
      attorney2Name: attorney2Name,
      attorney2Address: attorney2Address,
      isAttorney2Corporate: isAttorney2Corporation,
      attorney2CorporationType:
          isAttorney2Corporation == true && attorney2CorporationType != null
              ? _mapActCorporationType(attorney2CorporationType)
              : null,
      isAttorney2DeclaredBankrupt: isAttorney2Bankrupt,
      // Attorney 3
      attorney3Name: attorney3Name,
      attorney3Address: attorney3Address,
      isAttorney3Corporate: isAttorney3Corporation,
      attorney3CorporationType:
          isAttorney3Corporation == true && attorney3CorporationType != null
              ? _mapActCorporationType(attorney3CorporationType)
              : null,
      isAttorney3DeclaredBankrupt: isAttorney3Bankrupt,
      // Attorney action
      attorneyActRules: attorneyActionType != null
          ? _mapActAttorneyAction(attorneyActionType)
          : null,
      // Delegation
      attorneyPowers: _mapActDelegation(delegationPowerType),
      attorneyPowerDetail: delegationPowersDetail,
      // Matters
      attorneyPowerMatters: mattersCovered.isNotEmpty
          ? mattersCovered
              .map((m) => m.toUpperCase().replaceAll('_', '_'))
              .toList()
          : null,
      // Directions
      directionProperty: propertyDirections,
      directionPersonalCare: personalCareDirections,
      directionHealthCare: healthCareDirections,
      directionMedicalResearch: medicalResearchDirections,
      // Medical treatment
      medicalTreatmentWithdraw: medicalTreatmentRefusal != null
          ? _mapActMedicalTreatment(medicalTreatmentRefusal)
          : null,
      specificTreatment: medicalTreatmentSpecific,
      // Property commencement
      attorneyPowerCommencement:
          _mapActPropertyCommencement(propertyCommencementType),
      attorneyPowerCommencementCircumstance: propertyCommencementCircumstance,
      // Prior EPA
      enduringPoa: _mapActPriorEpa(priorEpaStatus),
      previousPoaDetail: priorEpaContinueDetail,
      datePoa: priorEpaDate,
      attorneyNamePoa: priorEpaAttorneyName,
      // Signing
      isEpoaSign: signingMyself,
      signPersonFullName: directedSignerName,
      signPersonAddress: directedSignerAddress,
    );
  }

  // ACT UI → backend mappers (match web's poaMapper.ts helper functions)
  static String _mapActCorporationType(String type) {
    const mapping = {
      'public_trustee_guardian': 'PUBLIC_TRUSTEE',
      'trustee_company': 'TRUSTEE_COMPANY',
      'others': 'OTHERS',
    };
    return mapping[type] ?? 'OTHERS';
  }

  static String _mapActAttorneyAction(String type) {
    const mapping = {
      'together': 'JOINTLY',
      'separately': 'JOINTLY_SEVERALLY',
    };
    return mapping[type] ?? 'JOINTLY';
  }

  static String _mapActDelegation(String type) {
    const mapping = {
      'no_delegation': 'NO_DELEGATION',
      'delegation_all_powers': 'ALL_POWERS',
      'delegate_some_powers': 'SOME_POWERS',
    };
    return mapping[type] ?? 'NO_DELEGATION';
  }

  static String _mapActMedicalTreatment(String type) {
    const mapping = {
      'not_allowed': 'NOT_ALLOWED',
      'allowed_generally': 'ALLOWED_GENERALLY',
      'allowed_specific': 'ALLOWED_SPECIFIC',
    };
    return mapping[type] ?? 'NOT_ALLOWED';
  }

  static String _mapActPropertyCommencement(String type) {
    const mapping = {
      'immediately': 'IMMEDIATELY',
      'from_date_or_event': 'FROM_DATE_EVENT',
      'only_when_impaired_capacity': 'IMPAIRED_CAPACITY',
    };
    return mapping[type] ?? 'IMMEDIATELY';
  }

  static String _mapActPriorEpa(String status) {
    const mapping = {
      'none_previous': 'NONE',
      'revoke_all_previous': 'REVOKE_ALL_PREVIOUS',
      'some_continue': 'SOME_CONTINUE',
    };
    return mapping[status] ?? 'NONE';
  }

  // Reverse mappers (backend → ACT UI)
  static String mapCorporationTypeToUi(String type) {
    const mapping = {
      'PUBLIC_TRUSTEE': 'public_trustee_guardian',
      'TRUSTEE_COMPANY': 'trustee_company',
      'OTHERS': 'others',
    };
    return mapping[type] ?? 'others';
  }

  static String mapAttorneyActionToUi(String type) {
    const mapping = {
      'JOINTLY': 'together',
      'JOINTLY_SEVERALLY': 'separately',
    };
    return mapping[type] ?? 'together';
  }

  static String mapDelegationToUi(String type) {
    const mapping = {
      'NO_DELEGATION': 'no_delegation',
      'ALL_POWERS': 'delegation_all_powers',
      'SOME_POWERS': 'delegate_some_powers',
    };
    return mapping[type] ?? 'no_delegation';
  }

  static String mapMedicalTreatmentToUi(String type) {
    const mapping = {
      'NOT_ALLOWED': 'not_allowed',
      'ALLOWED_GENERALLY': 'allowed_generally',
      'ALLOWED_SPECIFIC': 'allowed_specific',
    };
    return mapping[type] ?? 'not_allowed';
  }

  static String mapPropertyCommencementToUi(String type) {
    const mapping = {
      'IMMEDIATELY': 'immediately',
      'FROM_DATE_EVENT': 'from_date_or_event',
      'IMPAIRED_CAPACITY': 'only_when_impaired_capacity',
    };
    return mapping[type] ?? 'immediately';
  }

  static String mapPriorEpaToUi(String status) {
    const mapping = {
      'NONE': 'none_previous',
      'REVOKE_ALL_PREVIOUS': 'revoke_all_previous',
      'SOME_CONTINUE': 'some_continue',
    };
    return mapping[status] ?? 'none_previous';
  }
}

// ---------------------------------------------------------------------------
// South Australia mapper — mirrors mapSouthAustraliaPOAToBackend()
// ---------------------------------------------------------------------------
class SaPoaMapper {
  static PowerOfAttorneyDto toBackend({
    required String fullName,
    required String residentialAddress,
    required String email,
    bool? hasSecondDonor,
    String? doneeActionType,
    required String commencementType,
    bool? hasConditions,
    String? conditionsDetail,
  }) {
    return PowerOfAttorneyDto(
      fullLegalName: fullName,
      residentialAddress: residentialAddress,
      emailId: email,
      hasSecondDonor: hasSecondDonor,
      doneesActRules: doneeActionType != null
          ? _mapDoneeAction(doneeActionType)
          : null,
      poaStartRule: _mapCommencement(commencementType),
      hasConditionsLimitations: hasConditions,
      conditionsLimitations: conditionsDetail,
    );
  }

  static String _mapDoneeAction(String type) {
    const mapping = {
      'jointly': 'JOINTLY',
      'jointly_and_severally': 'JOINTLY_SEVERALLY',
    };
    return mapping[type] ?? 'JOINTLY';
  }

  static String _mapCommencement(String type) {
    const mapping = {
      'upon_execution': 'IMMEDIATELY',
      'only_on_legal_incapacity': 'LEGAL_INCAPACITY',
    };
    return mapping[type] ?? 'IMMEDIATELY';
  }

  // Reverse mappers
  static String mapDoneeActionToUi(String type) {
    const mapping = {
      'JOINTLY': 'JOINTLY',
      'JOINTLY_SEVERALLY': 'JOINTLY_SEVERALLY',
    };
    return mapping[type] ?? 'jointly';
  }

  static String mapCommencementToUi(String type) {
    const mapping = {
      'IMMEDIATELY': 'upon_execution',
      'LEGAL_INCAPACITY': 'only_on_legal_incapacity',
    };
    return mapping[type] ?? 'upon_execution';
  }
}

// ---------------------------------------------------------------------------
// Tasmania mapper — mirrors mapTasmaniaPOAToBackend()
// ---------------------------------------------------------------------------
class TasPoaMapper {
  static PowerOfAttorneyDto toBackend({
    required bool? is18OrOlder,
    required bool? understandsEpa,
    required String fullName,
    required String residentialAddress,
    required String email,
    String? completionDate,
    String? attorneyActionType,
    bool? hasConditions,
    String? conditionsDetail,
  }) {
    return PowerOfAttorneyDto(
      isAdult: is18OrOlder,
      isUnderstandEffectPoa: understandsEpa,
      fullLegalName: fullName,
      residentialAddress: residentialAddress,
      emailId: email,
      enduringPoaCompletionDate: completionDate,
      attorneyActRules: attorneyActionType != null
          ? _mapAttorneyAction(attorneyActionType)
          : null,
      hasConditionsLimitations: hasConditions,
      conditionsLimitations: conditionsDetail,
    );
  }

  static String _mapAttorneyAction(String type) {
    const mapping = {
      'JOINTLY': 'JOINTLY',
      'JOINTLY_SEVERALLY': 'JOINTLY_SEVERALLY',
    };
    return mapping[type] ?? 'JOINTLY';
  }

  // Reverse mapper
  static String mapAttorneyActionToUi(String type) {
    const mapping = {
      'JOINTLY': 'JOINTLY',
      'JOINTLY_SEVERALLY': 'JOINTLY_SEVERALLY',
    };
    return mapping[type] ?? 'JOINTLY';
  }
}

// ---------------------------------------------------------------------------
// Western Australia mapper — mirrors mapWesternAustraliaPOAToBackend()
// ---------------------------------------------------------------------------
class WaPoaMapper {
  static PowerOfAttorneyDto toBackend({
    required String fullName,
    required String residentialAddress,
    required String email,
    String? completionDate,
    required String attorneyAppointmentType,
    bool? hasSubstituteAttorney,
    String? substituteAppointmentType,
    String? substitutionFor,
    String? substitutionEvent,
    bool? hasConditions,
    String? conditionsDetail,
    required String commencementType,
  }) {
    return PowerOfAttorneyDto(
      fullLegalName: fullName,
      residentialAddress: residentialAddress,
      emailId: email,
      enduringPoaCompletionDate: completionDate,
      attorneyAppointmentType:
          _mapAppointmentType(attorneyAppointmentType),
      hasSubstituteAttorney: hasSubstituteAttorney,
      substituteAttorneyAppointmentType: substituteAppointmentType != null
          ? _mapSubstituteAppointmentType(substituteAppointmentType)
          : null,
      substituteActSubstitution: substitutionFor != null
          ? _mapSubstitutionFor(substitutionFor)
          : null,
      substituteActActivation: substitutionEvent,
      hasConditionsRestrictions: hasConditions,
      conditionsRestrictions: conditionsDetail,
      epaEffect: _mapCommencement(commencementType),
    );
  }

  static String _mapAppointmentType(String type) {
    const mapping = {
      'sole': 'SOLO',
      'joint': 'JOINT',
      'joint_and_several': 'JOINT_SEVERAL',
    };
    return mapping[type] ?? 'SOLO';
  }

  static String _mapSubstituteAppointmentType(String type) {
    const mapping = {
      'sole_substitute': 'SOLO',
      'joint_substitute': 'JOINT',
      'joint_and_several_substitutes': 'JOINT_SEVERAL',
    };
    return mapping[type] ?? 'SOLO';
  }

  static String _mapSubstitutionFor(String type) {
    const mapping = {
      'attorney_1_only': 'ATTORNEY_1',
      'attorney_2_only': 'ATTORNEY_2',
      'attorney_1_and_2': 'BOTH',
    };
    return mapping[type] ?? 'ATTORNEY_1';
  }

  static String _mapCommencement(String type) {
    const mapping = {
      'immediately': 'IMMEDIATELY',
      'only_when_declaration': 'DECLARATION_IN_FORCE',
    };
    return mapping[type] ?? 'IMMEDIATELY';
  }

  // Reverse mappers
  static String mapAppointmentTypeToUi(String type) {
    const mapping = {
      'SOLO': 'sole',
      'JOINT': 'joint',
      'JOINT_SEVERAL': 'joint_and_several',
    };
    return mapping[type] ?? 'sole';
  }

  static String mapCommencementToUi(String type) {
    const mapping = {
      'IMMEDIATELY': 'immediately',
      'DECLARATION_IN_FORCE': 'only_when_declaration',
    };
    return mapping[type] ?? 'immediately';
  }

  static String mapSubstitutionForToUi(String type) {
    const mapping = {
      'ATTORNEY_1': 'attorney_1_only',
      'ATTORNEY_2': 'attorney_2_only',
      'BOTH': 'attorney_1_and_2',
    };
    return mapping[type] ?? 'attorney_1_only';
  }

  static String mapSubstituteAppointmentTypeToUi(String type) {
    const mapping = {
      'SOLO': 'sole_substitute',
      'JOINT': 'joint_substitute',
      'JOINT_SEVERAL': 'joint_and_several_substitutes',
    };
    return mapping[type] ?? 'sole_substitute';
  }
}

// ---------------------------------------------------------------------------
// Northern Territory mapper — mirrors mapNorthernTerritoryPOAToBackend()
// ---------------------------------------------------------------------------
class NtPoaMapper {
  static PowerOfAttorneyDto toBackend({
    required bool? is18OrOlder,
    required bool? understandsPlanFreely,
    required String fullName,
    required String residentialAddress,
    required String dob,
    required int numberOfDecisionMakers,
    String? decisionMakerActionType,
    String? financialLimitsInstructions,
    bool? ownsNtLand,
    bool? allowLandDealings,
  }) {
    return PowerOfAttorneyDto(
      isAdult: is18OrOlder,
      isDoingVoluntarily: understandsPlanFreely,
      fullLegalName: fullName,
      residentialAddress: residentialAddress,
      // NOTE: Web maps dob into email_id field for NT
      emailId: dob,
      numberOfDecisionMakers: numberOfDecisionMakers,
      attorneyActRules: decisionMakerActionType,
      instructionDecisionMakers: financialLimitsInstructions,
      hasLandNorthernTerritory: ownsNtLand,
      needFinancialDecisionForLand: allowLandDealings,
    );
  }
}
