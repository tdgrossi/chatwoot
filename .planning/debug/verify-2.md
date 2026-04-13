---
status: resolved
trigger: "docker-migration-mismatch-verification"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
resolved: 2026-04-13T07:20:00.000Z
---

## Current Focus
hypothesis: "When user runs `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`, it uses `POSTGRES_HOST=localhost` from the user's `.env` file, connecting to the host's local PostgreSQL. But `docker compose up` uses Docker's postgres service (hostname `postgres`), which has different/empty data."
test: "Trace what database connection params are set when running `docker compose run` vs `docker compose up` for the rails service"
expecting: "If hypothesis is correct, `docker compose run` would override POSTGRES_HOST with localhost, while `docker compose up` would use postgres hostname"
next_action: "Document findings and determine if hypothesis is confirmed or eliminated"

## Symptoms
expected: "docker compose run and docker compose up should use the same database"
actual: "Hypothesis suggests they use different databases"
errors: []
reproduction: []
started: "Hypothesis only - not yet investigated"

## Eliminated

## Evidence

### Finding 1: pg_database_url.rb does NOT export POSTGRES_DATABASE
- **checked:** docker/entrypoints/helpers/pg_database_url.rb line 7
- **found:** Script only exports: `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USERNAME` from DATABASE_URL
- **implication:** POSTGRES_DATABASE is never derived from DATABASE_URL by this script

### Finding 2: rails service in docker-compose.yaml sets POSTGRES_DATABASE=chatwoot
- **checked:** docker-compose.yaml lines 43-50
- **found:** The rails service has `environment:` block with hardcoded `POSTGRES_DATABASE=chatwoot`
- **implication:** Both `docker compose up` and `docker compose run` use the same rails service definition, so both get `POSTGRES_DATABASE=chatwoot`

### Finding 3: rails service does NOT run pg_database_url.rb on `docker compose run`
- **checked:** docker-compose.yaml line 50 - entrypoint is `docker/entrypoints/rails.sh`
- **found:** `pg_database_url.rb` is called inside `rails.sh` entrypoint (line 12), which runs `bundle exec rails db:chatwoot_prepare` (line 32)
- **implication:** When `docker compose run --rm rails bundle exec rails db:chatwoot_prepare` runs, it OVERRIDES the entrypoint/command, so the `rails.sh` entrypoint is NOT executed

### Finding 4: POSTGRES_HOST in .env is already `postgres`
- **checked:** .env line 66
- **found:** `POSTGRES_HOST=postgres` (not localhost)
- **implication:** User's .env already has the correct Docker hostname

### Finding 5: database.yml defaults to chatwoot_dev when POSTGRES_DATABASE unset
- **checked:** config/database.yml line 17
- **found:** `database: "<%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_dev') %>"`
- **implication:** If POSTGRES_DATABASE were not set, default database would be `chatwoot_dev`

### Finding 6: rails service depends on postgres service
- **checked:** docker-compose.yaml lines 35-37
- **found:** `depends_on: - postgres - redis ...`
- **implication:** Docker Compose network ensures `postgres` hostname resolves to the postgres container

## Resolution
root_cause: "HYPOTHESIS IS INCORRECT - No mismatch between docker compose run and docker compose up"
fix: "N/A - This hypothesis was wrong"
verification: "Independent verification confirms hypothesis does not hold"
files_changed: []
---