# Agent 2 Findings: Entrypoint Behavior and Command Override

## Key Files Analyzed

### 1. docker/entrypoints/rails.sh

The entrypoint script does the following in order:
1. Removes stale PID file and cache
2. Waits for postgres to be ready using `pg_isready`
3. Runs `bundle check` and `bundle install` if gems are missing
4. **Runs `bundle exec rails db:chatwoot_prepare` unconditionally**
5. Executes the main process via `exec "$@"`

**Critical observation:** Line 32 - `bundle exec rails db:chatwoot_prepare` runs **every time** the container starts, regardless of what command is passed. This is NOT conditional.

### 2. lib/tasks/db_enhancements.rake - What db:chatwoot_prepare Does

The task `db:chatwoot_prepare` (lines 17-31):
- For each database config, establishes connection
- **If `ar_internal_metadata` table does NOT exist**: loads schema from SCHEMA env var and runs seeds (fresh database setup)
- **If `ar_internal_metadata` table EXISTS**: runs `db:migrate` (migration path)

This is the standard "create if missing, migrate if exists" pattern.

### 3. docker/entrypoints/helpers/pg_database_url.rb

A Ruby script that exports POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USERNAME from DATABASE_URL if present. Otherwise defaults port to 5432.

## The Core Issue: `docker compose run` vs `docker compose up`

### How ENTRYPOINT works:
- The Dockerfile declares `CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]`
- This gets converted to an ENTRYPOINT in the image metadata
- **When you use `docker compose run`, the service's ENTRYPOINT is NOT run by default** -- only the command you specify is run
- The `run` command bypasses the image's ENTRYPOINT entirely unless you pass `--entrypoint`

### The Problem Scenario:

1. **User runs:** `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`
   - Command override bypasses entrypoint
   - `db:chatwoot_prepare` runs via bundle exec
   - **Migrations execute and complete**

2. **User then runs:** `docker compose up`
   - This uses the full image entrypoint (rails.sh)
   - Entrypoint runs `bundle exec rails db:chatwoot_prepare` **AGAIN**
   - But wait -- `db:chatwoot_prepare` should be idempotent when tables exist...

### Possible Root Cause:

The entrypoint ALWAYS runs `db:chatwoot_prepare` on container start (line 32 of rails.sh). But `db:chatwoot_prepare` should skip migration if `ar_internal_metadata` exists.

**Hypothesis:** The entrypoint's `db:chatwoot_prepare` call may be running in a **different context** where:
- The database exists and has pending migrations from initial setup
- Something about the environment or database state is different between `run` and `up`

### Evidence from entrypoint:
- Line 32: `bundle exec rails db:chatwoot_prepare` runs **unconditionally** every time
- No check to see if migrations have already been run
- The idempotency relies entirely on `db:chatwoot_prepare`'s internal logic

### Additional Note:
Looking at `db_enhancements.rake` line 22: `ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, ENV.fetch('SCHEMA', nil))`

This loads schema from `ENV['SCHEMA']` - if this env var is not set properly during `up`, it could cause the schema loading path to fail and fall through to migration path.

## Summary

The entrypoint script **always runs** its initialization sequence (including `db:chatwoot_prepare`) when the container starts normally via `up`. The `run` command bypasses this entrypoint when you pass a command override.

The pending migrations issue likely stems from:
1. **SCHEMA env var not being set** during `docker compose up`, causing load_schema to fail or not run
2. **Race condition or timing issue** in how the entrypoint waits for postgres
3. **Multiple databases** being handled differently between the two invocation methods

Need to verify how SCHEMA env var is set and whether it's present during `docker compose up`.