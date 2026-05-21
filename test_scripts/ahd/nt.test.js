/**
 * AHD Integration Tests — Northern Territory (NT)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — REFUSE
 *  4. CPR and resuscitation
 *  5. Living preferences (NT-specific)
 *  6. Organ and body donation
 *  7. Treatment decisions
 *  8. AHD persons — SDM + DECISION_MAKER + witness
 *  9. Declarations and wishes
 * 10. ACD revoked + GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/nt.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — Northern Territory (NT)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Diabetes mellitus type 1, retinopathy',
        things_important_for_me:                     'Staying connected to country and family',
        beliefs_considered_during_health_care:       'Cultural healing alongside Western medicine',
        nearing_death_preference:                    'Die on country with family present',
        people_not_to_involve_healthcare_discussion: 'None',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'CULTURAL_RELIGIOUS', 'SPIRITUAL_CARE'],
      },
    });
    printResult('POST /user/ahd (NT minimal)', res, 200);
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
        direction_instruction: 'Consent to all treatment.',
        assisted_ventilation: 'CONSENT',
        artificial_nutrition: 'CONSENT',
        antibiotics:          'CONSENT',
        blood_transfusion:    'CONSENT',
      },
    });
    printResult('POST /user/ahd (NT LST CONSENT)', res, 200);
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
        direction_instruction:            'Refuse all heroic measures.',
        assisted_ventilation:             'REFUSE',
        assisted_ventilation_instruction: 'No mechanical ventilation.',
        artificial_nutrition:             'REFUSE',
        artificial_nutrition_instruction: 'No tube feeding.',
        antibiotics:                      'CONSENT',
        blood_transfusion: 'CANT_DECIDE',
        blood_transfusion_instruction:    'Attorney decides with elders consultation.',
      },
    });
    printResult('POST /user/ahd (NT LST REFUSE)', res, 200);
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
        cpr_resuscitation_instruction:   'No CPR; DNAR in file.',
        cpr_consent: 'ALLOW_TO_DIE',
        cpr_consent_instruction:         'No resuscitation attempt.',
      },
    });
    printResult('POST /user/ahd (NT CPR)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 5. Living preferences (NT-specific) ──────────────────────────────
  printSection('Scenario 5: Living preferences (NT-specific)');
  {
    const res = await request('POST', '/user/ahd', {
      living_preferences: {
        health_treatment_priority:    'Quality over quantity of life',
        living_well_importance: ['SPEND_TIME_WITH_FAMILY', 'LIVE_WITH_CULTURAL_RELIGIOUS_VALUES'],
        is_nearing_death: ['RECEIVE_CARE', 'OTHER'],
        nearing_death_goals_detail:   'I want to be on country and around family.',
        wish_to_live:                 'IN_COMMUNITY',
        important_people_nearing_death: 'Elders and immediate family.',
        nearing_death_unacceptable:   'Hospital ICU; isolation from family.',
        where_to_die:                 'HOME',
        where_to_die_instruction:     'On community land, near my homeland.',
      },
    });
    printResult('POST /user/ahd (NT living_preferences)', res, 200);
    const d = res.body?.data;
    const ok = d?.living_preferences?.health_treatment_priority != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} living_preferences.health_treatment_priority persisted`);
    console.log(`    \x1b[36m?\x1b[0m where_to_die: ${d?.living_preferences?.where_to_die}`);
  }

  // ── 6. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 6: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      is_registered_australian_organ_donor: false,
      organ_and_body_donation: {
        donate_organ:           false,
        consent_organ_donation: false,
        donate_body:            false,
        consent_body_donation:  false,
      },
    });
    printResult('POST /user/ahd (NT organ donation — none)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_and_body_donation?.donate_organ === false;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} donate_organ = false: ${d?.organ_and_body_donation?.donate_organ}`);
  }

  // ── 7. Treatment decisions ────────────────────────────────────────────
  printSection('Scenario 7: Treatment decisions');
  {
    const res = await request('POST', '/user/ahd', {
      treatment_decisions: {
        life_sustaining_treatment: 'REFUSE_ALL_TREATMENT',
        artificial_hydration:                       'CONSENT',
        artificial_hydration_instruction:           'Oral hydration only.',
        consent_palliative_comfort_care:            'CONSENT',
        specific_treatment_no_consent: 'ARTIFICIAL_FEEDING',
        specific_treatment_no_consent_instruction:  'No surgery without elder family consultation.',
        healthcare_preferred:                       'Royal Darwin Hospital if needed.',
      },
    });
    printResult('POST /user/ahd (NT treatment decisions)', res, 200);
    const d = res.body?.data;
    const ok = d?.treatment_decisions?.life_sustaining_treatment != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} treatment_decisions stored`);
  }

  // ── 8. AHD persons ────────────────────────────────────────────────────
  printSection('Scenario 8: AHD persons — SDM + DECISION_MAKER + witness');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: false,
      ahd_persons: [
        {
          full_name:   'Aunty June Wilson',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone:       '0889991234',
          address:     '1 Todd Mall, Alice Springs NT 0870',
        },
        {
          full_name:   'Elder Thomas Brown',
          person_type: 'DECISION_MAKER',
          phone:       '0889992345',
          address:     'Community Office, Tennant Creek NT 0860',
          other: {
            matters: 'BOTH',
          },
        },
        {
          full_name:    'Dr. Fiona Clarke',
          person_type:  'WITNESS_MEDICAL_PRACTITIONER',
          qualification: 'Remote Area General Practitioner',
          phone:         '0889993456',
          address:       '1 Hospital Road, Darwin NT 0800',
        },
      ],
    });
    printResult('POST /user/ahd (NT ahd_persons x3)', res, 200);
    const persons = res.body?.data?.ahd_persons ?? [];
    const hasSdm = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    console.log(`    ${hasSdm ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 9. Declarations and wishes + attorney_decision_power ──────────────
  printSection('Scenario 9: Declarations/wishes + attorney_decision_power_detail');
  {
    // Test after_death_importance (Fix #6 — Flutter now maps to this field)
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I make this advance care directive freely.',
        what_matter_most:                          'Connection to country, family, and culture.',
        what_worries_most:                         'Dying away from country.',
        unacceptable_medical_treatment_outcome:    'Permanently hospitalised away from community.',
        cultural_request:                          'Aboriginal sorry business to be observed.',
        religious_beliefs:                         'Traditional spiritual beliefs.',
        after_death_importance:                    'Return to country; traditional burial.',
      },
      attorney_and_advice: {
        attorney_decision_power:        'SEVERALLY',
        attorney_decision_power_detail: 'Any one decision maker may act independently.',
      },
    });
    printResult('POST /user/ahd (NT declarations + decision power)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes persisted`);
    const adOk = d?.declarations_and_wishes?.after_death_importance;
    console.log(`    ${adOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} after_death_importance: ${adOk ?? 'MISSING'}`);
    const dp = d?.attorney_and_advice?.attorney_decision_power;
    const dpd = d?.attorney_and_advice?.attorney_decision_power_detail;
    console.log(`    ${dp ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_decision_power: ${dp ?? 'MISSING'}`);
    console.log(`    ${dpd ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_decision_power_detail: ${dpd ?? 'MISSING'}`);
  }

  // ── 10. ACD revoked + GET round-trip ──────────────────────────────────
  printSection('Scenario 10: ACD revoked + GET round-trip');
  {
    const revRes = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2027-03-31',
    });
    printResult('POST /user/ahd (NT is_acd_revoked)', revRes, 200);
    console.log(`    ${revRes.body?.data?.is_acd_revoked === true ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_acd_revoked: ${revRes.body?.data?.is_acd_revoked}`);

    const getRes = await request('GET', '/user/ahd');
    printResult('GET  /user/ahd (round-trip assertions)', getRes, 200);
    const d = getRes.body?.data;

    console.log('\n    \x1b[1m── Top-level flags ──\x1b[0m');
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked ?? 'MISSING'}`);
    const expiryOk = d?.acd_expiry_date === '2027-03-31';
    console.log(`    ${expiryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} acd_expiry_date === '2027-03-31': ${d?.acd_expiry_date ?? 'MISSING'}`);
    const guardianOk = d?.is_enduring_guardian_appointed === false;
    console.log(`    ${guardianOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === false: ${d?.is_enduring_guardian_appointed ?? 'MISSING'}`);
    const organDonorOk = d?.is_registered_australian_organ_donor === false;
    console.log(`    ${organDonorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_registered_australian_organ_donor === false: ${d?.is_registered_australian_organ_donor ?? 'MISSING'}`);

    // ── health_conditions (scenario 1) ──
    console.log('\n    \x1b[1m── health_conditions (scenario 1) ──\x1b[0m');
    const hc = d?.health_conditions;
    const hcMajorOk = hc?.major_health_conditions === 'Diabetes mellitus type 1, retinopathy';
    console.log(`    ${hcMajorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} major_health_conditions === 'Diabetes mellitus type 1, retinopathy': ${hc?.major_health_conditions ?? 'MISSING'}`);
    const hcThingsOk = hc?.things_important_for_me === 'Staying connected to country and family';
    console.log(`    ${hcThingsOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} things_important_for_me === 'Staying connected to country and family': ${hc?.things_important_for_me ?? 'MISSING'}`);
    const hcBeliefsOk = hc?.beliefs_considered_during_health_care === 'Cultural healing alongside Western medicine';
    console.log(`    ${hcBeliefsOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} beliefs_considered_during_health_care === 'Cultural healing alongside Western medicine': ${hc?.beliefs_considered_during_health_care ?? 'MISSING'}`);
    const hcNearingOk = hc?.nearing_death_preference === 'Die on country with family present';
    console.log(`    ${hcNearingOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_preference === 'Die on country with family present': ${hc?.nearing_death_preference ?? 'MISSING'}`);
    const hcPeopleOk = hc?.people_not_to_involve_healthcare_discussion === 'None';
    console.log(`    ${hcPeopleOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} people_not_to_involve_healthcare_discussion === 'None': ${hc?.people_not_to_involve_healthcare_discussion ?? 'MISSING'}`);
    const hcComfortArr = Array.isArray(hc?.comfort_nearing_death);
    const hcComfortVal = hcComfortArr && hc.comfort_nearing_death.includes('LOVED_ONES_NEARBY');
    console.log(`    ${hcComfortArr ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death is Array: ${hcComfortArr}`);
    console.log(`    ${hcComfortVal ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death includes 'LOVED_ONES_NEARBY': ${JSON.stringify(hc?.comfort_nearing_death) ?? 'MISSING'}`);
    const hcComfortLenOk = hcComfortArr && hc.comfort_nearing_death.length >= 3;
    console.log(`    ${hcComfortLenOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death length >= 3: ${hc?.comfort_nearing_death?.length ?? 'MISSING'}`);

    // ── life_sustaining_treatment (scenario 3 overwrites 2) ──
    console.log('\n    \x1b[1m── life_sustaining_treatment (scenario 3) ──\x1b[0m');
    const lst = d?.life_sustaining_treatment;
    const lstDirOk = lst?.direction_type === 'REFUSE';
    console.log(`    ${lstDirOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_type === 'REFUSE': ${lst?.direction_type ?? 'MISSING'}`);
    const lstDirInstOk = lst?.direction_instruction === 'Refuse all heroic measures.';
    console.log(`    ${lstDirInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_instruction === 'Refuse all heroic measures.': ${lst?.direction_instruction ?? 'MISSING'}`);
    const lstVentOk = lst?.assisted_ventilation === 'REFUSE';
    console.log(`    ${lstVentOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation === 'REFUSE': ${lst?.assisted_ventilation ?? 'MISSING'}`);
    const lstVentInstOk = lst?.assisted_ventilation_instruction === 'No mechanical ventilation.';
    console.log(`    ${lstVentInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation_instruction === 'No mechanical ventilation.': ${lst?.assisted_ventilation_instruction ?? 'MISSING'}`);
    const lstNutrOk = lst?.artificial_nutrition === 'REFUSE';
    console.log(`    ${lstNutrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition === 'REFUSE': ${lst?.artificial_nutrition ?? 'MISSING'}`);
    const lstNutrInstOk = lst?.artificial_nutrition_instruction === 'No tube feeding.';
    console.log(`    ${lstNutrInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition_instruction === 'No tube feeding.': ${lst?.artificial_nutrition_instruction ?? 'MISSING'}`);
    const lstAbxOk = lst?.antibiotics === 'CONSENT';
    console.log(`    ${lstAbxOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} antibiotics === 'CONSENT': ${lst?.antibiotics ?? 'MISSING'}`);
    const lstBloodOk = lst?.blood_transfusion === 'CANT_DECIDE';
    console.log(`    ${lstBloodOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion === 'CANT_DECIDE': ${lst?.blood_transfusion ?? 'MISSING'}`);
    const lstBloodInstOk = lst?.blood_transfusion_instruction === 'Attorney decides with elders consultation.';
    console.log(`    ${lstBloodInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion_instruction === 'Attorney decides with elders consultation.': ${lst?.blood_transfusion_instruction ?? 'MISSING'}`);

    // ── cpr_and_resuscitation (scenario 4) ──
    console.log('\n    \x1b[1m── cpr_and_resuscitation (scenario 4) ──\x1b[0m');
    const cpr = d?.cpr_and_resuscitation;
    const cprInstOk = cpr?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${cprInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_instruction === 'UNBEARABLE': ${cpr?.cpr_instruction ?? 'MISSING'}`);
    const cprMedOk = cpr?.medical_not_expected_to_recover === 'REJECT_CPR';
    console.log(`    ${cprMedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} medical_not_expected_to_recover === 'REJECT_CPR': ${cpr?.medical_not_expected_to_recover ?? 'MISSING'}`);
    const cprResOk = cpr?.cpr_resuscitation === 'REFUSE';
    console.log(`    ${cprResOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation === 'REFUSE': ${cpr?.cpr_resuscitation ?? 'MISSING'}`);
    const cprResInstOk = cpr?.cpr_resuscitation_instruction === 'No CPR; DNAR in file.';
    console.log(`    ${cprResInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation_instruction === 'No CPR; DNAR in file.': ${cpr?.cpr_resuscitation_instruction ?? 'MISSING'}`);
    const cprConOk = cpr?.cpr_consent === 'ALLOW_TO_DIE';
    console.log(`    ${cprConOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent === 'ALLOW_TO_DIE': ${cpr?.cpr_consent ?? 'MISSING'}`);
    const cprConInstOk = cpr?.cpr_consent_instruction === 'No resuscitation attempt.';
    console.log(`    ${cprConInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent_instruction === 'No resuscitation attempt.': ${cpr?.cpr_consent_instruction ?? 'MISSING'}`);

    // ── living_preferences (scenario 5 — NT-specific) ──
    console.log('\n    \x1b[1m── living_preferences (scenario 5 — NT-specific) ──\x1b[0m');
    const lp = d?.living_preferences;
    const lpHtpOk = lp?.health_treatment_priority === 'Quality over quantity of life';
    console.log(`    ${lpHtpOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_treatment_priority === 'Quality over quantity of life': ${lp?.health_treatment_priority ?? 'MISSING'}`);
    const lpLwArr = Array.isArray(lp?.living_well_importance);
    const lpLwVal = lpLwArr && lp.living_well_importance.includes('SPEND_TIME_WITH_FAMILY') && lp.living_well_importance.includes('LIVE_WITH_CULTURAL_RELIGIOUS_VALUES');
    console.log(`    ${lpLwArr ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} living_well_importance is Array: ${lpLwArr}`);
    console.log(`    ${lpLwVal ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} living_well_importance includes SPEND_TIME_WITH_FAMILY + LIVE_WITH_CULTURAL_RELIGIOUS_VALUES: ${JSON.stringify(lp?.living_well_importance) ?? 'MISSING'}`);
    const lpNdArr = Array.isArray(lp?.is_nearing_death);
    const lpNdVal = lpNdArr && lp.is_nearing_death.includes('RECEIVE_CARE') && lp.is_nearing_death.includes('OTHER');
    console.log(`    ${lpNdArr ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_nearing_death is Array: ${lpNdArr}`);
    console.log(`    ${lpNdVal ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_nearing_death includes RECEIVE_CARE + OTHER: ${JSON.stringify(lp?.is_nearing_death) ?? 'MISSING'}`);
    const lpNdGoalsOk = lp?.nearing_death_goals_detail === 'I want to be on country and around family.';
    console.log(`    ${lpNdGoalsOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_goals_detail === 'I want to be on country and around family.': ${lp?.nearing_death_goals_detail ?? 'MISSING'}`);
    const lpWishOk = lp?.wish_to_live === 'IN_COMMUNITY';
    console.log(`    ${lpWishOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} wish_to_live === 'IN_COMMUNITY': ${lp?.wish_to_live ?? 'MISSING'}`);
    const lpImpPplOk = lp?.important_people_nearing_death === 'Elders and immediate family.';
    console.log(`    ${lpImpPplOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} important_people_nearing_death === 'Elders and immediate family.': ${lp?.important_people_nearing_death ?? 'MISSING'}`);
    const lpUnaccOk = lp?.nearing_death_unacceptable === 'Hospital ICU; isolation from family.';
    console.log(`    ${lpUnaccOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_unacceptable === 'Hospital ICU; isolation from family.': ${lp?.nearing_death_unacceptable ?? 'MISSING'}`);
    const lpWtdOk = lp?.where_to_die === 'HOME';
    console.log(`    ${lpWtdOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} where_to_die === 'HOME': ${lp?.where_to_die ?? 'MISSING'}`);
    const lpWtdInstOk = lp?.where_to_die_instruction === 'On community land, near my homeland.';
    console.log(`    ${lpWtdInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} where_to_die_instruction === 'On community land, near my homeland.': ${lp?.where_to_die_instruction ?? 'MISSING'}`);

    // ── organ_and_body_donation (scenario 6) ──
    console.log('\n    \x1b[1m── organ_and_body_donation (scenario 6) ──\x1b[0m');
    const obd = d?.organ_and_body_donation;
    const obdDonOk = obd?.donate_organ === false;
    console.log(`    ${obdDonOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_organ === false: ${obd?.donate_organ ?? 'MISSING'}`);
    const obdConOk = obd?.consent_organ_donation === false;
    console.log(`    ${obdConOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_organ_donation === false: ${obd?.consent_organ_donation ?? 'MISSING'}`);
    const obdBodyOk = obd?.donate_body === false;
    console.log(`    ${obdBodyOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_body === false: ${obd?.donate_body ?? 'MISSING'}`);
    const obdConBodyOk = obd?.consent_body_donation === false;
    console.log(`    ${obdConBodyOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_body_donation === false: ${obd?.consent_body_donation ?? 'MISSING'}`);

    // ── treatment_decisions (scenario 7) ──
    console.log('\n    \x1b[1m── treatment_decisions (scenario 7) ──\x1b[0m');
    const td = d?.treatment_decisions;
    const tdLstOk = td?.life_sustaining_treatment === 'REFUSE_ALL_TREATMENT';
    console.log(`    ${tdLstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment === 'REFUSE_ALL_TREATMENT': ${td?.life_sustaining_treatment ?? 'MISSING'}`);
    const tdHydOk = td?.artificial_hydration === 'CONSENT';
    console.log(`    ${tdHydOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration === 'CONSENT': ${td?.artificial_hydration ?? 'MISSING'}`);
    const tdHydInstOk = td?.artificial_hydration_instruction === 'Oral hydration only.';
    console.log(`    ${tdHydInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration_instruction === 'Oral hydration only.': ${td?.artificial_hydration_instruction ?? 'MISSING'}`);
    const tdPallOk = td?.consent_palliative_comfort_care === 'CONSENT';
    console.log(`    ${tdPallOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_palliative_comfort_care === 'CONSENT': ${td?.consent_palliative_comfort_care ?? 'MISSING'}`);
    const tdSpecOk = td?.specific_treatment_no_consent === 'ARTIFICIAL_FEEDING';
    console.log(`    ${tdSpecOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent === 'ARTIFICIAL_FEEDING': ${td?.specific_treatment_no_consent ?? 'MISSING'}`);
    const tdSpecInstOk = td?.specific_treatment_no_consent_instruction === 'No surgery without elder family consultation.';
    console.log(`    ${tdSpecInstOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent_instruction === 'No surgery without elder family consultation.': ${td?.specific_treatment_no_consent_instruction ?? 'MISSING'}`);
    const tdHcPrefOk = td?.healthcare_preferred === 'Royal Darwin Hospital if needed.';
    console.log(`    ${tdHcPrefOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} healthcare_preferred === 'Royal Darwin Hospital if needed.': ${td?.healthcare_preferred ?? 'MISSING'}`);

    // ── ahd_persons (scenario 8) ──
    console.log('\n    \x1b[1m── ahd_persons (scenario 8) ──\x1b[0m');
    const persons = d?.ahd_persons ?? [];
    const personsIsArr = Array.isArray(d?.ahd_persons);
    console.log(`    ${personsIsArr ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ahd_persons is Array: ${personsIsArr}`);
    const personsCountOk = persons.length >= 3;
    console.log(`    ${personsCountOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ahd_persons count >= 3: ${persons.length}`);

    // Person 1: SDM
    const sdm = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const sdmNameOk = sdm?.full_name === 'Aunty June Wilson';
    console.log(`    ${sdmNameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM full_name === 'Aunty June Wilson': ${sdm?.full_name ?? 'MISSING'}`);
    const sdmPhoneOk = sdm?.phone === '0889991234';
    console.log(`    ${sdmPhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM phone === '0889991234': ${sdm?.phone ?? 'MISSING'}`);
    const sdmAddrOk = sdm?.address === '1 Todd Mall, Alice Springs NT 0870';
    console.log(`    ${sdmAddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM address === '1 Todd Mall, Alice Springs NT 0870': ${sdm?.address ?? 'MISSING'}`);

    // Person 2: DECISION_MAKER
    const dm = persons.find((p) => p.person_type === 'DECISION_MAKER');
    const dmNameOk = dm?.full_name === 'Elder Thomas Brown';
    console.log(`    ${dmNameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} DECISION_MAKER full_name === 'Elder Thomas Brown': ${dm?.full_name ?? 'MISSING'}`);
    const dmPhoneOk = dm?.phone === '0889992345';
    console.log(`    ${dmPhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} DECISION_MAKER phone === '0889992345': ${dm?.phone ?? 'MISSING'}`);
    const dmAddrOk = dm?.address === 'Community Office, Tennant Creek NT 0860';
    console.log(`    ${dmAddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} DECISION_MAKER address === 'Community Office, Tennant Creek NT 0860': ${dm?.address ?? 'MISSING'}`);
    const dmMattersOk = dm?.other?.matters === 'BOTH';
    console.log(`    ${dmMattersOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} DECISION_MAKER other.matters === 'BOTH': ${dm?.other?.matters ?? 'MISSING'}`);

    // Person 3: WITNESS_MEDICAL_PRACTITIONER
    const wit = persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const witNameOk = wit?.full_name === 'Dr. Fiona Clarke';
    console.log(`    ${witNameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS full_name === 'Dr. Fiona Clarke': ${wit?.full_name ?? 'MISSING'}`);
    const witQualOk = (wit?.qualification === 'Remote Area General Practitioner') || (wit?.other?.qualification === 'Remote Area General Practitioner');
    console.log(`    ${witQualOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS qualification === 'Remote Area General Practitioner': ${wit?.qualification ?? wit?.other?.qualification ?? 'MISSING'}`);
    const witPhoneOk = wit?.phone === '0889993456';
    console.log(`    ${witPhoneOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS phone === '0889993456': ${wit?.phone ?? 'MISSING'}`);
    const witAddrOk = wit?.address === '1 Hospital Road, Darwin NT 0800';
    console.log(`    ${witAddrOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS address === '1 Hospital Road, Darwin NT 0800': ${wit?.address ?? 'MISSING'}`);

    // ── declarations_and_wishes (scenario 9) ──
    console.log('\n    \x1b[1m── declarations_and_wishes (scenario 9) ──\x1b[0m');
    const dw = d?.declarations_and_wishes;
    const dwDeclOk = dw?.declaration === 'I make this advance care directive freely.';
    console.log(`    ${dwDeclOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declaration === 'I make this advance care directive freely.': ${dw?.declaration ?? 'MISSING'}`);
    const dwMatterOk = dw?.what_matter_most === 'Connection to country, family, and culture.';
    console.log(`    ${dwMatterOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_matter_most === 'Connection to country, family, and culture.': ${dw?.what_matter_most ?? 'MISSING'}`);
    const dwWorryOk = dw?.what_worries_most === 'Dying away from country.';
    console.log(`    ${dwWorryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_worries_most === 'Dying away from country.': ${dw?.what_worries_most ?? 'MISSING'}`);
    const dwUnaccOk = dw?.unacceptable_medical_treatment_outcome === 'Permanently hospitalised away from community.';
    console.log(`    ${dwUnaccOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} unacceptable_medical_treatment_outcome === 'Permanently hospitalised away from community.': ${dw?.unacceptable_medical_treatment_outcome ?? 'MISSING'}`);
    const dwCultOk = dw?.cultural_request === 'Aboriginal sorry business to be observed.';
    console.log(`    ${dwCultOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cultural_request === 'Aboriginal sorry business to be observed.': ${dw?.cultural_request ?? 'MISSING'}`);
    const dwRelOk = dw?.religious_beliefs === 'Traditional spiritual beliefs.';
    console.log(`    ${dwRelOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} religious_beliefs === 'Traditional spiritual beliefs.': ${dw?.religious_beliefs ?? 'MISSING'}`);
    const dwAdOk = dw?.after_death_importance === 'Return to country; traditional burial.';
    console.log(`    ${dwAdOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} after_death_importance === 'Return to country; traditional burial.': ${dw?.after_death_importance ?? 'MISSING'}`);

    // ── attorney_and_advice (scenario 9) ──
    console.log('\n    \x1b[1m── attorney_and_advice (scenario 9) ──\x1b[0m');
    const aa = d?.attorney_and_advice;
    const aaPowOk = aa?.attorney_decision_power === 'SEVERALLY';
    console.log(`    ${aaPowOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} attorney_decision_power === 'SEVERALLY': ${aa?.attorney_decision_power ?? 'MISSING'}`);
    const aaPowDetOk = aa?.attorney_decision_power_detail === 'Any one decision maker may act independently.';
    console.log(`    ${aaPowDetOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} attorney_decision_power_detail === 'Any one decision maker may act independently.': ${aa?.attorney_decision_power_detail ?? 'MISSING'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
