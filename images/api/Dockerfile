# syntax=docker/dockerfile:1
#
# AnyCrawl API for the Railway template: the official API image, pinned by digest, plus a start-up wrapper that
# seeds a working API key from the ANYCRAWL_API_KEY environment variable (so the operator gets a known key without
# reading it from the logs). The application is unmodified — only a seed script and an entrypoint are added. The
# scrape worker images (cheerio, playwright) are used unmodified and are not wrapped. Not affiliated with AnyCrawl.
ARG ANYCRAWL_API_IMAGE=ghcr.io/any4ai/anycrawl-api:v1.0.0@sha256:c279e18d0bf31cd6154050f8f1bd40557032d1b0a17ed8975f2260f7fde2e710

FROM ${ANYCRAWL_API_IMAGE}
ARG WRAPPER_VERSION=0.0.0-dev
ARG VCS_REF=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z

COPY images/api/seed-railway-key.mjs /usr/src/app/apps/api/dist/scripts/seed-railway-key.mjs
COPY --chmod=0755 images/api/entrypoint.sh /usr/local/bin/anycrawl-railway-entrypoint

LABEL org.opencontainers.image.title="anycrawl-railway-api" \
      org.opencontainers.image.description="AnyCrawl API for the Railway template: the official image with an API-key seed start-up. Not affiliated with the AnyCrawl project." \
      org.opencontainers.image.source="https://github.com/youssefsiam38/anycrawl-railway" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${WRAPPER_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}"

ENTRYPOINT ["/usr/local/bin/anycrawl-railway-entrypoint"]
