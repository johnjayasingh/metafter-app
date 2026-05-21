/**
 * AHD Integration Tests — Queensland (QLD)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — ATTORNEY_DECISION
 *  4. Other health directions (QLD-specific)
 *  5. CPR and resuscitation
 *  6. Organ and body donation
 *  7. Treatment decisions
 *  8. AHD persons — substitute decision maker + enduring guardian + witness + attorney health matters
 *  9. Attorney and advice
 * 10. Declarations and wishes
 * 11. ACD revoked
 * 12. GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/qld.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — Queensland (QLD)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Chronic kidney disease, stage 3',
        things_important_for_me:                     'Staying at home with my dogs',
        beliefs_considered_during_health_care:       'I believe in natural end-of-life processes',
        nearing_death_preference:                    'No heroic measures; comfort only',
        people_not_to_involve_healthcare_discussion: 'My son Peter',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'MANAGED_SYMPTOMS', 'SPIRITUAL_CARE'],
      },
    });
    printResult('POST /user/ahd (QLD minimal)', res, 200);
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
        direction_instruction: 'I consent to all forms of life-sustaining treatment.',
        assisted_ventilation: 'CONSENT',
        artificial_nutrition: 'CONSENT',
        antibiotics:          'CONSENT',
        blood_transfusion:    'CONSENT',
      },
    });
    printResult('POST /user/ahd (QLD LST CONSENT)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'CONSENT';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
  }

  // ── 3. Life sustaining — ATTORNEY_DECISION ───────────────────────────
  printSection('Scenario 3: Life sustaining treatment — ATTORNEY_DECISION');
  {
    const res = await request('POST', '/user/ahd', {
      life_sustaining_treatment: {
        direction_type: 'ATTORNEY_DECISION',
        direction_instruction:            'Attorney decides based on circumstances.',
        treatment_type: 'CIRCUMSTANCE',
        treatment_instruction: 'Treat only if prospect of meaningful recovery.',
        assisted_ventilation: 'TREATMENT_DECISION',
        assisted_ventilation_instruction: 'Use only if reasonable prospect of recovery.',
        artificial_nutrition: 'CANT_DECIDE',
        antibiotics:                      'CONSENT',
        blood_transfusion:                'REFUSE',
        blood_transfusion_instruction:    'Religious objection to transfusion.',
      },
    });
    printResult('POST /user/ahd (QLD LST ATTORNEY_DECISION)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'ATTORNEY_DECISION';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
    console.log(`    \x1b[36m?\x1b[0m blood_transfusion: ${d?.life_sustaining_treatment?.blood_transfusion}`);
  }

  // ── 4. Other health directions (QLD-specific) ──────────────────────
  printSection('Scenario 4: Other health directions (QLD-specific)');
  {
    const res = await request('POST', '/user/ahd', {
      other_health_directions: [
        {
          health_condition: 'If I develop advanced dementia',
          health_direction: 'Refuse all treatment except palliative care.',
        },
        {
          health_condition: 'If I have a stroke with severe brain damage',
          health_direction: 'Withdraw all life-sustaining treatment within 72 hours.',
        },
      ],
    });
    printResult('POST /user/ahd (QLD other_health_directions)', res, 200);
    const d = res.body?.data;
    const ok = Array.isArray(d?.other_health_directions) && d.other_health_directions.length >= 2;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} other_health_directions count: ${d?.other_health_directions?.length ?? 0}`);
  }

  // ── 5. CPR ────────────────────────────────────────────────────────────
  printSection('Scenario 5: CPR and resuscitation');
  {
    const res = await request('POST', '/user/ahd', {
      cpr_and_resuscitation: {
        cpr_instruction: 'UNBEARABLE',
        medical_not_expected_to_recover: 'REJECT_CPR',
        cpr_resuscitation: 'REFUSE',
        cpr_resuscitation_instruction:   'DNAR order to be documented.',
        cpr_consent: 'ALLOW_TO_DIE',
        cpr_consent_instruction:         'No resuscitation under any circumstances.',
      },
    });
    printResult('POST /user/ahd (QLD CPR REFUSE)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 6. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 6: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      is_registered_australian_organ_donor: true,
      organ_and_body_donation: {
        donate_organ:               true,
        organ_donation_instruction: 'Heart and kidneys preferred.',
        consent_organ_donation:     true,
        donate_body:                false,
        consent_body_donation:      false,
      },
    });
    printResult('POST /user/ahd (QLD organ donation)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_and_body_donation?.donate_organ === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} donate_organ: ${d?.organ_and_body_donation?.donate_organ}`);
    console.log(`    \x1b[36m?\x1b[0m donate_body: ${d?.organ_and_body_donation?.donate_body}`);
  }

  // ── 7. Treatment decisions ────────────────────────────────────────────
  printSection('Scenario 7: Treatment decisions');
  {
    const res = await request('POST', '/user/ahd', {
      treatment_decisions: {
        life_sustaining_treatment: 'REFUSE_ALL_TREATMENT',
        artificial_hydration:                      'CONSENT',
        artificial_hydration_instruction:          'Oral hydration preferred; IV if needed.',
        consent_palliative_comfort_care:           'CONSENT',
        specific_treatment_no_consent: 'ARTIFICIAL_FEEDING',
        specific_treatment_no_consent_instruction: 'No experimental treatments.',
        healthcare_preferred:                      'Princess Alexandra Hospital Brisbane preferred.',
      },
    });
    printResult('POST /user/ahd (QLD treatment decisions)', res, 200);
    const d = res.body?.data;
    const ok = d?.treatment_decisions?.life_sustaining_treatment != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} treatment_decisions.life_sustaining_treatment: ${d?.treatment_decisions?.life_sustaining_treatment}`);
  }

  // ── 8. AHD persons ────────────────────────────────────────────────────
  printSection('Scenario 8: AHD persons (SDM + enduring guardian + witness + attorney health matters)');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: true,
      ahd_persons: [
        {
          full_name:   'Thomas Hughes',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone:       '0755551234',
          address:     '10 George Street, Brisbane QLD 4000',
        },
        {
          full_name:   'Rachel Green',
          person_type: 'ENDURING_GUARDIAN',
          phone:       '0766664321',
          address:     '88 Queen Street, Brisbane QLD 4000',
        },
        {
          full_name:   'Dr. Paul Carter',
          person_type: 'WITNESS_MEDICAL_PRACTITIONER',
          phone:       '0777771234',
          address:     '240 Roma Street, Brisbane QLD 4000',
          other: {
            qualification: 'Specialist Physician',
          },
        },
        {
          full_name: 'Mark Davies',
          person_type: 'ATTORNEY_HEALTH_MATTERS',
          phone: '0788881234',
          address: '50 Eagle Street, Brisbane QLD 4000',
        },
        {
          full_name:    'Dr. Lisa Wong',
          person_type:  'DOCTOR',
          phone:        '+61 432111222',
          dob:          '1975-08-22',
          address:      '100 Wickham Terrace, Brisbane QLD 4000',
          suburb:       'Spring Hill',
          state:        'queensland',
          postcode:     '4000',
          other: {
            facility_name: 'Brisbane Private Hospital',
          },
        },
      ],
    });
    printResult('POST /user/ahd (QLD ahd_persons x5)', res, 200);
    const persons = res.body?.data?.ahd_persons ?? [];
    const hasSdm    = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const hasDoctor = Array.isArray(persons) && persons.some((p) => p.person_type === 'DOCTOR');
    const doctor    = persons.find((p) => p.person_type === 'DOCTOR');
    console.log(`    ${hasSdm    ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    console.log(`    ${hasDoctor ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} DOCTOR present`);
    console.log(`    ${doctor?.dob ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} DOCTOR dob: ${doctor?.dob ?? 'MISSING'}`);
    console.log(`    ${doctor?.state ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} DOCTOR state: ${doctor?.state ?? 'MISSING'}`);
    console.log(`    ${doctor?.postcode ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} DOCTOR postcode: ${doctor?.postcode ?? 'MISSING'}`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 9. Attorney and advice ────────────────────────────────────────────
  printSection('Scenario 9: Attorney and advice');
  {
    const res = await request('POST', '/user/ahd', {
      attorney_and_advice: {
        attorney_decision_power: 'MAJORITY',
        attorney_decision_power_detail: 'Majority decision among appointed attorneys.',
      },
    });
    printResult('POST /user/ahd (QLD attorney_and_advice)', res, 200);
    const d = res.body?.data;
    const ok = d?.attorney_and_advice?.attorney_decision_power === 'MAJORITY';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_decision_power: ${d?.attorney_and_advice?.attorney_decision_power}`);
  }

  // ── 10. Declarations and wishes ───────────────────────────────────────
  printSection('Scenario 10: Declarations and wishes');
  {
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I provide this directive freely and voluntarily.',
        what_matter_most:                          'Quality of life over quantity.',
        what_worries_most:                         'Being a burden on my family.',
        unacceptable_medical_treatment_outcome:    'Permanent loss of consciousness.',
        cultural_request:                          'ANZAC traditions and burial in Queensland.',
        religious_beliefs:                         'Anglican, no last rites required.',
        after_death_importance:                    'Cremation and scatter ashes at sea.',
        nearing_death_instruction:                 'Play jazz music; family to hold my hand.',
      },
    });
    printResult('POST /user/ahd (QLD declarations)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes.declaration persisted`);
  }

  // ── 11. ACD revoked ───────────────────────────────────────────────────
  printSection('Scenario 11: ACD revoked flag');
  {
    const res = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2027-06-30',
    });
    printResult('POST /user/ahd (QLD is_acd_revoked)', res, 200);
    const d = res.body?.data;
    const ok = d?.is_acd_revoked === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_acd_revoked: ${d?.is_acd_revoked}`);
  }

  // ── 12. GET round-trip ─────────────────────────────────────────────────
  printSection('Scenario 12: GET round-trip — stored value assertions');
  {
    const res = await request('GET', '/user/ahd');
    printResult('GET  /user/ahd', res, 200);
    const d = res.body?.data;

    // ── Top-level flags ──────────────────────────────────────────────────
    console.log('  \x1b[1mTop-level flags\x1b[0m');
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked ?? 'MISSING'}`);
    const expiryOk = d?.acd_expiry_date === '2027-06-30';
    console.log(`    ${expiryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} acd_expiry_date === '2027-06-30': ${d?.acd_expiry_date ?? 'MISSING'}`);
    const guardianOk = d?.is_enduring_guardian_appointed === true;
    console.log(`    ${guardianOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === true: ${d?.is_enduring_guardian_appointed ?? 'MISSING'}`);
    const organDonorOk = d?.is_registered_australian_organ_donor === true;
    console.log(`    ${organDonorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_registered_australian_organ_donor === true: ${d?.is_registered_australian_organ_donor ?? 'MISSING'}`);

    // ── health_conditions (scenario 1) ───────────────────────────────────
    console.log('  \x1b[1mhealth_conditions\x1b[0m');
    const hc = d?.health_conditions;
    const hc1Ok = hc?.major_health_conditions === 'Chronic kidney disease, stage 3';
    console.log(`    ${hc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} major_health_conditions === 'Chronic kidney disease, stage 3': ${hc?.major_health_conditions ?? 'MISSING'}`);
    const hc2Ok = hc?.things_important_for_me === 'Staying at home with my dogs';
    console.log(`    ${hc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} things_important_for_me === 'Staying at home with my dogs': ${hc?.things_important_for_me ?? 'MISSING'}`);
    const hc3Ok = hc?.beliefs_considered_during_health_care === 'I believe in natural end-of-life processes';
    console.log(`    ${hc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} beliefs_considered_during_health_care === 'I believe in natural end-of-life processes': ${hc?.beliefs_considered_during_health_care ?? 'MISSING'}`);
    const hc4Ok = hc?.nearing_death_preference === 'No heroic measures; comfort only';
    console.log(`    ${hc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_preference === 'No heroic measures; comfort only': ${hc?.nearing_death_preference ?? 'MISSING'}`);
    const hc5Ok = hc?.people_not_to_involve_healthcare_discussion === 'My son Peter';
    console.log(`    ${hc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} people_not_to_involve_healthcare_discussion === 'My son Peter': ${hc?.people_not_to_involve_healthcare_discussion ?? 'MISSING'}`);
    const hc6Ok = Array.isArray(hc?.comfort_nearing_death) && hc.comfort_nearing_death.includes('LOVED_ONES_NEARBY');
    console.log(`    ${hc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death includes 'LOVED_ONES_NEARBY': ${JSON.stringify(hc?.comfort_nearing_death) ?? 'MISSING'}`);
    const hc7Ok = Array.isArray(hc?.comfort_nearing_death) && hc.comfort_nearing_death.length >= 3;
    console.log(`    ${hc7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death length >= 3: ${hc?.comfort_nearing_death?.length ?? 'MISSING'}`);

    // ── life_sustaining_treatment (scenario 3 overwrites 2) ──────────────
    console.log('  \x1b[1mlife_sustaining_treatment\x1b[0m');
    const lst = d?.life_sustaining_treatment;
    const lst1Ok = lst?.direction_type === 'ATTORNEY_DECISION';
    console.log(`    ${lst1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_type === 'ATTORNEY_DECISION': ${lst?.direction_type ?? 'MISSING'}`);
    const lst2Ok = lst?.direction_instruction === 'Attorney decides based on circumstances.';
    console.log(`    ${lst2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_instruction === 'Attorney decides based on circumstances.': ${lst?.direction_instruction ?? 'MISSING'}`);
    const lstTtOk = lst?.treatment_type === 'CIRCUMSTANCE';
    console.log(`    ${lstTtOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_type === 'CIRCUMSTANCE': ${lst?.treatment_type ?? 'MISSING'}`);
    const lstTiOk = lst?.treatment_instruction === 'Treat only if prospect of meaningful recovery.';
    console.log(`    ${lstTiOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_instruction === 'Treat only if prospect of meaningful recovery.': ${lst?.treatment_instruction ?? 'MISSING'}`);
    const lst3Ok = lst?.assisted_ventilation === 'TREATMENT_DECISION';
    console.log(`    ${lst3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation === 'TREATMENT_DECISION': ${lst?.assisted_ventilation ?? 'MISSING'}`);
    const lst4Ok = lst?.assisted_ventilation_instruction === 'Use only if reasonable prospect of recovery.';
    console.log(`    ${lst4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation_instruction === 'Use only if reasonable prospect of recovery.': ${lst?.assisted_ventilation_instruction ?? 'MISSING'}`);
    const lst5Ok = lst?.artificial_nutrition === 'CANT_DECIDE';
    console.log(`    ${lst5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition === 'CANT_DECIDE': ${lst?.artificial_nutrition ?? 'MISSING'}`);
    const lst6Ok = lst?.antibiotics === 'CONSENT';
    console.log(`    ${lst6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} antibiotics === 'CONSENT': ${lst?.antibiotics ?? 'MISSING'}`);
    const lst7Ok = lst?.blood_transfusion === 'REFUSE';
    console.log(`    ${lst7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion === 'REFUSE': ${lst?.blood_transfusion ?? 'MISSING'}`);
    const lst8Ok = lst?.blood_transfusion_instruction === 'Religious objection to transfusion.';
    console.log(`    ${lst8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion_instruction === 'Religious objection to transfusion.': ${lst?.blood_transfusion_instruction ?? 'MISSING'}`);

    // ── cpr_and_resuscitation (scenario 4) ───────────────────────────────
    console.log('  \x1b[1mcpr_and_resuscitation\x1b[0m');
    const cpr = d?.cpr_and_resuscitation;
    const cpr1Ok = cpr?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${cpr1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_instruction === 'UNBEARABLE': ${cpr?.cpr_instruction ?? 'MISSING'}`);
    const cpr2Ok = cpr?.medical_not_expected_to_recover === 'REJECT_CPR';
    console.log(`    ${cpr2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} medical_not_expected_to_recover === 'REJECT_CPR': ${cpr?.medical_not_expected_to_recover ?? 'MISSING'}`);
    const cpr3Ok = cpr?.cpr_resuscitation === 'REFUSE';
    console.log(`    ${cpr3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation === 'REFUSE': ${cpr?.cpr_resuscitation ?? 'MISSING'}`);
    const cpr4Ok = cpr?.cpr_resuscitation_instruction === 'DNAR order to be documented.';
    console.log(`    ${cpr4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation_instruction === 'DNAR order to be documented.': ${cpr?.cpr_resuscitation_instruction ?? 'MISSING'}`);
    const cpr5Ok = cpr?.cpr_consent === 'ALLOW_TO_DIE';
    console.log(`    ${cpr5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent === 'ALLOW_TO_DIE': ${cpr?.cpr_consent ?? 'MISSING'}`);
    const cpr6Ok = cpr?.cpr_consent_instruction === 'No resuscitation under any circumstances.';
    console.log(`    ${cpr6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent_instruction === 'No resuscitation under any circumstances.': ${cpr?.cpr_consent_instruction ?? 'MISSING'}`);

    // ── organ_and_body_donation (scenario 5) ─────────────────────────────
    console.log('  \x1b[1morgan_and_body_donation\x1b[0m');
    const organ = d?.organ_and_body_donation;
    const org1Ok = organ?.donate_organ === true;
    console.log(`    ${org1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_organ === true: ${organ?.donate_organ ?? 'MISSING'}`);
    const org2Ok = organ?.organ_donation_instruction === 'Heart and kidneys preferred.';
    console.log(`    ${org2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_donation_instruction === 'Heart and kidneys preferred.': ${organ?.organ_donation_instruction ?? 'MISSING'}`);
    const org3Ok = organ?.consent_organ_donation === true;
    console.log(`    ${org3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_organ_donation === true: ${organ?.consent_organ_donation ?? 'MISSING'}`);
    const org4Ok = organ?.donate_body === false;
    console.log(`    ${org4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_body === false: ${organ?.donate_body ?? 'MISSING'}`);
    const org5Ok = organ?.consent_body_donation === false;
    console.log(`    ${org5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_body_donation === false: ${organ?.consent_body_donation ?? 'MISSING'}`);

    // ── treatment_decisions (scenario 6) ─────────────────────────────────
    console.log('  \x1b[1mtreatment_decisions\x1b[0m');
    const td = d?.treatment_decisions;
    const td1Ok = td?.life_sustaining_treatment === 'REFUSE_ALL_TREATMENT';
    console.log(`    ${td1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment === 'REFUSE_ALL_TREATMENT': ${td?.life_sustaining_treatment ?? 'MISSING'}`);
    const td2Ok = td?.artificial_hydration === 'CONSENT';
    console.log(`    ${td2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration === 'CONSENT': ${td?.artificial_hydration ?? 'MISSING'}`);
    const td3Ok = td?.artificial_hydration_instruction === 'Oral hydration preferred; IV if needed.';
    console.log(`    ${td3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration_instruction === 'Oral hydration preferred; IV if needed.': ${td?.artificial_hydration_instruction ?? 'MISSING'}`);
    const td4Ok = td?.consent_palliative_comfort_care === 'CONSENT';
    console.log(`    ${td4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_palliative_comfort_care === 'CONSENT': ${td?.consent_palliative_comfort_care ?? 'MISSING'}`);
    const td5Ok = td?.specific_treatment_no_consent === 'ARTIFICIAL_FEEDING';
    console.log(`    ${td5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent === 'ARTIFICIAL_FEEDING': ${td?.specific_treatment_no_consent ?? 'MISSING'}`);
    const td6Ok = td?.specific_treatment_no_consent_instruction === 'No experimental treatments.';
    console.log(`    ${td6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent_instruction === 'No experimental treatments.': ${td?.specific_treatment_no_consent_instruction ?? 'MISSING'}`);
    const td7Ok = td?.healthcare_preferred === 'Princess Alexandra Hospital Brisbane preferred.';
    console.log(`    ${td7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} healthcare_preferred === 'Princess Alexandra Hospital Brisbane preferred.': ${td?.healthcare_preferred ?? 'MISSING'}`);

    // ── ahd_persons (scenario 7) ─────────────────────────────────────────
    console.log('  \x1b[1mahd_persons\x1b[0m');
    const persons = d?.ahd_persons ?? [];
    const personsCountOk = Array.isArray(persons) && persons.length >= 5;
    console.log(`    ${personsCountOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ahd_persons count >= 5: ${Array.isArray(persons) ? persons.length : 'MISSING'}`);

    // Person 1 — SUBSTITUTE_DECISION_MAKER
    console.log('    \x1b[1mPerson 1: SUBSTITUTE_DECISION_MAKER\x1b[0m');
    const sdm = Array.isArray(persons) && persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const sdm1Ok = sdm?.full_name === 'Thomas Hughes';
    console.log(`    ${sdm1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Thomas Hughes': ${sdm?.full_name ?? 'MISSING'}`);
    const sdm2Ok = sdm?.phone === '0755551234';
    console.log(`    ${sdm2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0755551234': ${sdm?.phone ?? 'MISSING'}`);
    const sdm3Ok = sdm?.address === '10 George Street, Brisbane QLD 4000';
    console.log(`    ${sdm3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '10 George Street, Brisbane QLD 4000': ${sdm?.address ?? 'MISSING'}`);

    // Person 2 — ENDURING_GUARDIAN
    console.log('    \x1b[1mPerson 2: ENDURING_GUARDIAN\x1b[0m');
    const eg = Array.isArray(persons) && persons.find((p) => p.person_type === 'ENDURING_GUARDIAN');
    const eg1Ok = eg?.full_name === 'Rachel Green';
    console.log(`    ${eg1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Rachel Green': ${eg?.full_name ?? 'MISSING'}`);
    const eg2Ok = eg?.phone === '0766664321';
    console.log(`    ${eg2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0766664321': ${eg?.phone ?? 'MISSING'}`);
    const eg3Ok = eg?.address === '88 Queen Street, Brisbane QLD 4000';
    console.log(`    ${eg3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '88 Queen Street, Brisbane QLD 4000': ${eg?.address ?? 'MISSING'}`);

    // Person 3 — WITNESS_MEDICAL_PRACTITIONER
    console.log('    \x1b[1mPerson 3: WITNESS_MEDICAL_PRACTITIONER\x1b[0m');
    const wmp = Array.isArray(persons) && persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const wmp1Ok = wmp?.full_name === 'Dr. Paul Carter';
    console.log(`    ${wmp1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Dr. Paul Carter': ${wmp?.full_name ?? 'MISSING'}`);
    const wmp2Ok = wmp?.phone === '0777771234';
    console.log(`    ${wmp2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0777771234': ${wmp?.phone ?? 'MISSING'}`);
    const wmp3Ok = wmp?.address === '240 Roma Street, Brisbane QLD 4000';
    console.log(`    ${wmp3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '240 Roma Street, Brisbane QLD 4000': ${wmp?.address ?? 'MISSING'}`);
    const wmp4Ok = wmp?.other?.qualification === 'Specialist Physician';
    console.log(`    ${wmp4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.qualification === 'Specialist Physician': ${wmp?.other?.qualification ?? 'MISSING'}`);

    // Person 4 — DOCTOR
    console.log('    \x1b[1mPerson 4: DOCTOR\x1b[0m');
    const doctor = Array.isArray(persons) && persons.find((p) => p.person_type === 'DOCTOR');
    const doc1Ok = doctor?.full_name === 'Dr. Lisa Wong';
    console.log(`    ${doc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Dr. Lisa Wong': ${doctor?.full_name ?? 'MISSING'}`);
    const doc2Ok = doctor?.phone === '+61 432111222';
    console.log(`    ${doc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '+61 432111222': ${doctor?.phone ?? 'MISSING'}`);
    const doc3Ok = doctor?.dob === '1975-08-22';
    console.log(`    ${doc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} dob === '1975-08-22': ${doctor?.dob ?? 'MISSING'}`);
    const doc4Ok = doctor?.address === '100 Wickham Terrace, Brisbane QLD 4000';
    console.log(`    ${doc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '100 Wickham Terrace, Brisbane QLD 4000': ${doctor?.address ?? 'MISSING'}`);
    const doc5Ok = doctor?.suburb === 'Spring Hill';
    console.log(`    ${doc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} suburb === 'Spring Hill': ${doctor?.suburb ?? 'MISSING'}`);
    const doc6Ok = doctor?.state === 'queensland';
    console.log(`    ${doc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} state === 'queensland': ${doctor?.state ?? 'MISSING'}`);
    const doc7Ok = doctor?.postcode === '4000';
    console.log(`    ${doc7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} postcode === '4000': ${doctor?.postcode ?? 'MISSING'}`);
    const doc8Ok = doctor?.other?.facility_name === 'Brisbane Private Hospital';
    console.log(`    ${doc8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.facility_name === 'Brisbane Private Hospital': ${doctor?.other?.facility_name ?? 'MISSING'}`);

    // Person 5 — ATTORNEY_HEALTH_MATTERS
    console.log('    \x1b[1mPerson 5: ATTORNEY_HEALTH_MATTERS\x1b[0m');
    const ahm = Array.isArray(persons) && persons.find((p) => p.person_type === 'ATTORNEY_HEALTH_MATTERS');
    const ahm1Ok = ahm?.full_name === 'Mark Davies';
    console.log(`    ${ahm1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Mark Davies': ${ahm?.full_name ?? 'MISSING'}`);
    const ahm2Ok = ahm?.phone === '0788881234';
    console.log(`    ${ahm2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0788881234': ${ahm?.phone ?? 'MISSING'}`);
    const ahm3Ok = ahm?.address === '50 Eagle Street, Brisbane QLD 4000';
    console.log(`    ${ahm3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '50 Eagle Street, Brisbane QLD 4000': ${ahm?.address ?? 'MISSING'}`);

    // ── other_health_directions (scenario 4) ────────────────────────────
    console.log('  \x1b[1mother_health_directions\x1b[0m');
    const ohd = d?.other_health_directions;
    const ohd1Ok = Array.isArray(ohd) && ohd.length >= 2;
    console.log(`    ${ohd1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_health_directions length >= 2: ${ohd?.length ?? 'MISSING'}`);
    const ohd2Ok = ohd?.[0]?.health_condition === 'If I develop advanced dementia';
    console.log(`    ${ohd2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} [0].health_condition === 'If I develop advanced dementia': ${ohd?.[0]?.health_condition ?? 'MISSING'}`);
    const ohd3Ok = ohd?.[0]?.health_direction === 'Refuse all treatment except palliative care.';
    console.log(`    ${ohd3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} [0].health_direction === 'Refuse all treatment except palliative care.': ${ohd?.[0]?.health_direction ?? 'MISSING'}`);

    // ── attorney_and_advice (scenario 9) ────────────────────────────────
    console.log('  \x1b[1mattorney_and_advice\x1b[0m');
    const aa = d?.attorney_and_advice;
    const aa1Ok = aa?.attorney_decision_power === 'MAJORITY';
    console.log(`    ${aa1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} attorney_decision_power === 'MAJORITY': ${aa?.attorney_decision_power ?? 'MISSING'}`);
    const aa2Ok = aa?.attorney_decision_power_detail === 'Majority decision among appointed attorneys.';
    console.log(`    ${aa2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} attorney_decision_power_detail === 'Majority decision among appointed attorneys.': ${aa?.attorney_decision_power_detail ?? 'MISSING'}`);

    // ── declarations_and_wishes (scenario 10) ────────────────────────────
    console.log('  \x1b[1mdeclarations_and_wishes\x1b[0m');
    const dw = d?.declarations_and_wishes;
    const dw1Ok = dw?.declaration === 'I provide this directive freely and voluntarily.';
    console.log(`    ${dw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declaration === 'I provide this directive freely and voluntarily.': ${dw?.declaration ?? 'MISSING'}`);
    const dw2Ok = dw?.what_matter_most === 'Quality of life over quantity.';
    console.log(`    ${dw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_matter_most === 'Quality of life over quantity.': ${dw?.what_matter_most ?? 'MISSING'}`);
    const dw3Ok = dw?.what_worries_most === 'Being a burden on my family.';
    console.log(`    ${dw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_worries_most === 'Being a burden on my family.': ${dw?.what_worries_most ?? 'MISSING'}`);
    const dw4Ok = dw?.unacceptable_medical_treatment_outcome === 'Permanent loss of consciousness.';
    console.log(`    ${dw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} unacceptable_medical_treatment_outcome === 'Permanent loss of consciousness.': ${dw?.unacceptable_medical_treatment_outcome ?? 'MISSING'}`);
    const dw5Ok = dw?.cultural_request === 'ANZAC traditions and burial in Queensland.';
    console.log(`    ${dw5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cultural_request === 'ANZAC traditions and burial in Queensland.': ${dw?.cultural_request ?? 'MISSING'}`);
    const dw6Ok = dw?.religious_beliefs === 'Anglican, no last rites required.';
    console.log(`    ${dw6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} religious_beliefs === 'Anglican, no last rites required.': ${dw?.religious_beliefs ?? 'MISSING'}`);
    const dw7Ok = dw?.after_death_importance === 'Cremation and scatter ashes at sea.';
    console.log(`    ${dw7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} after_death_importance === 'Cremation and scatter ashes at sea.': ${dw?.after_death_importance ?? 'MISSING'}`);
    const dw8Ok = dw?.nearing_death_instruction === 'Play jazz music; family to hold my hand.';
    console.log(`    ${dw8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_instruction === 'Play jazz music; family to hold my hand.': ${dw?.nearing_death_instruction ?? 'MISSING'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
