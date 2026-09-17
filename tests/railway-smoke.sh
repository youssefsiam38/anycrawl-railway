#!/usr/bin/env bash
# shellcheck disable=SC2015
# Live test of a deployed template: the scrape flows over HTTPS, both the cheerio (static) and playwright
# (JavaScript-rendered) engines.
#
#   ANYCRAWL_API_KEY_FILE=./api-key tests/railway-smoke.sh https://<app-domain>
#
# The API key is read from a file (never an argument, never printed).
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
[ $# -ge 1 ] || { sed -n '3,7p' "$0"; exit 2; }
APP_URL=${1%/}; export APP_URL
: "${ANYCRAWL_API_KEY_FILE:?set ANYCRAWL_API_KEY_FILE}"
ANYCRAWL_KEY=$(tr -d '\n' < "$ANYCRAWL_API_KEY_FILE"); export ANYCRAWL_KEY
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"
trap 'rm -rf "$TEST_TMP"' EXIT

section "availability over HTTPS"
wait_for_code "$APP_URL/health" 200 300 && pass "/health returns 200 over HTTPS" || die "not healthy"

section "auth is enforced over HTTPS"
assert_eq "a scrape without a key is rejected" "401" \
  "$(http_code -X POST "$APP_URL/v1/scrape" -H 'Content-Type: application/json' --data '{"url":"https://example.com","engine":"cheerio"}')"

section "cheerio scrape (static HTML) over HTTPS"
out=$(scrape "https://example.com" cheerio)
assert_contains "the cheerio scrape succeeds" '"success":true' "$out"
assert_contains "the page content is extracted" "Example Domain" "$out"

section "playwright scrape (JavaScript-rendered) over HTTPS"
out=$(scrape "https://example.com" playwright)
assert_contains "the playwright scrape succeeds" '"success":true' "$out"
assert_contains "the page content is extracted" "Example Domain" "$out"

summary
