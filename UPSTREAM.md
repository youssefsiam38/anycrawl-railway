# Upstream and pinned versions

This template runs **AnyCrawl** (a scrape/crawl/SERP API) with a bundled **PostgreSQL** and **Redis**. All images
are official and pinned by digest.

## AnyCrawl

- Project: https://github.com/any4ai/AnyCrawl
- Licence: MIT (`licenses/ANYCRAWL-LICENSE`)
- Official images (pinned to `v1.0.0`):
  - api: `ghcr.io/any4ai/anycrawl-api:v1.0.0` — digest `sha256:c279e18d0bf31cd6154050f8f1bd40557032d1b0a17ed8975f2260f7fde2e710`
  - scrape-cheerio: `ghcr.io/any4ai/anycrawl-scrape-cheerio:v1.0.0` — digest `sha256:a56bc477e24d0d3d7254e7f75cacc86f2d4f354e8cd1f25a6906b1dd9f4ea1fa`
  - scrape-playwright: `ghcr.io/any4ai/anycrawl-scrape-playwright:v1.0.0` — digest `sha256:abc6a14d60d8248a41573fd3def3c5fbf63fa74ad07567128156053f30217b53`
- The wrapper image (`images/api/Dockerfile`) is `FROM` the api digest and only adds an API-key seed script and a
  start-up wrapper. The api application and the two worker images are unmodified.

## Bundled infrastructure

- PostgreSQL: `postgres:16-alpine` — digest `sha256:cf78e76683b9ca8c5733cbbdce6c9262b45b6767934dd0a95e671f9a0fc20685`
- Redis: `redis:7-alpine` — digest `sha256:ff02b58f971e7d7d156a1267e283fcbbeee91773b6aa36c49dac28ecfe28eadf`
  (run with `--protected-mode no`; the ioredis client uses `?family=0` to reach it over Railway's IPv6 private network)

## Refreshing a digest

```bash
docker buildx imagetools inspect <image>:<tag> --format '{{json .Manifest}}' | jq -r .digest
```

Update the pins here, in `images/api/Dockerfile`, `compose.yaml`, and `_audit/spec_anycrawl.py`, then bump the
wrapper tag and re-run the tests. See `MAINTENANCE.md`.
