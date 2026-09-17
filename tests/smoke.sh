#!/usr/bin/env bash
# shellcheck disable=SC2015
# Smoke test: build+run the stack, then verify liveness, that auth is enforced, that the seeded API key works, and
# that a scrape returns LLM-ready markdown (the API -> Redis queue -> cheerio worker -> result loop).
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"

STARTED=0
if [ "${ANYCRAWL_REUSE_STACK:-0}" != "1" ]; then
  section "bring the stack up"
  compose up -d --build >/dev/null 2>&1 || die "compose up failed"
  STARTED=1
  trap 'compose logs --no-color --tail 120 || true; [ "$STARTED" = 1 ] && compose down -v --remove-orphans >/dev/null 2>&1 || true; rm -rf "$TEST_TMP"' EXIT
else
  trap 'rm -rf "$TEST_TMP"' EXIT
fi

section "liveness"
wait_for_code "$APP_URL/health" 200 180 && pass "/health returns 200" || die "API never became healthy"

section "auth is enforced"
assert_eq "a scrape without a key is rejected" "401" \
  "$(http_code -X POST "$APP_URL/v1/scrape" -H 'Content-Type: application/json' --data '{"url":"https://example.com","engine":"cheerio"}')"

section "the seeded API key works"
wait_key_ready 180 && pass "the seeded key is accepted (async seed completed)" || die "the seeded key was never accepted"
assert_eq "a scrape with a wrong key is rejected" "401" \
  "$(http_code -X POST "$APP_URL/v1/scrape" -H 'Authorization: Bearer definitely-not-the-key' -H 'Content-Type: application/json' --data '{"url":"https://example.com","engine":"cheerio"}')"

section "the scrape loop returns LLM-ready markdown"
out=$(scrape "https://example.com" cheerio)
assert_contains "the scrape succeeds" '"success":true' "$out"
assert_contains "the result carries markdown" '"markdown"' "$out"
assert_contains "the page content is extracted" "Example Domain" "$out"

summary
