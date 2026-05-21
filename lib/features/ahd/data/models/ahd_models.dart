// Advance Health Directive — data models
//
// [HealthCareDirection] holds a single health condition & its directions.
// [AhdFlowData] accumulates all wizard state and is passed through route extras.

class HealthCareDirection {
  final String healthCondition;
  final String directions;

  const HealthCareDirection({
    this.healthCondition = '',
    this.directions = '',
  });

  HealthCareDirection copyWith({
    String? healthCondition,
    String? directions,
  }) {
    return HealthCareDirection(
      healthCondition: healthCondition ?? this.healthCondition,
      directions: directions ?? this.directions,
    );
  }
}

/// Treatment consent values
class TreatmentChoice {
  static const String consentAll = 'CONSENT_ALL';
  static const String refuseAll = 'REFUSE_ALL';
  static const String consentCircumstances = 'CONSENT_CIRCUMSTANCES';
  static const String cantDecide = 'CANT_DECIDE';
}

/// WA life-sustaining treatment main question values
class WaLifeSustainingMain {
  static const String consentAll = 'CONSENT_TO_ALL_TREATMENT';
  static const String consentUntilRecover =
      'CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING';
  static const String specificTreatment = 'CONSENT_SPECIFIC_TREATMENT';
  static const String refuseAll = 'REFUSE_ALL_TREATMENT';
  static const String cantDecide = 'CANT_DECIDE';
}

/// Life-sustaining directive (overall) values
class LifeSustainingDirective {
  static const String consentAll = 'CONSENT_ALL';
  static const String refuseAll = 'REFUSE_ALL';
  static const String attorneyDecides = 'ATTORNEY_DECIDES';
  static const String enterDetails = 'ENTER_DETAILS';
}

/// Blood transfusion values
class BloodTransfusionChoice {
  static const String consent = 'CONSENT';
  static const String doNotConsent = 'DO_NOT_CONSENT';
  static const String other = 'OTHER';
}

/// Attorney decision method values
class AttorneyDecisionMethod {
  static const String jointly = 'JOINTLY';
  static const String severally = 'SEVERALLY';
  static const String majority = 'MAJORITY';
  static const String other = 'OTHER';
}

/// Organ and tissue donation values
class OrganDonationChoice {
  static const String willing = 'CONSENT';
  static const String notWilling = 'REFUSE';
}

/// Personal values about dying — bearability choices
class BearabilityChoice {
  static const String bearable = 'BEARABLE';
  static const String unbearable = 'UNBEARABLE';
  static const String unsure = 'UNSURE';
}

/// CPR choice values
class CprChoice {
  static const String accept = 'ACCEPT';
  static const String doNotAccept = 'DO_NOT_ACCEPT';
}

/// Interpreter language options (matches web enum)
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

/// Medical treatment type values
class MedicalTreatmentType {
  static const String artificialVentilation = 'ARTIFICIAL_VENTILATION';
  static const String renalDialysis = 'RENAL_DIALYSIS';
  static const String lifeProlonging = 'LIFE_PROLONGING';
  static const String other = 'OTHER';
}

/// WA — Nearing death location choices
class WaNearingDeathLocation {
  static const String atHome = 'AT_HOME';
  static const String notAtHome = 'NOT_AT_HOME';
  static const String noPreference = 'NO_PREFERENCE';
  static const String bestCare = 'BEST_CARE';
  static const String other = 'OTHER';
}

/// WA — Interpreter choice
class WaInterpreterChoice {
  static const String englishFirstLanguage = 'ENGLISH_FIRST_LANGUAGE';
  static const String engagedInterpreter = 'ENGAGED_INTERPRETER';
  static const String didNotEngage = 'DID_NOT_ENGAGE';
}

/// WA — EPG choice
class WaEpgChoice {
  static const String notMade = 'NOT_MADE';
  static const String made = 'MADE';
}

/// WA — Advice choice (medical and legal)
class WaAdviceChoice {
  static const String didNotObtain = 'DID_NOT_OBTAIN';
  static const String didObtain = 'DID_OBTAIN';
}

/// SA — Witness category for authorised witness
class SaWitnessCategory {
  static const String justiceOfPeace = 'JUSTICE_OF_PEACE';
  static const String proclaimedPoliceOfficer = 'PROCLAIMED_POLICE_OFFICER';
  static const String legalPractitioner = 'LEGAL_PRACTITIONER';
  static const String registeredNurse = 'REGISTERED_NURSE';
  static const String registeredPharmacist = 'REGISTERED_PHARMACIST';
  static const String other = 'OTHER';

