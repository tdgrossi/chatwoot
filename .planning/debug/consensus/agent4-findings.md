# Agent-4 Findings: Rails Schema Migration State Detection

## Investigation Focus
Understanding HOW Rails determines if migrations are "pending" and what could cause false positives when migrations have already run successfully.

---

## 1. How Rails Determines Pending Migrations

### The `schema_migrations` Table

Rails stores all applied migrations in the `schema_migrations` table. This table has a simple structure:
- **Table**: `schema_migrations`
- **Column**: `version` (VARCHAR, stores migration timestamp like `20260410000002`)
- **Key**: Primary key on `version`

Rails compares:
1. **Migrations in `db/migrate/` directory** (sorted by version)
2. **Migrations recorded in `schema_migrations` table**

A migration is "pending" if its version exists in `db/migrate/` but NOT in `schema_migrations`.

### Rails Migration Check Mechanism

Rails' `ActiveRecord::MigrationContext` determines pending migrations by:

```ruby
# Simplified logic from ActiveRecord::MigrationContext
def pending_migrations
  migrations.reject { |m| executed?(m) }
end

def executed?(migration)
  # Check if version exists in schema_migrations table
  ActiveRecord::Base.connection.execute(
    "SELECT version FROM schema_migrations WHERE version = '#{migration.version}'"
  ).any?
end
```

**Key insight**: Rails ONLY checks if the version string is present in `schema_migrations`. It does NOT verify:
- Schema structure
- Whether migrations ran successfully
- Whether database state matches migration intent

### The `PendingMigrationError`

The error `ActiveRecord::PendingMigrationError` is raised when:
1. `ActiveRecord::Migration.maintain_test_schema!` is called (in Rails environments)
2. There are migrations in `db/migrate/` that don't have corresponding entries in `schema_migrations`

---

## 2. The `db:chatwoot_prepare` Task

From `lib/tasks/db_enhancements.rake`:

```ruby
task chatwoot_prepare: :load_config do
  ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
    ActiveRecord::Base.establish_connection(db_config.configuration_hash)
    unless ActiveRecord::Base.connection.table_exists? 'ar_internal_metadata'
      db_namespace['load_config'].invoke if ActiveRecord.schema_format == :ruby
      ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, ENV.fetch('SCHEMA', nil))
      db_namespace['seed'].invoke
    end

    db_namespace['migrate'].invoke  # <-- Applies pending migrations
  rescue ActiveRecord::NoDatabaseError
    db_namespace['setup'].invoke
  end
end
```

**What happens:**
1. For each database config (development, test), it establishes connection
2. If `ar_internal_metadata` table exists, it runs `db:migrate`
3. `db:migrate` queries `schema_migrations` to find pending migrations
4. Running migrations inserts version into `schema_migrations`

---

## 3. Multiple Database Environments

Rails can have multiple database configurations in `config/database.yml`:

```yaml
development:
  database: "<%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_dev') %>"
  # Default: chatwoot_dev

test:
  database: "<%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_test') %>"
  # Default: chatwoot_test
```

**Critical**: `db:chatwoot_prepare` iterates over ALL database configs for the current Rails environment. Each has its own `schema_migrations` table.

If Rails runs with `RAILS_ENV=development`:
- It connects to `chatwoot_dev` database
- Uses that database's `schema_migrations` table

If Rails runs with `RAILS_ENV=test`:
- It connects to `chatwoot_test` database
- Uses that database's `schema_migrations` table (separate!)

---

## 4. What Could Cause False Positives?

### A. Different Database Connections

**Most likely cause of user's issue:**

If `docker compose run --rm rails` connects to a DIFFERENT postgres than `docker compose up`, the `schema_migrations` table being checked might be in a different database.

**Mechanism:**
1. `pg_database_url.rb` exports `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USERNAME` from `DATABASE_URL`
2. It does NOT export `POSTGRES_DATABASE` from `DATABASE_URL`
3. If `DATABASE_URL` in `.env` has different host (e.g., `localhost`) than Docker postgres (`postgres`), two different databases might be accessed

