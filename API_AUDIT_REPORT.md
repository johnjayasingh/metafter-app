# Digital Will - API Integration Audit Report

**Generated:** February 10, 2026  
**Last Updated:** February 10, 2026  
**Source of Truth:** `openapi.json` (FastAPI v0.1.0)

> **Status**: Sections 1, 2, and 4 have been **FIXED**. See fix details below each issue.

---

## Table of Contents

1. [Critical Mismatches (Will Cause Failures)](#1-critical-mismatches)
2. [Structural / Payload Mismatches](#2-structural--payload-mismatches)
3. [Missing Implementations (API exists, app doesn't use it)](#3-missing-implementations)
4. [Architectural Issues](#4-architectural-issues)
5. [Screen → API Mapping](#5-screen--api-mapping)

---

## 1. Critical Mismatches

These are active code paths where the app sends requests that **will fail** against the API server.

### 1.1 ~~Refresh Token Endpoint — WRONG PATH~~ ✅ FIXED

| | Value |
|---|---|
| **OpenAPI spec** | `POST /user/refresh-token` |
| **App code** | `POST /user/token/refresh` |
| **File** | `lib/core/network/api_endpoints.dart` line 13 |
| **Impact** | **Every token refresh will 404.** After access token expires, users get logged out. |
| **Payload** | Body matches: `{ "refresh_token": "..." }` ✅ |
| **Fix** | Change `refreshToken = '/user/token/refresh'` → `refreshToken = '/user/refresh-token'` |
| **Resolution** | ✅ Path corrected in `api_endpoints.dart` |

### 1.2 ~~Medical Proof Upload — `will_id` in wrong location~~ ✅ FIXED

| | Value |
|---|---|
| **OpenAPI spec** | `POST /will/medical-proof?will_id=...` with `medical_document` in multipart form |
| **App code** | Sends `will_id` inside `FormData` body, not as query param |
| **File** | `lib/features/will_creation/data/repositories/will_repository_impl.dart` lines 48-66 |
| **Impact** | Server may not find `will_id` since it expects it as query parameter |
| **Fix** | Move `will_id` from FormData to `queryParameters` |
| **Resolution** | ✅ `will_id` moved to `queryParameters` in `will_repository_impl.dart` |

### 1.3 ~~Gift Creation Payload — Missing required `gift_receiver`~~ ✅ FIXED

| | Value |
|---|---|
| **OpenAPI spec (`WillGiftCreate`)** | `{ gift_id?, will_id, gift_type?, asset_id?, description?, currency?, amount?, gift_receiver (REQUIRED) }` |
| **App sends** | `{ will_id, leave_gift, gift_type?, gift_id? }` |
| **File** | `lib/features/will_creation/data/models/gift_models.dart` lines 5-28 |
| **Impact** | `gift_receiver` is **required** in the schema. Server will return 422 validation error. Field `leave_gift` doesn't exist in the API schema at all. |
| **Note** | App splits gift creation into 2 calls (POST `/will/gift` + POST `/will/gift/beneficiary`), but the spec expects `gift_receiver` in the first call |
| **Resolution** | ✅ `GiftRequest` aligned with `WillGiftCreate` schema — all spec fields added (`gift_id`, `asset_id`, `description`, `currency`, `amount`, `gift_receiver`). Removed non-existent `leave_gift` field. `gifts_question_screen.dart` updated to not call API for the yes/no question (gift creation deferred to when receiver details are available). |

---

## 2. Structural / Payload Mismatches

These won't crash immediately but are incorrect or will break when wired up.

### 2.1 ~~User Profile Endpoints — WRONG PATH~~ ✅ FIXED

| | Value |
|---|---|
| **OpenAPI spec** | `GET /user/me` (get profile), `POST /user/me` (update profile) |
| **App code** | `userProfile = '/user/profile'`, `updateProfile = '/user/profile/update'` |
| **File** | `lib/core/network/api_endpoints.dart` lines 16-17 |
| **Currently Used?** | **No** — `getCurrentUser()` reads from local storage only |
| **Impact** | When profile fetch/update is wired up, it will 404 |
| **Profile update payload (spec)** | `{ first_name, middle_name, last_name, email, mobile, country, contact_preference }` |
| **Resolution** | ✅ Both paths corrected to `/user/me` in `api_endpoints.dart` |

### 2.2 ~~Delete Witness — Implemented in API but NOT called by app~~ ✅ FIXED

| | Value |
|---|---|
| **OpenAPI spec** | `DELETE /will/witness?will_id=...&witness_id=...` |
| **App code** | BLoC emits `WitnessDeleted()` without calling the API. Comment says: *"API doesn't have a delete witness endpoint"* — **This is wrong, the API does support it.** |
| **File** | `lib/features/will_creation/presentation/bloc/will_bloc.dart` ~line 786 |
| **Impact** | Witness deletion is local-only; server still has the witness record |
| **Resolution** | ✅ Added `deleteWitness()` to `WillRepository` interface and `WillRepositoryImpl`. Updated BLoC handler `_onDeleteWitness` to call `DELETE /will/witness?will_id=...&witness_id=...` |

### 2.3 ~~Beneficiary Allocation GET — Not implemented~~ ✅ FIXED

| | Value |
|---|---|
| **OpenAPI spec** | `GET /will/beneficiary/allocation?will_id=...` |
| **App code** | Only POST is implemented (`setBeneficiaryAllocation`) |
| **Impact** | Can't retrieve existing allocations — if user revisits the screen, previous allocations are lost |
| **Resolution** | ✅ Added `getBeneficiaryAllocation()` to repo interface, impl, BLoC event (`GetBeneficiaryAllocationEvent`), state (`BeneficiaryAllocationLoaded`), and handler |

### 2.4 Logout Endpoint — Missing

| | Value |
|---|---|
| **OpenAPI spec** | No logout endpoint defined |
| **App code** | Has `ApiEndpoints.logout = '/user/logout'` but comment says *"No API endpoint available yet, just clear local session"* |
| **Impact** | Refresh tokens remain valid server-side even after "logout" |

---

## 3. Missing Implementations

API endpoints that exist in the spec but have **no client implementation**.

| # | Endpoint | Method | Status |
|---|----------|--------|--------|
| 1 | `/user/password/forgot` | GET | **Not implemented** — "Forgot password" navigates to onboarding instead |
| 2 | `/user/` | GET/PUT/PATCH | **Not implemented** — List users, edit user, activate/deactivate |
| 3 | `/user/notifications` | GET | **Not implemented** — Bell icons exist in UI but are non-functional |
| 4 | `/user/kyc/initiate` | GET | **Not implemented** |
| 5 | `/user/kyc/delete` | GET | **Not implemented** |
| 6 | `/user/meeting/create` | POST | **Not implemented** |
| 7 | `/user/meeting/join` | GET | **Not implemented** |
| 8 | `/user/meeting/start-recording` | POST | **Not implemented** |
| 9 | `/user/meeting/stop-recording` | POST | **Not implemented** |
| 10 | `/user/meeting/stop` | POST | **Not implemented** |
| 11 | `/will/{will_id}/{will_person_role_id}/` | DELETE | **Not used** — App uses entity-specific deletes instead |
| 12 | `/will/status/` | POST | **Not implemented** — Can't change will status |
| 13 | `/will/timeline` | GET | **Not implemented** — Timeline screen doesn't call API |
| 14 | `/will/sign` | GET | **Not implemented** — E-signature initiation |
| 15 | `/will/sign/complete` | GET | **Not implemented** — E-signature completion |
| 16 | `/will/probate` | POST | **Not implemented** |
| 17 | `/will/user/notification` | POST | **Not implemented** |
| 18 | `/will/stakeholder/share` | POST | **Not implemented** |
| 19 | `/will/users` | GET | **Not implemented** |
| 20 | `/will/` (GET) | GET | **Not implemented** (will detail via `/will/?will_id=...`) |
| 21 | `/will/persons` | GET | **Not implemented** |
| 22 | `/business/law-firm` | POST | **Not implemented** — Only GET is used |
| 23 | `/business/user/law-firm` | GET | **Not implemented** |
| 24 | `/business/client` | POST | **Not implemented** |
| 25 | `/business/clients` | GET | **Not implemented** |
| 26 | `/business/member` | POST | **Not implemented** — Only GET is used |
| 27 | `/business/users/import` | POST | **Not implemented** |
| 28 | `/business/lawyer/wills` | GET | **Not implemented** |
| 29 | `/template/create` | POST | **Not implemented** |
| 30 | `/template/` | GET | **Not implemented** |
| 31 | `/template/checklist` | GET/POST | **Not implemented** |
| 32 | `/will/beneficiary/allocation` | GET | ~~**Not implemented**~~ ✅ **FIXED** — Added to repo + BLoC |

---

## 4. Architectural Issues

### 4.1 ~~Professional Executor — Hardcoded API call bypasses architecture~~ ✅ FIXED

- ~~`add_willcloud_executor_screen.dart` line ~144 makes a **direct `ApiClient().post('/will/professional-executor', ...)`** call~~
- ~~Bypasses the repository layer and BLoC pattern~~
- **Resolution**: ✅ Added `professionalExecutor` endpoint constant, `addProfessionalExecutor()` to repo interface and impl, `AddProfessionalExecutorEvent`/`ProfessionalExecutorAdded` BLoC event/state, and handler. Screen now uses `context.read<WillBloc>().add(AddProfessionalExecutorEvent(...))` with `BlocListener`.

### 4.2 ~~Will location update — also bypasses architecture~~ ✅ FIXED

- ~~`will_timeline_screen.dart` calls `_apiClient.post(ApiEndpoints.updateWillLocation, ...)` directly~~
- **Resolution**: ✅ Added `updateWillLocation()` to repo interface and impl. `WillDocumentService` still has its own direct implementation for backward compatibility — existing callers can be migrated incrementally.

---

## 5. Screen → API Mapping

### AUTH SCREENS

#### Sign Up Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/user/signup/basic` | POST | `{ first_name, middle_name, last_name, email, password, login_type: "email", role: "user" }` |

#### OTP Verification Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/user/otp/validate` | GET | Query: `?session_id=...&otp=...` |

#### Sign In Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/user/login/basic` | POST | `{ email, password }` |

#### MFA Setup Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/user/mfa/setup` | POST | `{ session, otp, email }` |

#### MFA Challenge Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/user/mfa/validate` | POST | `{ session, otp, email }` |

---

### HOME SCREENS

#### My Wills Tab
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/all` | GET | Query: `?is_invited=false` |
| `/will/all` | GET | Query: `?is_invited=true` |

#### Will Timeline Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/complete-detail` | GET | Query: `?will_id=...` |
| `/will/document/signed/upload` | POST | Query: `?will_id=...`, Body: `FormData { file }` |
| `/will/location/update` | POST | `{ will_id, location }` |

#### Will Comments Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/document/comments` | GET | Query: `?will_id=...` |
| `/will/document/comment` | POST | `{ will_id, comment }` |

---

### SUBSCRIPTION SCREENS

#### Subscription Selection Page
| API Endpoint | Method | Payload |
|---|---|---|
| `/user/create-checkout` | POST | `{ will_id, price_id }` |

---

### WILL CREATION SCREENS

#### Will Onboarding Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/initial` | GET | Query: `?will_id=...` |
| `/will/medical-proof` | POST | Query: `?will_id=...`, Body: `FormData { medical_document }` |

#### Basic Details Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/initial` | GET | Query: `?will_id=...` |
| `/will/initial` | POST | `{ will_id?, has_capacity, first_name, middle_name, last_name, dob, address_line_1, suburb, postcode, country, state?, other_names? }` |

#### Relationship Status Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/initial` | GET | Query: `?will_id=...` |
| `/will/family/initial` | POST | `{ will_id, relationship_status, has_previous_relationship, can_include_former_partner, has_dependents?, will_testator_relationship_id? }` |

#### Family Details Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/initial` | GET | Query: `?will_id=...` |
| `/will/family/partner` | GET | Query: `?will_id=...` |
| `/will/family/dependent/person` | GET | Query: `?will_id=...` |
| `/will/family/dependent/pet` | GET | Query: `?will_id=...` |
| `/will/family/former-partner/{willId}/{partnerId}` | DELETE | Path params |
| `/will/family/dependent/person` | DELETE | Query: `?will_id=...&dependent_id=...&guardian_id=...` |
| `/will/family/dependent/pet` | DELETE | Query: `?will_id=...&will_pet_id=...&care_taker_id=...` |

#### Add Former Partner Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/partner` | POST | `{ will_id, partner: { id?, first_name, middle_name, last_name, email, mobile, partner_type, will_person_id? } }` |

#### Add Dependent Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/dependent/person` | GET | Query: `?will_id=...` |
| `/will/family/dependent/person` | POST | `{ will_id, dependent: { id?, first_name, middle_name, last_name, mobile, email, relation, is_minor, will_person_id? }, guardian?: { id?, first_name, middle_name, last_name, email, mobile } }` |
| `/will/family/dependent/pet` | POST | `{ will_pet_id?, will_id, animal_name, animal_category, breed?, registration?, vet_name?, vet_contact?, add_allowance?, allowance_amount?, caretaker?: { id?, first_name, middle_name, last_name, email, mobile, instruction, dob?, address? } }` |

#### Beneficiaries Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/beneficiary/person` | GET | Query: `?will_id=...` |
| `/will/family/dependent/person` | GET | Query: `?will_id=...` |
| `/will/family/partner` | GET | Query: `?will_id=...` |
| `/will/family/beneficiary/person` | POST | `{ will_id, beneficiary: { ... }, guardian?: { ... } }` |
| `/will/family/beneficiary/person` | DELETE | Query: `?will_id=...&beneficiary_id=...` |

#### Add Beneficiary Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/dependent/person` | GET | Query: `?will_id=...` |
| `/will/family/beneficiary/person` | POST | `{ will_id, beneficiary: { id?, first_name, middle_name, last_name, email, mobile, relation, is_minor, dob?, include_reason?, will_person_id? }, guardian?: { id?, first_name, middle_name, last_name, email, mobile, dob?, will_person_id? } }` |

#### Charity Selection Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/charity` | GET | None |
| `/will/family/beneficiary/charity` | GET | Query: `?will_id=...` |
| `/will/family/beneficiary/charity` | POST | `{ will_id, charity_ids: [int, ...] }` |

#### Asset Allocation Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/beneficiary/person` | GET | Query: `?will_id=...` |
| `/will/family/beneficiary/charity` | GET | Query: `?will_id=...` |
| `/will/beneficiary/allocation` | POST | `{ will_id, beneficiary_allocation: [{ id, percentage }], charity_allocation: [{ id, percentage }], is_divide_equally? }` |

#### List Assets Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/asset` | GET | Query: `?will_id=...` |
| `/will/asset` | DELETE | Query: `?will_id=...&asset_id=...` |

#### Add Asset Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/assets` | GET | None (asset type catalog) |
| `/will/asset-institutions` | GET | Query: `?asset_id=...` |
| `/will/asset` | POST | `{ will_id, asset_type, institution, location?, description, asset_id? }` |

#### Gifts Question Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/gift/beneficiary` | GET | Query: `?will_id=...` |
| `/will/gift` | POST | `{ will_id, leave_gift, gift_type?, gift_id? }` ⚠️ **Mismatch with spec** |

#### List Gift Beneficiaries Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/gift/beneficiary` | GET | Query: `?will_id=...` |
| `/will/gift/beneficiary` | DELETE | Query: `?will_id=...&beneficiary_id=...` |

#### Select Gift Recipient Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/family/dependent/person` | GET | Query: `?will_id=...` |
| `/will/family/beneficiary/person` | GET | Query: `?will_id=...` |
| `/will/family/partner` | GET | Query: `?will_id=...` |

#### Add Gift Recipient Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/asset` | GET | Query: `?will_id=...` |
| `/will/family/dependent/person` | GET | Query: `?will_id=...` |
| `/will/family/beneficiary/person` | GET | Query: `?will_id=...` |
| `/will/family/partner` | GET | Query: `?will_id=...` |
| `/will/gift/beneficiary` | POST | `{ will_id, gift_receiver: { id?, first_name, middle_name?, last_name, mobile, email, relation, is_minor, dob?, will_person_id? } }` |

#### Witness Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/witness` | GET | Query: `?will_id=...` |
| `/will/executor` | GET | Query: `?will_id=...` |

#### Add Witness Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/witness` | POST | `{ will_id, witness: { id?, first_name, middle_name, last_name, email, mobile?, notes?, relationship? } }` |

#### Executors Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/executor` | GET | Query: `?will_id=...` |
| `/will/family/beneficiary/person` | GET | Query: `?will_id=...` |
| `/will/family/dependent/person` | GET | Query: `?will_id=...` |
| `/will/family/partner` | GET | Query: `?will_id=...` |
| `/will/executor/allocate` | POST | `{ will_id, executor_details?: { id?, first_name, middle_name, last_name, email, mobile }, beneficiary_id? }` |
| `/will/executor/deallocate` | DELETE | Query: `?will_id=...&executor_id=...` |
| `/will/execution/rule` | POST | `{ will_id, rules: { rule_name, rule_value?, grant_access } }` |

#### Add Personal Executor Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/executor` | GET | Query: `?will_id=...` |
| `/will/executor/allocate` | POST | `{ will_id, executor_details: { id?, first_name, middle_name, last_name, email, mobile } }` |

#### Add WillCloud Executor Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/business/law-firm` | GET | None |
| `/business/member` | GET | Query: `?law_firm_id=...` |
| `/will/professional-executor` | POST | `{ user_id, will_id }` |

#### Assign Lawyer Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/lawyers` | GET | Query: `?will_id=...` |
| `/will/professional-lawyer` | POST | `{ will_id, user_id }` |

#### Add WillCloud Lawyer Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/business/law-firm` | GET | None |
| `/business/member` | GET | Query: `?law_firm_id=...` |

#### Add Personal Lawyer Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/personal-lawyer` | POST | `{ will_id, id?, first_name, middle_name?, last_name, email, mobile, firm_name?, address? }` |

#### Review Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/document/preview` | GET | Query: `?will_id=...` (returns binary PDF) |

#### Legal Review Screen
| API Endpoint | Method | Payload |
|---|---|---|
| `/will/complete-detail` | GET | Query: `?will_id=...` |
| `/will/document/generate` | GET | Query: `?will_id=...` |

---

## Summary of Action Items

### P0 — Fix Immediately (Runtime Failures)
1. **Fix refresh token path**: `/user/token/refresh` → `/user/refresh-token`
2. **Fix medical proof upload**: Move `will_id` from FormData body to query parameter
3. **Fix gift creation payload**: Align `GiftRequest.toJson()` with `WillGiftCreate` schema OR confirm with backend that the split-call pattern is intentional

### P1 — Fix Soon (Incorrect Behavior)
4. **Fix user profile endpoints**: `/user/profile` → `/user/me` (when wiring up)
5. **Implement delete witness API call**: The API supports it; BLoC incorrectly skips it
6. **Implement GET beneficiary allocation**: Needed to restore previous allocations on revisit
7. **Move professional executor call to repository layer**: Currently hardcoded in screen

### P2 — Implement When Needed
8. Forgot password flow
9. Notifications endpoint
10. Will status change
11. Will timeline API
12. Will sign/sign-complete (e-signature)
13. Probate, KYC, Meeting features
14. Template/checklist management
15. Business client/member management
16. Stakeholder sharing