  static const List<String> all = [
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

/// NT — CPR choice
class NtCprChoice {
  static const String attemptCpr = 'ATTEMPT_CPR';
  static const String exceptUnacceptable = 'EXCEPT_UNACCEPTABLE';
  static const String naturalDeath = 'NATURAL_DEATH';
}

/// NT — Where to die/finish up choices
class NtWhereToDieChoice {
  static const String atHomeOnCountry = 'AT_HOME_ON_COUNTRY';
  static const String hospitalHospice = 'HOSPITAL_HOSPICE';
  static const String other = 'OTHER';
}

/// NT — Refused treatments (multi-select)
class NtRefusedTreatment {
  static const String artificialFeeding = 'ARTIFICIAL_FEEDING';
  static const String renalDialysis = 'RENAL_DIALYSIS';
  static const String bloodTransfusions = 'BLOOD_TRANSFUSIONS';
  static const String other = 'OTHER';
}

/// NT — Decision method
class NtDecisionMethod {
  static const String severally = 'SEVERALLY';
  static const String jointly = 'JOINTLY';
  static const String other = 'OTHER';
}

/// NT — Matters for decision maker appointment
class NtMatters {
  static const String allMatters = 'ALL_MATTERS';
  static const String financialMatters = 'FINANCIAL_MATTERS';
  static const String personalHealthMatters = 'PERSONAL_HEALTH_MATTERS';
  static const String limitedMatters = 'LIMITED_MATTERS';
}

class AhdFlowData {
  // ── Step 1: Personal Details ─────────────────────────────────────────────
  final String? fullName;
  final String? dob;
  final String? addressLine1;
  final String? suburb;
  final String? postcode;
  final String? state;
  final String? phone;
  final String? email;

  // ── Step 2: Health Conditions and Concerns ───────────────────────────────
  final String? healthConditions;

  // ── Step 3: Views, Wishes and Preferences ────────────────────────────────
  final String? thingsImportant;
  final String? thingsWorry;
  final String? culturalValues;
  final String? nearingDeathComfort;
  final String? nearingDeathImportant;
  final String? peopleNotInvolved;

  // ── Step 4: Your Directions ──────────────────────────────────────────────
  /// Overall life-sustaining directive
  final String? lifeSustainingDirective;
  final String? lifeSustainingDirectiveDetails;

  /// Per-treatment choices
  final String? lifeSustainingTreatment;
  final String? lifeSustainingTreatmentDetails;
  final String? assistedVentilation;
  final String? assistedVentilationDetails;
  final String? artificialNutrition;
  final String? artificialNutritionDetails;
  final String? artificialHydration;
  final String? artificialHydrationDetails;
  final String? antibiotics;
  final String? antibioticsDetails;
  final String? otherTreatment;
  final String? otherTreatmentDetails;
  final String? lstStateTreatment; // life_sustaining_treatment.life_sustaining_treatment (State the treatment text)

  // ── Step 5: Directions About Other Health Care ───────────────────────────
  final List<HealthCareDirection> otherHealthCareDirections;

  // ── Step 6: Directions About Blood Transfusions ──────────────────────────
  final String? bloodTransfusionChoice;
  final String? bloodTransfusionOther;

  // ── Step 7: Doctor Certificate ───────────────────────────────────────────
  final String? doctorName;
  final String? facilityName;
  final String? doctorDob;
  final String? doctorAddress;
  final String? doctorSuburb;
  final String? doctorPostcode;
  final String? doctorState;
  final String? doctorPhone;
  final String? doctorSign;

  // ── Step 8: Appointing Attorneys for Health Matters ──────────────────────
  final List<AhdAttorneyData> healthAttorneys;
  final String? attorneyDecisionMethod;
  final String? attorneyDecisionOther;
  final String? attorneyTerms;

  // ── Step 9: Declarations and Signatures ──────────────────────────────────
  final String? declarationDetails;

  // ── Victoria-specific fields ────────────────────────────────────────────

  // Values directive
  final String? vicUnacceptableOutcomes;
  final String? vicOtherThingsKnown;
  final String? vicPeopleInvolved;
  final String? vicOrganDonation;

  // Instructional directive
  final String? vicConsentTreatment;
  final String? vicRefuseTreatment;

  // Witnessing
  final String? vicPersonSign;
  final String? vicRefuseMedicalTreatment;
  final String? vicWitness1FullName;
  final String? vicWitness1Qualification;
  final String? vicWitness1Signature;
  final String? vicWitness1Date;
  final String? vicWitness2FullName;
  final String? vicWitness2Signature;
  final String? vicWitness2Date;

  // Interpreter
  final String? vicInterpreterName;
  final String? vicInterpreterNaati;
  final String? vicInterpreterLanguage;
  final String? vicInterpreterSignature;
  final String? vicInterpreterDate;

  // ── NSW-specific fields ──────────────────────────────────────────────

  // Personal values about dying (bearability choices)
  final String? nswCannotRecogniseFamily;
  final String? nswNoBladderControl;
  final String? nswCannotFeedWashDress;
  final String? nswCannotMoveInOutBed;
  final String? nswCannotMoveReposition;
  final String? nswCannotEatDrink;
  final String? nswEndOfLifeCare;

  // Directions about medical care
  final String? nswCprChoice;
  final String? nswMedicalTreatmentType;
  final String? nswMedicalTreatmentOther;

  // Organ and tissue donation
  final bool? nswDonateOrgans;
  final bool? nswDiscussedDonation;
  final bool? nswDonateBody;
  final bool? nswConsentOrganDonation;

  // Personal responsible
  final List<AhdAttorneyData> nswPersonsResponsible;

  // Enduring guardian
  final bool? nswHasEnduringGuardian;
  final List<AhdAttorneyData> nswEnduringGuardians;

  // Authorisation
  final String? nswAuthorisation;

  // ── WA-specific fields ────────────────────────────────────────────────

  // Revocation
  final bool? waRevokeAcd;

  // My Health
  final String? waHealthConditions;
  final String? waTreatmentPreferences;

  // My Values & Preferences
  final List<String> waLivingWellChoices;
  final String? waWorries;
  final List<String> waNearingDeathLocations;
  final String? waNearingDeathLocationDetails;
  final List<String> waComfortChoices;
  final String? waComfortPainDetails;
  final String? waComfortSurroundingsDetails;

  // Treatment directives
  final String? waLifeSustainingTreatment;
  final String? waLifeSustainingDetails;
  final String? waCpr;
  final String? waCprDetails;
  final String? waAssistedVentilation;
  final String? waAssistedVentilationDetails;
  final String? waArtificialNutrition;
  final String? waArtificialNutritionDetails;
  final String? waArtificialHydration;
  final String? waArtificialHydrationDetails;
  final String? waAntibiotics;
  final String? waAntibioticsDetails;
  final String? waBloodProducts;
  final String? waBloodProductsDetails;
  final String? waDialysis;
  final String? waDialysisDetails;
  final String? waOtherTreatmentName;
  final String? waOtherTreatment;
  final String? waOtherTreatmentDetails;

  // Medical research consent (WA) — one field per sub-question
  final String? waMrPlacebos;
  final String? waMrUseEquipment;
  final String? waMrLessPractitioners;
  final String? waMrComparativeAssessment;
  final String? waMrBloodSamples;
  final String? waMrTissueSample;
  final String? waMrNonIntrusiveTreatment;
  final String? waMrBeingObserved;
  final String? waMrUndertakingSurvey;
  final String? waMrCollectingDisclosing;
  final String? waMrEvaluatingSamples;
  final String? waMrOther;

  // People who helped — interpreter
  final String? waInterpreterChoice;

  // People who helped — EPG
  final String? waEpgChoice;
  final String? waEpgDate;
  final String? waEpgLocation;
  final String? waGuardianFirstName;
  final String? waGuardianPhone;
  final String? waSubstituteGuardianFirstName;
  final String? waSubstituteGuardianPhone;
  final String? waOtherSubstituteFirstName;
  final String? waOtherSubstitutePhone;

  // People who helped — medical / legal advice
  final String? waMedicalAdviceChoice;
  final String? waMedicalAdvisorFirstName;
  final String? waMedicalAdvisorPhone;
  final String? waMedicalAdvisorPractice;
  final String? waLegalAdviceChoice;
  final String? waLegalAdvisorFirstName;
  final String? waLegalAdvisorPhone;
  final String? waLegalAdvisorPractice;

  // Signature & witnessing
  final String? waAuthorisation;

  // ── SA-specific fields ──────────────────────────────────────────────

  // Step 2 — Conditions, refusals, expiry
  final String? saConditionsOfAppointments;
  final String? saRefusalHealthCare;
  final String? saExpiryDate;

  // Step 2 — Values and wishes
  final String? saLivingWell;
  final String? saWhereToLive;
  final String? saOtherThingsKnown;
  final String? saOtherPeopleInvolved;
  final String? saNearingDeath;
  final String? saStatementResponse;
  final String? saOrganDonationChoice; // OrganDonationChoice.willing / .notWilling
  final String? saOrganDonationInstruction;
  final String? saHealthcarePreferred;

  // Step 2 — Substitute Decision-Makers
  final List<AhdAttorneyData> saSubstituteDecisionMakers;
  final String? saSubDm1FullName;
  final String? saSubDm1Address;
  final String? saSubDm1Date;
  final String? saSubDm2FullName;
  final String? saSubDm2Address;
  final String? saSubDm2Date;

  // Step 3 — Witnessing
  final String? saWitnessFullName;
  final String? saWitnessPhone;
  final String? saWitnessSignature;
  final String? saWitnessDate;
  final String? saAuthorisedWitnessFullName;
  final String? saWitnessCategory;
  final String? saAuthorisedWitnessPhone;
  final String? saAuthorisedWitnessSignature;
  final String? saAuthorisedWitnessDate;
  final String? saExtraExecutionStatement;

  // Step 3 — Interpreter
  final String? saInterpreterName;
  final String? saInterpreterNaati;
  final String? saInterpreterSignature;
  final String? saInterpreterDate;

  // ── NT-specific fields ──────────────────────────────────────────────

  // Advanced care statement
  final String? ntLifeMeaning;
  final String? ntNearingDeathGoals;
  final String? ntUnacceptableOutcomes;
  final String? ntPalliativeCare;
  final String? ntWhereToDie;
  final String? ntWhereToDieChoice;
  final String? ntOtherMedicalInfo;
  final String? ntCulturalRequests;
  final String? ntAfterDeath1;
  final String? ntAfterDeath2;

  // Advanced consent decision
  final String? ntCprChoice;
  final String? ntCprConditionDetails;
  final List<String> ntRefusedTreatments;
  final String? ntRefusedTreatmentOther;
  final String? ntReligiousBeliefs;

  // Appointment Decision-Maker
  final List<AhdAttorneyData> ntDecisionMakers;
  final List<AhdAttorneyData> ntAppointedDecisionMakers;
  final String? ntDecisionMethod;
  final String? ntDecisionMethodOther;

  // Signing and witnessing
  final String? ntSign;

  // ── TAS-specific fields ──────────────────────────────────────────────

  // Step 2 — My Values & Views
  final String? tasHealthConditions;
  final String? tasViewsWishes;

  // Step 2 — Medical Treatment I Refuse
  final String? tasMedicalTreatmentRefuse;
  final String? tasMedicalCircumstances;

  // Step 2 — Organ and Tissue Donation
  final bool? tasOrganDonorRegister;
  final bool? tasBodyBequestProgram;

  // Step 2 — Expiry & Revoking
  final String? tasExpiryDate;
  final bool? tasRevokeAcd;
  final String? tasRevokeSignature;
  final String? tasRevokeDate;

  // Step 3 — Your Signature
  final String? tasSignFullName;
  final String? tasSignSignature;
  final String? tasSignDate;

  // Step 3 — Delegated completion
  final String? tasDelegatedPersonName;
  final String? tasDelegatedAcdPersonName;
  final String? tasDelegatedRelationship;
  final String? tasDelegatedSignature;
  final String? tasDelegatedDate;

  // Step 3 — Witnessing
  final List<AhdAttorneyData> tasWitnesses;

  // Step 3 — Interpreter/Translator
  final String? tasInterpreterName;
  final String? tasInterpreterLanguage;
  final String? tasInterpreterSignature;
  final String? tasInterpreterDob;
  final String? tasInterpreterNaati;

  // ── ACT-specific fields ──────────────────────────────────────────────

  // Step 2 — Medical treatment refuse
  final String? actMedicalTreatmentRefuse;

  // Step 2 — Certification
  final String? actDirectedPersonName;
  final String? actDirectedPersonAddress;

  // Step 2 — Previous direction revoked
  final bool? actRevokePreviousDirections;

  // Step 3 — Witnesses
  final String? actWitness1FullName;
  final String? actWitness1Address;

  const AhdFlowData({
    this.fullName,
    this.dob,
    this.addressLine1,
    this.suburb,
    this.postcode,
    this.state,
    this.phone,
    this.email,
    this.healthConditions,
    this.thingsImportant,
    this.thingsWorry,
    this.culturalValues,
    this.nearingDeathComfort,
    this.nearingDeathImportant,
    this.peopleNotInvolved,
    this.lifeSustainingDirective,
    this.lifeSustainingDirectiveDetails,
    this.lifeSustainingTreatment,
    this.lifeSustainingTreatmentDetails,
    this.assistedVentilation,
    this.assistedVentilationDetails,
    this.artificialNutrition,
    this.artificialNutritionDetails,
    this.artificialHydration,
    this.artificialHydrationDetails,
    this.antibiotics,
    this.antibioticsDetails,
    this.otherTreatment,
    this.otherTreatmentDetails,
    this.lstStateTreatment,
    this.otherHealthCareDirections = const [],
    this.bloodTransfusionChoice,
    this.bloodTransfusionOther,
    this.doctorName,
    this.facilityName,
    this.doctorDob,
    this.doctorAddress,
    this.doctorSuburb,
    this.doctorPostcode,
    this.doctorState,
    this.doctorPhone,
    this.doctorSign,
    this.healthAttorneys = const [],
    this.attorneyDecisionMethod,
    this.attorneyDecisionOther,
    this.attorneyTerms,
    this.declarationDetails,
    // Victoria-specific
    this.vicUnacceptableOutcomes,
    this.vicOtherThingsKnown,
    this.vicPeopleInvolved,
    this.vicOrganDonation,
    this.vicConsentTreatment,
    this.vicRefuseTreatment,
    this.vicPersonSign,
    this.vicRefuseMedicalTreatment,
    this.vicWitness1FullName,
    this.vicWitness1Qualification,
    this.vicWitness1Signature,
    this.vicWitness1Date,
    this.vicWitness2FullName,
    this.vicWitness2Signature,
    this.vicWitness2Date,
    this.vicInterpreterName,
    this.vicInterpreterNaati,
    this.vicInterpreterLanguage,
    this.vicInterpreterSignature,
    this.vicInterpreterDate,
    // NSW-specific
    this.nswCannotRecogniseFamily,
    this.nswNoBladderControl,
    this.nswCannotFeedWashDress,
    this.nswCannotMoveInOutBed,
    this.nswCannotMoveReposition,
    this.nswCannotEatDrink,
    this.nswEndOfLifeCare,
    this.nswCprChoice,
    this.nswMedicalTreatmentType,
    this.nswMedicalTreatmentOther,
    this.nswDonateOrgans,
    this.nswDiscussedDonation,
    this.nswDonateBody,
    this.nswConsentOrganDonation,
    this.nswPersonsResponsible = const [],
    this.nswHasEnduringGuardian,
    this.nswEnduringGuardians = const [],
    this.nswAuthorisation,
    // WA-specific
    this.waRevokeAcd,
    this.waHealthConditions,
    this.waTreatmentPreferences,
    this.waLivingWellChoices = const [],
    this.waWorries,
    this.waNearingDeathLocations = const [],
    this.waNearingDeathLocationDetails,
    this.waComfortChoices = const [],
    this.waComfortPainDetails,
    this.waComfortSurroundingsDetails,
    this.waLifeSustainingTreatment,
    this.waLifeSustainingDetails,
    this.waCpr,
    this.waCprDetails,
    this.waAssistedVentilation,
    this.waAssistedVentilationDetails,
    this.waArtificialNutrition,
    this.waArtificialNutritionDetails,
    this.waArtificialHydration,
    this.waArtificialHydrationDetails,
    this.waAntibiotics,
    this.waAntibioticsDetails,
    this.waBloodProducts,
    this.waBloodProductsDetails,
    this.waDialysis,
    this.waDialysisDetails,
    this.waOtherTreatmentName,
    this.waOtherTreatment,
    this.waOtherTreatmentDetails,
    this.waMrPlacebos,
    this.waMrUseEquipment,
    this.waMrLessPractitioners,
    this.waMrComparativeAssessment,
    this.waMrBloodSamples,
    this.waMrTissueSample,
    this.waMrNonIntrusiveTreatment,
    this.waMrBeingObserved,
    this.waMrUndertakingSurvey,
    this.waMrCollectingDisclosing,
    this.waMrEvaluatingSamples,
    this.waMrOther,
    this.waInterpreterChoice,
    this.waEpgChoice,
    this.waEpgDate,
    this.waEpgLocation,
    this.waGuardianFirstName,
    this.waGuardianPhone,
    this.waSubstituteGuardianFirstName,
    this.waSubstituteGuardianPhone,
    this.waOtherSubstituteFirstName,
    this.waOtherSubstitutePhone,
    this.waMedicalAdviceChoice,
    this.waMedicalAdvisorFirstName,
    this.waMedicalAdvisorPhone,
    this.waMedicalAdvisorPractice,
    this.waLegalAdviceChoice,
    this.waLegalAdvisorFirstName,
    this.waLegalAdvisorPhone,
    this.waLegalAdvisorPractice,
    this.waAuthorisation,
    // SA-specific
    this.saConditionsOfAppointments,
    this.saRefusalHealthCare,
    this.saExpiryDate,
    this.saLivingWell,
    this.saWhereToLive,
    this.saOtherThingsKnown,
    this.saOtherPeopleInvolved,
    this.saNearingDeath,
    this.saStatementResponse,
    this.saOrganDonationChoice,
    this.saOrganDonationInstruction,
    this.saHealthcarePreferred,
    this.saSubstituteDecisionMakers = const [],
    this.saSubDm1FullName,
    this.saSubDm1Address,
    this.saSubDm1Date,
    this.saSubDm2FullName,
    this.saSubDm2Address,
    this.saSubDm2Date,
    this.saWitnessFullName,
    this.saWitnessPhone,
    this.saWitnessSignature,
    this.saWitnessDate,
    this.saAuthorisedWitnessFullName,
    this.saWitnessCategory,
    this.saAuthorisedWitnessPhone,
    this.saAuthorisedWitnessSignature,
    this.saAuthorisedWitnessDate,
    this.saExtraExecutionStatement,
    this.saInterpreterName,
    this.saInterpreterNaati,
    this.saInterpreterSignature,
    this.saInterpreterDate,
    // NT-specific
    this.ntLifeMeaning,
    this.ntNearingDeathGoals,
    this.ntUnacceptableOutcomes,
    this.ntPalliativeCare,
    this.ntWhereToDie,
    this.ntWhereToDieChoice,
    this.ntOtherMedicalInfo,
    this.ntCulturalRequests,
    this.ntAfterDeath1,
    this.ntAfterDeath2,
    this.ntCprChoice,
    this.ntCprConditionDetails,
    this.ntRefusedTreatments = const [],
    this.ntRefusedTreatmentOther,
    this.ntReligiousBeliefs,
    this.ntDecisionMakers = const [],
    this.ntAppointedDecisionMakers = const [],
    this.ntDecisionMethod,
    this.ntDecisionMethodOther,
    this.ntSign,
    // TAS-specific
    this.tasHealthConditions,
    this.tasViewsWishes,
    this.tasMedicalTreatmentRefuse,
    this.tasMedicalCircumstances,
    this.tasOrganDonorRegister,
    this.tasBodyBequestProgram,
    this.tasExpiryDate,
    this.tasRevokeAcd,
    this.tasRevokeSignature,
    this.tasRevokeDate,
    this.tasSignFullName,
    this.tasSignSignature,
    this.tasSignDate,
    this.tasDelegatedPersonName,
    this.tasDelegatedAcdPersonName,
    this.tasDelegatedRelationship,
    this.tasDelegatedSignature,
    this.tasDelegatedDate,
    this.tasWitnesses = const [],
    this.tasInterpreterName,
    this.tasInterpreterLanguage,
    this.tasInterpreterSignature,
    this.tasInterpreterDob,
    this.tasInterpreterNaati,
    // ACT-specific
    this.actMedicalTreatmentRefuse,
    this.actDirectedPersonName,
    this.actDirectedPersonAddress,
    this.actRevokePreviousDirections,
    this.actWitness1FullName,
    this.actWitness1Address,
  });

  AhdFlowData copyWith({
    String? fullName,
    String? dob,
    String? addressLine1,
    String? suburb,
    String? postcode,
    String? state,
    String? phone,
    String? email,
    String? healthConditions,
    String? thingsImportant,
    String? thingsWorry,
    String? culturalValues,
    String? nearingDeathComfort,
    String? nearingDeathImportant,
    String? peopleNotInvolved,
    String? lifeSustainingDirective,
    String? lifeSustainingDirectiveDetails,
    String? lifeSustainingTreatment,
    String? lifeSustainingTreatmentDetails,
    String? assistedVentilation,
    String? assistedVentilationDetails,
    String? artificialNutrition,
    String? artificialNutritionDetails,
    String? artificialHydration,
    String? artificialHydrationDetails,
    String? antibiotics,
    String? antibioticsDetails,
    String? otherTreatment,
    String? otherTreatmentDetails,
    String? lstStateTreatment,
    List<HealthCareDirection>? otherHealthCareDirections,
    String? bloodTransfusionChoice,
    String? bloodTransfusionOther,
    String? doctorName,
    String? facilityName,
    String? doctorDob,
    String? doctorAddress,
    String? doctorSuburb,
    String? doctorPostcode,
    String? doctorState,
    String? doctorPhone,
    String? doctorSign,
    List<AhdAttorneyData>? healthAttorneys,
    String? attorneyDecisionMethod,
    String? attorneyDecisionOther,
    String? attorneyTerms,
    String? declarationDetails,
    // Victoria-specific
    String? vicUnacceptableOutcomes,
    String? vicOtherThingsKnown,
    String? vicPeopleInvolved,
    String? vicOrganDonation,
    String? vicConsentTreatment,
    String? vicRefuseTreatment,
    String? vicPersonSign,
    String? vicRefuseMedicalTreatment,
    String? vicWitness1FullName,
    String? vicWitness1Qualification,
    String? vicWitness1Signature,
    String? vicWitness1Date,
    String? vicWitness2FullName,
    String? vicWitness2Signature,
    String? vicWitness2Date,
    String? vicInterpreterName,
    String? vicInterpreterNaati,
    String? vicInterpreterLanguage,
    String? vicInterpreterSignature,
    String? vicInterpreterDate,
    // NSW-specific
    String? nswCannotRecogniseFamily,
    String? nswNoBladderControl,
    String? nswCannotFeedWashDress,
    String? nswCannotMoveInOutBed,
    String? nswCannotMoveReposition,
    String? nswCannotEatDrink,
    String? nswEndOfLifeCare,
    String? nswCprChoice,
    String? nswMedicalTreatmentType,
    String? nswMedicalTreatmentOther,
    bool? nswDonateOrgans,
    bool? nswDiscussedDonation,
    bool? nswDonateBody,
    bool? nswConsentOrganDonation,
    List<AhdAttorneyData>? nswPersonsResponsible,
    bool? nswHasEnduringGuardian,
    List<AhdAttorneyData>? nswEnduringGuardians,
    String? nswAuthorisation,
    // WA-specific
    bool? waRevokeAcd,
    String? waHealthConditions,
    String? waTreatmentPreferences,
    List<String>? waLivingWellChoices,
    String? waWorries,
    List<String>? waNearingDeathLocations,
    String? waNearingDeathLocationDetails,
    List<String>? waComfortChoices,
    String? waComfortPainDetails,
    String? waComfortSurroundingsDetails,
    String? waLifeSustainingTreatment,
    String? waLifeSustainingDetails,
    String? waCpr,
    String? waCprDetails,
    String? waAssistedVentilation,
    String? waAssistedVentilationDetails,
    String? waArtificialNutrition,
    String? waArtificialNutritionDetails,
    String? waArtificialHydration,
    String? waArtificialHydrationDetails,
    String? waAntibiotics,
    String? waAntibioticsDetails,
    String? waBloodProducts,
    String? waBloodProductsDetails,
    String? waDialysis,
    String? waDialysisDetails,
    String? waOtherTreatmentName,
    String? waOtherTreatment,
    String? waOtherTreatmentDetails,
    String? waMrPlacebos,
    String? waMrUseEquipment,
    String? waMrLessPractitioners,
    String? waMrComparativeAssessment,
    String? waMrBloodSamples,
    String? waMrTissueSample,
    String? waMrNonIntrusiveTreatment,
    String? waMrBeingObserved,
    String? waMrUndertakingSurvey,
    String? waMrCollectingDisclosing,
    String? waMrEvaluatingSamples,
    String? waMrOther,
    String? waInterpreterChoice,
    String? waEpgChoice,
    String? waEpgDate,
    String? waEpgLocation,
    String? waGuardianFirstName,
    String? waGuardianPhone,
    String? waSubstituteGuardianFirstName,
    String? waSubstituteGuardianPhone,
    String? waOtherSubstituteFirstName,
    String? waOtherSubstitutePhone,
    String? waMedicalAdviceChoice,
    String? waMedicalAdvisorFirstName,
    String? waMedicalAdvisorPhone,
    String? waMedicalAdvisorPractice,
    String? waLegalAdviceChoice,
    String? waLegalAdvisorFirstName,
    String? waLegalAdvisorPhone,
    String? waLegalAdvisorPractice,
    String? waAuthorisation,
    // SA-specific
    String? saConditionsOfAppointments,
    String? saRefusalHealthCare,
    String? saExpiryDate,
    String? saLivingWell,
    String? saWhereToLive,
    String? saOtherThingsKnown,
    String? saOtherPeopleInvolved,
    String? saNearingDeath,
    String? saStatementResponse,
    String? saOrganDonationChoice,
    String? saOrganDonationInstruction,
    String? saHealthcarePreferred,
    List<AhdAttorneyData>? saSubstituteDecisionMakers,
    String? saSubDm1FullName,
    String? saSubDm1Address,
    String? saSubDm1Date,
    String? saSubDm2FullName,
    String? saSubDm2Address,
    String? saSubDm2Date,
    String? saWitnessFullName,
    String? saWitnessPhone,
    String? saWitnessSignature,
    String? saWitnessDate,
    String? saAuthorisedWitnessFullName,
    String? saWitnessCategory,
    String? saAuthorisedWitnessPhone,
    String? saAuthorisedWitnessSignature,
    String? saAuthorisedWitnessDate,
    String? saExtraExecutionStatement,
    String? saInterpreterName,
    String? saInterpreterNaati,
    String? saInterpreterSignature,
    String? saInterpreterDate,
    // NT-specific
    String? ntLifeMeaning,
    String? ntNearingDeathGoals,
    String? ntUnacceptableOutcomes,
    String? ntPalliativeCare,
    String? ntWhereToDie,
    String? ntWhereToDieChoice,
    String? ntOtherMedicalInfo,
    String? ntCulturalRequests,
    String? ntAfterDeath1,
    String? ntAfterDeath2,
    String? ntCprChoice,
    String? ntCprConditionDetails,
    List<String>? ntRefusedTreatments,
    String? ntRefusedTreatmentOther,
    String? ntReligiousBeliefs,
    List<AhdAttorneyData>? ntDecisionMakers,
    List<AhdAttorneyData>? ntAppointedDecisionMakers,
    String? ntDecisionMethod,
    String? ntDecisionMethodOther,
    String? ntSign,
    // TAS-specific
    String? tasHealthConditions,
    String? tasViewsWishes,
    String? tasMedicalTreatmentRefuse,
    String? tasMedicalCircumstances,
    bool? tasOrganDonorRegister,
    bool? tasBodyBequestProgram,
    String? tasExpiryDate,
    bool? tasRevokeAcd,
    String? tasRevokeSignature,
    String? tasRevokeDate,
    String? tasSignFullName,
    String? tasSignSignature,
    String? tasSignDate,
    String? tasDelegatedPersonName,
    String? tasDelegatedAcdPersonName,
    String? tasDelegatedRelationship,
    String? tasDelegatedSignature,
    String? tasDelegatedDate,
    List<AhdAttorneyData>? tasWitnesses,
    String? tasInterpreterName,
    String? tasInterpreterLanguage,
    String? tasInterpreterSignature,
    String? tasInterpreterDob,
    String? tasInterpreterNaati,
    // ACT-specific
    String? actMedicalTreatmentRefuse,
    String? actDirectedPersonName,
    String? actDirectedPersonAddress,
    bool? actRevokePreviousDirections,
    String? actWitness1FullName,
    String? actWitness1Address,
  }) {
    return AhdFlowData(
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      addressLine1: addressLine1 ?? this.addressLine1,
      suburb: suburb ?? this.suburb,
      postcode: postcode ?? this.postcode,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      healthConditions: healthConditions ?? this.healthConditions,
      thingsImportant: thingsImportant ?? this.thingsImportant,
      thingsWorry: thingsWorry ?? this.thingsWorry,
      culturalValues: culturalValues ?? this.culturalValues,
      nearingDeathComfort: nearingDeathComfort ?? this.nearingDeathComfort,
      nearingDeathImportant:
          nearingDeathImportant ?? this.nearingDeathImportant,
      peopleNotInvolved: peopleNotInvolved ?? this.peopleNotInvolved,
      lifeSustainingDirective:
          lifeSustainingDirective ?? this.lifeSustainingDirective,
      lifeSustainingDirectiveDetails:
          lifeSustainingDirectiveDetails ?? this.lifeSustainingDirectiveDetails,
      lifeSustainingTreatment:
          lifeSustainingTreatment ?? this.lifeSustainingTreatment,
      lifeSustainingTreatmentDetails:
          lifeSustainingTreatmentDetails ?? this.lifeSustainingTreatmentDetails,
      assistedVentilation: assistedVentilation ?? this.assistedVentilation,
      assistedVentilationDetails:
          assistedVentilationDetails ?? this.assistedVentilationDetails,
      artificialNutrition: artificialNutrition ?? this.artificialNutrition,
      artificialNutritionDetails:
          artificialNutritionDetails ?? this.artificialNutritionDetails,
      artificialHydration: artificialHydration ?? this.artificialHydration,
      artificialHydrationDetails:
          artificialHydrationDetails ?? this.artificialHydrationDetails,
      antibiotics: antibiotics ?? this.antibiotics,
      antibioticsDetails: antibioticsDetails ?? this.antibioticsDetails,
      otherTreatment: otherTreatment ?? this.otherTreatment,
      otherTreatmentDetails:
          otherTreatmentDetails ?? this.otherTreatmentDetails,
      lstStateTreatment: lstStateTreatment ?? this.lstStateTreatment,
      otherHealthCareDirections:
          otherHealthCareDirections ?? this.otherHealthCareDirections,
      bloodTransfusionChoice:
          bloodTransfusionChoice ?? this.bloodTransfusionChoice,
      bloodTransfusionOther:
          bloodTransfusionOther ?? this.bloodTransfusionOther,
      doctorName: doctorName ?? this.doctorName,
      facilityName: facilityName ?? this.facilityName,
      doctorDob: doctorDob ?? this.doctorDob,
      doctorAddress: doctorAddress ?? this.doctorAddress,
      doctorSuburb: doctorSuburb ?? this.doctorSuburb,
      doctorPostcode: doctorPostcode ?? this.doctorPostcode,
      doctorState: doctorState ?? this.doctorState,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      doctorSign: doctorSign ?? this.doctorSign,
      healthAttorneys: healthAttorneys ?? this.healthAttorneys,
      attorneyDecisionMethod:
          attorneyDecisionMethod ?? this.attorneyDecisionMethod,
      attorneyDecisionOther:
          attorneyDecisionOther ?? this.attorneyDecisionOther,
      attorneyTerms: attorneyTerms ?? this.attorneyTerms,
      declarationDetails: declarationDetails ?? this.declarationDetails,
      // Victoria-specific
      vicUnacceptableOutcomes:
          vicUnacceptableOutcomes ?? this.vicUnacceptableOutcomes,
      vicOtherThingsKnown:
          vicOtherThingsKnown ?? this.vicOtherThingsKnown,
      vicPeopleInvolved: vicPeopleInvolved ?? this.vicPeopleInvolved,
      vicOrganDonation: vicOrganDonation ?? this.vicOrganDonation,
      vicConsentTreatment:
          vicConsentTreatment ?? this.vicConsentTreatment,
      vicRefuseTreatment: vicRefuseTreatment ?? this.vicRefuseTreatment,
      vicPersonSign: vicPersonSign ?? this.vicPersonSign,
      vicRefuseMedicalTreatment:
          vicRefuseMedicalTreatment ?? this.vicRefuseMedicalTreatment,
      vicWitness1FullName:
          vicWitness1FullName ?? this.vicWitness1FullName,
      vicWitness1Qualification:
          vicWitness1Qualification ?? this.vicWitness1Qualification,
      vicWitness1Signature:
          vicWitness1Signature ?? this.vicWitness1Signature,
      vicWitness1Date: vicWitness1Date ?? this.vicWitness1Date,
      vicWitness2FullName:
          vicWitness2FullName ?? this.vicWitness2FullName,
      vicWitness2Signature:
          vicWitness2Signature ?? this.vicWitness2Signature,
      vicWitness2Date: vicWitness2Date ?? this.vicWitness2Date,
      vicInterpreterName:
          vicInterpreterName ?? this.vicInterpreterName,
      vicInterpreterNaati:
          vicInterpreterNaati ?? this.vicInterpreterNaati,
      vicInterpreterLanguage:
          vicInterpreterLanguage ?? this.vicInterpreterLanguage,
      vicInterpreterSignature:
          vicInterpreterSignature ?? this.vicInterpreterSignature,
      vicInterpreterDate: vicInterpreterDate ?? this.vicInterpreterDate,
      // NSW-specific
      nswCannotRecogniseFamily:
          nswCannotRecogniseFamily ?? this.nswCannotRecogniseFamily,
      nswNoBladderControl:
          nswNoBladderControl ?? this.nswNoBladderControl,
      nswCannotFeedWashDress:
          nswCannotFeedWashDress ?? this.nswCannotFeedWashDress,
      nswCannotMoveInOutBed:
          nswCannotMoveInOutBed ?? this.nswCannotMoveInOutBed,
      nswCannotMoveReposition:
          nswCannotMoveReposition ?? this.nswCannotMoveReposition,
      nswCannotEatDrink: nswCannotEatDrink ?? this.nswCannotEatDrink,
      nswEndOfLifeCare: nswEndOfLifeCare ?? this.nswEndOfLifeCare,
      nswCprChoice: nswCprChoice ?? this.nswCprChoice,
      nswMedicalTreatmentType:
          nswMedicalTreatmentType ?? this.nswMedicalTreatmentType,
      nswMedicalTreatmentOther:
          nswMedicalTreatmentOther ?? this.nswMedicalTreatmentOther,
      nswDonateOrgans: nswDonateOrgans ?? this.nswDonateOrgans,
      nswDiscussedDonation:
          nswDiscussedDonation ?? this.nswDiscussedDonation,
      nswDonateBody: nswDonateBody ?? this.nswDonateBody,
      nswConsentOrganDonation:
          nswConsentOrganDonation ?? this.nswConsentOrganDonation,
      nswPersonsResponsible:
          nswPersonsResponsible ?? this.nswPersonsResponsible,
      nswHasEnduringGuardian:
          nswHasEnduringGuardian ?? this.nswHasEnduringGuardian,
      nswEnduringGuardians:
          nswEnduringGuardians ?? this.nswEnduringGuardians,
      nswAuthorisation: nswAuthorisation ?? this.nswAuthorisation,
      // WA-specific
      waRevokeAcd: waRevokeAcd ?? this.waRevokeAcd,
      waHealthConditions: waHealthConditions ?? this.waHealthConditions,
      waTreatmentPreferences:
          waTreatmentPreferences ?? this.waTreatmentPreferences,
      waLivingWellChoices:
          waLivingWellChoices ?? this.waLivingWellChoices,
      waWorries: waWorries ?? this.waWorries,
      waNearingDeathLocations:
          waNearingDeathLocations ?? this.waNearingDeathLocations,
      waNearingDeathLocationDetails:
          waNearingDeathLocationDetails ?? this.waNearingDeathLocationDetails,
      waComfortChoices: waComfortChoices ?? this.waComfortChoices,
      waComfortPainDetails:
          waComfortPainDetails ?? this.waComfortPainDetails,
      waComfortSurroundingsDetails:
          waComfortSurroundingsDetails ?? this.waComfortSurroundingsDetails,
      waLifeSustainingTreatment:
          waLifeSustainingTreatment ?? this.waLifeSustainingTreatment,
      waLifeSustainingDetails:
          waLifeSustainingDetails ?? this.waLifeSustainingDetails,
      waCpr: waCpr ?? this.waCpr,
      waCprDetails: waCprDetails ?? this.waCprDetails,
      waAssistedVentilation:
          waAssistedVentilation ?? this.waAssistedVentilation,
      waAssistedVentilationDetails:
          waAssistedVentilationDetails ?? this.waAssistedVentilationDetails,
      waArtificialNutrition:
          waArtificialNutrition ?? this.waArtificialNutrition,
      waArtificialNutritionDetails:
          waArtificialNutritionDetails ?? this.waArtificialNutritionDetails,
      waArtificialHydration:
          waArtificialHydration ?? this.waArtificialHydration,
      waArtificialHydrationDetails:
          waArtificialHydrationDetails ?? this.waArtificialHydrationDetails,
      waAntibiotics: waAntibiotics ?? this.waAntibiotics,
      waAntibioticsDetails:
          waAntibioticsDetails ?? this.waAntibioticsDetails,
      waBloodProducts: waBloodProducts ?? this.waBloodProducts,
      waBloodProductsDetails:
          waBloodProductsDetails ?? this.waBloodProductsDetails,
      waDialysis: waDialysis ?? this.waDialysis,
      waDialysisDetails: waDialysisDetails ?? this.waDialysisDetails,
      waOtherTreatmentName: waOtherTreatmentName ?? this.waOtherTreatmentName,
      waOtherTreatment: waOtherTreatment ?? this.waOtherTreatment,
      waOtherTreatmentDetails: waOtherTreatmentDetails ?? this.waOtherTreatmentDetails,
      waMrPlacebos: waMrPlacebos ?? this.waMrPlacebos,
      waMrUseEquipment: waMrUseEquipment ?? this.waMrUseEquipment,
      waMrLessPractitioners: waMrLessPractitioners ?? this.waMrLessPractitioners,
      waMrComparativeAssessment: waMrComparativeAssessment ?? this.waMrComparativeAssessment,
      waMrBloodSamples: waMrBloodSamples ?? this.waMrBloodSamples,
      waMrTissueSample: waMrTissueSample ?? this.waMrTissueSample,
      waMrNonIntrusiveTreatment: waMrNonIntrusiveTreatment ?? this.waMrNonIntrusiveTreatment,
      waMrBeingObserved: waMrBeingObserved ?? this.waMrBeingObserved,
      waMrUndertakingSurvey: waMrUndertakingSurvey ?? this.waMrUndertakingSurvey,
      waMrCollectingDisclosing: waMrCollectingDisclosing ?? this.waMrCollectingDisclosing,
      waMrEvaluatingSamples: waMrEvaluatingSamples ?? this.waMrEvaluatingSamples,
      waMrOther: waMrOther ?? this.waMrOther,
      waInterpreterChoice:
          waInterpreterChoice ?? this.waInterpreterChoice,
      waEpgChoice: waEpgChoice ?? this.waEpgChoice,
      waEpgDate: waEpgDate ?? this.waEpgDate,
      waEpgLocation: waEpgLocation ?? this.waEpgLocation,
      waGuardianFirstName:
          waGuardianFirstName ?? this.waGuardianFirstName,
      waGuardianPhone: waGuardianPhone ?? this.waGuardianPhone,
      waSubstituteGuardianFirstName:
          waSubstituteGuardianFirstName ?? this.waSubstituteGuardianFirstName,
      waSubstituteGuardianPhone:
          waSubstituteGuardianPhone ?? this.waSubstituteGuardianPhone,
      waOtherSubstituteFirstName:
          waOtherSubstituteFirstName ?? this.waOtherSubstituteFirstName,
      waOtherSubstitutePhone:
          waOtherSubstitutePhone ?? this.waOtherSubstitutePhone,
      waMedicalAdviceChoice:
          waMedicalAdviceChoice ?? this.waMedicalAdviceChoice,
      waMedicalAdvisorFirstName:
          waMedicalAdvisorFirstName ?? this.waMedicalAdvisorFirstName,
      waMedicalAdvisorPhone:
          waMedicalAdvisorPhone ?? this.waMedicalAdvisorPhone,
      waMedicalAdvisorPractice:
          waMedicalAdvisorPractice ?? this.waMedicalAdvisorPractice,
      waLegalAdviceChoice:
          waLegalAdviceChoice ?? this.waLegalAdviceChoice,
      waLegalAdvisorFirstName:
          waLegalAdvisorFirstName ?? this.waLegalAdvisorFirstName,
      waLegalAdvisorPhone:
          waLegalAdvisorPhone ?? this.waLegalAdvisorPhone,
      waLegalAdvisorPractice:
          waLegalAdvisorPractice ?? this.waLegalAdvisorPractice,
      waAuthorisation: waAuthorisation ?? this.waAuthorisation,
      // SA-specific
      saConditionsOfAppointments:
          saConditionsOfAppointments ?? this.saConditionsOfAppointments,
      saRefusalHealthCare:
          saRefusalHealthCare ?? this.saRefusalHealthCare,
      saExpiryDate: saExpiryDate ?? this.saExpiryDate,
      saLivingWell: saLivingWell ?? this.saLivingWell,
      saWhereToLive: saWhereToLive ?? this.saWhereToLive,
      saOtherThingsKnown:
          saOtherThingsKnown ?? this.saOtherThingsKnown,
      saOtherPeopleInvolved:
          saOtherPeopleInvolved ?? this.saOtherPeopleInvolved,
      saNearingDeath: saNearingDeath ?? this.saNearingDeath,
      saStatementResponse:
          saStatementResponse ?? this.saStatementResponse,
      saOrganDonationChoice:
          saOrganDonationChoice ?? this.saOrganDonationChoice,
      saOrganDonationInstruction:
          saOrganDonationInstruction ?? this.saOrganDonationInstruction,
      saHealthcarePreferred:
          saHealthcarePreferred ?? this.saHealthcarePreferred,
      saSubstituteDecisionMakers:
          saSubstituteDecisionMakers ?? this.saSubstituteDecisionMakers,
      saSubDm1FullName: saSubDm1FullName ?? this.saSubDm1FullName,
      saSubDm1Address: saSubDm1Address ?? this.saSubDm1Address,
      saSubDm1Date: saSubDm1Date ?? this.saSubDm1Date,
      saSubDm2FullName: saSubDm2FullName ?? this.saSubDm2FullName,
      saSubDm2Address: saSubDm2Address ?? this.saSubDm2Address,
      saSubDm2Date: saSubDm2Date ?? this.saSubDm2Date,
      saWitnessFullName: saWitnessFullName ?? this.saWitnessFullName,
      saWitnessPhone: saWitnessPhone ?? this.saWitnessPhone,
      saWitnessSignature: saWitnessSignature ?? this.saWitnessSignature,
      saWitnessDate: saWitnessDate ?? this.saWitnessDate,
      saAuthorisedWitnessFullName:
          saAuthorisedWitnessFullName ?? this.saAuthorisedWitnessFullName,
      saWitnessCategory: saWitnessCategory ?? this.saWitnessCategory,
      saAuthorisedWitnessPhone:
          saAuthorisedWitnessPhone ?? this.saAuthorisedWitnessPhone,
      saAuthorisedWitnessSignature:
          saAuthorisedWitnessSignature ?? this.saAuthorisedWitnessSignature,
      saAuthorisedWitnessDate:
          saAuthorisedWitnessDate ?? this.saAuthorisedWitnessDate,
      saExtraExecutionStatement:
          saExtraExecutionStatement ?? this.saExtraExecutionStatement,
      saInterpreterName: saInterpreterName ?? this.saInterpreterName,
      saInterpreterNaati: saInterpreterNaati ?? this.saInterpreterNaati,
      saInterpreterSignature:
          saInterpreterSignature ?? this.saInterpreterSignature,
      saInterpreterDate: saInterpreterDate ?? this.saInterpreterDate,
      // NT-specific
      ntLifeMeaning: ntLifeMeaning ?? this.ntLifeMeaning,
      ntNearingDeathGoals:
          ntNearingDeathGoals ?? this.ntNearingDeathGoals,
      ntUnacceptableOutcomes:
          ntUnacceptableOutcomes ?? this.ntUnacceptableOutcomes,
      ntPalliativeCare: ntPalliativeCare ?? this.ntPalliativeCare,
      ntWhereToDie: ntWhereToDie ?? this.ntWhereToDie,
      ntWhereToDieChoice:
          ntWhereToDieChoice ?? this.ntWhereToDieChoice,
      ntOtherMedicalInfo:
          ntOtherMedicalInfo ?? this.ntOtherMedicalInfo,
      ntCulturalRequests:
          ntCulturalRequests ?? this.ntCulturalRequests,
      ntAfterDeath1: ntAfterDeath1 ?? this.ntAfterDeath1,
      ntAfterDeath2: ntAfterDeath2 ?? this.ntAfterDeath2,
      ntCprChoice: ntCprChoice ?? this.ntCprChoice,
      ntCprConditionDetails:
          ntCprConditionDetails ?? this.ntCprConditionDetails,
      ntRefusedTreatments:
          ntRefusedTreatments ?? this.ntRefusedTreatments,
      ntRefusedTreatmentOther:
          ntRefusedTreatmentOther ?? this.ntRefusedTreatmentOther,
      ntReligiousBeliefs:
          ntReligiousBeliefs ?? this.ntReligiousBeliefs,
      ntDecisionMakers:
          ntDecisionMakers ?? this.ntDecisionMakers,
      ntAppointedDecisionMakers:
          ntAppointedDecisionMakers ?? this.ntAppointedDecisionMakers,
      ntDecisionMethod: ntDecisionMethod ?? this.ntDecisionMethod,
      ntDecisionMethodOther:
          ntDecisionMethodOther ?? this.ntDecisionMethodOther,
      ntSign: ntSign ?? this.ntSign,
      // TAS-specific
      tasHealthConditions:
          tasHealthConditions ?? this.tasHealthConditions,
      tasViewsWishes: tasViewsWishes ?? this.tasViewsWishes,
      tasMedicalTreatmentRefuse:
          tasMedicalTreatmentRefuse ?? this.tasMedicalTreatmentRefuse,
      tasMedicalCircumstances:
          tasMedicalCircumstances ?? this.tasMedicalCircumstances,
      tasOrganDonorRegister:
          tasOrganDonorRegister ?? this.tasOrganDonorRegister,
      tasBodyBequestProgram:
          tasBodyBequestProgram ?? this.tasBodyBequestProgram,
      tasExpiryDate: tasExpiryDate ?? this.tasExpiryDate,
      tasRevokeAcd: tasRevokeAcd ?? this.tasRevokeAcd,
      tasRevokeSignature: tasRevokeSignature ?? this.tasRevokeSignature,
      tasRevokeDate: tasRevokeDate ?? this.tasRevokeDate,
      tasSignFullName: tasSignFullName ?? this.tasSignFullName,
      tasSignSignature: tasSignSignature ?? this.tasSignSignature,
      tasSignDate: tasSignDate ?? this.tasSignDate,
      tasDelegatedPersonName:
          tasDelegatedPersonName ?? this.tasDelegatedPersonName,
      tasDelegatedAcdPersonName:
          tasDelegatedAcdPersonName ?? this.tasDelegatedAcdPersonName,
      tasDelegatedRelationship:
          tasDelegatedRelationship ?? this.tasDelegatedRelationship,
      tasDelegatedSignature:
          tasDelegatedSignature ?? this.tasDelegatedSignature,
      tasDelegatedDate: tasDelegatedDate ?? this.tasDelegatedDate,
      tasWitnesses: tasWitnesses ?? this.tasWitnesses,
      tasInterpreterName: tasInterpreterName ?? this.tasInterpreterName,
      tasInterpreterLanguage:
          tasInterpreterLanguage ?? this.tasInterpreterLanguage,
      tasInterpreterSignature:
          tasInterpreterSignature ?? this.tasInterpreterSignature,
      tasInterpreterDob: tasInterpreterDob ?? this.tasInterpreterDob,
      tasInterpreterNaati: tasInterpreterNaati ?? this.tasInterpreterNaati,
      // ACT-specific
      actMedicalTreatmentRefuse:
          actMedicalTreatmentRefuse ?? this.actMedicalTreatmentRefuse,
      actDirectedPersonName:
          actDirectedPersonName ?? this.actDirectedPersonName,
      actDirectedPersonAddress:
          actDirectedPersonAddress ?? this.actDirectedPersonAddress,
      actRevokePreviousDirections:
          actRevokePreviousDirections ?? this.actRevokePreviousDirections,
      actWitness1FullName:
          actWitness1FullName ?? this.actWitness1FullName,
      actWitness1Address: actWitness1Address ?? this.actWitness1Address,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // API Serialization
  // ══════════════════════════════════════════════════════════════════════════

  /// Convert AhdFlowData → API JSON body for POST /user/ahd.
  Map<String, dynamic> toApiJson() {
    final json = <String, dynamic>{};

    // ── High-level flags ──
    if (tasExpiryDate != null) json['acd_expiry_date'] = tasExpiryDate;
    if (saExpiryDate != null) {
      json['acd_expiry_date'] = saExpiryDate;
      json['expiry_date'] = saExpiryDate;
    }
    if (tasRevokeAcd != null) json['is_acd_revoked'] = tasRevokeAcd;
    if (waRevokeAcd != null) json['is_acd_revoked'] = waRevokeAcd;
    if (actRevokePreviousDirections != null) {
      json['is_acd_revoked'] = actRevokePreviousDirections;
    }
    if (tasOrganDonorRegister != null) {
      json['is_registered_australian_organ_donor'] = tasOrganDonorRegister;
    }
    if (tasBodyBequestProgram != null) {
      json['is_registered_tasmania_bequest_program'] = tasBodyBequestProgram;
    }
    if (nswHasEnduringGuardian != null) {
      json['is_enduring_guardian_appointed'] = nswHasEnduringGuardian;
    }

    // ── VIC: person sign / refuse treatment ──
    _putIfNotEmpty(json, 'medical_treatment_consent', vicPersonSign);
    _putIfNotEmpty(json, 'medical_treatment_refuse', vicRefuseMedicalTreatment);

    // ── ACT: medical treatment refuse ──
    _putIfNotEmpty(json, 'medical_treatment_refuse', actMedicalTreatmentRefuse);

    // ── health_conditions DTO ──
    final healthConditionsDto = <String, dynamic>{};
    _putIfNotEmpty(healthConditionsDto, 'major_health_conditions',
        healthConditions ?? waHealthConditions ?? tasHealthConditions);
    _putIfNotEmpty(healthConditionsDto, 'things_important_for_me',
        thingsImportant ?? saLivingWell ?? tasViewsWishes);
    _putIfNotEmpty(healthConditionsDto, 'beliefs_considered_during_health_care',
        culturalValues);
    _putIfNotEmpty(healthConditionsDto, 'nearing_death_preference',
        nearingDeathComfort ?? saNearingDeath);
    _putIfNotEmpty(healthConditionsDto,
        'people_not_to_involve_healthcare_discussion', peopleNotInvolved ?? saOtherPeopleInvolved);
    if (healthConditionsDto.isNotEmpty) {
      json['health_conditions'] = healthConditionsDto;
      json.addAll(healthConditionsDto); // flat fields for backend
    }

    // ── life_sustaining_treatment DTO ──
    final lstDto = <String, dynamic>{};
    _putIfNotNull(lstDto, 'direction_type',
        _mapLifeSustainingDirective(lifeSustainingDirective));
    _putIfNotEmpty(lstDto, 'direction_instruction',
        lifeSustainingDirectiveDetails);
    _putIfNotNull(lstDto, 'treatment_type',
        _mapTreatmentChoice(lifeSustainingTreatment));
    _putIfNotEmpty(lstDto, 'treatment_instruction',
        lifeSustainingTreatmentDetails ?? waLifeSustainingDetails);
    _putIfNotNull(lstDto, 'assisted_ventilation',
        _mapTreatmentChoice(assistedVentilation ?? waAssistedVentilation));
    _putIfNotEmpty(lstDto, 'assisted_ventilation_instruction',
        assistedVentilationDetails ?? waAssistedVentilationDetails);
    _putIfNotNull(lstDto, 'artificial_nutrition',
        _mapTreatmentChoice(artificialNutrition ?? waArtificialNutrition));
    _putIfNotEmpty(lstDto, 'artificial_nutrition_instruction',
        artificialNutritionDetails ?? waArtificialNutritionDetails);
    _putIfNotNull(lstDto, 'antibiotics',
        _mapTreatmentChoice(antibiotics ?? waAntibiotics));
    _putIfNotEmpty(lstDto, 'antibiotics_instruction',
        antibioticsDetails ?? waAntibioticsDetails);
    _putIfNotNull(lstDto, 'blood_transfusion',
        _mapBloodTransfusion(bloodTransfusionChoice));
    _putIfNotEmpty(lstDto, 'blood_transfusion_instruction',
        bloodTransfusionOther);
    // WA uses 'transfusion' (not 'blood_transfusion')
    _putIfNotNull(lstDto, 'transfusion',
        _mapBloodTransfusion(waBloodProducts));
    _putIfNotEmpty(lstDto, 'transfusion_instruction', waBloodProductsDetails);
    _putIfNotNull(lstDto, 'other_treatment',
        _mapTreatmentChoice(otherTreatment));
    _putIfNotEmpty(lstDto, 'other_instruction', otherTreatmentDetails);
    if (lstDto.isNotEmpty) {
      json['life_sustaining_treatment'] = lstDto;
      // Flat fields for backend — some use prefixed names, some are direct
      if (lstDto.containsKey('direction_type')) {
        json['life_sustaining_treatment_direction_type'] = lstDto['direction_type'];
      }
      if (lstDto.containsKey('direction_instruction')) {
        json['life_sustaining_treatment_direction_instruction'] = lstDto['direction_instruction'];
      }
      if (lstDto.containsKey('treatment_type')) {
        json['life_sustaining_treatment_type'] = lstDto['treatment_type'];
      }
      if (lstDto.containsKey('treatment_instruction')) {
        json['life_sustaining_treatment_instruction'] = lstDto['treatment_instruction'];
      }
      // These use their own name directly as flat keys
      for (final key in [
        'assisted_ventilation', 'assisted_ventilation_instruction',
        'artificial_nutrition', 'artificial_nutrition_instruction',
        'antibiotics', 'antibiotics_instruction',
        'blood_transfusion', 'blood_transfusion_instruction',
        'transfusion', 'transfusion_instruction',
        'other_treatment', 'other_instruction',
      ]) {
        if (lstDto.containsKey(key)) json[key] = lstDto[key];
      }
      // Flat alias: other_treatment → other_life_sustaining_treatment
      if (lstDto.containsKey('other_treatment')) {
        json['other_life_sustaining_treatment'] = lstDto['other_treatment'];
      }
      if (lstDto.containsKey('other_instruction')) {
        json['other_life_sustaining_instruction'] = lstDto['other_instruction'];
      }
    }

    // ── other_health_directions (top-level array) ──
    if (otherHealthCareDirections.isNotEmpty) {
      final validEntries = otherHealthCareDirections
          .where((d) => d.healthCondition.isNotEmpty || d.directions.isNotEmpty)
          .toList();
      if (validEntries.isNotEmpty) {
        json['other_health_directions'] = validEntries
            .map((d) => {
                  'health_condition': d.healthCondition,
                  'health_direction': d.directions,
                })
            .toList();
      }
    }

    // ── quality_of_life_tolerance DTO (NSW) ──
    final qolDto = <String, dynamic>{};
    _putIfNotNull(qolDto, 'no_longer_recognise_family', nswCannotRecogniseFamily);
    _putIfNotNull(qolDto, 'no_bladder_control', nswNoBladderControl);
    _putIfNotNull(qolDto, 'cant_feed_wash_dress', nswCannotFeedWashDress);
    _putIfNotNull(qolDto, 'rely_people_for_movement', nswCannotMoveInOutBed);
    _putIfNotNull(qolDto, 'need_life_tube_for_food', nswCannotEatDrink);
    _putIfNotNull(qolDto, 'cant_converse_with_people', nswEndOfLifeCare);
    if (qolDto.isNotEmpty) {
      json['quality_of_life_tolerance'] = qolDto;
      json.addAll(qolDto);
    }

    // ── cpr_and_resuscitation DTO ──
    final cprDto = <String, dynamic>{};
    _putIfNotNull(cprDto, 'medical_not_expected_to_recover',
        _mapCprChoice(nswCprChoice));
    // NSW bearability scenario "Not being able to move or reposition myself"
    // stored in cpr_instruction (uses same BEARABLE/UNBEARABLE/UNSURE values)
    _putIfNotNull(cprDto, 'cpr_instruction', nswCannotMoveReposition);
    _putIfNotNull(cprDto, 'cpr_resuscitation',
        _mapTreatmentChoice(waCpr));
    _putIfNotEmpty(cprDto, 'cpr_resuscitation_instruction', waCprDetails);
    _putIfNotNull(cprDto, 'cpr_consent', _mapNtCprChoice(ntCprChoice));
    _putIfNotEmpty(cprDto, 'cpr_consent_instruction', ntCprConditionDetails);
    if (cprDto.isNotEmpty) {
      json['cpr_and_resuscitation'] = cprDto;
      json.addAll(cprDto);
    }

    // ── organ_and_body_donation DTO ──
    final organDto = <String, dynamic>{};
    if (nswDonateOrgans != null) organDto['donate_organ'] = nswDonateOrgans;
    if (nswConsentOrganDonation != null) {
      organDto['consent_organ_donation'] = nswConsentOrganDonation;
    }
    if (nswDonateBody != null) organDto['donate_body'] = nswDonateBody;
    if (nswDiscussedDonation != null) {
      organDto['consent_body_donation'] = nswDiscussedDonation;
    }
    // VIC organ donation as authorisation text
    _putIfNotEmpty(organDto, 'authorisation',
        vicOrganDonation ?? waAuthorisation ?? nswAuthorisation);
    // SA organ donation: convert choice constant to bool
    if (saOrganDonationChoice == OrganDonationChoice.willing) {
      json['organ_donation'] = OrganDonationChoice.willing;
      organDto['donate_organ'] = true;
      organDto['consent_organ_donation'] = true;
    } else if (saOrganDonationChoice == OrganDonationChoice.notWilling) {
      json['organ_donation'] = OrganDonationChoice.notWilling;
      organDto['donate_organ'] = false;
      organDto['consent_organ_donation'] = false;
    }
    _putIfNotEmpty(organDto, 'organ_donation_instruction',
        saOrganDonationInstruction);
    if (organDto.isNotEmpty) {
      json['organ_and_body_donation'] = organDto;
      json.addAll(organDto);
    }

    // ── medical_research_consent DTO (WA) ──
    {
      final mrDto = <String, dynamic>{};
      _putIfNotNull(mrDto, 'placebos', waMrPlacebos);
      _putIfNotNull(mrDto, 'use_equipment', waMrUseEquipment);
      _putIfNotNull(mrDto, 'less_practitioners_support', waMrLessPractitioners);
      _putIfNotNull(mrDto, 'comparative_assessment', waMrComparativeAssessment);
      _putIfNotNull(mrDto, 'blood_samples', waMrBloodSamples);
      _putIfNotNull(mrDto, 'tissue_sample', waMrTissueSample);
      _putIfNotNull(mrDto, 'non_intrusive_treatment', waMrNonIntrusiveTreatment);
      _putIfNotNull(mrDto, 'being_observed', waMrBeingObserved);
      _putIfNotNull(mrDto, 'undertaking_survey', waMrUndertakingSurvey);
      _putIfNotNull(mrDto, 'collecing_disclosing_information', waMrCollectingDisclosing);
      _putIfNotNull(mrDto, 'evaluating_samples', waMrEvaluatingSamples);
      _putIfNotNull(mrDto, 'other', waMrOther);
      if (mrDto.isNotEmpty) {
        json['medical_research_consent'] = mrDto;
        json.addAll(mrDto);
      }
    }

    // ── living_preferences DTO ──
    final lpDto = <String, dynamic>{};
    // SA where to live → wish_to_live (not where_to_die_instruction)
    _putIfNotEmpty(lpDto, 'wish_to_live', saWhereToLive);
    if (waLivingWellChoices.isNotEmpty) {
      lpDto['living_well_importance'] =
          waLivingWellChoices.map(_mapWaLivingWellChoice).toList();
    }
    if (waComfortChoices.isNotEmpty) {
      lpDto['comfort_care_preferences'] = List<String>.from(waComfortChoices);
    }
    _putIfNotEmpty(lpDto, 'comfort_pain_details', waComfortPainDetails);
    _putIfNotEmpty(lpDto, 'comfort_surroundings_details',
        waComfortSurroundingsDetails);
    if (waNearingDeathLocations.isNotEmpty) {
      lpDto['is_nearing_death'] = waNearingDeathLocations
          .map((loc) => _mapWaNearingDeathLocation(loc))
          .toList();
    }
    _putIfNotEmpty(lpDto, 'nearing_death_goals_detail',
        waNearingDeathLocationDetails ?? ntNearingDeathGoals);
    _putIfNotEmpty(lpDto, 'important_people_nearing_death',
        nearingDeathImportant);
    _putIfNotEmpty(lpDto, 'nearing_death_unacceptable',
        ntUnacceptableOutcomes ?? vicUnacceptableOutcomes);
    _putIfNotNull(lpDto, 'where_to_die', _mapNtWhereToDie(ntWhereToDieChoice));
    _putIfNotEmpty(lpDto, 'where_to_die_instruction', ntWhereToDie);
    // SA healthcare priority → living_preferences.health_treatment_priority
    _putIfNotEmpty(lpDto, 'health_treatment_priority',
        waTreatmentPreferences ?? saHealthcarePreferred);
    if (lpDto.isNotEmpty) {
      json['living_preferences'] = lpDto;
      json.addAll(lpDto);
    }

    // ── treatment_decisions DTO ──
    final tdDto = <String, dynamic>{};
    _putIfNotNull(tdDto, 'artificial_hydration',
        _mapTreatmentChoice(artificialHydration ?? waArtificialHydration));
    _putIfNotEmpty(tdDto, 'artificial_hydration_instruction',
        artificialHydrationDetails ?? waArtificialHydrationDetails);
    _putIfNotEmpty(tdDto, 'consent_palliative_comfort_care', ntPalliativeCare);
    // WA dialysis → other_treatment_decision
    _putIfNotNull(tdDto, 'other_treatment_decision',
        _mapTreatmentChoice(waDialysis));
    // WA life-sustaining treatment (top-level treatment choice for WA)
    _putIfNotNull(tdDto, 'life_sustaining_treatment',
        _mapTreatmentChoice(waLifeSustainingTreatment));
    // TAS treatment decision type enum (REFUSE or CIRCUMSTANCE)
    if (tasMedicalTreatmentRefuse != null && tasMedicalTreatmentRefuse!.isNotEmpty) {
      tdDto['other_treatment_decision'] = 'REFUSE';
    } else if (tasMedicalCircumstances != null && tasMedicalCircumstances!.isNotEmpty) {
      tdDto['other_treatment_decision'] = 'CIRCUMSTANCE';
    }
    // NSW medical treatment type → other_medical_support + other_medical_support_instruction
    if (nswMedicalTreatmentType != null) {
      tdDto['other_medical_support'] =
          _mapMedicalTreatmentType(nswMedicalTreatmentType!);
      if (nswMedicalTreatmentType == MedicalTreatmentType.other &&
          nswMedicalTreatmentOther != null) {
        tdDto['other_medical_support_instruction'] = nswMedicalTreatmentOther;
      }
    }
    // NT refused treatments → specific_treatment_no_consent
    if (ntRefusedTreatments.isNotEmpty) {
      tdDto['specific_treatment_no_consent'] =
          _mapNtRefusedTreatment(ntRefusedTreatments.first);
    }
    _putIfNotEmpty(tdDto, 'specific_treatment_no_consent_instruction',
        ntRefusedTreatmentOther);
    // Shared key: other_treatment_decision_instruction
    // (only one state's value will be non-null for a given user)
    _putIfNotEmpty(tdDto, 'other_treatment_decision_instruction',
        vicConsentTreatment ??
        tasMedicalTreatmentRefuse ?? waDialysisDetails);
    // TAS circumstances → separate API key
    _putIfNotEmpty(tdDto, 'health_circumstance_decision_instruction',
        tasMedicalCircumstances);
    // SA healthcare preferred — also write to treatment_decisions for web↔mobile sync
    _putIfNotEmpty(tdDto, 'healthcare_preferred', saHealthcarePreferred);
    if (tdDto.isNotEmpty) {
      json['treatment_decisions'] = tdDto;
      json.addAll(tdDto);
    }

    // ── attorney_and_advice DTO ──
    final aaDto = <String, dynamic>{};
    _putIfNotNull(aaDto, 'attorney_decision_power', attorneyDecisionMethod);
    _putIfNotEmpty(aaDto, 'attorney_decision_power_detail',
        attorneyDecisionOther ?? ntDecisionMethodOther);
    _putIfNotNull(aaDto, 'has_used_interpreter',
        _mapWaInterpreterChoice(waInterpreterChoice));
    _putIfNotNull(aaDto, 'has_epg', _mapWaEpgChoice(waEpgChoice));
    _putIfNotEmpty(aaDto, 'epg_date', waEpgDate);
    _putIfNotEmpty(aaDto, 'epg_place_detail', waEpgLocation);
    _putIfNotNull(aaDto, 'seek_medical_advice',
        _mapWaMedicalAdvice(waMedicalAdviceChoice));
    _putIfNotNull(aaDto, 'seek_legal_advice',
        _mapWaLegalAdvice(waLegalAdviceChoice));
    if (aaDto.isNotEmpty) {
      json['attorney_and_advice'] = aaDto;
      json.addAll(aaDto);
    }

    // ── declarations_and_wishes DTO ──
    final dwDto = <String, dynamic>{};
    _putIfNotEmpty(dwDto, 'declaration',
        declarationDetails ?? saStatementResponse);
    _putIfNotEmpty(dwDto, 'what_matter_most', thingsImportant ?? ntLifeMeaning);
    _putIfNotEmpty(dwDto, 'what_worries_most', thingsWorry ?? waWorries);
    _putIfNotEmpty(dwDto, 'unacceptable_medical_treatment_outcome',
        vicUnacceptableOutcomes ?? ntUnacceptableOutcomes);
    _putIfNotEmpty(dwDto, 'other_things_known',
        vicOtherThingsKnown ?? saOtherThingsKnown);
    _putIfNotEmpty(dwDto, 'other_people_involved_in_care_discussion',
        vicPeopleInvolved);
    _putIfNotEmpty(dwDto, 'appointment_conditon',
        saConditionsOfAppointments ?? attorneyTerms);
    _putIfNotEmpty(dwDto, 'cultural_request', ntCulturalRequests);
    _putIfNotEmpty(dwDto, 'religious_beliefs', ntReligiousBeliefs);
    _putIfNotEmpty(dwDto, 'after_death_importance',
        ntAfterDeath1);
    _putIfNotEmpty(dwDto, 'nearing_death_instruction',
        ntAfterDeath2);
    _putIfNotEmpty(dwDto, 'other_medical_decision',
        saRefusalHealthCare ?? vicRefuseTreatment ?? ntOtherMedicalInfo);
    if (dwDto.isNotEmpty) {
      json['declarations_and_wishes'] = dwDto;
      json.addAll(dwDto);
    }

    // ── ahd_persons array ──
    final persons = <Map<String, dynamic>>[];

    // Doctor
    if (doctorName != null && doctorName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: doctorName!,
        personType: 'DOCTOR',
        phone: doctorPhone,
        address: doctorAddress,
        suburb: doctorSuburb,
        state: doctorState,
        postcode: doctorPostcode,
        dob: doctorDob,
        other: {
          if (facilityName != null) 'facility_name': facilityName,
          if (doctorSign != null) 'signature': doctorSign,
        },
      ));
    }

    // Health attorneys
    for (final a in healthAttorneys) {
      persons.add(_buildPersonFromAttorney(a, 'ATTORNEY_HEALTH_MATTERS'));
    }

    // VIC witnesses
    if (vicWitness1FullName != null && vicWitness1FullName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: vicWitness1FullName!,
        personType: 'WITNESS_MEDICAL_PRACTITIONER',
        qualification: vicWitness1Qualification,
        other: {
          if (vicWitness1Signature != null) 'signature': vicWitness1Signature,
          if (vicWitness1Date != null) 'date': vicWitness1Date,
        },
      ));
    }
    if (vicWitness2FullName != null && vicWitness2FullName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: vicWitness2FullName!,
        personType: 'WITNESS_PERSON',
        other: {
          if (vicWitness2Signature != null) 'signature': vicWitness2Signature,
          if (vicWitness2Date != null) 'date': vicWitness2Date,
        },
      ));
    }

    // VIC interpreter
    if (vicInterpreterName != null && vicInterpreterName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: vicInterpreterName!,
        personType: 'INTERPRETER',
        other: {
          if (vicInterpreterNaati != null) 'naati_number': vicInterpreterNaati,
          if (vicInterpreterLanguage != null) 'language': vicInterpreterLanguage,
          if (vicInterpreterSignature != null) 'signature': vicInterpreterSignature,
          if (vicInterpreterDate != null) 'date': vicInterpreterDate,
        },
      ));
    }

    // NSW persons responsible
    for (final a in nswPersonsResponsible) {
      persons.add(_buildPersonFromAttorney(a, 'MEDICAL_GUARDIAN'));
    }

    // NSW enduring guardians
    for (final a in nswEnduringGuardians) {
      persons.add(_buildPersonFromAttorney(a, 'ENDURING_GUARDIAN'));
    }

    // WA guardians
    if (waGuardianFirstName != null && waGuardianFirstName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: waGuardianFirstName!,
        personType: 'ENDURING_GUARDIAN',
        phone: waGuardianPhone,
      ));
    }
    if (waSubstituteGuardianFirstName != null &&
        waSubstituteGuardianFirstName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: waSubstituteGuardianFirstName!,
        personType: 'SECONDARY_ENDURING_GUARDIAN',
        phone: waSubstituteGuardianPhone,
      ));
    }
    if (waOtherSubstituteFirstName != null &&
        waOtherSubstituteFirstName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: waOtherSubstituteFirstName!,
        personType: 'TERTIARY_ENDURING_GUARDIAN',
        phone: waOtherSubstitutePhone,
      ));
    }

    // WA medical advisor
    if (waMedicalAdvisorFirstName != null &&
        waMedicalAdvisorFirstName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: waMedicalAdvisorFirstName!,
        personType: 'MEDICAL_ADVISOR',
        phone: waMedicalAdvisorPhone,
        other: {
          if (waMedicalAdvisorPractice != null)
            'practice': waMedicalAdvisorPractice,
        },
      ));
    }

    // WA legal advisor
    if (waLegalAdvisorFirstName != null &&
        waLegalAdvisorFirstName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: waLegalAdvisorFirstName!,
        personType: 'LEGAL_ADVISOR',
        phone: waLegalAdvisorPhone,
        other: {
          if (waLegalAdvisorPractice != null)
            'practice': waLegalAdvisorPractice,
        },
      ));
    }

    // SA substitute decision-makers (merge separate address/date fields)
    for (int i = 0; i < saSubstituteDecisionMakers.length; i++) {
      final a = saSubstituteDecisionMakers[i];
      final p = _buildPersonFromAttorney(a, 'SUBSTITUTE_DECISION_MAKER');
      final other = (p['other'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      // Overlay SA-specific address/date stored in separate flowData fields
      if (i == 0) {
        if (saSubDm1Address != null) p['address'] = saSubDm1Address;
        if (saSubDm1Date != null) other['date'] = saSubDm1Date;
      } else if (i == 1) {
        if (saSubDm2Address != null) p['address'] = saSubDm2Address;
        if (saSubDm2Date != null) other['date'] = saSubDm2Date;
      }
      if (other.isNotEmpty) p['other'] = other;
      persons.add(p);
    }

    // SA witness
    if (saWitnessFullName != null && saWitnessFullName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: saWitnessFullName!,
        phone: saWitnessPhone,
        personType: 'WITNESS_PERSON',
        other: {
          if (saWitnessSignature != null) 'signature': saWitnessSignature,
          if (saWitnessDate != null) 'date': saWitnessDate,
        },
      ));
    }

    // SA authorised witness
    if (saAuthorisedWitnessFullName != null &&
        saAuthorisedWitnessFullName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: saAuthorisedWitnessFullName!,
        personType: 'WITNESS_AUTHORIZED',
        phone: saAuthorisedWitnessPhone,
        other: {
          if (saWitnessCategory != null)
            'witness_category': _mapSaWitnessCategory(saWitnessCategory!),
          if (saAuthorisedWitnessSignature != null)
            'signature': saAuthorisedWitnessSignature,
          if (saAuthorisedWitnessDate != null)
            'date': saAuthorisedWitnessDate,
          if (saExtraExecutionStatement != null)
            'statement': saExtraExecutionStatement,
        },
      ));
    }

    // SA interpreter
    if (saInterpreterName != null && saInterpreterName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: saInterpreterName!,
        personType: 'INTERPRETER',
        other: {
          if (saInterpreterNaati != null) 'naati_number': saInterpreterNaati,
          if (saInterpreterSignature != null) 'signature': saInterpreterSignature,
          if (saInterpreterDate != null) 'date': saInterpreterDate,
        },
      ));
    }

    // NT decision makers
    for (final a in ntDecisionMakers) {
      persons.add(_buildPersonFromAttorney(a, 'PRIMARY_PERSON'));
    }
    for (final a in ntAppointedDecisionMakers) {
      persons.add(_buildPersonFromAttorney(a, 'DECISION_MAKER'));
    }

    // TAS witnesses
    for (final a in tasWitnesses) {
      persons.add(_buildPersonFromAttorney(
        a,
        a.isHealthPractitioner == true
            ? 'WITNESS_MEDICAL_PRACTITIONER'
            : 'WITNESS_PERSON',
      ));
    }

    // TAS interpreter
    if (tasInterpreterName != null && tasInterpreterName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: tasInterpreterName!,
        personType: 'INTERPRETER',
        dob: tasInterpreterDob,
        other: {
          if (tasInterpreterNaati != null) 'naati_number': tasInterpreterNaati,
          if (tasInterpreterLanguage != null) 'language': tasInterpreterLanguage,
          if (tasInterpreterSignature != null) 'signature': tasInterpreterSignature,
        },
      ));
    }

    // ACT witness
    if (actWitness1FullName != null && actWitness1FullName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: actWitness1FullName!,
        personType: 'WITNESS_PERSON',
        address: actWitness1Address,
      ));
    }

    // ACT directed person
    if (actDirectedPersonName != null &&
        actDirectedPersonName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: actDirectedPersonName!,
        personType: 'HELPER',
        address: actDirectedPersonAddress,
      ));
    }

    // TAS delegated person
    if (tasDelegatedPersonName != null &&
        tasDelegatedPersonName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: tasDelegatedPersonName!,
        personType: 'HELPER',
        other: {
          if (tasDelegatedAcdPersonName != null)
            'ahd_primary_person_name': tasDelegatedAcdPersonName,
          if (tasDelegatedRelationship != null)
            'relationship': tasDelegatedRelationship,
          if (tasDelegatedSignature != null)
            'signature': tasDelegatedSignature,
          if (tasDelegatedDate != null) 'date': tasDelegatedDate,
        },
      ));
    }

    // TAS primary person (signature)
    if (tasSignFullName != null && tasSignFullName!.trim().isNotEmpty) {
      persons.add(_buildPerson(
        fullName: tasSignFullName!,
        personType: 'PRIMARY_PERSON',
        other: {
          if (tasSignSignature != null) 'signature': tasSignSignature,
          if (tasSignDate != null) 'date': tasSignDate,
        },
      ));
    }

    if (persons.isNotEmpty) json['ahd_persons'] = persons;

    return json;
  }

  // ── Person builder helpers ──

  static Map<String, dynamic> _buildPerson({
    required String fullName,
    required String personType,
    String? qualification,
    String? dob,
    String? phone,
    String? address,
    String? suburb,
    String? state,
    String? postcode,
    Map<String, dynamic>? other,
  }) {
    final p = <String, dynamic>{
      'full_name': fullName.trim(),
      'person_type': personType,
      'country': 'Australia',
    };
    if (qualification != null) p['qualification'] = qualification;
    if (dob != null) p['dob'] = dob;
    if (phone != null) p['phone'] = phone;
    if (address != null) p['address'] = address;
    if (suburb != null) p['suburb'] = suburb;
    if (state != null) p['state'] = state;
    if (postcode != null) p['postcode'] = postcode;
    if (other != null && other.isNotEmpty) p['other'] = other;
    return p;
  }

  static Map<String, dynamic> _buildPersonFromAttorney(
      AhdAttorneyData a, String personType) {
    final other = <String, dynamic>{};
    if (a.signature != null) other['signature'] = a.signature;
    if (a.qualification != null) other['qualification'] = a.qualification;
    if (a.matters != null && personType == 'DECISION_MAKER') {
      other['matters'] = _mapNtMatters(a.matters!);
    }

    return _buildPerson(
      fullName: a.fullName,
      personType: personType,
      qualification: a.qualification,
      dob: a.dob,
      phone: a.phone,
      address: a.address,
      suburb: a.addressSuburb,
      state: a.addressState,
      postcode: a.addressPostcode,
      other: other.isNotEmpty ? other : null,
    );
  }

  // ── Enum mapping helpers (Flutter UI → API) ──

  static void _putIfNotEmpty(
      Map<String, dynamic> map, String key, String? value) {
    if (value != null && value.trim().isNotEmpty) map[key] = value.trim();
  }

  static void _putIfNotNull(
      Map<String, dynamic> map, String key, String? value) {
    if (value != null) map[key] = value;
  }

  /// TreatmentChoice: CONSENT_ALL→CONSENT, REFUSE_ALL→REFUSE,
  /// CONSENT_CIRCUMSTANCES→CIRCUMSTANCE
  static String? _mapTreatmentChoice(String? choice) {
    switch (choice) {
      case 'CONSENT_ALL':
      case 'CONSENT_TO_ALL_TREATMENT':
      case 'CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING':
        return 'CONSENT';
      case 'REFUSE_ALL':
      case 'REFUSE_ALL_TREATMENT':
        return 'REFUSE';
      case 'CONSENT_CIRCUMSTANCES':
      case 'CONSENT_SPECIFIC_TREATMENT':
        return 'CIRCUMSTANCE';
      default:
        return choice;
    }
  }

  /// Reverse: CONSENT→CONSENT_ALL, REFUSE→REFUSE_ALL,
  /// CIRCUMSTANCE→CONSENT_CIRCUMSTANCES
  static String? _unmapTreatmentChoice(String? choice) {
    switch (choice) {
      case 'CONSENT':
        return 'CONSENT_ALL';
      case 'REFUSE':
        return 'REFUSE_ALL';
      case 'CIRCUMSTANCE':
        return 'CONSENT_CIRCUMSTANCES';
      default:
        return choice;
    }
  }

  /// LifeSustainingDirective: CONSENT_ALL→CONSENT, REFUSE_ALL→REFUSE,
  /// ATTORNEY_DECIDES→ATTORNEY_DECISION, ENTER_DETAILS→SPECIFIC_DIRECTION
  static String? _mapLifeSustainingDirective(String? d) {
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


  /// BloodTransfusion: handles both BloodTransfusionChoice and TreatmentChoice values
  static String? _mapBloodTransfusion(String? choice) {
    switch (choice) {
      case 'DO_NOT_CONSENT':
      case 'REFUSE_ALL':
        return 'REFUSE';
      case 'CONSENT':
      case 'CONSENT_ALL':
        return 'CONSENT';
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

  /// Reverse map for WaLifeSustainingMain: API→UI
  static String? _unmapWaLifeSustainingTreatment(String? choice) {
    switch (choice) {
      case 'CONSENT':
        return 'CONSENT_TO_ALL_TREATMENT';
      case 'REFUSE':
        return 'REFUSE_ALL_TREATMENT';
      case 'CIRCUMSTANCE':
        return 'CONSENT_SPECIFIC_TREATMENT';
      case 'CANT_DECIDE':
        return 'CANT_DECIDE';
      default:
        return choice;
    }
  }

  static String? _unmapBloodTransfusion(String? choice) {
    switch (choice) {
      case 'REFUSE':
        return 'DO_NOT_CONSENT';
      default:
        return choice;
    }
  }

  /// CprChoice: ACCEPT→ACCEPT_CPR, DO_NOT_ACCEPT→REJECT_CPR
  static String? _mapCprChoice(String? choice) {
    switch (choice) {
      case 'ACCEPT':
        return 'ACCEPT_CPR';
      case 'DO_NOT_ACCEPT':
        return 'REJECT_CPR';
      default:
        return choice;
    }
  }

  static String? _unmapCprChoice(String? choice) {
    switch (choice) {
      case 'ACCEPT_CPR':
        return 'ACCEPT';
      case 'REJECT_CPR':
        return 'DO_NOT_ACCEPT';
      default:
        return choice;
    }
  }

  /// MedicalTreatmentType: LIFE_PROLONGING→LIFE_PROLONGING_TREATMENT
  static String _mapMedicalTreatmentType(String type) {
    switch (type) {
      case 'LIFE_PROLONGING':
        return 'LIFE_PROLONGING_TREATMENT';
      default:
        return type;
    }
  }

  static String _unmapMedicalTreatmentType(String type) {
    switch (type) {
      case 'LIFE_PROLONGING_TREATMENT':
        return 'LIFE_PROLONGING';
      default:
        return type;
    }
  }

  /// WA living well: FAMILY_FRIENDS→SPEND_TIME_WITH_FAMILY, etc.
  static String _mapWaLivingWellChoice(String key) {
    switch (key) {
      case 'FAMILY_FRIENDS':
        return 'SPEND_TIME_WITH_FAMILY';
      case 'LIVING_INDEPENDENTLY':
        return 'LIVE_INDEPENDENTLY';
      case 'SELF_CARE':
        return 'CARE_MYSELF';
      case 'KEEPING_ACTIVE':
        return 'KEEP_ACTIVE';
      case 'RELIGIOUS_CULTURAL':
        return 'PRACTISING_RELIGION';
      case 'CULTURAL_VALUES':
        return 'LIVE_WITH_CULTURAL_RELIGIOUS_VALUES';
      case 'WORKING':
        return 'WORKING_IN_A_JOB';
      default:
        return key; // VISIT_HOMETOWN, RECREATIONAL_ACTIVITIES stay the same
    }
  }

  static String _unmapWaLivingWellChoice(String key) {
    switch (key) {
      case 'SPEND_TIME_WITH_FAMILY':
        return 'FAMILY_FRIENDS';
      case 'LIVE_INDEPENDENTLY':
        return 'LIVING_INDEPENDENTLY';
      case 'CARE_MYSELF':
        return 'SELF_CARE';
      case 'KEEP_ACTIVE':
        return 'KEEPING_ACTIVE';
      case 'PRACTISING_RELIGION':
        return 'RELIGIOUS_CULTURAL';
      case 'LIVE_WITH_CULTURAL_RELIGIOUS_VALUES':
        return 'CULTURAL_VALUES';
      case 'WORKING_IN_A_JOB':
        return 'WORKING';
      default:
        return key;
    }
  }

  /// Reverse-map API comfort values back to UI keys.
  static String _unmapWaComfortChoice(String key) {
    switch (key) {
      case 'MANAGED_SYMPTOMS':
        return 'NO_PAIN';
      case 'LOVED_ONES_NEARBY':
        return 'LOVED_ONES';
      case 'CULTURAL_RELIGIOUS':
        return 'CULTURAL_TRADITIONS';
      case 'SPIRITUAL_CARE':
        return 'PASTORAL_CARE';
      case 'HEALTHY_SURROUNDINGS':
        return 'SURROUNDINGS';
      default:
        return key;
    }
  }

  /// WA nearing death: BEST_CARE→RECEIVE_CARE
  static String _mapWaNearingDeathLocation(String loc) {
    switch (loc) {
      case 'BEST_CARE':
        return 'RECEIVE_CARE';
      default:
        return loc; // AT_HOME, NOT_AT_HOME, NO_PREFERENCE, OTHER match
    }
  }

  static String _unmapWaNearingDeathLocation(String loc) {
    switch (loc) {
      case 'RECEIVE_CARE':
        return 'BEST_CARE';
      default:
        return loc;
    }
  }

  /// WA interpreter: ENGAGED_INTERPRETER→ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER
  static String? _mapWaInterpreterChoice(String? choice) {
    switch (choice) {
      case 'ENGLISH_FIRST_LANGUAGE':
        return 'ENGLISH_FIRST_LANGUAGE';
      case 'ENGAGED_INTERPRETER':
        return 'ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER';
      case 'DID_NOT_ENGAGE':
        return 'ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER';
      default:
        return choice;
    }
  }

  static String? _unmapWaInterpreterChoice(String? choice) {
    switch (choice) {
      case 'ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER':
        return 'ENGAGED_INTERPRETER';
      case 'ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER':
        return 'DID_NOT_ENGAGE';
      default:
        return choice;
    }
  }

  /// WA EPG: NOT_MADE→NOT_DONE, MADE→DONE
  static String? _mapWaEpgChoice(String? choice) {
    switch (choice) {
      case 'NOT_MADE':
        return 'NOT_DONE';
      case 'MADE':
        return 'DONE';
      default:
        return choice;
    }
  }

  static String? _unmapWaEpgChoice(String? choice) {
    switch (choice) {
      case 'NOT_DONE':
        return 'NOT_MADE';
      case 'DONE':
        return 'MADE';
      default:
        return choice;
    }
  }

  /// WA advice: DID_OBTAIN→OBTAIN_MEDICAL_ADVICE, DID_NOT_OBTAIN→NOT_OBTAIN_MEDICAL_ADVICE
  static String? _mapWaMedicalAdvice(String? choice) {
    switch (choice) {
      case 'DID_OBTAIN':
        return 'OBTAIN_MEDICAL_ADVICE';
      case 'DID_NOT_OBTAIN':
        return 'NOT_OBTAIN_MEDICAL_ADVICE';
      default:
        return choice;
    }
  }

  static String? _unmapWaMedicalAdvice(String? choice) {
    switch (choice) {
      case 'OBTAIN_MEDICAL_ADVICE':
        return 'DID_OBTAIN';
      case 'NOT_OBTAIN_MEDICAL_ADVICE':
        return 'DID_NOT_OBTAIN';
      default:
        return choice;
    }
  }

  static String? _mapWaLegalAdvice(String? choice) {
    switch (choice) {
      case 'DID_OBTAIN':
        return 'OBTAIN_LEGAL_ADVICE';
      case 'DID_NOT_OBTAIN':
        return 'NOT_OBTAIN_LEGAL_ADVICE';
      default:
        return choice;
    }
  }

  static String? _unmapWaLegalAdvice(String? choice) {
    switch (choice) {
      case 'OBTAIN_LEGAL_ADVICE':
        return 'DID_OBTAIN';
      case 'NOT_OBTAIN_LEGAL_ADVICE':
        return 'DID_NOT_OBTAIN';
      default:
        return choice;
    }
  }

  /// NT CPR: ATTEMPT_CPR→RESTART, EXCEPT_UNACCEPTABLE→CONDITION,
  /// NATURAL_DEATH→ALLOW_TO_DIE
  static String? _mapNtCprChoice(String? choice) {
    switch (choice) {
      case 'ATTEMPT_CPR':
        return 'RESTART';
      case 'EXCEPT_UNACCEPTABLE':
        return 'CONDITION';
      case 'NATURAL_DEATH':
        return 'ALLOW_TO_DIE';
      default:
        return choice;
    }
  }

  static String? _unmapNtCprChoice(String? choice) {
    switch (choice) {
      case 'RESTART':
        return 'ATTEMPT_CPR';
      case 'CONDITION':
        return 'EXCEPT_UNACCEPTABLE';
      case 'ALLOW_TO_DIE':
        return 'NATURAL_DEATH';
      default:
        return choice;
    }
  }

  /// NT where to die: AT_HOME_ON_COUNTRY→HOME, HOSPITAL_HOSPICE→HOSPITAL
  static String? _mapNtWhereToDie(String? choice) {
    switch (choice) {
      case 'AT_HOME_ON_COUNTRY':
        return 'HOME';
      case 'HOSPITAL_HOSPICE':
        return 'HOSPITAL';
      case 'OTHER':
        return 'OTHER';
      default:
        return choice;
    }
  }

  static String? _unmapNtWhereToDie(String? choice) {
    switch (choice) {
      case 'HOME':
        return 'AT_HOME_ON_COUNTRY';
      case 'HOSPITAL':
        return 'HOSPITAL_HOSPICE';
      default:
        return choice;
    }
  }

  /// NT refused treatment: BLOOD_TRANSFUSIONS→TRANSFUSIONS
  static String _mapNtRefusedTreatment(String t) {
    switch (t) {
      case 'BLOOD_TRANSFUSIONS':
        return 'TRANSFUSIONS';
      default:
        return t;
    }
  }

  static String _unmapNtRefusedTreatment(String t) {
    switch (t) {
      case 'TRANSFUSIONS':
        return 'BLOOD_TRANSFUSIONS';
      default:
        return t;
    }
  }

  /// NT matters: ALL_MATTERS→BOTH, PERSONAL_HEALTH_MATTERS→HEALTH,
  /// FINANCIAL_MATTERS→PERSONAL, LIMITED_MATTERS→PERSONAL
  static String _mapNtMatters(String m) {
    switch (m) {
      case 'ALL_MATTERS':
        return 'ALL';
      case 'PERSONAL_HEALTH_MATTERS':
        return 'PERSONAL';
      case 'FINANCIAL_MATTERS':
        return 'FINANCE';
      case 'LIMITED_MATTERS':
        return 'LIMITED';
      default:
        return m;
    }
  }

  static String _unmapNtMatters(String m) {
    switch (m) {
      case 'ALL':
        return 'ALL_MATTERS';
      case 'PERSONAL':
        return 'PERSONAL_HEALTH_MATTERS';
      case 'FINANCE':
        return 'FINANCIAL_MATTERS';
      case 'LIMITED':
        return 'LIMITED_MATTERS';
      default:
        return m;
    }
  }

  /// SA witness category mapping
  static String _mapSaWitnessCategory(String cat) {
    switch (cat) {
      case 'JUSTICE_OF_PEACE':
        return 'JUSTICE_OF_PEACE';
      case 'LEGAL_PRACTITIONER':
        return 'LAWYER';
      case 'PROCLAIMED_POLICE_OFFICER':
        return 'COMMISSIONER_FOR_DECLARATIONS';
      default:
        return cat;
    }
  }

  static String _unmapSaWitnessCategory(String cat) {
    switch (cat) {
      case 'LAWYER':
        return 'LEGAL_PRACTITIONER';
      case 'COMMISSIONER_FOR_DECLARATIONS':
        return 'PROCLAIMED_POLICE_OFFICER';
      default:
        return cat;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Deserialize API response → AhdFlowData (for prefill on edit)
  // ══════════════════════════════════════════════════════════════════════════

  /// Restructure a flat API GET response into the nested format that
  /// [fromApiJson] expects. The GET endpoint returns flat column names
  /// (e.g. `assisted_ventilation`) while the POST/nested format groups
  /// them under objects (e.g. `life_sustaining_treatment.assisted_ventilation`).
  static Map<String, dynamic> _restructureFlatResponse(
      Map<String, dynamic> flat) {
    final nested = Map<String, dynamic>.from(flat);

    void moveToGroup(String groupKey, List<String> fields) {
      final group = <String, dynamic>{};
      for (final field in fields) {
        if (flat.containsKey(field)) {
          group[field] = flat[field];
          nested.remove(field);
        }
      }
      // Also check for prefixed flat keys (e.g. life_sustaining_treatment_direction_type → direction_type)
      final prefix = '${groupKey}_';
      for (final key in flat.keys.toList()) {
        if (key.startsWith(prefix) && !fields.contains(key)) {
          final nestedKey = key.substring(prefix.length);
          group[nestedKey] = flat[key];
          nested.remove(key);
        }
      }
      if (group.isNotEmpty) {
        nested[groupKey] = group;
      }
    }

    // health_conditions
    moveToGroup('health_conditions', [
      'major_health_conditions',
      'things_important_for_me',
      'beliefs_considered_during_health_care',
      'nearing_death_preference',
      'people_not_to_involve_healthcare_discussion',
      'comfort_nearing_death',
    ]);

    // life_sustaining_treatment
    moveToGroup('life_sustaining_treatment', [
      'direction_type',
      'direction_instruction',
      'treatment_type',
      'treatment_instruction',
      'assisted_ventilation',
      'assisted_ventilation_instruction',
      'artificial_nutrition',
      'artificial_nutrition_instruction',
      'antibiotics',
      'antibiotics_instruction',
      'blood_transfusion',
      'blood_transfusion_instruction',
      'other_treatment',
      'other_instruction',
      'transfusion',
      'transfusion_instruction',
      // Flat variants with prefix (handled by prefix scan):
      // life_sustaining_treatment_direction_type → direction_type
      // life_sustaining_treatment_type → type (but we need treatment_type)
    ]);
    // Fix: flat key `life_sustaining_treatment_type` maps to nested `treatment_type`
    final lstGroup =
        nested['life_sustaining_treatment'] as Map<String, dynamic>? ?? {};
    if (lstGroup.containsKey('type') && !lstGroup.containsKey('treatment_type')) {
      lstGroup['treatment_type'] = lstGroup.remove('type');
    }
    if (lstGroup.containsKey('instruction') &&
        !lstGroup.containsKey('treatment_instruction')) {
      lstGroup['treatment_instruction'] = lstGroup.remove('instruction');
    }
    // Flat `other_life_sustaining_treatment` → nested `other_treatment`
    if (flat.containsKey('other_life_sustaining_treatment')) {
      lstGroup['other_treatment'] = flat['other_life_sustaining_treatment'];
      nested.remove('other_life_sustaining_treatment');
    }
    if (flat.containsKey('other_life_sustaining_instruction')) {
      lstGroup['other_instruction'] = flat['other_life_sustaining_instruction'];
      nested.remove('other_life_sustaining_instruction');
    }
    if (lstGroup.isNotEmpty) {
      nested['life_sustaining_treatment'] = lstGroup;
    }

    // quality_of_life_tolerance (NSW)
    moveToGroup('quality_of_life_tolerance', [
      'no_longer_recognise_family',
      'no_bladder_control',
      'cant_feed_wash_dress',
      'rely_people_for_movement',
      'need_life_tube_for_food',
      'cant_converse_with_people',
    ]);

    // cpr_and_resuscitation
    moveToGroup('cpr_and_resuscitation', [
      'cpr_instruction',
      'medical_not_expected_to_recover',
      'cpr_resuscitation',
      'cpr_resuscitation_instruction',
      'cpr_consent',
      'cpr_consent_instruction',
    ]);

    // organ_and_body_donation
    moveToGroup('organ_and_body_donation', [
      'donate_organ',
      'organ_donation_instruction',
      'consent_organ_donation',
      'donate_body',
      'consent_body_donation',
      'authorisation',
    ]);

    // medical_research_consent (WA)
    moveToGroup('medical_research_consent', [
      'placebos',
      'use_equipment',
      'less_practitioners_support',
      'comparative_assessment',
      'blood_samples',
      'tissue_sample',
      'non_intrusive_treatment',
      'being_observed',
      'undertaking_survey',
      'collecing_disclosing_information',
      'evaluating_samples',
      // 'other' is too generic to move — handled by prefix scan
    ]);

    // living_preferences
    moveToGroup('living_preferences', [
      'health_treatment_priority',
      'living_well_importance',
      'is_nearing_death',
      'nearing_death_goals_detail',
      'wish_to_live',
      'important_people_nearing_death',
      'nearing_death_unacceptable',
      'where_to_die',
      'where_to_die_instruction',
      'comfort_care_preferences',
      'comfort_pain_details',
      'comfort_surroundings_details',
    ]);

    // treatment_decisions
    moveToGroup('treatment_decisions', [
      'artificial_hydration',
      'artificial_hydration_instruction',
      'other_treatment_decision',
      'other_treatment_decision_instruction',
      'health_circumstance_decision_instruction',
      'other_medical_support',
      'other_medical_support_instruction',
      'consent_palliative_comfort_care',
      'specific_treatment_no_consent',
      'specific_treatment_no_consent_instruction',
      'healthcare_preferred',
    ]);
    // Also: flat `life_sustaining_treatment` (without prefix) may be a
    // treatment_decisions field in WA context — only if it's a string, not
    // the nested map we already built.
    if (flat.containsKey('life_sustaining_treatment') &&
        flat['life_sustaining_treatment'] is String?) {
      final tdGroup =
          nested['treatment_decisions'] as Map<String, dynamic>? ?? {};
      tdGroup['life_sustaining_treatment'] = flat['life_sustaining_treatment'];
      nested['treatment_decisions'] = tdGroup;
    }

    // attorney_and_advice
    moveToGroup('attorney_and_advice', [
      'attorney_decision_power',
      'attorney_decision_power_detail',
      'has_used_interpreter',
      'has_epg',
      'epg_date',
      'epg_place_detail',
      'seek_medical_advice',
      'seek_legal_advice',
    ]);

    // declarations_and_wishes
    moveToGroup('declarations_and_wishes', [
      'declaration',
      'what_matter_most',
      'what_worries_most',
      'unacceptable_medical_treatment_outcome',
      'other_things_known',
      'other_people_involved_in_care_discussion',
      'appointment_conditon',
      'other_medical_decision',
      'cultural_request',
      'religious_beliefs',
      'after_death_importance',
      'medical_not_expected_to_recover_instruction',
      'nearing_death_instruction',
    ]);

    return nested;
  }

  /// Create AhdFlowData from API GET response JSON.
  ///
  /// The API GET response returns flat column names while the POST accepts
  /// nested objects. This factory handles both formats by detecting flat
  /// responses and restructuring them into the nested format.
  factory AhdFlowData.fromApiJson(Map<String, dynamic> rawJson) {
    // Detect flat format: if known nested keys are missing but flat keys exist
    final json = rawJson.containsKey('health_conditions')
        ? rawJson
        : _restructureFlatResponse(rawJson);

    // Parse nested DTOs
    final hc = json['health_conditions'] as Map<String, dynamic>? ?? {};
    final lst = json['life_sustaining_treatment'] as Map<String, dynamic>? ?? {};
    final qol = json['quality_of_life_tolerance'] as Map<String, dynamic>? ?? {};
    final cpr = json['cpr_and_resuscitation'] as Map<String, dynamic>? ?? {};
    final organ = json['organ_and_body_donation'] as Map<String, dynamic>? ?? {};
    final lp = json['living_preferences'] as Map<String, dynamic>? ?? {};
    final td = json['treatment_decisions'] as Map<String, dynamic>? ?? {};
    final aa = json['attorney_and_advice'] as Map<String, dynamic>? ?? {};
    final dw = json['declarations_and_wishes'] as Map<String, dynamic>? ?? {};

    // Parse persons
    final personsRaw = json['ahd_persons'] as List<dynamic>? ?? [];
    final persons = personsRaw.cast<Map<String, dynamic>>();

    // Group persons by type
    final doctors = persons.where((p) => p['person_type'] == 'DOCTOR').toList();
    final attorneys = persons
        .where((p) => p['person_type'] == 'ATTORNEY_HEALTH_MATTERS')
        .toList();
    final witnessMedical = persons
        .where((p) => p['person_type'] == 'WITNESS_MEDICAL_PRACTITIONER')
        .toList();
    final witnessPersons =
        persons.where((p) => p['person_type'] == 'WITNESS_PERSON').toList();
    final interpreters =
        persons.where((p) => p['person_type'] == 'INTERPRETER').toList();
    final medicalGuardians =
        persons.where((p) => p['person_type'] == 'MEDICAL_GUARDIAN').toList();
    final tasPrimaryPersons =
        persons.where((p) => p['person_type'] == 'PRIMARY_PERSON').toList();
    final enduringGuardians =
        persons.where((p) => p['person_type'] == 'ENDURING_GUARDIAN').toList();
    final secondaryGuardians = persons
        .where((p) => p['person_type'] == 'SECONDARY_ENDURING_GUARDIAN')
        .toList();
    final tertiaryGuardians = persons
        .where((p) => p['person_type'] == 'TERTIARY_ENDURING_GUARDIAN')
        .toList();
    final medicalAdvisors =
        persons.where((p) => p['person_type'] == 'MEDICAL_ADVISOR').toList();
    final legalAdvisors =
        persons.where((p) => p['person_type'] == 'LEGAL_ADVISOR').toList();
    final substituteDms = persons
        .where((p) =>
            p['person_type'] == 'SUBSTITUTE_DECISION_MAKER' ||
            p['person_type'] == 'SUBSTITUTE_DECISION_MAKER_SECONDARY')
        .toList();
    final decisionMakers =
        persons.where((p) => p['person_type'] == 'DECISION_MAKER').toList();
    final helpers =
        persons.where((p) => p['person_type'] == 'HELPER').toList();
    final authorizedWitnesses =
        persons.where((p) => p['person_type'] == 'WITNESS_AUTHORIZED').toList();

    // Doctor fields
    final doctor = doctors.isNotEmpty ? doctors.first : null;
    final doctorOther = doctor?['other'] as Map<String, dynamic>? ?? {};

    // VIC witness 1 (medical practitioner)
    final vicW1 = witnessMedical.isNotEmpty ? witnessMedical.first : null;
    final vicW1Other = vicW1?['other'] as Map<String, dynamic>? ?? {};
    // VIC witness 2 (person)
    final vicW2 = witnessPersons.isNotEmpty ? witnessPersons.first : null;
    final vicW2Other = vicW2?['other'] as Map<String, dynamic>? ?? {};
    // VIC interpreter
    final vicInterp = interpreters.isNotEmpty ? interpreters.first : null;
    final vicInterpOther = vicInterp?['other'] as Map<String, dynamic>? ?? {};

    // WA guardians
    final waGuard = enduringGuardians.isNotEmpty ? enduringGuardians.first : null;
    final waSubGuard =
        secondaryGuardians.isNotEmpty ? secondaryGuardians.first : null;
    final waOtherGuard =
        tertiaryGuardians.isNotEmpty ? tertiaryGuardians.first : null;

    // WA advisors
    final waMedAdv = medicalAdvisors.isNotEmpty ? medicalAdvisors.first : null;
    final waMedAdvOther = waMedAdv?['other'] as Map<String, dynamic>? ?? {};
    final waLegalAdv = legalAdvisors.isNotEmpty ? legalAdvisors.first : null;
    final waLegalAdvOther = waLegalAdv?['other'] as Map<String, dynamic>? ?? {};

    // SA authorised witness
    final saAuthW =
        authorizedWitnesses.isNotEmpty ? authorizedWitnesses.first : null;
    final saAuthWOther = saAuthW?['other'] as Map<String, dynamic>? ?? {};

    // Helpers (ACT directed person, TAS delegated person)
    final acdHelper = helpers.isNotEmpty ? helpers.first : null;
    final acdHelperOther = acdHelper?['other'] as Map<String, dynamic>? ?? {};

    // WITNESS_PRIMARY (NT sign, ACT cert signature, SA person giving directive)
    final witnessPrimary = persons
        .where((p) => p['person_type'] == 'WITNESS_PRIMARY')
        .toList();
    final wpFirst = witnessPrimary.isNotEmpty ? witnessPrimary.first : null;
    final wpFirstOther = wpFirst?['other'] as Map<String, dynamic>? ?? {};

    // SA witness (person giving directive) — sent as WITNESS_PRIMARY by DTO
    // Falls back to WITNESS_PERSON for legacy data
    final saWitness = witnessPrimary.isNotEmpty
        ? witnessPrimary.first
        : (witnessPersons.length > 1 ? witnessPersons[1] : null);
    final saWitnessOther = saWitness?['other'] as Map<String, dynamic>? ?? {};

    // SA interpreter — same person type as VIC; use first available
    final saInterp = interpreters.isNotEmpty ? interpreters.first : null;
    final saInterpOther = saInterp?['other'] as Map<String, dynamic>? ?? {};

    // TAS interpreter — same INTERPRETER person type; alias for clarity
    final tasInterp = interpreters.isNotEmpty ? interpreters.first : null;
    final tasInterpOther = tasInterp?['other'] as Map<String, dynamic>? ?? {};

    // Medical research consent (WA)
    final mr = json['medical_research_consent'] as Map<String, dynamic>? ?? {};

    // Living well importance → WA choices
    final livingWell = lp['living_well_importance'] as List<dynamic>? ?? [];
    final waLivingWellList = livingWell
        .map((e) => _unmapWaLivingWellChoice(e.toString()))
        .toList();

    // Nearing death → WA locations (multi-select)
    final nearingDeath = lp['is_nearing_death'] as List<dynamic>? ?? [];
    final waNearingDeathList = nearingDeath
        .map((e) => _unmapWaNearingDeathLocation(e.toString()))
        .toList();

    return AhdFlowData(
      // Generic health conditions
      healthConditions: hc['major_health_conditions'] as String?,
      thingsImportant:
          hc['things_important_for_me'] as String? ?? dw['what_matter_most'] as String?,
      culturalValues:
          hc['beliefs_considered_during_health_care'] as String?,
      nearingDeathComfort: hc['nearing_death_preference'] as String?,
      nearingDeathImportant:
          lp['important_people_nearing_death'] as String?,
      peopleNotInvolved:
          hc['people_not_to_involve_healthcare_discussion'] as String?,
      thingsWorry: dw['what_worries_most'] as String?,

      // Life-sustaining treatment — store RAW API values (QLD format).
      // QLD screens use these directly (CONSENT, REFUSE, CIRCUMSTANCE,
      // SPECIFIC_DIRECTION).  VIC screens map to their own enum in initState.
      lifeSustainingDirective: lst['direction_type'] as String?,
      lifeSustainingDirectiveDetails: lst['direction_instruction'] as String?,
      lifeSustainingTreatment: lst['treatment_type'] as String?,
      lifeSustainingTreatmentDetails: lst['treatment_instruction'] as String?,
      assistedVentilation: lst['assisted_ventilation'] as String?,
      assistedVentilationDetails:
          lst['assisted_ventilation_instruction'] as String?,
      artificialNutrition: lst['artificial_nutrition'] as String?,
      artificialNutritionDetails:
          lst['artificial_nutrition_instruction'] as String?,
      antibiotics: lst['antibiotics'] as String?,
      antibioticsDetails: lst['antibiotics_instruction'] as String?,
      otherTreatment: lst['other_treatment'] as String?,
      otherTreatmentDetails: lst['other_instruction'] as String?,
      lstStateTreatment: td['life_sustaining_treatment'] as String?,
      otherHealthCareDirections: (json['other_health_directions'] as List<dynamic>?)
              ?.map((e) => HealthCareDirection(
                    healthCondition:
                        (e as Map<String, dynamic>)['health_condition'] as String? ?? '',
                    directions: e['health_direction'] as String? ?? '',
                  ))
              .toList() ??
          const [],
      bloodTransfusionChoice:
          _unmapBloodTransfusion(lst['blood_transfusion'] as String?),
      bloodTransfusionOther:
          lst['blood_transfusion_instruction'] as String?,
      artificialHydration: td['artificial_hydration'] as String?,
      artificialHydrationDetails:
          td['artificial_hydration_instruction'] as String?,

      // Doctor
      doctorName: doctor?['full_name'] as String?,
      facilityName: doctorOther['facility_name'] as String?,
      doctorDob: doctor?['dob'] as String?,
      doctorAddress: doctor?['address'] as String?,
      doctorSuburb: doctor?['suburb'] as String?,
      doctorPostcode: doctor?['postcode'] as String?,
      doctorState: doctor?['state'] as String?,
      doctorPhone: doctor?['phone'] as String?,
      doctorSign: doctorOther['signature'] as String?,

      // Attorneys
      healthAttorneys: attorneys.map(_parseAttorney).toList(),
      attorneyDecisionMethod:
          aa['attorney_decision_power'] as String?,
      attorneyDecisionOther:
          aa['attorney_decision_power_detail'] as String?,

      declarationDetails: dw['declaration'] as String?,
      attorneyTerms: dw['appointment_conditon'] as String?,

      // ── NSW ──
      nswCannotRecogniseFamily:
          qol['no_longer_recognise_family'] as String?,
      nswNoBladderControl: qol['no_bladder_control'] as String?,
      nswCannotFeedWashDress: qol['cant_feed_wash_dress'] as String?,
      nswCannotMoveInOutBed: qol['rely_people_for_movement'] as String?,
      nswCannotMoveReposition: cpr['cpr_instruction'] as String?,
      nswCannotEatDrink: qol['need_life_tube_for_food'] as String?,
      nswEndOfLifeCare: qol['cant_converse_with_people'] as String?,
      nswCprChoice:
          _unmapCprChoice(cpr['medical_not_expected_to_recover'] as String?),
      nswMedicalTreatmentType: () {
        final oms = td['other_medical_support'] as String?;
        return oms != null ? _unmapMedicalTreatmentType(oms) : null;
      }(),
      nswMedicalTreatmentOther:
          td['other_medical_support_instruction'] as String?,
      nswDonateOrgans: organ['donate_organ'] as bool?,
      nswConsentOrganDonation: organ['consent_organ_donation'] as bool?,
      nswDonateBody: organ['donate_body'] as bool?,
      nswDiscussedDonation: organ['consent_body_donation'] as bool?,
      nswPersonsResponsible: medicalGuardians.map(_parseAttorney).toList(),
      nswHasEnduringGuardian:
          (json['is_enduring_guardian_appointed'] as bool?) ??
          (enduringGuardians.isNotEmpty ? true : null),
      nswEnduringGuardians: enduringGuardians.map(_parseAttorney).toList(),
      nswAuthorisation: organ['authorisation'] as String?,

      // ── VIC ──
      vicUnacceptableOutcomes:
          dw['unacceptable_medical_treatment_outcome'] as String?,
      vicOtherThingsKnown: dw['other_things_known'] as String?,
      vicPeopleInvolved:
          dw['other_people_involved_in_care_discussion'] as String?,
      vicOrganDonation: organ['authorisation'] as String? ??
          json['organ_donation'] as String?,
      vicConsentTreatment:
          td['other_treatment_decision_instruction'] as String? ??
              json['medical_treatment_consent'] as String?,
      vicRefuseTreatment: dw['other_medical_decision'] as String?,
      vicPersonSign: json['medical_treatment_consent'] as String?,
      vicRefuseMedicalTreatment:
          json['medical_treatment_refuse'] as String?,
      vicWitness1FullName: vicW1?['full_name'] as String?,
      vicWitness1Qualification: vicW1?['qualification'] as String? ??
          vicW1Other['qualification'] as String?,
      vicWitness1Signature: vicW1Other['signature'] as String?,
      vicWitness1Date: vicW1Other['date'] as String?,
      vicWitness2FullName: vicW2?['full_name'] as String?,
      vicWitness2Signature: vicW2Other['signature'] as String?,
      vicWitness2Date: vicW2Other['date'] as String?,
      vicInterpreterName: vicInterp?['full_name'] as String?,
      vicInterpreterNaati: vicInterpOther['naati_number'] as String?,
      vicInterpreterLanguage: vicInterpOther['language'] as String?,
      vicInterpreterSignature: vicInterpOther['signature'] as String?,
      vicInterpreterDate: vicInterpOther['date'] as String?,

      // ── WA ──
      waRevokeAcd: json['is_acd_revoked'] as bool?,
      waHealthConditions: hc['major_health_conditions'] as String?,
        waTreatmentPreferences:
          hc['things_important_for_me'] as String? ??
          lp['health_treatment_priority'] as String?,
      waLivingWellChoices: waLivingWellList,
      waComfortChoices: ((hc['comfort_nearing_death'] as List<dynamic>?) ??
              (lp['comfort_care_preferences'] as List<dynamic>?) ??
              [])
          .map((e) => _unmapWaComfortChoice(e.toString()))
          .toList(),
        waComfortPainDetails:
          lp['comfort_pain_details'] as String? ??
          rawJson['comfort_pain_details'] as String? ??
          hc['nearing_death_preference'] as String?,
        waComfortSurroundingsDetails:
          lp['comfort_surroundings_details'] as String? ??
          rawJson['comfort_surroundings_details'] as String? ??
          hc['nearing_death_preference'] as String?,
      waWorries: dw['what_worries_most'] as String?,
      waNearingDeathLocations: waNearingDeathList,
        waNearingDeathLocationDetails:
          dw['nearing_death_instruction'] as String? ??
          lp['nearing_death_goals_detail'] as String?,
      waLifeSustainingTreatment:
          _unmapWaLifeSustainingTreatment(lst['treatment_type'] as String?) ??
          _unmapWaLifeSustainingTreatment(rawJson['life_sustaining_treatment_type'] as String?),
      waLifeSustainingDetails: lst['treatment_instruction'] as String? ??
          rawJson['life_sustaining_treatment_instruction'] as String?,
      waCpr: _unmapTreatmentChoice(cpr['cpr_resuscitation'] as String?),
      waCprDetails: cpr['cpr_resuscitation_instruction'] as String?,
      waAssistedVentilation:
          _unmapTreatmentChoice(lst['assisted_ventilation'] as String?),
      waAssistedVentilationDetails:
          lst['assisted_ventilation_instruction'] as String?,
      waArtificialNutrition:
          _unmapTreatmentChoice(lst['artificial_nutrition'] as String?),
      waArtificialNutritionDetails:
          lst['artificial_nutrition_instruction'] as String?,
      waArtificialHydration:
          _unmapTreatmentChoice(td['artificial_hydration'] as String?),
      waArtificialHydrationDetails:
          td['artificial_hydration_instruction'] as String?,
      waAntibiotics:
          _unmapTreatmentChoice(lst['antibiotics'] as String?),
      waAntibioticsDetails: lst['antibiotics_instruction'] as String?,
      waBloodProducts:
          _unmapTreatmentChoice(lst['blood_transfusion'] as String? ??
              lst['transfusion'] as String?) ??
          _unmapTreatmentChoice(rawJson['blood_transfusion'] as String?),
      waBloodProductsDetails:
          lst['blood_transfusion_instruction'] as String? ??
              lst['transfusion_instruction'] as String? ??
              rawJson['blood_transfusion_instruction'] as String?,
      waInterpreterChoice:
          _unmapWaInterpreterChoice(aa['has_used_interpreter'] as String?),
      waEpgChoice: _unmapWaEpgChoice(aa['has_epg'] as String?),
      waEpgDate: aa['epg_date'] as String?,
      waEpgLocation: aa['epg_place_detail'] as String?,
      waGuardianFirstName: waGuard?['full_name'] as String?,
      waGuardianPhone: waGuard?['phone'] as String?,
      waSubstituteGuardianFirstName: waSubGuard?['full_name'] as String?,
      waSubstituteGuardianPhone: waSubGuard?['phone'] as String?,
      waOtherSubstituteFirstName: waOtherGuard?['full_name'] as String?,
      waOtherSubstitutePhone: waOtherGuard?['phone'] as String?,
      waMedicalAdviceChoice:
          _unmapWaMedicalAdvice(aa['seek_medical_advice'] as String?),
      waMedicalAdvisorFirstName: waMedAdv?['full_name'] as String?,
      waMedicalAdvisorPhone: waMedAdv?['phone'] as String?,
      waMedicalAdvisorPractice: waMedAdvOther['practice'] as String?,
      waLegalAdviceChoice:
          _unmapWaLegalAdvice(aa['seek_legal_advice'] as String?),
      waLegalAdvisorFirstName: waLegalAdv?['full_name'] as String?,
      waLegalAdvisorPhone: waLegalAdv?['phone'] as String?,
      waLegalAdvisorPractice: waLegalAdvOther['practice'] as String?,
      waDialysis:
          _unmapTreatmentChoice(td['other_treatment_decision'] as String?),
      waDialysisDetails:
          td['other_treatment_decision_instruction'] as String?,
      waOtherTreatment:
          _unmapTreatmentChoice(lst['other_treatment'] as String?),
      waOtherTreatmentDetails: lst['other_instruction'] as String?,
      waMrPlacebos: mr['placebos'] as String?,
      waMrUseEquipment: mr['use_equipment'] as String?,
      waMrLessPractitioners: mr['less_practitioners_support'] as String?,
      waMrComparativeAssessment: mr['comparative_assessment'] as String?,
      waMrBloodSamples: mr['blood_samples'] as String?,
      waMrTissueSample: mr['tissue_sample'] as String?,
      waMrNonIntrusiveTreatment: mr['non_intrusive_treatment'] as String?,
      waMrBeingObserved: mr['being_observed'] as String?,
      waMrUndertakingSurvey: mr['undertaking_survey'] as String?,
      waMrCollectingDisclosing: mr['collecing_disclosing_information'] as String?,
      waMrEvaluatingSamples: mr['evaluating_samples'] as String?,
      waMrOther: mr['other'] as String?,
      waAuthorisation: organ['authorisation'] as String?,

      // ── SA ──
      saConditionsOfAppointments: dw['appointment_conditon'] as String?,
      saRefusalHealthCare: dw['other_medical_decision'] as String?,
        saExpiryDate:
          json['acd_expiry_date'] as String? ??
          json['expiry_date'] as String?,
      saLivingWell: hc['things_important_for_me'] as String?,
      saOtherThingsKnown: dw['other_things_known'] as String?,
      saOtherPeopleInvolved:
          hc['people_not_to_involve_healthcare_discussion'] as String?,
      saNearingDeath: hc['nearing_death_preference'] as String?,
      saSubstituteDecisionMakers: substituteDms.map(_parseAttorney).toList(),
      saSubDm1FullName: substituteDms.isNotEmpty
          ? substituteDms.first['full_name'] as String?
          : null,
      saSubDm1Address: substituteDms.isNotEmpty
          ? substituteDms.first['address'] as String?
          : null,
      saSubDm1Date: substituteDms.isNotEmpty
          ? (substituteDms.first['other'] as Map<String, dynamic>? ?? {})['date'] as String?
          : null,
      saSubDm2FullName: substituteDms.length > 1
          ? substituteDms[1]['full_name'] as String?
          : null,
      saSubDm2Address: substituteDms.length > 1
          ? substituteDms[1]['address'] as String?
          : null,
      saSubDm2Date: substituteDms.length > 1
          ? (substituteDms[1]['other'] as Map<String, dynamic>? ?? {})['date'] as String?
          : null,
      saWitnessFullName: saWitness?['full_name'] as String?,
      saWitnessPhone: saWitness?['phone'] as String?,
      saWitnessSignature: saWitnessOther['signature'] as String?,
      saWitnessDate: saWitnessOther['date'] as String?,
      saAuthorisedWitnessFullName: saAuthW?['full_name'] as String?,
      saWitnessCategory: saAuthWOther['witness_category'] != null
          ? _unmapSaWitnessCategory(saAuthWOther['witness_category'] as String)
          : null,
      saAuthorisedWitnessPhone: saAuthW?['phone'] as String?,
      saAuthorisedWitnessSignature: saAuthWOther['signature'] as String?,
      saAuthorisedWitnessDate: saAuthWOther['date'] as String?,
      saExtraExecutionStatement: saAuthWOther['statement'] as String?,
      saInterpreterName: saInterp?['full_name'] as String?,
      saInterpreterNaati: saInterpOther['naati_number'] as String?,
      saInterpreterSignature: saInterpOther['signature'] as String?,
      saInterpreterDate: saInterpOther['date'] as String?,
      saWhereToLive: lp['wish_to_live'] as String?,
      saStatementResponse: dw['declaration'] as String?,
      saOrganDonationChoice: () {
        final flatOrganDonation = rawJson['organ_donation'] as String?;
        if (flatOrganDonation == OrganDonationChoice.willing ||
            flatOrganDonation == OrganDonationChoice.notWilling) {
          return flatOrganDonation;
        }
        if (organ['donate_organ'] == true) {
          return OrganDonationChoice.willing;
        }
        if (organ['donate_organ'] == false) {
          return OrganDonationChoice.notWilling;
        }
        return null;
      }(),
      saOrganDonationInstruction: organ['organ_donation_instruction'] as String?,
      saHealthcarePreferred: td['healthcare_preferred'] as String?,

      // ── NT ──
      ntLifeMeaning: dw['what_matter_most'] as String? ??
          lp['wish_to_live'] as String? ??
          rawJson['what_matter_most'] as String?,
      ntNearingDeathGoals: lp['nearing_death_goals_detail'] as String?,
      ntUnacceptableOutcomes:
          lp['nearing_death_unacceptable'] as String?,
      ntPalliativeCare:
          td['consent_palliative_comfort_care'] as String?,
      ntWhereToDieChoice:
          _unmapNtWhereToDie(lp['where_to_die'] as String?),
      ntWhereToDie: lp['where_to_die_instruction'] as String?,
      ntOtherMedicalInfo: dw['other_medical_decision'] as String? ??
          dw['other_things_known'] as String? ??
          rawJson['other_medical_decision'] as String?,
      ntCulturalRequests: dw['cultural_request'] as String?,
      ntAfterDeath1: dw['after_death_importance'] as String?,
      ntAfterDeath2: dw['nearing_death_instruction'] as String?,
      ntCprChoice: _unmapNtCprChoice(cpr['cpr_consent'] as String?),
      ntCprConditionDetails: cpr['cpr_consent_instruction'] as String?,
      ntReligiousBeliefs: dw['religious_beliefs'] as String?,
        ntDecisionMakers: tasPrimaryPersons
          .map(_parseAttorney)
          .toList(),
        ntAppointedDecisionMakers: decisionMakers
          .map(_parseAttorney)
          .toList(),
      ntDecisionMethod: aa['attorney_decision_power'] as String?,
      ntDecisionMethodOther:
          aa['attorney_decision_power_detail'] as String?,
      ntRefusedTreatments: () {
        final specific =
            td['specific_treatment_no_consent'] as String?;
        return specific != null
            ? [_unmapNtRefusedTreatment(specific)]
            : <String>[];
      }(),
      ntRefusedTreatmentOther:
          td['specific_treatment_no_consent_instruction'] as String?,
      ntSign: wpFirstOther['signature'] as String?,

      // ── TAS ──
      tasHealthConditions: hc['major_health_conditions'] as String?,
      tasViewsWishes: lp['wish_to_live'] as String? ??
          hc['things_important_for_me'] as String?,
      tasOrganDonorRegister:
          json['is_registered_australian_organ_donor'] as bool?,
      tasBodyBequestProgram:
          json['is_registered_tasmania_bequest_program'] as bool?,
      tasExpiryDate: json['acd_expiry_date'] as String?,
      tasRevokeAcd: json['is_acd_revoked'] as bool?,
      tasMedicalTreatmentRefuse:
          td['other_treatment_decision_instruction'] as String?,
      tasMedicalCircumstances:
          td['health_circumstance_decision_instruction'] as String?,
      tasSignFullName: tasPrimaryPersons.isNotEmpty
          ? tasPrimaryPersons.first['full_name'] as String?
          : null,
      tasSignSignature: tasPrimaryPersons.isNotEmpty
          ? (tasPrimaryPersons.first['other'] as Map<String, dynamic>? ?? {})['signature'] as String?
          : null,
      tasSignDate: tasPrimaryPersons.isNotEmpty
          ? (tasPrimaryPersons.first['other'] as Map<String, dynamic>? ?? {})['date'] as String?
          : null,
      tasDelegatedPersonName: acdHelper?['full_name'] as String?,
      tasDelegatedAcdPersonName:
          acdHelperOther['ahd_primary_person_name'] as String?,
      tasDelegatedRelationship:
          acdHelperOther['relationship'] as String?,
      tasDelegatedSignature:
          acdHelperOther['signature'] as String?,
      tasDelegatedDate: acdHelperOther['date'] as String?,
      tasWitnesses: [
        ...witnessMedical.map((p) => _parseAttorney(p)),
        ...witnessPersons.map(_parseAttorney),
      ],
      tasInterpreterName: tasInterp?['full_name'] as String?,
      tasInterpreterLanguage: tasInterpOther['language'] as String?,
      tasInterpreterSignature:
          tasInterpOther['signature'] as String?,
      tasInterpreterDob: tasInterp?['dob'] as String?,
      tasInterpreterNaati: tasInterpOther['naati_number'] as String?,

      // ── ACT ──
      actMedicalTreatmentRefuse:
          json['medical_treatment_refuse'] as String?,
      actRevokePreviousDirections: json['is_acd_revoked'] as bool?,
      actDirectedPersonName: acdHelper?['full_name'] as String?,
      actDirectedPersonAddress: acdHelper?['address'] as String?,
      actWitness1FullName: witnessPersons.isNotEmpty
          ? witnessPersons.first['full_name'] as String?
          : null,
      actWitness1Address: witnessPersons.isNotEmpty
          ? witnessPersons.first['address'] as String?
          : null,
    );
  }

  /// Parse a person JSON map into AhdAttorneyData.
  static AhdAttorneyData _parseAttorney(Map<String, dynamic> p) {
    final fullName = p['full_name'] as String? ?? '';
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.last : '';
    final middleName =
        parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : null;
    final other = p['other'] as Map<String, dynamic>? ?? {};

    return AhdAttorneyData(
      id: '',
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: p['email'] as String?,
      phone: p['phone'] as String?,
      dob: p['dob'] as String?,
      address: p['address'] as String?,
      addressSuburb: p['suburb'] as String?,
      addressPostcode: p['postcode'] as String?,
      addressState: p['state'] as String?,
      addressCountry: p['country'] as String?,
      matters: other['matters'] != null
          ? _unmapNtMatters(other['matters'] as String)
          : null,
      signature: other['signature'] as String?,
      isHealthPractitioner:
          p['person_type'] == 'WITNESS_MEDICAL_PRACTITIONER',
      qualification: p['qualification'] as String? ??
          other['qualification'] as String?,
      houseNumber: other['house_number'] as String?,
    );
  }
}

/// Person data for AHD attorneys
class AhdAttorneyData {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? relation;

  // Optional extended fields (used by SA substitute decision-maker)
  final String? dob;
  final String? address;
  final String? addressSuburb;
  final String? addressPostcode;
  final String? addressCountry;
  final String? addressState;

  // Optional matters field (used by NT decision maker)
  final String? matters;

  // Optional TAS-specific fields
  final String? signature;
  final bool? isHealthPractitioner;
  final String? qualification;
  final String? houseNumber;

  const AhdAttorneyData({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.phone,
    this.relation,
    this.dob,
    this.address,
    this.addressSuburb,
    this.addressPostcode,
    this.addressCountry,
    this.addressState,
    this.matters,
    this.signature,
    this.isHealthPractitioner,
    this.qualification,
    this.houseNumber,
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
}
