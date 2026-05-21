/**
 * POA Integration Tests — Queensland (QLD)
 *
 * Scenarios:
 *  1. Financial matters only, single attorney, commencement IMMEDIATELY
 *  2. Financial matters, commencement when LEGALLY_INCAPACITATED
 *  3. Personal/health matters only
 *  4. Both financial + personal/health
 *  5. Has preference (preferences text)
 *  6. Successive attorneys
 *  7. Enduring guardian (QLD eg_* fields)
 *  8. FINANCIAL notification
 *  9. GET round-trip
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/qld.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary,
  clearAttorneysByType,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const ATK_PRIMARY = {
  full_name:     'Nathan Cooper',
  address:       '100 Queen Street, Brisbane QLD 4000',
  email:         'nathan.cooper@example.com',
  phone:         '0712341234',
  attorney_type: 'PRIMARY',
};

const ATK_GUARDIAN = {
  full_name:     'Amanda Scott',
  address:       '50 Adelaide Street, Brisbane QLD 4000',
  email:         'amanda.scott@example.com',
  phone:         '0722223333',
  attorney_type: 'ENDURING_GUARDIAN',
};

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — Queensland (QLD)');
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
    });
    printResult('POST /user/power-of-attorney (QLD financial IMMEDIATELY)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.matters?.includes('FINANCE');
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} matters: ${JSON.stringify(d?.matters)}`);
    console.log(`    \x1b[36m?\x1b[0m financial_commencement: ${d?.financial_commencement}`);
  }

  // ── 2. Financial only, LEGALLY_INCAPACITATED ──────────────────────────
  printSection('Scenario 2: Financial matters, LEGALLY_INCAPACITATED');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE'],
      financial_commencement: 'DONT_HAVE_CAPACITY',
      has_preference:        false,
    });
    printResult('POST /user/power-of-attorney (QLD financial DONT_HAVE_CAPACITY)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.financial_commencement === 'DONT_HAVE_CAPACITY';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} financial_commencement: ${d?.financial_commencement}`);
  }

  // ── 3. Personal/health matters only ───────────────────────────────────
  printSection('Scenario 3: Personal/health matters (PERSONAL_HEALTH) only');
  {
    await clearAttorneysByType('ENDURING_GUARDIAN');
    await request('POST', '/user/attorney-for-poa', ATK_GUARDIAN);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:        ['PERSONAL', 'HEALTH'],
      has_preference: false,
    });
    printResult('POST /user/power-of-attorney (QLD personal/health)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.matters?.includes('PERSONAL') || d?.matters?.includes('HEALTH');
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} matters: ${JSON.stringify(d?.matters)}`);
  }

  // ── 4. Both matters ────────────────────────────────────────────────────
  printSection('Scenario 4: Both FINANCIAL + PERSONAL_HEALTH');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE', 'PERSONAL', 'HEALTH'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      has_preference:        false,
    });
    printResult('POST /user/power-of-attorney (QLD both matters)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.matters?.length >= 2;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} Both matters stored: ${JSON.stringify(d?.matters)}`);
  }

  // ── 5. With preference ────────────────────────────────────────────────
  printSection('Scenario 5: Has preference (preferences text)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:               ['FINANCE'],
      financial_commencement: 'IMMEDIATELY_OTHERS',
      has_preference:        true,
      preferences:           'Retain the family property at all costs.',
    });
    printResult('POST /user/power-of-attorney (QLD with preferences)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_preference === true && d?.preferences;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} preferences: "${d?.preferences?.slice(0, 50)}"`);
  }

  // ── 6. Successive attorneys ────────────────────────────────────────────
  printSection('Scenario 6: Successive attorneys');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                     ['FINANCE'],
      financial_commencement:      'IMMEDIATELY_OTHERS',
      appoint_successive_attorneys: true,
    });
    printResult('POST /user/power-of-attorney (QLD successive)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.appoint_successive_attorneys === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} appoint_successive_attorneys = true: ${d?.appoint_successive_attorneys}`);
  }

  // ── 7. Enduring guardian fields ────────────────────────────────────────
  printSection('Scenario 7: Enduring guardian (QLD eg_* fields)');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      matters:                     ['PERSONAL', 'HEALTH'],
      eg_can_decide_living_place:  true,
      eg_living_place_detail:      'Stay home for as long as practicable.',
      eg_can_decide_services:      true,
      eg_can_decide_healthcare:    true,
      eg_healthcare_detail:        'No chemotherapy if terminal prognosis.',
      eg_can_consent_medical_and_dental: true,
      eg_has_directions:           true,
      eg_directions_detail:        'Guardian must consult my GP before any major decision.',
    });
    printResult('POST /user/power-of-attorney (QLD enduring guardian)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.eg_can_decide_living_place === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} eg_can_decide_living_place = true: ${d?.eg_can_decide_living_place}`);
  }

  // ── 8. FINANCIAL notification ─────────────────────────────────────────
  printSection('Scenario 8: FINANCIAL type notification (QLD)');
  {
    const notifRes = await request('POST', '/user/poa-notification', {
      notification_type: 'FINANCIAL',
      notify_for:        ['ME'],
      notify_of:         'WRITTEN_INTENTION_NOTICE',
    });
    printResult(
      'POST /user/poa-notification (QLD FINANCIAL)',
      notifRes,
      [200, 201],
    );
    const notifGetRes = await request('GET', '/user/poa-notification');
    printResult('GET  /user/poa-notification', notifGetRes, 200);
    const notifs = notifGetRes.body?.data;
    const hasFinancial = Array.isArray(notifs)
      ? notifs.some((n) => n.notification_type === 'FINANCIAL')
      : notifs?.notification_type === 'FINANCIAL';
    console.log(`    ${hasFinancial ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} FINANCIAL notification present`);
  }

  // ── 9. GET round-trip ─────────────────────────────────────────────────
  printSection('Scenario 9: GET round-trip');
  {
    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney', getRes, 200);
    const d = getRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m matters: ${JSON.stringify(d?.matters)}`);
    console.log(`    \x1b[36m?\x1b[0m has_preference: ${d?.has_preference}`);
    console.log(`    \x1b[36m?\x1b[0m financial_commencement: ${d?.financial_commencement}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
