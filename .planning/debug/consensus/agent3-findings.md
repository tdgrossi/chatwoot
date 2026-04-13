# Agent 3 Findings: Volume and Data Persistence

## Configuration Analysis

### docker-compose.yaml postgres service (lines 93-103):
```yaml
postgres:
  image: pgvector/pgvector:pg16
  restart: always
  ports:
    - '5432:5432'
  volumes:
    - postgres:/data/postgres
  environment:
    - POSTGRES_DB=chatwoot
    - POSTGRES_USER=${POSTGRES_USERNAME}
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
```

### Named volumes defined (lines 121-127):
```yaml
volumes:
  postgres:      # <-- This is a NAMED VOLUME
  redis:
  packs:
  node_modules:
  cache:
  bundle:
```

### Rails environment variables (.env):
```
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DATABASE=chatwoot   # Set in docker-compose rails service (line 49)
```

### Rails entrypoint (docker/entrypoints/rails.sh):
- Runs `rails db:chatwoot_prepare` on EVERY container start (line 32)

## Key Findings

### 1. Named Volume Configuration: CORRECT
- The `postgres` service uses named volume `postgres:/data/postgres`
- This SHOULD persist data to Docker's named volume storage, not host filesystem
- Named volumes persist across `docker compose down` (without `-v` flag)

### 2. Migration Count: 120 pending = ZERO migrations applied
- Confirmed: `db/migrate/*.rb` contains exactly 120 migration files
- "120 pending migrations" means the `schema_migrations` table is EMPTY
- This indicates the database was reset/erased, not that migrations failed

### 3. Data Persistence Behavior
| Command | Volumes Effect |
|---------|---------------|
| `docker compose down` | Named volumes PRESERVED |
| `docker compose down -v` | Named volumes DELETED |
| `docker compose up` | Reattaches existing volumes |
| `docker compose run --rm` | Uses same volumes as up |

### 4. What Happens During Commands

**`docker compose run --rm rails bundle exec rails db:chatwoot_prepare`:**
1. Docker Compose starts postgres service (if not running)
2. Postgres starts with `restart: always` - stays running in background
3. Rails container runs migrations successfully
4. Migrations recorded in `schema_migrations` table
5. Rails container removed (`--rm`), postgres remains

**`docker compose up` (after):**
1. Rails entrypoint runs `rails db:chatwoot_prepare`
2. Rails checks `schema_migrations` table
3. If 120 pending: database was reset since last run

## Root Cause Hypothesis

**Most Likely Cause: `docker compose down -v` was run between commands**

If the user (or a script) ran `docker compose down -v`, the postgres named volume would be DELETED. When `docker compose up` starts postgres again, it creates a FRESH database with no schema, causing all 120 migrations to appear as pending.

**Alternative Causes:**
1. Volume attachment failure during postgres start
2. Postgres connecting to wrong database (host postgres vs docker postgres)
3. Docker storage driver issue (aufs/overlay2 volume corruption)

## Verification Steps

To confirm volume is persisting:
```bash
# Check if postgres volume exists
docker volume ls | grep chatwoot_postgres

# Inspect volume details
docker volume inspect chatwoot_postgres

# Check postgres logs for "database system is ready"
docker compose logs postgres | grep -i ready
```

## Potential Issue: No postgres env_file

The postgres service does NOT have `env_file: .env`:
```yaml
postgres:
  # ... no env_file here
  environment:
    - POSTGRES_DB=chatwoot
    - POSTGRES_USER=${POSTGRES_USERNAME}  # interpolated from shell
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
```

But this is fine because docker-compose interpolates `${POSTGRES_USERNAME}` from the host environment before passing to the container.

## Conclusion

**The named volume IS correctly configured.** Data should persist between `run` and `up` commands unless:
1. `docker compose down -v` was executed (intentionally or in a cleanup script)
2. Docker volume storage has issues

The user's issue is NOT a configuration problem but likely a command sequence issue where volumes were deleted.
