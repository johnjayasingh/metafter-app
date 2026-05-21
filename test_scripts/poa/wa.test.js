/**
 * POA Integration Tests — Western Australia (WA)
 *
 * Scenarios:
 *  1. SOLE attorney, commencement IMMEDIATELY, no substitute, no conditions
 *  2. SOLE attorney, commencement SAT_DECLARATION
 *  3. JOINT attorneys (2), no substitute
 *  4. JOINT_AND_SEVERAL attorneys (2+)
 *  5. Has substitute attorney (SOLE substitute)
 *  6. Has substitute attorney (JOINT substitute)
 *  7. Substitute — acts_for specific named attorney
 *  8. Conditions/restrictions present
 *  9. No conditions (has_conditions_restrictions=false)
 * 10. GET round-trip validation for all fields
 *
 * Run:  BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=pw node poa/wa.test.js
 */

const {
  login, request,
  printResult, printSection, printSummary,
  clearAttorneysByType,
} = require('../utils/api');

// ── Fixtures ───────────────────────────────────────────────────────────────
const DOC = {
  enduring_poa_completion_date: '2026-03-26',
  full_legal_name:              'Christine Louise Hammond',
  residential_address:          '100 St Georges Terrace, Perth WA 6000',
  email_id:                     'christine.hammond@example.com',
};

const ATK_PRIMARY_1 = {
  full_name: 'Brian Wallace',
  address:   '50 Hay Street, Perth WA 6000',
  email:     'brian.wallace@example.com',
  phone:     '0893334444',
  attorney_type: 'PRIMARY',
};

const ATK_PRIMARY_2 = {
  full_name: 'Natalie Ford',
  address:   '80 William Street, Perth WA 6003',
  email:     'natalie.ford@example.com',
  phone:     '0892221111',
  attorney_type: 'PRIMARY',
};

const ATK_SUBSTITUTE_1 = {
  full_name: 'Liam Chen',
  address:   '22 Barrack Street, Perth WA 6000',
  email:     'liam.chen@example.com',
  phone:     '0412000000',
  attorney_type: 'SUBSTITUTE',
};

