# Marketplace audit

A record of the diligence behind publishing this template.

## Identity

- Template: **AnyCrawl** — a self-hosted scrape/crawl/SERP API for LLMs.
- Upstream: [any4ai/AnyCrawl](https://github.com/any4ai/AnyCrawl), MIT, active (~3.5k stars).

## Licence

- AnyCrawl is MIT (`licenses/ANYCRAWL-LICENSE`); redistribution as a template is permitted. The api, cheerio and
  playwright images are used unmodified; the api wrapper only adds an API-key seed. See `THIRD_PARTY_NOTICES.md`.

## Security review

- **Auth on, key seeded.** `ANYCRAWL_API_AUTH_ENABLED=true`; the template generates `ANYCRAWL_API_KEY` and seeds
  that exact value so the operator never reads it from the logs. A request with no/wrong key is rejected (401);
  verified live.
- **Secret hygiene.** The seed reads the key only from the environment, uses the app's DB layer (no secret on a
  command line), is idempotent, and never logs the key. The static test greps the tree for credential shapes.
- **Private data plane.** Postgres, Redis and both workers have no public domain.
- **Reproducible.** Every image pinned by digest.

## Architecture note

The queue expected an "all-in-one image + Redis + Postgres". AnyCrawl is actually a small microservice set: an api
plus per-engine scrape workers that communicate through Redis (queue) and Postgres (results). The template runs the
api, a cheerio worker (static HTML), a playwright worker (JavaScript pages), Postgres and Redis — five services,
no shared filesystem, which fits Railway's per-service volumes.

## Reproducibility & tests

- `tests/static.sh` (24 checks): syntax, shellcheck, compose shape, digest pins, auth on, key-seed security,
  secret scan.
- `tests/smoke.sh` (7 checks): health, auth enforced, the seeded key works (and a wrong key is rejected), and the
  scrape loop returns LLM-ready markdown.
- `tests/persistence.sh` (4 checks): the seeded key and data survive a restart with volumes kept.
- `tests/railway-smoke.sh`: the same flows over HTTPS, exercising both the cheerio and playwright engines.
- CI runs static + build + smoke + persistence on every push; the publish workflow re-tests the candidate image.

## Deploy-time inputs

- `ANYCRAWL_API_KEY` — generated (the Bearer token; copy it to call the API).
- Everything else is fixed by the template (DB, Redis, ports, health check, volumes). No required human input
  beyond clicking deploy.

## Verdict

Shippable. A self-contained, reproducible, key-authenticated AnyCrawl deployment whose scrape loop is verified on a
live Railway deployment for both engines.
