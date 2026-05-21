#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run-all.sh — Master test runner for all POA + AHD integration tests
#
# Usage:
#   BASE_URL=http://13.54.59.56:8000 TEST_EMAIL=you@test.com TEST_PASS=secret ./test_scripts/run-all.sh
#   TEST_SUITE=poa ./test_scripts/run-all.sh          # POA only
#   TEST_SUITE=ahd ./test_scripts/run-all.sh          # AHD only
#   TEST_FILE=poa/vic ./test_scripts/run-all.sh       # Single file
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Resolve script directory ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Guard: node must be available ────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "❌  node is not installed. Please install Node.js (v16+)."
  exit 1
fi

# ── Colour helpers ────────────────────────────────────────────────────────────
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# ── Config ────────────────────────────────────────────────────────────────────
export BASE_URL="${BASE_URL:-http://13.54.59.56:8000}"
export TEST_EMAIL="${TEST_EMAIL:-}"
export TEST_PASS="${TEST_PASS:-}"

if [[ -z "$TEST_EMAIL" || -z "$TEST_PASS" ]]; then
  echo "${RED}ERROR:${RESET} TEST_EMAIL and TEST_PASS must be set."
  echo "  Example: TEST_EMAIL=user@test.com TEST_PASS=secret $0"
  exit 1
fi

# ── Test file lists ───────────────────────────────────────────────────────────
POA_FILES=(
  "$SCRIPT_DIR/poa/vic.test.js"
  "$SCRIPT_DIR/poa/qld.test.js"
  "$SCRIPT_DIR/poa/nsw.test.js"
  "$SCRIPT_DIR/poa/act.test.js"
  "$SCRIPT_DIR/poa/wa.test.js"
  "$SCRIPT_DIR/poa/tas.test.js"
  "$SCRIPT_DIR/poa/sa.test.js"
  "$SCRIPT_DIR/poa/nt.test.js"
)

AHD_FILES=(
  "$SCRIPT_DIR/ahd/vic.test.js"
  "$SCRIPT_DIR/ahd/qld.test.js"
  "$SCRIPT_DIR/ahd/nsw.test.js"
  "$SCRIPT_DIR/ahd/act.test.js"
  "$SCRIPT_DIR/ahd/wa.test.js"
  "$SCRIPT_DIR/ahd/tas.test.js"
  "$SCRIPT_DIR/ahd/sa.test.js"
  "$SCRIPT_DIR/ahd/nt.test.js"
)

# ── Determine what to run ─────────────────────────────────────────────────────
TEST_SUITE="${TEST_SUITE:-all}"
TEST_FILE="${TEST_FILE:-}"

if [[ -n "$TEST_FILE" ]]; then
  # Single-file mode: TEST_FILE=poa/vic or poa/vic.test.js
  SINGLE="${TEST_FILE%.test.js}.test.js"
  if [[ "$SINGLE" != /* ]]; then
    SINGLE="$SCRIPT_DIR/$SINGLE"
  fi
  FILES_TO_RUN=("$SINGLE")
elif [[ "$TEST_SUITE" == "poa" ]]; then
  FILES_TO_RUN=("${POA_FILES[@]}")
elif [[ "$TEST_SUITE" == "ahd" ]]; then
  FILES_TO_RUN=("${AHD_FILES[@]}")
else
  FILES_TO_RUN=("${POA_FILES[@]}" "${AHD_FILES[@]}")
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${CYAN}║   Digital Will — Integration Test Suite          ║${RESET}"
echo "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${RESET}"
echo "  Base URL  : ${BASE_URL}"
echo "  Test email : ${TEST_EMAIL}"
echo "  Suite      : ${TEST_SUITE}"
echo "  Files      : ${#FILES_TO_RUN[@]}"
echo ""

# ── Log file ─────────────────────────────────────────────────────────────────
LOG_DIR="$SCRIPT_DIR/../build/reports"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test-run-$(date +%Y%m%d-%H%M%S).log"
echo "  Log        : $LOG_FILE"
echo ""

# ── Run ───────────────────────────────────────────────────────────────────────
PASS=0
FAIL=0
FAILED_FILES=()
START_TIME=$SECONDS

for FILE in "${FILES_TO_RUN[@]}"; do
  if [[ ! -f "$FILE" ]]; then
    echo "${YELLOW}SKIP${RESET}  $FILE  (not found)"
    continue
  fi

  LABEL="${FILE#"$SCRIPT_DIR/"}"
  printf "%-50s" "  Running ${BOLD}$LABEL${RESET} ... "
  {
    echo "════════════════════════════════════════════"
    echo " $LABEL"
    echo "════════════════════════════════════════════"
    node "$FILE"
    echo ""
  } >> "$LOG_FILE" 2>&1

  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "${GREEN}PASS${RESET}"
    ((PASS++)) || true
  else
    echo "${RED}FAIL${RESET}  (exit $EXIT_CODE)"
    ((FAIL++)) || true
    FAILED_FILES+=("$LABEL")
  fi
done

ELAPSED=$(( SECONDS - START_TIME ))

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "${BOLD}─────────────────────────────────────────────────${RESET}"
echo "  Total: $((PASS + FAIL))  ${GREEN}Passed: $PASS${RESET}  ${RED}Failed: $FAIL${RESET}  Time: ${ELAPSED}s"
echo "  Full log: $LOG_FILE"

if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
  echo ""
  echo "${RED}Failed suites:${RESET}"
  for F in "${FAILED_FILES[@]}"; do
    echo "    ✗ $F"
  done
  echo ""
  exit 1
fi

echo ""
echo "${GREEN}${BOLD}All tests passed.${RESET}"
exit 0
