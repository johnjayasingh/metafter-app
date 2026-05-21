# POA All-States Comprehensive Audit Report

**Date:** June 2025  
**Environment:** DEV (`http://13.54.59.56:8000`)  
**Test Account:** johnjayasingh.s@gmail.com  
**Scope:** All 8 Australian states — QLD, NSW, VIC, SA, WA, TAS, NT, ACT

---

## Executive Summary

| Category | Count |
|----------|-------|
| **Fields Tested** | 99 |
| **PASS** | 90 |
| **FAIL (Backend Bugs)** | 8 |
| **WARNINGS (Code Issues)** | 15 |
| **Backend Gaps (Not Persisted)** | 0 |

**Overall:** 90/99 fields pass round-trip save/retrieve (91%). The 8 failures are all **backend bugs** — fields defined in OpenAPI schema that are accepted but not returned by GET. The 15 warnings are Flutter code architecture issues that need fixing.

### Backend Team Clarifications (from Ragavendran)
- **`has_terms_instructions` / `terms_instructions`** — These fields do NOT exist in the backend. Flutter should use `has_conditions_limitations` / `conditions_limitations` instead.
- **`matters` enum** — Confirmed values: `PERSONAL`, `HEALTH`, `FINANCE`, `SPECIFIC`. Backend will add a new combined type: **`PERSONAL AND FINANCE`** (single string instead of sending `["PERSONAL", "FINANCE"]` array). **Not deployed yet** — still returns 422.
- **`specific_matters`** — This field does NOT exist in the backend. `SPECIFIC` is just a `matters` enum value. There is **no field** to store custom description text. Flutter must stop sending `specific_matters` and should store the text in an existing field (e.g. `conditions_limitations` or `attorney_instruction`).

---

## 1. API Round-Trip Test Results by State

### QLD (Queensland) — Universal Payload ✅
| # | Field | Result |
|---|-------|--------|
| 1 | `matters` | ✅ PASS |
| 2 | `financial_commencement` | ✅ PASS (`DONT_HAVE_CAPACITY` → `INCAPACITY` mapping verified) |
| 3 | `has_preference` | ✅ PASS |
| 4 | `preferences` | ✅ PASS |
| 5 | `has_attorney_instruction` | ✅ PASS |
| 6 | `attorney_instruction` | ✅ PASS |
| 7 | `need_signing_assistance` | ✅ PASS |
| 8 | `has_conditions_limitations` | ✅ PASS |
| 9 | `conditions_limitations` | ✅ PASS |
| 10 | `has_terms_instructions` | ⚠️ Field does NOT exist in backend — use `has_conditions_limitations` instead |
| 11 | `terms_instructions` | ⚠️ Field does NOT exist in backend — use `conditions_limitations` instead |

**QLD: 9/9 pass** — QLD already maps `termsInstructions` → `conditions_limitations` as fallback in payload

---

### NSW (New South Wales) — Universal Payload ✅
| # | Field | Result |
|---|-------|--------|
| 1 | `attorney_additional_powers` | ✅ PASS |
| 2 | `has_conditions_limitations` | ✅ PASS |
| 3 | `conditions_limitations` | ✅ PASS |
| 4 | `matters` | ✅ PASS |
| 5 | `has_preference` | ✅ PASS |
| 6 | `preferences` | ✅ PASS |
| 7 | `has_attorney_instruction` | ✅ PASS |
| 8 | `attorney_instruction` | ✅ PASS |
| 9 | `need_signing_assistance` | ✅ PASS |

**NSW: 9/9 pass** (verified with correct `REASONABLE_GIFTS` enum)

---

### VIC (Victoria) — Universal Payload ✅
| # | Field | Result |
|---|-------|--------|
| 1 | `matters` | ✅ PASS |
| 2 | `commencement` | ✅ PASS |
| 3 | `has_preference` | ✅ PASS |
| 4 | `preferences` | ✅ PASS |
| 5 | `has_attorney_instruction` | ✅ PASS |
| 6 | `attorney_instruction` | ✅ PASS |
| 7 | `need_signing_assistance` | ✅ PASS |
| 8 | `need_revocation` | ✅ PASS |
| 9 | `previous_poa_detail` | ✅ PASS |
| 10 | `ci_conflict_transactions` | ✅ PASS |
| 11 | `ci_gifts` | ✅ PASS |
| 12 | `ci_dependent_maintenance` | ✅ PASS |
| 13 | `ci_payment_to_attorney` | ✅ PASS |
| 14 | `ci_additional_condition` | ✅ PASS |
| 15 | `has_conditions_limitations` | ✅ PASS |
| 16 | `conditions_limitations` | ✅ PASS |
| 17 | `specific_matters` | ⚠️ Field does NOT exist in backend — `SPECIFIC` is just a matters enum value, custom text has NO storage |
| 18 | `has_terms_instructions` | ⚠️ Field does NOT exist in backend — use `has_conditions_limitations` |
| 19 | `terms_instructions` | ⚠️ VIC terms data LOST — saved to non-existent field, not mapped to `conditions_limitations` |

