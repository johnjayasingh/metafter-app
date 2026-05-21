/**
 * POA Integration Tests — Northern Territory (NT)
 *
 * Scenarios:
 *  1. Eligible (isDoingVoluntarily=true), 1 decision maker, JOINTLY, no land
 *  2. 1 DM with financial limits
 *  3. 2 DMs acting JOINTLY
 *  4. 2 DMs acting JOINTLY_AND_SEVERALLY
 *  5. 3 DMs
 *  6. 4 DMs (maximum)
 *  7. Owns land + DM can deal land
 *  8. Owns land + DM cannot deal land
 *  9. Notification — FINANCIAL type (NT always uses HEALTH per service)
 * 10. GET round-trip validation
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/nt.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary,
  clearAttorneysByType,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const DONOR = {
  full_legal_name:     'Thomas Arthur White',
  residential_address: '7 Smith Street, Darwin NT 0800',
  email_id:            'thomas.white@example.com',
};

function makeDm(n) {
  return {
    full_name: `Decision Maker ${n}`,
    address:   `${n * 10} Stuart Highway, Darwin NT 0800`,
    email:     `dm${n}@example.com`,
    phone:     `041000000${n}`,
    attorney_type: 'PRIMARY',
  };
}

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — Northern Territory (NT)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. Minimal — 1 DM, no land ─────────────────────────────────────────
  printSection('Scenario 1: 1 DM, JOINTLY, no land');
  {
    await clearAttorneysByType('PRIMARY');
    await request('POST', '/user/attorney-for-poa', makeDm(1));

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:           true,
      number_of_decision_makers:      1,
      instruction_decision_makers:    'JOINTLY',
      has_land_northern_territory:    false,
      need_financial_decision_for_land: false,
    });
    printResult('POST /user/power-of-attorney (NT 1 DM minimal)', poaRes, 200);
  }

  // ── 2. 1 DM with financial limits ──────────────────────────────────────
  printSection('Scenario 2: 1 DM with financial limits text');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:           true,
      number_of_decision_makers:      1,
      instruction_decision_makers:    'JOINTLY',
      financial_decision_for_attorney: 'No single transaction over $50,000 without prior approval.',
      has_land_northern_territory:    false,
    });
    printResult('POST /user/power-of-attorney (NT financial limits)', poaRes, 200);
  }

  // ── 3. 2 DMs — JOINTLY ─────────────────────────────────────────────────
  printSection('Scenario 3: 2 DMs acting JOINTLY');
  {
    await clearAttorneysByType('PRIMARY');
    await request('POST', '/user/attorney-for-poa', makeDm(1));
    await request('POST', '/user/attorney-for-poa', makeDm(2));

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:           true,
      number_of_decision_makers:      2,
      instruction_decision_makers:    'JOINTLY',
      has_land_northern_territory:    false,
    });
    printResult('POST /user/power-of-attorney (NT 2 DMs JOINTLY)', poaRes, 200);
  }

  // ── 4. 2 DMs — JOINTLY_AND_SEVERALLY ───────────────────────────────────
  printSection('Scenario 4: 2 DMs acting JOINTLY_AND_SEVERALLY');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:           true,
      number_of_decision_makers:      2,
      instruction_decision_makers:    'JOINTLY_SEVERALLY',
      has_land_northern_territory:    false,
    });
    printResult('POST /user/power-of-attorney (NT JOINTLY_SEVERALLY)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.instruction_decision_makers === 'JOINTLY_SEVERALLY';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} instruction_decision_makers: "${d?.instruction_decision_makers}"`);
  }

  // ── 5. 3 DMs ───────────────────────────────────────────────────────────
  printSection('Scenario 5: 3 DMs');
  {
    await clearAttorneysByType('PRIMARY');
    for (let i = 1; i <= 3; i++) await request('POST', '/user/attorney-for-poa', makeDm(i));

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:           true,
      number_of_decision_makers:      3,
      instruction_decision_makers:    'JOINTLY',
      has_land_northern_territory:    false,
    });
    printResult('POST /user/power-of-attorney (NT 3 DMs)', poaRes, 200);

    const atksRes = await request('GET', '/user/attorneys-for-poa');
    const primaryCount = (atksRes.body?.data || []).filter(a => a.attorney_type === 'PRIMARY').length;
    console.log(`    ${primaryCount >= 3 ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} 3 PRIMARY attorneys saved (found ${primaryCount})`);
  }

  // ── 6. 4 DMs (maximum) ─────────────────────────────────────────────────
  printSection('Scenario 6: 4 DMs (maximum allowed)');
  {
    await clearAttorneysByType('PRIMARY');
    for (let i = 1; i <= 4; i++) await request('POST', '/user/attorney-for-poa', makeDm(i));

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:           true,
      number_of_decision_makers:      4,
      instruction_decision_makers:    'JOINTLY',
      has_land_northern_territory:    false,
    });
    printResult('POST /user/power-of-attorney (NT 4 DMs)', poaRes, 200);
  }

  // ── 7. Owns land — DM CAN deal land ────────────────────────────────────
  printSection('Scenario 7: Owns land, DM CAN deal land');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:             true,
      number_of_decision_makers:        1,
      instruction_decision_makers:      'JOINTLY',
      has_land_northern_territory:      true,
      need_financial_decision_for_land: true,
    });
    printResult('POST /user/power-of-attorney (NT owns land, can deal)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_land_northern_territory === true && d?.need_financial_decision_for_land === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} land flags: has_land=${d?.has_land_northern_territory}, can_deal=${d?.need_financial_decision_for_land}`);
  }

  // ── 8. Owns land — DM CANNOT deal land ─────────────────────────────────
  printSection('Scenario 8: Owns land, DM CANNOT deal land');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DONOR,
      is_doing_voluntarily:             true,
      number_of_decision_makers:        1,
      instruction_decision_makers:      'JOINTLY',
      has_land_northern_territory:      true,
      need_financial_decision_for_land: false,
    });
    printResult('POST /user/power-of-attorney (NT owns land, cannot deal)', poaRes, 200);
  }

  // ── 9. POA notification (NT always sends HEALTH notification) ──────────
  printSection('Scenario 9: NT notification (HEALTH)');
  {
    const notifRes = await request('POST', '/user/poa-notification', {
      notification_type: 'HEALTH',
      notify_for:        ['ME'],
      notify_of:         'WRITTEN_INTENTION_NOTICE',
      notify_of_detail:  'Notify family doctor in writing within 7 days.',
      attorneys: [{
        full_name: 'Dr Helen Cook',
        email:     'helen.cook@hospital.com',
        phone:     '0899999999',
        address:   '1 Hospital Road, Darwin NT 0800',
      }],
    });
    printResult('POST /user/poa-notification (NT HEALTH)', notifRes, [200, 201]);

    const getNotifRes = await request('GET', '/user/poa-notification');
    printResult('GET  /user/poa-notification (NT)', getNotifRes, 200);
  }

  // ── 10. GET round-trip ──────────────────────────────────────────────────
  printSection('Scenario 10: GET round-trip validation');
  {
    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney', getRes, 200);
    const d = getRes.body?.data;
    const nameOk = d?.full_legal_name === DONOR.full_legal_name;
    console.log(`    ${nameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_legal_name round-trip: "${d?.full_legal_name}"`);
    console.log(`    \x1b[36m?\x1b[0m is_doing_voluntarily: ${d?.is_doing_voluntarily}`);
    console.log(`    \x1b[36m?\x1b[0m number_of_decision_makers: ${d?.number_of_decision_makers}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
