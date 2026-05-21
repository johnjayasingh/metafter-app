import '../../features/poa/data/models/poa_models.dart';

/// Mock POA flow data for all Australian states.
/// Used in local environment to pre-fill forms for rapid testing.
///
/// Every field read by every step screen is covered here.
class MockPoaData {
  MockPoaData._();

  /// Returns a fully-populated PoaFlowData for the given [state].
  /// Falls back to NSW if the state is unrecognised.
  static PoaFlowData forState(String state) {
    switch (state.toUpperCase()) {
      case 'VICTORIA':
        return _victoria;
      case 'NEW_SOUTH_WALES':
        return _nsw;
      case 'WESTERN_AUSTRALIA':
        return _wa;
      case 'SOUTH_AUSTRALIA':
        return _sa;
      case 'NORTHERN_TERRITORY':
        return _nt;
      case 'TASMANIA':
        return _tas;
      case 'AUSTRALIAN_CAPITAL_TERRITORY':
        return _act;
      case 'QUEENSLAND':
        return _qld;
      default:
        return _nsw;
    }
  }

  // ── Shared personal details ───────────────────────────────────────────────

  static const _base = PoaFlowData(
    firstName: 'John',
    middleName: 'Michael',
    lastName: 'Doe',
    phone: '+61412345678',
    dob: '1985-06-15',
    addressLine1: '42 Wallaby Way',
    suburb: 'Sydney',
    postcode: '2000',
    country: 'Australia',
  );

  // ── Helper attorneys ──────────────────────────────────────────────────────

  static const _primaryAttorney = PoaPersonData(
    id: 'mock-poa-att-1',
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane.doe@example.com',
    phone: '+61412000001',
    address: '10 Smith St, Sydney NSW 2000',
    role: 'Attorney',
    attorneyType: AttorneyType.PRIMARY,
  );

  static const _successiveAttorney = PoaPersonData(
    id: 'mock-poa-succ-1',
    firstName: 'Emily',
    lastName: 'Doe',
    email: 'emily.doe@example.com',
    phone: '+61412000002',
    address: '20 King St, Melbourne VIC 3000',
    role: 'Successive Attorney',
    attorneyType: AttorneyType.SUCCESSIVE,
  );

  static const _enduringGuardian = PoaPersonData(
    id: 'mock-poa-eg-1',
    firstName: 'David',
    lastName: 'Doe',
    email: 'david.doe@example.com',
    phone: '+61412000003',
    address: '30 Queen St, Brisbane QLD 4000',
    role: 'Enduring Guardian',
    attorneyType: AttorneyType.ENDURING_GUARDIAN,
  );

  static const _substituteEnduringGuardian = PoaPersonData(
    id: 'mock-poa-seg-1',
    firstName: 'Sarah',
    lastName: 'Doe',
    email: 'sarah.doe@example.com',
    phone: '+61412000004',
    address: '40 Elizabeth St, Adelaide SA 5000',
    role: 'Substitute Enduring Guardian',
    attorneyType: AttorneyType.SUBSTITUTE_ENDURING_GUARDIAN,
  );

  static const _benefitsPerson = PoaPersonData(
    id: 'mock-poa-ben-1',
    firstName: 'Robert',
    lastName: 'Doe',
    email: 'robert.doe@example.com',
    phone: '+61412000005',
    address: '50 George St, Perth WA 6000',
    role: 'Benefits Person',
    attorneyType: AttorneyType.ADDITIONAL_AUTHORITY,
  );

  // ── NSW ────────────────────────────────────────────────────────────────────
  // Step 2: commencementType, commencementOther, hasViewsWishes, viewsWishes,
  //         hasConditionsLimitations, conditionsLimitations, ciConflict/Gifts/etc,
  //         selectedAdditionalPower, benefitsPersons, egCanDecide*, egHasDirections