**VIC: 16/16 pass, 2 Flutter data loss bugs (VIC terms + specific matters text)**

---

### SA (South Australia) — Dedicated Payload ✅
| # | Field | Result |
|---|-------|--------|
| 1 | `full_legal_name` | ✅ PASS |
| 2 | `residential_address` | ✅ PASS |
| 3 | `email_id` | ✅ PASS |
| 4 | `has_second_donor` | ✅ PASS |
| 5 | `donees_act_rules` | ✅ PASS |
| 6 | `poa_start_rule` | ✅ PASS |
| 7 | `has_conditions_limitations` | ✅ PASS |
| 8 | `conditions_limitations` | ✅ PASS |

**SA: 8/8 pass**

---

### WA (Western Australia) — Dedicated Payload ✅
| # | Field | Result |
|---|-------|--------|
| 1 | `full_legal_name` | ✅ PASS |
| 2 | `residential_address` | ✅ PASS |
| 3 | `email_id` | ✅ PASS |
| 4 | `attorney_appointment_type` | ✅ PASS |
| 5 | `has_substitute_attorney` | ✅ PASS |
| 6 | `substitute_attorney_appointment_type` | ✅ PASS |
| 7 | `substitute_act_substitution` | ✅ PASS |
| 8 | `substitute_act_activation` | ✅ PASS |
| 9 | `has_conditions_restrictions` | ✅ PASS |
| 10 | `conditions_restrictions` | ✅ PASS |
| 11 | `epa_effect` | ✅ PASS |
| 12 | `enduring_poa_completion_date` | ✅ PASS |

**WA: 12/12 pass**

---

### TAS (Tasmania) — Dedicated Payload ✅
| # | Field | Result |
|---|-------|--------|
| 1 | `is_adult` | ✅ PASS |
| 2 | `is_understand_effect_poa` | ✅ PASS |
| 3 | `full_legal_name` | ✅ PASS |
| 4 | `residential_address` | ✅ PASS |
| 5 | `email_id` | ✅ PASS |
| 6 | `attorney_act_rules` | ✅ PASS |
| 7 | `has_conditions_limitations` | ✅ PASS |
| 8 | `conditions_limitations` | ✅ PASS |

**TAS: 8/8 pass**

---

### NT (Northern Territory) — Dedicated Payload ⚠️
| # | Field | Result |
|---|-------|--------|
| 1 | `is_adult` | ✅ PASS |
| 2 | `is_doing_voluntarily` | ✅ PASS |
| 3 | `full_legal_name` | ✅ PASS |
| 4 | `residential_address` | ✅ PASS |
| 5 | `email_id` | ✅ PASS |
| 6 | `attorney_act_rules` | ✅ PASS |
| 7 | `instruction_decision_makers` | ✅ PASS |
| 8 | `has_land_northern_territory` | ✅ PASS |
| 9 | `need_financial_decision_for_land` | ✅ PASS |
| 10 | `number_of_decision_makers` | ❌ FAIL — expected=2, got=None |

**NT: 9/10 pass, 1 backend bug**

---

