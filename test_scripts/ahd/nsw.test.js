/**
 * AHD Integration Tests — New South Wales (NSW)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — REFUSE
 *  4. Quality-of-life tolerance (NSW-specific)
 *  5. CPR and resuscitation
 *  6. Organ and body donation
 *  7. Treatment decisions
 *  8. AHD persons — SDM + witness
 *  9. Declarations and wishes
 * 10. ACD revoked + GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/nsw.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — New South Wales (NSW)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Advanced COPD, heart failure',
        things_important_for_me:                     'Breathing comfortably; staying at home',
        beliefs_considered_during_health_care:       'I prioritise quality over quantity of life',
        nearing_death_preference:                    'Palliative care; hospice if necessary',
        people_not_to_involve_healthcare_discussion: 'No restrictions',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'MANAGED_SYMPTOMS', 'CULTURAL_RELIGIOUS'],
      },
    });
    printResult('POST /user/ahd (NSW minimal)', res, 200);
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
    printResult('POST /user/ahd (NSW LST CONSENT)', res, 200);
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
        direction_instruction:            'Refuse all treatment beyond comfort care.',
        assisted_ventilation:             'REFUSE',
        assisted_ventilation_instruction: 'No mechanical ventilation.',
        artificial_nutrition:             'REFUSE',
        artificial_nutrition_instruction: 'No PEG feeding.',
        antibiotics: 'CANT_DECIDE',
        blood_transfusion:                'CONSENT',
        other_treatment: 'CANT_DECIDE',
        other_instruction:                'No dialysis.',
      },
    });
    printResult('POST /user/ahd (NSW LST REFUSE)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'REFUSE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
  }

  // ── 4. Quality-of-life tolerance (NSW-specific) ────────────────────────
  printSection('Scenario 4: Quality-of-life tolerance (NSW-specific)');
  {
    const res = await request('POST', '/user/ahd', {
      quality_of_life_tolerance: {
        no_longer_recognise_family: 'UNBEARABLE',
        no_bladder_control: 'BEARABLE',
        cant_feed_wash_dress: 'UNBEARABLE',
        rely_people_for_movement: 'BEARABLE',
        need_life_tube_for_food: 'UNBEARABLE',
        cant_converse_with_people: 'UNBEARABLE',
      },
    });
    printResult('POST /user/ahd (NSW quality_of_life_tolerance)', res, 200);
    const d = res.body?.data;
    const ok = d?.quality_of_life_tolerance?.no_longer_recognise_family != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} quality_of_life_tolerance.no_longer_recognise_family: ${d?.quality_of_life_tolerance?.no_longer_recognise_family}`);
    console.log(`    \x1b[36m?\x1b[0m cant_feed_wash_dress: ${d?.quality_of_life_tolerance?.cant_feed_wash_dress}`);
    console.log(`    \x1b[36m?\x1b[0m need_life_tube_for_food: ${d?.quality_of_life_tolerance?.need_life_tube_for_food}`);
  }

  // ── 5. CPR and resuscitation ──────────────────────────────────────────
  printSection('Scenario 5: CPR and resuscitation');
  {
    const res = await request('POST', '/user/ahd', {
      cpr_and_resuscitation: {
        cpr_instruction: 'UNSURE',
        medical_not_expected_to_recover: 'REJECT_CPR',
        cpr_resuscitation: 'CANT_DECIDE',
        cpr_resuscitation_instruction:   'Attorney decides based on prognosis.',
        cpr_consent: 'ALLOW_TO_DIE',
        cpr_consent_instruction:         'No resuscitation if irreversible brain damage.',
      },
    });
    printResult('POST /user/ahd (NSW CPR)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNSURE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 6. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 6: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      is_registered_australian_organ_donor: true,
      organ_and_body_donation: {
        donate_organ:               true,
        organ_donation_instruction: 'All suitable organs.',
        consent_organ_donation:     true,
        donate_body:                true,
        consent_body_donation:      true,
        authorisation:              'Authorise for anatomical/medical education.',
      },
    });
    printResult('POST /user/ahd (NSW organ donation)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_and_body_donation?.donate_organ === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} donate_organ: ${d?.organ_and_body_donation?.donate_organ}`);
  }

  // ── 7. Treatment decisions ────────────────────────────────────────────
  printSection('Scenario 7: Treatment decisions');
  {
    const res = await request('POST', '/user/ahd', {
      treatment_decisions: {
        life_sustaining_treatment: 'CANT_DECIDE',
        artificial_hydration:                       'CONSENT',
        artificial_hydration_instruction:           'IV fluids acceptable for comfort.',
        other_medical_support:                      'RENAL_DIALYSIS',
        other_medical_support_instruction:          'Only if expected full recovery.',
        consent_palliative_comfort_care:            'CONSENT',
        specific_treatment_no_consent: 'ARTIFICIAL_FEEDING',
        specific_treatment_no_consent_instruction:  'No experimental treatments.',
        healthcare_preferred:                       'Royal Prince Alfred Hospital preferred.',
      },
    });
    printResult('POST /user/ahd (NSW treatment decisions)', res, 200);
    const d = res.body?.data;
    const ok = d?.treatment_decisions?.life_sustaining_treatment != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} treatment_decisions stored`);
  }

  // ── 8. AHD persons ────────────────────────────────────────────────────
  printSection('Scenario 8: AHD persons — SDM + medical witness');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: true,
      ahd_persons: [
        {
          full_name:   'Susan Parker',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone:       '0211231234',
          address:     '5 Bridge Street, Sydney NSW 2000',
        },
        {
          full_name:    'Dr. Michael Chen',
          person_type:  'WITNESS_MEDICAL_PRACTITIONER',
          qualification: 'Geriatrician',
          phone:         '0299998888',
          address:       '150 Macquarie Street, Sydney NSW 2000',
        },
        {
          full_name:   'John Parker',
          person_type: 'ENDURING_GUARDIAN',
          phone:       '0211235555',
          address:     '5 Bridge Street, Sydney NSW 2000',
        },
        {
          full_name:   'Dr. Rebecca Liu',
          person_type: 'MEDICAL_GUARDIAN',
          phone:       '0299997777',
          address:     '250 George Street, Sydney NSW 2000',
        },
      ],
    });
    printResult('POST /user/ahd (NSW ahd_persons)', res, 200);
    const persons = res.body?.data?.ahd_persons ?? [];
    const hasSdm = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    console.log(`    ${hasSdm ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 9. Declarations and wishes ────────────────────────────────────────
  printSection('Scenario 9: Declarations and wishes');
  {
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I make this decision of my own free will.',
        what_matter_most:                          'Dignity and freedom from pain.',
        what_worries_most:                         'Prolonged suffering.',
        unacceptable_medical_treatment_outcome:    'Vegetative state or severe dementia.',
        cultural_request:                          'No specific cultural requirements.',
        religious_beliefs:                         'None.',
        after_death_importance:                    'Cremation.',
        nearing_death_instruction:                 'Notify family immediately.',
      },
    });
    printResult('POST /user/ahd (NSW declarations)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes persisted`);
  }

  // ── 10. ACD revoked + GET round-trip ──────────────────────────────────
  printSection('Scenario 10: ACD revoked + GET round-trip');
  {
    const revRes = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2026-03-31',
    });
    printResult('POST /user/ahd (NSW is_acd_revoked)', revRes, 200);
    const rd = revRes.body?.data;
    console.log(`    ${rd?.is_acd_revoked === true ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_acd_revoked: ${rd?.is_acd_revoked}`);

    const getRes = await request('GET', '/user/ahd');
    printResult('GET  /user/ahd (round-trip assertions)', getRes, 200);
    const d = getRes.body?.data;

    // ── Top-level flags ──
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked}`);
    const expiryOk = d?.acd_expiry_date === '2026-03-31';
    console.log(`    ${expiryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} acd_expiry_date === '2026-03-31': ${d?.acd_expiry_date ?? 'MISSING'}`);
    const egOk = d?.is_enduring_guardian_appointed === true;
    console.log(`    ${egOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === true: ${d?.is_enduring_guardian_appointed}`);
    const organDonorOk = d?.is_registered_australian_organ_donor === true;
    console.log(`    ${organDonorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_registered_australian_organ_donor === true: ${d?.is_registered_australian_organ_donor}`);

    // ── Health conditions (scenario 1) ──
    const hc = d?.health_conditions;
    const hc1Ok = hc?.major_health_conditions === 'Advanced COPD, heart failure';
    console.log(`    ${hc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_conditions.major_health_conditions === 'Advanced COPD, heart failure': ${hc?.major_health_conditions ?? 'MISSING'}`);
    const hc2Ok = hc?.things_important_for_me === 'Breathing comfortably; staying at home';
    console.log(`    ${hc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_conditions.things_important_for_me === 'Breathing comfortably; staying at home': ${hc?.things_important_for_me ?? 'MISSING'}`);
    const hc3Ok = hc?.beliefs_considered_during_health_care === 'I prioritise quality over quantity of life';
    console.log(`    ${hc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_conditions.beliefs_considered_during_health_care === 'I prioritise quality over quantity of life': ${hc?.beliefs_considered_during_health_care ?? 'MISSING'}`);
    const hc4Ok = hc?.nearing_death_preference === 'Palliative care; hospice if necessary';
    console.log(`    ${hc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_conditions.nearing_death_preference === 'Palliative care; hospice if necessary': ${hc?.nearing_death_preference ?? 'MISSING'}`);
    const hc5Ok = hc?.people_not_to_involve_healthcare_discussion === 'No restrictions';
    console.log(`    ${hc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_conditions.people_not_to_involve_healthcare_discussion === 'No restrictions': ${hc?.people_not_to_involve_healthcare_discussion ?? 'MISSING'}`);
    const comfortVal = JSON.stringify(hc?.comfort_nearing_death);
    const hc6Ok = Array.isArray(hc?.comfort_nearing_death) && hc?.comfort_nearing_death?.includes('LOVED_ONES_NEARBY');
    console.log(`    ${hc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_conditions.comfort_nearing_death includes 'LOVED_ONES_NEARBY': ${comfortVal ?? 'MISSING'}`);
    const hc7Ok = Array.isArray(hc?.comfort_nearing_death) && hc?.comfort_nearing_death.length >= 3;
    console.log(`    ${hc7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_conditions.comfort_nearing_death length >= 3: ${hc?.comfort_nearing_death?.length ?? 'MISSING'}`);

    // ── Life sustaining treatment (scenario 3 overwrites 2) ──
    const lst = d?.life_sustaining_treatment;
    const lst1Ok = lst?.direction_type === 'REFUSE';
    console.log(`    ${lst1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.direction_type === 'REFUSE': ${lst?.direction_type ?? 'MISSING'}`);
    const lst2Ok = lst?.direction_instruction === 'Refuse all treatment beyond comfort care.';
    console.log(`    ${lst2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.direction_instruction === 'Refuse all treatment beyond comfort care.': ${lst?.direction_instruction ?? 'MISSING'}`);
    const lst3Ok = lst?.assisted_ventilation === 'REFUSE';
    console.log(`    ${lst3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.assisted_ventilation === 'REFUSE': ${lst?.assisted_ventilation ?? 'MISSING'}`);
    const lst4Ok = lst?.assisted_ventilation_instruction === 'No mechanical ventilation.';
    console.log(`    ${lst4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.assisted_ventilation_instruction === 'No mechanical ventilation.': ${lst?.assisted_ventilation_instruction ?? 'MISSING'}`);
    const lst5Ok = lst?.artificial_nutrition === 'REFUSE';
    console.log(`    ${lst5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.artificial_nutrition === 'REFUSE': ${lst?.artificial_nutrition ?? 'MISSING'}`);
    const lst6Ok = lst?.artificial_nutrition_instruction === 'No PEG feeding.';
    console.log(`    ${lst6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.artificial_nutrition_instruction === 'No PEG feeding.': ${lst?.artificial_nutrition_instruction ?? 'MISSING'}`);
    const lst7Ok = lst?.antibiotics === 'CANT_DECIDE';
    console.log(`    ${lst7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.antibiotics === 'CANT_DECIDE': ${lst?.antibiotics ?? 'MISSING'}`);
    const lst8Ok = lst?.blood_transfusion === 'CONSENT';
    console.log(`    ${lst8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.blood_transfusion === 'CONSENT': ${lst?.blood_transfusion ?? 'MISSING'}`);
    const lst9Ok = lst?.other_treatment === 'CANT_DECIDE';
    console.log(`    ${lst9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.other_treatment === 'CANT_DECIDE': ${lst?.other_treatment ?? 'MISSING'}`);
    const lst10Ok = lst?.other_instruction === 'No dialysis.';
    console.log(`    ${lst10Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment.other_instruction === 'No dialysis.': ${lst?.other_instruction ?? 'MISSING'}`);

    // ── Quality of life tolerance (scenario 4 - NSW-specific) ──
    const qol = d?.quality_of_life_tolerance;
    const qol1Ok = qol?.no_longer_recognise_family === 'UNBEARABLE';
    console.log(`    ${qol1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} quality_of_life_tolerance.no_longer_recognise_family === 'UNBEARABLE': ${qol?.no_longer_recognise_family ?? 'MISSING'}`);
    const qol2Ok = qol?.no_bladder_control === 'BEARABLE';
    console.log(`    ${qol2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} quality_of_life_tolerance.no_bladder_control === 'BEARABLE': ${qol?.no_bladder_control ?? 'MISSING'}`);
    const qol3Ok = qol?.cant_feed_wash_dress === 'UNBEARABLE';
    console.log(`    ${qol3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} quality_of_life_tolerance.cant_feed_wash_dress === 'UNBEARABLE': ${qol?.cant_feed_wash_dress ?? 'MISSING'}`);
    const qol4Ok = qol?.rely_people_for_movement === 'BEARABLE';
    console.log(`    ${qol4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} quality_of_life_tolerance.rely_people_for_movement === 'BEARABLE': ${qol?.rely_people_for_movement ?? 'MISSING'}`);
    const qol5Ok = qol?.need_life_tube_for_food === 'UNBEARABLE';
    console.log(`    ${qol5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} quality_of_life_tolerance.need_life_tube_for_food === 'UNBEARABLE': ${qol?.need_life_tube_for_food ?? 'MISSING'}`);
    const qol6Ok = qol?.cant_converse_with_people === 'UNBEARABLE';
    console.log(`    ${qol6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} quality_of_life_tolerance.cant_converse_with_people === 'UNBEARABLE': ${qol?.cant_converse_with_people ?? 'MISSING'}`);

    // ── CPR and resuscitation (scenario 5) ──
    const cpr = d?.cpr_and_resuscitation;
    const cpr1Ok = cpr?.cpr_instruction === 'UNSURE';
    console.log(`    ${cpr1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_and_resuscitation.cpr_instruction === 'UNSURE': ${cpr?.cpr_instruction ?? 'MISSING'}`);
    const cpr2Ok = cpr?.medical_not_expected_to_recover === 'REJECT_CPR';
    console.log(`    ${cpr2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_and_resuscitation.medical_not_expected_to_recover === 'REJECT_CPR': ${cpr?.medical_not_expected_to_recover ?? 'MISSING'}`);
    const cpr3Ok = cpr?.cpr_resuscitation === 'CANT_DECIDE';
    console.log(`    ${cpr3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_and_resuscitation.cpr_resuscitation === 'CANT_DECIDE': ${cpr?.cpr_resuscitation ?? 'MISSING'}`);
    const cpr4Ok = cpr?.cpr_resuscitation_instruction === 'Attorney decides based on prognosis.';
    console.log(`    ${cpr4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_and_resuscitation.cpr_resuscitation_instruction === 'Attorney decides based on prognosis.': ${cpr?.cpr_resuscitation_instruction ?? 'MISSING'}`);
    const cpr5Ok = cpr?.cpr_consent === 'ALLOW_TO_DIE';
    console.log(`    ${cpr5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_and_resuscitation.cpr_consent === 'ALLOW_TO_DIE': ${cpr?.cpr_consent ?? 'MISSING'}`);
    const cpr6Ok = cpr?.cpr_consent_instruction === 'No resuscitation if irreversible brain damage.';
    console.log(`    ${cpr6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_and_resuscitation.cpr_consent_instruction === 'No resuscitation if irreversible brain damage.': ${cpr?.cpr_consent_instruction ?? 'MISSING'}`);

    // ── Organ and body donation (scenario 6 - nested for NSW) ──
    const organ = d?.organ_and_body_donation;
    const org1Ok = organ?.donate_organ === true;
    console.log(`    ${org1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_and_body_donation.donate_organ === true: ${organ?.donate_organ}`);
    const org2Ok = organ?.organ_donation_instruction === 'All suitable organs.';
    console.log(`    ${org2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_and_body_donation.organ_donation_instruction === 'All suitable organs.': ${organ?.organ_donation_instruction ?? 'MISSING'}`);
    const org3Ok = organ?.consent_organ_donation === true;
    console.log(`    ${org3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_and_body_donation.consent_organ_donation === true: ${organ?.consent_organ_donation}`);
    const org4Ok = organ?.donate_body === true;
    console.log(`    ${org4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_and_body_donation.donate_body === true: ${organ?.donate_body}`);
    const org5Ok = organ?.consent_body_donation === true;
    console.log(`    ${org5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_and_body_donation.consent_body_donation === true: ${organ?.consent_body_donation}`);
    const org6Ok = organ?.authorisation === 'Authorise for anatomical/medical education.';
    console.log(`    ${org6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_and_body_donation.authorisation === 'Authorise for anatomical/medical education.': ${organ?.authorisation ?? 'MISSING'}`);

    // ── Treatment decisions (scenario 7) ──
    const td = d?.treatment_decisions;
    const td1Ok = td?.life_sustaining_treatment === 'CANT_DECIDE';
    console.log(`    ${td1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.life_sustaining_treatment === 'CANT_DECIDE': ${td?.life_sustaining_treatment ?? 'MISSING'}`);
    const td2Ok = td?.artificial_hydration === 'CONSENT';
    console.log(`    ${td2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.artificial_hydration === 'CONSENT': ${td?.artificial_hydration ?? 'MISSING'}`);
    const td3Ok = td?.artificial_hydration_instruction === 'IV fluids acceptable for comfort.';
    console.log(`    ${td3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.artificial_hydration_instruction === 'IV fluids acceptable for comfort.': ${td?.artificial_hydration_instruction ?? 'MISSING'}`);
    const td4Ok = td?.consent_palliative_comfort_care === 'CONSENT';
    console.log(`    ${td4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.consent_palliative_comfort_care === 'CONSENT': ${td?.consent_palliative_comfort_care ?? 'MISSING'}`);
    const td5Ok = td?.specific_treatment_no_consent === 'ARTIFICIAL_FEEDING';
    console.log(`    ${td5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.specific_treatment_no_consent === 'ARTIFICIAL_FEEDING': ${td?.specific_treatment_no_consent ?? 'MISSING'}`);
    const td6Ok = td?.specific_treatment_no_consent_instruction === 'No experimental treatments.';
    console.log(`    ${td6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.specific_treatment_no_consent_instruction === 'No experimental treatments.': ${td?.specific_treatment_no_consent_instruction ?? 'MISSING'}`);
    const td7Ok = td?.healthcare_preferred === 'Royal Prince Alfred Hospital preferred.';
    console.log(`    ${td7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.healthcare_preferred === 'Royal Prince Alfred Hospital preferred.': ${td?.healthcare_preferred ?? 'MISSING'}`);
    const td8Ok = td?.other_medical_support === 'RENAL_DIALYSIS';
    console.log(`    ${td8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.other_medical_support === 'RENAL_DIALYSIS': ${td?.other_medical_support ?? 'MISSING'}`);
    const td9Ok = td?.other_medical_support_instruction === 'Only if expected full recovery.';
    console.log(`    ${td9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_decisions.other_medical_support_instruction === 'Only if expected full recovery.': ${td?.other_medical_support_instruction ?? 'MISSING'}`);

    // ── Persons (scenario 8) ──
    const persons = d?.ahd_persons ?? [];
    const sdm = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const sdm1Ok = sdm?.full_name === 'Susan Parker';
    console.log(`    ${sdm1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM full_name === 'Susan Parker': ${sdm?.full_name ?? 'MISSING'}`);
    const sdm2Ok = sdm?.phone === '0211231234';
    console.log(`    ${sdm2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM phone === '0211231234': ${sdm?.phone ?? 'MISSING'}`);
    const sdm3Ok = sdm?.address === '5 Bridge Street, Sydney NSW 2000';
    console.log(`    ${sdm3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM address === '5 Bridge Street, Sydney NSW 2000': ${sdm?.address ?? 'MISSING'}`);

    const medWit = persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const mw1Ok = medWit?.full_name === 'Dr. Michael Chen';
    console.log(`    ${mw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER full_name === 'Dr. Michael Chen': ${medWit?.full_name ?? 'MISSING'}`);
    const mwQual = medWit?.qualification || medWit?.other?.qualification;
    const mw2Ok = mwQual === 'Geriatrician';
    console.log(`    ${mw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER qualification === 'Geriatrician': ${mwQual ?? 'MISSING'}`);
    const mw3Ok = medWit?.phone === '0299998888';
    console.log(`    ${mw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER phone === '0299998888': ${medWit?.phone ?? 'MISSING'}`);
    const mw4Ok = medWit?.address === '150 Macquarie Street, Sydney NSW 2000';
    console.log(`    ${mw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER address === '150 Macquarie Street, Sydney NSW 2000': ${medWit?.address ?? 'MISSING'}`);

    const eg = persons.find((p) => p.person_type === 'ENDURING_GUARDIAN');
    const eg1Ok = eg?.full_name === 'John Parker';
    console.log(`    ${eg1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ENDURING_GUARDIAN full_name === 'John Parker': ${eg?.full_name ?? 'MISSING'}`);
    const eg2Ok = eg?.phone === '0211235555';
    console.log(`    ${eg2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ENDURING_GUARDIAN phone === '0211235555': ${eg?.phone ?? 'MISSING'}`);
    const eg3Ok = eg?.address === '5 Bridge Street, Sydney NSW 2000';
    console.log(`    ${eg3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ENDURING_GUARDIAN address === '5 Bridge Street, Sydney NSW 2000': ${eg?.address ?? 'MISSING'}`);

    const mg = persons.find((p) => p.person_type === 'MEDICAL_GUARDIAN');
    const mg1Ok = mg?.full_name === 'Dr. Rebecca Liu';
    console.log(`    ${mg1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} MEDICAL_GUARDIAN full_name === 'Dr. Rebecca Liu': ${mg?.full_name ?? 'MISSING'}`);
    const mg2Ok = mg?.phone === '0299997777';
    console.log(`    ${mg2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} MEDICAL_GUARDIAN phone === '0299997777': ${mg?.phone ?? 'MISSING'}`);
    const mg3Ok = mg?.address === '250 George Street, Sydney NSW 2000';
    console.log(`    ${mg3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} MEDICAL_GUARDIAN address === '250 George Street, Sydney NSW 2000': ${mg?.address ?? 'MISSING'}`);

    const personsOk = persons.length >= 4;
    console.log(`    ${personsOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ahd_persons count >= 4: ${persons.length}`);

    // ── Declarations and wishes (scenario 9) ──
    const dw = d?.declarations_and_wishes;
    const dw1Ok = dw?.declaration === 'I make this decision of my own free will.';
    console.log(`    ${dw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.declaration === 'I make this decision of my own free will.': ${dw?.declaration ?? 'MISSING'}`);
    const dw2Ok = dw?.what_matter_most === 'Dignity and freedom from pain.';
    console.log(`    ${dw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.what_matter_most === 'Dignity and freedom from pain.': ${dw?.what_matter_most ?? 'MISSING'}`);
    const dw3Ok = dw?.what_worries_most === 'Prolonged suffering.';
    console.log(`    ${dw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.what_worries_most === 'Prolonged suffering.': ${dw?.what_worries_most ?? 'MISSING'}`);
    const dw4Ok = dw?.unacceptable_medical_treatment_outcome === 'Vegetative state or severe dementia.';
    console.log(`    ${dw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.unacceptable_medical_treatment_outcome === 'Vegetative state or severe dementia.': ${dw?.unacceptable_medical_treatment_outcome ?? 'MISSING'}`);
    const dw5Ok = dw?.cultural_request === 'No specific cultural requirements.';
    console.log(`    ${dw5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.cultural_request === 'No specific cultural requirements.': ${dw?.cultural_request ?? 'MISSING'}`);
    const dw6Ok = dw?.religious_beliefs === 'None.';
    console.log(`    ${dw6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.religious_beliefs === 'None.': ${dw?.religious_beliefs ?? 'MISSING'}`);
    const dw7Ok = dw?.after_death_importance === 'Cremation.';
    console.log(`    ${dw7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.after_death_importance === 'Cremation.': ${dw?.after_death_importance ?? 'MISSING'}`);
    const dw8Ok = dw?.nearing_death_instruction === 'Notify family immediately.';
    console.log(`    ${dw8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declarations_and_wishes.nearing_death_instruction === 'Notify family immediately.': ${dw?.nearing_death_instruction ?? 'MISSING'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
