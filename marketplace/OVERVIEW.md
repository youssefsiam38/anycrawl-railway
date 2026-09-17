# Deploy and Host AnyCrawl on Railway

AnyCrawl is an open-source, self-hosted scrape / crawl / SERP API that turns websites into LLM-ready data and
extracts structured search results — a MIT-licensed alternative to hosted crawling APIs. This template deploys
AnyCrawl with API-key authentication on and a working key generated for you. It is a community-maintained template
and is not affiliated with the AnyCrawl project.

## About Hosting AnyCrawl

AnyCrawl is a small microservice set: an HTTP API plus per-engine scrape workers that communicate through Redis (a
job queue) and PostgreSQL (state and results). It requires API-key authentication — keys are database rows, and
exposing the API without a key on a public URL would let anyone crawl the web on your bill.

This template runs AnyCrawl on Railway with a bundled private PostgreSQL and Redis, a static-HTML (cheerio) worker
and a JavaScript-rendering (playwright) worker, and it generates an API key and seeds it into the database at
start-up — so you get a known, working key from the service's variables instead of one printed to the logs. Only
the API is public; the workers, database and cache stay on the private network. Every image is official and pinned
by digest.

## Common Use Cases

- Feeding clean, LLM-ready markdown from web pages into RAG pipelines and agents.
- Scraping JavaScript-rendered pages (via the playwright engine) that a plain HTTP fetch cannot read.
- Running a private, self-hosted crawling/SERP API where the data and the key stay in your own infrastructure.

## Dependencies for AnyCrawl Hosting

- Nothing external — PostgreSQL and Redis are bundled, and the scrape workers run in the same project.

### Deployment Dependencies

- AnyCrawl: https://github.com/any4ai/AnyCrawl (MIT)
- PostgreSQL and Redis (official Docker images)
- Template repository, image and tests: https://github.com/youssefsiam38/anycrawl-railway

### Implementation Details

The API runs upstream's official image, pinned by digest, with a start-up wrapper that seeds the API key from the
generated `ANYCRAWL_API_KEY` (using AnyCrawl's own database layer, idempotently, without printing it). The API
enqueues scrape jobs on Redis; the cheerio worker (static HTML) and the playwright worker (JavaScript-rendered
pages) consume them and write results to PostgreSQL, which the API returns — so no shared filesystem is needed
between services. Redis is reachable over Railway's IPv6 private network via the client's `family=0` option, only the API has a public domain, and
the port and health check are wired.

Tested in CI and on a live deployment of this template: the API is healthy, a request with no key or a wrong key is
rejected, the seeded key works, and a scrape returns LLM-ready markdown for both the cheerio and playwright engines;
the key and data survive a redeploy.

After deploying, copy `ANYCRAWL_API_KEY` from the api service's variables and call
`POST https://<your-domain>/v1/scrape` with `Authorization: Bearer <key>` and a JSON body
`{"url":"…","engine":"cheerio"}` (or `"playwright"` for JavaScript pages).

## Why Deploy AnyCrawl on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you
don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying AnyCrawl on Railway, you are one step closer to supporting a complete full-stack application with
minimal burden. Host your servers, databases, AI agents, and more on Railway.
