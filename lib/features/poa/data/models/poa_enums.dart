// POA enums — exact API string values matching web's enum/index.ts
//
// Two layers of enums exist per state:
//   1. UI-level values (used in form state, often lowercase)
//   2. Backend-level values (sent to API, often UPPERCASE)
// The mapper converts UI → backend. Both are defined here.

// ---------------------------------------------------------------------------
// POA Matters (backend values)
// ---------------------------------------------------------------------------
class PoaMatters {
  static const String personal = 'PERSONAL';
  static const String health = 'HEALTH';
  static const String finance = 'FINANCE';
  static const String specific = 'SPECIFIC';

  static const List<String> all = [personal, health, finance, specific];

  static String displayName(String value) {
    switch (value) {
      case personal:
        return 'Personal (including health) matters';
      case health:
        return 'Health matters';
      case finance:
        return 'Financial matters';
      case specific:
        return 'Specific matters';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Matters type UI (form-level for NSW/QLD/VIC)
// ---------------------------------------------------------------------------
class MattersTypeUI {
  static const String personal = 'personal';
  static const String financial = 'financial';
  static const String both = 'both';
  static const String specific = 'specific';

  static const List<String> all = [personal, financial, both, specific];
}

// ---------------------------------------------------------------------------
// Financial commencement (backend values)
// ---------------------------------------------------------------------------
class FinancialCommencement {
  static const String dontHaveCapacity = 'DONT_HAVE_CAPACITY';
  static const String immediatelyOthers = 'IMMEDIATELY_OTHERS';

  static const List<String> all = [dontHaveCapacity, immediatelyOthers];

  static String displayName(String value) {
    switch (value) {
      case dontHaveCapacity:
        return 'When I don\'t have capacity';
      case immediatelyOthers:
        return 'Immediately';
      default:
        return value;
    }
  }
}

// ---------------------------------------------------------------------------
// Commencement (backend values)
// ---------------------------------------------------------------------------
class Commencement {
  static const String uponAttorneyReceivingCondition = 'UPON_ATTORNEY_RECEIVING_CONDITION';
  static const String immediately = 'IMMEDIATELY';

  static const List<String> all = [uponAttorneyReceivingCondition, immediately];
}

// ---------------------------------------------------------------------------
// Commencement type UI (form-level)
// ---------------------------------------------------------------------------
class CommencementTypeUI {
  static const String noCapacity = 'no_capacity';
  static const String immediately = 'immediately';
}

// ---------------------------------------------------------------------------
// Victoria commencement type UI
// ---------------------------------------------------------------------------
class VictoriaCommencementTypeUI {
  static const String conditions = 'conditions';
  static const String immediately = 'immediately';
}

// ---------------------------------------------------------------------------
// Attorney additional powers
// ---------------------------------------------------------------------------
class AttorneyAdditionalPowers {
  static const String reasonableGifts = 'REASONABLE_GIFTS';
  static const String benefitToAttorney = 'BENEFIT_TO_ATTORNEY';
  static const String benefitToSelectedPerson = 'BENEFIT_TO_SELECTED_PERSON';

  static const List<String> all = [reasonableGifts, benefitToAttorney, benefitToSelectedPerson];
}

// ---------------------------------------------------------------------------
// Attorney type (discriminator for /user/attorney-for-poa)
// ---------------------------------------------------------------------------
class PoaAttorneyType {
  static const String primary = 'PRIMARY';
  static const String secondary = 'SECONDARY';
  static const String tertiary = 'TERTIARY';
  static const String successive = 'SUCCESSIVE';
  static const String substitute = 'SUBSTITUTE';
  static const String appointedAttorney = 'APPOINTED_ATTORNEY';
  static const String medicalDecisionMaker = 'MEDICAL_DECISION_MAKER';
  static const String personalAssistance = 'PERSONAL_ASSISTANCE';
  static const String enduringGuardian = 'ENDURING_GUARDIAN';
  static const String substituteEnduringGuardian = 'SUBSTITUTE_ENDURING_GUARDIAN';
  static const String additionalAuthority = 'ADDITIONAL_AUTHORITY';
  static const String attorneyDonee = 'ATTORNEY_DONEE';
  static const String attorneyDonor = 'ATTORNEY_DONOR';
  static const String secondDonor = 'SECOND_DONOR';
  static const String financialDecisionMakerPrimary = 'FINANCIAL_DECISION_MAKER_PRIMARY';
}

// ---------------------------------------------------------------------------
// POA Notification enums
// ---------------------------------------------------------------------------
class PoaNotifyFor {
  static const String me = 'ME';
  static const String nominatedPerson = 'NOMINATED_PERSON';
}

class PoaNotificationType {
  static const String personal = 'PERSONAL';
  static const String health = 'HEALTH';
  static const String financial = 'FINANCIAL';
}

class PoaNotifyOf {
  static const String writtenIntentionNotice = 'WRITTEN_INTENTION_NOTICE';
  static const String other = 'OTHER';
}

// ===========================================================================
// ACT-specific enums
// ===========================================================================

// UI-level (form values, lowercase)
class ActAttorneyActionTypeUI {
  static const String together = 'together';
  static const String separately = 'separately';
}

// Backend-level (sent to API)
class ActAttorneyActRules {
  static const String jointly = 'JOINTLY';
  static const String jointlySeverally = 'JOINTLY_SEVERALLY';
}

class ActDelegationPowerTypeUI {
  static const String noDelegation = 'no_delegation';
  static const String delegationAllPowers = 'delegation_all_powers';
  static const String delegateSomePowers = 'delegate_some_powers';
}

// Backend
class ActAttorneyPowers {
  static const String noDelegation = 'NO_DELEGATION';
  static const String allPowers = 'ALL_POWERS';
  static const String somePowers = 'SOME_POWERS';
}

class ActMattersCoveredUI {
  static const String property = 'property';
  static const String personalCare = 'personal_care';
  static const String healthCare = 'health_care';
  static const String medicalResearch = 'medical_research';
}

// Backend
class ActAttorneyPowerMatters {
  static const String property = 'PROPERTY';
  static const String personalCare = 'PERSONAL_CARE';
  static const String healthCare = 'HEALTH_CARE';
  static const String medicalResearch = 'MEDICAL_RESEARCH';
}

class ActMedicalTreatmentRefusalUI {
  static const String notAllowed = 'not_allowed';
  static const String allowedGenerally = 'allowed_generally';
  static const String allowedSpecific = 'allowed_specific';
}

// Backend
class ActMedicalTreatmentWithdraw {
  static const String notAllowed = 'NOT_ALLOWED';
  static const String allowedGenerally = 'ALLOWED_GENERALLY';
  static const String allowedSpecific = 'ALLOWED_SPECIFIC';
}

class ActPropertyCommencementTypeUI {
  static const String immediately = 'immediately';
  static const String fromDateOrEvent = 'from_date_or_event';
  static const String onlyWhenImpairedCapacity = 'only_when_impaired_capacity';
}

// Backend
class ActAttorneyPowerCommencement {
  static const String immediately = 'IMMEDIATELY';
  static const String fromDateEvent = 'FROM_DATE_EVENT';
  static const String impairedCapacity = 'IMPAIRED_CAPACITY';
}

class ActPriorEpaStatusUI {
  static const String nonePrevious = 'none_previous';
  static const String revokeAllPrevious = 'revoke_all_previous';
  static const String someContinue = 'some_continue';
}

// Backend
class ActEnduringPoa {
  static const String none = 'NONE';
  static const String revokeAllPrevious = 'REVOKE_ALL_PREVIOUS';
  static const String someContinue = 'SOME_CONTINUE';
}

class ActCorporationTypeUI {
  static const String publicTrusteeGuardian = 'public_trustee_guardian';
  static const String trusteeCompany = 'trustee_company';
  static const String others = 'others';
}

// Backend
class ActCorporationType {
  static const String publicTrustee = 'PUBLIC_TRUSTEE';
  static const String trusteeCompany = 'TRUSTEE_COMPANY';
  static const String others = 'OTHERS';
}

// ===========================================================================
// SA-specific enums
// ===========================================================================

class SaCommencementTypeUI {
  static const String uponExecution = 'upon_execution';
  static const String onlyOnLegalIncapacity = 'only_on_legal_incapacity';
}

// Backend
class SaPoaStartRule {
  static const String immediately = 'IMMEDIATELY';
  static const String legalIncapacity = 'LEGAL_INCAPACITY';
}

class SaDoneeActionType {
  static const String jointly = 'JOINTLY';
  static const String jointlySeverally = 'JOINTLY_SEVERALLY';

  static const List<String> all = [jointly, jointlySeverally];
}

// ===========================================================================
// WA-specific enums
// ===========================================================================

// UI-level
class WaAttorneyAppointmentTypeUI {
  static const String sole = 'sole';
  static const String joint = 'joint';
  static const String jointAndSeveral = 'joint_and_several';

  static const List<String> all = [sole, joint, jointAndSeveral];
}

// Backend
class WaAttorneyAppointmentType {
  static const String solo = 'SOLO';
  static const String joint = 'JOINT';
  static const String jointSeveral = 'JOINT_SEVERAL';
}

class WaSubstituteAppointmentTypeUI {
  static const String soleSubstitute = 'sole_substitute';
  static const String jointSubstitute = 'joint_substitute';
  static const String jointAndSeveralSubstitutes = 'joint_and_several_substitutes';
}

class WaSubstitutionForUI {
  static const String attorney1Only = 'attorney_1_only';
  static const String attorney2Only = 'attorney_2_only';
  static const String attorney1And2 = 'attorney_1_and_2';
}

// Backend
class WaSubstituteActSubstitution {
  static const String attorney1 = 'ATTORNEY_1';
  static const String attorney2 = 'ATTORNEY_2';
  static const String both = 'BOTH';
}

class WaCommencementTypeUI {
  static const String immediately = 'immediately';
  static const String onlyWhenDeclaration = 'only_when_declaration';
}

// Backend
class WaEpaEffect {
  static const String immediately = 'IMMEDIATELY';
  static const String declarationInForce = 'DECLARATION_IN_FORCE';
}

// ===========================================================================
// Tasmania-specific enums
// ===========================================================================

class TasAttorneyActionType {
  static const String jointly = 'JOINTLY';
  static const String jointlySeverally = 'JOINTLY_SEVERALLY';

  static const List<String> all = [jointly, jointlySeverally];
}

// ===========================================================================
// NT-specific enums
// ===========================================================================

class NtDecisionMakerActionType {
  static const String jointly = 'JOINTLY';
  static const String severally = 'JOINTLY_SEVERALLY'; // NOTE: web maps SEVERALLY → JOINTLY_SEVERALLY

  static const List<String> all = [jointly, severally];

  static String displayName(String value) {
    switch (value) {
      case jointly:
        return 'Jointly';
      case severally:
        return 'Severally';
      default:
        return value;
    }
  }
}

// ===========================================================================
// Common YesNo helper
// ===========================================================================
class YesNo {
  static const String yes = 'yes';
  static const String no = 'no';
}
