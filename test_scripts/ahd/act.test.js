/**
 * AHD Integration Tests — Australian Capital Territory (ACT)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — REFUSE
 *  4. CPR and resuscitation — ATTORNEY_DECISION
 *  5. Organ and body donation
 *  6. Treatment decisions
 *  7. Medical treatment refuse (flat field)
 *  8. AHD persons — SDM + secondary SDM + witness + WITNESS_PERSON + HELPER
 *  9. Declarations and wishes
 * 10. ACD revoked
 * 11. GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/act.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — Australian Capital Territory (ACT)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Multiple sclerosis, stage 2',
        things_important_for_me:                     'Maintaining independence and dignity',
        beliefs_considered_during_health_care:       'Scientific and evidence-based care only',
        nearing_death_preference:                    'Hospice care; no hospital admission',
        people_not_to_involve_healthcare_discussion: 'No one excluded',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'MANAGED_SYMPTOMS', 'SPIRITUAL_CARE'],
      },
    });
    printResult('POST /user/ahd (ACT minimal)', res, 200);
    const d = res.body?.data;
    const ok = d?.health_conditions?.major_health_conditions != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} health_conditions persisted`);
  }

  // ── 2. Life sustaining — CONSENT ─────────────────────────────────────
  printSection('Scenario 2: Life sustaining treatment — CONSENT');
  {
    const res = await request('POST', '/user/ahd', {
      life_sustaining_treatment: {
        direction_type:       'CONSENT',
        direction_instruction: 'I consent to all life-sustaining treatment.',
        assisted_ventilation: 'CONSENT',
        artificial_nutrition: 'CONSENT',
        antibiotics:          'CONSENT',
        blood_transfusion:    'CONSENT',
      },
    });
    printResult('POST /user/ahd (ACT LST CONSENT)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'CONSENT';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
  }

  // ── 3. Life sustaining — REFUSE ──────────────────────────────────────
  printSection('Scenario 3: Life sustaining treatment — REFUSE');
  {
    const res = await request('POST', '/user/ahd', {
      life_sustaining_treatment: {
        direction_type:                   'REFUSE',
        direction_instruction:            'Refuse all intervention beyond pain management.',
        assisted_ventilation:             'REFUSE',
        assisted_ventilation_instruction: 'No intubation.',
        artificial_nutrition:             'REFUSE',
        artificial_nutrition_instruction: 'No enteral feeding.',
        antibiotics:                      'CONSENT',
        blood_transfusion: 'CANT_DECIDE',
        blood_transfusion_instruction:    'Attorney consults clinical team.',
      },
    });
    printResult('POST /user/ahd (ACT LST REFUSE)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'REFUSE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
    console.log(`    \x1b[36m?\x1b[0m blood_transfusion: ${d?.life_sustaining_treatment?.blood_transfusion}`);
  }

  // ── 4. CPR — ATTORNEY_DECISION ────────────────────────────────────────
  printSection('Scenario 4: CPR — ATTORNEY_DECISION');
  {
    const res = await request('POST', '/user/ahd', {
      cpr_and_resuscitation: {
        cpr_instruction: 'UNSURE',
        medical_not_expected_to_recover: 'REJECT_CPR',
        cpr_resuscitation: 'CANT_DECIDE',
        cpr_resuscitation_instruction:   'Discuss with treating medical team.',
        cpr_consent: 'CONDITION',
        cpr_consent_instruction:         'Based on quality-of-life prognosis.',
      },
    });
    printResult('POST /user/ahd (ACT CPR ATTORNEY_DECISION)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNSURE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 5. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 5: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      is_registered_australian_organ_donor: true,
      organ_and_body_donation: {
        donate_organ:           false,
        consent_organ_donation: false,
        donate_body:            true,
        consent_body_donation:  true,
        authorisation:          'Authorise use of body for Canberra medical school.',
      },
    });
    printResult('POST /user/ahd (ACT organ donation)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_and_body_donation?.donate_body === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} donate_body: ${d?.organ_and_body_donation?.donate_body}`);
    console.log(`    \x1b[36m?\x1b[0m donate_organ: ${d?.organ_and_body_donation?.donate_organ}`);
  }

  // ── 6. Treatment decisions ────────────────────────────────────────────
  printSection('Scenario 6: Treatment decisions');
  {
    const res = await request('POST', '/user/ahd', {
      treatment_decisions: {
        life_sustaining_treatment: 'REFUSE_ALL_TREATMENT',
        artificial_hydration:                       'CONSENT',
        artificial_hydration_instruction:           'Slow drip acceptable for comfort.',
        consent_palliative_comfort_care:            'CONSENT',
        specific_treatment_no_consent: 'ARTIFICIAL_FEEDING',
        specific_treatment_no_consent_instruction:  'No experimental drug trials.',
        healthcare_preferred:                       'Calvary Public Hospital preferred.',
      },
    });
    printResult('POST /user/ahd (ACT treatment decisions)', res, 200);
    const d = res.body?.data;
    const ok = d?.treatment_decisions?.life_sustaining_treatment != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} treatment_decisions stored`);
  }

  // ── 7. Medical treatment refuse (flat field) ─────────────────────────
  printSection('Scenario 7: Medical treatment refuse (flat field)');
  {
    const res = await request('POST', '/user/ahd', {
      medical_treatment_refuse: 'I refuse all experimental and invasive treatments.',
    });
    printResult('POST /user/ahd (ACT medical_treatment_refuse)', res, 200);
    const d = res.body?.data;
    const ok = d?.medical_treatment_refuse != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} medical_treatment_refuse: ${d?.medical_treatment_refuse ?? 'MISSING'}`);
  }

  // ── 8. AHD persons ────────────────────────────────────────────────────
  printSection('Scenario 8: AHD persons — SDM + secondary SDM + witness + WITNESS_PERSON + HELPER');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: false,
      ahd_persons: [
        {
          full_name: 'Patricia O\'Brien',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone: '0261234567',
          address: '1 London Circuit, Canberra ACT 2601',
        },
        {
          full_name: 'Robert O\'Brien',
          person_type: 'SUBSTITUTE_DECISION_MAKER_SECONDARY',
          phone: '0262345678',
          address: '1 London Circuit, Canberra ACT 2601',
        },
        {
          full_name: 'Dr. Helen Morris',
          person_type: 'WITNESS_MEDICAL_PRACTITIONER',
          qualification: 'Cardiologist',
          phone: '0263456789',
          address: '4 Bowes Street, Phillip ACT 2606',
        },
        {
          full_name: 'George Mitchell',
          person_type: 'WITNESS_PERSON',
          phone: '0264567890',
          address: '10 Northbourne Avenue, Canberra ACT 2601',
        },
        {
          full_name: 'Anne Mitchell',
          person_type: 'HELPER',
          phone: '0265678901',
          address: '10 Northbourne Avenue, Canberra ACT 2601',
        },
      ],
    });
    printResult('POST /user/ahd (ACT ahd_persons x5)', res, 200);
    const persons = res.body?.data?.ahd_persons ?? [];
    const hasSdm = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    console.log(`    ${hasSdm ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    const hasSecondary = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER_SECONDARY');
    console.log(`    ${hasSecondary ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER_SECONDARY present`);
    const hasWitPerson = Array.isArray(persons) && persons.some((p) => p.person_type === 'WITNESS_PERSON');
    console.log(`    ${hasWitPerson ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} WITNESS_PERSON present`);
    const hasHelper = Array.isArray(persons) && persons.some((p) => p.person_type === 'HELPER');
    console.log(`    ${hasHelper ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} HELPER present`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 9. Declarations and wishes ────────────────────────────────────────
  printSection('Scenario 9: Declarations and wishes');
  {
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I make this directive freely and voluntarily.',
        what_matter_most:                          'Remaining conscious and connected to family.',
        what_worries_most:                         'Pain and loss of dignity.',
        unacceptable_medical_treatment_outcome:    'Prolonged unconscious state with no prognosis.',
        cultural_request:                          'No specific cultural requirements.',
        religious_beliefs:                         'Secular; no religious rites.',
        after_death_importance:                    'Burial at National Memorial.',
        nearing_death_instruction:                 'Keep conversation light; read to me.',
      },
    });
    printResult('POST /user/ahd (ACT declarations)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes persisted`);
  }

  // ── 10. ACD revoked ───────────────────────────────────────────────────
  printSection('Scenario 10: ACD revoked flag');
  {
    const res = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2028-01-01',
    });
    printResult('POST /user/ahd (ACT is_acd_revoked)', res, 200);
    const d = res.body?.data;
    const ok = d?.is_acd_revoked === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_acd_revoked: ${d?.is_acd_revoked}`);
  }

  // ── 11. GET round-trip ─────────────────────────────────────────────────
  printSection('Scenario 11: GET round-trip — stored value assertions');
  {
    const res = await request('GET', '/user/ahd');
    printResult('GET  /user/ahd', res, 200);
    const d = res.body?.data;

    // ── Top-level flags ──────────────────────────────────────────────────
    console.log('    \x1b[1m[Top-level flags]\x1b[0m');
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked ?? 'MISSING'}`);
    const expiryOk = d?.acd_expiry_date === '2028-01-01';
    console.log(`    ${expiryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} acd_expiry_date === '2028-01-01': ${d?.acd_expiry_date ?? 'MISSING'}`);
    const guardianOk = d?.is_enduring_guardian_appointed === false;
    console.log(`    ${guardianOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === false: ${d?.is_enduring_guardian_appointed ?? 'MISSING'}`);
    const organDonorOk = d?.is_registered_australian_organ_donor === true;
    console.log(`    ${organDonorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_registered_australian_organ_donor === true: ${d?.is_registered_australian_organ_donor ?? 'MISSING'}`);

    // ── health_conditions (scenario 1) ───────────────────────────────────
    console.log('    \x1b[1m[health_conditions]\x1b[0m');
    const hc = d?.health_conditions;
    const hc1Ok = hc?.major_health_conditions === 'Multiple sclerosis, stage 2';
    console.log(`    ${hc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} major_health_conditions === 'Multiple sclerosis, stage 2': ${hc?.major_health_conditions ?? 'MISSING'}`);
    const hc2Ok = hc?.things_important_for_me === 'Maintaining independence and dignity';
    console.log(`    ${hc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} things_important_for_me === 'Maintaining independence and dignity': ${hc?.things_important_for_me ?? 'MISSING'}`);
    const hc3Ok = hc?.beliefs_considered_during_health_care === 'Scientific and evidence-based care only';
    console.log(`    ${hc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} beliefs_considered_during_health_care === 'Scientific and evidence-based care only': ${hc?.beliefs_considered_during_health_care ?? 'MISSING'}`);
    const hc4Ok = hc?.nearing_death_preference === 'Hospice care; no hospital admission';
    console.log(`    ${hc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_preference === 'Hospice care; no hospital admission': ${hc?.nearing_death_preference ?? 'MISSING'}`);
    const hc5Ok = hc?.people_not_to_involve_healthcare_discussion === 'No one excluded';
    console.log(`    ${hc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} people_not_to_invoke_healthcare_discussion === 'No one excluded': ${hc?.people_not_to_involve_healthcare_discussion ?? 'MISSING'}`);
    const comfortArr = hc?.comfort_nearing_death;
    const hc6Ok = Array.isArray(comfortArr) && comfortArr.includes('LOVED_ONES_NEARBY');
    console.log(`    ${hc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death includes 'LOVED_ONES_NEARBY': ${JSON.stringify(comfortArr) ?? 'MISSING'}`);
    const hc7Ok = Array.isArray(comfortArr) && comfortArr.length >= 3;
    console.log(`    ${hc7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death length >= 3: ${comfortArr?.length ?? 'MISSING'}`);

    // ── life_sustaining_treatment (scenario 3 overwrites 2) ──────────────
    console.log('    \x1b[1m[life_sustaining_treatment]\x1b[0m');
    const lst = d?.life_sustaining_treatment;
    const lst1Ok = lst?.direction_type === 'REFUSE';
    console.log(`    ${lst1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_type === 'REFUSE': ${lst?.direction_type ?? 'MISSING'}`);
    const lst2Ok = lst?.direction_instruction === 'Refuse all intervention beyond pain management.';
    console.log(`    ${lst2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_instruction === 'Refuse all intervention beyond pain management.': ${lst?.direction_instruction ?? 'MISSING'}`);
    const lst3Ok = lst?.assisted_ventilation === 'REFUSE';
    console.log(`    ${lst3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation === 'REFUSE': ${lst?.assisted_ventilation ?? 'MISSING'}`);
    const lst4Ok = lst?.assisted_ventilation_instruction === 'No intubation.';
    console.log(`    ${lst4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation_instruction === 'No intubation.': ${lst?.assisted_ventilation_instruction ?? 'MISSING'}`);
    const lst5Ok = lst?.artificial_nutrition === 'REFUSE';
    console.log(`    ${lst5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition === 'REFUSE': ${lst?.artificial_nutrition ?? 'MISSING'}`);
    const lst6Ok = lst?.artificial_nutrition_instruction === 'No enteral feeding.';
    console.log(`    ${lst6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition_instruction === 'No enteral feeding.': ${lst?.artificial_nutrition_instruction ?? 'MISSING'}`);
    const lst7Ok = lst?.antibiotics === 'CONSENT';
    console.log(`    ${lst7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} antibiotics === 'CONSENT': ${lst?.antibiotics ?? 'MISSING'}`);
    const lst8Ok = lst?.blood_transfusion === 'CANT_DECIDE';
    console.log(`    ${lst8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion === 'CANT_DECIDE': ${lst?.blood_transfusion ?? 'MISSING'}`);
    const lst9Ok = lst?.blood_transfusion_instruction === 'Attorney consults clinical team.';
    console.log(`    ${lst9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion_instruction === 'Attorney consults clinical team.': ${lst?.blood_transfusion_instruction ?? 'MISSING'}`);

    // ── cpr_and_resuscitation (scenario 4) ───────────────────────────────
    console.log('    \x1b[1m[cpr_and_resuscitation]\x1b[0m');
    const cpr = d?.cpr_and_resuscitation;
    const cpr1Ok = cpr?.cpr_instruction === 'UNSURE';
    console.log(`    ${cpr1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_instruction === 'UNSURE': ${cpr?.cpr_instruction ?? 'MISSING'}`);
    const cpr2Ok = cpr?.medical_not_expected_to_recover === 'REJECT_CPR';
    console.log(`    ${cpr2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} medical_not_expected_to_recover === 'REJECT_CPR': ${cpr?.medical_not_expected_to_recover ?? 'MISSING'}`);
    const cpr3Ok = cpr?.cpr_resuscitation === 'CANT_DECIDE';
    console.log(`    ${cpr3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation === 'CANT_DECIDE': ${cpr?.cpr_resuscitation ?? 'MISSING'}`);
    const cpr4Ok = cpr?.cpr_resuscitation_instruction === 'Discuss with treating medical team.';
    console.log(`    ${cpr4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation_instruction === 'Discuss with treating medical team.': ${cpr?.cpr_resuscitation_instruction ?? 'MISSING'}`);
    const cpr5Ok = cpr?.cpr_consent === 'CONDITION';
    console.log(`    ${cpr5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent === 'CONDITION': ${cpr?.cpr_consent ?? 'MISSING'}`);
    const cpr6Ok = cpr?.cpr_consent_instruction === 'Based on quality-of-life prognosis.';
    console.log(`    ${cpr6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent_instruction === 'Based on quality-of-life prognosis.': ${cpr?.cpr_consent_instruction ?? 'MISSING'}`);

    // ── organ_and_body_donation (scenario 5) ─────────────────────────────
    console.log('    \x1b[1m[organ_and_body_donation]\x1b[0m');
    const organ = d?.organ_and_body_donation;
    const org1Ok = organ?.donate_organ === false;
    console.log(`    ${org1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_organ === false: ${organ?.donate_organ ?? 'MISSING'}`);
    const org2Ok = organ?.consent_organ_donation === false;
    console.log(`    ${org2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_organ_donation === false: ${organ?.consent_organ_donation ?? 'MISSING'}`);
    const org3Ok = organ?.donate_body === true;
    console.log(`    ${org3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_body === true: ${organ?.donate_body ?? 'MISSING'}`);
    const org4Ok = organ?.consent_body_donation === true;
    console.log(`    ${org4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_body_donation === true: ${organ?.consent_body_donation ?? 'MISSING'}`);
    const org5Ok = organ?.authorisation === 'Authorise use of body for Canberra medical school.';
    console.log(`    ${org5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} authorisation === 'Authorise use of body for Canberra medical school.': ${organ?.authorisation ?? 'MISSING'}`);

    // ── treatment_decisions (scenario 6) ─────────────────────────────────
    console.log('    \x1b[1m[treatment_decisions]\x1b[0m');
    const td = d?.treatment_decisions;
    const td1Ok = td?.life_sustaining_treatment === 'REFUSE_ALL_TREATMENT';
    console.log(`    ${td1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment === 'REFUSE_ALL_TREATMENT': ${td?.life_sustaining_treatment ?? 'MISSING'}`);
    const td2Ok = td?.artificial_hydration === 'CONSENT';
    console.log(`    ${td2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration === 'CONSENT': ${td?.artificial_hydration ?? 'MISSING'}`);
    const td3Ok = td?.artificial_hydration_instruction === 'Slow drip acceptable for comfort.';
    console.log(`    ${td3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration_instruction === 'Slow drip acceptable for comfort.': ${td?.artificial_hydration_instruction ?? 'MISSING'}`);
    const td4Ok = td?.consent_palliative_comfort_care === 'CONSENT';
    console.log(`    ${td4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_palliative_comfort_care === 'CONSENT': ${td?.consent_palliative_comfort_care ?? 'MISSING'}`);
    const td5Ok = td?.specific_treatment_no_consent === 'ARTIFICIAL_FEEDING';
    console.log(`    ${td5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent === 'ARTIFICIAL_FEEDING': ${td?.specific_treatment_no_consent ?? 'MISSING'}`);
    const td6Ok = td?.specific_treatment_no_consent_instruction === 'No experimental drug trials.';
    console.log(`    ${td6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent_instruction === 'No experimental drug trials.': ${td?.specific_treatment_no_consent_instruction ?? 'MISSING'}`);
    const td7Ok = td?.healthcare_preferred === 'Calvary Public Hospital preferred.';
    console.log(`    ${td7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} healthcare_preferred === 'Calvary Public Hospital preferred.': ${td?.healthcare_preferred ?? 'MISSING'}`);

    // ── medical_treatment_refuse (scenario 7) ──────────────────────────
    console.log('    \x1b[1m[medical_treatment_refuse]\x1b[0m');
    const mtrOk = d?.medical_treatment_refuse === 'I refuse all experimental and invasive treatments.';
    console.log(`    ${mtrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} medical_treatment_refuse === 'I refuse all experimental and invasive treatments.': ${d?.medical_treatment_refuse ?? 'MISSING'}`);

    // ── ahd_persons (scenario 8) ─────────────────────────────────────────
    console.log('    \x1b[1m[ahd_persons]\x1b[0m');
    const persons = d?.ahd_persons ?? [];
    const personsCountOk = persons.length >= 5;
    console.log(`    ${personsCountOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ahd_persons count >= 5: ${persons.length}`);

    // Person 1 — SDM
    const sdm = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const sdmNameOk = sdm?.full_name === 'Patricia O\'Brien';
    console.log(`    ${sdmNameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM full_name === 'Patricia O\\'Brien': ${sdm?.full_name ?? 'MISSING'}`);
    const sdmPhoneOk = sdm?.phone === '0261234567';
    console.log(`    ${sdmPhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM phone === '0261234567': ${sdm?.phone ?? 'MISSING'}`);
    const sdmAddrOk = sdm?.address === '1 London Circuit, Canberra ACT 2601';
    console.log(`    ${sdmAddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM address === '1 London Circuit, Canberra ACT 2601': ${sdm?.address ?? 'MISSING'}`);

    // Person 2 — SDM_SECONDARY
    const sdm2 = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER_SECONDARY');
    const sdm2NameOk = sdm2?.full_name === 'Robert O\'Brien';
    console.log(`    ${sdm2NameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM_SECONDARY full_name === 'Robert O\\'Brien': ${sdm2?.full_name ?? 'MISSING'}`);
    const sdm2PhoneOk = sdm2?.phone === '0262345678';
    console.log(`    ${sdm2PhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM_SECONDARY phone === '0262345678': ${sdm2?.phone ?? 'MISSING'}`);
    const sdm2AddrOk = sdm2?.address === '1 London Circuit, Canberra ACT 2601';
    console.log(`    ${sdm2AddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM_SECONDARY address === '1 London Circuit, Canberra ACT 2601': ${sdm2?.address ?? 'MISSING'}`);

    // Person 3 — WITNESS_MEDICAL_PRACTITIONER
    const medWit = persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const mwNameOk = medWit?.full_name === 'Dr. Helen Morris';
    console.log(`    ${mwNameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS full_name === 'Dr. Helen Morris': ${medWit?.full_name ?? 'MISSING'}`);
    const mwQualOk = medWit?.qualification === 'Cardiologist' || medWit?.other?.qualification === 'Cardiologist';
    console.log(`    ${mwQualOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS qualification === 'Cardiologist': ${medWit?.qualification ?? medWit?.other?.qualification ?? 'MISSING'}`);
    const mwPhoneOk = medWit?.phone === '0263456789';
    console.log(`    ${mwPhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS phone === '0263456789': ${medWit?.phone ?? 'MISSING'}`);
    const mwAddrOk = medWit?.address === '4 Bowes Street, Phillip ACT 2606';
    console.log(`    ${mwAddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS address === '4 Bowes Street, Phillip ACT 2606': ${medWit?.address ?? 'MISSING'}`);

    // Person 4 — WITNESS_PERSON
    const wp = persons.find((p) => p.person_type === 'WITNESS_PERSON');
    const wpNameOk = wp?.full_name === 'George Mitchell';
    console.log(`    ${wpNameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON full_name === 'George Mitchell': ${wp?.full_name ?? 'MISSING'}`);
    const wpPhoneOk = wp?.phone === '0264567890';
    console.log(`    ${wpPhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON phone === '0264567890': ${wp?.phone ?? 'MISSING'}`);
    const wpAddrOk = wp?.address === '10 Northbourne Avenue, Canberra ACT 2601';
    console.log(`    ${wpAddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON address === '10 Northbourne Avenue, Canberra ACT 2601': ${wp?.address ?? 'MISSING'}`);

    // Person 5 — HELPER
    const hlp = persons.find((p) => p.person_type === 'HELPER');
    const hlpNameOk = hlp?.full_name === 'Anne Mitchell';
    console.log(`    ${hlpNameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} HELPER full_name === 'Anne Mitchell': ${hlp?.full_name ?? 'MISSING'}`);
    const hlpPhoneOk = hlp?.phone === '0265678901';
    console.log(`    ${hlpPhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} HELPER phone === '0265678901': ${hlp?.phone ?? 'MISSING'}`);
    const hlpAddrOk = hlp?.address === '10 Northbourne Avenue, Canberra ACT 2601';
    console.log(`    ${hlpAddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} HELPER address === '10 Northbourne Avenue, Canberra ACT 2601': ${hlp?.address ?? 'MISSING'}`);

    // ── declarations_and_wishes (scenario 9) ─────────────────────────────
    console.log('    \x1b[1m[declarations_and_wishes]\x1b[0m');
    const dw = d?.declarations_and_wishes;
    const dw1Ok = dw?.declaration === 'I make this directive freely and voluntarily.';
    console.log(`    ${dw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declaration === 'I make this directive freely and voluntarily.': ${dw?.declaration ?? 'MISSING'}`);
    const dw2Ok = dw?.what_matter_most === 'Remaining conscious and connected to family.';
    console.log(`    ${dw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_matter_most === 'Remaining conscious and connected to family.': ${dw?.what_matter_most ?? 'MISSING'}`);
    const dw3Ok = dw?.what_worries_most === 'Pain and loss of dignity.';
    console.log(`    ${dw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_worries_most === 'Pain and loss of dignity.': ${dw?.what_worries_most ?? 'MISSING'}`);
    const dw4Ok = dw?.unacceptable_medical_treatment_outcome === 'Prolonged unconscious state with no prognosis.';
    console.log(`    ${dw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} unacceptable_medical_treatment_outcome === 'Prolonged unconscious state with no prognosis.': ${dw?.unacceptable_medical_treatment_outcome ?? 'MISSING'}`);
    const dw5Ok = dw?.cultural_request === 'No specific cultural requirements.';
    console.log(`    ${dw5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cultural_request === 'No specific cultural requirements.': ${dw?.cultural_request ?? 'MISSING'}`);
    const dw6Ok = dw?.religious_beliefs === 'Secular; no religious rites.';
    console.log(`    ${dw6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} religious_beliefs === 'Secular; no religious rites.': ${dw?.religious_beliefs ?? 'MISSING'}`);
    const dw7Ok = dw?.after_death_importance === 'Burial at National Memorial.';
    console.log(`    ${dw7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} after_death_importance === 'Burial at National Memorial.': ${dw?.after_death_importance ?? 'MISSING'}`);
    const dw8Ok = dw?.nearing_death_instruction === 'Keep conversation light; read to me.';
    console.log(`    ${dw8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_instruction === 'Keep conversation light; read to me.': ${dw?.nearing_death_instruction ?? 'MISSING'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
