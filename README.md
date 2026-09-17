# AnyCrawl on Railway

A one-click [Railway](https://railway.com) template that runs [AnyCrawl](https://github.com/any4ai/AnyCrawl) — a
self-hosted scrape / crawl / SERP API that turns websites into **LLM-ready data** (a MIT-licensed Firecrawl-style
service). API-key authentication is on, and a working key is **generated and seeded** for you.

This is a community-maintained template and is not affiliated with the AnyCrawl project.

- **Template image:** `ghcr.io/youssefsiam38/anycrawl-railway` (the official API image, pinned by digest, with
  an API-key seed) plus the official worker images
- **Upstream:** AnyCrawl (MIT) + PostgreSQL + Redis — see [UPSTREAM.md](UPSTREAM.md)

## What you get

- Five services: **api** (public HTTPS), **scrape-cheerio** and **scrape-playwright** (workers), **postgres** and
  **redis** (private). The API enqueues scrape jobs on Redis; the workers do the fetching and write results to
  Postgres.
- **API-key auth on** with a generated `ANYCRAWL_API_KEY`, seeded at start-up so you never read it from the logs.
- Two engines: **cheerio** (fast static HTML) and **playwright** (JavaScript-rendered pages).

## Deploy

1. Click **Deploy on Railway** and wait for the services to go healthy.
2. Open the **api** service → **Variables** and copy `ANYCRAWL_API_KEY`.
3. Call the API at your public domain.

## Use it

```bash
# scrape a static page (cheerio)
curl -X POST https://<your-domain>/v1/scrape \
  -H "Authorization: Bearer <ANYCRAWL_API_KEY>" -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","engine":"cheerio"}'

# scrape a JavaScript-rendered page (playwright)
curl -X POST https://<your-domain>/v1/scrape \
  -H "Authorization: Bearer <ANYCRAWL_API_KEY>" -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","engine":"playwright"}'
```

The response includes the page's `markdown` (LLM-ready), title and metadata. AnyCrawl also exposes crawl and SERP
endpoints — see the [AnyCrawl docs](https://github.com/any4ai/AnyCrawl).

## Security

- The API key is generated per deploy and gates every request; treat it like a password. Rotate it by changing
  `ANYCRAWL_API_KEY` (and re-seeding) or by managing keys in the database.
- Postgres and Redis have no public domain — only the api and workers reach them over Railway's private network.
- See [SECURITY.md](SECURITY.md).

## Repository layout

| Path | What |
|---|---|
| `images/api/Dockerfile` · `entrypoint.sh` · `seed-railway-key.mjs` | The api wrapper and API-key seed |
| `compose.yaml` | Lean local test topology (api + cheerio + postgres + redis) |
| `tests/` | Static, smoke (scrape loop), persistence, and live (HTTPS, both engines) tests |
| `marketplace/OVERVIEW.md` | The marketplace overview shown on the template page |
| `RAILWAY_TEMPLATE.md` | The exact published template configuration (all five services) |
| `UPSTREAM.md` · `SECURITY.md` · `ARCHITECTURE.md` · `MAINTENANCE.md` | Reference docs |

## Local development

```bash
docker compose up --build     # api + cheerio + postgres + redis
tests/smoke.sh                # health, auth, seeded key, scrape→markdown
tests/persistence.sh          # the key + data survive a restart
```

## Licence

The template's own files are MIT (`LICENSE`). AnyCrawl, PostgreSQL and Redis keep their own licences; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