// ── Test runner ────────────────────────────────────────────────────────────
async function run() {
  console.log('\n\x1b[1m\x1b[35m═══════════════════════════════════════════════');
  console.log(' POA Tests — Western Australia (WA)');
  console.log('═══════════════════════════════════════════════\x1b[0m');

  await login();

  // ── 1. SOLE attorney, IMMEDIATELY, no substitute ───────────────────────
  printSection('Scenario 1: SOLE attorney, IMMEDIATELY, no substitute, no conditions');
  {
    await clearAttorneysByType('PRIMARY');
    await clearAttorneysByType('SUBSTITUTE');
    await request('POST', '/user/attorney-for-poa', ATK_PRIMARY_1);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DOC,
      attorney_appointment_type:     'SOLO',
      has_substitute_attorney:       false,
      has_conditions_restrictions:   false,
      epa_effect:                    'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (WA SOLE IMMEDIATELY)', poaRes, 200);
    const d = poaRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m attorney_appointment_type: "${d?.attorney_appointment_type}"`);
    console.log(`    \x1b[36m?\x1b[0m epa_effect: "${d?.epa_effect}"`);
  }

  // ── 2. SOLE attorney, SAT_DECLARATION ─────────────────────────────────
  printSection('Scenario 2: SOLE attorney, SAT_DECLARATION commencement');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DOC,
      attorney_appointment_type:   'SOLO',
      has_substitute_attorney:     false,
      has_conditions_restrictions: false,
      epa_effect:                  'DECLARATION_IN_FORCE',
    });
    printResult('POST /user/power-of-attorney (WA SOLO DECLARATION_IN_FORCE)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.epa_effect === 'DECLARATION_IN_FORCE';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} epa_effect = DECLARATION_IN_FORCE: "${d?.epa_effect}"`);
  }

  // ── 3. JOINT attorneys (2) ─────────────────────────────────────────────
  printSection('Scenario 3: JOINT attorneys (2)');
  {
    await clearAttorneysByType('PRIMARY');
    await request('POST', '/user/attorney-for-poa', ATK_PRIMARY_1);
    await request('POST', '/user/attorney-for-poa', ATK_PRIMARY_2);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DOC,
      attorney_appointment_type:   'JOINT',
      has_substitute_attorney:     false,
      has_conditions_restrictions: false,
      epa_effect:                  'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (WA JOINT)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.attorney_appointment_type === 'JOINT';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_appointment_type = JOINT: "${d?.attorney_appointment_type}"`);
  }

  // ── 4. JOINT_AND_SEVERAL attorneys ─────────────────────────────────────
  printSection('Scenario 4: JOINT_AND_SEVERAL attorneys');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DOC,
      attorney_appointment_type:   'JOINT_SEVERAL',
      has_substitute_attorney:     false,
      has_conditions_restrictions: false,
      epa_effect:                  'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (WA JOINT_SEVERAL)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.attorney_appointment_type === 'JOINT_SEVERAL';
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} attorney_appointment_type = JOINT_SEVERAL: "${d?.attorney_appointment_type}"`);
  }

  // ── 5. SOLE substitute attorney ────────────────────────────────────────
  printSection('Scenario 5: SOLE substitute attorney');
  {
    await clearAttorneysByType('SUBSTITUTE');
    const subRes = await request('POST', '/user/attorney-for-poa', ATK_SUBSTITUTE_1);
    printResult('POST /user/attorney-for-poa (SUBSTITUTE)', subRes, [200, 201]);

    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DOC,
      attorney_appointment_type:              'SOLO',
      has_substitute_attorney:               true,
      substitute_attorney_appointment_type:  'SOLO',
      substitute_act_activation:             'UNABLE_TO_ACT',
      has_conditions_restrictions:           false,
      epa_effect:                            'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (WA has substitute SOLE)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_substitute_attorney === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_substitute_attorney = true: ${d?.has_substitute_attorney}`);
  }

  // ── 6. JOINT substitute ────────────────────────────────────────────────
  printSection('Scenario 6: JOINT substitute + substitute acts for specific attorney');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DOC,
      attorney_appointment_type:              'JOINT',
      has_substitute_attorney:               true,
      substitute_attorney_appointment_type:  'JOINT',
      substitute_act_substitution:           'ATTORNEY_1',
      substitute_act_activation:             'UNABLE_TO_ACT',
      has_conditions_restrictions:           false,
      epa_effect:                            'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (WA JOINT substitute acts for specific)', poaRes, 200);
    const d = poaRes.body?.data;
    console.log(`    \x1b[36m?\x1b[0m substitute_act_substitution: "${d?.substitute_act_substitution}"`);
  }

  // ── 7. Conditions/restrictions present ────────────────────────────────
  printSection('Scenario 7: Conditions/restrictions present');
  {
    const poaRes = await request('POST', '/user/power-of-attorney', {
      ...DOC,
      attorney_appointment_type:   'SOLO',
      has_substitute_attorney:     false,
      has_conditions_restrictions: true,
      conditions_restrictions:     'Attorney must not sell the family home without written consent of all children.',
      epa_effect:                  'IMMEDIATELY',
    });
    printResult('POST /user/power-of-attorney (WA with conditions)', poaRes, 200);
    const d = poaRes.body?.data;
    const ok = d?.has_conditions_restrictions === true;
    console.log(`    ${ok ? '\x1b[32m✓\x1b[0m' : '\x1b[31m?\x1b[0m'} has_conditions_restrictions = true: ${d?.has_conditions_restrictions}`);
    console.log(`    \x1b[36m?\x1b[0m conditions text: "${d?.conditions_restrictions?.slice(0, 60)}..."`);
  }

  // ── 8. GET round-trip ──────────────────────────────────────────────────
  printSection('Scenario 8: GET round-trip validation');
  {
    const getRes = await request('GET', '/user/power-of-attorney');
    printResult('GET  /user/power-of-attorney', getRes, 200);
    const d = getRes.body?.data;
    const nameOk = d?.full_legal_name === DOC.full_legal_name;
    console.log(`    ${nameOk ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m'} full_legal_name round-trip: "${d?.full_legal_name}"`);
    console.log(`    \x1b[36m?\x1b[0m epa_effect: ${d?.epa_effect}`);
    console.log(`    \x1b[36m?\x1b[0m has_conditions_restrictions: ${d?.has_conditions_restrictions}`);
  }

  // ── 9. Attorneys retrieval ─────────────────────────────────────────────
  printSection('Scenario 9: Attorneys retrieval (PRIMARY + SUBSTITUTE)');
  {
    const atksRes = await request('GET', '/user/attorneys-for-poa');
    printResult('GET  /user/attorneys-for-poa', atksRes, 200);
    const attorneys = atksRes.body?.data || [];
    const primaryCount = attorneys.filter(a => a.attorney_type === 'PRIMARY').length;
    const substituteCount = attorneys.filter(a => a.attorney_type === 'SUBSTITUTE').length;
    console.log(`    \x1b[36m?\x1b[0m PRIMARY: ${primaryCount}, SUBSTITUTE: ${substituteCount}`);
  }

  return printSummary();
}

run().catch((err) => {
  console.error('\x1b[31mFatal error:\x1b[0m', err.message);
  process.exit(1);
}).then((ok) => process.exit(ok ? 0 : 1));