### ACT (Australian Capital Territory) — Dedicated Payload ⚠️
| # | Field | Result |
|---|-------|--------|
| 1 | `is_adult` | ✅ PASS |
| 2 | `is_understand_effect_poa` | ✅ PASS |
| 3 | `full_legal_name` | ✅ PASS |
| 4 | `residential_address` | ✅ PASS |
| 5 | `email_id` | ✅ PASS |
| 6 | `is_attorney_corporate` | ✅ PASS |
| 7 | `is_attorney_declared_bankrupt` | ✅ PASS |
| 8 | `attorney_act_rules` | ✅ PASS |
| 9 | `attorney_powers` | ✅ PASS |
| 10 | `direction_property` | ✅ PASS |
| 11 | `direction_personal_care` | ✅ PASS |
| 12 | `direction_health_care` | ✅ PASS |
| 13 | `direction_medical_research` | ✅ PASS |
| 14 | `medical_treatment_withdraw` | ✅ PASS |
| 15 | `specific_treatment` | ✅ PASS |
| 16 | `attorney_power_commencement` | ✅ PASS |
| 17 | `attorney_power_commencement_circumstance` | ✅ PASS |
| 18 | `enduring_poa` | ✅ PASS |
| 19 | `previous_poa_detail` | ✅ PASS |
| 20 | `date_poa` | ✅ PASS |
| 21 | `attorney_name_poa` | ✅ PASS |
| 22 | `is_epoa_sign` | ✅ PASS |
| 23 | `attorney_power_matters` | ✅ PASS |
| 24 | `number_of_attorneys` | ❌ FAIL — expected=2, got=None |
| 25 | `attorney_name` | ❌ FAIL — expected='Attorney One', got=None |
| 26 | `attorney_address` | ❌ FAIL — expected='1 Attorney St', got=None |
| 27 | `attorney_2_name` | ❌ FAIL — expected='Attorney Two', got=None |
| 28 | `attorney_2_address` | ❌ FAIL — expected='2 Attorney St', got=None |
| 29 | `is_attorney_2_corporate` | ❌ FAIL — expected=True, got=None |
| 30 | `attorney_2_corporation_type` | ❌ FAIL — expected='TRUSTEE_COMPANY', got=None |

**ACT: 23/30 pass, 7 backend bugs**

---

### Attorney Endpoint ✅
| Type | Name | Result |
|------|------|--------|
| PRIMARY | Sarah Ann Johnson | ✅ Returned |
| SUCCESSIVE | Tommy James Doe | ✅ Returned |
| PERSONAL_ASSISTANCE | dfdf Dfdf | ✅ Returned |
| MEDICAL_DECISION_MAKER | Dr. Jane Medical Smith | ✅ Returned |

**Attorney endpoint: 4/4 types verified**

### Notification Endpoint ✅
| Type | For | Of |
|------|-----|-----|
| HEALTH | ME | OTHER |

**Notification: 1/1 verified**

---

## 2. Backend Bugs (Require Backend Fix)

### BUG-1: ACT attorney inline fields not persisted (7 fields)
**Fields:** `number_of_attorneys`, `attorney_name`, `attorney_address`, `attorney_2_name`, `attorney_2_address`, `is_attorney_2_corporate`, `attorney_2_corporation_type`
**Impact:** ACT attorney details cannot be prefilled on edit. Fields are in OpenAPI schema, sent by both Flutter and web app, but backend GET returns `null`.
**Severity:** HIGH — Breaks edit flow for ACT

### BUG-2: NT `number_of_decision_makers` not persisted
**Impact:** Cannot prefill how many decision makers the user selected. Field is in OpenAPI schema.
**Severity:** MEDIUM — NT edit flow partially broken

### ~~BUG-3~~ RESOLVED: `specific_matters` — NOT a backend field
**Clarification from backend:** `specific_matters` does not exist in the API. `SPECIFIC` is just a `matters` enum value. The custom description text entered by the VIC user has no backend storage.
**Verified by API test:** POST with `matters: ['SPECIFIC'], specific_matters: 'text'` → GET returns `specific_matters: null`.
**OpenAPI schema:** Field not defined.
**Impact:** VIC users who select "Specific matters" and type custom text will lose that text on save.
**Fix needed:** Flutter must store the specific matters text in an existing field (e.g. `conditions_limitations` or `attorney_instruction`), or request backend to add the field.

### ~~BUG-4~~ RESOLVED: `has_terms_instructions` / `terms_instructions` — NOT backend fields
**Clarification from backend:** These fields intentionally do not exist. Flutter should use `has_conditions_limitations` / `conditions_limitations` instead.
**Impact on QLD:** Already works — `_buildUniversalPayload()` maps `termsInstructions` → `conditions_limitations` as fallback for non-VIC states.
**Impact on VIC:** **DATA LOSS BUG** — VIC sends `has_terms_instructions`/`terms_instructions` separately into the void. VIC's "Terms and limits" text is never persisted. See ISSUE-11 below.

