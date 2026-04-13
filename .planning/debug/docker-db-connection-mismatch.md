---
status: resolved
trigger: "Docker DB connection mismatch - rails db:chatwoot_prepare succeeds but migrations not applied on container start"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
resolved: 2026-04-13T07:20:00.000Z
---

# Debug: docker-db-connection-mismatch

## Issue Summary
User runs `docker compose run --rm rails bundle exec rails db:chatwoot_prepare` (succeeds), then runs `docker compose up`. But Rails still shows 120 pending migrations. The DB that migrations run against is different from what the Rails container uses.

## Root Cause: pg_database_url.rb Does Not Export POSTGRES_DATABASE

The `docker/entrypoints/helpers/pg_database_url.rb` script only exports `POSTGRES_HOST`, `POSTGRES_PORT`, and `POSTGRES_USERNAME` from `DATABASE_URL`. It does NOT export `POSTGRES_DATABASE`.

**pg_database_url.rb (lines 5-10):**
```ruby
if !ENV['DATABASE_URL'].nil? && ENV['DATABASE_URL'] != ''
  uri = URI(ENV.fetch('DATABASE_URL', nil))
  puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user}"
elsif ENV['POSTGRES_PORT'].nil? || ENV['POSTGRES_PORT'] == ''
  puts 'export POSTGRES_PORT=5432'
end
```

**The problem:** If `DATABASE_URL` is set in `.env` with a different host (e.g., `localhost`) or different database name, the script will:
1. Export `POSTGRES_HOST` from `DATABASE_URL` (e.g., `localhost`)
2. NOT export `POSTGRES_DATABASE` from `DATABASE_URL`

This means `docker compose run --rm rails` can connect to a DIFFERENT postgres than the Docker postgres service.

## Scenario That Causes This Issue

1. User has in `.env`:
   ```
   DATABASE_URL=postgres://postgres:postgres@localhost:5432/chatwoot_dev
   ```
   OR individual vars:
   ```
   POSTGRES_HOST=localhost
   ```

2. `pg_database_url.rb` exports `POSTGRES_HOST=localhost` (from `DATABASE_URL`)

3. `pg_isready -h localhost -p 5432 -U postgres` checks the **host's local postgres**, not the Docker postgres service

4. If host has a local postgres with old/no migrations, `db:chatwoot_prepare` runs migrations on the **wrong database**

5. When `docker compose up` runs, `POSTGRES_HOST=postgres` (from docker-compose environment), connecting to the **correct Docker postgres** which has no/old migrations

## docker-compose.yml Configuration

**Rails service (lines 44-50):**
```yaml
environment:
  - POSTGRES_DATABASE=chatwoot
entrypoint: docker/entrypoints/rails.sh
```

**Postgres service (lines 93-103):**
```yaml
postgres:
  image: pgvector/pgvector:pg16
  ports:
    - '5432:5432'
  volumes:
    - postgres:/data/postgres
  environment:
    - POSTGRES_DB=chatwoot
    - POSTGRES_USER=${POSTGRES_USERNAME}
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
```

**Key observation:** The postgres container sets `POSTGRES_DB=chatwoot` (database name), but the `pg_database_url.rb` script ignores the database name from `DATABASE_URL`.

## Entrypoint Execution Flow

`docker/entrypoints/rails.sh`:
```sh
$(docker/entrypoints/helpers/pg_database_url.rb)  # Sets env vars from DATABASE_URL
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"
until $PG_READY; do sleep 2; done
bundle exec rails db:chatwoot_prepare  # Always runs, even if user specifies command
exec "$@"
```

**Double execution issue:** When user runs:
```bash
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```
The entrypoint runs `db:chatwoot_prepare` first, then `exec "$@"` runs it again. Both executions use the same (possibly wrong) `POSTGRES_HOST`.

## Why docker compose run Works Differently Than docker compose up

| Aspect | `docker compose run` | `docker compose up` |
|--------|---------------------|---------------------|
| Environment | Shell + `.env` + compose environment | Compose environment only |
| `DATABASE_URL` in `.env` | Used by entrypoint | NOT used (not in environment section) |
| `POSTGRES_HOST` | May be `localhost` (from `.env`) | Always `postgres` (Docker service) |
| `pg_isready` target | Host's local postgres | Docker postgres |
| Migration target | Host's postgres | Docker postgres |

## Evidence from Existing Debug Sessions

From `.planning/debug/docker-migrations-not-applied-v2.md`:
> The `pg_database_url.rb` helper exports `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USERNAME` from either `DATABASE_URL` or individual env vars. This is working correctly...

The previous investigation confirmed `pg_database_url.rb` doesn't export `POSTGRES_DATABASE`, but this was not identified as the root cause.

## Recommended Fix

**Option 1:** Modify `pg_database_url.rb` to also export the database name:
```ruby
if !ENV['DATABASE_URL'].nil? && ENV['DATABASE_URL'] != ''
  uri = URI(ENV.fetch('DATABASE_URL', nil))
  puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user} POSTGRES_DATABASE=#{uri.path[1..-1]}"
elsif ENV['POSTGRES_PORT'].nil? || ENV['POSTGRES_PORT'] == ''
  puts 'export POSTGRES_PORT=5432'
end
```

**Option 2:** Document that users should NOT have `DATABASE_URL` or `POSTGRES_HOST=localhost` in their `.env` when using Docker.

**Option 3:** Have the entrypoint explicitly override `POSTGRES_HOST` to always use the Docker service name:
```sh
# Always use Docker's postgres service
export POSTGRES_HOST=postgres
```

## User Verification Steps

1. Check if `POSTGRES_HOST=localhost` or `DATABASE_URL` with `localhost` is in `.env`
2. Check if host has postgres running on port 5432: `netstat -an | grep 5432`
3. Verify which database migrations run against:
   ```bash
   # In docker compose run (check logs)
   docker compose run --rm rails echo "POSTGRES_HOST=$POSTGRES_HOST"
   ```
4. Check docker postgres migration count:
   ```bash
   docker compose exec postgres psql -U postgres -d chatwoot -c "SELECT COUNT(*) FROM schema_migrations;"
   ```
5. Check host postgres migration count (if running locally):
   ```bash
   psql -U postgres -d chatwoot_dev -c "SELECT COUNT(*) FROM schema_migrations;"
   ```

## Related Issues

- `.planning/debug/docker-migrations-not-applied-v2.md` - Same issue, investigated but root cause not fully identified
- `.planning/debug/resolved/sidekiq-db-name-mismatch.md` - Similar pattern: missing `POSTGRES_DATABASE` env var
