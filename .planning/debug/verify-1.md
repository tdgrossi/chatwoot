---
status: resolved
trigger: "verify docker-migration-mismatch-verification"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
---

## Verification Report: docker-migration-mismatch

### Key Question: Does `pg_database_url.rb` export `POSTGRES_DATABASE` from `DATABASE_URL`?

**Answer: NO.** Line 7 only exports:
```
POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USERNAME
```

It does NOT export `POSTGRES_DATABASE`. The database name is never extracted from `DATABASE_URL`.

---

### How Rails Resolves the Database Name

From `config/database.yml` line 17:
```ruby
database: "<%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_dev') %>"
```

**When `POSTGRES_DATABASE` is not set**, Rails defaults to `chatwoot_dev` (development) or `chatwoot_test` (test).

---

### What `docker compose run --rm rails` Uses

The `rails` service in `docker-compose.yaml` (line 43-49):
```yaml
env_file: .env
environment:
  - POSTGRES_DATABASE=chatwoot   # <-- EXPLICITLY SET
```

The `.env` file does NOT set `POSTGRES_DATABASE` (only `POSTGRES_HOST=postgres`, `POSTGRES_USERNAME`, `POSTGRES_PASSWORD`).

**BUT** the `environment:` block in docker-compose.yaml overrides this with `POSTGRES_DATABASE=chatwoot`.

So the rails container gets: `POSTGRES_DATABASE=chatwoot` from the compose file's environment block.

---

### What `docker compose up` Uses (via entrypoint)

The `rails.sh` entrypoint runs `pg_database_url.rb` which exports:
```
POSTGRES_HOST=<from DATABASE_URL or .env>
POSTGRES_PORT=<from DATABASE_URL or default 5432>
POSTGRES_USERNAME=<from DATABASE_URL or .env>
```

It does NOT export `POSTGRES_DATABASE`. So Rails falls back to the `.env` value (not set) or the default `chatwoot_dev`.

**BUT** the `environment:` block in docker-compose.yaml still sets `POSTGRES_DATABASE=chatwoot`, which overrides any fallback.

---

### Actual Database Names Used

| Scenario | POSTGRES_DATABASE Value | Database Connected |
|---|---|---|
| `docker compose run --rm rails bundle exec rails db:chatwoot_prepare` | `chatwoot` (from compose environment block) | `chatwoot` |
| `docker compose up` (via rails.sh entrypoint) | `chatwoot` (from compose environment block) | `chatwoot` |

Both scenarios use `POSTGRES_DATABASE=chatwoot` from the compose file's environment block.

---

### What `pg_database_url.rb` Actually Does

When `DATABASE_URL` is set (e.g., `postgres://user:pass@host:5432/dbname`):
- It extracts `host`, `port`, `user` from the URL
- Exports them as `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USERNAME`
- Does NOT extract or export the database name from the URL path

When `DATABASE_URL` is NOT set:
- It only exports `POSTGRES_PORT=5432` as a default (lines 8-9)

---

### Mismatch Verification

**Hypothesis was INCORRECT** in assuming the issue is with `docker compose run` vs `docker compose up`.

The actual mismatch is between:
- **User's host machine** (when running Rails outside Docker): May have `POSTGRES_HOST=localhost` pointing to a local postgres with `chatwoot_dev` database
- **Docker compose environment**: Both `run` and `up` use `POSTGRES_DATABASE=chatwoot` from the compose file

The **real issue** is:
1. The entrypoint script (`rails.sh`) does NOT export `POSTGRES_DATABASE` from `DATABASE_URL`
2. If a user sets `DATABASE_URL` in their `.env`, the database name in that URL is silently ignored
3. Rails then uses the default `chatwoot_dev` (not the database name from `DATABASE_URL`)

---

### Root Cause

**The `pg_database_url.rb` helper does not extract `POSTGRES_DATABASE` from `DATABASE_URL`.**

Line 7 only exports host, port, and username:
```ruby
puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user}"
```

The database name in `DATABASE_URL` (the path component after the host) is completely ignored. If `DATABASE_URL=postgres://postgres:password@localhost/chatwoot_prod`, only `localhost` is exported as `POSTGRES_HOST` - the `chatwoot_prod` database name is never exported as `POSTGRES_DATABASE`.

This means when the entrypoint runs, it correctly sets up host/port/user from `DATABASE_URL`, but the database name still comes from `POSTGRES_DATABASE` env var (which defaults to `chatwoot_dev` in development).

---

### Fix Direction

`pg_database_url.rb` should also extract and export the database name from `DATABASE_URL`:
```ruby
# Line 7 should include POSTGRES_DATABASE:
puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user} POSTGRES_DATABASE=#{uri.path[1..-1]}"
```

Or more robustly (handle empty path):
```ruby
db_name = uri.path.empty? ? nil : uri.path[1..-1]
puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user}#{" POSTGRES_DATABASE=#{db_name}" if db_name}"
```