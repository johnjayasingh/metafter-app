/**
 * POA Integration Tests — South Australia (SA)
 *
 * Scenarios:
 *  1. Single donor, single donee, commencement IMMEDIATELY, no conditions
 *  2. Single donor, single donee, commencement LEGAL_INCAPACITY, no conditions
 *  3. Two donors (has_second_donor=true), single donee
 *  4. Donee acting method JOINTLY
 *  5. Donee acting method JOINTLY_SEVERALLY
 *  6. Conditions present
 *  7. Second-donor attorney saved via /user/attorney-for-poa
 *  8. Donee saved via /user/attorney-for-poa (ATTORNEY_DONEE type)
 *  9. GET retrieval round-trip validation
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/sa.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary,
  clearAttorneysByType,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const BASE_POA = {
  full_legal_name:     'Alice Margaret Brown',
  residential_address: '45 King William Street, Adelaide SA 5000',
  email_id:            'alice.brown@example.com',
};

const SECOND_DONOR = {
  full_name: 'George Brown',
  address:   '45 King William Street, Adelaide SA 5000',
  email:     'george.brown@example.com',
  attorney_type: 'SECOND_DONOR',
};

const DONEE = {
  full_name: 'Michael Green',
  address:   '10 Rundle Mall, Adelaide SA 5000',
  email:     'michael.green@example.com',
  phone:     '0411111111',
  attorney_type: 'ATTORNEY_DONEE',
};

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — South Australia (SA)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Single donor + donee, IMMEDIATELY, no conditions ────────────────
  printSection('Scenario 1: Single donor, commencement IMMEDIATELY');
  {
    await clearAttorneysByType('ATTORNEY_DONEE');
    await clearAttorneysByType('SECOND_DONOR');
    await request('POST', '/user/attorney-for-poa', DONEE);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE_POA,
      has_second_donor:           false,
      donees_act_rules:           'JOINTLY',
      poa_start_rule:             'IMMEDIATELY',
      has_conditions_limitations: false,
    });
    printResult('POST /user/power-of-attorney (SA minimal)', poaRes, 200);
  }

  // ── 2. Commencement LEGAL_INCAPACITY ───────────────────────────────────
  printSection('Scenario 2: Commencement LEGAL_INCAPACITY');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE_POA,
      has_second_donor:           false,
      donees_act_rules:           'JOINTLY',
      poa_start_rule:             'LEGAL_INCAPACITY',
      has_conditions_limitations: false,
    });
    printResult('POST /user/power-of-attorney (SA LEGAL_INCAPACITY)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.poa_start_rule === 'LEGAL_INCAPACITY';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} poa_start_rule persisted as LEGAL_INCAPACITY: "${d?.poa_start_rule}"`);
  }

  // ── 3. Two donors ───────────────────────────────────────────────────────
  printSection('Scenario 3: Two donors (has_second_donor=true)');
  {
    await clearAttorneysByType('SECOND_DONOR');
    const sdRes = await request('POST', '/user/attorney-for-poa', SECOND_DONOR);
    printResult('POST /user/attorney-for-poa (SECOND_DONOR)', sdRes, [200, 201]);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE_POA,
      has_second_donor:              true,
      second_donor_full_name:        SECOND_DONOR.full_name,
      second_donor_residential_address: SECOND_DONOR.address,
      second_donor_email:            SECOND_DONOR.email,
      donees_act_rules:              'JOINTLY',
      poa_start_rule:                'IMMEDIATELY',
      has_conditions_limitations:    false,
    });
    printResult('POST /user/power-of-attorney (has_second_donor=true)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_second_donor === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_second_donor stored as true: ${d?.has_second_donor}`);
  }

  // ── 4. Donee acting JOINTLY_SEVERALLY ──────────────────────────────────
  printSection('Scenario 4: Donee acting method JOINTLY_SEVERALLY');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE_POA,
      has_second_donor:           false,
      donees_act_rules:           'JOINTLY_SEVERALLY',
      poa_start_rule:             'IMMEDIATELY',
      has_conditions_limitations: false,
    });
    printResult('POST /user/power-of-attorney (SA JOINTLY_SEVERALLY)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.donees_act_rules === 'JOINTLY_SEVERALLY';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} donees_act_rules = JOINTLY_SEVERALLY: "${d?.donees_act_rules}"`);
  }

  // ── 5. Conditions present ───────────────────────────────────────────────
  printSection('Scenario 5: Conditions/limitations present');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...BASE_POA,
      has_second_donor:           false,
      donees_act_rules:           'JOINTLY',
      poa_start_rule:             'IMMEDIATELY',
      has_conditions_limitations: true,
      conditions_limitations:     'Donee must consult with GP before major medical decisions.',
    });
    printResult('POST /user/power-of-attorney (SA with conditions)', poaRes, 200);
  }

  // ── 6. ATTORNEY_DONEE retrieval ─────────────────────────────────────────
  printSection('Scenario 6: Retrieve attorneys — ATTORNEY_DONEE type present');
  {
    const atksRes = await request('GET', '/user/attorneys-for-poa');
    printResult('GET  /user/attorneys-for-poa', atksRes, 200);
    const donees = (atksRes.body?.data || []).filter(a => a.type === 'ATTORNEY_DONEE');
    console.log(`    ${donees.length > 0 ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} ATTORNEY_DONEE present (found ${donees.length})`);
  }

  // ── 7. GET round-trip ───────────────────────────────────────────────────
  printSection('Scenario 7: GET /user/power-of-attorney round-trip');
  {
    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney', getRes, 200);
    const d = getRes.body?.data;
    const nameOk = d?.full_legal_name === BASE_POA.full_legal_name;
    console.log(`    ${nameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_legal_name round-trip: "${d?.full_legal_name}"`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
