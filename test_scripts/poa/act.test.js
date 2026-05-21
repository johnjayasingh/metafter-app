/**
 * POA Integration Tests — Australian Capital Territory (ACT)
 *
 * Scenarios:
 *  1. 1 attorney (non-corporate), powers=ALL_MATTERS, commencement=IMMEDIATELY, no revocation
 *  2. 1 attorney, powers=SPECIFIC_MATTER, specific matters list
 *  3. 2 attorneys, attorney_power_commencement=IMMEDIATELY
 *  4. 3 attorneys
 *  5. Attorney is corporate (is_attorney_corporate=true)
 *  6. Commencement = specific circumstance
 *  7. Has previous valid POA + revocation needed
 *  8. Enduring POA with eIsEpoaSign=true + sign person details
 *  9. GET round-trip validation
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/act.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const BASE = {
  matters:              ['FINANCE'],
  financial_commencement: 'IMMEDIATELY_OTHERS',
};

const ATK1 = {
  attorney_name:              'Patricia Clark',
  attorney_address:           '10 London Circuit, Canberra ACT 2600',
  is_attorney_corporate:      false,
  is_attorney_declared_bankrupt: false,
};

const ATK2 = {
  attorney2_name:               'David Miller',
  attorney2_address:            '5 City Walk, Canberra ACT 2601',
  is_attorney2_corporate:       false,
  is_attorney2_declared_bankrupt: false,
};

const ATK3 = {
  attorney3_name:               'Helen Wong',
  attorney3_address:            '2 Akuna Street, Canberra ACT 2601',
  is_attorney3_corporate:       false,
  is_attorney3_declared_bankrupt: false,
};

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — ACT');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. 1 attorney, ALL_MATTERS, IMMEDIATELY ────────────────────────────
  printSection('Scenario 1: 1 attorney, ALL_MATTERS, IMMEDIATELY');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:       1,
      ...ATK1,
      attorney_powers: 'ALL_POWERS',
      attorney_power_commencement: 'IMMEDIATELY',
      has_previous_valid_poa:    false,
      need_revocation:           false,
    });
    printResult('POST /user/power-of-attorney (ACT 1 atk ALL_MATTERS)', poaRes, 200);
    const d = poaRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m attorney_name stored: "${d?.attorney_name}"`);
  }

  // ── 2. 1 attorney, SPECIFIC_MATTER ────────────────────────────────────
  printSection('Scenario 2: 1 attorney, SPECIFIC_MATTER with matters list');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:         1,
      ...ATK1,
      attorney_powers: 'SOME_POWERS',
      attorney_power_matters:      ['PROPERTY', 'FINANCIAL'],
      attorney_power_detail:       'Management of investment portfolio only.',
      attorney_power_commencement: 'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (ACT SPECIFIC_MATTER)', poaRes, 200);
    const d = poaRes.body?.data;
    const mattersOk = Array.isArray(d?.attorney_power_matters) && d.attorney_power_matters.length > 0;
    console.log(`    ${mattersOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_power_matters stored: ${JSON.stringify(d?.attorney_power_matters)}`);
  }

  // ── 3. 2 attorneys ─────────────────────────────────────────────────────
  printSection('Scenario 3: 2 attorneys');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:         2,
      ...ATK1, ...ATK2,
      attorney_powers: 'ALL_POWERS',
      attorney_power_commencement: 'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (ACT 2 attorneys)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.number_of_attorneys === 2 || d?.attorney2_name != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney2_name: "${d?.attorney2_name}"`);
  }

  // ── 4. 3 attorneys ─────────────────────────────────────────────────────
  printSection('Scenario 4: 3 attorneys');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:         3,
      ...ATK1, ...ATK2, ...ATK3,
      attorney_powers: 'ALL_POWERS',
      attorney_power_commencement: 'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (ACT 3 attorneys)', poaRes, 200);
    const d = poaRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m attorney3_name: "${d?.attorney3_name}"`);
  }

  // ── 5. Corporate attorney ──────────────────────────────────────────────
  printSection('Scenario 5: Corporate attorney');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:         1,
      attorney_name:               'ABC Legal Corp Pty Ltd',
      attorney_address:            '1 Constitution Avenue, Canberra ACT 2600',
      is_attorney_corporate:       true,
      corporation_type: 'OTHERS',
      is_attorney_declared_bankrupt: false,
      attorney_powers: 'ALL_POWERS',
      attorney_power_commencement: 'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (ACT corporate attorney)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.is_attorney_corporate === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} is_attorney_corporate: ${d?.is_attorney_corporate}`);
  }

  // ── 6. Commencement = specific circumstance ────────────────────────────
  printSection('Scenario 6: Commencement on specific circumstance');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:                         1,
      ...ATK1,
      attorney_powers: 'ALL_POWERS',
      attorney_power_commencement:                 'RECEIVING_CONDITION',
      attorney_power_commencement_circumstance:    'Upon loss of capacity as certified by two medical practitioners.',
    });
    printResult('POST /user/power-of-attorney (ACT RECEIVING_CONDITION)', poaRes, 200);
    const d = poaRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m circumstance: "${d?.attorney_power_commencement_circumstance?.slice(0, 50)}..."`);
  }

  // ── 7. Has previous valid POA + needs revocation ───────────────────────
  printSection('Scenario 7: Previous valid POA + revocation needed');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:       1,
      ...ATK1,
      attorney_powers: 'ALL_POWERS',
      attorney_power_commencement: 'IMMEDIATELY',
      has_previous_valid_poa:    true,
      need_revocation:           true,
      previous_poa_detail:       'EPA dated 15 January 2020, registered in ACT.',
    });
    printResult('POST /user/power-of-attorney (ACT prev POA + revocation)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_previous_valid_poa === true && d?.need_revocation === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_previous_valid_poa=${d?.has_previous_valid_poa}, need_revocation=${d?.need_revocation}`);
  }

  // ── 8. isEpoaSign with signing person details ──────────────────────────
  printSection('Scenario 8: Enduring POA signed by another person');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE,
      number_of_attorneys:       1,
      ...ATK1,
      attorney_powers: 'ALL_POWERS',
      attorney_power_commencement: 'IMMEDIATELY',
      is_epoa_sign:              true,
      sign_person_full_name:     'James Clarke',
      sign_person_address:       '77 Northbourne Avenue, Canberra ACT 2600',
    });
    printResult('POST /user/power-of-attorney (ACT is_epoa_sign=true)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.is_epoa_sign === true || d?.sign_person_full_name != null;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} sign_person_full_name: "${d?.sign_person_full_name}"`);
  }

  // ── 9. GET round-trip ──────────────────────────────────────────────────
  printSection('Scenario 9: GET round-trip');
  {
    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney', getRes, 200);
    const d = getRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m matters: ${JSON.stringify(d?.matters)}`);
    console.log(`    \x1b[36m?\x1b[0m number_of_attorneys: ${d?.number_of_attorneys}`);
    console.log(`    \x1b[36m?\x1b[0m attorney_name: "${d?.attorney_name}"`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
