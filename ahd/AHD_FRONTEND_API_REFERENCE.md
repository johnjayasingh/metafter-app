# AHD API Reference for Frontend Developers

**Version:** 1.0  
**Last Updated:** March 16, 2026

This document provides a complete reference for the AHD (Advance Health Directive) API, including all DTOs, field types, possible enum values, and examples.

---

## Table of Contents
- [Overview](#overview)
- [Main Request DTO](#main-request-dto)
- [JSON Field DTOs](#json-field-dtos)
- [Enum Values Reference](#enum-values-reference)
- [Complete Example Request](#complete-example-request)
- [Validation Rules](#validation-rules)

---

## Overview

The AHD API uses structured DTOs (Data Transfer Objects) for type safety and validation. All fields are optional unless marked as required.

### Base URL
```
POST /api/ahd
```

### Request Body Structure
```typescript
{
  // Legacy individual fields (backward compatibility)
  major_health_conditions?: string
  organ_donation?: string
  expiry_date?: string
  
  // High-level flags
  acd_expiry_date?: string
  is_acd_revoked?: boolean
  is_registered_australian_organ_donor?: boolean
  is_registered_tasmania_bequest_program?: boolean
  
  // Structured JSON DTOs (10 objects)
  health_conditions?: HealthConditionsDTO
  life_sustaining_treatment?: LifeSustainingTreatmentDTO
  quality_of_life_tolerance?: QualityOfLifeToleranceDTO
  cpr_and_resuscitation?: CPRAndResuscitationDTO
  organ_and_body_donation?: OrganAndBodyDonationDTO
  medical_research_consent?: MedicalResearchConsentDTO
  living_preferences?: LivingPreferencesDTO
  treatment_decisions?: TreatmentDecisionsDTO
  attorney_and_advice?: AttorneyAndAdviceDTO
  declarations_and_wishes?: DeclarationsAndWishesDTO
  
  // Persons array
  ahd_persons?: AHDPersonDTO[]
}
```

---

## Main Request DTO

### AHDCreate

```typescript
interface AHDCreate {
  id?: string  // If provided: update, otherwise: create
  
  // === BACKWARD COMPATIBILITY FIELDS ===
  major_health_conditions?: string
  things_important_for_me?: string
  beliefs_considered_during_health_care?: string
  nearing_death_preference?: string
  people_not_to_involve_healthcare_discussion?: string
  
  life_sustaining_treatment_direction_type?: "CONSENT" | "REFUSE" | "ATTORNEY_DECISION" | "SPECIFIC_DIRECTION"
  life_sustaining_treatment_direction_instruction?: string
  
  life_sustaining_treatment_type?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  life_sustaining_treatment_instruction?: string
  
  assisted_ventilation?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  assisted_ventilation_instruction?: string
  
  artificial_nutrition?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  artificial_nutrition_instruction?: string
  
  antibiotics?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  antibiotics_instruction?: string
  
  other_life_sustaining_treatment?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  other_life_sustaining_instruction?: string
  
  blood_transfusion?: "CONSENT" | "REFUSE" | "OTHER"
  blood_transfusion_instruction?: string
  
  attorney_decision_power?: "JOINTLY" | "SEVERALLY" | "MAJORITY" | "OTHER"
  attorney_decision_power_detail?: string
  
  declaration?: string
  what_matter_most?: string
  what_worries_most?: string
  unacceptable_medical_treatment_outcome?: string
  other_things_known?: string
  other_people_involved_in_care_discussion?: string
  
  organ_donation?: "CONSENT" | "REFUSE"
  medical_treatment_consent?: string
  medical_treatment_refuse?: string
  
  expiry_date?: string  // ISO date format: "YYYY-MM-DD"
  
  // === HIGH-LEVEL QUERYABLE FIELDS ===
  acd_expiry_date?: string  // ISO date format
  is_acd_revoked?: boolean
  is_registered_australian_organ_donor?: boolean
  is_registered_tasmania_bequest_program?: boolean
  
  // === STRUCTURED JSON DTOs (RECOMMENDED) ===
  health_conditions?: HealthConditionsDTO
  life_sustaining_treatment?: LifeSustainingTreatmentDTO
  quality_of_life_tolerance?: QualityOfLifeToleranceDTO
  cpr_and_resuscitation?: CPRAndResuscitationDTO
  organ_and_body_donation?: OrganAndBodyDonationDTO
  medical_research_consent?: MedicalResearchConsentDTO
  living_preferences?: LivingPreferencesDTO
  treatment_decisions?: TreatmentDecisionsDTO
  attorney_and_advice?: AttorneyAndAdviceDTO
  declarations_and_wishes?: DeclarationsAndWishesDTO
  
  // === PERSONS ===
  ahd_persons?: AHDPersonDTO[]
}
```

---

## JSON Field DTOs

### 1. HealthConditionsDTO

General health information and beliefs.

```typescript
interface HealthConditionsDTO {
  major_health_conditions?: string        // Existing major health conditions
  things_important_for_me?: string        // What matters most in healthcare
  beliefs_considered_during_health_care?: string  // Religious/cultural beliefs
  nearing_death_preference?: string       // Preferences when nearing death
  people_not_to_involve_healthcare_discussion?: string  // People to exclude
}
```

**Example:**
```json
{
  "major_health_conditions": "Diabetes Type 2, Hypertension",
  "things_important_for_me": "Family time and dignity",
  "beliefs_considered_during_health_care": "Catholic beliefs to be respected",
  "nearing_death_preference": "Prefer to be at home surrounded by family",
  "people_not_to_involve_healthcare_discussion": "Estranged brother John"
}
```

---

### 2. LifeSustainingTreatmentDTO

Treatment directive preferences.

```typescript
interface LifeSustainingTreatmentDTO {
  direction_type?: "CONSENT" | "REFUSE" | "ATTORNEY_DECISION" | "SPECIFIC_DIRECTION"
  direction_instruction?: string
  
  treatment_type?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  treatment_instruction?: string
  
  assisted_ventilation?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  assisted_ventilation_instruction?: string
  
  artificial_nutrition?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  artificial_nutrition_instruction?: string
  
  antibiotics?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  antibiotics_instruction?: string
  
  blood_transfusion?: "CONSENT" | "REFUSE" | "OTHER"
  blood_transfusion_instruction?: string
  
  other_treatment?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  other_instruction?: string
}
```

**Example:**
```json
{
  "direction_type": "CONSENT",
  "direction_instruction": "Accept life-sustaining treatment with quality of life consideration",
  "treatment_type": "CIRCUMSTANCE",
  "treatment_instruction": "Only if recovery is reasonably likely",
  "assisted_ventilation": "CIRCUMSTANCE",
  "assisted_ventilation_instruction": "Short-term only (max 2 weeks)",
  "artificial_nutrition": "REFUSE",
  "artificial_nutrition_instruction": "No long-term tube feeding",
  "antibiotics": "CONSENT",
  "antibiotics_instruction": "Accept for treatable infections",
  "blood_transfusion": "CONSENT",
  "blood_transfusion_instruction": "Accept when medically necessary"
}
```

---

### 3. QualityOfLifeToleranceDTO

Quality of life situations tolerance.

```typescript
interface QualityOfLifeToleranceDTO {
  no_longer_recognise_family?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  no_bladder_control?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  cant_feed_wash_dress?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  rely_people_for_movement?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  need_life_tube_for_food?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  cant_converse_with_people?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
}
```

**Possible Values:** `"BEARABLE"`, `"UNBEARABLE"`, `"UNSURE"`

**Example:**
```json
{
  "no_longer_recognise_family": "UNBEARABLE",
  "no_bladder_control": "BEARABLE",
  "cant_feed_wash_dress": "BEARABLE",
  "rely_people_for_movement": "BEARABLE",
  "need_life_tube_for_food": "UNBEARABLE",
  "cant_converse_with_people": "UNBEARABLE"
}
```

---

### 4. CPRAndResuscitationDTO

CPR and resuscitation preferences.

```typescript
interface CPRAndResuscitationDTO {
  cpr_instruction?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  medical_not_expected_to_recover?: "ACCEPT_CPR" | "REJECT_CPR"
  cpr_resuscitation?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE" | "CANT_DECIDE"
  cpr_resuscitation_instruction?: string
  cpr_consent?: "RESTART" | "CONDITION" | "ALLOW_TO_DIE"
}
```

**Possible Values:**
- `cpr_instruction`: `"BEARABLE"`, `"UNBEARABLE"`, `"UNSURE"`
- `medical_not_expected_to_recover`: `"ACCEPT_CPR"`, `"REJECT_CPR"`
- `cpr_resuscitation`: `"CONSENT"`, `"REFUSE"`, `"CIRCUMSTANCE"`, `"CANT_DECIDE"`
- `cpr_consent`: `"RESTART"`, `"CONDITION"`, `"ALLOW_TO_DIE"`

**Example:**
```json
{
  "cpr_instruction": "UNBEARABLE",
  "medical_not_expected_to_recover": "REJECT_CPR",
  "cpr_resuscitation": "REFUSE",
  "cpr_resuscitation_instruction": "Do not resuscitate if no reasonable chance of recovery",
  "cpr_consent": "ALLOW_TO_DIE"
}
```

---

### 5. OrganAndBodyDonationDTO

Organ and body donation preferences.

```typescript
interface OrganAndBodyDonationDTO {
  donate_organ?: boolean
  consent_organ_donation?: boolean
  donate_body?: boolean
  consent_body_donation?: boolean
  authorisation?: string
}
```

**Example:**
```json
{
  "donate_organ": true,
  "consent_organ_donation": true,
  "donate_body": false,
  "consent_body_donation": false,
  "authorisation": "Authorize donation of all viable organs including heart, lungs, kidneys"
}
```

---

### 6. MedicalResearchConsentDTO

Consent for medical research participation.

```typescript
interface MedicalResearchConsentDTO {
  placebos?: MedicalResearchConsentValue
  use_equipment?: MedicalResearchConsentValue
  less_practitioners_support?: MedicalResearchConsentValue
  comparative_assessment?: MedicalResearchConsentValue
  blood_samples?: MedicalResearchConsentValue
  tissue_sample?: MedicalResearchConsentValue
  non_intrusive_treatment?: MedicalResearchConsentValue
  being_observed?: MedicalResearchConsentValue
  undertaking_survey?: MedicalResearchConsentValue
  collecing_disclosing_information?: MedicalResearchConsentValue
  evaluating_samples?: MedicalResearchConsentValue
  other?: MedicalResearchConsentValue
}

type MedicalResearchConsentValue = 
  | "IF_URGENT"
  | "IF_IMPROVE_CONDITION"
  | "ACHIEVE_BETTER_UNDERSTANDING_OF_FUTURE"
  | "IF_NO_OPTION"
  | "DONT_CONSENT"
```

**Possible Values:** `"IF_URGENT"`, `"IF_IMPROVE_CONDITION"`, `"ACHIEVE_BETTER_UNDERSTANDING_OF_FUTURE"`, `"IF_NO_OPTION"`, `"DONT_CONSENT"`

**Example:**
```json
{
  "placebos": "IF_IMPROVE_CONDITION",
  "use_equipment": "IF_IMPROVE_CONDITION",
  "less_practitioners_support": "DONT_CONSENT",
  "comparative_assessment": "ACHIEVE_BETTER_UNDERSTANDING_OF_FUTURE",
  "blood_samples": "IF_IMPROVE_CONDITION",
  "tissue_sample": "IF_IMPROVE_CONDITION",
  "non_intrusive_treatment": "IF_IMPROVE_CONDITION",
  "being_observed": "IF_IMPROVE_CONDITION",
  "undertaking_survey": "IF_IMPROVE_CONDITION",
  "collecing_disclosing_information": "IF_NO_OPTION",
  "evaluating_samples": "IF_IMPROVE_CONDITION",
  "other": "DONT_CONSENT"
}
```

---

### 7. LivingPreferencesDTO

Living and end-of-life preferences.

```typescript
interface LivingPreferencesDTO {
  health_treatment_priority?: string
  living_well_importance?: LivingWellImportanceValue[]
  is_nearing_death?: NearingDeathPreferenceValue[]
  nearing_death_goals_detail?: string
  wish_to_live?: string
  important_people_nearing_death?: string
  nearing_death_unacceptable?: string
  where_to_die?: "HOME" | "HOSPITAL" | "OTHER"
}

type LivingWellImportanceValue = 
  | "SPEND_TIME_WITH_FAMILY"
  | "LIVE_INDEPENDENTLY"
  | "VISIT_HOMETOWN"
  | "CARE_MYSELF"
  | "KEEP_ACTIVE"
  | "RECREATIONAL_ACTIVITIES"
  | "PRACTISING_RELIGION"
  | "LIVE_WITH_CULTURAL_RELGIOUS_VALUES"

type NearingDeathPreferenceValue = 
  | "AT_HOME"
  | "NOT_AT_HOME"
  | "NO_PREFERENCE"
  | "RECEIVE_CARE"
  | "OTHER"
```

**Possible Values for `living_well_importance`:**
- `"SPEND_TIME_WITH_FAMILY"`
- `"LIVE_INDEPENDENTLY"`
- `"VISIT_HOMETOWN"`
- `"CARE_MYSELF"`
- `"KEEP_ACTIVE"`
- `"RECREATIONAL_ACTIVITIES"`
- `"PRACTISING_RELIGION"`
- `"LIVE_WITH_CULTURAL_RELGIOUS_VALUES"`

**Possible Values for `is_nearing_death`:**
- `"AT_HOME"`
- `"NOT_AT_HOME"`
- `"NO_PREFERENCE"`
- `"RECEIVE_CARE"`
- `"OTHER"`

**Possible Values for `where_to_die`:**
- `"HOME"`
- `"HOSPITAL"`
- `"OTHER"`

**Example:**
```json
{
  "health_treatment_priority": "Maintain quality of life over quantity",
  "living_well_importance": ["SPEND_TIME_WITH_FAMILY", "LIVE_INDEPENDENTLY", "KEEP_ACTIVE"],
  "is_nearing_death": ["AT_HOME", "RECEIVE_CARE"],
  "nearing_death_goals_detail": "Be comfortable and surrounded by loved ones",
  "wish_to_live": "As long as I can maintain dignity and communicate",
  "important_people_nearing_death": "My spouse, children, and close friends",
  "nearing_death_unacceptable": "Being kept alive on machines with no consciousness",
  "where_to_die": "HOME"
}
```

---

### 8. TreatmentDecisionsDTO

Specific treatment decisions.

```typescript
interface TreatmentDecisionsDTO {
  life_sustaining_treatment?: 
    | "CONSENT_TO_ALL_TREATMENT"
    | "CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING"
    | "REFUSE_ALL_TREATMENT"
    | "CONSENT_SPECIFIC_TREATMENT"
    | "CANT_DECIDE"
  
  artificial_hydration?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE" | "CANT_DECIDE"
  artificial_hydration_instruction?: string
  
  other_treatment_decision?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE" | "CANT_DECIDE"
  other_treatment_decision_instruction?: string
  
  other_medical_support_instruction?: OtherMedicalSupportValue[]
  consent_palliative_comfort_care?: string
  
  specific_treatment_no_consent?: 
    | "ARTIFICIAL_FEEDING"
    | "RENAL_DIALYSIS"
    | "TRANSFUSIONS"
    | "OTHER"
}

type OtherMedicalSupportValue = 
  | "ARTIFICIAL_VENTILATION"
  | "RENAL_DIALYSIS"
  | "LIFE_PROLONGING_TREATMENT"
  | "OTHER"
```

**Possible Values for `life_sustaining_treatment`:**
- `"CONSENT_TO_ALL_TREATMENT"`
- `"CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING"`
- `"REFUSE_ALL_TREATMENT"`
- `"CONSENT_SPECIFIC_TREATMENT"`
- `"CANT_DECIDE"`

**Possible Values for `other_medical_support_instruction`:**
- `"ARTIFICIAL_VENTILATION"`
- `"RENAL_DIALYSIS"`
- `"LIFE_PROLONGING_TREATMENT"`
- `"OTHER"`

**Possible Values for `specific_treatment_no_consent`:**
- `"ARTIFICIAL_FEEDING"`
- `"RENAL_DIALYSIS"`
- `"TRANSFUSIONS"`
- `"OTHER"`

**Example:**
```json
{
  "life_sustaining_treatment": "CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING",
  "artificial_hydration": "CIRCUMSTANCE",
  "artificial_hydration_instruction": "Only if temporary and aids recovery",
  "other_treatment_decision": "CONSENT",
  "other_treatment_decision_instruction": "Open to treatments that improve quality of life",
  "other_medical_support_instruction": ["ARTIFICIAL_VENTILATION", "RENAL_DIALYSIS"],
  "consent_palliative_comfort_care": "Full consent for palliative care",
  "specific_treatment_no_consent": "ARTIFICIAL_FEEDING"
}
```

---

### 9. AttorneyAndAdviceDTO

Attorney powers and advice information.

```typescript
interface AttorneyAndAdviceDTO {
  attorney_decision_power?: "JOINTLY" | "SEVERALLY" | "MAJORITY" | "OTHER"
  attorney_decision_power_detail?: string
  
  has_used_interpreter?: 
    | "ENGLISH_FIRST_LANGUAGE"
    | "ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER"
    | "ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER"
  
  has_epg?: "NOT_DONE" | "DONE"
  epg_date?: string  // ISO date format: "YYYY-MM-DD"
  epg_place_detail?: string
  
  seek_medical_advice?: "OBTAIN_MEDICAL_ADVICE" | "NOT_OBTAIN_MEDICAL_ADVICE"
  seek_legal_advice?: "OBTAIN_LEGAL_ADVICE" | "NOT_OBTAIN_LEGAL_ADVICE"
}
```

**Possible Values:**
- `attorney_decision_power`: `"JOINTLY"`, `"SEVERALLY"`, `"MAJORITY"`, `"OTHER"`
- `has_used_interpreter`: `"ENGLISH_FIRST_LANGUAGE"`, `"ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER"`, `"ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER"`
- `has_epg`: `"NOT_DONE"`, `"DONE"`
- `seek_medical_advice`: `"OBTAIN_MEDICAL_ADVICE"`, `"NOT_OBTAIN_MEDICAL_ADVICE"`
- `seek_legal_advice`: `"OBTAIN_LEGAL_ADVICE"`, `"NOT_OBTAIN_LEGAL_ADVICE"`

**Example:**
```json
{
  "attorney_decision_power": "JOINTLY",
  "attorney_decision_power_detail": "Both attorneys must agree on major health decisions",
  "has_used_interpreter": "ENGLISH_FIRST_LANGUAGE",
  "has_epg": "DONE",
  "epg_date": "2025-06-15",
  "epg_place_detail": "Wilson & Associates Law Firm, Sydney",
  "seek_medical_advice": "OBTAIN_MEDICAL_ADVICE",
  "seek_legal_advice": "OBTAIN_LEGAL_ADVICE"
}
```

---

### 10. DeclarationsAndWishesDTO

General declarations and wishes.

```typescript
interface DeclarationsAndWishesDTO {
  declaration?: string
  what_matter_most?: string
  what_worries_most?: string
  unacceptable_medical_treatment_outcome?: string
  other_things_known?: string
  other_people_involved_in_care_discussion?: string
  appointment_conditon?: string
  other_medical_decision?: string
  cultural_request?: string
  religious_beliefs?: string
  after_death_importance?: string
}
```

**Example:**
```json
{
  "declaration": "I declare this to be my advance health directive made while of sound mind",
  "what_matter_most": "Maintaining my dignity and being able to communicate with my family",
  "what_worries_most": "Loss of cognitive abilities or being a burden",
  "unacceptable_medical_treatment_outcome": "Permanent vegetative state",
  "other_things_known": "I prefer natural remedies when appropriate",
  "other_people_involved_in_care_discussion": "My spouse and children",
  "appointment_conditon": "I appoint my spouse as primary decision maker",
  "other_medical_decision": "Allow experimental treatments if needed",
  "cultural_request": "Respect Greek Orthodox traditions",
  "religious_beliefs": "Greek Orthodox Christian",
  "after_death_importance": "Traditional Orthodox burial within 3 days"
}
```

---

### 11. AHDPersonDTO

Person associated with the AHD.

```typescript
interface AHDPersonDTO {
  full_name: string  // REQUIRED
  person_type: PersonType  // REQUIRED
  
  // Optional fields
  qualification?: string
  dob?: string  // ISO date format: "YYYY-MM-DD"
  phone?: string
  address?: string
  suburb?: string
  state?: string
  postcode?: string
  country?: string
  
  // Person-type-specific fields
  other?: Record<string, any>
}

type PersonType = 
  | "WITNESS_MEDICAL_PRACTITIONER"
  | "WITNESS_PERSON"
  | "INTERPRETER"
  | "DOCTOR"
  | "ATTORNEY_HEALTH_MATTERS"
  | "ENDURING_GUARDIAN"
  | "MEDICAL_GUARDIAN"
  | "SECONDARY_ENDURING_GUARDIAN"
  | "TERTIARY_ENDURING_GUARDIAN"
  | "MEDICAL_ADVISOR"
  | "LEGAL_ADVISOR"
  | "SUBSTITUTE_DECISION_MAKER"
  | "SUBSTITUTE_DECISION_MAKER_SECONDARY"
  | "SUBSTITUTE_DECISION_MAKER_TERTIARY"
  | "WITNESS_PRIMARY"
  | "WITNESS_AUTHORIZED"
  | "WITNESS_INTERPRETER"
  | "DECISION_MAKER"
  | "PRIMARY_PERSON"
  | "HELPER"
  | "SECONDARY_PERSON"
```

**Person Type Specific Fields (`other` object):**

#### WITNESS_MEDICAL_PRACTITIONER
```typescript
{
  signature?: string
  date?: string  // ISO date format
}
```

#### WITNESS_PERSON
```typescript
{
  signature?: string
  date?: string
}
```

#### INTERPRETER
```typescript
{
  naati_number?: string
  language?: "ENGLISH" | "MANDARIN" | "CANTONESE" | "ARABIC" | "VIETNAMESE" | "GREEK" | "ITALIAN" | "SPANISH" | "OTHER"
  signature?: string
  date?: string
}
```

#### DOCTOR
```typescript
{
  facility_name?: string
  date?: string
  signature?: string
}
```

#### MEDICAL_ADVISOR
```typescript
{
  practice?: string
}
```

#### LEGAL_ADVISOR
```typescript
{
  practice?: string
}
```

#### WITNESS_PRIMARY
```typescript
{
  signature?: string
  date?: string
}
```

#### WITNESS_AUTHORIZED
```typescript
{
  witness_category?: "JUSTICE_OF_PEACE" | "COMMISSIONER_FOR_DECLARATIONS" | "NOTARY_PUBLIC" | "LAWYER"
  signature?: string
  date?: string
  statement?: string
}
```

**Example:**
```json
{
  "full_name": "Dr. John Smith",
  "person_type": "WITNESS_MEDICAL_PRACTITIONER",
  "qualification": "MBBS, FRACP",
  "phone": "+61412345678",
  "address": "123 Medical Centre",
  "suburb": "Melbourne",
  "state": "VIC",
  "postcode": "3000",
  "country": "Australia",
  "other": {
    "signature": "base64_encoded_signature",
    "date": "2026-03-16"
  }
}
```

---

## Enum Values Reference

### Complete Enum List

#### BearableStatus
```typescript
type BearableStatus = "BEARABLE" | "UNBEARABLE" | "UNSURE"
```

#### CPRMedicalDecision
```typescript
type CPRMedicalDecision = "ACCEPT_CPR" | "REJECT_CPR"
```

#### CPRResuscitation
```typescript
type CPRResuscitation = "CONSENT" | "REFUSE" | "CIRCUMSTANCE" | "CANT_DECIDE"
```

#### CPRConsent
```typescript
type CPRConsent = "RESTART" | "CONDITION" | "ALLOW_TO_DIE"
```

#### LifeSustainingTreatmentDirectionType
```typescript
type LifeSustainingTreatmentDirectionType = 
  | "CONSENT"
  | "REFUSE"
  | "ATTORNEY_DECISION"
  | "SPECIFIC_DIRECTION"
```

#### LifeSustainingTreatmentType
```typescript
type LifeSustainingTreatmentType = "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
```

#### AssistedVentilation / ArtificialNutrition / Antibiotics
```typescript
type TreatmentConsent = "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
```

#### BloodTransfusion
```typescript
type BloodTransfusion = "CONSENT" | "REFUSE" | "OTHER"
```

#### AttorneyDecisionPower
```typescript
type AttorneyDecisionPower = "JOINTLY" | "SEVERALLY" | "MAJORITY" | "OTHER"
```

#### OrganDonation
```typescript
type OrganDonation = "CONSENT" | "REFUSE"
```

#### MedicalResearchConsent
```typescript
type MedicalResearchConsent = 
  | "IF_URGENT"
  | "IF_IMPROVE_CONDITION"
  | "ACHIEVE_BETTER_UNDERSTANDING_OF_FUTURE"
  | "IF_NO_OPTION"
  | "DONT_CONSENT"
```

#### LivingWellImportance
```typescript
type LivingWellImportance = 
  | "SPEND_TIME_WITH_FAMILY"
  | "LIVE_INDEPENDENTLY"
  | "VISIT_HOMETOWN"
  | "CARE_MYSELF"
  | "KEEP_ACTIVE"
  | "RECREATIONAL_ACTIVITIES"
  | "PRACTISING_RELIGION"
  | "LIVE_WITH_CULTURAL_RELGIOUS_VALUES"
```

#### NearingDeathPreference
```typescript
type NearingDeathPreference = 
  | "AT_HOME"
  | "NOT_AT_HOME"
  | "NO_PREFERENCE"
  | "RECEIVE_CARE"
  | "OTHER"
```

#### WhereToDie
```typescript
type WhereToDie = "HOME" | "HOSPITAL" | "OTHER"
```

#### LifeSustainingTreatmentDecision
```typescript
type LifeSustainingTreatmentDecision = 
  | "CONSENT_TO_ALL_TREATMENT"
  | "CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING"
  | "REFUSE_ALL_TREATMENT"
  | "CONSENT_SPECIFIC_TREATMENT"
  | "CANT_DECIDE"
```

#### OtherMedicalSupport
```typescript
type OtherMedicalSupport = 
  | "ARTIFICIAL_VENTILATION"
  | "RENAL_DIALYSIS"
  | "LIFE_PROLONGING_TREATMENT"
  | "OTHER"
```

#### SpecificTreatmentNoConsent
```typescript
type SpecificTreatmentNoConsent = 
  | "ARTIFICIAL_FEEDING"
  | "RENAL_DIALYSIS"
  | "TRANSFUSIONS"
  | "OTHER"
```

#### InterpreterUsage
```typescript
type InterpreterUsage = 
  | "ENGLISH_FIRST_LANGUAGE"
  | "ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER"
  | "ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER"
```

#### EPGStatus
```typescript
type EPGStatus = "NOT_DONE" | "DONE"
```

#### MedicalAdviceStatus
```typescript
type MedicalAdviceStatus = "OBTAIN_MEDICAL_ADVICE" | "NOT_OBTAIN_MEDICAL_ADVICE"
```

#### LegalAdviceStatus
```typescript
type LegalAdviceStatus = "OBTAIN_LEGAL_ADVICE" | "NOT_OBTAIN_LEGAL_ADVICE"
```

#### AHDPersonType
```typescript
type AHDPersonType = 
  | "WITNESS_MEDICAL_PRACTITIONER"
  | "WITNESS_PERSON"
  | "INTERPRETER"
  | "DOCTOR"
  | "ATTORNEY_HEALTH_MATTERS"
  | "ENDURING_GUARDIAN"
  | "MEDICAL_GUARDIAN"
  | "SECONDARY_ENDURING_GUARDIAN"
  | "TERTIARY_ENDURING_GUARDIAN"
  | "MEDICAL_ADVISOR"
  | "LEGAL_ADVISOR"
  | "SUBSTITUTE_DECISION_MAKER"
  | "SUBSTITUTE_DECISION_MAKER_SECONDARY"
  | "SUBSTITUTE_DECISION_MAKER_TERTIARY"
  | "WITNESS_PRIMARY"
  | "WITNESS_AUTHORIZED"
  | "WITNESS_INTERPRETER"
  | "DECISION_MAKER"
  | "PRIMARY_PERSON"
  | "HELPER"
  | "SECONDARY_PERSON"
```

#### Language
```typescript
type Language = 
  | "ENGLISH"
  | "MANDARIN"
  | "CANTONESE"
  | "ARABIC"
  | "VIETNAMESE"
  | "GREEK"
  | "ITALIAN"
  | "SPANISH"
  | "OTHER"
```

#### WitnessCategory
```typescript
type WitnessCategory = 
  | "JUSTICE_OF_PEACE"
  | "COMMISSIONER_FOR_DECLARATIONS"
  | "NOTARY_PUBLIC"
  | "LAWYER"
```

---

## Complete Example Request

Here's a complete example with all fields populated:

```json
{
  "acd_expiry_date": "2035-12-31",
  "is_acd_revoked": false,
  "is_registered_australian_organ_donor": true,
  "is_registered_tasmania_bequest_program": false,
  
  "health_conditions": {
    "major_health_conditions": "Diabetes Type 2, Hypertension, Mild Arthritis",
    "things_important_for_me": "Family, dignity, and quality of life",
    "beliefs_considered_during_health_care": "Catholic beliefs to be respected",
    "nearing_death_preference": "At home with family present",
    "people_not_to_involve_healthcare_discussion": "Estranged brother Robert"
  },
  
  "life_sustaining_treatment": {
    "direction_type": "CONSENT",
    "direction_instruction": "Accept with quality of life consideration",
    "treatment_type": "CIRCUMSTANCE",
    "treatment_instruction": "Only if recovery likely within 6 months",
    "assisted_ventilation": "CIRCUMSTANCE",
    "assisted_ventilation_instruction": "Short-term only (max 2 weeks)",
    "artificial_nutrition": "REFUSE",
    "artificial_nutrition_instruction": "No long-term tube feeding",
    "antibiotics": "CONSENT",
    "antibiotics_instruction": "Accept for treatable infections",
    "blood_transfusion": "CONSENT",
    "blood_transfusion_instruction": "Accept when necessary"
  },
  
  "quality_of_life_tolerance": {
    "no_longer_recognise_family": "UNBEARABLE",
    "no_bladder_control": "BEARABLE",
    "cant_feed_wash_dress": "BEARABLE",
    "rely_people_for_movement": "BEARABLE",
    "need_life_tube_for_food": "UNBEARABLE",
    "cant_converse_with_people": "UNBEARABLE"
  },
  
  "cpr_and_resuscitation": {
    "cpr_instruction": "UNBEARABLE",
    "medical_not_expected_to_recover": "REJECT_CPR",
    "cpr_resuscitation": "REFUSE",
    "cpr_resuscitation_instruction": "DNR if no recovery expected",
    "cpr_consent": "ALLOW_TO_DIE"
  },
  
  "organ_and_body_donation": {
    "donate_organ": true,
    "consent_organ_donation": true,
    "donate_body": false,
    "consent_body_donation": false,
    "authorisation": "Authorize all viable organ donation"
  },
  
  "medical_research_consent": {
    "placebos": "IF_IMPROVE_CONDITION",
    "use_equipment": "IF_IMPROVE_CONDITION",
    "less_practitioners_support": "DONT_CONSENT",
    "comparative_assessment": "IF_IMPROVE_CONDITION",
    "blood_samples": "IF_IMPROVE_CONDITION",
    "tissue_sample": "IF_IMPROVE_CONDITION",
    "non_intrusive_treatment": "IF_IMPROVE_CONDITION",
    "being_observed": "IF_IMPROVE_CONDITION",
    "undertaking_survey": "IF_IMPROVE_CONDITION",
    "collecing_disclosing_information": "IF_NO_OPTION",
    "evaluating_samples": "IF_IMPROVE_CONDITION",
    "other": "DONT_CONSENT"
  },
  
  "living_preferences": {
    "health_treatment_priority": "Quality of life over quantity",
    "living_well_importance": ["SPEND_TIME_WITH_FAMILY", "LIVE_INDEPENDENTLY", "KEEP_ACTIVE"],
    "is_nearing_death": ["AT_HOME", "RECEIVE_CARE"],
    "nearing_death_goals_detail": "Comfort and family presence",
    "wish_to_live": "With dignity and consciousness",
    "important_people_nearing_death": "Spouse and children",
    "nearing_death_unacceptable": "Permanent unconsciousness",
    "where_to_die": "HOME"
  },
  
  "treatment_decisions": {
    "life_sustaining_treatment": "CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING",
    "artificial_hydration": "CIRCUMSTANCE",
    "artificial_hydration_instruction": "Temporary only",
    "other_treatment_decision": "CONSENT",
    "other_treatment_decision_instruction": "Open to quality of life treatments",
    "other_medical_support_instruction": ["ARTIFICIAL_VENTILATION", "RENAL_DIALYSIS"],
    "consent_palliative_comfort_care": "Full consent",
    "specific_treatment_no_consent": "ARTIFICIAL_FEEDING"
  },
  
  "attorney_and_advice": {
    "attorney_decision_power": "JOINTLY",
    "attorney_decision_power_detail": "Both must agree",
    "has_used_interpreter": "ENGLISH_FIRST_LANGUAGE",
    "has_epg": "DONE",
    "epg_date": "2025-06-15",
    "epg_place_detail": "Wilson Law, Sydney",
    "seek_medical_advice": "OBTAIN_MEDICAL_ADVICE",
    "seek_legal_advice": "OBTAIN_LEGAL_ADVICE"
  },
  
  "declarations_and_wishes": {
    "declaration": "This is my advance health directive",
    "what_matter_most": "Dignity and family",
    "what_worries_most": "Loss of consciousness",
    "unacceptable_medical_treatment_outcome": "Vegetative state",
    "other_things_known": "Prefer natural remedies",
    "other_people_involved_in_care_discussion": "Spouse and children",
    "appointment_conditon": "Spouse as primary decision maker",
    "other_medical_decision": "Allow experimental if needed",
    "cultural_request": "Greek Orthodox traditions",
    "religious_beliefs": "Greek Orthodox",
    "after_death_importance": "Traditional burial"
  },
  
  "ahd_persons": [
    {
      "full_name": "Dr. John Smith",
      "person_type": "WITNESS_MEDICAL_PRACTITIONER",
      "qualification": "MBBS, FRACP",
      "phone": "+61412345678",
      "address": "123 Medical Centre",
      "suburb": "Melbourne",
      "state": "VIC",
      "postcode": "3000",
      "country": "Australia",
      "other": {
        "signature": "base64_signature",
        "date": "2026-03-16"
      }
    },
    {
      "full_name": "Jane Doe",
      "person_type": "ATTORNEY_HEALTH_MATTERS",
      "phone": "+61423456789",
      "address": "45 Oak Street",
      "suburb": "Melbourne",
      "state": "VIC",
      "postcode": "3001",
      "country": "Australia",
      "dob": "1970-05-20"
    }
  ]
}
```

---

## Validation Rules

### Required Fields
- `AHDPersonDTO.full_name` - Required
- `AHDPersonDTO.person_type` - Required

### Date Format
All date fields must use ISO 8601 format: `YYYY-MM-DD`

Examples:
- ✅ `"2026-03-16"`
- ✅ `"2025-12-31"`
- ❌ `"16/03/2026"`
- ❌ `"March 16, 2026"`

### Phone Format
Recommended format: International format with country code

Examples:
- ✅ `"+61412345678"`
- ✅ `"+1-555-123-4567"`
- ✅ `"0412345678"`

### Enum Validation
All enum fields must match exactly (case-sensitive):
- ✅ `"CONSENT"`
- ❌ `"consent"`
- ❌ `"Consent"`

### Boolean Fields
Must be `true` or `false` (lowercase, no quotes in JSON):
```json
{
  "donate_organ": true,
  "consent_organ_donation": false
}
```

### Array Fields
Fields expecting arrays must provide arrays, even if empty:
```json
{
  "living_well_importance": ["SPEND_TIME_WITH_FAMILY"],
  "other_medical_support_instruction": []
}
```

---

## Error Responses

### Validation Error Example
```json
{
  "detail": [
    {
      "loc": ["body", "cpr_and_resuscitation", "cpr_consent"],
      "msg": "Input should be 'RESTART', 'CONDITION', or 'ALLOW_TO_DIE'",
      "type": "enum"
    }
  ]
}
```

### Common Errors
1. **Invalid Enum Value**: Enum value doesn't match allowed values
2. **Missing Required Field**: Required field not provided
3. **Invalid Date Format**: Date not in YYYY-MM-DD format
4. **Type Mismatch**: Expected boolean but got string, etc.

---

## Response Format

### Success Response
```typescript
interface AHDResponse {
  id: string
  user_id: string
  
  // All fields from AHDCreate
  // Plus:
  created_at: string  // ISO 8601 timestamp
  updated_at: string  // ISO 8601 timestamp
  is_active: boolean
}
```

**Example:**
```json
{
  "id": "ahd_123456789",
  "user_id": "user_987654321",
  "health_conditions": {
    "major_health_conditions": "Diabetes Type 2"
  },
  "created_at": "2026-03-16T10:30:00Z",
  "updated_at": "2026-03-16T10:30:00Z",
  "is_active": true
}
```

---

## Quick Reference Table

| DTO | Key Fields | Example Values |
|-----|------------|----------------|
| HealthConditionsDTO | 5 text fields | Free text |
| LifeSustainingTreatmentDTO | 7 enum + 7 text | CONSENT, REFUSE, CIRCUMSTANCE |
| QualityOfLifeToleranceDTO | 6 enums | BEARABLE, UNBEARABLE, UNSURE |
| CPRAndResuscitationDTO | 3 enums + 2 text | ACCEPT_CPR, REJECT_CPR, etc. |
| OrganAndBodyDonationDTO | 4 booleans + 1 text | true, false |
| MedicalResearchConsentDTO | 12 enums | IF_URGENT, IF_IMPROVE_CONDITION, etc. |
| LivingPreferencesDTO | 2 arrays + 5 text + 1 enum | Arrays of preferences |
| TreatmentDecisionsDTO | 3 enums + 4 text + 1 array | Treatment decisions |
| AttorneyAndAdviceDTO | 5 enums + 3 text | JOINTLY, SEVERALLY, etc. |
| DeclarationsAndWishesDTO | 11 text fields | Free text |
| AHDPersonDTO | 2 required + 9 optional | 21 person types |

---

## TypeScript Interface (Complete)

Copy this into your frontend project:

```typescript
// Main Request Type
export interface AHDCreateRequest {
  id?: string
  
  // High-level flags
  acd_expiry_date?: string
  is_acd_revoked?: boolean
  is_registered_australian_organ_donor?: boolean
  is_registered_tasmania_bequest_program?: boolean
  
  // Structured DTOs
  health_conditions?: HealthConditionsDTO
  life_sustaining_treatment?: LifeSustainingTreatmentDTO
  quality_of_life_tolerance?: QualityOfLifeToleranceDTO
  cpr_and_resuscitation?: CPRAndResuscitationDTO
  organ_and_body_donation?: OrganAndBodyDonationDTO
  medical_research_consent?: MedicalResearchConsentDTO
  living_preferences?: LivingPreferencesDTO
  treatment_decisions?: TreatmentDecisionsDTO
  attorney_and_advice?: AttorneyAndAdviceDTO
  declarations_and_wishes?: DeclarationsAndWishesDTO
  
  ahd_persons?: AHDPersonDTO[]
}

export interface HealthConditionsDTO {
  major_health_conditions?: string
  things_important_for_me?: string
  beliefs_considered_during_health_care?: string
  nearing_death_preference?: string
  people_not_to_involve_healthcare_discussion?: string
}

export interface LifeSustainingTreatmentDTO {
  direction_type?: "CONSENT" | "REFUSE" | "ATTORNEY_DECISION" | "SPECIFIC_DIRECTION"
  direction_instruction?: string
  treatment_type?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  treatment_instruction?: string
  assisted_ventilation?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  assisted_ventilation_instruction?: string
  artificial_nutrition?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  artificial_nutrition_instruction?: string
  antibiotics?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  antibiotics_instruction?: string
  blood_transfusion?: "CONSENT" | "REFUSE" | "OTHER"
  blood_transfusion_instruction?: string
  other_treatment?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE"
  other_instruction?: string
}

export interface QualityOfLifeToleranceDTO {
  no_longer_recognise_family?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  no_bladder_control?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  cant_feed_wash_dress?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  rely_people_for_movement?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  need_life_tube_for_food?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  cant_converse_with_people?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
}

export interface CPRAndResuscitationDTO {
  cpr_instruction?: "BEARABLE" | "UNBEARABLE" | "UNSURE"
  medical_not_expected_to_recover?: "ACCEPT_CPR" | "REJECT_CPR"
  cpr_resuscitation?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE" | "CANT_DECIDE"
  cpr_resuscitation_instruction?: string
  cpr_consent?: "RESTART" | "CONDITION" | "ALLOW_TO_DIE"
}

export interface OrganAndBodyDonationDTO {
  donate_organ?: boolean
  consent_organ_donation?: boolean
  donate_body?: boolean
  consent_body_donation?: boolean
  authorisation?: string
}

export type MedicalResearchConsentValue = 
  | "IF_URGENT"
  | "IF_IMPROVE_CONDITION"
  | "ACHIEVE_BETTER_UNDERSTANDING_OF_FUTURE"
  | "IF_NO_OPTION"
  | "DONT_CONSENT"

export interface MedicalResearchConsentDTO {
  placebos?: MedicalResearchConsentValue
  use_equipment?: MedicalResearchConsentValue
  less_practitioners_support?: MedicalResearchConsentValue
  comparative_assessment?: MedicalResearchConsentValue
  blood_samples?: MedicalResearchConsentValue
  tissue_sample?: MedicalResearchConsentValue
  non_intrusive_treatment?: MedicalResearchConsentValue
  being_observed?: MedicalResearchConsentValue
  undertaking_survey?: MedicalResearchConsentValue
  collecing_disclosing_information?: MedicalResearchConsentValue
  evaluating_samples?: MedicalResearchConsentValue
  other?: MedicalResearchConsentValue
}

export type LivingWellImportanceValue = 
  | "SPEND_TIME_WITH_FAMILY"
  | "LIVE_INDEPENDENTLY"
  | "VISIT_HOMETOWN"
  | "CARE_MYSELF"
  | "KEEP_ACTIVE"
  | "RECREATIONAL_ACTIVITIES"
  | "PRACTISING_RELIGION"
  | "LIVE_WITH_CULTURAL_RELGIOUS_VALUES"

export type NearingDeathPreferenceValue = 
  | "AT_HOME"
  | "NOT_AT_HOME"
  | "NO_PREFERENCE"
  | "RECEIVE_CARE"
  | "OTHER"

export interface LivingPreferencesDTO {
  health_treatment_priority?: string
  living_well_importance?: LivingWellImportanceValue[]
  is_nearing_death?: NearingDeathPreferenceValue[]
  nearing_death_goals_detail?: string
  wish_to_live?: string
  important_people_nearing_death?: string
  nearing_death_unacceptable?: string
  where_to_die?: "HOME" | "HOSPITAL" | "OTHER"
}

export interface TreatmentDecisionsDTO {
  life_sustaining_treatment?: 
    | "CONSENT_TO_ALL_TREATMENT"
    | "CONSENT_TO_TREATMENT_UNTIL_RECOVER_WITHDRAW_LIFE_SUSTAINING"
    | "REFUSE_ALL_TREATMENT"
    | "CONSENT_SPECIFIC_TREATMENT"
    | "CANT_DECIDE"
  artificial_hydration?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE" | "CANT_DECIDE"
  artificial_hydration_instruction?: string
  other_treatment_decision?: "CONSENT" | "REFUSE" | "CIRCUMSTANCE" | "CANT_DECIDE"
  other_treatment_decision_instruction?: string
  other_medical_support_instruction?: Array<"ARTIFICIAL_VENTILATION" | "RENAL_DIALYSIS" | "LIFE_PROLONGING_TREATMENT" | "OTHER">
  consent_palliative_comfort_care?: string
  specific_treatment_no_consent?: "ARTIFICIAL_FEEDING" | "RENAL_DIALYSIS" | "TRANSFUSIONS" | "OTHER"
}

export interface AttorneyAndAdviceDTO {
  attorney_decision_power?: "JOINTLY" | "SEVERALLY" | "MAJORITY" | "OTHER"
  attorney_decision_power_detail?: string
  has_used_interpreter?: 
    | "ENGLISH_FIRST_LANGUAGE"
    | "ENGLISH_NOT_FIRST_LANGUAGE_ENGAGED_INTERPRETER"
    | "ENGLISH_NOT_FIRST_LANGUAGE_NOT_ENGAGED_INTERPRETER"
  has_epg?: "NOT_DONE" | "DONE"
  epg_date?: string
  epg_place_detail?: string
  seek_medical_advice?: "OBTAIN_MEDICAL_ADVICE" | "NOT_OBTAIN_MEDICAL_ADVICE"
  seek_legal_advice?: "OBTAIN_LEGAL_ADVICE" | "NOT_OBTAIN_LEGAL_ADVICE"
}

export interface DeclarationsAndWishesDTO {
  declaration?: string
  what_matter_most?: string
  what_worries_most?: string
  unacceptable_medical_treatment_outcome?: string
  other_things_known?: string
  other_people_involved_in_care_discussion?: string
  appointment_conditon?: string
  other_medical_decision?: string
  cultural_request?: string
  religious_beliefs?: string
  after_death_importance?: string
}

export type PersonType = 
  | "WITNESS_MEDICAL_PRACTITIONER"
  | "WITNESS_PERSON"
  | "INTERPRETER"
  | "DOCTOR"
  | "ATTORNEY_HEALTH_MATTERS"
  | "ENDURING_GUARDIAN"
  | "MEDICAL_GUARDIAN"
  | "SECONDARY_ENDURING_GUARDIAN"
  | "TERTIARY_ENDURING_GUARDIAN"
  | "MEDICAL_ADVISOR"
  | "LEGAL_ADVISOR"
  | "SUBSTITUTE_DECISION_MAKER"
  | "SUBSTITUTE_DECISION_MAKER_SECONDARY"
  | "SUBSTITUTE_DECISION_MAKER_TERTIARY"
  | "WITNESS_PRIMARY"
  | "WITNESS_AUTHORIZED"
  | "WITNESS_INTERPRETER"
  | "DECISION_MAKER"
  | "PRIMARY_PERSON"
  | "HELPER"
  | "SECONDARY_PERSON"

export interface AHDPersonDTO {
  full_name: string
  person_type: PersonType
  qualification?: string
  dob?: string
  phone?: string
  address?: string
  suburb?: string
  state?: string
  postcode?: string
  country?: string
  other?: Record<string, any>
}

export interface AHDResponse extends AHDCreateRequest {
  id: string
  user_id: string
  created_at: string
  updated_at: string
  is_active: boolean
}
```

---

## Summary

- ✅ All fields are optional unless marked as required
- ✅ All enum values are case-sensitive and must match exactly
- ✅ Dates must be in ISO 8601 format (YYYY-MM-DD)
- ✅ Arrays can be empty but must be arrays if provided
- ✅ The API validates all input automatically
- ✅ Clear error messages are returned for validation failures

For questions or issues, refer to the complete example request or contact the backend team.

---

**Document Version:** 1.0  
**Last Updated:** March 16, 2026  
**Maintained By:** Backend Team