  static final _nsw = _base.copyWith(
    state: 'NEW_SOUTH_WALES',
    matters: ['PERSONAL', 'FINANCE'],
    attorneys: [_primaryAttorney],
    successiveAttorneys: [_successiveAttorney],
    enduringGuardians: [_enduringGuardian],
    substituteEnduringGuardians: [_substituteEnduringGuardian],
    // OTHER reveals the commencementOther text field
    commencementType: 'OTHER',
    commencementOther:
        'When I am no longer able to manage my own financial affairs.',
    hasViewsWishes: true,
    viewsWishes:
        'I trust my attorney to act in my best interest. Please consult with my GP.',
    hasConditionsLimitations: true,
    conditionsLimitations:
        'My attorney may not sell my primary residence without court approval.',
    ciConflictTransactions:
        'No transactions that benefit my attorney personally.',
    ciGifts: 'Gifts up to \$500 per person per occasion are acceptable.',
    ciDependentMaintenance:
        'Continue supporting my dependent children\'s education expenses.',
    ciPaymentToAttorney: 'Reasonable expenses only, no salary.',
    ciAdditionalCondition:
        'Consult with my accountant for any transaction over \$5,000.',
    selectedAdditionalPower: 'REASONABLE_GIFTS',
    benefitsPersons: [_benefitsPerson],
    // Enduring guardian functions
    egCanDecideLivingPlace: true,
    egCanDecideHealthcare: true,
    egHealthcareDetail:
        'My guardian may make all healthcare decisions on my behalf.',
    egCanDecideOtherPersonalService: true,
    egOtherPersonalService: 'Daily care and personal hygiene support.',
    egCanConsentMedicalAndDental: true,
    egMedicalDetail: 'All standard medical and dental procedures.',
    egOtherDetail: 'Physiotherapy and rehabilitation services.',
    egHasDirections: true,
    egDirectionsDetail:
        'Please consult with family before any major medical decisions.',
    // Notification — OTHER reveals the notifyWhatOtherText text field
    notifyWho: 'NOMINATED_PERSON',
    notifyWhatOption: 'OTHER',
    notifyWhatOtherText:
        'Notify my attorney by phone call within 24 hours of any decision.',
    notifyInstructions: 'Please contact my GP as well.',
    notifyPersons: [_primaryAttorney],
    needsSigningAssistance: false,
  );

  // ── VIC ────────────────────────────────────────────────────────────────────
  // Step 2: matters, specificMatters, attorneys, successiveAttorneys,
  //         hasTermsInstructions, termsInstructions, hasRevocation, revocationDetails,
  //         commencementType, ciConflict/Gifts/etc, needsSigningAssistance,
  //         hasLimitations, limitationsDetails

  static final _victoria = _base.copyWith(
    state: 'VICTORIA',
    matters: ['PERSONAL', 'FINANCE'],
    specificMatters: '',
    attorneys: [_primaryAttorney],
    successiveAttorneys: [_successiveAttorney],
    commencementType: 'IMMEDIATELY',
    hasTermsInstructions: true,
    termsInstructions:
        'Always act in my best interest and consult my family where possible.',
    hasRevocation: false,
    revocationDetails: '',
    ciConflictTransactions:
        'My attorney may not enter into transactions that could benefit them personally.',
    ciGifts: 'Gifts up to \$500 per person per occasion are acceptable.',
    ciDependentMaintenance:
        'Continue supporting my dependent children\'s education expenses.',
    ciPaymentToAttorney: 'Reasonable expenses only, no salary.',
    ciAdditionalCondition: '',
    hasLimitations: true,
    limitationsDetails:
        'My attorney cannot sell my primary residence or make gifts exceeding \$1,000.',
    hasMedicalDecisionMaker: true,
    medicalDecisionMakerDetails:
        'Jane Doe is my medical treatment decision maker.',
    // Notification — OTHER reveals the notifyWhatOtherText text field
    notifyWho: 'NOMINATED_PERSON',
    notifyWhatOption: 'OTHER',
    notifyWhatOtherText:
        'Notify my spouse by phone within 24 hours of any major decision.',
    notifyPersons: [_primaryAttorney],
    needsSigningAssistance: false,
  );

  // ── QLD ────────────────────────────────────────────────────────────────────
  // Step 2: matters, attorneys, successiveAttorneys, enduringGuardians,
  //         substituteEnduringGuardians, commencementType, commencementOther,
  //         hasPreference, preferences, directions, hasTermsInstructions,
  //         termsInstructions

  static final _qld = _base.copyWith(
    state: 'QUEENSLAND',
    matters: ['PERSONAL', 'FINANCE'],
    attorneys: [_primaryAttorney],
    successiveAttorneys: [_successiveAttorney],
    enduringGuardians: [_enduringGuardian],
    substituteEnduringGuardians: [_substituteEnduringGuardian],
    // OTHER reveals the commencementOther text field
    commencementType: 'OTHER',
    commencementOther:
        'When certified by my GP that I lack capacity to manage my affairs.',
    hasPreference: 'yes',
    preferences: 'Conservative investment approach. No property sales.',
    hasAttorneyInstruction: 'yes',
    directions:
        'Always consult with my accountant before making financial decisions over \$10,000.',
    hasTermsInstructions: true,
    termsInstructions:
        'Act jointly on all matters. Consult my GP for health decisions.',
    // Notification — OTHER reveals the notifyWhatOtherText text field
    notifyWho: 'NOMINATED_PERSON',
    notifyWhatOption: 'OTHER',
    notifyWhatOtherText:
        'Notify by email within 48 hours of any financial decision over \$5,000.',
    notifyInstructions: 'Keep records of all notifications sent.',
    notifyPersons: [_primaryAttorney],
    needsSigningAssistance: false,
  );

