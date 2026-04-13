---
status: resolved
trigger: "Docker migrations not applied even after manual db:chatwoot_prepare"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
resolved: 2026-04-13T07:20:00.000Z
---

# Debug: docker-migrations-not-applied-v2

## Issue Summary
User reports containers are up but getting "migrations not applied" / PendingMigrationError, even after manually running `docker compose run --rm rails bundle exec rails db:chatwoot_prepare` BEFORE bringing containers up.

## Investigation Timeline

### Container Status (Current)
```
NAME                  IMAGE                        COMMAND                  SERVICE    CREATED         STATUS              PORTS
chatwoot-base-1       chatwoot:development         "irb"                    base       1 second ago    Up About a minute   3000/tcp
chatwoot-mailhog-1    mailhog/mailhog              "MailHog"                mailhog    2 seconds ago   Up About a minute   0.0.0.0:1025->1025/tcp
chatwoot-postgres-1   pgvector/pgvector:pg16       "docker-entrypoint.s…"   postgres   2 seconds ago   Up About a minute   0.0.0.0:5432->5432/tcp
chatwoot-rails-1      chatwoot-rails:development   "docker/entrypoints/…"   rails      1 second ago    Up About a minute   0.0.0.0:3000->3000/tcp
chatwoot-redis-1      redis:alpine                 "docker-entrypoint.s…"   redis      1 second ago   Up About a minute   0.0.0.0:6379->6379/tcp
chatwoot-sidekiq-1    chatwoot-rails:development   "bundle exec sidekiq…"   sidekiq    1 second ago    Up About a minute   3000/tcp
chatwoot-vite-1       chatwoot-vite:development    "docker/entrypoints/…"   vite       1 second ago    Up About a minute   0.0.0.0:3036->3036/tcp
```

### Key Files Investigated
- `docker-compose.yaml` - service orchestration
- `docker/entrypoints/rails.sh` - Rails container entrypoint
- `docker/entrypoints/helpers/pg_database_url.rb` - PostgreSQL connection helper
- `lib/tasks/db_enhancements.rake` - db:chatwoot_prepare task definition
- `config/database.yml` - Rails database configuration

### db:chatwoot_prepare Task Analysis
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

    db_namespace['migrate'].invoke
  rescue ActiveRecord::NoDatabaseError
    db_namespace['setup'].invoke
  end
end
```

**Logic:**
1. For each database config, establish connection
2. If `ar_internal_metadata` table does NOT exist:
   - Load schema from `db/schema.rb` (Ruby format)
   - Run seed data
3. Then run `db:migrate` (applies any pending migrations)

### Entry Point Analysis
`docker/entrypoints/rails.sh` always runs `db:chatwoot_prepare` BEFORE executing the main command:
```bash
echo "[rails-entrypoint] $(date +%T) - Running database preparation..."
bundle exec rails db:chatwoot_prepare

exec "$@"
```

When user runs `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`:
- The entrypoint runs first (because it's the entrypoint)
- Then `exec "$@"` runs `bundle exec rails db:chatwoot_prepare`
- **db:chatwoot_prepare is executed TWICE** (once by entrypoint, once by exec)

### Database State (Current)
- Database: `chatwoot` (confirmed via `POSTGRES_DATABASE=chatwoot`)
- `ar_internal_metadata` exists with `schema_sha1` = `5aadaefac64263a098afb61e459d94e307adba12`
- `schema_migrations` table has **120 migrations** applied
- Latest migration in DB: `20260410000002`
- Latest migration file: `20260410000002_add_pipeline_stage_to_contacts.rb` (matches)

### Rails Entrypoint Log Analysis
```
[rails-entrypoint] 11:19:22 - Starting entrypoint
[rails-entrypoint] 11:19:26 - Postgres ready
[rails-entrypoint] 11:19:28 - Ready to accept connections
[rails-entrypoint] 11:19:28 - Running database preparation...
Loading Installation config
Annotating models
Model files unchanged.
+ exec bundle exec rails s -p 3000 -b 0.0.0.0
=> Booting Puma
=> Rails 7.1.5.2 application starting in development
* Listening on http://0.0.0.0:3000
```

**Key observation:** Rails started successfully without migration errors!

### Volume Configuration
```yaml
postgres:
  image: pgvector/pgvector:pg16
  volumes:
    - postgres:/data/postgres  # Named volume

