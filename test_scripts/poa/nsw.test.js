/**
 * POA Integration Tests — New South Wales (NSW)
 *
 * Scenarios:
 *  1. Financial matters only, single attorney, commencement IMMEDIATELY
 *  2. Personal/health matters only (enduring guardian)
 *  3. Both financial + personal/health
 *  4. Successive attorneys
 *  5. Needs signing assistance
 *  6. With financial preferences
 *  7. Enduring guardian (NSW eg_* fields)
 *  8. Conditions and limitations (simple Yes/No + text)
 *  9. Additional powers (attorney_additional_powers)
 * 10. Previous valid POA
 * 11. Attorneys retrieval + GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/nsw.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary,
  clearAttorneysByType,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const ATK_PRIMARY = {
  full_name:     'Edward Walsh',
  address:       '1 Macquarie Street, Sydney NSW 2000',
  email:         'edward.walsh@example.com',
  phone:         '0211112222',
  attorney_type: 'PRIMARY',
};

const ATK_GUARDIAN = {
  full_name:     'Claire Burton',
  address:       '33 Pitt Street, Sydney NSW 2000',
  email:         'claire.burton@example.com',
  phone:         '0233334444',
  attorney_type: 'ENDURING_GUARDIAN',
};

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — New South Wales (NSW)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Financial only, IMMEDIATELY ────────────────────────────────────
  printSection('Scenario 1: Financial matters only, IMMEDIATELY');
  {
    await clearAttorneysByType('PRIMARY');
    await request('POST', '/user/attorney-for-poa', ATK_PRIMARY);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      has_preference:        false,
      need_signing_assistance: false,
    });
    printResult('POST /user/power-of-attorney (NSW financial IMMEDIATELY)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.matters?.includes('FINANCE');
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} matters: ${JSON.stringify(d?.matters)}`);
    console.log(`    \x1b[36m?\x1b[0m financial_commencement: ${d?.financial_commencement}`);
  }

  // ── 2. Personal/health matters only ───────────────────────────────────
  printSection('Scenario 2: Personal/health matters (PERSONAL_HEALTH) only');
  {
    await clearAttorneysByType('ENDURING_GUARDIAN');
    await request('POST', '/user/attorney-for-poa', ATK_GUARDIAN);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:        ['PERSONAL', 'HEALTH'],
      has_preference: false,
    });
    printResult('POST /user/power-of-attorney (NSW personal/health)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.matters?.includes('PERSONAL') || d?.matters?.includes('HEALTH');
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} matters: ${JSON.stringify(d?.matters)}`);
  }

  // ── 3. Both matters ────────────────────────────────────────────────────
  printSection('Scenario 3: Both FINANCIAL + PERSONAL_HEALTH');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE', 'PERSONAL', 'HEALTH'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      has_preference:        false,
    });
    printResult('POST /user/power-of-attorney (NSW both matters)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.matters?.length >= 2;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} Both matters: ${JSON.stringify(d?.matters)}`);
  }

  // ── 4. Successive attorneys ────────────────────────────────────────────
  printSection('Scenario 4: Successive attorneys (NSW)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                     ['FINANCE'],
      financial_commencement:      'IMMEDIATELY_OTHERS',
      appoint_successive_attorneys: true,
    });
    printResult('POST /user/power-of-attorney (NSW successive)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.appoint_successive_attorneys === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} appoint_successive_attorneys: ${d?.appoint_successive_attorneys}`);
  }

  // ── 5. Signing assistance ─────────────────────────────────────────────
  printSection('Scenario 5: Signing assistance needed');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      need_signing_assistance: true,
    });
    printResult('POST /user/power-of-attorney (NSW signing assistance)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.need_signing_assistance === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} need_signing_assistance: ${d?.need_signing_assistance}`);
  }

  // ── 6. Financial preferences ──────────────────────────────────────────
  printSection('Scenario 6: Financial preferences text');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      has_preference:        true,
      preferences:           'Do not sell the family home unless absolutely necessary.',
    });
    printResult('POST /user/power-of-attorney (NSW with preferences)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_preference === true && d?.preferences;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} preferences: "${d?.preferences?.slice(0, 60)}"`);
  }

  // ── 7. Enduring guardian fields ────────────────────────────────────────
  printSection('Scenario 7: Enduring guardian (NSW eg_* fields)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                            ['PERSONAL', 'HEALTH'],
      eg_can_decide_living_place:         true,
      eg_living_place_detail:             'Prefer supported independent living near family.',
      eg_can_decide_services:             true,
      eg_can_decide_healthcare:           true,
      eg_healthcare_detail:               'Comfort care only; no ventilation if prognosis hopeless.',
      eg_can_decide_other_personal_service: true,
      eg_can_consent_medical_and_dental:  true,
      eg_has_directions:                  true,
      eg_directions_detail:               'Consult my daughter Sarah before any surgical decision.',
    });
    printResult('POST /user/power-of-attorney (NSW enduring guardian)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.eg_can_decide_living_place === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} eg_can_decide_living_place: ${d?.eg_can_decide_living_place}`);
    console.log(`    \x1b[36m?\x1b[0m eg_can_decide_healthcare: ${d?.eg_can_decide_healthcare}`);
    console.log(`    \x1b[36m?\x1b[0m eg_has_directions: ${d?.eg_has_directions}`);
  }

  // ── 8. Conditions + ci_* sub-fields (web↔mobile sync) ────────────
  printSection('Scenario 8: Conditions + ci_* sub-fields (web↔mobile sync)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                    ['FINANCE'],
      financial_commencement:     'IMMEDIATELY_OTHERS',
      has_conditions_limitations: true,
      conditions_limitations:     'Attorney must not sell real property without written family consent.',
      ci_conflict_transactions:   'Report all conflict transactions within 30 days.',
      ci_gifts:                   'No gifts exceeding $500.',
      ci_dependent_maintenance:   'Dependents must be consulted.',
      ci_payment_to_attorney:     'Zero payments to attorney without approval.',
      ci_additional_condition:    'Consult with family solicitor annually.',
    });
    printResult('POST /user/power-of-attorney (NSW conditions + ci_*)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_conditions_limitations === true || d?.conditions_limitations != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} conditions_limitations: "${d?.conditions_limitations?.slice(0, 60) ?? 'via GET'}"`);
  }

  // ── 9. Additional powers ────────────────────────────────────────────
  printSection('Scenario 9: Additional powers (attorney_additional_powers)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                    ['FINANCE'],
      financial_commencement:     'IMMEDIATELY_OTHERS',
      attorney_additional_powers: 'REASONABLE_GIFTS',
    });
    printResult('POST /user/power-of-attorney (NSW additional powers)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.attorney_additional_powers != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_additional_powers: ${d?.attorney_additional_powers}`);
  }

  // ── 10. Previous valid POA (final POST — includes ci_* to preserve) ─
  printSection('Scenario 10: Previous valid POA + ci_* preserved');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                    ['FINANCE'],
      financial_commencement:     'IMMEDIATELY_OTHERS',
      has_previous_valid_poa:     true,
      previous_poa_detail:        'EPA made in 2018 under Powers of Attorney Act 2003 NSW.',
      has_conditions_limitations: true,
      conditions_limitations:     'Attorney must not sell real property without written family consent.',
      ci_conflict_transactions:   'Report all conflict transactions within 30 days.',
      ci_gifts:                   'No gifts exceeding $500.',
      ci_dependent_maintenance:   'Dependents must be consulted.',
      ci_payment_to_attorney:     'Zero payments to attorney without approval.',
      ci_additional_condition:    'Consult with family solicitor annually.',
      attorney_additional_powers: 'REASONABLE_GIFTS',
    });
    printResult('POST /user/power-of-attorney (NSW final POST)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_previous_valid_poa === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_previous_valid_poa: ${d?.has_previous_valid_poa}`);
  }

  // ── 11. Attorneys retrieval + GET round-trip ───────────────────────
  printSection('Scenario 11: Attorneys retrieval + GET round-trip');
  {
    const atksRes = await request('GET', '/user/attorneys-for-poa');
    printResult('GET  /user/attorneys-for-poa', atksRes, 200);
    const atks = atksRes.body?.data ?? [];
    const types = Array.isArray(atks) ? [...new Set(atks.map((a) => a.attorney_type))] : [];
    console.log(`    \x1b[36m?\x1b[0m Attorney types present: ${JSON.stringify(types)}`);
    console.log(`    \x1b[36m?\x1b[0m Total attorneys: ${Array.isArray(atks) ? atks.length : '?'}`);

    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney', getRes, 200);
    const d = getRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m matters: ${JSON.stringify(d?.matters)}`);
    console.log(`    \x1b[36m?\x1b[0m has_preference: ${d?.has_preference}`);
    console.log(`    \x1b[36m?\x1b[0m need_signing_assistance: ${d?.need_signing_assistance}`);
    // Verify conditions_limitations round-trip
    const clOk = d?.has_conditions_limitations === true;
    console.log(`    ${clOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_conditions_limitations round-trip: ${d?.has_conditions_limitations}`);
    console.log(`    ${d?.conditions_limitations ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} conditions_limitations round-trip: "${d?.conditions_limitations?.slice(0, 60) ?? 'MISSING'}"`);
    // Verify ci_* sub-fields round-trip (web↔mobile sync)
    console.log(`    ${d?.ci_conflict_transactions ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} ci_conflict_transactions round-trip: "${d?.ci_conflict_transactions?.slice(0, 40) ?? 'MISSING'}"`);
    console.log(`    ${d?.ci_gifts ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} ci_gifts round-trip: "${d?.ci_gifts?.slice(0, 40) ?? 'MISSING'}"`);
    console.log(`    ${d?.ci_dependent_maintenance ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} ci_dependent_maintenance round-trip: "${d?.ci_dependent_maintenance?.slice(0, 40) ?? 'MISSING'}"`);
    console.log(`    ${d?.ci_payment_to_attorney ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} ci_payment_to_attorney round-trip: "${d?.ci_payment_to_attorney?.slice(0, 40) ?? 'MISSING'}"`);
    console.log(`    ${d?.ci_additional_condition ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} ci_additional_condition round-trip: "${d?.ci_additional_condition?.slice(0, 40) ?? 'MISSING'}"`);
    // Verify attorney_additional_powers round-trip
    console.log(`    ${d?.attorney_additional_powers ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_additional_powers round-trip: ${d?.attorney_additional_powers ?? 'MISSING'}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