### UPCOMING: `matters` combined type
**Backend will add:** `PERSONAL_AND_FINANCE = "PERSONAL AND FINANCE"` to `POAMatters` enum.
**Current Flutter behavior:** Sends `["PERSONAL", "FINANCE"]` as two array items when both PERSONAL_HEALTH and FINANCIAL are selected.
**Action needed:** Once backend deploys, update Flutter `_buildUniversalPayload()` to send `['PERSONAL AND FINANCE']` and update `fromPoaData()` reverse mapping to handle it.

---

## 3. Flutter Code Issues (Require Flutter Fix)

### ISSUE-1: Duplicate attorneys on re-save (ACT) — HIGH
**File:** `lib/features/poa/presentation/screens/poa_step5_act_screen.dart`
**Problem:** `createAttorneyForPoa(APPOINTED_ATTORNEY)` is called without first deleting existing APPOINTED_ATTORNEY records. Re-saving creates duplicate entries.
**Fix:** Add `deleteAttorneysByType('APPOINTED_ATTORNEY')` before the loop that creates new attorneys.

### ISSUE-2: Duplicate decision makers on re-save (NT) — HIGH
**File:** `lib/features/poa/presentation/screens/poa_assistance_signing_screen.dart`
**Problem:** `createAttorneyForPoa(FINANCIAL_DECISION_MAKER_*)` called without deleting existing records first.
**Fix:** Add `deleteAttorneysByType('FINANCIAL_DECISION_MAKER_PRIMARY')`, `deleteAttorneysByType('FINANCIAL_DECISION_MAKER_SECONDARY')`, `deleteAttorneysByType('FINANCIAL_DECISION_MAKER_TERTIARY')` before re-save.

### ISSUE-3: Duplicate medical DM on re-save (VIC) — HIGH
**File:** `lib/features/poa/presentation/screens/poa_assistance_signing_screen.dart`
**Problem:** `createAttorneyForPoa(MEDICAL_DECISION_MAKER)` called without deleting existing records first.
**Fix:** Add `deleteAttorneysByType('MEDICAL_DECISION_MAKER')` before creating new medical DM.

### ISSUE-4: SA donee/second donor prefill missing — HIGH
**File:** `lib/features/home/presentation/tabs/poa_tab.dart` → `_applyAttorneys()`
**Problem:** `_applyAttorneys()` doesn't handle `SECOND_DONOR` or `ATTORNEY_DONEE` attorney types. SA donee details and second donor details from the attorney endpoint cannot be prefilled on edit.
**Fix:** Add cases in `_applyAttorneys()`:
```dart
case 'SECOND_DONOR':
  flowData.saSecondDonorName = attorney.fullName;
  flowData.saSecondDonorAddress = attorney.address;
  // etc.
case 'ATTORNEY_DONEE':
  flowData.saDoneeName = attorney.fullName;
  flowData.saDoneeEmail = attorney.email;
  // etc.
```

### ISSUE-5: Notification always saved for all states — MEDIUM
**File:** `lib/features/poa/data/services/poa_service.dart` → `createOrUpdatePoa()`
**Problem:** `createOrUpdatePoa()` always calls `createPoaNotification()` regardless of state. SA, WA, TAS, NT, ACT don't have notification screens — this creates empty/stale notification records.
**Fix:** Only call `createPoaNotification()` for QLD/NSW/VIC states.

### ISSUE-6: Universal payload sends VIC-only fields to QLD/NSW — LOW
**File:** `lib/features/poa/data/models/poa_models.dart` → `_buildUniversalPayload()`
**Problem:** `ci_conflict_transactions`, `ci_gifts`, `ci_dependent_maintenance`, `ci_payment_to_attorney`, `ci_additional_condition`, `commencement` fields are VIC-only but sent in the universal payload for QLD/NSW too. Backend accepts them but stores stale data.
**Fix:** Conditionally include VIC-only fields only when `state == 'victoria'`.

### ISSUE-7: WA/TAS date field cross-contamination — MEDIUM
**File:** `lib/features/poa/data/models/poa_models.dart` → `fromPoaData()`
**Problem:** `enduring_poa_completion_date` is read into both `epaDate` (WA) and `tasCompletionDate` (TAS) in `fromPoaData()`. Switching between WA and TAS edits could pre-populate wrong dates.
**Fix:** Only set `epaDate` when state is WA, only set `tasCompletionDate` when state is TAS.

