import '../../features/ahd/data/models/ahd_models.dart';

/// Mock AHD flow data for all Australian states.
/// Used in local environment to pre-fill forms for rapid testing.
///
/// Every field read by every step screen is covered here.
class MockAhdData {
  MockAhdData._();

  /// Returns a fully-populated AhdFlowData for the given [state].
  /// Falls back to QLD if the state is unrecognised.
  static AhdFlowData forState(String state) {
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
      default:
        return _qld;
    }
  }

  // ── Shared personal details ───────────────────────────────────────────────

  static const _base = AhdFlowData(
    fullName: 'John Michael Doe',
    dob: '1985-06-15',
    addressLine1: '42 Wallaby Way',
    suburb: 'Sydney',
    postcode: '2000',
    phone: '+61412345678',
    email: 'john.doe@example.com',
  );

  // ── QLD ────────────────────────────────────────────────────────────────────
  // Steps: 2(health), 3(values), 4(life-sustaining directive),
  //        5(treatment details), 6(other healthcare + blood),
  //        7(doctor), 8(attorneys), 9(declaration)

  static final _qld = _base.copyWith(
    state: 'QUEENSLAND',
    // Step 2
    healthConditions:
        'I have mild asthma controlled with an inhaler. No other significant medical history.',
    // Step 3
    thingsImportant:
        'Spending time with my family. Maintaining dignity and comfort.',
    culturalValues:
        'I value my Christian faith and would like pastoral care if available.',
    nearingDeathComfort:
        'I would like to be at home surrounded by family if possible.',
    peopleNotInvolved: 'No specific exclusions.',
    // Step 4 — SPECIFIC_DIRECTION reveals the details text field
    lifeSustainingDirective: 'SPECIFIC_DIRECTION',
    lifeSustainingDirectiveDetails:
        'I consent to life-sustaining treatment only while recovery is possible.',
    // CIRCUMSTANCE reveals the details text field
    lifeSustainingTreatment: 'CIRCUMSTANCE',
    lifeSustainingTreatmentDetails:
        'Continue treatment while there is reasonable hope of recovery.',
    // Step 5 — CIRCUMSTANCE reveals the details text field for each
    assistedVentilation: 'CIRCUMSTANCE',
    assistedVentilationDetails: 'Short-term ventilation only, not long-term.',
    artificialNutrition: 'CIRCUMSTANCE',
    artificialNutritionDetails: 'Only if needed for short-term recovery.',
    artificialHydration: 'CONSENT',
    artificialHydrationDetails: '',
    antibiotics: 'CONSENT',
    antibioticsDetails: '',
    otherTreatment: 'CIRCUMSTANCE',
    otherTreatmentDetails: 'Consult my family before any experimental treatment.',
    // Step 6 — OTHER reveals the bloodTransfusionOther text field
    otherHealthCareDirections: [
      HealthCareDirection(
        healthCondition: 'If I develop dementia',
        directions: 'Keep me comfortable and manage pain. Do not resuscitate.',
      ),
    ],
    bloodTransfusionChoice: 'OTHER',
    bloodTransfusionOther:
        'I prefer alternatives to blood transfusion where available.',
    // Step 7
    doctorName: 'Dr Sarah Williams',
    facilityName: 'Brisbane General Practice',
    doctorPhone: '+61733334444',
    doctorDob: '1970-03-20',
    doctorAddress: '100 Medical Drive',
    doctorSuburb: 'Brisbane',
    doctorPostcode: '4000',
    doctorState: 'QUEENSLAND',
    // Step 8
    healthAttorneys: [
      AhdAttorneyData(
        id: 'mock-att-1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane.doe@example.com',
        phone: '+61412000001',
        relation: 'SPOUSE',
      ),
    ],
    // Step 8 — OTHER reveals the attorneyDecisionOther text field
    attorneyDecisionMethod: 'OTHER',
    attorneyDecisionOther:
        'First attorney decides health matters; second attorney decides financial matters.',
    // Step 9
    declarationDetails:
        'I, John Michael Doe, declare that I have made this advance health directive voluntarily and understand its contents.',
  );

  // ── VIC ────────────────────────────────────────────────────────────────────
  // Steps: 2(health), 3(values directive), 4(instructional directive),
  //        5(witnessing), 6(interpreter)

  static final _victoria = _base.copyWith(
    state: 'VICTORIA',
    // Step 2
    healthConditions:
        'Controlled Type 2 diabetes. Currently managed with medication.',
    // Step 3
    thingsImportant: 'Living independently and staying active.',
    thingsWorry: 'Losing the ability to communicate with my family.',
    vicUnacceptableOutcomes:
        'Permanent vegetative state or total dependency on life support.',
    vicOtherThingsKnown:
        'I have discussed my wishes with my spouse and children.',
    vicPeopleInvolved:
        'My spouse Jane and daughter Emily should be consulted.',
    nearingDeathComfort: 'Palliative care with family present.',
    vicOrganDonation: 'CONSENT',
    // Life-sustaining directive — raw API values (VIC screen maps to UI values)
    // SPECIFIC_DIRECTION → VIC shows as ENTER_DETAILS, reveals details text field
    lifeSustainingDirective: 'SPECIFIC_DIRECTION',
    lifeSustainingDirectiveDetails:
        'I consent to life-sustaining treatment only while recovery is reasonably expected.',
    // CIRCUMSTANCE → VIC shows as CONSENT_CIRCUMSTANCES, reveals detail text fields
    lifeSustainingTreatment: 'CIRCUMSTANCE',
    lifeSustainingTreatmentDetails:
        'Continue treatment while there is reasonable hope of recovery.',
    assistedVentilation: 'CIRCUMSTANCE',
    assistedVentilationDetails: 'Short-term ventilation only.',
    artificialNutrition: 'CIRCUMSTANCE',
    artificialNutritionDetails: 'Only if needed for short-term recovery.',
    artificialHydration: 'CONSENT',
    artificialHydrationDetails: '',
    antibiotics: 'CONSENT',
    antibioticsDetails: '',
    otherTreatment: 'CIRCUMSTANCE',
    otherTreatmentDetails:
        'Consult my family before any experimental treatment.',
    // Step 4
    vicConsentTreatment:
        'I consent to palliative care and pain management treatment.',
    vicRefuseTreatment:
        'I refuse long-term mechanical ventilation if recovery is unlikely.',
    // Step 5
    vicWitness1FullName: 'Dr Robert Chen',
    vicWitness1Qualification: 'Medical Practitioner',
    vicWitness2FullName: 'Patricia Smith',
    // Step 6
    vicInterpreterName: 'Maria Garcia',
    vicInterpreterNaati: 'NAATI-12345',
    vicInterpreterLanguage: 'SPANISH',
  );

  // ── NSW ────────────────────────────────────────────────────────────────────
  // Steps: 2(enduring guardian), 3(personal values about dying),
  //        4(directions about medical care), 5(organ donation),
  //        6(person responsible), 7(authorisation)

  static final _nsw = _base.copyWith(
    state: 'NEW_SOUTH_WALES',
    // Step 2
    nswHasEnduringGuardian: true,
    nswEnduringGuardians: [
      AhdAttorneyData(
        id: 'mock-eg-1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane.doe@example.com',
        phone: '+61412000001',
      ),
    ],
    // Step 3
    nswCannotRecogniseFamily: 'UNBEARABLE',
    nswNoBladderControl: 'BEARABLE',
    nswCannotFeedWashDress: 'UNBEARABLE',
    nswCannotMoveInOutBed: 'UNBEARABLE',
    nswCannotMoveReposition: 'BEARABLE',
    nswCannotEatDrink: 'UNBEARABLE',
    nswEndOfLifeCare: 'BEARABLE',
    // Step 4 — OTHER reveals the nswMedicalTreatmentOther text field
    nswCprChoice: 'DO_NOT_ACCEPT',
    nswMedicalTreatmentType: 'OTHER',
    nswMedicalTreatmentOther:
        'Dialysis and experimental treatments not covered above.',
    // Step 5
    nswDonateOrgans: true,
    nswDiscussedDonation: true,
    nswDonateBody: false,
    nswConsentOrganDonation: true,
    // Step 6
    nswPersonsResponsible: [
      AhdAttorneyData(
        id: 'mock-nsw-pr-1',
        firstName: 'Emily',
        lastName: 'Doe',
        email: 'emily.doe@example.com',
        phone: '+61412000002',
      ),
    ],
    // Step 7
    nswAuthorisation:
        'I authorise this advance care directive to take effect immediately.',
  );

  // ── WA ─────────────────────────────────────────────────────────────────────
  // Steps: 2(health), 3(values & preferences), 4(treatment directives),
  //        5(medical research), 6(people who helped), 7(revocation & auth)

  static final _wa = _base.copyWith(
    state: 'WESTERN_AUSTRALIA',
    // Step 2
    waHealthConditions:
        'Chronic back pain managed with physiotherapy. No other conditions.',
    waTreatmentPreferences:
        'Prefer conservative treatments before surgical options.',
    // Step 3 — OTHER reveals nearingDeathLocationDetails;
    //          NO_PAIN and SURROUNDINGS reveal their detail text fields
    waLivingWellChoices: [
      'FAMILY_FRIENDS',
      'LIVING_INDEPENDENTLY',
      'KEEPING_ACTIVE',
    ],
    waWorries: 'Being unable to care for myself or losing mental clarity.',
    waNearingDeathLocations: ['OTHER'],
    waNearingDeathLocationDetails: 'My family home in Perth, with family present.',
    waComfortChoices: [
      'NO_PAIN',
      'LOVED_ONES',
      'CULTURAL_TRADITIONS',
      'SURROUNDINGS',
    ],
    waComfortPainDetails: 'Maximum pain relief even if it shortens my life.',
    waComfortSurroundingsDetails: 'Quiet room with natural light preferred.',
    // Step 4 — CONSENT_SPECIFIC_TREATMENT reveals life-sustaining details;
    //          CONSENT_CIRCUMSTANCES reveals per-treatment detail text fields
    waLifeSustainingTreatment: 'CONSENT_SPECIFIC_TREATMENT',
    waLifeSustainingDetails: 'Continue all treatment while recovery is possible.',
    waCpr: 'CONSENT_CIRCUMSTANCES',
    waCprDetails: 'Attempt CPR unless I am in a terminal condition.',
    waAssistedVentilation: 'CONSENT_CIRCUMSTANCES',
    waAssistedVentilationDetails: 'Short-term ventilation only, not long-term.',
    waArtificialNutrition: 'CONSENT_CIRCUMSTANCES',
    waArtificialNutritionDetails: 'If needed for short-term recovery.',
    waArtificialHydration: 'CONSENT_ALL',
    waArtificialHydrationDetails: '',
    waAntibiotics: 'CONSENT_ALL',
    waAntibioticsDetails: '',
    waBloodProducts: 'CONSENT_CIRCUMSTANCES',
    waBloodProductsDetails: 'I consent to blood transfusions except Jehovah.',
    waDialysis: 'CONSENT_ALL',
    waDialysisDetails: '',
    // Step 5
    waMrPlacebos: 'IF_URGENT',
    waMrUseEquipment: 'IF_IMPROVE_CONDITION',
    waMrLessPractitioners: 'DONT_CONSENT',
    waMrComparativeAssessment: 'IF_URGENT',
    waMrBloodSamples: 'IF_IMPROVE_CONDITION',
    waMrTissueSample: 'DONT_CONSENT',
    waMrNonIntrusiveTreatment: 'IF_IMPROVE_CONDITION',
    waMrBeingObserved: 'IF_IMPROVE_CONDITION',
    waMrUndertakingSurvey: 'IF_IMPROVE_CONDITION',
    waMrCollectingDisclosing: 'DONT_CONSENT',
    waMrEvaluatingSamples: 'IF_IMPROVE_CONDITION',
    waMrOther: 'DONT_CONSENT',
    // Step 6 — MADE reveals EPG guardian fields;
    //          DID_OBTAIN reveals advisor detail fields
    waInterpreterChoice: 'ENGLISH_FIRST_LANGUAGE',
    waEpgChoice: 'MADE',
    waEpgDate: '2025-06-15',
    waEpgLocation: 'Perth, Western Australia',
    waGuardianFirstName: 'Jane Doe',
    waGuardianPhone: '+61412000001',
    waSubstituteGuardianFirstName: 'Emily Doe',
    waSubstituteGuardianPhone: '+61412000002',
    waOtherSubstituteFirstName: 'Sarah Doe',
    waOtherSubstitutePhone: '+61412000003',
    waMedicalAdviceChoice: 'DID_OBTAIN',
    waMedicalAdvisorFirstName: 'Dr Emma Taylor',
    waMedicalAdvisorPhone: '+61893334444',
    waMedicalAdvisorPractice: 'Perth Medical Centre',
    waLegalAdviceChoice: 'DID_OBTAIN',
    waLegalAdvisorFirstName: 'Michael Roberts',
    waLegalAdvisorPhone: '+61893335555',
    waLegalAdvisorPractice: 'Roberts & Partners Legal',
    // Step 7
    waRevokeAcd: true,
    waAuthorisation:
        'I, John Michael Doe, sign this advance health directive voluntarily.',
  );

  // ── SA ─────────────────────────────────────────────────────────────────────
  // Steps: 2(substitute DMs), 3(DM signatures), 4(conditions),
  //        5(values & wishes), 6(refusal), 7(organ donation),
  //        8(expiry), 9(witnesses), 10(interpreter)

  static final _sa = _base.copyWith(
    state: 'SOUTH_AUSTRALIA',
    // Step 2
    saSubstituteDecisionMakers: [
      AhdAttorneyData(
        id: 'mock-sa-dm-1',
        firstName: 'Emily',
        lastName: 'Doe',
        email: 'emily.doe@example.com',
        phone: '+61412000002',
        address: '15 King William St',
        addressSuburb: 'Adelaide',
        addressPostcode: '5000',
        addressState: 'SOUTH_AUSTRALIA',
      ),
    ],
    // Step 3
    saSubDm1FullName: 'Emily Doe',
    saSubDm1Address: '123 Main St, Adelaide',
    saSubDm1Date: '2026-03-26',
    saSubDm2FullName: '',
    saSubDm2Address: '',
    saSubDm2Date: '',
    // Step 4
    saConditionsOfAppointments:
        'My substitute decision-maker should consult with my GP.',
    // Step 5
    saLivingWell:
        'I value spending time with my grandchildren and gardening.',
    saWhereToLive: 'I prefer to stay in my own home as long as possible.',
    saOtherThingsKnown: 'I am allergic to penicillin and sulfa drugs.',
    saOtherPeopleInvolved:
        'My daughter Emily should be consulted on all decisions.',
    saNearingDeath:
        'I would like to be at home with palliative care support.',
    saHealthcarePreferred:
        'I prefer holistic care approaches alongside medical treatment.',
    // Step 6
    saRefusalHealthCare:
        'I refuse any form of experimental treatment without my prior consent.',
    // Step 7
    saOrganDonationChoice: 'CONSENT',
    // Step 8
    saExpiryDate: '2036-03-26',
    // Step 9
    saWitnessFullName: 'Andrew Mitchell',
    saAuthorisedWitnessFullName: 'Margaret Brown',
    saWitnessCategory: 'JUSTICE_OF_PEACE',
    saAuthorisedWitnessPhone: '+61883332222',
    saExtraExecutionStatement:
        'I confirm this document was signed in my presence.',
    // Step 10
    saInterpreterName: 'Maria Garcia',
    saInterpreterNaati: 'NAATI-67890',
  );

  // ── NT ─────────────────────────────────────────────────────────────────────
  // Steps: 2(advanced care statement), 3(other medical info),
  //        4(consent decisions), 5(decision makers),
  //        6(decision method), 7(signing)

  static final _nt = _base.copyWith(
    state: 'NORTHERN_TERRITORY',
    // Step 2
    ntLifeMeaning:
        'Family, community, and staying connected to country.',
    ntNearingDeathGoals:
        'To be comfortable and surrounded by loved ones.',
    ntUnacceptableOutcomes:
        'Being kept alive indefinitely on machines with no hope of recovery.',
    ntPalliativeCare:
        'Yes, I would like palliative care to manage pain and symptoms.',
    // Step 2 — OTHER reveals the ntWhereToDie text field
    ntWhereToDie: 'I want to be at home on country with my family present.',
    ntWhereToDieChoice: 'OTHER',
    // Step 3
    ntOtherMedicalInfo:
        'I take daily blood pressure medication. No allergies.',
    ntCulturalRequests:
        'Please respect my Indigenous cultural practices and traditions.',
    ntAfterDeath1:
        'I wish to be returned to my homeland for burial.',
    ntAfterDeath2:
        'Please notify the community elders.',
    // Step 4
    ntCprChoice: 'ATTEMPT_CPR',
    ntRefusedTreatments: ['ARTIFICIAL_FEEDING'],
    ntRefusedTreatmentOther: '',
    ntReligiousBeliefs:
        'Traditional cultural beliefs — please consult with family elders.',
    // Step 5
    ntDecisionMakers: [
      AhdAttorneyData(
        id: 'mock-nt-dm-1',
        firstName: 'David',
        lastName: 'Doe',
        email: 'david.doe@example.com',
        phone: '+61412000003',
        matters: 'ALL_MATTERS',
      ),
    ],
    ntAppointedDecisionMakers: [
      AhdAttorneyData(
        id: 'mock-nt-adm-1',
        firstName: 'Sarah',
        lastName: 'Doe',
        email: 'sarah.doe@example.com',
        phone: '+61412000004',
      ),
    ],
    // Step 6 — OTHER reveals the ntDecisionMethodOther text field
    ntDecisionMethod: 'OTHER',
    ntDecisionMethodOther:
        'First decision maker handles health matters; second handles property.',
    // Step 7
    ntSign: 'John Michael Doe',
  );

  // ── TAS ────────────────────────────────────────────────────────────────────
  // Steps: 2(health), 3(views/wishes), 4(treatment refusal),
  //        5(delegated completion), 6(signature), 7(witnesses),
  //        8(interpreter), 9(expiry), 10(revocation), 11(organ donation)

  static final _tas = _base.copyWith(
    state: 'TASMANIA',
    // Step 2
    tasHealthConditions:
        'Mild arthritis and seasonal allergies. No major conditions.',
    // Step 3
    tasViewsWishes:
        'I value comfort, dignity, and being around family. I prefer conservative treatment.',
    // Step 4
    tasMedicalTreatmentRefuse:
        'I refuse prolonged mechanical ventilation if recovery is unlikely.',
    tasMedicalCircumstances:
        'If I am in a persistent vegetative state with no reasonable hope of recovery.',
    // Step 5
    tasDelegatedPersonName: 'Jane Doe',
    tasDelegatedAcdPersonName: 'John Michael Doe',
    tasDelegatedRelationship: 'Spouse',
    // Step 6
    tasSignFullName: 'John Michael Doe',
    tasSignDate: '2026-03-26',
    // Step 7
    tasWitnesses: [
      AhdAttorneyData(
        id: 'mock-tas-w-1',
        firstName: 'Dr Robert',
        lastName: 'Chen',
        email: 'robert.chen@example.com',
        phone: '+61362221111',
        isHealthPractitioner: true,
      ),
    ],
    // Step 8
    tasInterpreterName: 'Maria Garcia',
    tasInterpreterNaati: 'NAATI-11111',
    tasInterpreterLanguage: 'SPANISH',
    // Step 9
    tasExpiryDate: '2036-03-26',
    // Step 10
    tasRevokeAcd: false,
    // Step 11
    tasOrganDonorRegister: true,
    tasBodyBequestProgram: false,
  );

  // ── ACT ────────────────────────────────────────────────────────────────────
  // Steps: 2(treatment refusal + revocation), 3(directed person/certification),
  //        4(witnesses — final)

  static final _act = _base.copyWith(
    state: 'AUSTRALIAN_CAPITAL_TERRITORY',
    // Step 2
    actMedicalTreatmentRefuse:
        'I refuse any treatment that would only prolong the dying process.',
    actRevokePreviousDirections: false,
    // Step 3
    actDirectedPersonName: 'Jane Doe',
    actDirectedPersonAddress: '42 Wallaby Way, Sydney NSW 2000',
    // Step 4
    actWitness1FullName: 'Dr Patricia Wong',
    actWitness1Address: '88 Northbourne Ave, Canberra ACT 2601',
  );
}
