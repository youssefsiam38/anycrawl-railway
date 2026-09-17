#!/usr/bin/env bash
# shellcheck disable=SC2015
# Persistence: the API key and job history live in PostgreSQL (the pg volume). Confirm the seeded key works, take
# the stack down keeping the volumes, bring it back, and confirm the same key still works and still scrapes
# (proving the DB — and the seeded key — survived). Standalone.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"
trap 'compose logs --no-color --tail 120 || true; compose down -v --remove-orphans >/dev/null 2>&1 || true; rm -rf "$TEST_TMP"' EXIT

section "bring the stack up"
compose up -d --build >/dev/null 2>&1 || die "compose up failed"
wait_for_code "$APP_URL/health" 200 180 || die "API never became healthy"
wait_key_ready 180 || die "the seeded key was never accepted"

section "before restart"
assert_contains "a scrape works before the restart" '"success":true' "$(scrape "https://example.com" cheerio)"

section "full restart (volumes preserved)"
compose down >/dev/null 2>&1
compose up -d >/dev/null 2>&1 || die "compose up failed"
wait_for_code "$APP_URL/health" 200 180 && pass "healthy again after restart" || die "not healthy after restart"

section "after restart"
# The key must already be valid from the persisted DB (not a fresh seed): a scrape must not be 401.
wait_key_ready 60 && pass "the same key still works (DB persisted)" || fail "the key was lost across the restart"
assert_contains "a scrape still works after the restart" '"success":true' "$(scrape "https://example.com" cheerio)"

summary
