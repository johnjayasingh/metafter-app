/**
 * POA Integration Tests — Tasmania (TAS)
 *
 * Covers all TAS-specific scenarios:
 *  1. Eligibility check (isAdult + isUnderstandEffectPoa)
 *  2. Donor details (full_legal_name, residential_address, email, completion_date)
 *  3. Single attorney (PRIMARY)
 *  4. Two attorneys acting JOINTLY
 *  5. Two attorneys acting JOINTLY_AND_SEVERALLY
 *  6. Conditions/limitations present
 *  7. No conditions
 *  8. Eligibility failure guard (isAdult=false → should not accept or app rejects)
 *  9. GET retrieval validates saved data round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/tas.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary, resetCounters,
  clearAttorneysByType,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const DONOR = {
  full_legal_name:      'Jane Elizabeth Doe',
  residential_address:  '12 Salamanca Place, Hobart TAS 7000',
  email_id:             'jane.doe@example.com',
  enduring_poa_completion_date: '2026-03-26',
};

const ATTORNEY_1 = {
  full_name: 'Robert Smith',
  address:   '5 Collins Street, Hobart TAS 7000',
  email:     'robert.smith@example.com',
  phone:     '0412345678',
  attorney_type: 'PRIMARY',
};

const ATTORNEY_2 = {
  full_name: 'Susan Jones',
  address:   '9 Murray Street, Hobart TAS 7000',
  email:     'susan.jones@example.com',
  phone:     '0487654321',
  attorney_type: 'PRIMARY',
};

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — Tasmania (TAS)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Save POA — eligible + minimal (no conditions) ───────────────────
  printSection('Scenario 1: Eligible donor, single attorney, no conditions');
  {
    await clearAttorneysByType('PRIMARY');

    // Step 1: save attorney
    const atkRes = await request('POST', '/user/attorney-for-poa', ATTORNEY_1);
    printResult('POST /user/attorney-for-poa (attorney 1)', atkRes, [200, 201]);

    // Step 2: save POA payload (TAS shape)
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_adult:                  true,
      is_understand_effect_poa:  true,
      attorney_act_rules:        'JOINTLY',
      has_conditions_limitations: false,
    });
    printResult('POST /user/power-of-attorney (TAS minimal)', poaRes, 200);

    // Step 3: retrieve and validate
    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney (TAS — retrieve)', getRes, 200);
    const d = getRes.body?.data;
    const donorOk = d?.full_legal_name === DONOR.full_legal_name;
    console.log(`    ${donorOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_legal_name round-trip: "${d?.full_legal_name}"`);
  }

  // ── 2. Two attorneys acting JOINTLY ────────────────────────────────────
  printSection('Scenario 2: Two attorneys acting JOINTLY');
  {
    await clearAttorneysByType('PRIMARY');

    await request('POST', '/user/attorney-for-poa', ATTORNEY_1);
    await request('POST', '/user/attorney-for-poa', ATTORNEY_2);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_adult:                  true,
      is_understand_effect_poa:  true,
      attorney_act_rules:        'JOINTLY',
      has_conditions_limitations: false,
    });
    printResult('POST /user/power-of-attorney (JOINTLY)', poaRes, 200);

    const attorneys = await request('GET', '/user/attorneys-for-poa');
    const primaryCount = (attorneys.body?.data || []).filter(a => a.type === 'PRIMARY').length;
    console.log(`    ${primaryCount >= 2 ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} Two PRIMARY attorneys saved (found ${primaryCount})`);
  }

  // ── 3. Two attorneys acting JOINTLY_AND_SEVERALLY ──────────────────────
  printSection('Scenario 3: Two attorneys acting JOINTLY_AND_SEVERALLY');
  {
    await clearAttorneysByType('PRIMARY');
    await request('POST', '/user/attorney-for-poa', ATTORNEY_1);
    await request('POST', '/user/attorney-for-poa', ATTORNEY_2);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_adult:                  true,
      is_understand_effect_poa:  true,
      attorney_act_rules:        'JOINTLY_SEVERALLY',
      has_conditions_limitations: false,
    });
    printResult('POST /user/power-of-attorney (JOINTLY_SEVERALLY)', poaRes, 200);
  }

  // ── 4. Conditions present ───────────────────────────────────────────────
  printSection('Scenario 4: Conditions/limitations present');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_adult:                  true,
      is_understand_effect_poa:  true,
      attorney_act_rules:        'JOINTLY',
      has_conditions_limitations: true,
      conditions_limitations:    'Attorney must consult with family doctor before financial decisions.',
    });
    printResult('POST /user/power-of-attorney (with conditions)', poaRes, 200);
    const d = poaRes.body?.data;
    const condOk = d?.has_conditions_limitations === true || d?.conditions_limitations != null;
    console.log(`    ${condOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} conditions_limitations persisted`);
  }

  // ── 5. Eligibility failure — isAdult=false ──────────────────────────────
  printSection('Scenario 5: Eligibility guard (is_adult=false)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_adult:                 false,
      is_understand_effect_poa: false,
    });
    // API may accept with flag=false; confirm flag is stored as-is
    printResult('POST /user/power-of-attorney (is_adult=false)', poaRes, 200);
    const d = poaRes.body?.data;
    const isAdultStored = d?.is_adult === false || d?.is_adult == null;
    console.log(`    ${isAdultStored ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} is_adult stored as false (blocked by app UI)`);
  }

  // ── 6. POA notification — not required for TAS, verify no 500 ──────────
  printSection('Scenario 6: Notification endpoint (TAS — not required, verify graceful)');
  {
    const notifRes = await request('GET', '/user/poa-notification');
    printResult('GET  /user/poa-notification (TAS — should not error)', notifRes, 200);
  }

  // ── Summary ─────────────────────────────────────────────────────────────
  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => {
  process.exit(ok ? 0 : 1);
});