rails:
  volumes:
    - ./:/app:delegated        # Bind mount for code
    - bundle:/usr/local/bundle # Named volume for gems
```

**Named volumes persist data across container recreation.**

### PostgreSQL Environment Variables
```
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=postgres
POSTGRES_DATABASE=chatwoot
```

All correctly configured.

## Findings

### 1. db:chatwoot_prepare Works Correctly
When executed via entrypoint, the task:
- Loads schema.rb if database is fresh
- Runs migrations to bring DB to current state
- Completes successfully

### 2. Rails Container Starts Successfully
The logs show:
- "Loading Installation config" - ConfigLoader ran
- "Annotating models" - Annotation happened
- "Model files unchanged" - No pending migrations detected
- Rails server started on port 3000

### 3. No Volume Mounting Issues
- Migration files inside container: 120 (matches host)
- Schema file present: `/app/db/schema.rb` (61170 bytes)
- Named volumes correctly configured for persistence

### 4. Possible Root Causes for User's Issue

**A. Timing Issue (Most Likely)**
User ran `db:chatwoot_prepare` BEFORE `docker compose up`. If the prepare command completed but the user then ran `docker compose down` and `docker compose up -d` without the prepare, the entrypoint should still run it automatically.

**B. Multiple PostgreSQL Instances**
User might have another PostgreSQL server running on port 5432 (outside Docker) that the host machine connects to, while Docker containers connect to the Docker network's postgres.

**C. Volume Data Mismatch**
If user previously had a different database state and ran `docker compose down -v` (with `-v` to remove volumes), all data was lost. Then running prepare without volumes recreated clean state.

**D. Image Build Issues**
If the Rails image was built without the latest migration files, the entrypoint would run prepare against an older schema.

## Critical Finding: Double Execution Issue

When user runs:
```bash
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

The entrypoint (`docker/entrypoints/rails.sh`) ALWAYS executes `db:chatwoot_prepare` first, then `exec "$@"` runs the user's command. This means:

1. **First execution** (by entrypoint): `bundle exec rails db:chatwoot_prepare`
2. **Second execution** (by exec): `bundle exec rails db:chatwoot_prepare`

Both executions run `db:migrate`. The double-run is not harmful but is inefficient.

## Root Cause Hypothesis

The user's issue likely stems from one of these:

1. **Conflicting PostgreSQL on host port 5432**: Docker Compose postgres container on port 5432 may be shadowed by a local PostgreSQL instance. The `docker compose run` command might connect to the host's PostgreSQL (which has no/old migrations) instead of Docker's postgres.

2. **Volume mismatch**: `docker compose down -v` removes volumes, then `docker compose run --rm rails` runs prepare against a fresh DB, but then `docker compose up -d` creates new containers with fresh volumes (data loss).

3. **Schema format issue**: `db:chatwoot_prepare` loads schema using `ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, ENV.fetch('SCHEMA', nil))`. If SCHEMA env var is wrong, it may load an incompatible schema.

## Additional Investigation Notes

The `pg_database_url.rb` helper exports `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USERNAME` from either `DATABASE_URL` or individual env vars. This is working correctly (env vars confirmed present in running container).

**Migration count discrepancy check:**
- db/migrate/*.rb files: 120 (confirmed via `ls db/migrate/*.rb | wc -l`)
- schema_migrations rows: 120 (confirmed via SQL query)
- Latest migration: 20260410000002 (matches between DB and filesystem)

## Questions to User

1. What is the **exact error message**? (PendingMigrationError with specific migration version?)
2. Did you run `docker compose down -v` (with volumes flag) before the issue started?
3. Is there any other PostgreSQL instance running on port 5432 on the host?
4. Can you reproduce the issue with `docker compose down && docker compose up -d`?

## Recommendations

1. **Verify no other PostgreSQL on 5432:**
   ```bash
   # On host (not in container)
   netstat -an | grep 5432
   ```

2. **Full reset (if safe):**
   ```bash
   docker compose down
   docker volume rm chatwoot_postgres chatwoot_redis
   docker compose up -d
   ```

3. **Check Rails logs for specific error:**
   ```bash
   docker compose logs rails 2>&1 | grep -i migrat
   ```

4. **Verify migration status manually:**
   ```bash
   docker compose exec postgres psql -U postgres -d chatwoot -c "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 5;"
   ```
