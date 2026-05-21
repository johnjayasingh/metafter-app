/**
 * AHD Integration Tests — Tasmania (TAS)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — REFUSE
 *  4. CPR and resuscitation
 *  5. Organ and body donation
 *  6. Tasmania-specific: registered_tasmania_bequest_program
 *  7. AHD persons — SDM + witness (qualification in other)
 *  8. Treatment decisions (other_treatment_decision)
 *  9. Declarations and wishes
 * 10. ACD revoked
 * 11. GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/tas.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — Tasmania (TAS)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Parkinson\'s disease, stage 3',
        things_important_for_me:                     'Living at home with my garden as long as possible',
        beliefs_considered_during_health_care:       'I believe in letting nature take its course',
        nearing_death_preference:                    'Home hospice only; avoid hospital',
        people_not_to_involve_healthcare_discussion: 'No one',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'MANAGED_SYMPTOMS', 'HEALTHY_SURROUNDINGS'],
      },
    });
    printResult('POST /user/ahd (TAS minimal)', res, 200);
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
        direction_instruction: 'Consent to all life-sustaining treatment.',
        assisted_ventilation: 'CONSENT',
        artificial_nutrition: 'CONSENT',
        antibiotics:          'CONSENT',
        blood_transfusion:    'CONSENT',
      },
    });
    printResult('POST /user/ahd (TAS LST CONSENT)', res, 200);
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
        direction_instruction:            'Refuse all except comfort and pain management.',
        assisted_ventilation:             'REFUSE',
        assisted_ventilation_instruction: 'No mechanical breathing.',
        artificial_nutrition:             'REFUSE',
        artificial_nutrition_instruction: 'No IV or tube feeding.',
        antibiotics: 'CANT_DECIDE',
        blood_transfusion:                'CONSENT',
        other_treatment:                  'REFUSE',
        other_instruction:                'No dialysis or surgical intervention.',
      },
    });
    printResult('POST /user/ahd (TAS LST REFUSE)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'REFUSE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
  }

  // ── 4. CPR and resuscitation ──────────────────────────────────────────
  printSection('Scenario 4: CPR and resuscitation');
  {
    const res = await request('POST', '/user/ahd', {
      cpr_and_resuscitation: {
        cpr_instruction: 'UNBEARABLE',
        medical_not_expected_to_recover: 'REJECT_CPR',
        cpr_resuscitation: 'REFUSE',
        cpr_resuscitation_instruction:   'DNAR to be placed on file.',
        cpr_consent: 'ALLOW_TO_DIE',
        cpr_consent_instruction:         'No CPR under any circumstances.',
      },
    });
    printResult('POST /user/ahd (TAS CPR)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 5. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 5: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      is_registered_australian_organ_donor: true,
      organ_and_body_donation: {
        donate_organ:               true,
        organ_donation_instruction: 'All viable organs.',
        consent_organ_donation:     true,
        donate_body:                true,
        consent_body_donation:      true,
        authorisation:              'Authorise for University of Tasmania medical research.',
      },
    });
    printResult('POST /user/ahd (TAS organ donation)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_and_body_donation?.donate_organ === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} donate_organ: ${d?.organ_and_body_donation?.donate_organ}`);
  }

  // ── 6. Tasmania-specific: bequest program ─────────────────────────────
  printSection('Scenario 6: TAS-specific — registered_tasmania_bequest_program');
  {
    const res = await request('POST', '/user/ahd', {
      is_registered_tasmania_bequest_program: true,
      is_registered_australian_organ_donor:   false,
    });
    printResult('POST /user/ahd (TAS bequest program)', res, 200);
    const d = res.body?.data;
    const ok = d?.is_registered_tasmania_bequest_program === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_registered_tasmania_bequest_program: ${d?.is_registered_tasmania_bequest_program}`);
  }

  // ── 7. AHD persons — witnesses with AHPRA + interpreter ───────────────
  printSection('Scenario 7: AHD persons — SDM + witnesses (AHPRA) + interpreter');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: true,
      ahd_persons: [
        {
          full_name:   'Emma Walsh',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone:       '0362221234',
          address:     '10 Murray Street, Hobart TAS 7000',
        },
        {
          full_name:   'Dr. Andrew Smith',
          person_type: 'WITNESS_MEDICAL_PRACTITIONER',
          phone:       '0363334567',
          address:     '40 Collins Street, Hobart TAS 7000',
          other: {
            qualification: 'MED0001234567',
            signature:     'Dr Andrew Smith',
            dob:           '1970-03-15',
            house_number:  '40',
          },
        },
        {
          full_name:   'Jane Doe',
          person_type: 'WITNESS_PERSON',
          phone:       '0363338888',
          address:     '5 Liverpool Street, Hobart TAS 7000',
          other: {
            signature:    'Jane Doe',
            dob:          '1985-09-22',
            house_number: '5',
          },
        },
        {
          full_name:   'Maria Garcia',
          person_type: 'INTERPRETER',
          dob:         '1985-04-12',
          other: {
            language:     'Spanish',
            naati_number: 'NAATI-9999',
          },
        },
        {
          full_name:   'Tom Walsh',
          person_type: 'PRIMARY_PERSON',
          phone:       '0362225555',
          address:     '10 Murray Street, Hobart TAS 7000',
          other: {
            date: '2026-01-15',
          },
        },
        {
          full_name:   'Sarah Walsh',
          person_type: 'HELPER',
          phone:       '0362226666',
          address:     '15 Murray Street, Hobart TAS 7000',
          other: {
            ahd_primary_person_name: 'Tom Walsh',
            relationship:            'Daughter',
          },
        },
      ],
    });
    printResult('POST /user/ahd (TAS ahd_persons)', res, 200);
    const persons = res.body?.data?.ahd_persons ?? [];
    const hasSdm    = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const hasMedWit = Array.isArray(persons) && persons.some((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const hasInterp = Array.isArray(persons) && persons.some((p) => p.person_type === 'INTERPRETER');
    const medWit    = persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const interp    = persons.find((p) => p.person_type === 'INTERPRETER');
    console.log(`    ${hasSdm    ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    console.log(`    ${hasMedWit ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER present`);
    console.log(`    ${(medWit?.qualification || medWit?.other?.qualification) ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} AHPRA qualification: ${medWit?.qualification ?? medWit?.other?.qualification ?? '?'}`);
    console.log(`    ${hasInterp ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} INTERPRETER present: ${interp?.full_name ?? '?'}`);
    console.log(`    ${interp?.other?.naati_number ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} NAATI: ${interp?.other?.naati_number ?? '?'}`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 8. Treatment decisions (TAS-specific mapping) ────────────────────
  printSection('Scenario 8: Treatment decisions — other_treatment_decision');
  {
    const res = await request('POST', '/user/ahd', {
      treatment_decisions: {
        other_treatment_decision:             'REFUSE',
        other_treatment_decision_instruction: 'Artificial feeding / tube feeding',
      },
    });
    printResult('POST /user/ahd (TAS treatment_decisions)', res, 200);
    const d = res.body?.data;
    const tdOk = d?.treatment_decisions?.other_treatment_decision === 'REFUSE';
    const tiOk = d?.treatment_decisions?.other_treatment_decision_instruction != null;
    console.log(`    ${tdOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} other_treatment_decision: ${d?.treatment_decisions?.other_treatment_decision ?? 'MISSING'}`);
    console.log(`    ${tiOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} other_treatment_decision_instruction: ${d?.treatment_decisions?.other_treatment_decision_instruction ?? 'MISSING'}`);
  }

  // ── 9. Declarations and wishes ────────────────────────────────────────
  printSection('Scenario 9: Declarations and wishes');
  {
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I provide this directive freely.',
        what_matter_most:                          'Being pain-free and at peace.',
        what_worries_most:                         'Losing awareness of surroundings.',
        unacceptable_medical_treatment_outcome:    'Vegetative state with no recovery prognosis.',
        cultural_request:                          'Bush burial tradition.',
        religious_beliefs:                         'Quaker.',
        after_death_importance:                    'Simple service; no funeral home.',
        nearing_death_instruction:                 'Bring my dog; fresh air if possible.',
      },
    });
    printResult('POST /user/ahd (TAS declarations)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes persisted`);
  }

  // ── 10. ACD revoked ───────────────────────────────────────────────────
  printSection('Scenario 10: ACD revoked flag');
  {
    const res = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2025-12-31',
    });
    printResult('POST /user/ahd (TAS is_acd_revoked)', res, 200);
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
    console.log('  \x1b[1mTop-level flags:\x1b[0m');
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked ?? 'MISSING'}`);
    const expiryOk = d?.acd_expiry_date === '2025-12-31';
    console.log(`    ${expiryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} acd_expiry_date === '2025-12-31': ${d?.acd_expiry_date ?? 'MISSING'}`);
    const guardianOk = d?.is_enduring_guardian_appointed === true;
    console.log(`    ${guardianOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === true: ${d?.is_enduring_guardian_appointed ?? 'MISSING'}`);
    const bequestOk = d?.is_registered_tasmania_bequest_program === true;
    console.log(`    ${bequestOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_registered_tasmania_bequest_program === true: ${d?.is_registered_tasmania_bequest_program ?? 'MISSING'}`);
    const organDonorOk = d?.is_registered_australian_organ_donor === false;
    console.log(`    ${organDonorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_registered_australian_organ_donor === false: ${d?.is_registered_australian_organ_donor ?? 'MISSING'}`);

    // ── health_conditions (scenario 1) ───────────────────────────────────
    console.log('  \x1b[1mhealth_conditions:\x1b[0m');
    const hc = d?.health_conditions;
    const hc1Ok = hc?.major_health_conditions === 'Parkinson\'s disease, stage 3';
    console.log(`    ${hc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} major_health_conditions === 'Parkinson\\'s disease, stage 3': ${hc?.major_health_conditions ?? 'MISSING'}`);
    const hc2Ok = hc?.things_important_for_me === 'Living at home with my garden as long as possible';
    console.log(`    ${hc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} things_important_for_me === 'Living at home with my garden as long as possible': ${hc?.things_important_for_me ?? 'MISSING'}`);
    const hc3Ok = hc?.beliefs_considered_during_health_care === 'I believe in letting nature take its course';
    console.log(`    ${hc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} beliefs_considered_during_health_care === 'I believe in letting nature take its course': ${hc?.beliefs_considered_during_health_care ?? 'MISSING'}`);
    const hc4Ok = hc?.nearing_death_preference === 'Home hospice only; avoid hospital';
    console.log(`    ${hc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_preference === 'Home hospice only; avoid hospital': ${hc?.nearing_death_preference ?? 'MISSING'}`);
    const hc5Ok = hc?.people_not_to_involve_healthcare_discussion === 'No one';
    console.log(`    ${hc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} people_not_to_involve_healthcare_discussion === 'No one': ${hc?.people_not_to_involve_healthcare_discussion ?? 'MISSING'}`);
    const comfortArr = hc?.comfort_nearing_death;
    const hc6Ok = Array.isArray(comfortArr) && comfortArr.includes('LOVED_ONES_NEARBY');
    console.log(`    ${hc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death includes 'LOVED_ONES_NEARBY': ${JSON.stringify(comfortArr) ?? 'MISSING'}`);
    const hc7Ok = Array.isArray(comfortArr) && comfortArr.length >= 3;
    console.log(`    ${hc7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death length >= 3: ${comfortArr?.length ?? 'MISSING'}`);

    // ── life_sustaining_treatment (scenario 3 overwrites 2) ──────────────
    console.log('  \x1b[1mlife_sustaining_treatment:\x1b[0m');
    const lst = d?.life_sustaining_treatment;
    const lst1Ok = lst?.direction_type === 'REFUSE';
    console.log(`    ${lst1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_type === 'REFUSE': ${lst?.direction_type ?? 'MISSING'}`);
    const lst2Ok = lst?.direction_instruction === 'Refuse all except comfort and pain management.';
    console.log(`    ${lst2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_instruction === 'Refuse all except comfort and pain management.': ${lst?.direction_instruction ?? 'MISSING'}`);
    const lst3Ok = lst?.assisted_ventilation === 'REFUSE';
    console.log(`    ${lst3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation === 'REFUSE': ${lst?.assisted_ventilation ?? 'MISSING'}`);
    const lst4Ok = lst?.assisted_ventilation_instruction === 'No mechanical breathing.';
    console.log(`    ${lst4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation_instruction === 'No mechanical breathing.': ${lst?.assisted_ventilation_instruction ?? 'MISSING'}`);
    const lst5Ok = lst?.artificial_nutrition === 'REFUSE';
    console.log(`    ${lst5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition === 'REFUSE': ${lst?.artificial_nutrition ?? 'MISSING'}`);
    const lst6Ok = lst?.artificial_nutrition_instruction === 'No IV or tube feeding.';
    console.log(`    ${lst6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition_instruction === 'No IV or tube feeding.': ${lst?.artificial_nutrition_instruction ?? 'MISSING'}`);
    const lst7Ok = lst?.antibiotics === 'CANT_DECIDE';
    console.log(`    ${lst7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} antibiotics === 'CANT_DECIDE': ${lst?.antibiotics ?? 'MISSING'}`);
    const lst8Ok = lst?.blood_transfusion === 'CONSENT';
    console.log(`    ${lst8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion === 'CONSENT': ${lst?.blood_transfusion ?? 'MISSING'}`);
    const lst9Ok = lst?.other_treatment === 'REFUSE';
    console.log(`    ${lst9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_treatment === 'REFUSE': ${lst?.other_treatment ?? 'MISSING'}`);
    const lst10Ok = lst?.other_instruction === 'No dialysis or surgical intervention.';
    console.log(`    ${lst10Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_instruction === 'No dialysis or surgical intervention.': ${lst?.other_instruction ?? 'MISSING'}`);

    // ── cpr_and_resuscitation (scenario 4) ───────────────────────────────
    console.log('  \x1b[1mcpr_and_resuscitation:\x1b[0m');
    const cpr = d?.cpr_and_resuscitation;
    const cpr1Ok = cpr?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${cpr1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_instruction === 'UNBEARABLE': ${cpr?.cpr_instruction ?? 'MISSING'}`);
    const cpr2Ok = cpr?.medical_not_expected_to_recover === 'REJECT_CPR';
    console.log(`    ${cpr2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} medical_not_expected_to_recover === 'REJECT_CPR': ${cpr?.medical_not_expected_to_recover ?? 'MISSING'}`);
    const cpr3Ok = cpr?.cpr_resuscitation === 'REFUSE';
    console.log(`    ${cpr3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation === 'REFUSE': ${cpr?.cpr_resuscitation ?? 'MISSING'}`);
    const cpr4Ok = cpr?.cpr_resuscitation_instruction === 'DNAR to be placed on file.';
    console.log(`    ${cpr4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation_instruction === 'DNAR to be placed on file.': ${cpr?.cpr_resuscitation_instruction ?? 'MISSING'}`);
    const cpr5Ok = cpr?.cpr_consent === 'ALLOW_TO_DIE';
    console.log(`    ${cpr5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent === 'ALLOW_TO_DIE': ${cpr?.cpr_consent ?? 'MISSING'}`);
    const cpr6Ok = cpr?.cpr_consent_instruction === 'No CPR under any circumstances.';
    console.log(`    ${cpr6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent_instruction === 'No CPR under any circumstances.': ${cpr?.cpr_consent_instruction ?? 'MISSING'}`);

    // ── organ_and_body_donation (scenario 5) ─────────────────────────────
    console.log('  \x1b[1morgan_and_body_donation:\x1b[0m');
    const ob = d?.organ_and_body_donation;
    const ob1Ok = ob?.donate_organ === true;
    console.log(`    ${ob1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_organ === true: ${ob?.donate_organ ?? 'MISSING'}`);
    const ob2Ok = ob?.organ_donation_instruction === 'All viable organs.';
    console.log(`    ${ob2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_donation_instruction === 'All viable organs.': ${ob?.organ_donation_instruction ?? 'MISSING'}`);
    const ob3Ok = ob?.consent_organ_donation === true;
    console.log(`    ${ob3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_organ_donation === true: ${ob?.consent_organ_donation ?? 'MISSING'}`);
    const ob4Ok = ob?.donate_body === true;
    console.log(`    ${ob4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_body === true: ${ob?.donate_body ?? 'MISSING'}`);
    const ob5Ok = ob?.consent_body_donation === true;
    console.log(`    ${ob5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_body_donation === true: ${ob?.consent_body_donation ?? 'MISSING'}`);
    const ob6Ok = ob?.authorisation === 'Authorise for University of Tasmania medical research.';
    console.log(`    ${ob6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} authorisation === 'Authorise for University of Tasmania medical research.': ${ob?.authorisation ?? 'MISSING'}`);

    // ── treatment_decisions (scenario 8) ─────────────────────────────────
    console.log('  \x1b[1mtreatment_decisions:\x1b[0m');
    const td = d?.treatment_decisions;
    const td1Ok = td?.other_treatment_decision === 'REFUSE';
    console.log(`    ${td1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_treatment_decision === 'REFUSE': ${td?.other_treatment_decision ?? 'MISSING'}`);
    const td2Ok = td?.other_treatment_decision_instruction === 'Artificial feeding / tube feeding';
    console.log(`    ${td2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_treatment_decision_instruction === 'Artificial feeding / tube feeding': ${td?.other_treatment_decision_instruction ?? 'MISSING'}`);

    // ── ahd_persons (scenario 7) ─────────────────────────────────────────
    console.log('  \x1b[1mahd_persons:\x1b[0m');
    const persons = d?.ahd_persons ?? [];
    const personsCountOk = persons.length >= 6;
    console.log(`    ${personsCountOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ahd_persons count >= 6: ${persons.length}`);

    // Person 1: SDM
    const sdm = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const sdm1Ok = sdm?.full_name === 'Emma Walsh';
    console.log(`    ${sdm1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM full_name === 'Emma Walsh': ${sdm?.full_name ?? 'MISSING'}`);
    const sdm2Ok = sdm?.phone === '0362221234';
    console.log(`    ${sdm2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM phone === '0362221234': ${sdm?.phone ?? 'MISSING'}`);
    const sdm3Ok = sdm?.address === '10 Murray Street, Hobart TAS 7000';
    console.log(`    ${sdm3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM address === '10 Murray Street, Hobart TAS 7000': ${sdm?.address ?? 'MISSING'}`);

    // Person 2: WITNESS_MEDICAL_PRACTITIONER
    const medWit = persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const mw1Ok = medWit?.full_name === 'Dr. Andrew Smith';
    console.log(`    ${mw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER full_name === 'Dr. Andrew Smith': ${medWit?.full_name ?? 'MISSING'}`);
    const mw2Ok = medWit?.phone === '0363334567';
    console.log(`    ${mw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER phone === '0363334567': ${medWit?.phone ?? 'MISSING'}`);
    const mw3Ok = medWit?.address === '40 Collins Street, Hobart TAS 7000';
    console.log(`    ${mw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER address === '40 Collins Street, Hobart TAS 7000': ${medWit?.address ?? 'MISSING'}`);
    const mwQual = medWit?.qualification ?? medWit?.other?.qualification;
    const mw4Ok = mwQual === 'MED0001234567';
    console.log(`    ${mw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER qualification === 'MED0001234567': ${mwQual ?? 'MISSING'}`);
    const mw5Ok = medWit?.other?.signature === 'Dr Andrew Smith';
    console.log(`    ${mw5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER other.signature === 'Dr Andrew Smith': ${medWit?.other?.signature ?? 'MISSING'}`);
    const mw6Ok = medWit?.other?.dob === '1970-03-15';
    console.log(`    ${mw6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER other.dob === '1970-03-15': ${medWit?.other?.dob ?? 'MISSING'}`);
    const mw7Ok = medWit?.other?.house_number === '40';
    console.log(`    ${mw7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER other.house_number === '40': ${medWit?.other?.house_number ?? 'MISSING'}`);

    // Person 3: WITNESS_PERSON
    const witPerson = persons.find((p) => p.person_type === 'WITNESS_PERSON');
    const wp1Ok = witPerson?.full_name === 'Jane Doe';
    console.log(`    ${wp1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON full_name === 'Jane Doe': ${witPerson?.full_name ?? 'MISSING'}`);
    const wp2Ok = witPerson?.phone === '0363338888';
    console.log(`    ${wp2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON phone === '0363338888': ${witPerson?.phone ?? 'MISSING'}`);
    const wp3Ok = witPerson?.address === '5 Liverpool Street, Hobart TAS 7000';
    console.log(`    ${wp3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON address === '5 Liverpool Street, Hobart TAS 7000': ${witPerson?.address ?? 'MISSING'}`);
    const wp4Ok = witPerson?.other?.signature === 'Jane Doe';
    console.log(`    ${wp4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON other.signature === 'Jane Doe': ${witPerson?.other?.signature ?? 'MISSING'}`);
    const wp5Ok = witPerson?.other?.dob === '1985-09-22';
    console.log(`    ${wp5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON other.dob === '1985-09-22': ${witPerson?.other?.dob ?? 'MISSING'}`);
    const wp6Ok = witPerson?.other?.house_number === '5';
    console.log(`    ${wp6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_PERSON other.house_number === '5': ${witPerson?.other?.house_number ?? 'MISSING'}`);

    // Person 4: INTERPRETER
    const interp = persons.find((p) => p.person_type === 'INTERPRETER');
    const ip1Ok = interp?.full_name === 'Maria Garcia';
    console.log(`    ${ip1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} INTERPRETER full_name === 'Maria Garcia': ${interp?.full_name ?? 'MISSING'}`);
    const ip2Ok = interp?.dob === '1985-04-12';
    console.log(`    ${ip2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} INTERPRETER dob === '1985-04-12': ${interp?.dob ?? 'MISSING'}`);
    const interpLang = interp?.other?.language;
    const ip3Ok = interpLang === 'Spanish';
    console.log(`    ${ip3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} INTERPRETER language === 'Spanish': ${interpLang ?? 'MISSING'}`);
    const interpNaati = interp?.other?.naati_number;
    const ip4Ok = interpNaati === 'NAATI-9999';
    console.log(`    ${ip4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} INTERPRETER naati_number === 'NAATI-9999': ${interpNaati ?? 'MISSING'}`);

    // Person 5: PRIMARY_PERSON
    const pp = persons.find((p) => p.person_type === 'PRIMARY_PERSON');
    const pp1Ok = pp?.full_name === 'Tom Walsh';
    console.log(`    ${pp1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} PRIMARY_PERSON full_name === 'Tom Walsh': ${pp?.full_name ?? 'MISSING'}`);
    const pp2Ok = pp?.phone === '0362225555';
    console.log(`    ${pp2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} PRIMARY_PERSON phone === '0362225555': ${pp?.phone ?? 'MISSING'}`);
    const pp3Ok = pp?.address === '10 Murray Street, Hobart TAS 7000';
    console.log(`    ${pp3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} PRIMARY_PERSON address === '10 Murray Street, Hobart TAS 7000': ${pp?.address ?? 'MISSING'}`);
    const pp4Ok = pp?.other?.date === '2026-01-15';
    console.log(`    ${pp4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} PRIMARY_PERSON other.date === '2026-01-15': ${pp?.other?.date ?? 'MISSING'}`);

    // Person 6: HELPER
    const helper = persons.find((p) => p.person_type === 'HELPER');
    const hp1Ok = helper?.full_name === 'Sarah Walsh';
    console.log(`    ${hp1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} HELPER full_name === 'Sarah Walsh': ${helper?.full_name ?? 'MISSING'}`);
    const hp2Ok = helper?.phone === '0362226666';
    console.log(`    ${hp2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} HELPER phone === '0362226666': ${helper?.phone ?? 'MISSING'}`);
    const hp3Ok = helper?.other?.ahd_primary_person_name === 'Tom Walsh';
    console.log(`    ${hp3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} HELPER other.ahd_primary_person_name === 'Tom Walsh': ${helper?.other?.ahd_primary_person_name ?? 'MISSING'}`);
    const hp4Ok = helper?.other?.relationship === 'Daughter';
    console.log(`    ${hp4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} HELPER other.relationship === 'Daughter': ${helper?.other?.relationship ?? 'MISSING'}`);

    // ── declarations_and_wishes (scenario 9) ─────────────────────────────
    console.log('  \x1b[1mdeclarations_and_wishes:\x1b[0m');
    const dw = d?.declarations_and_wishes;
    const dw1Ok = dw?.declaration === 'I provide this directive freely.';
    console.log(`    ${dw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declaration === 'I provide this directive freely.': ${dw?.declaration ?? 'MISSING'}`);
    const dw2Ok = dw?.what_matter_most === 'Being pain-free and at peace.';
    console.log(`    ${dw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_matter_most === 'Being pain-free and at peace.': ${dw?.what_matter_most ?? 'MISSING'}`);
    const dw3Ok = dw?.what_worries_most === 'Losing awareness of surroundings.';
    console.log(`    ${dw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_worries_most === 'Losing awareness of surroundings.': ${dw?.what_worries_most ?? 'MISSING'}`);
    const dw4Ok = dw?.unacceptable_medical_treatment_outcome === 'Vegetative state with no recovery prognosis.';
    console.log(`    ${dw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} unacceptable_medical_treatment_outcome === 'Vegetative state with no recovery prognosis.': ${dw?.unacceptable_medical_treatment_outcome ?? 'MISSING'}`);
    const dw5Ok = dw?.cultural_request === 'Bush burial tradition.';
    console.log(`    ${dw5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cultural_request === 'Bush burial tradition.': ${dw?.cultural_request ?? 'MISSING'}`);
    const dw6Ok = dw?.religious_beliefs === 'Quaker.';
    console.log(`    ${dw6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} religious_beliefs === 'Quaker.': ${dw?.religious_beliefs ?? 'MISSING'}`);
    const dw7Ok = dw?.after_death_importance === 'Simple service; no funeral home.';
    console.log(`    ${dw7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} after_death_importance === 'Simple service; no funeral home.': ${dw?.after_death_importance ?? 'MISSING'}`);
    const dw8Ok = dw?.nearing_death_instruction === 'Bring my dog; fresh air if possible.';
    console.log(`    ${dw8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_instruction === 'Bring my dog; fresh air if possible.': ${dw?.nearing_death_instruction ?? 'MISSING'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
