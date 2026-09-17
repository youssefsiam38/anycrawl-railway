# Railway template configuration

The template's exact configuration. Reproduce it from this file if it ever has to be rebuilt.

| | |
|---|---|
| Name | AnyCrawl |
| Code | `anycrawl` |
| Template id | `41263ab5-82db-42e7-9c00-1eee8c432f97` |
| Deploy URL | https://railway.com/deploy/anycrawl |
| Category | AI/ML |
| Card description | Self-hosted scrape/crawl/SERP API that turns sites into LLM-ready data. |
| Icon | `assets/icon.png` |
| Overview markdown | `marketplace/OVERVIEW.md` (Railway enforces its section headings) |

Generated values use Railway's `secret()` function: `hexN` is `${{secret(N, "abcdef0123456789")}}` and `alnumN` is
`${{secret(N, "a-zA-Z0-9")}}` spelled out. Alphanumeric passwords are used wherever a value is embedded in a
connection URL, so nothing needs percent-encoding. Images are referenced by tag, because the template generator
rejects digests; `UPSTREAM.md` records the digests.

## Services

### `postgres`

| Field | Value |
|---|---|
| Source | `postgres:16-alpine` |
| Public domain | none |
| Volume | `/var/lib/postgresql` |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|
| `POSTGRES_USER` | `anycrawl` |
| `POSTGRES_DB` | `anycrawl` |
| `POSTGRES_PASSWORD` | generated, alnum48 |

### `redis`

| Field | Value |
|---|---|
| Source | `redis:7-alpine` |
| Public domain | none |
| Volume | `/data` |
| Start command | `redis-server --appendonly yes --protected-mode no` |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|

### `api`

| Field | Value |
|---|---|
| Source | `ghcr.io/youssefsiam38/anycrawl-railway:1.0.0` |
| Public domain | target port 8080 |
| Volume | none |
| Healthcheck | `/health`, timeout from `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `ANYCRAWL_REDIS_URL` | `redis://${{redis.RAILWAY_PRIVATE_DOMAIN}}:6379?family=0` |
| `ANYCRAWL_API_DB_TYPE` | `postgresql` |
| `ANYCRAWL_API_DB_CONNECTION` | `postgres://anycrawl:${{postgres.POSTGRES_PASSWORD}}@${{postgres.RAILWAY_PRIVATE_DOMAIN}}:5432/anycrawl` |
| `ANYCRAWL_API_AUTH_ENABLED` | `true` |
| `ANYCRAWL_API_CREDITS_ENABLED` | `true` |
| `MIGRATE_DATABASE` | `true` |
| `ANYCRAWL_API_PORT` | `8080` |
| `PORT` | `8080` |
| `ANYCRAWL_API_KEY` | generated, alnum48 |
| `ANYCRAWL_HEADLESS` | `true` |
| `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` | `300` |

### `scrape-cheerio`

| Field | Value |
|---|---|
| Source | `ghcr.io/any4ai/anycrawl-scrape-cheerio:v1.0.0` |
| Public domain | none |
| Volume | none |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `ANYCRAWL_REDIS_URL` | `redis://${{redis.RAILWAY_PRIVATE_DOMAIN}}:6379?family=0` |
| `ANYCRAWL_API_DB_TYPE` | `postgresql` |
| `ANYCRAWL_API_DB_CONNECTION` | `postgres://anycrawl:${{postgres.POSTGRES_PASSWORD}}@${{postgres.RAILWAY_PRIVATE_DOMAIN}}:5432/anycrawl` |
| `ANYCRAWL_HEADLESS` | `true` |
| `ANYCRAWL_IGNORE_SSL_ERROR` | `true` |
| `MIGRATE_DATABASE` | `false` |
| `ANYCRAWL_CRAWLEE_STORAGE_DIR` | `/tmp/anycrawl-crawlee-storage/cheerio` |

### `scrape-playwright`

| Field | Value |
|---|---|
| Source | `ghcr.io/any4ai/anycrawl-scrape-playwright:v1.0.0` |
| Public domain | none |
| Volume | none |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `ANYCRAWL_REDIS_URL` | `redis://${{redis.RAILWAY_PRIVATE_DOMAIN}}:6379?family=0` |
| `ANYCRAWL_API_DB_TYPE` | `postgresql` |
| `ANYCRAWL_API_DB_CONNECTION` | `postgres://anycrawl:${{postgres.POSTGRES_PASSWORD}}@${{postgres.RAILWAY_PRIVATE_DOMAIN}}:5432/anycrawl` |
| `ANYCRAWL_HEADLESS` | `true` |
| `ANYCRAWL_IGNORE_SSL_ERROR` | `true` |
| `MIGRATE_DATABASE` | `false` |
| `ANYCRAWL_CRAWLEE_STORAGE_DIR` | `/tmp/anycrawl-crawlee-storage/playwright` |

## Notes

- **Five services, queue-based.** The api (public) enqueues scrape jobs on Redis; the cheerio (static HTML) and
  playwright (JavaScript) workers consume them and write results to Postgres, which the api returns. No shared
  filesystem, so no shared volume is needed — a good fit for Railway's per-service volumes.
- **PostgreSQL volume is mounted at the PARENT `/var/lib/postgresql`, not `/var/lib/postgresql/data`.** A Railway
  volume mounted directly at the data dir contains a `lost+found`, and `initdb` refuses a non-empty data directory;
  the parent mount lets Postgres create a fresh data subdirectory. (Local Docker volumes have no `lost+found`, so
  this only bites on Railway.)
- **Redis + the ioredis client need the IPv6 fix.** The Redis URL is `redis://…:6379?family=0` so ioredis (which
  defaults to IPv4) reaches Railway's IPv6 private network; Redis runs with `redis-server --appendonly yes
  --protected-mode no` (listens on all interfaces, private-network only). Without `?family=0` the api and workers
  cannot reach Redis and scrapes hang.
- **API-key auth is on and the key is seeded.** `ANYCRAWL_API_KEY` (generated) is inserted into the database at
  start-up so it is readable from the api service's variables, not the logs. Only the api migrates the schema
  (`MIGRATE_DATABASE=true`); the workers set it to `false`.
- **`PORT` = 8080 = `ANYCRAWL_API_PORT`** = the domain target port; health check `/health`. Call the API with
  `Authorization: Bearer <ANYCRAWL_API_KEY>` and `POST /v1/scrape {"url":"…","engine":"cheerio|playwright"}`.
