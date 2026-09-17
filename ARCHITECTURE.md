# Architecture

## Service graph

```
                 Railway HTTPS edge
                        │
                        ▼
              ┌───────────────────┐        enqueue jobs        ┌──────────────┐
              │  api (:8080)      │ ─────────────────────────▶ │  redis       │  (queue, private, :6379, ::)
              │  HTTP API + auth  │ ◀───────── results ─────── │  scrape-*    │
              │  seeds the key    │        (via Postgres)      └──────────────┘
              └─────────┬─────────┘                                   ▲
                        │                                             │ consume jobs
                        ▼                              ┌──────────────┴──────────────┐
              ┌───────────────────┐                    │ scrape-cheerio (static HTML) │
              │  postgres         │◀───────────────────│ scrape-playwright (JS pages) │
              │  keys, jobs,      │   read/write        └──────────────────────────────┘
              │  results (private)│
              └───────────────────┘
```

Five services. The **api** is the only public one. It authenticates the request (Bearer API key), enqueues a
scrape job on **redis**, and the matching **worker** (cheerio for static HTML, playwright for JavaScript-rendered
pages) fetches the page and writes the result to **postgres**; the api returns it. Nothing is shared over a
filesystem, so the services need no shared volume — which is exactly what Railway's per-service volumes require.

## The api service

- Image: the official `anycrawl-api`, pinned by digest, plus a start-up wrapper. **Port** `8080` — the template
  sets `PORT=8080`, `ANYCRAWL_API_PORT=8080` and the public domain's target port to `8080`, and the health check to
  `/health`, all aligned. **Auth** is on (`ANYCRAWL_API_AUTH_ENABLED=true`).
- **API-key seed.** AnyCrawl keys are database rows; upstream only mints a random key printed to the log. The
  wrapper instead seeds the key value from the generated `ANYCRAWL_API_KEY` env var (readable from the service's
  variables), using AnyCrawl's own DB layer. The seed runs in the background and retries until the schema exists
  (the api runs migrations, `MIGRATE_DATABASE=true`), and is idempotent. The key never touches a command line or
  the logs.

## The worker services

- `scrape-cheerio` and `scrape-playwright` run the official worker images unmodified. They have no public domain,
  connect to Redis (queue) and Postgres (results), and set `MIGRATE_DATABASE=false` (only the api migrates). The
  playwright worker runs a headless Chromium for JavaScript-rendered pages; cheerio is a fast static-HTML fetcher.
  The default engine is **cheerio**.

## postgres and redis

- `postgres:16-alpine`, pinned by digest, volume at `/var/lib/postgresql/data` — holds API keys, jobs and results.
- `redis:7-alpine`, pinned by digest, volume at `/data` (AOF). Run with `redis-server --appendonly yes --bind ::
  --protected-mode no` so it is reachable over Railway's IPv6 private network (dual-stack on Linux). Neither has a
  public domain.

## Notes

- The lean `compose.yaml` (api + cheerio + postgres + redis) mirrors the queue/result path for fast local and CI
  testing; the published template additionally runs `scrape-playwright` for JavaScript pages (verified on the live
  deploy). Both engines are exercised by `tests/railway-smoke.sh`.
