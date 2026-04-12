# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## sidekiq-db-name-mismatch - Docker Compose Sidekiq database name mismatch
- **Date:** 2026-04-12
- **Error patterns:** ActiveRecord::NoDatabaseError, chatwoot_dev, sidekiq, docker-compose, POSTGRES_DATABASE
- **Root cause:** The `sidekiq` service block in docker-compose.yaml was missing the `POSTGRES_DATABASE=chatwoot` environment variable override. Without it, Rails defaults to `chatwoot_dev` (app name + `_#{RAILS_ENV}`), but the postgres container only creates a database named `chatwoot`.
- **Fix:** Added `POSTGRES_DATABASE=chatwoot` to the `environment` block of the `sidekiq` service in docker-compose.yaml.
- **Files changed:** docker-compose.yaml
---
