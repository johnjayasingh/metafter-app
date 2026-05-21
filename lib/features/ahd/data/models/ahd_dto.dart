// AHD DTOs — mirrors web's src/dto/ahd.dto.ts exactly.
//
// Each class maps 1:1 to a backend JSON object.
// toJson() produces snake_case keys matching the API contract.
// fromJson() parses the API response back into typed Dart objects.

// ---------------------------------------------------------------------------
// DirectionAboutOtherHealthcare (top-level array items)
// ---------------------------------------------------------------------------
class DirectionAboutOtherHealthcareDto {
  final String? id;
  final String? healthCondition;
  final String? healthDirection;

  const DirectionAboutOtherHealthcareDto({
    this.id,
    this.healthCondition,
    this.healthDirection,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (id != null) json['id'] = id;
    if (healthCondition != null) json['health_condition'] = healthCondition;
    if (healthDirection != null) json['health_direction'] = healthDirection;
    return json;
  }

  factory DirectionAboutOtherHealthcareDto.fromJson(Map<String, dynamic> json) {
    return DirectionAboutOtherHealthcareDto(
      id: json['id'] as String?,
      healthCondition: json['health_condition'] as String?,
      healthDirection: json['health_direction'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// HealthConditionsDTO
// ---------------------------------------------------------------------------
class HealthConditionsDto {
  final String? majorHealthConditions;
  final String? thingsImportantForMe;
  final String? believesConsideredDuringHealthCare;
  final String? nearingDeathPreference;
  final String? peopleNotToInvolveHealthcareDiscussion;
  final List<String>? comfortNearingDeath;

  const HealthConditionsDto({
    this.majorHealthConditions,
    this.thingsImportantForMe,
    this.believesConsideredDuringHealthCare,
    this.nearingDeathPreference,
    this.peopleNotToInvolveHealthcareDiscussion,
    this.comfortNearingDeath,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'major_health_conditions', majorHealthConditions);
    _put(json, 'things_important_for_me', thingsImportantForMe);
    _put(json, 'beliefs_considered_during_health_care', believesConsideredDuringHealthCare);
    _put(json, 'nearing_death_preference', nearingDeathPreference);
    _put(json, 'people_not_to_involve_healthcare_discussion', peopleNotToInvolveHealthcareDiscussion);
    if (comfortNearingDeath != null && comfortNearingDeath!.isNotEmpty) {
      json['comfort_nearing_death'] = comfortNearingDeath;
    }
    return json;
  }

  factory HealthConditionsDto.fromJson(Map<String, dynamic> json) {
    return HealthConditionsDto(
      majorHealthConditions: json['major_health_conditions'] as String?,
      thingsImportantForMe: json['things_important_for_me'] as String?,
      believesConsideredDuringHealthCare: json['beliefs_considered_during_health_care'] as String?,
      nearingDeathPreference: json['nearing_death_preference'] as String?,
      peopleNotToInvolveHealthcareDiscussion: json['people_not_to_involve_healthcare_discussion'] as String?,
      comfortNearingDeath: (json['comfort_nearing_death'] as List<dynamic>?)
          ?.cast<String>(),
    );
  }
}

// ---------------------------------------------------------------------------
// LifeSustainingTreatmentDTO
// ---------------------------------------------------------------------------
class LifeSustainingTreatmentDto {
  final String? directionType;
  final String? directionInstruction;
  final String? treatmentType;
  final String? treatmentInstruction;
  final String? assistedVentilation;
  final String? assistedVentilationInstruction;
  final String? artificialNutrition;
  final String? artificialNutritionInstruction;
  final String? antibiotics;
  final String? antibioticsInstruction;
  final String? bloodTransfusion;
  final String? bloodTransfusionInstruction;
  final String? otherTreatment;
  final String? otherInstruction;

  const LifeSustainingTreatmentDto({
    this.directionType,
    this.directionInstruction,
    this.treatmentType,
    this.treatmentInstruction,
    this.assistedVentilation,
    this.assistedVentilationInstruction,
    this.artificialNutrition,
    this.artificialNutritionInstruction,
    this.antibiotics,
    this.antibioticsInstruction,
    this.bloodTransfusion,
    this.bloodTransfusionInstruction,
    this.otherTreatment,
    this.otherInstruction,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'direction_type', directionType);
    _put(json, 'direction_instruction', directionInstruction);
    _put(json, 'treatment_type', treatmentType);
    _put(json, 'treatment_instruction', treatmentInstruction);
    _put(json, 'assisted_ventilation', assistedVentilation);
    _put(json, 'assisted_ventilation_instruction', assistedVentilationInstruction);
    _put(json, 'artificial_nutrition', artificialNutrition);
    _put(json, 'artificial_nutrition_instruction', artificialNutritionInstruction);
    _put(json, 'antibiotics', antibiotics);
    _put(json, 'antibiotics_instruction', antibioticsInstruction);
    _put(json, 'blood_transfusion', bloodTransfusion);
    _put(json, 'blood_transfusion_instruction', bloodTransfusionInstruction);
    _put(json, 'other_treatment', otherTreatment);
    _put(json, 'other_instruction', otherInstruction);
    return json;
  }

  factory LifeSustainingTreatmentDto.fromJson(Map<String, dynamic> json) {
    return LifeSustainingTreatmentDto(
      directionType: json['direction_type'] as String?,
      directionInstruction: json['direction_instruction'] as String?,
      treatmentType: json['treatment_type'] as String?,
      treatmentInstruction: json['treatment_instruction'] as String?,
      assistedVentilation: json['assisted_ventilation'] as String?,
      assistedVentilationInstruction: json['assisted_ventilation_instruction'] as String?,
      artificialNutrition: json['artificial_nutrition'] as String?,
      artificialNutritionInstruction: json['artificial_nutrition_instruction'] as String?,
      antibiotics: json['antibiotics'] as String?,
      antibioticsInstruction: json['antibiotics_instruction'] as String?,
      bloodTransfusion: json['blood_transfusion'] as String?,
      bloodTransfusionInstruction: json['blood_transfusion_instruction'] as String?,
      otherTreatment: json['other_treatment'] as String?,
      otherInstruction: json['other_instruction'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// QualityOfLifeToleranceDTO (NSW)
// ---------------------------------------------------------------------------
class QualityOfLifeToleranceDto {
  final String? noLongerRecogniseFamily;
  final String? noBladderControl;
  final String? cantFeedWashDress;
  final String? relyPeopleForMovement;
  final String? needLifeTubeForFood;
  final String? cantConverseWithPeople;

  const QualityOfLifeToleranceDto({
    this.noLongerRecogniseFamily,
    this.noBladderControl,
    this.cantFeedWashDress,
    this.relyPeopleForMovement,
    this.needLifeTubeForFood,
    this.cantConverseWithPeople,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'no_longer_recognise_family', noLongerRecogniseFamily);
    _put(json, 'no_bladder_control', noBladderControl);
    _put(json, 'cant_feed_wash_dress', cantFeedWashDress);
    _put(json, 'rely_people_for_movement', relyPeopleForMovement);
    _put(json, 'need_life_tube_for_food', needLifeTubeForFood);
    _put(json, 'cant_converse_with_people', cantConverseWithPeople);
    return json;
  }

  factory QualityOfLifeToleranceDto.fromJson(Map<String, dynamic> json) {
    return QualityOfLifeToleranceDto(
      noLongerRecogniseFamily: json['no_longer_recognise_family'] as String?,
      noBladderControl: json['no_bladder_control'] as String?,
      cantFeedWashDress: json['cant_feed_wash_dress'] as String?,
      relyPeopleForMovement: json['rely_people_for_movement'] as String?,
      needLifeTubeForFood: json['need_life_tube_for_food'] as String?,
      cantConverseWithPeople: json['cant_converse_with_people'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// CPRAndResuscitationDTO
// ---------------------------------------------------------------------------
class CprAndResuscitationDto {
  final String? cprInstruction;
  final String? medicalNotExpectedToRecover;
  final String? cprResuscitation;
  final String? cprResuscitationInstruction;
  final String? cprConsent;
  final String? cprConsentInstruction;

  const CprAndResuscitationDto({
    this.cprInstruction,
    this.medicalNotExpectedToRecover,
    this.cprResuscitation,
    this.cprResuscitationInstruction,
    this.cprConsent,
    this.cprConsentInstruction,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'cpr_instruction', cprInstruction);
    _put(json, 'medical_not_expected_to_recover', medicalNotExpectedToRecover);
    _put(json, 'cpr_resuscitation', cprResuscitation);
    _put(json, 'cpr_resuscitation_instruction', cprResuscitationInstruction);
    _put(json, 'cpr_consent', cprConsent);
    _put(json, 'cpr_consent_instruction', cprConsentInstruction);
    return json;
  }

  factory CprAndResuscitationDto.fromJson(Map<String, dynamic> json) {
    return CprAndResuscitationDto(
      cprInstruction: json['cpr_instruction'] as String?,
      medicalNotExpectedToRecover: json['medical_not_expected_to_recover'] as String?,
      cprResuscitation: json['cpr_resuscitation'] as String?,
      cprResuscitationInstruction: json['cpr_resuscitation_instruction'] as String?,
      cprConsent: json['cpr_consent'] as String?,
      cprConsentInstruction: json['cpr_consent_instruction'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// OrganAndBodyDonationDTO
// ---------------------------------------------------------------------------
class OrganAndBodyDonationDto {
  final bool? donateOrgan;
  final String? organDonationInstruction;
  final bool? consentOrganDonation;
  final bool? donateBody;
  final bool? consentBodyDonation;
  final String? authorisation;

  const OrganAndBodyDonationDto({
    this.donateOrgan,
    this.organDonationInstruction,
    this.consentOrganDonation,
    this.donateBody,
    this.consentBodyDonation,
    this.authorisation,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (donateOrgan != null) json['donate_organ'] = donateOrgan;
    _put(json, 'organ_donation_instruction', organDonationInstruction);
    if (consentOrganDonation != null) json['consent_organ_donation'] = consentOrganDonation;
    if (donateBody != null) json['donate_body'] = donateBody;
    if (consentBodyDonation != null) json['consent_body_donation'] = consentBodyDonation;
    _put(json, 'authorisation', authorisation);
    return json;
  }

  factory OrganAndBodyDonationDto.fromJson(Map<String, dynamic> json) {
    return OrganAndBodyDonationDto(
      donateOrgan: json['donate_organ'] as bool?,
      organDonationInstruction: json['organ_donation_instruction'] as String?,
      consentOrganDonation: json['consent_organ_donation'] as bool?,
      donateBody: json['donate_body'] as bool?,
      consentBodyDonation: json['consent_body_donation'] as bool?,
      authorisation: json['authorisation'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// MedicalResearchConsentDTO (WA)
// ---------------------------------------------------------------------------
class MedicalResearchConsentDto {
  final String? placebos;
  final String? useEquipment;
  final String? lessPractitionersSupport;
  final String? comparativeAssessment;
  final String? bloodSamples;
  final String? tissueSample;
  final String? nonIntrusiveTreatment;
  final String? beingObserved;
  final String? undertakingSurvey;
  final String? collecingDisclosingInformation;
  final String? evaluatingSamples;
  final String? other;

  const MedicalResearchConsentDto({
    this.placebos,
    this.useEquipment,
    this.lessPractitionersSupport,
    this.comparativeAssessment,
    this.bloodSamples,
    this.tissueSample,
    this.nonIntrusiveTreatment,
    this.beingObserved,
    this.undertakingSurvey,
    this.collecingDisclosingInformation,
    this.evaluatingSamples,
    this.other,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'placebos', placebos);
    _put(json, 'use_equipment', useEquipment);
    _put(json, 'less_practitioners_support', lessPractitionersSupport);
    _put(json, 'comparative_assessment', comparativeAssessment);
    _put(json, 'blood_samples', bloodSamples);
    _put(json, 'tissue_sample', tissueSample);
    _put(json, 'non_intrusive_treatment', nonIntrusiveTreatment);
    _put(json, 'being_observed', beingObserved);
    _put(json, 'undertaking_survey', undertakingSurvey);
    // NOTE: web has typo "collecing" — we match it exactly
    _put(json, 'collecing_disclosing_information', collecingDisclosingInformation);
    _put(json, 'evaluating_samples', evaluatingSamples);
    _put(json, 'other', other);
    return json;
  }

  factory MedicalResearchConsentDto.fromJson(Map<String, dynamic> json) {
    return MedicalResearchConsentDto(
      placebos: json['placebos'] as String?,
      useEquipment: json['use_equipment'] as String?,
      lessPractitionersSupport: json['less_practitioners_support'] as String?,
      comparativeAssessment: json['comparative_assessment'] as String?,
      bloodSamples: json['blood_samples'] as String?,
      tissueSample: json['tissue_sample'] as String?,
      nonIntrusiveTreatment: json['non_intrusive_treatment'] as String?,
      beingObserved: json['being_observed'] as String?,
      undertakingSurvey: json['undertaking_survey'] as String?,
      collecingDisclosingInformation: json['collecing_disclosing_information'] as String?,
      evaluatingSamples: json['evaluating_samples'] as String?,
      other: json['other'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// LivingPreferencesDTO (WA/NT)
// ---------------------------------------------------------------------------
class LivingPreferencesDto {
  final String? healthTreatmentPriority;
  final List<String>? livingWellImportance;
  final List<String>? isNearingDeath;
  final String? nearingDeathGoalsDetail;
  final String? wishToLive;
  final String? importantPeopleNearingDeath;
  final String? nearingDeathUnacceptable;
  final String? whereToDie;
  final String? whereToDieInstruction;
  final String? comfortPainDetails;
  final String? comfortSurroundingsDetails;

  const LivingPreferencesDto({
    this.healthTreatmentPriority,
    this.livingWellImportance,
    this.isNearingDeath,
    this.nearingDeathGoalsDetail,
    this.wishToLive,
    this.importantPeopleNearingDeath,
    this.nearingDeathUnacceptable,
    this.whereToDie,
    this.whereToDieInstruction,
    this.comfortPainDetails,
    this.comfortSurroundingsDetails,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'health_treatment_priority', healthTreatmentPriority);
    if (livingWellImportance != null && livingWellImportance!.isNotEmpty) {
      json['living_well_importance'] = livingWellImportance;
    }
    if (isNearingDeath != null && isNearingDeath!.isNotEmpty) {
      json['is_nearing_death'] = isNearingDeath;
    }
    _put(json, 'nearing_death_goals_detail', nearingDeathGoalsDetail);
    _put(json, 'wish_to_live', wishToLive);
    _put(json, 'important_people_nearing_death', importantPeopleNearingDeath);
    _put(json, 'nearing_death_unacceptable', nearingDeathUnacceptable);
    _put(json, 'where_to_die', whereToDie);
    _put(json, 'where_to_die_instruction', whereToDieInstruction);
    _put(json, 'comfort_pain_details', comfortPainDetails);
    _put(json, 'comfort_surroundings_details', comfortSurroundingsDetails);
    return json;
  }

  factory LivingPreferencesDto.fromJson(Map<String, dynamic> json) {
    return LivingPreferencesDto(
      healthTreatmentPriority: json['health_treatment_priority'] as String?,
      livingWellImportance: (json['living_well_importance'] as List?)?.cast<String>(),
      isNearingDeath: (json['is_nearing_death'] as List?)?.cast<String>(),
      nearingDeathGoalsDetail: json['nearing_death_goals_detail'] as String?,
      wishToLive: json['wish_to_live'] as String?,
      importantPeopleNearingDeath: json['important_people_nearing_death'] as String?,
      nearingDeathUnacceptable: json['nearing_death_unacceptable'] as String?,
      whereToDie: json['where_to_die'] as String?,
      whereToDieInstruction: json['where_to_die_instruction'] as String?,
      comfortPainDetails: json['comfort_pain_details'] as String?,
      comfortSurroundingsDetails: json['comfort_surroundings_details'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// TreatmentDecisionsDTO
// ---------------------------------------------------------------------------
class TreatmentDecisionsDto {
  final String? lifeSustainingTreatment;
  final String? artificialHydration;
  final String? artificialHydrationInstruction;
  final String? otherTreatmentDecision;
  final String? otherTreatmentDecisionInstruction;
  final String? healthCircumstanceDecisionInstruction;
  final String? otherMedicalSupport;
  final String? otherMedicalSupportInstruction;
  final String? consentPalliativeComfortCare;
  final String? specificTreatmentNoConsent;
  final String? specificTreatmentNoConsentInstruction;
  final String? healthcarePreferred;

  const TreatmentDecisionsDto({
    this.lifeSustainingTreatment,
    this.artificialHydration,
    this.artificialHydrationInstruction,
    this.otherTreatmentDecision,
    this.otherTreatmentDecisionInstruction,
    this.healthCircumstanceDecisionInstruction,
    this.otherMedicalSupport,
    this.otherMedicalSupportInstruction,
    this.consentPalliativeComfortCare,
    this.specificTreatmentNoConsent,
    this.specificTreatmentNoConsentInstruction,
    this.healthcarePreferred,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'life_sustaining_treatment', lifeSustainingTreatment);
    _put(json, 'artificial_hydration', artificialHydration);
    _put(json, 'artificial_hydration_instruction', artificialHydrationInstruction);
    _put(json, 'other_treatment_decision', otherTreatmentDecision);
    _put(json, 'other_treatment_decision_instruction', otherTreatmentDecisionInstruction);
    _put(json, 'health_circumstance_decision_instruction', healthCircumstanceDecisionInstruction);
    _put(json, 'other_medical_support', otherMedicalSupport);
    _put(json, 'other_medical_support_instruction', otherMedicalSupportInstruction);
    _put(json, 'consent_palliative_comfort_care', consentPalliativeComfortCare);
    _put(json, 'specific_treatment_no_consent', specificTreatmentNoConsent);
    _put(json, 'specific_treatment_no_consent_instruction', specificTreatmentNoConsentInstruction);
    _put(json, 'healthcare_preferred', healthcarePreferred);
    return json;
  }

  factory TreatmentDecisionsDto.fromJson(Map<String, dynamic> json) {
    return TreatmentDecisionsDto(
      lifeSustainingTreatment: json['life_sustaining_treatment'] as String?,
      artificialHydration: json['artificial_hydration'] as String?,
      artificialHydrationInstruction: json['artificial_hydration_instruction'] as String?,
      otherTreatmentDecision: json['other_treatment_decision'] as String?,
      otherTreatmentDecisionInstruction: json['other_treatment_decision_instruction'] as String?,
      healthCircumstanceDecisionInstruction: json['health_circumstance_decision_instruction'] as String?,
      otherMedicalSupport: json['other_medical_support'] as String?,
      otherMedicalSupportInstruction: json['other_medical_support_instruction'] as String?,
      consentPalliativeComfortCare: json['consent_palliative_comfort_care'] as String?,
      specificTreatmentNoConsent: json['specific_treatment_no_consent'] as String?,
      specificTreatmentNoConsentInstruction: json['specific_treatment_no_consent_instruction'] as String?,
      healthcarePreferred: json['healthcare_preferred'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// AttorneyAndAdviceDTO (WA)
// ---------------------------------------------------------------------------
class AttorneyAndAdviceDto {
  final String? attorneyDecisionPower;
  final String? attorneyDecisionPowerDetail;
  final String? hasUsedInterpreter;
  final String? hasEpg;
  final String? epgDate;
  final String? epgPlaceDetail;
  final String? seekMedicalAdvice;
  final String? seekLegalAdvice;

  const AttorneyAndAdviceDto({
    this.attorneyDecisionPower,
    this.attorneyDecisionPowerDetail,
    this.hasUsedInterpreter,
    this.hasEpg,
    this.epgDate,
    this.epgPlaceDetail,
    this.seekMedicalAdvice,
    this.seekLegalAdvice,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'attorney_decision_power', attorneyDecisionPower);
    _put(json, 'attorney_decision_power_detail', attorneyDecisionPowerDetail);
    _put(json, 'has_used_interpreter', hasUsedInterpreter);
    _put(json, 'has_epg', hasEpg);
    _put(json, 'epg_date', epgDate);
    _put(json, 'epg_place_detail', epgPlaceDetail);
    _put(json, 'seek_medical_advice', seekMedicalAdvice);
    _put(json, 'seek_legal_advice', seekLegalAdvice);
    return json;
  }

  factory AttorneyAndAdviceDto.fromJson(Map<String, dynamic> json) {
    return AttorneyAndAdviceDto(
      attorneyDecisionPower: json['attorney_decision_power'] as String?,
      attorneyDecisionPowerDetail: json['attorney_decision_power_detail'] as String?,
      hasUsedInterpreter: json['has_used_interpreter'] as String?,
      hasEpg: json['has_epg'] as String?,
      epgDate: json['epg_date'] as String?,
      epgPlaceDetail: json['epg_place_detail'] as String?,
      seekMedicalAdvice: json['seek_medical_advice'] as String?,
      seekLegalAdvice: json['seek_legal_advice'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// DeclarationsAndWishesDTO
// ---------------------------------------------------------------------------
class DeclarationsAndWishesDto {
  final String? declaration;
  final String? whatMatterMost;
  final String? whatWorriesMost;
  final String? unacceptableMedicalTreatmentOutcome;
  final String? otherThingsKnown;
  final String? otherPeopleInvolvedInCareDiscussion;
  final String? appointmentConditon;
  final String? otherMedicalDecision;
  final String? culturalRequest;
  final String? religiousBeliefs;
  final String? afterDeathImportance;
  final String? medicalNotExpectedToRecoverInstruction;
  final String? nearingDeathInstruction;

  const DeclarationsAndWishesDto({
    this.declaration,
    this.whatMatterMost,
    this.whatWorriesMost,
    this.unacceptableMedicalTreatmentOutcome,
    this.otherThingsKnown,
    this.otherPeopleInvolvedInCareDiscussion,
    this.appointmentConditon,
    this.otherMedicalDecision,
    this.culturalRequest,
    this.religiousBeliefs,
    this.afterDeathImportance,
    this.medicalNotExpectedToRecoverInstruction,
    this.nearingDeathInstruction,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _put(json, 'declaration', declaration);
    _put(json, 'what_matter_most', whatMatterMost);
    _put(json, 'what_worries_most', whatWorriesMost);
    _put(json, 'unacceptable_medical_treatment_outcome', unacceptableMedicalTreatmentOutcome);
    _put(json, 'other_things_known', otherThingsKnown);
    _put(json, 'other_people_involved_in_care_discussion', otherPeopleInvolvedInCareDiscussion);
    // NOTE: web has typo "conditon" — we match it exactly
    _put(json, 'appointment_conditon', appointmentConditon);
    _put(json, 'other_medical_decision', otherMedicalDecision);
    _put(json, 'cultural_request', culturalRequest);
    _put(json, 'religious_beliefs', religiousBeliefs);
    _put(json, 'after_death_importance', afterDeathImportance);
    _put(json, 'medical_not_expected_to_recover_instruction', medicalNotExpectedToRecoverInstruction);
    _put(json, 'nearing_death_instruction', nearingDeathInstruction);
    return json;
  }

  factory DeclarationsAndWishesDto.fromJson(Map<String, dynamic> json) {
    return DeclarationsAndWishesDto(
      declaration: json['declaration'] as String?,
      whatMatterMost: json['what_matter_most'] as String?,
      whatWorriesMost: json['what_worries_most'] as String?,
      unacceptableMedicalTreatmentOutcome: json['unacceptable_medical_treatment_outcome'] as String?,
      otherThingsKnown: json['other_things_known'] as String?,
      otherPeopleInvolvedInCareDiscussion: json['other_people_involved_in_care_discussion'] as String?,
      appointmentConditon: json['appointment_conditon'] as String?,
      otherMedicalDecision: json['other_medical_decision'] as String?,
      culturalRequest: json['cultural_request'] as String?,
      religiousBeliefs: json['religious_beliefs'] as String?,
      afterDeathImportance: json['after_death_importance'] as String?,
      medicalNotExpectedToRecoverInstruction: json['medical_not_expected_to_recover_instruction'] as String?,
      nearingDeathInstruction: json['nearing_death_instruction'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// AHDPersonDTO
// ---------------------------------------------------------------------------
class AhdPersonDto {
  final String? id;
  final String? tempId;
  final String fullName;
  final String personType;
  final String? qualification;
  final String? dob;
  final String? phone;
  final String? address;
  final String? suburb;
  final String? state;
  final String? postcode;
  final String? country;
  final Map<String, dynamic>? other;

  const AhdPersonDto({
    this.id,
    this.tempId,
    required this.fullName,
    required this.personType,
    this.qualification,
    this.dob,
    this.phone,
    this.address,
    this.suburb,
    this.state,
    this.postcode,
    this.country,
    this.other,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'full_name': fullName,
      'person_type': personType,
    };
    if (id != null) json['id'] = id;
    if (tempId != null) json['_temp_id'] = tempId;
    _put(json, 'qualification', qualification);
    _put(json, 'dob', dob);
    _put(json, 'phone', phone);
    _put(json, 'address', address);
    _put(json, 'suburb', suburb);
    _put(json, 'state', state);
    _put(json, 'postcode', postcode);
    _put(json, 'country', country);
    if (other != null && other!.isNotEmpty) json['other'] = other;
    return json;
  }

  factory AhdPersonDto.fromJson(Map<String, dynamic> json) {
    return AhdPersonDto(
      id: json['id'] as String?,
      tempId: json['_temp_id'] as String?,
      fullName: (json['full_name'] as String?) ?? '',
      personType: (json['person_type'] as String?) ?? '',
      qualification: json['qualification'] as String?,
      dob: json['dob'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      suburb: json['suburb'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
      other: json['other'] as Map<String, dynamic>?,
    );
  }
}

// ---------------------------------------------------------------------------
// AHDCreate — top-level payload sent to POST /user/ahd
// ---------------------------------------------------------------------------
class AhdCreateDto {
  final String? id;

  // High-level flags
  final String? acdExpiryDate;
  final bool? isAcdRevoked;
  final bool? isRegisteredAustralianOrganDonor;
  final bool? isRegisteredTasmaniaBequestProgram;
  final bool? isEnduringGuardianAppointed;
  final String? organDonation;
  final String? medicalTreatmentConsent;
  final String? medicalTreatmentRefuse;

  // Structured DTOs
  final HealthConditionsDto? healthConditions;
  final LifeSustainingTreatmentDto? lifeSustainingTreatment;
  final QualityOfLifeToleranceDto? qualityOfLifeTolerance;
  final CprAndResuscitationDto? cprAndResuscitation;
  final OrganAndBodyDonationDto? organAndBodyDonation;
  final MedicalResearchConsentDto? medicalResearchConsent;
  final LivingPreferencesDto? livingPreferences;
  final TreatmentDecisionsDto? treatmentDecisions;
  final AttorneyAndAdviceDto? attorneyAndAdvice;
  final DeclarationsAndWishesDto? declarationsAndWishes;

  // Arrays
  final List<DirectionAboutOtherHealthcareDto>? otherHealthDirections;
  final List<AhdPersonDto>? ahdPersons;

  const AhdCreateDto({
    this.id,
    this.acdExpiryDate,
    this.isAcdRevoked,
    this.isRegisteredAustralianOrganDonor,
    this.isRegisteredTasmaniaBequestProgram,
    this.isEnduringGuardianAppointed,
    this.organDonation,
    this.medicalTreatmentConsent,
    this.medicalTreatmentRefuse,
    this.healthConditions,
    this.lifeSustainingTreatment,
    this.qualityOfLifeTolerance,
    this.cprAndResuscitation,
    this.organAndBodyDonation,
    this.medicalResearchConsent,
    this.livingPreferences,
    this.treatmentDecisions,
    this.attorneyAndAdvice,
    this.declarationsAndWishes,
    this.otherHealthDirections,
    this.ahdPersons,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (id != null) json['id'] = id;

    // High-level flags
    _put(json, 'acd_expiry_date', acdExpiryDate);
    _put(json, 'expiry_date', acdExpiryDate);
    if (isAcdRevoked != null) json['is_acd_revoked'] = isAcdRevoked;
    if (isRegisteredAustralianOrganDonor != null) {
      json['is_registered_australian_organ_donor'] = isRegisteredAustralianOrganDonor;
    }
    if (isRegisteredTasmaniaBequestProgram != null) {
      json['is_registered_tasmania_bequest_program'] = isRegisteredTasmaniaBequestProgram;
    }
    if (isEnduringGuardianAppointed != null) {
      json['is_enduring_guardian_appointed'] = isEnduringGuardianAppointed;
    }
    _put(json, 'organ_donation', organDonation);
    _put(json, 'medical_treatment_consent', medicalTreatmentConsent);
    _put(json, 'medical_treatment_refuse', medicalTreatmentRefuse);

    // Flat top-level fields — the backend processes these directly.
    // The web app sends both flat AND nested; we match that pattern.
    _put(json, 'major_health_conditions', healthConditions?.majorHealthConditions);
    _put(json, 'things_important_for_me', healthConditions?.thingsImportantForMe);
    _put(json, 'beliefs_considered_during_health_care', healthConditions?.believesConsideredDuringHealthCare);
    _put(json, 'nearing_death_preference', healthConditions?.nearingDeathPreference);
    _put(json, 'people_not_to_involve_healthcare_discussion', healthConditions?.peopleNotToInvolveHealthcareDiscussion);
    if (healthConditions?.comfortNearingDeath != null &&
        healthConditions!.comfortNearingDeath!.isNotEmpty) {
      json['comfort_nearing_death'] = healthConditions!.comfortNearingDeath;
    }
    _put(json, 'life_sustaining_treatment_direction_type', lifeSustainingTreatment?.directionType);
    _put(json, 'life_sustaining_treatment_direction_instruction', lifeSustainingTreatment?.directionInstruction);
    _put(json, 'life_sustaining_treatment_type', lifeSustainingTreatment?.treatmentType);
    _put(json, 'life_sustaining_treatment_instruction', lifeSustainingTreatment?.treatmentInstruction);
    _put(json, 'assisted_ventilation', lifeSustainingTreatment?.assistedVentilation);
    _put(json, 'assisted_ventilation_instruction', lifeSustainingTreatment?.assistedVentilationInstruction);
    _put(json, 'artificial_nutrition', lifeSustainingTreatment?.artificialNutrition);
    _put(json, 'artificial_nutrition_instruction', lifeSustainingTreatment?.artificialNutritionInstruction);
    _put(json, 'antibiotics', lifeSustainingTreatment?.antibiotics);
    _put(json, 'antibiotics_instruction', lifeSustainingTreatment?.antibioticsInstruction);
    _put(json, 'blood_transfusion', lifeSustainingTreatment?.bloodTransfusion);
    _put(json, 'blood_transfusion_instruction', lifeSustainingTreatment?.bloodTransfusionInstruction);
    _put(json, 'other_life_sustaining_treatment', lifeSustainingTreatment?.otherTreatment);
    _put(json, 'other_life_sustaining_instruction', lifeSustainingTreatment?.otherInstruction);
    _put(json, 'no_longer_recognise_family', qualityOfLifeTolerance?.noLongerRecogniseFamily);
    _put(json, 'no_bladder_control', qualityOfLifeTolerance?.noBladderControl);
    _put(json, 'cant_feed_wash_dress', qualityOfLifeTolerance?.cantFeedWashDress);
    _put(json, 'rely_people_for_movement', qualityOfLifeTolerance?.relyPeopleForMovement);
    _put(json, 'need_life_tube_for_food', qualityOfLifeTolerance?.needLifeTubeForFood);
    _put(json, 'cant_converse_with_people', qualityOfLifeTolerance?.cantConverseWithPeople);
    _put(json, 'cpr_instruction', cprAndResuscitation?.cprInstruction);
    _put(json, 'medical_not_expected_to_recover', cprAndResuscitation?.medicalNotExpectedToRecover);
    _put(json, 'cpr_resuscitation', cprAndResuscitation?.cprResuscitation);
    _put(json, 'cpr_resuscitation_instruction', cprAndResuscitation?.cprResuscitationInstruction);
    _put(json, 'cpr_consent', cprAndResuscitation?.cprConsent);
    _put(json, 'cpr_consent_instruction', cprAndResuscitation?.cprConsentInstruction);
    if (organAndBodyDonation?.donateOrgan != null) json['donate_organ'] = organAndBodyDonation!.donateOrgan;
    _put(json, 'organ_donation_instruction', organAndBodyDonation?.organDonationInstruction);
    if (organAndBodyDonation?.consentOrganDonation != null) json['consent_organ_donation'] = organAndBodyDonation!.consentOrganDonation;
    if (organAndBodyDonation?.donateBody != null) json['donate_body'] = organAndBodyDonation!.donateBody;
    if (organAndBodyDonation?.consentBodyDonation != null) json['consent_body_donation'] = organAndBodyDonation!.consentBodyDonation;
    _put(json, 'authorisation', organAndBodyDonation?.authorisation);
    _put(json, 'health_treatment_priority', livingPreferences?.healthTreatmentPriority);
    if (livingPreferences?.livingWellImportance != null && livingPreferences!.livingWellImportance!.isNotEmpty) {
      json['living_well_importance'] = livingPreferences!.livingWellImportance;
    }
    if (livingPreferences?.isNearingDeath != null && livingPreferences!.isNearingDeath!.isNotEmpty) {
      json['is_nearing_death'] = livingPreferences!.isNearingDeath;
    }
    _put(json, 'nearing_death_goals_detail', livingPreferences?.nearingDeathGoalsDetail);
    _put(json, 'wish_to_live', livingPreferences?.wishToLive);
    _put(json, 'important_people_nearing_death', livingPreferences?.importantPeopleNearingDeath);
    _put(json, 'nearing_death_unacceptable', livingPreferences?.nearingDeathUnacceptable);
    _put(json, 'where_to_die', livingPreferences?.whereToDie);
    _put(json, 'where_to_die_instruction', livingPreferences?.whereToDieInstruction);
    _put(json, 'comfort_pain_details', livingPreferences?.comfortPainDetails);
    _put(json, 'comfort_surroundings_details', livingPreferences?.comfortSurroundingsDetails);
    _put(json, 'life_sustaining_treatment', treatmentDecisions?.lifeSustainingTreatment);
    _put(json, 'artificial_hydration', treatmentDecisions?.artificialHydration);
    _put(json, 'artificial_hydration_instruction', treatmentDecisions?.artificialHydrationInstruction);
    _put(json, 'other_treatment_decision', treatmentDecisions?.otherTreatmentDecision);
    _put(json, 'other_treatment_decision_instruction', treatmentDecisions?.otherTreatmentDecisionInstruction);
    _put(json, 'health_circumstance_decision_instruction', treatmentDecisions?.healthCircumstanceDecisionInstruction);
    _put(json, 'other_medical_support', treatmentDecisions?.otherMedicalSupport);
    _put(json, 'other_medical_support_instruction', treatmentDecisions?.otherMedicalSupportInstruction);
    _put(json, 'consent_palliative_comfort_care', treatmentDecisions?.consentPalliativeComfortCare);
    _put(json, 'specific_treatment_no_consent', treatmentDecisions?.specificTreatmentNoConsent);
    _put(json, 'specific_treatment_no_consent_instruction', treatmentDecisions?.specificTreatmentNoConsentInstruction);
    _put(json, 'healthcare_preferred', treatmentDecisions?.healthcarePreferred);
    _put(json, 'attorney_decision_power', attorneyAndAdvice?.attorneyDecisionPower);
    _put(json, 'attorney_decision_power_detail', attorneyAndAdvice?.attorneyDecisionPowerDetail);
    _put(json, 'has_used_interpreter', attorneyAndAdvice?.hasUsedInterpreter);
    _put(json, 'has_epg', attorneyAndAdvice?.hasEpg);
    _put(json, 'epg_date', attorneyAndAdvice?.epgDate);
    _put(json, 'epg_place_detail', attorneyAndAdvice?.epgPlaceDetail);
    _put(json, 'seek_medical_advice', attorneyAndAdvice?.seekMedicalAdvice);
    _put(json, 'seek_legal_advice', attorneyAndAdvice?.seekLegalAdvice);
    _put(json, 'declaration', declarationsAndWishes?.declaration);
    _put(json, 'what_matter_most', declarationsAndWishes?.whatMatterMost);
    _put(json, 'what_worries_most', declarationsAndWishes?.whatWorriesMost);
    _put(json, 'unacceptable_medical_treatment_outcome', declarationsAndWishes?.unacceptableMedicalTreatmentOutcome);
    _put(json, 'other_things_known', declarationsAndWishes?.otherThingsKnown);
    _put(json, 'other_people_involved_in_care_discussion', declarationsAndWishes?.otherPeopleInvolvedInCareDiscussion);
    _put(json, 'appointment_conditon', declarationsAndWishes?.appointmentConditon);
    _put(json, 'other_medical_decision', declarationsAndWishes?.otherMedicalDecision);
    _put(json, 'cultural_request', declarationsAndWishes?.culturalRequest);
    _put(json, 'religious_beliefs', declarationsAndWishes?.religiousBeliefs);
    _put(json, 'after_death_importance', declarationsAndWishes?.afterDeathImportance);
    _put(json, 'nearing_death_instruction', declarationsAndWishes?.nearingDeathInstruction);
    _put(json, 'placebos', medicalResearchConsent?.placebos);
    _put(json, 'use_equipment', medicalResearchConsent?.useEquipment);
    _put(json, 'less_practitioners_support', medicalResearchConsent?.lessPractitionersSupport);
    _put(json, 'comparative_assessment', medicalResearchConsent?.comparativeAssessment);
    _put(json, 'blood_samples', medicalResearchConsent?.bloodSamples);
    _put(json, 'tissue_sample', medicalResearchConsent?.tissueSample);
    _put(json, 'non_intrusive_treatment', medicalResearchConsent?.nonIntrusiveTreatment);
    _put(json, 'being_observed', medicalResearchConsent?.beingObserved);
    _put(json, 'undertaking_survey', medicalResearchConsent?.undertakingSurvey);
    _put(json, 'collecing_disclosing_information', medicalResearchConsent?.collecingDisclosingInformation);
    _put(json, 'evaluating_samples', medicalResearchConsent?.evaluatingSamples);
    _put(json, 'medical_research_other', medicalResearchConsent?.other);

    // Nested DTOs — kept for forward compatibility with backend updates
    _putDto(json, 'health_conditions', healthConditions?.toJson());
    _putDto(json, 'life_sustaining_treatment', lifeSustainingTreatment?.toJson());
    _putDto(json, 'quality_of_life_tolerance', qualityOfLifeTolerance?.toJson());
    _putDto(json, 'cpr_and_resuscitation', cprAndResuscitation?.toJson());
    _putDto(json, 'organ_and_body_donation', organAndBodyDonation?.toJson());
    _putDto(json, 'medical_research_consent', medicalResearchConsent?.toJson());
    _putDto(json, 'living_preferences', livingPreferences?.toJson());
    _putDto(json, 'treatment_decisions', treatmentDecisions?.toJson());
    _putDto(json, 'attorney_and_advice', attorneyAndAdvice?.toJson());
    _putDto(json, 'declarations_and_wishes', declarationsAndWishes?.toJson());

    // Arrays
    if (otherHealthDirections != null && otherHealthDirections!.isNotEmpty) {
      json['other_health_directions'] = otherHealthDirections!.map((d) => d.toJson()).toList();
    }
    if (ahdPersons != null && ahdPersons!.isNotEmpty) {
      json['ahd_persons'] = ahdPersons!.map((p) => p.toJson()).toList();
    }

    return json;
  }

  factory AhdCreateDto.fromJson(Map<String, dynamic> json) {
    return AhdCreateDto(
      id: json['id'] as String?,
      acdExpiryDate: json['acd_expiry_date'] as String?,
      isAcdRevoked: json['is_acd_revoked'] as bool?,
      isRegisteredAustralianOrganDonor: json['is_registered_australian_organ_donor'] as bool?,
      isRegisteredTasmaniaBequestProgram: json['is_registered_tasmania_bequest_program'] as bool?,
      isEnduringGuardianAppointed: json['is_enduring_guardian_appointed'] as bool?,
      organDonation: json['organ_donation'] as String?,
      medicalTreatmentConsent: json['medical_treatment_consent'] as String?,
      medicalTreatmentRefuse: json['medical_treatment_refuse'] as String?,
      healthConditions: json['health_conditions'] != null
          ? HealthConditionsDto.fromJson(json['health_conditions'] as Map<String, dynamic>)
          : null,
      lifeSustainingTreatment: json['life_sustaining_treatment'] != null
          ? LifeSustainingTreatmentDto.fromJson(json['life_sustaining_treatment'] as Map<String, dynamic>)
          : null,
      qualityOfLifeTolerance: json['quality_of_life_tolerance'] != null
          ? QualityOfLifeToleranceDto.fromJson(json['quality_of_life_tolerance'] as Map<String, dynamic>)
          : null,
      cprAndResuscitation: json['cpr_and_resuscitation'] != null
          ? CprAndResuscitationDto.fromJson(json['cpr_and_resuscitation'] as Map<String, dynamic>)
          : null,
      organAndBodyDonation: json['organ_and_body_donation'] != null
          ? OrganAndBodyDonationDto.fromJson(json['organ_and_body_donation'] as Map<String, dynamic>)
          : null,
      medicalResearchConsent: json['medical_research_consent'] != null
          ? MedicalResearchConsentDto.fromJson(json['medical_research_consent'] as Map<String, dynamic>)
          : null,
      livingPreferences: json['living_preferences'] != null
          ? LivingPreferencesDto.fromJson(json['living_preferences'] as Map<String, dynamic>)
          : null,
      treatmentDecisions: json['treatment_decisions'] != null
          ? TreatmentDecisionsDto.fromJson(json['treatment_decisions'] as Map<String, dynamic>)
          : null,
      attorneyAndAdvice: json['attorney_and_advice'] != null
          ? AttorneyAndAdviceDto.fromJson(json['attorney_and_advice'] as Map<String, dynamic>)
          : null,
      declarationsAndWishes: json['declarations_and_wishes'] != null
          ? DeclarationsAndWishesDto.fromJson(json['declarations_and_wishes'] as Map<String, dynamic>)
          : null,
      otherHealthDirections: (json['other_health_directions'] as List?)
          ?.map((e) => DirectionAboutOtherHealthcareDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      ahdPersons: (json['ahd_persons'] as List?)
          ?.map((e) => AhdPersonDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// AHDResponse — extends AHDCreate with server-side fields
// ---------------------------------------------------------------------------
class AhdResponseDto extends AhdCreateDto {
  final String? userId;
  final String? createdAt;
  final String? updatedAt;
  final bool? isActive;

  const AhdResponseDto({
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    super.id,
    super.acdExpiryDate,
    super.isAcdRevoked,
    super.isRegisteredAustralianOrganDonor,
    super.isRegisteredTasmaniaBequestProgram,
    super.isEnduringGuardianAppointed,
    super.organDonation,
    super.medicalTreatmentConsent,
    super.medicalTreatmentRefuse,
    super.healthConditions,
    super.lifeSustainingTreatment,
    super.qualityOfLifeTolerance,
    super.cprAndResuscitation,
    super.organAndBodyDonation,
    super.medicalResearchConsent,
    super.livingPreferences,
    super.treatmentDecisions,
    super.attorneyAndAdvice,
    super.declarationsAndWishes,
    super.otherHealthDirections,
    super.ahdPersons,
  });

  factory AhdResponseDto.fromJson(Map<String, dynamic> json) {
    final base = AhdCreateDto.fromJson(json);
    return AhdResponseDto(
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      isActive: json['is_active'] as bool?,
      id: base.id,
      acdExpiryDate: base.acdExpiryDate,
      isAcdRevoked: base.isAcdRevoked,
      isRegisteredAustralianOrganDonor: base.isRegisteredAustralianOrganDonor,
      isRegisteredTasmaniaBequestProgram: base.isRegisteredTasmaniaBequestProgram,
      isEnduringGuardianAppointed: base.isEnduringGuardianAppointed,
      organDonation: base.organDonation,
      medicalTreatmentConsent: base.medicalTreatmentConsent,
      medicalTreatmentRefuse: base.medicalTreatmentRefuse,
      healthConditions: base.healthConditions,
      lifeSustainingTreatment: base.lifeSustainingTreatment,
      qualityOfLifeTolerance: base.qualityOfLifeTolerance,
      cprAndResuscitation: base.cprAndResuscitation,
      organAndBodyDonation: base.organAndBodyDonation,
      medicalResearchConsent: base.medicalResearchConsent,
      livingPreferences: base.livingPreferences,
      treatmentDecisions: base.treatmentDecisions,
      attorneyAndAdvice: base.attorneyAndAdvice,
      declarationsAndWishes: base.declarationsAndWishes,
      otherHealthDirections: base.otherHealthDirections,
      ahdPersons: base.ahdPersons,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers — only add non-null/non-empty values to avoid sending empty strings
// ---------------------------------------------------------------------------
void _put(Map<String, dynamic> json, String key, String? value) {
  if (value != null && value.isNotEmpty) json[key] = value;
}

void _putDto(Map<String, dynamic> json, String key, Map<String, dynamic>? dto) {
  if (dto != null && dto.isNotEmpty) json[key] = dto;
}

// ---------------------------------------------------------------------------
// AhdEnumMapper — maps UI enum values to API-expected values.
//
// The UI (AhdFlowData) uses user-friendly enum strings like 'CONSENT_ALL',
// 'REFUSE_ALL', 'ENTER_DETAILS', etc. The API expects different strings
// like 'CONSENT', 'REFUSE', 'SPECIFIC_DIRECTION'. These helpers bridge
// that gap and must be called in _buildDto before constructing DTOs.
// ---------------------------------------------------------------------------
class AhdEnumMapper {
  AhdEnumMapper._();

  /// Maps TreatmentChoice UI values to API values.
  /// CONSENT_ALL→CONSENT, REFUSE_ALL→REFUSE, CONSENT_CIRCUMSTANCES→CIRCUMSTANCE
  static String? mapTreatmentChoice(String? choice) {
    switch (choice) {
      case 'CONSENT_ALL':
        return 'CONSENT';
      case 'REFUSE_ALL':
        return 'REFUSE';
      case 'CONSENT_CIRCUMSTANCES':
        return 'CIRCUMSTANCE';
      default:
        return choice;
    }
  }

  /// Maps WaLifeSustainingMain UI values to API values.
  /// CONSENT_TO_ALL_TREATMENT→CONSENT, REFUSE_ALL_TREATMENT→REFUSE,
  /// CONSENT_SPECIFIC_TREATMENT→CIRCUMSTANCE,
  /// CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING→CONSENT
  static String? mapWaLifeSustainingTreatment(String? choice) {
    switch (choice) {
      case 'CONSENT_TO_ALL_TREATMENT':
        return 'CONSENT';
      case 'CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING':
        return 'CONSENT';
      case 'REFUSE_ALL_TREATMENT':
        return 'REFUSE';
      case 'CONSENT_SPECIFIC_TREATMENT':
        return 'CIRCUMSTANCE';
      case 'CANT_DECIDE':
        return 'CANT_DECIDE';
      default:
        return choice;
    }
  }

  /// LifeSustainingDirective: CONSENT_ALL→CONSENT, REFUSE_ALL→REFUSE,
  /// ATTORNEY_DECIDES→ATTORNEY_DECISION, ENTER_DETAILS→SPECIFIC_DIRECTION
  static String? mapLifeSustainingDirective(String? d) {
    switch (d) {
      case 'CONSENT_ALL':
        return 'CONSENT';
      case 'REFUSE_ALL':
        return 'REFUSE';
      case 'ATTORNEY_DECIDES':
        return 'ATTORNEY_DECISION';
      case 'ENTER_DETAILS':
        return 'SPECIFIC_DIRECTION';
      default:
        return d;
    }
  }

  /// Maps BloodTransfusion UI values to API values.
  /// Handles both BloodTransfusionChoice (QLD) and TreatmentChoice (WA) values.
  static String? mapBloodTransfusion(String? choice) {
    switch (choice) {
      case 'DO_NOT_CONSENT':
        return 'REFUSE';
      case 'CONSENT':
      case 'CONSENT_ALL':
        return 'CONSENT';
      case 'REFUSE_ALL':
        return 'REFUSE';
      case 'CONSENT_CIRCUMSTANCES':
        return 'CIRCUMSTANCE';
      case 'OTHER':
        return 'OTHER';
      case 'CANT_DECIDE':
        return 'CANT_DECIDE';
      default:
        return choice;
    }
  }
}