**The pg_database_url.rb issue (from previous debug):**
```ruby
# Lines 5-10 - only exports HOST, PORT, USERNAME - NOT DATABASE
if !ENV['DATABASE_URL'].nil? && ENV['DATABASE_URL'] != ''
  uri = URI(ENV.fetch('DATABASE_URL', nil))
  puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user}"
  # POSTGRES_DATABASE is NOT extracted!
end
```

If user has `DATABASE_URL=postgres://...@localhost:5432/chatwoot_dev` in `.env`:
- `pg_database_url.rb` exports `POSTGRES_HOST=localhost`
- Docker's postgres service is named `postgres`, not `localhost`
- Migrations run against host's postgres (potentially different database state)
- `docker compose up` uses `POSTGRES_HOST=postgres` from docker-compose environment
- Checks Docker postgres's `schema_migrations` (different!)

### B. Multiple Rails Environments

If `db:chatwoot_prepare` was run in one environment (e.g., `development`) but Rails boots in another (e.g., `test`), the `schema_migrations` tables would be in different databases.

```bash
# Run migrations in development
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
# This creates schema_migrations in chatwoot_dev

# Rails boots expecting chatwoot (Docker postgres)
# But docker-compose sets POSTGRES_DATABASE=chatwoot (different DB!)
```

### C. Schema Loading vs Migration

The `db:chatwoot_prepare` task does:
1. If `ar_internal_metadata` doesn't exist: `load_schema_current` (loads from `db/schema.rb`)
2. Then: `db:migrate` (applies pending migrations)

**Issue**: If schema was loaded from `db/schema.rb` but migrations weren't run, the `schema_migrations` table might have entries from the schema load that don't match actual migration files.

---

## 5. Entry Point Flow Analysis

From `docker/entrypoints/rails.sh`:
```bash
$(docker/entrypoints/helpers/pg_database_url.rb)  # Set env vars from DATABASE_URL
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"
until $PG_READY; do sleep 2; done
bundle exec rails db:chatwoot_prepare  # Always runs
exec "$@"
```

When user runs: `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`

The entrypoint runs `db:chatwoot_prepare` FIRST, then `exec "$@"` runs it AGAIN.

Both executions use the same `POSTGRES_HOST` which comes from:
1. `pg_database_url.rb` parsing `DATABASE_URL` from `.env`
2. OR `postgres` from docker-compose environment variable

**If DATABASE_URL contains localhost**: Migrations run against host postgres, not Docker postgres.

---

## 6. Key Findings Summary

| Aspect | Details |
|--------|---------|
| **Where pending status is stored** | `schema_migrations.version` table in the connected database |
| **How pending is determined** | Migration version exists in `db/migrate/` but NOT in `schema_migrations` |
| **What `db:chatwoot_prepare` does** | Iterates all DB configs, runs `db:migrate` for each |
| **What could cause false positive** | Connecting to wrong database (different `schema_migrations` table) |
| **Root cause hypothesis** | `pg_database_url.rb` doesn't export `POSTGRES_DATABASE`, causing connection to wrong postgres instance |

---

## 7. Migration Version Counts

From investigation:
- Total migration files: **120**
- Latest migration: `20260410000002_add_pipeline_stage_to_contacts.rb`
- These numbers match between filesystem and what was observed in Docker postgres

---

## 8. Questions for Agent-5

1. In your investigation of environment variables and Docker entrypoints, did you observe any case where `POSTGRES_DATABASE` is set differently between `docker compose run` and `docker compose up`?

2. Did you find evidence of multiple postgres instances (host vs Docker) being accessed during the migration process?

3. Are there any differences in how the Rails environment is determined between `docker compose run` and `docker compose up`?

---

## Conclusion

Rails determines pending migrations by comparing:
1. Migration files in `db/migrate/`
2. Entries in `schema_migrations` table of the connected database

**The most likely false positive cause**: Migrations were applied to a DIFFERENT database than the one Rails connects to during `docker compose up`. This happens because:
- `pg_database_url.rb` exports `POSTGRES_HOST` from `DATABASE_URL` (potentially wrong host)
- It does NOT export `POSTGRES_DATABASE` from `DATABASE_URL`
- Result: Two different postgres instances may be used, with different `schema_migrations` states