/**
 * Shared API helpers for all POA/AHD integration tests.
 *
 * Usage:
 *   const { login, request, printResult, ENV } = require('../utils/api');
 *
 * Config via environment variables (or edit defaults below):
 *   BASE_URL  — API base URL          (default: http://13.54.59.56:8000)
 *   TEST_EMAIL — test account email   (default: testuser@example.com)
 *   TEST_PASS  — test account password
 */

const https = require('https');
const http  = require('http');
const url   = require('url');

// ── Config ─────────────────────────────────────────────────────────────────
const ENV = {
  BASE_URL:   process.env.BASE_URL   || 'http://13.54.59.56:8000',
  TEST_EMAIL: process.env.TEST_EMAIL || 'johnjayasingh.s@gmail.com',
  TEST_PASS:  process.env.TEST_PASS  || 'Admin@100',
};

let _token = null;

// ── Low-level HTTP ─────────────────────────────────────────────────────────
function rawRequest(method, path, body, headers) {
  return new Promise((resolve, reject) => {
    const parsed  = url.parse(ENV.BASE_URL + path);
    const payload = body ? JSON.stringify(body) : null;

    const options = {
      hostname: parsed.hostname,
      port:     parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
      path:     parsed.path,
      method,
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
        ...headers,
      },
    };

    const lib = parsed.protocol === 'https:' ? https : http;
    const req = lib.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        let json;
        try { json = JSON.parse(data); } catch { json = data; }
        resolve({ status: res.statusCode, body: json });
      });
    });

    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

// ── Auth ───────────────────────────────────────────────────────────────────
async function login(email, password) {
  const e = email    || ENV.TEST_EMAIL;
  const p = password || ENV.TEST_PASS;

  const loginRes = await rawRequest('POST', '/user/login/basic', {
    email: e, password: p,
  });

  if (loginRes.status !== 200) {
    throw new Error(`Login failed (${loginRes.status}): ${JSON.stringify(loginRes.body)}`);
  }

  const data = loginRes.body?.data;

  // Handle MFA challenge or direct token
  if (data?.login_step === 'COMPLETED' || data?.login_step === 'MFA_CHALLENGE') {
    // If MFA_CHALLENGE we can't auto-complete here — warn and continue with
    // whatever token is returned, or throw for manual resolution.
    if (data.login_step === 'MFA_CHALLENGE') {
      console.warn(
        '[AUTH] MFA_CHALLENGE required. Set token manually via setToken() or ' +
        'configure a test account with MFA disabled.'
      );
    }
  }

  const token = data?.access_token || data?.token;
  if (!token) {
    throw new Error(`No access token in login response: ${JSON.stringify(loginRes.body)}`);
  }

  _token = token;
  return token;
}

/** Override token (useful when logged in externally). */
function setToken(token) { _token = token; }
function getToken()       { return _token; }

// ── Authenticated request ──────────────────────────────────────────────────
async function request(method, path, body) {
  if (!_token) throw new Error('Not authenticated — call login() first');
  return rawRequest(method, path, body, { Authorization: `Bearer ${_token}` });
}

// ── Result helpers ─────────────────────────────────────────────────────────
const GREEN  = '\x1b[32m';
const RED    = '\x1b[31m';
const YELLOW = '\x1b[33m';
const CYAN   = '\x1b[36m';
const RESET  = '\x1b[0m';
const BOLD   = '\x1b[1m';

let _passed = 0;
let _failed = 0;

function printResult(label, res, expectStatus = 200) {
  const expected = Array.isArray(expectStatus) ? expectStatus : [expectStatus];
  const ok     = expected.includes(res.status);
  const icon   = ok ? `${GREEN}✓${RESET}` : `${RED}✗${RESET}`;
  const status = ok ? `${GREEN}${res.status}${RESET}` : `${RED}${res.status}${RESET}`;

  console.log(`  ${icon} [${status}] ${label}`);

  if (!ok) {
    console.log(`       ${YELLOW}Expected: ${expected.join(',')}${RESET}`);
    console.log(`       ${YELLOW}Body: ${JSON.stringify(res.body).slice(0, 300)}${RESET}`);
    _failed++;
  } else {
    _passed++;
  }

  return ok;
}

function printSection(title) {
  console.log(`\n${BOLD}${CYAN}── ${title} ──────────────────────────────────${RESET}`);
}

function printSummary() {
  const total = _passed + _failed;
  console.log(`\n${BOLD}Results: ${GREEN}${_passed} passed${RESET}, ${_failed > 0 ? RED : ''}${_failed} failed${RESET} / ${total} total${RESET}`);
  return _failed === 0;
}

function resetCounters() { _passed = 0; _failed = 0; }

// ── Retry/cleanup helpers ──────────────────────────────────────────────────
/** Fetch current POA and return its id (or null). */
async function getPoaId() {
  const res = await request('GET', '/user/power-of-attorney');
  return res.body?.data?.id || null;
}

/** Fetch current AHD and return its id (or null). */
async function getAhdId() {
  const res = await request('GET', '/user/ahd');
  return res.body?.data?.id || null;
}

/** Fetch all attorneys-for-poa and return list. */
async function getAttorneys() {
  const res = await request('GET', '/user/attorneys-for-poa');
  return res.body?.data || [];
}

/** Delete all existing attorneys of a given type. */
async function clearAttorneysByType(type) {
  const attorneys = await getAttorneys();
  const matching  = attorneys.filter(a => a.attorney_type === type);
  for (const a of matching) {
    if (a.attorney_poa_id) {
      await request('DELETE', `/user/attorney-for-poa/${a.attorney_poa_id}`);
    }
  }
}

module.exports = {
  ENV,
  login, setToken, getToken,
  request, rawRequest,
  printResult, printSection, printSummary, resetCounters,
  getPoaId, getAhdId, getAttorneys, clearAttorneysByType,
};
