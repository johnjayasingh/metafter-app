/**
 * AHD Integration Tests — Western Australia (WA)
 *
 * Scenarios:
 *  1. Minimal AHD — health_conditions only
 *  2. Life sustaining treatment — CONSENT
 *  3. Life sustaining treatment — REFUSE
 *  4. CPR and resuscitation
 *  5. WA-specific: living preferences
 *  6. WA-specific: medical research consent (all types)
 *  7. WA-specific: attorney_and_advice (has_epg, seek advice)
 *  8. Organ and body donation
 *  9. AHD persons — SDM + attorney + witness + enduring guardians + advisors
 * 10. Declarations and wishes
 * 11. ACD revoked + GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node ahd/wa.test.js
 */

const { login, request, printResult, printSection, printSummary } = require('../utils/api');

async function run() {
  console.log('\n\x1b[1m\x1b[33m═══════════════════════════════════════════════');
  console.log(' AHD Tests — Western Australia (WA)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal: health_conditions only ────────────────────────────────
  printSection('Scenario 1: Minimal AHD — health_conditions only');
  {
    const res = await request('POST', '/user/ahd', {
      health_conditions: {
        major_health_conditions:                     'Motor neurone disease',
        things_important_for_me:                     'Communicating with family and painting',
        beliefs_considered_during_health_care:       'I prioritise quality of life over longevity',
        nearing_death_preference:                    'Palliative care at Sir Charles Gairdner',
        people_not_to_involve_healthcare_discussion: 'My brother Mark',
        comfort_nearing_death: ['LOVED_ONES_NEARBY', 'MANAGED_SYMPTOMS', 'HEALTHY_SURROUNDINGS', 'CULTURAL_RELIGIOUS'],
      },
    });
    printResult('POST /user/ahd (WA minimal)', res, 200);
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
    printResult('POST /user/ahd (WA LST CONSENT)', res, 200);
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
        direction_instruction:            'Refuse all life-sustaining treatment.',
        assisted_ventilation:             'REFUSE',
        assisted_ventilation_instruction: 'No ventilator.',
        artificial_nutrition:             'REFUSE',
        artificial_nutrition_instruction: 'No PEG tube or IV nutrition.',
        antibiotics: 'CANT_DECIDE',
        antibiotics_instruction:          'Decide with treating team.',
        blood_transfusion:                'CONSENT',
        other_treatment: 'CANT_DECIDE',
        other_instruction:                'No dialysis unless expected full recovery.',
        treatment_type: 'REFUSE',
        treatment_instruction: 'Refuse all except palliative and comfort care.',
      },
    });
    printResult('POST /user/ahd (WA LST REFUSE)', res, 200);
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
        cpr_resuscitation_instruction:   'DNAR to be placed prominently on file.',
        cpr_consent: 'ALLOW_TO_DIE',
        cpr_consent_instruction:         'No resuscitation.',
      },
    });
    printResult('POST /user/ahd (WA CPR)', res, 200);
    const d = res.body?.data;
    const ok = d?.cpr_and_resuscitation?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} cpr_instruction: ${d?.cpr_and_resuscitation?.cpr_instruction}`);
  }

  // ── 5. Living preferences (WA-specific) ──────────────────────────────
  printSection('Scenario 5: Living preferences (WA-specific)');
  {
    const res = await request('POST', '/user/ahd', {
      living_preferences: {
        health_treatment_priority:      'Comfort and dignity over longevity',
        living_well_importance: ['SPEND_TIME_WITH_FAMILY', 'LIVE_INDEPENDENTLY', 'KEEP_ACTIVE'],
        is_nearing_death: ['RECEIVE_CARE', 'OTHER'],
        nearing_death_goals_detail:     'Remain pain free and aware.',
        wish_to_live:                   'AT_HOME',
        important_people_nearing_death: 'Partner and adult children.',
        nearing_death_unacceptable:     'Prolonged ICU admission; loss of dignity.',
        where_to_die:                   'HOME',
        where_to_die_instruction:       'My house in Cottesloe, Perth.',
      },
    });
    printResult('POST /user/ahd (WA living_preferences)', res, 200);
    const d = res.body?.data;
    const ok = d?.living_preferences?.health_treatment_priority != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} living_preferences persisted`);
    console.log(`    \x1b[36m?\x1b[0m where_to_die: ${d?.living_preferences?.where_to_die}`);
  }

  // ── 6. Medical research consent (WA-specific) ─────────────────────────
  printSection('Scenario 6: Medical research consent (WA-specific)');
  {
    const res = await request('POST', '/user/ahd', {
      medical_research_consent: {
        placebos: 'IF_IMPROVE_CONDITION',
        use_equipment: 'IF_IMPROVE_CONDITION',
        less_practitioners_support: 'DONT_CONSENT',
        comparative_assessment: 'IF_IMPROVE_CONDITION',
        blood_samples: 'IF_IMPROVE_CONDITION',
        tissue_sample: 'DONT_CONSENT',
        non_intrusive_treatment: 'IF_IMPROVE_CONDITION',
        being_observed: 'IF_IMPROVE_CONDITION',
        undertaking_survey: 'IF_IMPROVE_CONDITION',
        collecing_disclosing_information: 'IF_IMPROVE_CONDITION',
        evaluating_samples: 'DONT_CONSENT',
        other: 'IF_IMPROVE_CONDITION',
      },
    });
    printResult('POST /user/ahd (WA medical_research_consent)', res, 200);
    const d = res.body?.data;
    const ok = d?.medical_research_consent?.placebos != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} medical_research_consent.placebos: ${d?.medical_research_consent?.placebos}`);
    console.log(`    \x1b[36m?\x1b[0m blood_samples: ${d?.medical_research_consent?.blood_samples}`);
    console.log(`    \x1b[36m?\x1b[0m tissue_sample: ${d?.medical_research_consent?.tissue_sample}`);
  }

  // ── 7. Attorney and advice (WA-specific) ────────────────────────────
  printSection('Scenario 7: Attorney and advice (WA-specific)');
  {
    const res = await request('POST', '/user/ahd', {
      attorney_and_advice: {
        attorney_decision_power: 'JOINTLY',
        attorney_decision_power_detail: 'Attorney may make all health decisions.',
        has_used_interpreter: 'ENGLISH_FIRST_LANGUAGE',
        has_epg: 'DONE',
        epg_date:                       '2023-05-15',
        epg_place_detail:               'Perth Law Firm, West Perth WA 6005',
        seek_medical_advice: 'OBTAIN_MEDICAL_ADVICE',
        seek_legal_advice: 'OBTAIN_LEGAL_ADVICE',
      },
    });
    printResult('POST /user/ahd (WA attorney_and_advice)', res, 200);
    const d = res.body?.data;
    const ok = d?.attorney_and_advice?.has_epg === 'DONE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_and_advice.has_epg: ${d?.attorney_and_advice?.has_epg}`);
    console.log(`    \x1b[36m?\x1b[0m seek_medical_advice: ${d?.attorney_and_advice?.seek_medical_advice}`);
  }

  // ── 8. Organ and body donation ────────────────────────────────────────
  printSection('Scenario 8: Organ and body donation');
  {
    const res = await request('POST', '/user/ahd', {
      is_registered_australian_organ_donor: true,
      organ_and_body_donation: {
        donate_organ:               true,
        organ_donation_instruction: 'Eyes and kidneys preferred.',
        consent_organ_donation:     true,
        donate_body:                true,
        consent_body_donation:      true,
        authorisation:              'Authorise for University of WA medical school.',
      },
    });
    printResult('POST /user/ahd (WA organ donation)', res, 200);
    const d = res.body?.data;
    const ok = d?.organ_and_body_donation?.donate_organ === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} donate_organ: ${d?.organ_and_body_donation?.donate_organ}`);
  }

  // ── 9. AHD persons ────────────────────────────────────────────────────
  printSection('Scenario 9: AHD persons — SDM + attorney + witness + enduring guardians + advisors');
  {
    const res = await request('POST', '/user/ahd', {
      is_enduring_guardian_appointed: true,
      ahd_persons: [
        {
          full_name: 'Lisa Gardner',
          person_type: 'SUBSTITUTE_DECISION_MAKER',
          phone: '0892341234',
          address: '10 St Georges Terrace, Perth WA 6000',
        },
        {
          full_name: 'James Gardner',
          person_type: 'ATTORNEY_HEALTH_MATTERS',
          phone: '0892342345',
          address: '10 St Georges Terrace, Perth WA 6000',
        },
        {
          full_name: 'Dr. Anna Brown',
          person_type: 'WITNESS_MEDICAL_PRACTITIONER',
          qualification: 'Palliative Care Specialist',
          phone: '0893453456',
          address: '480 Murray Street, Perth WA 6000',
        },
        {
          full_name: 'Peter Gardner',
          person_type: 'ENDURING_GUARDIAN',
          phone: '0892343456',
          address: '20 Hay Street, Perth WA 6000',
        },
        {
          full_name: 'Emily Gardner',
          person_type: 'SECONDARY_ENDURING_GUARDIAN',
          phone: '0892344567',
          address: '20 Hay Street, Perth WA 6000',
        },
        {
          full_name: 'Michael Gardner',
          person_type: 'TERTIARY_ENDURING_GUARDIAN',
          phone: '0892345678',
          address: '30 Hay Street, Perth WA 6000',
        },
        {
          full_name: 'Dr. Sarah Mills',
          person_type: 'MEDICAL_ADVISOR',
          phone: '0893456789',
          address: '100 Wellington Street, Perth WA 6000',
          other: { practice: 'Perth Medical Centre' },
        },
        {
          full_name: 'Richard Tate',
          person_type: 'LEGAL_ADVISOR',
          phone: '0894567890',
          address: '200 St Georges Terrace, Perth WA 6000',
          other: { practice: 'Tate & Partners Law' },
        },
      ],
    });
    printResult('POST /user/ahd (WA ahd_persons x8)', res, 200);
    const persons = res.body?.data?.ahd_persons ?? [];
    const hasSdm  = Array.isArray(persons) && persons.some((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const hasAtk  = Array.isArray(persons) && persons.some((p) => p.person_type === 'ATTORNEY_HEALTH_MATTERS');
    const hasEg   = Array.isArray(persons) && persons.some((p) => p.person_type === 'ENDURING_GUARDIAN');
    const hasSeg  = Array.isArray(persons) && persons.some((p) => p.person_type === 'SECONDARY_ENDURING_GUARDIAN');
    const hasTeg  = Array.isArray(persons) && persons.some((p) => p.person_type === 'TERTIARY_ENDURING_GUARDIAN');
    const hasMa   = Array.isArray(persons) && persons.some((p) => p.person_type === 'MEDICAL_ADVISOR');
    const hasLa   = Array.isArray(persons) && persons.some((p) => p.person_type === 'LEGAL_ADVISOR');
    console.log(`    ${hasSdm  ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SUBSTITUTE_DECISION_MAKER present`);
    console.log(`    ${hasAtk  ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} ATTORNEY_HEALTH_MATTERS present`);
    console.log(`    ${hasEg   ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} ENDURING_GUARDIAN present`);
    console.log(`    ${hasSeg  ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} SECONDARY_ENDURING_GUARDIAN present`);
    console.log(`    ${hasTeg  ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} TERTIARY_ENDURING_GUARDIAN present`);
    console.log(`    ${hasMa   ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} MEDICAL_ADVISOR present`);
    console.log(`    ${hasLa   ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} LEGAL_ADVISOR present`);
    console.log(`    \x1b[36m?\x1b[0m Total persons: ${Array.isArray(persons) ? persons.length : '?'}`);
  }

  // ── 10. Declarations and wishes ───────────────────────────────────────
  printSection('Scenario 10: Declarations and wishes');
  {
    const res = await request('POST', '/user/ahd', {
      declarations_and_wishes: {
        declaration:                               'I provide this directive freely.',
        what_matter_most:                          'Quality time with family at home.',
        what_worries_most:                         'Dying in pain in hospital.',
        unacceptable_medical_treatment_outcome:    'Persistent vegetative state.',
        cultural_request:                          'Italian Catholic traditions.',
        religious_beliefs:                         'Roman Catholic.',
        after_death_importance:                    'Requiem Mass; buried with family.',
        nearing_death_instruction:                 'Call parish priest; rosary in hand.',
      },
    });
    printResult('POST /user/ahd (WA declarations)', res, 200);
    const d = res.body?.data;
    const ok = d?.declarations_and_wishes?.declaration != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} declarations_and_wishes persisted`);
  }

  // ── 11. ACD revoked + GET round-trip ──────────────────────────────────
  printSection('Scenario 11: ACD revoked + GET round-trip');
  {
    const revRes = await request('POST', '/user/ahd', {
      is_acd_revoked:  true,
      acd_expiry_date: '2026-06-30',
    });
    printResult('POST /user/ahd (WA is_acd_revoked)', revRes, 200);
    console.log(`    ${revRes.body?.data?.is_acd_revoked === true ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_acd_revoked: ${revRes.body?.data?.is_acd_revoked}`);

    const getRes = await request('GET', '/user/ahd');
    printResult('GET  /user/ahd (round-trip assertions)', getRes, 200);
    const d = getRes.body?.data;

    // ── Top-level flags ──
    console.log('\n    \x1b[1m── Top-level flags ──\x1b[0m');
    const revokedOk = d?.is_acd_revoked === true;
    console.log(`    ${revokedOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_acd_revoked === true: ${d?.is_acd_revoked ?? 'MISSING'}`);
    const expiryOk = d?.acd_expiry_date === '2026-06-30';
    console.log(`    ${expiryOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} acd_expiry_date === '2026-06-30': ${d?.acd_expiry_date ?? 'MISSING'}`);
    const egOk = d?.is_enduring_guardian_appointed === true;
    console.log(`    ${egOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_enduring_guardian_appointed === true: ${d?.is_enduring_guardian_appointed ?? 'MISSING'}`);
    const organDonorOk = d?.is_registered_australian_organ_donor === true;
    console.log(`    ${organDonorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_registered_australian_organ_donor === true: ${d?.is_registered_australian_organ_donor ?? 'MISSING'}`);

    // ── health_conditions (scenario 1) ──
    console.log('\n    \x1b[1m── health_conditions ──\x1b[0m');
    const hc = d?.health_conditions;
    const hc1Ok = hc?.major_health_conditions === 'Motor neurone disease';
    console.log(`    ${hc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} major_health_conditions === 'Motor neurone disease': ${hc?.major_health_conditions ?? 'MISSING'}`);
    const hc2Ok = hc?.things_important_for_me === 'Communicating with family and painting';
    console.log(`    ${hc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} things_important_for_me === 'Communicating with family and painting': ${hc?.things_important_for_me ?? 'MISSING'}`);
    const hc3Ok = hc?.beliefs_considered_during_health_care === 'I prioritise quality of life over longevity';
    console.log(`    ${hc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} beliefs_considered_during_health_care === 'I prioritise quality of life over longevity': ${hc?.beliefs_considered_during_health_care ?? 'MISSING'}`);
    const hc4Ok = hc?.nearing_death_preference === 'Palliative care at Sir Charles Gairdner';
    console.log(`    ${hc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_preference === 'Palliative care at Sir Charles Gairdner': ${hc?.nearing_death_preference ?? 'MISSING'}`);
    const hc5Ok = hc?.people_not_to_involve_healthcare_discussion === 'My brother Mark';
    console.log(`    ${hc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} people_not_to_involve_healthcare_discussion === 'My brother Mark': ${hc?.people_not_to_involve_healthcare_discussion ?? 'MISSING'}`);
    const hc6Ok = Array.isArray(hc?.comfort_nearing_death) && hc.comfort_nearing_death.includes('LOVED_ONES_NEARBY');
    console.log(`    ${hc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death includes 'LOVED_ONES_NEARBY': ${JSON.stringify(hc?.comfort_nearing_death ?? 'MISSING')}`);
    const hc7Ok = Array.isArray(hc?.comfort_nearing_death) && hc.comfort_nearing_death.length >= 4;
    console.log(`    ${hc7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comfort_nearing_death length >= 4: ${hc?.comfort_nearing_death?.length ?? 'MISSING'}`);

    // ── life_sustaining_treatment (scenario 3) ──
    console.log('\n    \x1b[1m── life_sustaining_treatment ──\x1b[0m');
    const lst = d?.life_sustaining_treatment;
    const lst1Ok = lst?.direction_type === 'REFUSE';
    console.log(`    ${lst1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_type === 'REFUSE': ${lst?.direction_type ?? 'MISSING'}`);
    const lst2Ok = lst?.direction_instruction === 'Refuse all life-sustaining treatment.';
    console.log(`    ${lst2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} direction_instruction === 'Refuse all life-sustaining treatment.': ${lst?.direction_instruction ?? 'MISSING'}`);
    const lst3Ok = lst?.assisted_ventilation === 'REFUSE';
    console.log(`    ${lst3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation === 'REFUSE': ${lst?.assisted_ventilation ?? 'MISSING'}`);
    const lst4Ok = lst?.assisted_ventilation_instruction === 'No ventilator.';
    console.log(`    ${lst4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} assisted_ventilation_instruction === 'No ventilator.': ${lst?.assisted_ventilation_instruction ?? 'MISSING'}`);
    const lst5Ok = lst?.artificial_nutrition === 'REFUSE';
    console.log(`    ${lst5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition === 'REFUSE': ${lst?.artificial_nutrition ?? 'MISSING'}`);
    const lst6Ok = lst?.artificial_nutrition_instruction === 'No PEG tube or IV nutrition.';
    console.log(`    ${lst6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} artificial_nutrition_instruction === 'No PEG tube or IV nutrition.': ${lst?.artificial_nutrition_instruction ?? 'MISSING'}`);
    const lst7Ok = lst?.antibiotics === 'CANT_DECIDE';
    console.log(`    ${lst7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} antibiotics === 'CANT_DECIDE': ${lst?.antibiotics ?? 'MISSING'}`);
    const lst8Ok = lst?.antibiotics_instruction === 'Decide with treating team.';
    console.log(`    ${lst8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} antibiotics_instruction === 'Decide with treating team.': ${lst?.antibiotics_instruction ?? 'MISSING'}`);
    const lst9Ok = lst?.blood_transfusion === 'CONSENT';
    console.log(`    ${lst9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_transfusion === 'CONSENT': ${lst?.blood_transfusion ?? 'MISSING'}`);
    const lst10Ok = lst?.other_treatment === 'CANT_DECIDE';
    console.log(`    ${lst10Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_treatment === 'CANT_DECIDE': ${lst?.other_treatment ?? 'MISSING'}`);
    const lst11Ok = lst?.other_instruction === 'No dialysis unless expected full recovery.';
    console.log(`    ${lst11Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other_instruction === 'No dialysis unless expected full recovery.': ${lst?.other_instruction ?? 'MISSING'}`);
    const lst12Ok = lst?.treatment_type === 'REFUSE';
    console.log(`    ${lst12Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_type === 'REFUSE': ${lst?.treatment_type ?? 'MISSING'}`);
    const lst13Ok = lst?.treatment_instruction === 'Refuse all except palliative and comfort care.';
    console.log(`    ${lst13Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} treatment_instruction === 'Refuse all except palliative and comfort care.': ${lst?.treatment_instruction ?? 'MISSING'}`);

    // ── cpr_and_resuscitation (scenario 4) ──
    console.log('\n    \x1b[1m── cpr_and_resuscitation ──\x1b[0m');
    const cpr = d?.cpr_and_resuscitation;
    const cpr1Ok = cpr?.cpr_instruction === 'UNBEARABLE';
    console.log(`    ${cpr1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_instruction === 'UNBEARABLE': ${cpr?.cpr_instruction ?? 'MISSING'}`);
    const cpr2Ok = cpr?.medical_not_expected_to_recover === 'REJECT_CPR';
    console.log(`    ${cpr2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} medical_not_expected_to_recover === 'REJECT_CPR': ${cpr?.medical_not_expected_to_recover ?? 'MISSING'}`);
    const cpr3Ok = cpr?.cpr_resuscitation === 'REFUSE';
    console.log(`    ${cpr3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation === 'REFUSE': ${cpr?.cpr_resuscitation ?? 'MISSING'}`);
    const cpr4Ok = cpr?.cpr_resuscitation_instruction === 'DNAR to be placed prominently on file.';
    console.log(`    ${cpr4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_resuscitation_instruction === 'DNAR to be placed prominently on file.': ${cpr?.cpr_resuscitation_instruction ?? 'MISSING'}`);
    const cpr5Ok = cpr?.cpr_consent === 'ALLOW_TO_DIE';
    console.log(`    ${cpr5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent === 'ALLOW_TO_DIE': ${cpr?.cpr_consent ?? 'MISSING'}`);
    const cpr6Ok = cpr?.cpr_consent_instruction === 'No resuscitation.';
    console.log(`    ${cpr6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cpr_consent_instruction === 'No resuscitation.': ${cpr?.cpr_consent_instruction ?? 'MISSING'}`);

    // ── living_preferences (scenario 5) ──
    console.log('\n    \x1b[1m── living_preferences ──\x1b[0m');
    const lp = d?.living_preferences;
    const lp1Ok = lp?.health_treatment_priority === 'Comfort and dignity over longevity';
    console.log(`    ${lp1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} health_treatment_priority === 'Comfort and dignity over longevity': ${lp?.health_treatment_priority ?? 'MISSING'}`);
    const lp2Ok = Array.isArray(lp?.living_well_importance) && lp.living_well_importance.includes('SPEND_TIME_WITH_FAMILY') && lp.living_well_importance.includes('LIVE_INDEPENDENTLY') && lp.living_well_importance.includes('KEEP_ACTIVE');
    console.log(`    ${lp2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} living_well_importance === ['SPEND_TIME_WITH_FAMILY','LIVE_INDEPENDENTLY','KEEP_ACTIVE']: ${JSON.stringify(lp?.living_well_importance ?? 'MISSING')}`);
    const lp3Ok = Array.isArray(lp?.is_nearing_death) && lp.is_nearing_death.includes('RECEIVE_CARE') && lp.is_nearing_death.includes('OTHER');
    console.log(`    ${lp3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_nearing_death === ['RECEIVE_CARE','OTHER']: ${JSON.stringify(lp?.is_nearing_death ?? 'MISSING')}`);
    const lp4Ok = lp?.nearing_death_goals_detail === 'Remain pain free and aware.';
    console.log(`    ${lp4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_goals_detail === 'Remain pain free and aware.': ${lp?.nearing_death_goals_detail ?? 'MISSING'}`);
    const lp5Ok = lp?.wish_to_live === 'AT_HOME';
    console.log(`    ${lp5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} wish_to_live === 'AT_HOME': ${lp?.wish_to_live ?? 'MISSING'}`);
    const lp6Ok = lp?.important_people_nearing_death === 'Partner and adult children.';
    console.log(`    ${lp6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} important_people_nearing_death === 'Partner and adult children.': ${lp?.important_people_nearing_death ?? 'MISSING'}`);
    const lp7Ok = lp?.nearing_death_unacceptable === 'Prolonged ICU admission; loss of dignity.';
    console.log(`    ${lp7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_unacceptable === 'Prolonged ICU admission; loss of dignity.': ${lp?.nearing_death_unacceptable ?? 'MISSING'}`);
    const lp8Ok = lp?.where_to_die === 'HOME';
    console.log(`    ${lp8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} where_to_die === 'HOME': ${lp?.where_to_die ?? 'MISSING'}`);
    const lp9Ok = lp?.where_to_die_instruction === 'My house in Cottesloe, Perth.';
    console.log(`    ${lp9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} where_to_die_instruction === 'My house in Cottesloe, Perth.': ${lp?.where_to_die_instruction ?? 'MISSING'}`);

    // ── medical_research_consent (scenario 6) ──
    console.log('\n    \x1b[1m── medical_research_consent ──\x1b[0m');
    const mrc = d?.medical_research_consent;
    const mrc1Ok = mrc?.placebos === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} placebos === 'IF_IMPROVE_CONDITION': ${mrc?.placebos ?? 'MISSING'}`);
    const mrc2Ok = mrc?.use_equipment === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} use_equipment === 'IF_IMPROVE_CONDITION': ${mrc?.use_equipment ?? 'MISSING'}`);
    const mrc3Ok = mrc?.less_practitioners_support === 'DONT_CONSENT';
    console.log(`    ${mrc3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} less_practitioners_support === 'DONT_CONSENT': ${mrc?.less_practitioners_support ?? 'MISSING'}`);
    const mrc4Ok = mrc?.comparative_assessment === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} comparative_assessment === 'IF_IMPROVE_CONDITION': ${mrc?.comparative_assessment ?? 'MISSING'}`);
    const mrc5Ok = mrc?.blood_samples === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} blood_samples === 'IF_IMPROVE_CONDITION': ${mrc?.blood_samples ?? 'MISSING'}`);
    const mrc6Ok = mrc?.tissue_sample === 'DONT_CONSENT';
    console.log(`    ${mrc6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} tissue_sample === 'DONT_CONSENT': ${mrc?.tissue_sample ?? 'MISSING'}`);
    const mrc7Ok = mrc?.non_intrusive_treatment === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} non_intrusive_treatment === 'IF_IMPROVE_CONDITION': ${mrc?.non_intrusive_treatment ?? 'MISSING'}`);
    const mrc8Ok = mrc?.being_observed === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} being_observed === 'IF_IMPROVE_CONDITION': ${mrc?.being_observed ?? 'MISSING'}`);
    const mrc9Ok = mrc?.undertaking_survey === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc9Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} undertaking_survey === 'IF_IMPROVE_CONDITION': ${mrc?.undertaking_survey ?? 'MISSING'}`);
    const mrc10Ok = mrc?.collecing_disclosing_information === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc10Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} collecing_disclosing_information === 'IF_IMPROVE_CONDITION': ${mrc?.collecing_disclosing_information ?? 'MISSING'}`);
    const mrc11Ok = mrc?.evaluating_samples === 'DONT_CONSENT';
    console.log(`    ${mrc11Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} evaluating_samples === 'DONT_CONSENT': ${mrc?.evaluating_samples ?? 'MISSING'}`);
    const mrc12Ok = mrc?.other === 'IF_IMPROVE_CONDITION';
    console.log(`    ${mrc12Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} other === 'IF_IMPROVE_CONDITION': ${mrc?.other ?? 'MISSING'}`);

    // ── attorney_and_advice (scenario 7) ──
    console.log('\n    \x1b[1m── attorney_and_advice ──\x1b[0m');
    const aa = d?.attorney_and_advice;
    const aa1Ok = aa?.attorney_decision_power === 'JOINTLY';
    console.log(`    ${aa1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} attorney_decision_power === 'JOINTLY': ${aa?.attorney_decision_power ?? 'MISSING'}`);
    const aa2Ok = aa?.attorney_decision_power_detail === 'Attorney may make all health decisions.';
    console.log(`    ${aa2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} attorney_decision_power_detail === 'Attorney may make all health decisions.': ${aa?.attorney_decision_power_detail ?? 'MISSING'}`);
    const aa3Ok = aa?.has_used_interpreter === 'ENGLISH_FIRST_LANGUAGE';
    console.log(`    ${aa3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} has_used_interpreter === 'ENGLISH_FIRST_LANGUAGE': ${aa?.has_used_interpreter ?? 'MISSING'}`);
    const aa4Ok = aa?.has_epg === 'DONE';
    console.log(`    ${aa4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} has_epg === 'DONE': ${aa?.has_epg ?? 'MISSING'}`);
    const aa5Ok = aa?.epg_date === '2023-05-15';
    console.log(`    ${aa5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} epg_date === '2023-05-15': ${aa?.epg_date ?? 'MISSING'}`);
    const aa6Ok = aa?.epg_place_detail === 'Perth Law Firm, West Perth WA 6005';
    console.log(`    ${aa6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} epg_place_detail === 'Perth Law Firm, West Perth WA 6005': ${aa?.epg_place_detail ?? 'MISSING'}`);
    const aa7Ok = aa?.seek_medical_advice === 'OBTAIN_MEDICAL_ADVICE';
    console.log(`    ${aa7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} seek_medical_advice === 'OBTAIN_MEDICAL_ADVICE': ${aa?.seek_medical_advice ?? 'MISSING'}`);
    const aa8Ok = aa?.seek_legal_advice === 'OBTAIN_LEGAL_ADVICE';
    console.log(`    ${aa8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} seek_legal_advice === 'OBTAIN_LEGAL_ADVICE': ${aa?.seek_legal_advice ?? 'MISSING'}`);

    // ── organ_and_body_donation (scenario 8) ──
    console.log('\n    \x1b[1m── organ_and_body_donation ──\x1b[0m');
    const organ = d?.organ_and_body_donation;
    const org1Ok = organ?.donate_organ === true;
    console.log(`    ${org1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_organ === true: ${organ?.donate_organ ?? 'MISSING'}`);
    const org2Ok = organ?.organ_donation_instruction === 'Eyes and kidneys preferred.';
    console.log(`    ${org2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} organ_donation_instruction === 'Eyes and kidneys preferred.': ${organ?.organ_donation_instruction ?? 'MISSING'}`);
    const org3Ok = organ?.consent_organ_donation === true;
    console.log(`    ${org3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_organ_donation === true: ${organ?.consent_organ_donation ?? 'MISSING'}`);
    const org4Ok = organ?.donate_body === true;
    console.log(`    ${org4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} donate_body === true: ${organ?.donate_body ?? 'MISSING'}`);
    const org5Ok = organ?.consent_body_donation === true;
    console.log(`    ${org5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} consent_body_donation === true: ${organ?.consent_body_donation ?? 'MISSING'}`);
    const org6Ok = organ?.authorisation === 'Authorise for University of WA medical school.';
    console.log(`    ${org6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} authorisation === 'Authorise for University of WA medical school.': ${organ?.authorisation ?? 'MISSING'}`);

    // ── ahd_persons (scenario 9) ──
    console.log('\n    \x1b[1m── ahd_persons ──\x1b[0m');
    const persons = d?.ahd_persons ?? [];
    const personsCountOk = persons.length >= 8;
    console.log(`    ${personsCountOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ahd_persons count >= 8: ${persons.length}`);

    // Person 1: SDM
    const sdm = persons.find((p) => p.person_type === 'SUBSTITUTE_DECISION_MAKER');
    const sdm1Ok = sdm?.full_name === 'Lisa Gardner';
    console.log(`    ${sdm1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM full_name === 'Lisa Gardner': ${sdm?.full_name ?? 'MISSING'}`);
    const sdm2Ok = sdm?.phone === '0892341234';
    console.log(`    ${sdm2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM phone === '0892341234': ${sdm?.phone ?? 'MISSING'}`);
    const sdm3Ok = sdm?.address === '10 St Georges Terrace, Perth WA 6000';
    console.log(`    ${sdm3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SDM address === '10 St Georges Terrace, Perth WA 6000': ${sdm?.address ?? 'MISSING'}`);

    // Person 2: ATTORNEY_HEALTH_MATTERS
    const atk = persons.find((p) => p.person_type === 'ATTORNEY_HEALTH_MATTERS');
    const atk1Ok = atk?.full_name === 'James Gardner';
    console.log(`    ${atk1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ATTORNEY full_name === 'James Gardner': ${atk?.full_name ?? 'MISSING'}`);
    const atk2Ok = atk?.phone === '0892342345';
    console.log(`    ${atk2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ATTORNEY phone === '0892342345': ${atk?.phone ?? 'MISSING'}`);
    const atk3Ok = atk?.address === '10 St Georges Terrace, Perth WA 6000';
    console.log(`    ${atk3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ATTORNEY address === '10 St Georges Terrace, Perth WA 6000': ${atk?.address ?? 'MISSING'}`);

    // Person 3: WITNESS_MEDICAL_PRACTITIONER
    const medWit = persons.find((p) => p.person_type === 'WITNESS_MEDICAL_PRACTITIONER');
    const mw1Ok = medWit?.full_name === 'Dr. Anna Brown';
    console.log(`    ${mw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS full_name === 'Dr. Anna Brown': ${medWit?.full_name ?? 'MISSING'}`);
    const mwQual = medWit?.qualification || medWit?.other?.qualification;
    const mw2Ok = mwQual === 'Palliative Care Specialist';
    console.log(`    ${mw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS qualification === 'Palliative Care Specialist': ${mwQual ?? 'MISSING'}`);
    const mw3Ok = medWit?.phone === '0893453456';
    console.log(`    ${mw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS phone === '0893453456': ${medWit?.phone ?? 'MISSING'}`);
    const mw4Ok = medWit?.address === '480 Murray Street, Perth WA 6000';
    console.log(`    ${mw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} WITNESS address === '480 Murray Street, Perth WA 6000': ${medWit?.address ?? 'MISSING'}`);

    // Person 4: ENDURING_GUARDIAN
    const eg = persons.find((p) => p.person_type === 'ENDURING_GUARDIAN');
    const eg1Ok = eg?.full_name === 'Peter Gardner';
    console.log(`    ${eg1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ENDURING_GUARDIAN full_name === 'Peter Gardner': ${eg?.full_name ?? 'MISSING'}`);
    const eg2Ok = eg?.phone === '0892343456';
    console.log(`    ${eg2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ENDURING_GUARDIAN phone === '0892343456': ${eg?.phone ?? 'MISSING'}`);
    const eg3Ok = eg?.address === '20 Hay Street, Perth WA 6000';
    console.log(`    ${eg3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ENDURING_GUARDIAN address === '20 Hay Street, Perth WA 6000': ${eg?.address ?? 'MISSING'}`);

    // Person 5: SECONDARY_ENDURING_GUARDIAN
    const seg = persons.find((p) => p.person_type === 'SECONDARY_ENDURING_GUARDIAN');
    const seg1Ok = seg?.full_name === 'Emily Gardner';
    console.log(`    ${seg1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SECONDARY_ENDURING_GUARDIAN full_name === 'Emily Gardner': ${seg?.full_name ?? 'MISSING'}`);
    const seg2Ok = seg?.phone === '0892344567';
    console.log(`    ${seg2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} SECONDARY_ENDURING_GUARDIAN phone === '0892344567': ${seg?.phone ?? 'MISSING'}`);

    // Person 6: TERTIARY_ENDURING_GUARDIAN
    const teg = persons.find((p) => p.person_type === 'TERTIARY_ENDURING_GUARDIAN');
    const teg1Ok = teg?.full_name === 'Michael Gardner';
    console.log(`    ${teg1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} TERTIARY_ENDURING_GUARDIAN full_name === 'Michael Gardner': ${teg?.full_name ?? 'MISSING'}`);
    const teg2Ok = teg?.phone === '0892345678';
    console.log(`    ${teg2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} TERTIARY_ENDURING_GUARDIAN phone === '0892345678': ${teg?.phone ?? 'MISSING'}`);

    // Person 7: MEDICAL_ADVISOR
    const ma = persons.find((p) => p.person_type === 'MEDICAL_ADVISOR');
    const ma1Ok = ma?.full_name === 'Dr. Sarah Mills';
    console.log(`    ${ma1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} MEDICAL_ADVISOR full_name === 'Dr. Sarah Mills': ${ma?.full_name ?? 'MISSING'}`);
    const ma2Ok = ma?.phone === '0893456789';
    console.log(`    ${ma2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} MEDICAL_ADVISOR phone === '0893456789': ${ma?.phone ?? 'MISSING'}`);
    const ma3Ok = ma?.other?.practice === 'Perth Medical Centre';
    console.log(`    ${ma3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} MEDICAL_ADVISOR other.practice === 'Perth Medical Centre': ${ma?.other?.practice ?? 'MISSING'}`);

    // Person 8: LEGAL_ADVISOR
    const la = persons.find((p) => p.person_type === 'LEGAL_ADVISOR');
    const la1Ok = la?.full_name === 'Richard Tate';
    console.log(`    ${la1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} LEGAL_ADVISOR full_name === 'Richard Tate': ${la?.full_name ?? 'MISSING'}`);
    const la2Ok = la?.phone === '0894567890';
    console.log(`    ${la2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} LEGAL_ADVISOR phone === '0894567890': ${la?.phone ?? 'MISSING'}`);
    const la3Ok = la?.other?.practice === 'Tate & Partners Law';
    console.log(`    ${la3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} LEGAL_ADVISOR other.practice === 'Tate & Partners Law': ${la?.other?.practice ?? 'MISSING'}`);

    // ── declarations_and_wishes (scenario 10) ──
    console.log('\n    \x1b[1m── declarations_and_wishes ──\x1b[0m');
    const dw = d?.declarations_and_wishes;
    const dw1Ok = dw?.declaration === 'I provide this directive freely.';
    console.log(`    ${dw1Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} declaration === 'I provide this directive freely.': ${dw?.declaration ?? 'MISSING'}`);
    const dw2Ok = dw?.what_matter_most === 'Quality time with family at home.';
    console.log(`    ${dw2Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_matter_most === 'Quality time with family at home.': ${dw?.what_matter_most ?? 'MISSING'}`);
    const dw3Ok = dw?.what_worries_most === 'Dying in pain in hospital.';
    console.log(`    ${dw3Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} what_worries_most === 'Dying in pain in hospital.': ${dw?.what_worries_most ?? 'MISSING'}`);
    const dw4Ok = dw?.unacceptable_medical_treatment_outcome === 'Persistent vegetative state.';
    console.log(`    ${dw4Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} unacceptable_medical_treatment_outcome === 'Persistent vegetative state.': ${dw?.unacceptable_medical_treatment_outcome ?? 'MISSING'}`);
    const dw5Ok = dw?.cultural_request === 'Italian Catholic traditions.';
    console.log(`    ${dw5Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} cultural_request === 'Italian Catholic traditions.': ${dw?.cultural_request ?? 'MISSING'}`);
    const dw6Ok = dw?.religious_beliefs === 'Roman Catholic.';
    console.log(`    ${dw6Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} religious_beliefs === 'Roman Catholic.': ${dw?.religious_beliefs ?? 'MISSING'}`);
    const dw7Ok = dw?.after_death_importance === 'Requiem Mass; buried with family.';
    console.log(`    ${dw7Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} after_death_importance === 'Requiem Mass; buried with family.': ${dw?.after_death_importance ?? 'MISSING'}`);
    const dw8Ok = dw?.nearing_death_instruction === 'Call parish priest; rosary in hand.';
    console.log(`    ${dw8Ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} nearing_death_instruction === 'Call parish priest; rosary in hand.': ${dw?.nearing_death_instruction ?? 'MISSING'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
