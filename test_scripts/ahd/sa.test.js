/**
 * AHD Integration Tests — South Australia (SA)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — REFUSE
 *  4. CPR and resuscitation — ATTORNEY_DECISION
 *  5. Organ and body donation
 *  6. Treatment decisions
 *  7. AHD persons — SUBSTITUTE_DECISION_MAKER + WITNESS_PRIMARY + WITNESS_AUTHORIZED
 *  8. Declarations and wishes
 *  9. ACD revoked
 * 10. GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/sa.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — South Australia (SA)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Metastatic breast cancer',
        things_important_for_me:                     'Family, work projects, and being outdoors',
        beliefs_considered_during_health_care:       'Believe in evidence-based palliation',
        nearing_death_preference:                    'Die at home with family; no ICU',
        people_not_to_involve_healthcare_discussion: 'None',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'CULTURAL_RELIGIOUS', 'HEALTHY_SURROUNDINGS'],
      },
    });
    printResult('POST /user/ahd (SA minimal)', res, 200);
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
    printResult('POST /user/ahd (SA LST CONSENT)', res, 200);
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
        direction_instruction:            'Refuse all life-sustaining treatment beyond comfort.',
        assisted_ventilation:             'REFUSE',
        assisted_ventilation_instruction: 'No mechanical airways.',
        artificial_nutrition:             'REFUSE',
        artificial_nutrition_instruction: 'No tube or IV feeding.',
        antibiotics: 'CANT_DECIDE',
        blood_transfusion:                'CONSENT',
        other_treatment: 'CANT_DECIDE',
        other_instruction:                'No dialysis; consider oral hydration only.',
      },
    });
    printResult('POST /user/ahd (SA LST REFUSE)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'REFUSE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
  }

  // ── 4. CPR — ATTORNEY_DECISION ────────────────────────────────────────
  printSection('Scenario 4: CPR — ATTORNEY_DECISION');
  {
    const res = await request('POST', '/user/ahd', {
      cpr_and_resuscitation: {
        cpr_instruction: 'UNSURE',
        medical_not_expected_to_recover: 'REJECT_CPR',
        cpr_resuscitation: 'CANT_DECIDE',
        cpr_resuscitation_instruction:   'Attorney consults palliative team.',
        cpr_consent: 'CONDITION',
        cpr_consent_instruction:         'Base decision on dignity and prognosis.',
      },
    });
    printResult('POST /user/ahd (SA CPR ATTORNEY_DECISION)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNSURE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 5. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 5: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      organ_donation: 'CONSENT',
    });
    printResult('POST /user/ahd (SA organ_donation)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_donation === 'CONSENT';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} organ_donation: ${d?.organ_donation}`);
  }

  // ── 6. Treatment decisions + living_preferences.health_treatment_priority ──
  printSection('Scenario 6: Treatment decisions + living_preferences');
  {
    const res = await request('POST', '/user/ahd', {
      treatment_decisions: {
        life_sustaining_treatment: 'CANT_DECIDE',
        artificial_hydration:                       'CONSENT',
        artificial_hydration_instruction:           'IV acceptable for 48h maximum.',
        consent_palliative_comfort_care:            'CONSENT',
        specific_treatment_no_consent: 'ARTIFICIAL_FEEDING',
        specific_treatment_no_consent_instruction:  'No clinical trials without prior consent.',
        healthcare_preferred:                       'Royal Adelaide Hospital preferred.',
      },
      living_preferences: {
        wish_to_live:              'Stay at home with family support.',
      },
    });
    printResult('POST /user/ahd (SA treatment + living_preferences)', res, 200);
    const d = res.body?.data;
    const ok = d?.treatment_decisions?.life_sustaining_treatment != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} treatment_decisions stored`);
    const hpOk = d?.treatment_decisions?.healthcare_preferred != null;
    console.log(`    ${hpOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} treatment_decisions.healthcare_preferred: ${d?.treatment_decisions?.healthcare_preferred ?? 'MISSING'}`);
  }

  // ── 7. AHD persons — SDM (with signature/date) + WITNESS_PRIMARY + WITNESS_AUTHORIZED
  printSection('Scenario 7: AHD persons — SDM with signature/date + WITNESS_PRIMARY + WITNESS_AUTHORIZED');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: true,
      ahd_persons: [
        {
          full_name:   'Nicole Adams',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone:       '0881234567',
          address:     '1 King William Street, Adelaide SA 5000',
          other: {
            signature: 'Nicole Adams',
            date:      '2026-03-15',
          },
        },
        {
          full_name:   'David Adams',
          person_type: 'WITNESS_PRIMARY',
          phone:       '0882345678',
          address:     '1 King William Street, Adelaide SA 5000',
        },
        {
          full_name:    'Officer Sarah Lane',
          person_type:  'WITNESS_AUTHORIZED',
          qualification: 'Justice of the Peace',
          phone:         '0883456789',
          address:       '10 Pirie Street, Adelaide SA 5000',
          other: {
            witness_category: 'JUSTICE_OF_PEACE',
            signature:        'Sarah Lane JP',
            date:             '2026-03-15',
          },
        },
        {
          full_name:   'James Adams',
          person_type: 'SUBSTITUTE_DECISION_MAKER_SECONDARY',
          phone:       '0884567890',
          address:     '5 Rundle Mall, Adelaide SA 5000',
        },
        {
          full_name:   'Elena Papadopoulos',
          person_type: 'INTERPRETER',
          dob:         '1982-06-15',
          other: {
            language:    'Greek',
            naati_number: 'NAATI-7788',
          },
        },
      ],
    });
    printResult('POST /user/ahd (SA ahd_persons x3)', res, 200);
    const persons = res.body?.data?.ahd_persons ?? [];
    const hasSdm  = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const hasWitA = Array.isArray(persons) && persons.some((p) => p.person_type === 'WITNESS_AUTHORIZED');
    const sdm     = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    console.log(`    ${hasSdm  ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    console.log(`    ${sdm?.other?.signature ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SDM signature: ${sdm?.other?.signature ?? 'MISSING'}`);
    console.log(`    ${sdm?.other?.date ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SDM date: ${sdm?.other?.date ?? 'MISSING'}`);
    console.log(`    ${hasWitA ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} WITNESS_AUTHORIZED present`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 8. Declarations and wishes ────────────────────────────────────────
  printSection('Scenario 8: Declarations and wishes');
  {
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I freely provide this Advance Care Directive.',
        what_matter_most:                          'Being comfortable and surrounded by loved ones.',
        what_worries_most:                         'Suffering without purpose.',
        unacceptable_medical_treatment_outcome:    'Brain-dead state with no prognosis of recovery.',
        cultural_request:                          'Greek Orthodox traditions.',
        religious_beliefs:                         'Greek Orthodox.',
        after_death_importance:                    'Religious burial service.',
        nearing_death_instruction:                 'Play Greek Orthodox hymns; call priest.',
      },
    });
    printResult('POST /user/ahd (SA declarations)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes persisted`);
  }

  // ── 9. ACD revoked ────────────────────────────────────────────────────
  printSection('Scenario 9: ACD revoked flag');
  {
    const res = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2026-09-30',
    });
    printResult('POST /user/ahd (SA is_acd_revoked)', res, 200);
    const d = res.body?.data;
    const ok = d?.is_acd_revoked === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_acd_revoked: ${d?.is_acd_revoked}`);
  }

  // ── 10. GET round-trip ─────────────────────────────────────────────────
  printSection('Scenario 10: GET round-trip — stored value assertions');
  {
    const res = await request('GET', '/user/ahd');
    printResult('GET  /user/ahd', res, 200);
    const d = res.body?.data;

    // ── Top-level flags ──
    console.log('  Top-level flags:');
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked}`);
    const expiryOk = d?.acd_expiry_date === '2026-09-30';
    console.log(`    ${expiryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} acd_expiry_date === '2026-09-30': ${d?.acd_expiry_date ?? 'MISSING'}`);
    const guardianOk = d?.is_enduring_guardian_appointed === true;
    console.log(`    ${guardianOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === true: ${d?.is_enduring_guardian_appointed}`);

    // ── Health conditions ──
    console.log('  Health conditions:');
    const hc = d?.health_conditions;
    const hc1Ok = hc?.major_health_conditions === 'Metastatic breast cancer';
    console.log(`    ${hc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} major_health_conditions === 'Metastatic breast cancer': ${hc?.major_health_conditions ?? 'MISSING'}`);
    const hc2Ok = hc?.things_important_for_me === 'Family, work projects, and being outdoors';
    console.log(`    ${hc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} things_important_for_me === 'Family, work projects, and being outdoors': ${hc?.things_important_for_me ?? 'MISSING'}`);
    const hc3Ok = hc?.beliefs_considered_during_health_care === 'Believe in evidence-based palliation';
    console.log(`    ${hc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} beliefs_considered_during_health_care === 'Believe in evidence-based palliation': ${hc?.beliefs_considered_during_health_care ?? 'MISSING'}`);
    const hc4Ok = hc?.nearing_death_preference === 'Die at home with family; no ICU';
    console.log(`    ${hc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_preference === 'Die at home with family; no ICU': ${hc?.nearing_death_preference ?? 'MISSING'}`);
    const hc5Ok = hc?.people_not_to_involve_healthcare_discussion === 'None';
    console.log(`    ${hc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} people_not_to_involve_healthcare_discussion === 'None': ${hc?.people_not_to_involve_healthcare_discussion ?? 'MISSING'}`);
    const comfortArr = hc?.comfort_nearing_death;
    const hc6Ok = Array.isArray(comfortArr) && comfortArr.length >= 3 && comfortArr.includes('LOVED_ONES_NEARBY');
    console.log(`    ${hc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death length >= 3 and includes 'LOVED_ONES_NEARBY': ${JSON.stringify(comfortArr) ?? 'MISSING'}`);

    // ── Life sustaining treatment ──
    console.log('  Life sustaining treatment:');
    const lst = d?.life_sustaining_treatment;
    const lst1Ok = lst?.direction_type === 'REFUSE';
    console.log(`    ${lst1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_type === 'REFUSE': ${lst?.direction_type ?? 'MISSING'}`);
    const lst2Ok = lst?.direction_instruction === 'Refuse all life-sustaining treatment beyond comfort.';
    console.log(`    ${lst2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_instruction === 'Refuse all life-sustaining treatment beyond comfort.': ${lst?.direction_instruction ?? 'MISSING'}`);
    const lst3Ok = lst?.assisted_ventilation === 'REFUSE';
    console.log(`    ${lst3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation === 'REFUSE': ${lst?.assisted_ventilation ?? 'MISSING'}`);
    const lst4Ok = lst?.assisted_ventilation_instruction === 'No mechanical airways.';
    console.log(`    ${lst4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation_instruction === 'No mechanical airways.': ${lst?.assisted_ventilation_instruction ?? 'MISSING'}`);
    const lst5Ok = lst?.artificial_nutrition === 'REFUSE';
    console.log(`    ${lst5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition === 'REFUSE': ${lst?.artificial_nutrition ?? 'MISSING'}`);
    const lst6Ok = lst?.artificial_nutrition_instruction === 'No tube or IV feeding.';
    console.log(`    ${lst6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition_instruction === 'No tube or IV feeding.': ${lst?.artificial_nutrition_instruction ?? 'MISSING'}`);
    const lst7Ok = lst?.antibiotics === 'CANT_DECIDE';
    console.log(`    ${lst7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} antibiotics === 'CANT_DECIDE': ${lst?.antibiotics ?? 'MISSING'}`);
    const lst8Ok = lst?.blood_transfusion === 'CONSENT';
    console.log(`    ${lst8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion === 'CONSENT': ${lst?.blood_transfusion ?? 'MISSING'}`);
    const lst9Ok = lst?.other_treatment === 'CANT_DECIDE';
    console.log(`    ${lst9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_treatment === 'CANT_DECIDE': ${lst?.other_treatment ?? 'MISSING'}`);
    const lst10Ok = lst?.other_instruction === 'No dialysis; consider oral hydration only.';
    console.log(`    ${lst10Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_instruction === 'No dialysis; consider oral hydration only.': ${lst?.other_instruction ?? 'MISSING'}`);

    // ── CPR and resuscitation ──
    console.log('  CPR and resuscitation:');
    const cpr = d?.cpr_and_resuscitation;
    const cpr1Ok = cpr?.cpr_instruction === 'UNSURE';
    console.log(`    ${cpr1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_instruction === 'UNSURE': ${cpr?.cpr_instruction ?? 'MISSING'}`);
    const cpr2Ok = cpr?.medical_not_expected_to_recover === 'REJECT_CPR';
    console.log(`    ${cpr2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} medical_not_expected_to_recover === 'REJECT_CPR': ${cpr?.medical_not_expected_to_recover ?? 'MISSING'}`);
    const cpr3Ok = cpr?.cpr_resuscitation === 'CANT_DECIDE';
    console.log(`    ${cpr3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation === 'CANT_DECIDE': ${cpr?.cpr_resuscitation ?? 'MISSING'}`);
    const cpr4Ok = cpr?.cpr_resuscitation_instruction === 'Attorney consults palliative team.';
    console.log(`    ${cpr4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation_instruction === 'Attorney consults palliative team.': ${cpr?.cpr_resuscitation_instruction ?? 'MISSING'}`);
    const cpr5Ok = cpr?.cpr_consent === 'CONDITION';
    console.log(`    ${cpr5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent === 'CONDITION': ${cpr?.cpr_consent ?? 'MISSING'}`);
    const cpr6Ok = cpr?.cpr_consent_instruction === 'Base decision on dignity and prognosis.';
    console.log(`    ${cpr6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent_instruction === 'Base decision on dignity and prognosis.': ${cpr?.cpr_consent_instruction ?? 'MISSING'}`);

    // ── Organ donation (flat for SA) ──
    console.log('  Organ donation:');
    const od = d?.organ_donation;
    const odOk = od === 'CONSENT';
    console.log(`    ${odOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_donation === 'CONSENT': ${od ?? 'MISSING'}`);

    // ── Treatment decisions ──
    console.log('  Treatment decisions:');
    const td = d?.treatment_decisions;
    const td1Ok = td?.life_sustaining_treatment === 'CANT_DECIDE';
    console.log(`    ${td1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} life_sustaining_treatment === 'CANT_DECIDE': ${td?.life_sustaining_treatment ?? 'MISSING'}`);
    const td2Ok = td?.artificial_hydration === 'CONSENT';
    console.log(`    ${td2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration === 'CONSENT': ${td?.artificial_hydration ?? 'MISSING'}`);
    const td3Ok = td?.artificial_hydration_instruction === 'IV acceptable for 48h maximum.';
    console.log(`    ${td3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_hydration_instruction === 'IV acceptable for 48h maximum.': ${td?.artificial_hydration_instruction ?? 'MISSING'}`);
    const td4Ok = td?.consent_palliative_comfort_care === 'CONSENT';
    console.log(`    ${td4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_palliative_comfort_care === 'CONSENT': ${td?.consent_palliative_comfort_care ?? 'MISSING'}`);
    const td5Ok = td?.specific_treatment_no_consent === 'ARTIFICIAL_FEEDING';
    console.log(`    ${td5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent === 'ARTIFICIAL_FEEDING': ${td?.specific_treatment_no_consent ?? 'MISSING'}`);
    const td6Ok = td?.specific_treatment_no_consent_instruction === 'No clinical trials without prior consent.';
    console.log(`    ${td6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} specific_treatment_no_consent_instruction === 'No clinical trials without prior consent.': ${td?.specific_treatment_no_consent_instruction ?? 'MISSING'}`);
    const td7Ok = td?.healthcare_preferred === 'Royal Adelaide Hospital preferred.';
    console.log(`    ${td7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} healthcare_preferred === 'Royal Adelaide Hospital preferred.': ${td?.healthcare_preferred ?? 'MISSING'}`);

    // ── Living preferences ──
    console.log('  Living preferences:');
    const lp = d?.living_preferences;
    const lpOk = lp?.wish_to_live === 'Stay at home with family support.';
    console.log(`    ${lpOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} wish_to_live === 'Stay at home with family support.': ${lp?.wish_to_live ?? 'MISSING'}`);

    // ── Declarations and wishes ──
    console.log('  Declarations and wishes:');
    const dw = d?.declarations_and_wishes;
    const dw1Ok = dw?.declaration === 'I freely provide this Advance Care Directive.';
    console.log(`    ${dw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declaration === 'I freely provide this Advance Care Directive.': ${dw?.declaration ?? 'MISSING'}`);
    const dw2Ok = dw?.what_matter_most === 'Being comfortable and surrounded by loved ones.';
    console.log(`    ${dw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_matter_most === 'Being comfortable and surrounded by loved ones.': ${dw?.what_matter_most ?? 'MISSING'}`);
    const dw3Ok = dw?.what_worries_most === 'Suffering without purpose.';
    console.log(`    ${dw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_worries_most === 'Suffering without purpose.': ${dw?.what_worries_most ?? 'MISSING'}`);
    const dw4Ok = dw?.unacceptable_medical_treatment_outcome === 'Brain-dead state with no prognosis of recovery.';
    console.log(`    ${dw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} unacceptable_medical_treatment_outcome === 'Brain-dead state with no prognosis of recovery.': ${dw?.unacceptable_medical_treatment_outcome ?? 'MISSING'}`);
    const dw5Ok = dw?.cultural_request === 'Greek Orthodox traditions.';
    console.log(`    ${dw5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cultural_request === 'Greek Orthodox traditions.': ${dw?.cultural_request ?? 'MISSING'}`);
    const dw6Ok = dw?.religious_beliefs === 'Greek Orthodox.';
    console.log(`    ${dw6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} religious_beliefs === 'Greek Orthodox.': ${dw?.religious_beliefs ?? 'MISSING'}`);
    const dw7Ok = dw?.after_death_importance === 'Religious burial service.';
    console.log(`    ${dw7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} after_death_importance === 'Religious burial service.': ${dw?.after_death_importance ?? 'MISSING'}`);
    const dw8Ok = dw?.nearing_death_instruction === 'Play Greek Orthodox hymns; call priest.';
    console.log(`    ${dw8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_instruction === 'Play Greek Orthodox hymns; call priest.': ${dw?.nearing_death_instruction ?? 'MISSING'}`);

    // ── AHD Persons ──
    console.log('  AHD Persons:');
    const persons = d?.ahd_persons ?? [];

    // Person 1: SDM
    console.log('    SDM (Substitute Decision Maker):');
    const sdm = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const sdm1Ok = sdm?.full_name === 'Nicole Adams';
    console.log(`      ${sdm1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Nicole Adams': ${sdm?.full_name ?? 'MISSING'}`);
    const sdm2Ok = sdm?.phone === '0881234567';
    console.log(`      ${sdm2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0881234567': ${sdm?.phone ?? 'MISSING'}`);
    const sdm3Ok = sdm?.address === '1 King William Street, Adelaide SA 5000';
    console.log(`      ${sdm3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '1 King William Street, Adelaide SA 5000': ${sdm?.address ?? 'MISSING'}`);
    const sdm4Ok = sdm?.other?.signature === 'Nicole Adams';
    console.log(`      ${sdm4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.signature === 'Nicole Adams': ${sdm?.other?.signature ?? 'MISSING'}`);
    const sdm5Ok = sdm?.other?.date === '2026-03-15';
    console.log(`      ${sdm5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.date === '2026-03-15': ${sdm?.other?.date ?? 'MISSING'}`);

    // Person 2: WITNESS_PRIMARY
    console.log('    WITNESS_PRIMARY:');
    const witPrimary = persons.find((p) => p.person_type === 'WITNESS_PRIMARY');
    const wp1Ok = witPrimary?.full_name === 'David Adams';
    console.log(`      ${wp1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'David Adams': ${witPrimary?.full_name ?? 'MISSING'}`);
    const wp2Ok = witPrimary?.phone === '0882345678';
    console.log(`      ${wp2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0882345678': ${witPrimary?.phone ?? 'MISSING'}`);
    const wp3Ok = witPrimary?.address === '1 King William Street, Adelaide SA 5000';
    console.log(`      ${wp3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '1 King William Street, Adelaide SA 5000': ${witPrimary?.address ?? 'MISSING'}`);

    // Person 3: WITNESS_AUTHORIZED
    console.log('    WITNESS_AUTHORIZED:');
    const witAuth = persons.find((p) => p.person_type === 'WITNESS_AUTHORIZED');
    const wa1Ok = witAuth?.full_name === 'Officer Sarah Lane';
    console.log(`      ${wa1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Officer Sarah Lane': ${witAuth?.full_name ?? 'MISSING'}`);
    const wa2Ok = witAuth?.qualification === 'Justice of the Peace';
    console.log(`      ${wa2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} qualification === 'Justice of the Peace': ${witAuth?.qualification ?? 'MISSING'}`);
    const wa3Ok = witAuth?.phone === '0883456789';
    console.log(`      ${wa3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0883456789': ${witAuth?.phone ?? 'MISSING'}`);
    const wa4Ok = witAuth?.address === '10 Pirie Street, Adelaide SA 5000';
    console.log(`      ${wa4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '10 Pirie Street, Adelaide SA 5000': ${witAuth?.address ?? 'MISSING'}`);
    const wa5Ok = witAuth?.other?.witness_category === 'JUSTICE_OF_PEACE';
    console.log(`      ${wa5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.witness_category === 'JUSTICE_OF_PEACE': ${witAuth?.other?.witness_category ?? 'MISSING'}`);
    const wa6Ok = witAuth?.other?.signature === 'Sarah Lane JP';
    console.log(`      ${wa6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.signature === 'Sarah Lane JP': ${witAuth?.other?.signature ?? 'MISSING'}`);
    const wa7Ok = witAuth?.other?.date === '2026-03-15';
    console.log(`      ${wa7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.date === '2026-03-15': ${witAuth?.other?.date ?? 'MISSING'}`);

    // Person 4: SUBSTITUTE_DECISION_MAKER_SECONDARY
    console.log('    SUBSTITUTE_DECISION_MAKER_SECONDARY:');
    const sdmSec = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER_SECONDARY');
    const ss1Ok = sdmSec?.full_name === 'James Adams';
    console.log(`      ${ss1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'James Adams': ${sdmSec?.full_name ?? 'MISSING'}`);
    const ss2Ok = sdmSec?.phone === '0884567890';
    console.log(`      ${ss2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} phone === '0884567890': ${sdmSec?.phone ?? 'MISSING'}`);
    const ss3Ok = sdmSec?.address === '5 Rundle Mall, Adelaide SA 5000';
    console.log(`      ${ss3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} address === '5 Rundle Mall, Adelaide SA 5000': ${sdmSec?.address ?? 'MISSING'}`);

    // Person 5: INTERPRETER
    console.log('    INTERPRETER:');
    const interp = persons.find((p) => p.person_type === 'INTERPRETER');
    const in1Ok = interp?.full_name === 'Elena Papadopoulos';
    console.log(`      ${in1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_name === 'Elena Papadopoulos': ${interp?.full_name ?? 'MISSING'}`);
    const in2Ok = interp?.dob === '1982-06-15';
    console.log(`      ${in2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} dob === '1982-06-15': ${interp?.dob ?? 'MISSING'}`);
    const in3Ok = interp?.other?.language === 'Greek';
    console.log(`      ${in3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.language === 'Greek': ${interp?.other?.language ?? 'MISSING'}`);
    const in4Ok = interp?.other?.naati_number === 'NAATI-7788';
    console.log(`      ${in4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other.naati_number === 'NAATI-7788': ${interp?.other?.naati_number ?? 'MISSING'}`);

    // Total persons count
    const personsCountOk = Array.isArray(persons) && persons.length >= 5;
    console.log(`    ${personsCountOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} Total persons >= 5: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
