/**
 * POA Integration Tests — Victoria (VIC)
 *
 * Scenarios:
 *  1. Financial matters only, single attorney, commencement IMMEDIATELY
 *  2. Personal/health matters only
 *  3. Both financial + personal/health matters
 *  4. Successive attorneys (appoint_successive_attorneys=true)
 *  5. Needs signing assistance
 *  6. VIC conditions/limitations — ci_* fields (API uses ci_* prefix)
 *  7. Additional attorney instructions
 *  8. Specific matters (via conditions_limitations)
 *  9. Enduring guardian fields (eg_can_decide_living_place, etc.)
 * 10. Previous valid POA present
 * 11. GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/vic.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary,
  clearAttorneysByType,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const ATK_FINANCIAL = {
  full_name:     'Oliver Barnes',
  address:       '200 Collins Street, Melbourne VIC 3000',
  email:         'oliver.barnes@example.com',
  phone:         '0396661234',
  attorney_type: 'PRIMARY',
};

const ATK_GUARDIAN = {
  full_name:     'Sophie Turner',
  address:       '15 Bourke Street, Melbourne VIC 3000',
  email:         'sophie.turner@example.com',
  phone:         '0387654321',
  attorney_type: 'ENDURING_GUARDIAN',
};

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — Victoria (VIC)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Financial matters only, IMMEDIATELY ─────────────────────────────
  printSection('Scenario 1: Financial matters only, IMMEDIATELY');
  {
    await clearAttorneysByType('PRIMARY');
    await request('POST', '/user/attorney-for-poa', ATK_FINANCIAL);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      has_preference:        false,
      has_attorney_instruction: false,
      need_signing_assistance:  false,
    });
    printResult('POST /user/power-of-attorney (VIC financial only)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = Array.isArray(d?.matters) && d.matters.includes('FINANCE');
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} matters includes FINANCE: ${JSON.stringify(d?.matters)}`);
  }

  // ── 2. Personal/health matters only ───────────────────────────────────
  printSection('Scenario 2: Personal/health matters (PERSONAL_HEALTH) only');
  {
    await clearAttorneysByType('ENDURING_GUARDIAN');
    await request('POST', '/user/attorney-for-poa', ATK_GUARDIAN);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters: ['PERSONAL', 'HEALTH'],
      has_preference:         false,
      has_attorney_instruction: false,
      need_signing_assistance:  false,
    });
    printResult('POST /user/power-of-attorney (VIC personal/health only)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = Array.isArray(d?.matters) && (d.matters.includes('PERSONAL') || d.matters.includes('HEALTH'));
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} matters includes PERSONAL/HEALTH: ${JSON.stringify(d?.matters)}`);
  }

  // ── 3. Both matters ────────────────────────────────────────────────────
  printSection('Scenario 3: Both FINANCIAL + PERSONAL_HEALTH');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE', 'PERSONAL', 'HEALTH'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      has_preference:        false,
    });
    printResult('POST /user/power-of-attorney (VIC both matters)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.matters?.length >= 2;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} Two matters stored: ${JSON.stringify(d?.matters)}`);
  }

  // ── 4. Successive attorneys ────────────────────────────────────────────
  printSection('Scenario 4: Appoint successive attorneys');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                     ['FINANCE'],
      financial_commencement:      'IMMEDIATELY_OTHERS',
      appoint_successive_attorneys: true,
    });
    printResult('POST /user/power-of-attorney (VIC successive)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.appoint_successive_attorneys === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} appoint_successive_attorneys = true: ${d?.appoint_successive_attorneys}`);
  }

  // ── 5. Signing assistance needed ──────────────────────────────────────
  printSection('Scenario 5: Signing assistance needed');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      need_signing_assistance: true,
    });
    printResult('POST /user/power-of-attorney (VIC signing assistance)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.need_signing_assistance === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} need_signing_assistance = true: ${d?.need_signing_assistance}`);
  }

  // ── 6. VIC conditions/limitations — plain text + ci_* fields ──────────
  printSection('Scenario 6: VIC conditions/limitations — plain text + ci_* fields');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                     ['FINANCE'],
      financial_commencement:      'IMMEDIATELY_OTHERS',
      has_conditions_limitations:  true,
      conditions_limitations:      'Attorney must consult family before major property decisions.',
      ci_conflict_transactions:    'Attorney may enter conflict transactions only with OPA approval.',
      ci_gifts:                    'Gifts limited to $1,000 per year.',
      ci_dependent_maintenance:    'Maintain my dependents at current standard.',
      ci_payment_to_attorney:      'No payments to attorney without court approval.',
      ci_additional_condition:     'Advise agents to act in best interests.',
    });
    printResult('POST /user/power-of-attorney (VIC conditions + ci_*)', poaRes, 200);
    const d = poaRes.body?.data;
    const condOk = d?.has_conditions_limitations === true;
    console.log(`    ${condOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_conditions_limitations: ${d?.has_conditions_limitations}`);
    console.log(`    ${d?.conditions_limitations ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} conditions_limitations (plain text): "${d?.conditions_limitations?.slice(0, 50)}"`);
  }

  // ── 7. Attorney instruction ────────────────────────────────────────────
  printSection('Scenario 7: Attorney additional instruction');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                  ['FINANCE'],
      financial_commencement:   'IMMEDIATELY_OTHERS',
      has_attorney_instruction: true,
      attorney_instruction:     'Prioritise keeping the family home.',
      attorney_additional_powers: 'REASONABLE_GIFTS',
    });
    printResult('POST /user/power-of-attorney (VIC attorney instruction)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.attorney_instruction != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_instruction persisted: "${d?.attorney_instruction?.slice(0, 40)}..."`);
    console.log(`    ${d?.attorney_additional_powers ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_additional_powers: ${d?.attorney_additional_powers}`);
  }

  // ── 8. Specific matters (VIC — stored via conditions_limitations) ─────
  printSection('Scenario 8: Specific matters (VIC)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                    ['FINANCE', 'SPECIFIC'],
      financial_commencement:     'IMMEDIATELY_OTHERS',
      has_conditions_limitations: true,
      conditions_limitations:     'Only manage rental properties at 42 Bourke St and 7 Flinders Ln.',
    });
    printResult('POST /user/power-of-attorney (VIC SPECIFIC matters)', poaRes, 200);
    const d = poaRes.body?.data;
    const mattersOk = Array.isArray(d?.matters) && d.matters.includes('SPECIFIC');
    console.log(`    ${mattersOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} matters includes SPECIFIC: ${JSON.stringify(d?.matters)}`);
  }

  // ── 9. Enduring guardian fields ────────────────────────────────────────
  printSection('Scenario 9: Enduring guardian decisions (VIC)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                            ['PERSONAL', 'HEALTH'],
      eg_can_decide_living_place:         true,
      eg_living_place_detail:             'Prefer to remain at home as long as possible.',
      eg_can_decide_services:             true,
      eg_can_decide_healthcare:           true,
      eg_healthcare_detail:               'No life-prolonging treatment if no reasonable prospect of recovery.',
      eg_can_decide_other_personal_service: false,
      eg_can_consent_medical_and_dental:  true,
      eg_has_directions:                  true,
      eg_directions_detail:               'Guardian must involve my sister in all major decisions.',
    });
    printResult('POST /user/power-of-attorney (VIC enduring guardian)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.eg_can_decide_living_place === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} eg_can_decide_living_place = true: ${d?.eg_can_decide_living_place}`);
  }

  // ── 10. Previous POA (final POST — includes ci_* to preserve for GET) ─
  printSection('Scenario 10: Previous valid POA + ci_* preserved');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                     ['FINANCE', 'SPECIFIC'],
      financial_commencement:      'IMMEDIATELY_OTHERS',
      has_previous_valid_poa:      true,
      previous_poa_detail:         'EPA dated 2019, executed in VIC.',
      has_conditions_limitations:  true,
      conditions_limitations:      'Attorney must consult family before major property decisions.',
      ci_conflict_transactions:    'Attorney may enter conflict transactions only with OPA approval.',
      ci_gifts:                    'Gifts limited to $1,000 per year.',
      ci_dependent_maintenance:    'Maintain my dependents at current standard.',
      ci_payment_to_attorney:      'No payments to attorney without court approval.',
      ci_additional_condition:     'Advise agents to act in best interests.',
      attorney_additional_powers:  'REASONABLE_GIFTS',
    });
    printResult('POST /user/power-of-attorney (VIC previous POA)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_previous_valid_poa === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_previous_valid_poa = true: ${d?.has_previous_valid_poa}`);
  }

  // ── 11. GET round-trip ────────────────────────────────────────────────
  printSection('Scenario 11: GET round-trip');
  {
    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney', getRes, 200);
    const d = getRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m matters: ${JSON.stringify(d?.matters)}`);
    console.log(`    \x1b[36m?\x1b[0m financial_commencement: ${d?.financial_commencement}`);
    // Verify conditions_limitations round-trip (plain text)
    const condOk = d?.conditions_limitations != null;
    console.log(`    ${condOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} conditions_limitations round-trip (plain text): "${d?.conditions_limitations?.slice(0, 50) ?? 'MISSING'}"`);
    // Verify ci_* fields round-trip (API stores ci_* prefix, not cl_*)
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