### ISSUE-8: TAS attorneys may not be saved — MEDIUM
**File:** `lib/features/poa/presentation/screens/poa_review_nsw_screen.dart`
**Problem:** TAS save goes through `poa_review_nsw_screen` which only has WA-specific attorney save logic (`_saveWaAttorneys`). TAS attorneys may not be saved to the attorney endpoint.
**Needs verification:** Check if TAS attorney save is handled elsewhere or if this is a bug.

### ISSUE-9: NSW guardians/substitutes may not be saved — MEDIUM
**File:** `lib/features/poa/presentation/screens/poa_review_nsw_screen.dart`
**Problem:** NSW save goes through `_handleSaveAndDownload` which only calls `_saveWaAttorneys` for WA state. NSW guardian and substitute attorney details may not be saved via the attorney endpoint.
**Needs verification:** Check if NSW has a separate attorney save flow.

### ISSUE-10: QLD dual notification limitation — LOW
**File:** `lib/features/poa/presentation/screens/poa_qld_final_screen.dart`
**Problem:** QLD can have both `PERSONAL_HEALTH` and `FINANCIAL` matters simultaneously, but the API only stores ONE notification record. If user has both, only the last one saved persists.
**Status:** This may be a backend design limitation rather than a Flutter bug.

### ISSUE-11: VIC "Terms and limits" data LOST — HIGH (NEW)
**File:** `lib/features/poa/data/models/poa_models.dart` → `_buildUniversalPayload()`
**Problem:** VIC sends terms data to non-existent backend fields:
```dart
// VIC currently sends:
'has_conditions_limitations': hasLimitations ?? false,         // "Limitations" only
'conditions_limitations': limitationsDetails?.trim(),          // "Limitations" text only
'has_terms_instructions': hasTermsInstructions ?? false,       // ← LOST (field doesn't exist)
'terms_instructions': termsInstructions?.trim(),               // ← LOST (field doesn't exist)
```
**Impact:** Any text entered in VIC's "Terms and limits" section is silently discarded by the backend. Cannot be prefilled on edit.
**Fix:** Combine VIC's `termsInstructions` and `limitationsDetails` into `conditions_limitations`:
```dart
// For VIC:
'has_conditions_limitations': (hasLimitations ?? false) || (hasTermsInstructions ?? false),
'conditions_limitations': [limitationsDetails?.trim(), termsInstructions?.trim()]
    .where((s) => s != null && s.isNotEmpty)
    .join('\n---\n'),
```
And update `fromPoaData()` to split them back on prefill.

### ISSUE-12: `matters` mapping update needed (UPCOMING)
**File:** `lib/features/poa/data/models/poa_models.dart` → `_buildUniversalPayload()` + `fromPoaData()`
**Problem:** Backend is adding `PERSONAL_AND_FINANCE` combined enum. Currently Flutter sends `['PERSONAL', 'FINANCE']`.
**Status:** Not deployed yet — `['PERSONAL AND FINANCE']` returns 422. Current `['PERSONAL', 'FINANCE']` still works.
**Action:** Once backend deploys:
```dart
// In _buildUniversalPayload():
if (matters.contains('PERSONAL_HEALTH') && matters.contains('FINANCIAL')) {
  apiMatters = ['PERSONAL AND FINANCE'];  // New combined value
}

// In fromPoaData():
if (data.matters.contains('PERSONAL AND FINANCE')) {
  uiMatters = ['PERSONAL_HEALTH', 'FINANCIAL'];
}
```

### ISSUE-13: VIC "Specific matters" text data loss — HIGH (NEW)
**File:** `lib/features/poa/data/models/poa_models.dart` → `_buildUniversalPayload()`
**Problem:** `specific_matters` field does NOT exist in the backend API (not in OpenAPI schema). When VIC user selects "Specific matters" and enters custom description text, it's sent as:
```dart
'specific_matters': matters.contains('SPECIFIC') ? specificMatters?.trim() : null,
```
But the backend silently discards this — GET returns `specific_matters: null`.
**Verified:** POST with `matters: ['SPECIFIC'], specific_matters: 'My text'` → GET returns `specific_matters: null`.
**Impact:** VIC specific matters custom text is permanently lost. Cannot be prefilled on edit.
**Fix options:**
1. **Ask backend to add the field** — cleanest solution
2. **Store in `conditions_limitations`** — use as fallback storage
3. **Store in `attorney_instruction`** — use as fallback storage

---

## 4. State-by-State Health Summary