  // ── WA ─────────────────────────────────────────────────────────────────────
  // Step 2: waEpaDate, waFullLegalName, waResidentialAddress, waEmail
  // Step 3: waAttorneyAppointmentType, waAttorneys
  // Step 4: waHasSubstitute, waSubstituteAppointmentType, waSubstitutes,
  //         waSubstituteActsFor, waSubstituteWhenToAct
  // Step 5: waHasConditions, waConditions
  // Step 6: commencementType

  static final _wa = _base.copyWith(
    state: 'WESTERN_AUSTRALIA',
    matters: ['FINANCE'],
    // Step 2
    waEpaDate: '2026-03-26',
    waFullLegalName: 'John Michael Doe',
    waResidentialAddress: '42 Wallaby Way, Sydney NSW 2000',
    waEmail: 'john.doe@example.com',
    // Step 3
    waAttorneyAppointmentType: 'SOLE',
    waAttorneys: [
      WaPersonEntry(
        name: 'Jane Doe',
        address: '10 Smith St, Sydney NSW 2000',
        email: 'jane.doe@example.com',
      ),
    ],
    // Step 4
    waHasSubstitute: true,
    waSubstituteAppointmentType: 'SOLE',
    waSubstitutes: [
      WaPersonEntry(
        name: 'Emily Doe',
        address: '20 King St, Melbourne VIC 3000',
        email: 'emily.doe@example.com',
      ),
    ],
    waSubstituteActsFor: 'ATTORNEY_1',
    waSubstituteWhenToAct:
        'When my primary attorney is unable or unwilling to act.',
    // Step 5
    waHasConditions: true,
    waConditions:
        'Attorney must not sell the family home without consulting all children.',
    // Step 6
    commencementType: 'IMMEDIATELY',
    needsSigningAssistance: false,
  );

  // ── SA ─────────────────────────────────────────────────────────────────────
  // Step 2: saDonorFullName, saDonorAddress, saDonorEmail, saHasSecondDonor,
  //         saSecondDonor*
  // Step 3: doneeName, doneeAddress, doneeEmail, doneeActingMethod
  // Step 4: saCommencementType
  // Step 5: hasConditionsLimitations, conditionsLimitations

  static final _sa = _base.copyWith(
    state: 'SOUTH_AUSTRALIA',
    matters: ['PERSONAL', 'FINANCE'],
    // Step 2
    saDonorFullName: 'John Michael Doe',
    saDonorAddress: '42 Wallaby Way, Sydney NSW 2000',
    saDonorEmail: 'john.doe@example.com',
    // true reveals second donor name/address/email fields
    saHasSecondDonor: true,
    saSecondDonorFullName: 'Emily Jane Doe',
    saSecondDonorAddress: '20 King St, Adelaide SA 5000',
    saSecondDonorEmail: 'emily.doe@example.com',
    // Step 3
    doneeName: 'Jane Doe',
    doneeAddress: '10 Smith St, Sydney NSW 2000',
    doneeEmail: 'jane.doe@example.com',
    doneeActingMethod: 'JOINTLY_SEVERALLY',
    // Step 4
    saCommencementType: 'IMMEDIATELY',
    // Step 5
    hasConditionsLimitations: true,
    conditionsLimitations:
        'My donee must not sell my primary residence without my family\'s agreement.',
    needsSigningAssistance: false,
  );

  // ── NT ─────────────────────────────────────────────────────────────────────
  // Step 2: ntIsOver18, ntUnderstandsEpa
  // Step 3: ntDonorFullName, ntDonorAddress, ntDonorDob
  // Step 4: ntFinancialDmCount, ntFinancialDms, ntFinancialDmActingMethod,
  //         ntFinancialLimits
  // Step 5: ntOwnsLand, ntDmCanDealLand

  static final _nt = _base.copyWith(
    state: 'NORTHERN_TERRITORY',
    matters: ['FINANCE'],
    // Step 2
    ntIsOver18: true,
    ntUnderstandsEpa: true,
    // Step 3
    ntDonorFullName: 'John Michael Doe',
    ntDonorAddress: '42 Wallaby Way, Sydney NSW 2000',
    ntDonorDob: '1985-06-15',
    // Step 4
    ntFinancialDmCount: 1,
    ntFinancialDms: [
      NtDecisionMakerEntry(
        name: 'Jane Doe',
        address: '10 Smith St, Sydney NSW 2000',
      ),
    ],
    ntFinancialDmActingMethod: 'SEVERALLY',
    ntFinancialLimits:
        'No investments exceeding \$50,000 without family consultation.',
    // Step 5
    ntOwnsLand: true,
    ntDmCanDealLand: true,
    needsSigningAssistance: false,
  );

