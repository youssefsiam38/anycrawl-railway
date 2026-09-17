# Third-party notices

This template packages and runs the following third-party software. Each keeps its own licence; the template's own
files are MIT (see `LICENSE`).

## AnyCrawl

- Source: https://github.com/any4ai/AnyCrawl
- Licence: MIT — full text in `licenses/ANYCRAWL-LICENSE`
- Used unmodified from the official images `ghcr.io/any4ai/anycrawl-api`, `…-scrape-cheerio`, `…-scrape-playwright`
  (pinned by digest in `UPSTREAM.md`). The wrapper on the api image only adds an API-key seed script and an
  entrypoint; the worker images are unmodified.

## PostgreSQL and Redis

- PostgreSQL: https://www.postgresql.org — official `postgres` image (PostgreSQL License).
- Redis: https://redis.io — official `redis` image (RSALv2/SSPL per the tag used).

---

"AnyCrawl" is the mark of its project. This template is community-maintained and is not affiliated with, or endorsed
by, the AnyCrawl project.
