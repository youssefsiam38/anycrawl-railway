# Security

## API-key authentication

AnyCrawl requires an API key on every request (`ANYCRAWL_API_AUTH_ENABLED=true`, `Authorization: Bearer <key>`).
On a public URL this is what stops strangers from using your deployment to crawl the web on your bill. Keys are
rows in the database.

This template generates `ANYCRAWL_API_KEY` (48 alphanumerics) and **seeds that exact value** into the database at
start-up, so the operator gets a known, working key from the service's variables — the upstream `generate-api-key`
script instead mints a random key printed to the log. The seed:

- reads the key only from the environment (never a hard-coded value),
- writes the request body through AnyCrawl's own DB layer (no secret on a command line),
- is idempotent (inserts once; leaves it alone afterwards),
- and never prints the key.

Verified in the smoke, persistence and live tests: a request with no key or a wrong key is rejected (`401`); the
seeded key works and survives a restart.

## Network posture

- **Only the api is public.** Postgres, Redis, and both scrape workers have no public domain; they are reachable
  only over Railway's private network. Redis runs with `--protected-mode no` because it is private-network-only (no
  public exposure) and AnyCrawl connects without a password, matching upstream's compose.
- **TLS at the edge.** Railway terminates HTTPS; the internal hops are plaintext inside the private network.
- **Pinned images.** Every image is pinned by digest (see `UPSTREAM.md`).

## What you should do

- **Copy and guard `ANYCRAWL_API_KEY`.** Anyone with it can drive your crawler. Rotate it by changing the variable
  (then re-seed / restart) or by managing keys directly in the database.
- **Mind egress and abuse.** A crawler fetches arbitrary URLs on your behalf; keep the key private and consider the
  credits limit (`ANYCRAWL_API_CREDITS_ENABLED=true`) when exposing it to others.
- **Back up the Postgres volume** (keys, jobs, results) with Railway's volume backups.

## Reporting

For issues in AnyCrawl itself, report upstream. For issues specific to this template's packaging, open an issue on
the template repository.
