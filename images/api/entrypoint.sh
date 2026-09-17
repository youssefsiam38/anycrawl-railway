#!/bin/sh
# AnyCrawl API for Railway: seed a working API key at start-up, then hand over to the stock API entrypoint.
#
# AnyCrawl requires API-key auth (ANYCRAWL_API_AUTH_ENABLED=true). Keys are rows in the database; upstream only
# ships a script that mints a RANDOM key printed to the log. Instead, this wrapper seeds the key value from the
# ANYCRAWL_API_KEY environment variable (a generated secret the operator can read from the service's variables),
# so nothing secret is written to the logs. The seed runs in the background and retries until the database schema
# exists (the stock entrypoint runs the migrations), then the API keeps running in the foreground.
set -eu

log() { printf '[anycrawl-railway] %s\n' "$*"; }

if [ -n "${ANYCRAWL_API_KEY:-}" ]; then
  (
    cd /usr/src/app/apps/api
    n=0
    until node dist/scripts/seed-railway-key.mjs; do
      n=$((n + 1))
      if [ "$n" -ge 60 ]; then log "API key seed: giving up after retries (schema never appeared)"; break; fi
      sleep 5
    done
  ) &
else
  log "ANYCRAWL_API_KEY is not set; no API key will be seeded and the API will reject all authenticated requests."
fi

# Stock API entrypoint: runs database migrations, then starts the server in the foreground.
exec /usr/src/app/start-api.sh
