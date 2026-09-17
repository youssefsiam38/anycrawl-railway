#!/usr/bin/env bash
# shellcheck disable=SC2015
# Shared helpers for anycrawl-railway tests. Source this file; do not execute it.
# The API key is never echoed. Auth is a Bearer token; the API returns JSON {success:...}.

: "${APP_URL:=http://localhost:${ANYCRAWL_TEST_PORT:-18080}}"
: "${TEST_TIMEOUT:=300}"
: "${ANYCRAWL_KEY:=${ANYCRAWL_TEST_API_KEY:-local-test-only-anycrawl-api-key-000000000000}}"

TEST_TMP="${TEST_TMP:-$(mktemp -d)}"
export TEST_TMP
_PASS=0; _FAIL=0

pass() { _PASS=$((_PASS+1)); printf '  PASS  %s\n' "$*"; }
fail() { _FAIL=$((_FAIL+1)); printf '  FAIL  %s\n' "$*" >&2; }
die()  { printf 'FATAL: %s\n' "$*" >&2; exit 1; }
section() { printf '\n== %s ==\n' "$*"; }
summary() { printf '\n%d passed, %d failed\n' "$_PASS" "$_FAIL"; [ "$_FAIL" -eq 0 ]; }

assert_eq() { if [ "$2" = "$3" ]; then pass "$1 ($3)"; else fail "$1: expected [$2] got [$3]"; fi; }
assert_contains() { if grep -q -- "$2" <<<"$3"; then pass "$1"; else fail "$1: missing [$2]"; fi; }

http_code() { curl -s -o /dev/null -w '%{http_code}' --max-time 30 "$@" || true; }

wait_for_code() {
  local url=$1 want=$2 timeout=${3:-$TEST_TIMEOUT} start code
  start=$(date +%s)
  while :; do
    code=$(http_code "$url")
    [ "$code" = "$want" ] && return 0
    if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then printf 'timed out waiting for %s -> %s (last %s)\n' "$url" "$want" "$code" >&2; return 1; fi
    sleep 3
  done
}

compose() { docker compose -f "$REPO_ROOT/compose.yaml" "$@"; }

# scrape URL ENGINE -> prints the raw JSON response of POST /v1/scrape with the API key.
scrape() {
  local url=$1 engine=${2:-cheerio}
  curl -s --max-time 120 -X POST "$APP_URL/v1/scrape" \
    -H "Authorization: Bearer $ANYCRAWL_KEY" -H 'Content-Type: application/json' \
    --data "$(jq -nc --arg u "$url" --arg e "$engine" '{url:$u, engine:$e}')"
}

# wait until the seeded key is accepted (the async seed has run): a scrape must stop returning 401.
wait_key_ready() {
  local timeout=${1:-180} start code
  start=$(date +%s)
  while :; do
    code=$(http_code -X POST "$APP_URL/v1/scrape" -H "Authorization: Bearer $ANYCRAWL_KEY" \
      -H 'Content-Type: application/json' --data '{"url":"https://example.com","engine":"cheerio"}')
    [ "$code" != "401" ] && [ "$code" != "000" ] && return 0
    if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then return 1; fi
    sleep 3
  done
}
