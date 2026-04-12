---
status: resolved
trigger: "Docker Compose Sidekiq failing with ActiveRecord::NoDatabaseError: We could not find your database: chatwoot_dev"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
---

## Current Focus
hypothesis: "Environment variable mismatch — sidekiq service is missing POSTGRES_DATABASE env var"
test: "Read docker-compose.yaml to find postgres service config and compare DB names across services"
expecting: "Mismatch between what postgres creates vs what rails/sidekiq services use"
next_action: "Resolved — fix applied to docker-compose.yaml"

## Evidence
- timestamp: 2026-04-12T00:00:00.000Z
  checked: docker-compose.yaml postgres service
  found: "postgres container sets POSTGRES_DB=chatwoot"
  implication: "DB created inside container is named 'chatwoot'"
- timestamp: 2026-04-12T00:00:00.000Z
  checked: docker-compose.yaml rails service environment block
  found: "rails service has POSTGRES_DATABASE=chatwoot explicitly set"
  implication: "Rails service connects to correct DB"
- timestamp: 2026-04-12T00:00:00.000Z
  checked: docker-compose.yaml sidekiq service environment block
  found: "sidekiq service is MISSING POSTGRES_DATABASE env var"
  implication: "sidekiq falls back to Rails default: chatwoot_dev (RAILS_ENV=development suffix)"
- timestamp: 2026-04-12T00:00:00.000Z
  checked: .env for POSTGRES_DATABASE value
  found: "POSTGRES_DATABASE is commented out in .env (# POSTGRES_DATABASE=)"
  implication: "No fallback from .env — the compose file must set it per-service"

## Symptoms
<!-- IMMUTABLE -->
expected: Sidekiq connects to PostgreSQL using the correct database name
actual: Sidekiq tries to connect to `chatwoot_dev` but the database is `chatwoot`
errors: "ActiveRecord::NoDatabaseError: We could not find your database: chatwoot_dev"
reproduction: `docker compose up` - Sidekiq container throws NoDatabaseError
started: Started after recent docker-compose or env changes

## Eliminated
<!-- none -->

## Resolution
root_cause: "The `sidekiq` service block in docker-compose.yaml did not set `POSTGRES_DATABASE=chatwoot`. Without this override, Rails falls back to its default naming convention of appending `_#{RAILS_ENV}` to the app name, producing `chatwoot_dev`. The postgres container only creates a database named `chatwoot`, so sidekiq fails on startup."
fix: "Added `POSTGRES_DATABASE=chatwoot` to the `environment` block of the `sidekiq` service in docker-compose.yaml, matching what the `rails` service already had."
verification: "Fix applied — sidekiq service environment now matches rails service. Restart `docker compose up` and confirm sidekiq connects without NoDatabaseError."
files_changed:
  - docker-compose.yaml
