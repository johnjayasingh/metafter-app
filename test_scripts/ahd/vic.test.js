/**
 * AHD Integration Tests — Victoria (VIC)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — REFUSE with specifics
 *  4. CPR and resuscitation
 *  5. Organ and body donation
 *  6. Treatment decisions (VIC)
 *  7. AHD persons — substitute decision maker + witness
 *  8. Declarations and wishes
 *  9. ACD revoked flag
 * 10. Medical treatment consent/refuse (flat fields)
 * 11. GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/vic.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — Victoria (VIC)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Hypertension, Type 2 diabetes',
        things_important_for_me:                     'Remaining independent and at home',
        beliefs_considered_during_health_care:       'Strong preference for natural recovery',
        nearing_death_preference:                    'Comfort care; pain management only',
        people_not_to_involve_healthcare_discussion: 'My estranged brother Kevin',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'MANAGED_SYMPTOMS', 'SPIRITUAL_CARE'],
      },
    });
    printResult('POST /user/ahd (VIC minimal health_conditions)', res, 200);
    const d = res.body?.data;
    const ok = d?.health_conditions?.major_health_conditions != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} health_conditions.major_health_conditions persisted`);
  }

  // ── 2. Life sustaining — CONSENT ─────────────────────────────────────
  printSection('Scenario 2: Life sustaining treatment — CONSENT');
  {
    const res = await request('POST', '/user/ahd', {
      life_sustaining_treatment: {
        direction_type:        'CONSENT',
        direction_instruction: 'Consent to all life-sustaining treatment.',
        assisted_ventilation:  'CONSENT',
        artificial_nutrition:  'CONSENT',
        antibiotics:           'CONSENT',
        blood_transfusion:     'CONSENT',
      },
    });
    printResult('POST /user/ahd (VIC LST CONSENT)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'CONSENT';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
  }

  // ── 3. Life sustaining — REFUSE with specifics ────────────────────────
  printSection('Scenario 3: Life sustaining treatment — REFUSE with per-treatment instructions');
  {
    const res = await request('POST', '/user/ahd', {
      life_sustaining_treatment: {
        direction_type:                      'REFUSE',
        direction_instruction:               'Refuse all unless comfort care.',
        assisted_ventilation:                'REFUSE',
        assisted_ventilation_instruction:    'Do not intubate.',
        artificial_nutrition:                'REFUSE',
        artificial_nutrition_instruction:    'No PEG tube.',
        antibiotics: 'CANT_DECIDE',
        antibiotics_instruction:             'Attorney to decide case by case.',
        blood_transfusion:                   'CONSENT',
        other_treatment: 'CANT_DECIDE',
        other_instruction:                   'No dialysis unless expected full recovery.',
      },
    });
    printResult('POST /user/ahd (VIC LST REFUSE)', res, 200);
    const d = res.body?.data;
    const ok = d?.life_sustaining_treatment?.direction_type === 'REFUSE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} direction_type: ${d?.life_sustaining_treatment?.direction_type}`);
    console.log(`    \x1b[36m?\x1b[0m antibiotics: ${d?.life_sustaining_treatment?.antibiotics}`);
  }

  // ── 4. CPR and resuscitation ──────────────────────────────────────────
  printSection('Scenario 4: CPR and resuscitation');
  {
    const res = await request('POST', '/user/ahd', {
      cpr_and_resuscitation: {
        cpr_instruction: 'UNBEARABLE',
        medical_not_expected_to_recover: 'REJECT_CPR',
        cpr_resuscitation: 'REFUSE',
        cpr_resuscitation_instruction:    'Do not attempt CPR.',
        cpr_consent: 'ALLOW_TO_DIE',
        cpr_consent_instruction:          'No resuscitation in any form.',
      },
    });
    printResult('POST /user/ahd (VIC CPR)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 5. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 5: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      organ_donation: 'CONSENT',
    });
    printResult('POST /user/ahd (VIC organ_donation)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_donation === 'CONSENT';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} organ_donation: ${d?.organ_donation}`);
  }

  // ── 6. Treatment decisions ────────────────────────────────────────────
  printSection('Scenario 6: Treatment decisions (VIC)');
  {
    const res = await request('POST', '/user/ahd', {
      treatment_decisions: {
        life_sustaining_treatment: 'CANT_DECIDE',
        artificial_hydration:                       'CONSENT',
        artificial_hydration_instruction:           'IV fluids are acceptable.',
        other_treatment_decision: 'CANT_DECIDE',
        other_treatment_decision_instruction:       'As per living will on file.',
        health_circumstance_decision_instruction:   'If PVS, withdraw all treatment.',
        consent_palliative_comfort_care:            'CONSENT',
        specific_treatment_no_consent: 'ARTIFICIAL_FEEDING',
        specific_treatment_no_consent_instruction:  'No experimental treatments.',
        healthcare_preferred:                       'Royal Melbourne Hospital preferred.',
      },
    });
    printResult('POST /user/ahd (VIC treatment decisions)', res, 200);
    const d = res.body?.data;
    const ok = d?.treatment_decisions?.life_sustaining_treatment != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} treatment_decisions.life_sustaining_treatment: ${d?.treatment_decisions?.life_sustaining_treatment}`);
  }

  // ── 7. AHD persons ────────────────────────────────────────────────────
  printSection('Scenario 7: AHD persons — substitute decision maker + witness');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: true,
      ahd_persons: [
        {
          full_name:   'Margaret White',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone:       '0398765432',
          address:     '44 Flinders Street, Melbourne VIC 3000',
        },
        {
          full_name:   'Dr. James Anderson',
          person_type: 'WITNESS_MEDICAL_PRACTITIONER',
          phone:       '0312345678',
          address:     '200 St Kilda Road, Melbourne VIC 3004',
          other: {
            qualification: 'General Practitioner',
          },
        },
        {
          full_name:   'Sarah Thompson',
          person_type: 'WITNESS_PERSON',
          phone:       '0398761111',
          address:     '12 Collins Street, Melbourne VIC 3000',
        },
        {
          full_name:   'Carlos Rivera',
          person_type: 'INTERPRETER',
          dob:         '1978-11-20',
          other: {
            language:    'Spanish',
            naati_number: 'NAATI-5432',
          },
        },
      ],
    });
    printResult('POST /user/ahd (VIC ahd_persons)', res, 200);
    const d = res.body?.data;
    const persons = d?.ahd_persons ?? [];
    const hasSdm = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    console.log(`    ${hasSdm ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 8. Declarations and wishes ────────────────────────────────────────
  printSection('Scenario 8: Declarations and wishes');
  {
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I provide this directive of my own free will.',
        what_matter_most:                          'Time with family and being pain-free.',
        what_worries_most:                         'Losing the ability to communicate.',
        unacceptable_medical_treatment_outcome:    'Permanent vegetative state.',
        other_things_known:                        'I have a strong faith.',
        other_people_involved_in_care_discussion:  'My daughter Lisa.',
        appointment_conditon:                      'Only when I lack capacity.',
        other_medical_decision:                    'No gastric feeding tube.',
        cultural_request:                          'Christian burial rites.',
        religious_beliefs:                         'Roman Catholic.',
        after_death_importance:                    'Burial near family.',
        medical_not_expected_to_recover_instruction: 'Comfort care only.',
        nearing_death_instruction:                 'Keep family informed at all times.',
      },
    });
    printResult('POST /user/ahd (VIC declarations)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes.declaration persisted`);
  }

  // ── 9. ACD revoked ────────────────────────────────────────────────────
  printSection('Scenario 9: ACD revoked flag and expiry date');
  {
    const res = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2026-12-31',
    });
    printResult('POST /user/ahd (VIC acd_revoked)', res, 200);
    const d = res.body?.data;
    const ok = d?.is_acd_revoked === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_acd_revoked: ${d?.is_acd_revoked}`);
    console.log(`    \x1b[36m?\x1b[0m acd_expiry_date: ${d?.acd_expiry_date}`);
  }

  // ── 10. Medical treatment consent/refuse (top-level flat fields) ──────
  printSection('Scenario 10: medical_treatment_consent + medical_treatment_refuse');
  {
    const res = await request('POST', '/user/ahd', {
      medical_treatment_consent: 'I consent to palliative pain management including morphine.',
      medical_treatment_refuse:  'I refuse artificial nutrition and ventilation.',
    });
    printResult('POST /user/ahd (VIC consent/refuse flat fields)', res, 200);
    const d = res.body?.data;
    const consentOk = d?.medical_treatment_consent != null;
    const refuseOk  = d?.medical_treatment_refuse != null;
    console.log(`    ${consentOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} medical_treatment_consent: ${d?.medical_treatment_consent ?? 'MISSING'}`);
    console.log(`    ${refuseOk  ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} medical_treatment_refuse: ${d?.medical_treatment_refuse ?? 'MISSING'}`);
  }

  // ── 11. GET round-trip ─────────────────────────────────────────────────
  printSection('Scenario 11: GET round-trip — stored value assertions');
  {
    const res = await request('GET', '/user/ahd');
    printResult('GET  /user/ahd', res, 200);
    const d = res.body?.data;

    const check = (label, actual, expected) => {
      const ok = actual === expected;
      console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ${label} === '${expected}': ${actual ?? 'MISSING'}`);
    };

    // ── Top-level flags ──
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked}`);
    check('acd_expiry_date', d?.acd_expiry_date, '2026-12-31');
    const eguardOk = d?.is_enduring_guardian_appointed === true;
    console.log(`    ${eguardOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === true: ${d?.is_enduring_guardian_appointed}`);

    // ── Health conditions (scenario 1) ──
    const hc = d?.health_conditions;
    check('health_conditions.major_health_conditions', hc?.major_health_conditions, 'Hypertension, Type 2 diabetes');
    check('health_conditions.things_important_for_me', hc?.things_important_for_me, 'Remaining independent and at home');
    check('health_conditions.beliefs_considered_during_health_care', hc?.beliefs_considered_during_health_care, 'Strong preference for natural recovery');
    check('health_conditions.nearing_death_preference', hc?.nearing_death_preference, 'Comfort care; pain management only');
    check('health_conditions.people_not_to_involve_healthcare_discussion', hc?.people_not_to_involve_healthcare_discussion, 'My estranged brother Kevin');
    const comfortArr = hc?.comfort_nearing_death;
    const comfortIsArr = Array.isArray(comfortArr);
    const comfortHasVal = comfortIsArr && comfortArr.includes('LOVED_ONES_NEARBY');
    const comfortLen = comfortIsArr && comfortArr.length >= 3;
    console.log(`    ${comfortIsArr ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death is array: ${comfortIsArr}`);
    console.log(`    ${comfortLen ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death length >= 3: ${comfortIsArr ? comfortArr.length : 'N/A'}`);
    console.log(`    ${comfortHasVal ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death includes 'LOVED_ONES_NEARBY': ${comfortHasVal}`);

    // ── Life sustaining treatment (scenario 3 overwrites 2) ──
    const lst = d?.life_sustaining_treatment;
    check('life_sustaining_treatment.direction_type', lst?.direction_type, 'REFUSE');
    check('life_sustaining_treatment.direction_instruction', lst?.direction_instruction, 'Refuse all unless comfort care.');
    check('life_sustaining_treatment.assisted_ventilation', lst?.assisted_ventilation, 'REFUSE');
    check('life_sustaining_treatment.assisted_ventilation_instruction', lst?.assisted_ventilation_instruction, 'Do not intubate.');
    check('life_sustaining_treatment.artificial_nutrition', lst?.artificial_nutrition, 'REFUSE');
    check('life_sustaining_treatment.artificial_nutrition_instruction', lst?.artificial_nutrition_instruction, 'No PEG tube.');
    check('life_sustaining_treatment.antibiotics', lst?.antibiotics, 'CANT_DECIDE');
    check('life_sustaining_treatment.antibiotics_instruction', lst?.antibiotics_instruction, 'Attorney to decide case by case.');
    check('life_sustaining_treatment.blood_transfusion', lst?.blood_transfusion, 'CONSENT');
    check('life_sustaining_treatment.other_treatment', lst?.other_treatment, 'CANT_DECIDE');
    check('life_sustaining_treatment.other_instruction', lst?.other_instruction, 'No dialysis unless expected full recovery.');

    // ── CPR and resuscitation (scenario 4) ──
    const cpr = d?.cpr_and_resuscitation;
    check('cpr_and_resuscitation.cpr_instruction', cpr?.cpr_instruction, 'UNBEARABLE');
    check('cpr_and_resuscitation.medical_not_expected_to_recover', cpr?.medical_not_expected_to_recover, 'REJECT_CPR');
    check('cpr_and_resuscitation.cpr_resuscitation', cpr?.cpr_resuscitation, 'REFUSE');
    check('cpr_and_resuscitation.cpr_resuscitation_instruction', cpr?.cpr_resuscitation_instruction, 'Do not attempt CPR.');
    check('cpr_and_resuscitation.cpr_consent', cpr?.cpr_consent, 'ALLOW_TO_DIE');
    check('cpr_and_resuscitation.cpr_consent_instruction', cpr?.cpr_consent_instruction, 'No resuscitation in any form.');

    // ── Organ donation (flat for VIC, scenario 5) ──
    check('organ_donation', d?.organ_donation, 'CONSENT');

    // ── Treatment decisions (scenario 6) ──
    const td = d?.treatment_decisions;
    check('treatment_decisions.life_sustaining_treatment', td?.life_sustaining_treatment, 'CANT_DECIDE');
    check('treatment_decisions.artificial_hydration', td?.artificial_hydration, 'CONSENT');
    check('treatment_decisions.artificial_hydration_instruction', td?.artificial_hydration_instruction, 'IV fluids are acceptable.');
    check('treatment_decisions.other_treatment_decision', td?.other_treatment_decision, 'CANT_DECIDE');
    check('treatment_decisions.other_treatment_decision_instruction', td?.other_treatment_decision_instruction, 'As per living will on file.');
    check('treatment_decisions.health_circumstance_decision_instruction', td?.health_circumstance_decision_instruction, 'If PVS, withdraw all treatment.');
    check('treatment_decisions.consent_palliative_comfort_care', td?.consent_palliative_comfort_care, 'CONSENT');
    check('treatment_decisions.specific_treatment_no_consent', td?.specific_treatment_no_consent, 'ARTIFICIAL_FEEDING');
    check('treatment_decisions.specific_treatment_no_consent_instruction', td?.specific_treatment_no_consent_instruction, 'No experimental treatments.');
    check('treatment_decisions.healthcare_preferred', td?.healthcare_preferred, 'Royal Melbourne Hospital preferred.');

    // ── AHD persons (scenario 7) ──
    const persons = d?.ahd_persons ?? [];

    const sdm = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    check('SDM full_name', sdm?.full_name, 'Margaret White');
    check('SDM phone', sdm?.phone, '0398765432');
    check('SDM address', sdm?.address, '44 Flinders Street, Melbourne VIC 3000');

    const medWit = persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    check('WITNESS_MEDICAL_PRACTITIONER full_name', medWit?.full_name, 'Dr. James Anderson');
    check('WITNESS_MEDICAL_PRACTITIONER phone', medWit?.phone, '0312345678');
    check('WITNESS_MEDICAL_PRACTITIONER address', medWit?.address, '200 St Kilda Road, Melbourne VIC 3004');
    const qualVal = medWit?.other?.qualification ?? medWit?.qualification;
    const qualOk = qualVal === 'General Practitioner';
    console.log(`    ${qualOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS_MEDICAL_PRACTITIONER other.qualification === 'General Practitioner': ${qualVal ?? 'MISSING'}`);

    const witPerson = persons.find((p) => p.person_type === 'WITNESS_PERSON');
    check('WITNESS_PERSON full_name', witPerson?.full_name, 'Sarah Thompson');
    check('WITNESS_PERSON phone', witPerson?.phone, '0398761111');
    check('WITNESS_PERSON address', witPerson?.address, '12 Collins Street, Melbourne VIC 3000');

    const interp = persons.find((p) => p.person_type === 'INTERPRETER');
    check('INTERPRETER full_name', interp?.full_name, 'Carlos Rivera');
    check('INTERPRETER dob', interp?.dob, '1978-11-20');
    const interpLang = interp?.other?.language;
    const interpLangOk = interpLang === 'Spanish';
    console.log(`    ${interpLangOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} INTERPRETER other.language === 'Spanish': ${interpLang ?? 'MISSING'}`);
    const interpNaati = interp?.other?.naati_number;
    const interpNaatiOk = interpNaati === 'NAATI-5432';
    console.log(`    ${interpNaatiOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} INTERPRETER other.naati_number === 'NAATI-5432': ${interpNaati ?? 'MISSING'}`);

    const personsCountOk = Array.isArray(persons) && persons.length >= 4;
    console.log(`    ${personsCountOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} Total persons >= 4: ${Array.isArray(persons) ? persons.length : '?'}`);

    // ── Declarations and wishes (scenario 8) ──
    const dw = d?.declarations_and_wishes;
    check('declarations_and_wishes.declaration', dw?.declaration, 'I provide this directive of my own free will.');
    check('declarations_and_wishes.what_matter_most', dw?.what_matter_most, 'Time with family and being pain-free.');
    check('declarations_and_wishes.what_worries_most', dw?.what_worries_most, 'Losing the ability to communicate.');
    check('declarations_and_wishes.unacceptable_medical_treatment_outcome', dw?.unacceptable_medical_treatment_outcome, 'Permanent vegetative state.');
    check('declarations_and_wishes.other_things_known', dw?.other_things_known, 'I have a strong faith.');
    check('declarations_and_wishes.other_people_involved_in_care_discussion', dw?.other_people_involved_in_care_discussion, 'My daughter Lisa.');
    check('declarations_and_wishes.appointment_conditon', dw?.appointment_conditon, 'Only when I lack capacity.');
    check('declarations_and_wishes.other_medical_decision', dw?.other_medical_decision, 'No gastric feeding tube.');
    check('declarations_and_wishes.cultural_request', dw?.cultural_request, 'Christian burial rites.');
    check('declarations_and_wishes.religious_beliefs', dw?.religious_beliefs, 'Roman Catholic.');
    check('declarations_and_wishes.after_death_importance', dw?.after_death_importance, 'Burial near family.');
    check('declarations_and_wishes.medical_not_expected_to_recover_instruction', dw?.medical_not_expected_to_recover_instruction, 'Comfort care only.');
    check('declarations_and_wishes.nearing_death_instruction', dw?.nearing_death_instruction, 'Keep family informed at all times.');

    // ── Medical treatment flat fields (scenario 10) ──
    check('medical_treatment_consent', d?.medical_treatment_consent, 'I consent to palliative pain management including morphine.');
    check('medical_treatment_refuse', d?.medical_treatment_refuse, 'I refuse artificial nutrition and ventilation.');
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
