#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016
# Static validation: syntax, shellcheck, compose, image pins and security defaults. No Docker build.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
cd "$REPO_ROOT"
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"

section "syntax"
for f in images/api/entrypoint.sh tests/*.sh; do
  if bash -n "$f" 2>/dev/null; then pass "parses: $f"; else fail "syntax error: $f"; fi
done
sh -n images/api/entrypoint.sh && pass "entrypoint is POSIX sh" || fail "entrypoint not POSIX sh"
node --check images/api/seed-railway-key.mjs 2>/dev/null && pass "seed script parses" || echo "  SKIP  node not available to check seed script"

section "shellcheck"
if command -v shellcheck >/dev/null; then
  if shellcheck -s sh images/api/entrypoint.sh; then pass "shellcheck entrypoint"; else fail "shellcheck entrypoint"; fi
  if shellcheck -x -s bash tests/*.sh; then pass "shellcheck tests"; else fail "shellcheck tests"; fi
else
  echo "  SKIP  shellcheck not installed"
fi

section "compose"
if docker compose -f compose.yaml config -q; then pass "compose config"; else fail "compose config"; fi
cfg=$(docker compose -f compose.yaml config --format json)
assert_eq "four services (api, postgres, redis, scrape-cheerio)" "api postgres redis scrape-cheerio" \
  "$(jq -r '[.services | keys[]] | sort | join(" ")' <<<"$cfg")"
assert_eq "only the api publishes a port" "api" "$(jq -r '[.services | to_entries[] | select(.value.ports) | .key] | join(" ")' <<<"$cfg")"
assert_eq "the api port binds to loopback" "127.0.0.1" "$(jq -r '[.services.api.ports[]? | .host_ip] | join(" ")' <<<"$cfg")"
assert_eq "the database volume is mounted" "/var/lib/postgresql/data" "$(jq -r '[.services.postgres.volumes[]? | .target] | join(" ")' <<<"$cfg")"
assert_eq "auth is enabled" "true" "$(jq -r '.services.api.environment.ANYCRAWL_API_AUTH_ENABLED' <<<"$cfg")"
for img in postgres redis scrape-cheerio; do
  assert_contains "$img is pinned by digest" '@sha256:[0-9a-f]\{64\}$' "$(jq -r ".services.\"$img\".image" <<<"$cfg")"
done

section "image pins"
df=images/api/Dockerfile
assert_contains "api base pinned by digest" '^ARG ANYCRAWL_API_IMAGE=.*@sha256:[0-9a-f]\{64\}$' "$(grep '^ARG ANYCRAWL_API_IMAGE=' "$df")"

section "key seed security"
s=images/api/seed-railway-key.mjs
assert_contains "the key comes from the environment, not a hard-coded value" 'process.env.ANYCRAWL_API_KEY' "$(cat "$s")"
assert_contains "the seed is idempotent" 'already present' "$(cat "$s")"
e=images/api/entrypoint.sh
leaks=$(grep -nE 'log .*ANYCRAWL_API_KEY|echo .*ANYCRAWL_API_KEY' "$e" | grep -v 'not set' || true)
assert_eq "the entrypoint never prints the key" "" "$leaks"

section "secrets hygiene"
mapfile -t tracked < <(git ls-files 2>/dev/null | grep . || find . -type f -not -path './.git/*' -not -path './test-output/*')
if [ "${#tracked[@]}" -gt 0 ] && grep -lE '(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' "${tracked[@]}" 2>/dev/null; then
  fail "a credential-shaped string is in the repository"
else
  pass "no credential-shaped strings in ${#tracked[@]} files"
fi

summary
