# Agent 1 Findings: Database Connection Flow Analysis

## Root Cause Identified

The database that `db:chatwoot_prepare` writes to differs from what `docker compose up` rails uses because of a **missing POSTGRES_DATABASE environment variable propagation**.

## Key Evidence

### 1. docker-compose.yaml rails service configuration
```yaml
rails:
  env_file: .env          # loads .env
  environment:
    - POSTGRES_DATABASE=chatwoot   # OVERRIDES env_file value
  entrypoint: docker/entrypoints/rails.sh
```

The `environment:` section in docker-compose **overrides** values from `env_file: .env`.

### 2. .env file state
```
# POSTGRES_DATABASE=     # Line 65 - COMMENTED OUT / EMPTY
POSTGRES_HOST=postgres    # Line 66
```

### 3. pg_database_url.rb (docker/entrypoints/helpers/pg_database_url.rb)
- Only handles: POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USERNAME
- Does NOT handle POSTGRES_DATABASE at all
- Only sets defaults if DATABASE_URL is present

### 4. database.yml default
```ruby
database: "<%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_dev') %>"
```
Defaults to `chatwoot_dev` when POSTGRES_DATABASE is not set.

## The Bug Flow

### Scenario 1: `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`

1. **Entrypoint is BYPASSED** - command runs directly without rails.sh
2. No POSTGRES_DATABASE is explicitly set via environment
3. .env has `POSTGRES_DATABASE=` (empty/commented)
4. pg_database_url.rb doesn't set POSTGRES_DATABASE
5. Rails uses default `chatwoot_dev` from database.yml
6. **Migrations run against `chatwoot_dev`**

### Scenario 2: `docker compose up`

1. Entrypoint `rails.sh` runs first
2. `environment: POSTGRES_DATABASE=chatwoot` from docker-compose.yaml is applied
3. This overrides the empty .env value
4. pg_database_url.rb runs (doesn't change POSTGRES_DATABASE)
5. Rails uses `chatwoot` from environment
6. **Migrations should run against `chatwoot`**

## Verification

If user ran `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`:
- Migrations wrote to `chatwoot_dev` database

Then `docker compose up`:
- Rails connects to `chatwoot` database
- Shows 120 pending migrations because `chatwoot` was never migrated

## Proposed Fix

The `.env` file should have:
```
POSTGRES_DATABASE=chatwoot
```

This ensures both `docker compose run` and `docker compose up` use the same database.

## Files Involved

| File | Issue |
|------|-------|
| `.env` | Missing `POSTGRES_DATABASE=chatwoot` |
| `docker-compose.yaml` | Has correct value but only in environment: section (not env_file) |
| `docker/entrypoints/rails.sh` | Doesn't ensure POSTGRES_DATABASE is set |
| `pg_database_url.rb` | Doesn't handle POSTGRES_DATABASE |
| `database.yml` | Defaults to `chatwoot_dev` |