| State | API Fields | Attorney Save | Attorney Prefill | Notification | Issues |
|-------|-----------|---------------|-----------------|-------------|--------|
| **QLD** | 9/9 ✅ | Via MEDICAL_DECISION_MAKER ✅ | ✅ | Dual type limitation ⚠️ | #5, #6, #10 |
| **NSW** | 9/9 ✅ | Unknown for guardians ⚠️ | ✅ | ✅ | #5, #6, #9 |
| **VIC** | 16/16 ✅ | MEDICAL_DECISION_MAKER ✅ | Terms + specific lost ❌ | ✅ | #3, #5, #6, #11, #13 |
| **SA** | 8/8 ✅ | ATTORNEY_DONEE / SECOND_DONOR ✅ | ❌ Missing | N/A | #4, #5 |
| **WA** | 12/12 ✅ | Via _saveWaAttorneys ✅ | ✅ | N/A | #5, #7 |
| **TAS** | 8/8 ✅ | May not save ⚠️ | ✅ | N/A | #5, #7, #8 |
| **NT** | 9/10 ⚠️ | FINANCIAL_DECISION_MAKER ✅ | ✅ | N/A | #2, #5, BUG-2 |
| **ACT** | 23/30 ⚠️ | APPOINTED_ATTORNEY ✅ | ✅ | N/A | #1, #5, BUG-1 |

---

## 5. Priority Action Items

### P0 — Critical (Breaks edit flow / data loss)
1. **Backend:** Fix ACT inline attorney fields not persisting (BUG-1)
2. **Flutter:** Fix VIC "Terms and limits" data loss — map to `conditions_limitations` (#11) **NEW**
3. **Flutter:** Fix VIC "Specific matters" text data loss — store in existing field (#13) **NEW**
4. **Flutter:** Fix duplicate attorneys on re-save — ACT (#1), NT (#2), VIC (#3)
5. **Flutter:** Fix SA donee/second donor prefill (#4)

### P1 — Important (Data integrity)
6. **Backend:** Fix NT `number_of_decision_makers` not persisting (BUG-2)
7. **Flutter:** Fix notification always-fire for non-notification states (#5)
8. **Flutter:** Verify TAS attorney save path (#8)
9. **Flutter:** Verify NSW guardian/substitute save path (#9)

### P2 — Improvement (Cleanup / edge cases)
10. **Flutter:** Conditionally include VIC-only fields in universal payload (#6)
11. **Flutter:** Fix WA/TAS date cross-contamination (#7)
12. **Flutter:** Handle QLD dual notification (#10)
13. **Flutter:** Remove `has_terms_instructions`/`terms_instructions`/`specific_matters` from payload (dead fields)

### PENDING (Backend deploy required)
14. **Flutter:** Update `matters` mapping for new `PERSONAL AND FINANCE` combined enum (#12) — not deployed yet, still 422

---

## 6. Endpoint Summary

| Endpoint | Method | Used By | Status |
|----------|--------|---------|--------|
| `/user/power-of-attorney` | POST | All 8 states | ✅ Working |
| `/user/power-of-attorney` | GET | All 8 states | ✅ Working (with gaps noted above) |
| `/user/attorney-for-poa` | POST | QLD, SA, WA, NT, VIC, ACT | ✅ Working |
| `/user/attorneys-for-poa` | GET | All states on edit | ✅ Working |
| `/user/poa-notification` | POST | QLD (intended), all states (bug) | ✅ Working |
| `/user/poa-notification` | GET | QLD on edit | ✅ Working |

---

## 7. Payload Architecture Reference

| State | Payload Builder | Attorney Types Used |
|-------|----------------|-------------------|
| QLD | `_buildUniversalPayload()` | MEDICAL_DECISION_MAKER |
| NSW | `_buildUniversalPayload()` | (guardians/substitutes — needs verification) |
| VIC | `_buildUniversalPayload()` | MEDICAL_DECISION_MAKER |
| SA | `_buildSaPayload()` | SECOND_DONOR, ATTORNEY_DONEE |
| WA | `_buildWaPayload()` | (via `_saveWaAttorneys`) |
| TAS | `_buildTasPayload()` | (needs verification) |
| NT | `_buildNtPayload()` | FINANCIAL_DECISION_MAKER_PRIMARY/SECONDARY/TERTIARY |
| ACT | `_buildActPayload()` | APPOINTED_ATTORNEY |
