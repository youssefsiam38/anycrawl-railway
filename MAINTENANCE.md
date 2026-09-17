# Maintenance

## Releasing a new version

1. **Bump the pins.** Get the new digests (see `UPSTREAM.md`) for `anycrawl-api`, `anycrawl-scrape-cheerio`,
   `anycrawl-scrape-playwright`, `postgres` and `redis`, and update `images/api/Dockerfile`, `compose.yaml`,
   `UPSTREAM.md` and `_audit/spec_anycrawl.py`.
2. **Re-check the seed path.** The wrapper copies `seed-railway-key.mjs` to
   `/usr/src/app/apps/api/dist/scripts/`; if upstream moves the compiled app, update the path. The seed imports
   `@anycrawl/db` (the same package the stock `generateApiKey.js` uses).
3. **Run the tests locally.**
   ```bash
   tests/static.sh
   tests/smoke.sh
   tests/persistence.sh
   ```
4. **Tag and push.** `git tag vX.Y.Z && git push --tags`. The `publish-image` workflow builds the api wrapper, runs
   the tests against the candidate, and pushes `:X.Y.Z`, `:X.Y` and `:latest` to GHCR.
5. **Update the template** if the pinned tags changed: set the service images to the new tags and re-run the
   clean-room deploy + `tests/railway-smoke.sh` (both engines) before publishing.

## Rebuilding the Railway template from scratch

The exact configuration (all five services) is in `RAILWAY_TEMPLATE.md`. The generator spec is
`_audit/spec_anycrawl.py`; the kit in `_audit/` (`tplkit.py`) builds a skeleton, patches the template, and runs a
clean-room deploy. Volumes, domains and health checks are only set by `skeleton()`, so a change to those requires
rebuilding from a skeleton; if `verify_template` reports an empty volume right after create, delete the template and
re-create it.

## Gotchas worth remembering

- **Queue-based, no shared FS.** The api and workers communicate via Redis (queue) + Postgres (results), so Railway
  needs no shared volume between services.
- **Redis must bind `::`.** Railway's private network is IPv6; `redis-server --bind :: --protected-mode no` makes
  Redis reachable at `redis.railway.internal:6379` (dual-stack on Linux).
- **`PORT` = 8080 = `ANYCRAWL_API_PORT`** = the domain target port; health check `/health`.
- **Only the api migrates** (`MIGRATE_DATABASE=true`); the workers set it to `false` to avoid racing on migrations.
- **Deterministic key.** The wrapper seeds `ANYCRAWL_API_KEY` so it is readable from the variables, not the logs.
  Any string works as the key (the API matches it against the DB, no prefix required).
- **The compose is lean** (no playwright) for fast CI; the template adds `scrape-playwright`. Test playwright on the
  live deploy (`tests/railway-smoke.sh`).