  // ── TAS ────────────────────────────────────────────────────────────────────
  // Step 2: tasIsAdult, tasUnderstandsEpa
  // Step 3: tasCompletionDate, tasDonorFullName, tasDonorAddress, tasDonorEmail
  // Step 4: attorneys (reuses generic list), tasHowAttorneysAct
  // Step 5: hasConditionsLimitations, conditionsLimitations

  static final _tas = _base.copyWith(
    state: 'TASMANIA',
    matters: ['PERSONAL', 'FINANCE'],
    // Step 2
    tasIsAdult: true,
    tasUnderstandsEpa: true,
    // Step 3
    tasCompletionDate: '2026-03-26',
    tasDonorFullName: 'John Michael Doe',
    tasDonorAddress: '42 Wallaby Way, Sydney NSW 2000',
    tasDonorEmail: 'john.doe@example.com',
    // Step 4
    attorneys: [_primaryAttorney],
    tasAttorneyCount: 1,
    tasAttorneys: [
      TasAttorneyEntry(
        name: 'Jane Doe',
        address: '10 Smith St, Sydney NSW 2000',
        email: 'jane.doe@example.com',
      ),
    ],
    tasHowAttorneysAct: 'JOINTLY_SEVERALLY',
    // Step 5
    hasConditionsLimitations: true,
    conditionsLimitations:
        'Maintain my current standard of living and support my family.',
    needsSigningAssistance: false,
  );

  // ── ACT ────────────────────────────────────────────────────────────────────
  // Step 2: actIsOver18, actUnderstandsEpa, actPrincipalFullName/Address/Email
  // Step 3: actAttorneyCount, actAttorneys, actHowAttorneysAct, actDelegationType,
  //         actDelegationDescription, actMatters
  // Step 4: actDirectionsProperty/PersonalCare/HealthCare/MedicalResearch,
  //         actMedicalTreatmentRefusal, actSpecificTreatments,
  //         actPropertyCommencement, actCommencementCircumstance,
  //         actPriorEpa, actPriorEpaContinueWhich/Date/AttorneyName
  // Step 5: actSigningSelf, actDirectedSignerName/Address

  static final _act = _base.copyWith(
    state: 'AUSTRALIAN_CAPITAL_TERRITORY',
    matters: ['PERSONAL', 'FINANCE'],
    // Step 2
    actIsOver18: true,
    actUnderstandsEpa: true,
    actPrincipalFullName: 'John Michael Doe',
    actPrincipalAddress: '42 Wallaby Way, Sydney NSW 2000',
    actPrincipalEmail: 'john.doe@example.com',
    // Step 3
    actAttorneyCount: 1,
    actAttorneys: [
      ActAttorneyEntry(
        firstName: 'Jane',
        lastName: 'Doe',
        address: '10 Smith St, Sydney NSW 2000',
        email: 'jane.doe@example.com',
        phone: '+61412000001',
      ),
    ],
    actHowAttorneysAct: 'JOINTLY_SEVERALLY',
    // SOME_POWERS reveals the actDelegationDescription text field
    actDelegationType: 'SOME_POWERS',
    actDelegationDescription:
        'Property and financial matters only, excluding health care decisions.',
    actMatters: ['PROPERTY', 'PERSONAL_CARE', 'HEALTH_CARE'],
    // Step 4
    actDirectionsProperty:
        'Manage my property conservatively. No high-risk investments.',
    actDirectionsPersonalCare:
        'Ensure I receive appropriate personal care and support.',
    actDirectionsHealthCare:
        'Consult my GP before making major health decisions.',
    actDirectionsMedicalResearch: '',
    // ALLOWED_SPECIFIC reveals the actSpecificTreatments text field
    actMedicalTreatmentRefusal: 'ALLOWED_SPECIFIC',
    actSpecificTreatments:
        'I refuse blood transfusions and experimental treatments.',
    actPropertyCommencement: 'IMMEDIATELY',
    actCommencementCircumstance: '',
    // SOME_CONTINUE reveals continueWhich text field + date/attorney fields
    actPriorEpa: 'SOME_CONTINUE',
    actPriorEpaContinueWhich:
        'EPA dated 2020-01-15 with Jane Doe as attorney for financial matters.',
    actPriorEpaDate: '2020-01-15',
    actPriorEpaAttorneyName: 'Jane Doe',
    // Step 5
    actSigningSelf: true,
    actDirectedSignerName: '',
    actDirectedSignerAddress: '',
    needsSigningAssistance: false,
  );
}
