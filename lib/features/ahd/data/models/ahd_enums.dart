// AHD enums — exact API string values matching web's enum/index.ts
//
// Every enum value here is the exact string sent to/from the backend.
// Do NOT change these values without also changing the web app.

// ---------------------------------------------------------------------------
// Direction about life-sustaining treatment (overall directive)
// ---------------------------------------------------------------------------
class DirectionAboutLifeSustainingTreatment {
  static const String consent = 'CONSENT';
  static const String refuse = 'REFUSE';
  static const String attorneyDecision = 'ATTORNEY_DECISION';
  static const String specificDirection = 'SPECIFIC_DIRECTION';

  static const List<String> all = [consent, refuse, attorneyDecision, specificDirection];

  static String displayName(String value) {
    switch (value) {
      case consent:
        return 'I consent to all treatments aimed at sustaining or prolonging my life';
      case refuse:
        return 'I refuse any treatments aimed at sustaining or prolonging my life';
      case attorneyDecision:
        return 'I cannot decide at this point. I want my attorney(s) to make the decisions about life-sustaining treatment on my behalf at the time the decision needs to be made using the information in this advance health directive and in consultation with my health providers and the people I have listed in section 3.';
      case specificDirection:
        return 'I give the following specific directions about life-sustaining treatments:';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Common AHD options (CONSENT / REFUSE / CIRCUMSTANCE)
// Used for: assisted_ventilation, artificial_nutrition, antibiotics,
//           other_treatment, treatment_type
// ---------------------------------------------------------------------------
class CommonAhdOptions {
  static const String consent = 'CONSENT';
  static const String refuse = 'REFUSE';
  static const String circumstance = 'CIRCUMSTANCE';

  static const List<String> all = [consent, refuse, circumstance];

  static String displayName(String value) {
    switch (value) {
      case consent:
        return 'I consent to this treatment in all circumstances';
      case refuse:
        return 'I refuse this treatment in all circumstances';
      case circumstance:
        return 'I consent to this treatment in the following circumstances (You must specify the particular circumstances for each treatment)';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Common AHD decision options (adds CANT_DECIDE)
// Used for: artificial_hydration
// ---------------------------------------------------------------------------
class CommonAhdDecisionOptions {
  static const String consent = 'CONSENT';
  static const String refuse = 'REFUSE';
  static const String circumstance = 'CIRCUMSTANCE';
  static const String cantDecide = 'CANT_DECIDE';

  static const List<String> all = [consent, refuse, circumstance, cantDecide];

  static String displayName(String value) {
    switch (value) {
      case consent:
        return 'I consent to this treatment in all circumstances';
      case refuse:
        return 'I refuse this treatment in all circumstances';
      case circumstance:
        return 'I consent to this treatment in the following circumstances (You must specify the particular circumstances for each treatment)';
      case cantDecide:
        return 'I cannot decide at this time';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Blood transfusion
// ---------------------------------------------------------------------------
class BloodTransfusion {
  static const String consent = 'CONSENT';
  static const String refuse = 'REFUSE';
  static const String other = 'OTHER';

  static const List<String> all = [consent, refuse, other];

  static String displayName(String value) {
    switch (value) {
      case consent:
        return 'I consent to blood transfusions';
      case refuse:
        return 'I refuse blood transfusions';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Bearable status (NSW quality of life tolerance)
// ---------------------------------------------------------------------------
class BearableStatus {
  static const String bearable = 'BEARABLE';
  static const String unbearable = 'UNBEARABLE';
  static const String unsure = 'UNSURE';

  static const List<String> all = [bearable, unbearable, unsure];

  static String displayName(String value) {
    switch (value) {
      case bearable:
        return 'Bearable';
      case unbearable:
        return 'Unbearable';
      case unsure:
        return 'Unsure';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// CPR Medical Decision (NSW)
// ---------------------------------------------------------------------------
class CprMedicalDecision {
  static const String acceptCpr = 'ACCEPT_CPR';
  static const String rejectCpr = 'REJECT_CPR';

  static const List<String> all = [acceptCpr, rejectCpr];

  static String displayName(String value) {
    switch (value) {
      case acceptCpr:
        return 'I would like CPR attempted';
      case rejectCpr:
        return 'I do not want CPR attempted';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// CPR Consent (NT)
// ---------------------------------------------------------------------------
class CprConsent {
  static const String restart = 'RESTART';
  static const String condition = 'CONDITION';
  static const String allowToDie = 'ALLOW_TO_DIE';

  static const List<String> all = [restart, condition, allowToDie];

  static String displayName(String value) {
    switch (value) {
      case restart:
        return 'Attempt CPR';
      case condition:
        return 'Attempt CPR except in unacceptable conditions';
      case allowToDie:
        return 'Allow natural death';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Common treatment decision (WA CPR, etc.)
// ---------------------------------------------------------------------------
class CommonTreatmentDecision {
  static const String consent = 'CONSENT';
  static const String refuse = 'REFUSE';
  static const String circumstance = 'CIRCUMSTANCE';
  static const String cantDecide = 'CANT_DECIDE';

  static const List<String> all = [consent, refuse, circumstance, cantDecide];
}

// ---------------------------------------------------------------------------
// Life-sustaining treatment (WA main question / treatment_decisions.life_sustaining_treatment)
// ---------------------------------------------------------------------------
class LifeSustainingTreatmentDecision {
  static const String consentToAllTreatment = 'CONSENT_TO_ALL_TREATMENT';
  static const String consentUntilRecoverWithdraw =
      'CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING';
  static const String refuseAllTreatment = 'REFUSE_ALL_TREATMENT';
  static const String consentSpecificTreatment = 'CONSENT_SPECIFIC_TREATMENT';
  static const String cantDecide = 'CANT_DECIDE';

  static const List<String> all = [
    consentToAllTreatment,
    consentUntilRecoverWithdraw,
    refuseAllTreatment,
    consentSpecificTreatment,
    cantDecide,
  ];

  static String displayName(String value) {
    switch (value) {
      case consentToAllTreatment:
        return 'I consent to all treatment';
      case consentUntilRecoverWithdraw:
        return 'I consent to treatment until I can no longer recover, then withdraw life-sustaining treatment';
      case refuseAllTreatment:
        return 'I refuse all treatment';
      case consentSpecificTreatment:
        return 'I consent to specific treatment';
      case cantDecide:
        return 'I cannot decide at this time';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Other medical support (NSW)
// ---------------------------------------------------------------------------
class OtherMedicalSupport {
  static const String artificialVentilation = 'ARTIFICIAL_VENTILATION';
  static const String renalDialysis = 'RENAL_DIALYSIS';
  static const String lifeProlongingTreatment = 'LIFE_PROLONGING_TREATMENT';
  static const String other = 'OTHER';

  static const List<String> all = [
    artificialVentilation,
    renalDialysis,
    lifeProlongingTreatment,
    other,
  ];

  static String displayName(String value) {
    switch (value) {
      case artificialVentilation:
        return 'Artificial ventilation';
      case renalDialysis:
        return 'Renal dialysis';
      case lifeProlongingTreatment:
        return 'Life-prolonging treatment';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Other treatment decision (WA dialysis mapping)
// ---------------------------------------------------------------------------
class OtherTreatmentDecision {
  static const String treatmentDecision = 'TREATMENT_DECISION';
  static const String circumstance = 'CIRCUMSTANCE';

  static const List<String> all = [treatmentDecision, circumstance];
}

// ---------------------------------------------------------------------------
// Specific treatment no consent (NT)
// ---------------------------------------------------------------------------
class SpecificTreatmentNoConsent {
  static const String artificialFeeding = 'ARTIFICIAL_FEEDING';
  static const String renalDialysis = 'RENAL_DIALYSIS';
  static const String transfusions = 'TRANSFUSIONS';
  static const String other = 'OTHER';

  static const List<String> all = [artificialFeeding, renalDialysis, transfusions, other];

  static String displayName(String value) {
    switch (value) {
      case artificialFeeding:
        return 'Artificial feeding';
      case renalDialysis:
        return 'Renal dialysis';
      case transfusions:
        return 'Blood transfusions';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Attorney decision power
// ---------------------------------------------------------------------------
class AttorneyDecisionPower {
  static const String jointly = 'JOINTLY';
  static const String severally = 'SEVERALLY';
  static const String majority = 'MAJORITY';
  static const String other = 'OTHER';

  static const List<String> all = [jointly, severally, majority, other];

  static String displayName(String value) {
    switch (value) {
      case jointly:
        return 'Jointly (all of my attorneys must agree on all decisions)';
      case severally:
        return 'Severally (any one of my attorneys may decide)';
      case majority:
        return 'By a majority (more than half of my attorneys must agree on all decisions)';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Organ donation
// ---------------------------------------------------------------------------
class OrganDonation {
  static const String consent = 'CONSENT';
  static const String refuse = 'REFUSE';

  static const List<String> all = [consent, refuse];

  static String displayName(String value) {
    switch (value) {
      case consent:
        return 'I am willing to donate my organs';
      case refuse:
        return 'I am not willing to donate my organs';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Living well importance (WA multi-select checkboxes)
// ---------------------------------------------------------------------------
class LivingWellImportance {
  static const String spendTimeWithFamily = 'SPEND_TIME_WITH_FAMILY';
  static const String liveIndependently = 'LIVE_INDEPENDENTLY';
  static const String visitHometown = 'VISIT_HOMETOWN';
  static const String careMySelf = 'CARE_MYSELF';
  static const String keepActive = 'KEEP_ACTIVE';
  static const String recreationalActivities = 'RECREATIONAL_ACTIVITIES';
  static const String practisingReligion = 'PRACTISING_RELIGION';
  static const String liveWithCulturalReligiousValues = 'LIVE_WITH_CULTURAL_RELIGIOUS_VALUES';
  static const String workingInAJob = 'WORKING_IN_A_JOB';

  static const List<String> all = [
    spendTimeWithFamily,
    liveIndependently,
    visitHometown,
    careMySelf,
    keepActive,
    recreationalActivities,
    practisingReligion,
    liveWithCulturalReligiousValues,
    workingInAJob,
  ];

  static String displayName(String value) {
    switch (value) {
      case spendTimeWithFamily:
        return 'Spending time with my family and friends';
      case liveIndependently:
        return 'Living independently';
      case visitHometown:
        return 'Being able to visit my hometown';
      case careMySelf:
        return 'Being able to care for myself';
      case keepActive:
        return 'Keeping active';
      case recreationalActivities:
        return 'Recreational activities';
      case practisingReligion:
        return 'Practising my religion';
      case liveWithCulturalReligiousValues:
        return 'Living with my cultural or religious values';
      case workingInAJob:
        return 'Working in a job';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Nearing death preference (WA multi-select)
// ---------------------------------------------------------------------------
class NearingDeathPreference {
  static const String atHome = 'AT_HOME';
  static const String notAtHome = 'NOT_AT_HOME';
  static const String noPreference = 'NO_PREFERENCE';
  static const String receiveCare = 'RECEIVE_CARE';
  static const String other = 'OTHER';

  static const List<String> all = [atHome, notAtHome, noPreference, receiveCare, other];

  static String displayName(String value) {
    switch (value) {
      case atHome:
        return 'At home';
      case notAtHome:
        return 'Not at home';
      case noPreference:
        return 'No preference';
      case receiveCare:
        return 'Where I can receive the best care';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Comfort nearing death (WA multi-select)
// ---------------------------------------------------------------------------
class ComfortNearingDeath {
  static const String managedSymptoms = 'MANAGED_SYMPTOMS';
  static const String lovedOnesNearby = 'LOVED_ONES_NEARBY';
  static const String culturalReligious = 'CULTURAL_RELIGIOUS';
  static const String spiritualCare = 'SPIRITUAL_CARE';
  static const String healthySurroundings = 'HEALTHY_SURROUNDINGS';
  static const String other = 'OTHER';

  static const List<String> all = [
    managedSymptoms,
    lovedOnesNearby,
    culturalReligious,
    spiritualCare,
    healthySurroundings,
    other,
  ];

  static String displayName(String value) {
    switch (value) {
      case managedSymptoms:
        return 'Having my symptoms managed';
      case lovedOnesNearby:
        return 'Having my loved ones nearby';
      case culturalReligious:
        return 'Cultural or religious practices';
      case spiritualCare:
        return 'Spiritual care';
      case healthySurroundings:
        return 'Healthy surroundings';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Where to die preference (NT)
// ---------------------------------------------------------------------------
class WhereToDiePreference {
  static const String home = 'HOME';
  static const String hospital = 'HOSPITAL';
  static const String other = 'OTHER';

  static const List<String> all = [home, hospital, other];

  static String displayName(String value) {
    switch (value) {
      case home:
        return 'At home / on country';
      case hospital:
        return 'Hospital / hospice';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Medical research consent (WA — 12 category fields use same options)
// ---------------------------------------------------------------------------
class MedicalResearchConsent {
  static const String ifUrgent = 'IF_URGENT';
  static const String ifImproveCondition = 'IF_IMPROVE_CONDITION';
  static const String achieveBetterUnderstanding = 'ACHIEVE_BETTER_UNDERSTANDING_OF_FUTURE';
  static const String ifNoOption = 'IF_NO_OPTION';
  static const String dontConsent = 'DONT_CONSENT';

  static const List<String> all = [
    ifUrgent,
    ifImproveCondition,
    achieveBetterUnderstanding,
    ifNoOption,
    dontConsent,
  ];

  static String displayName(String value) {
    switch (value) {
      case ifUrgent:
        return 'If urgent';
      case ifImproveCondition:
        return 'If it may improve my condition';
      case achieveBetterUnderstanding:
        return 'To achieve better understanding of future treatments';
      case ifNoOption:
        return 'If there is no other option';
      case dontConsent:
        return 'I do not consent';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Interpreter usage (WA)
// ---------------------------------------------------------------------------
class InterpreterUsage {
  static const String englishFirstLanguage = 'ENGLISH_FIRST_LANGUAGE';
  static const String engagedInterpreter = 'ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER';
  static const String notEngagedInterpreter = 'ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER';

  static const List<String> all = [englishFirstLanguage, engagedInterpreter, notEngagedInterpreter];

  static String displayName(String value) {
    switch (value) {
      case englishFirstLanguage:
        return 'English is my first language';
      case engagedInterpreter:
        return 'English is not my first language — I engaged an interpreter';
      case notEngagedInterpreter:
        return 'English is not my first language — I did not engage an interpreter';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// EPG status (WA)
// ---------------------------------------------------------------------------
class EpgStatus {
  static const String notDone = 'NOT_DONE';
  static const String done = 'DONE';

  static const List<String> all = [notDone, done];

  static String displayName(String value) {
    switch (value) {
      case notDone:
        return 'I have not made an Enduring Power of Guardianship';
      case done:
        return 'I have made an Enduring Power of Guardianship';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Medical advice status (WA)
// ---------------------------------------------------------------------------
class MedicalAdviceStatus {
  static const String obtainMedicalAdvice = 'OBTAIN_MEDICAL_ADVICE';
  static const String notObtainMedicalAdvice = 'NOT_OBTAIN_MEDICAL_ADVICE';

  static const List<String> all = [obtainMedicalAdvice, notObtainMedicalAdvice];

  static String displayName(String value) {
    switch (value) {
      case obtainMedicalAdvice:
        return 'I did obtain medical advice';
      case notObtainMedicalAdvice:
        return 'I did not obtain medical advice';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Legal advice status (WA)
// ---------------------------------------------------------------------------
class LegalAdviceStatus {
  static const String obtainLegalAdvice = 'OBTAIN_LEGAL_ADVICE';
  static const String notObtainLegalAdvice = 'NOT_OBTAIN_LEGAL_ADVICE';

  static const List<String> all = [obtainLegalAdvice, notObtainLegalAdvice];

  static String displayName(String value) {
    switch (value) {
      case obtainLegalAdvice:
        return 'I did obtain legal advice';
      case notObtainLegalAdvice:
        return 'I did not obtain legal advice';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// AHD person type — discriminator for ahd_persons[] array
// ---------------------------------------------------------------------------
class AhdPersonType {
  static const String witnessMedicalPractitioner = 'WITNESS_MEDICAL_PRACTITIONER';
  static const String witnessPerson = 'WITNESS_PERSON';
  static const String interpreter = 'INTERPRETER';
  static const String doctor = 'DOCTOR';
  static const String attorneyHealthMatters = 'ATTORNEY_HEALTH_MATTERS';
  static const String enduringGuardian = 'ENDURING_GUARDIAN';
  static const String medicalGuardian = 'MEDICAL_GUARDIAN';
  static const String secondaryEnduringGuardian = 'SECONDARY_ENDURING_GUARDIAN';
  static const String tertiaryEnduringGuardian = 'TERTIARY_ENDURING_GUARDIAN';
  static const String medicalAdvisor = 'MEDICAL_ADVISOR';
  static const String legalAdvisor = 'LEGAL_ADVISOR';
  static const String substituteDecisionMaker = 'SUBSTITUTE_DECISION_MAKER';
  static const String substituteDecisionMakerSecondary = 'SUBSTITUTE_DECISION_MAKER_SECONDARY';
  static const String substituteDecisionMakerTertiary = 'SUBSTITUTE_DECISION_MAKER_TERTIARY';
  static const String witnessPrimary = 'WITNESS_PRIMARY';
  static const String witnessAuthorized = 'WITNESS_AUTHORIZED';
  static const String witnessInterpreter = 'WITNESS_INTERPRETER';
  static const String decisionMaker = 'DECISION_MAKER';
  static const String primaryPerson = 'PRIMARY_PERSON';
  static const String helper = 'HELPER';
  static const String secondaryPerson = 'SECONDARY_PERSON';
}

// ---------------------------------------------------------------------------
// AHD Matters
// ---------------------------------------------------------------------------
class AhdMatters {
  static const String personal = 'PERSONAL';
  static const String health = 'HEALTH';
  static const String limited = 'LIMITED';
  static const String finance = 'FINANCE';
  static const String all = 'ALL';
}

// ---------------------------------------------------------------------------
// SA Witness category
// ---------------------------------------------------------------------------
class SaWitnessCategory {
  static const String justiceOfPeace = 'JUSTICE_OF_PEACE';
  static const String proclaimedPoliceOfficer = 'PROCLAIMED_POLICE_OFFICER';
  static const String legalPractitioner = 'LEGAL_PRACTITIONER';
  static const String registeredNurse = 'REGISTERED_NURSE';
  static const String registeredPharmacist = 'REGISTERED_PHARMACIST';
  static const String other = 'OTHER';

  static const List<String> allValues = [
    justiceOfPeace,
    proclaimedPoliceOfficer,
    legalPractitioner,
    registeredNurse,
    registeredPharmacist,
    other,
  ];

  static String displayName(String value) {
    switch (value) {
      case justiceOfPeace:
        return 'Justice of the Peace';
      case proclaimedPoliceOfficer:
        return 'Proclaimed Police Officer';
      case legalPractitioner:
        return 'Legal Practitioner';
      case registeredNurse:
        return 'Registered Nurse';
      case registeredPharmacist:
        return 'Registered Pharmacist';
      case other:
        return 'Other';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Interpreter languages
// ---------------------------------------------------------------------------
class InterpreterLanguages {
  static const List<String> values = [
    'ENGLISH',
    'SPANISH',
    'MANDARIN',
    'CANTONESE',
    'ARABIC',
    'VIETNAMESE',
    'ITALIAN',
    'GREEK',
    'HINDI',
    'PUNJABI',
    'TAGALOG',
    'KOREAN',
    'JAPANESE',
    'FRENCH',
    'GERMAN',
    'OTHER',
  ];

  static String displayName(String value) {
    return value[0] + value.substring(1).toLowerCase();
  }
}
