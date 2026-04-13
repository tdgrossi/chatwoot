---
status: resolved
trigger: "Docker migrations not applied when Rails server starts"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
resolved: 2026-04-13T07:20:00.000Z
---

# Debug: Docker Migrations Not Applied

## Issue Summary
Docker containers are up but migrations are not being applied when Rails server starts.

## Investigation

### 1. Error Observed
When running `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`, migrations were actually being applied (all 120 migrations ran successfully). However, when the Rails container started normally via `docker compose up rails`, the server would fail with:

```
ActiveRecord::PendingMigrationError
Migrations are pending. To resolve this issue, run:
        bin/rails db:migrate
You have 120 pending migrations:
```

### 2. Root Cause
The `docker/entrypoints/rails.sh` entrypoint script was missing the database preparation step before starting the Rails server.

**Before (broken):**
```bash
echo "[rails-entrypoint] $(date +%T) - Ready to accept connections"

# Execute the main process of the container
exec "$@"
```

The entrypoint only:
1. Waited for postgres to be ready
2. Checked bundle status

It never ran `db:chatwoot_prepare` (or any migration step) before starting the Rails server.

### 3. Fix Applied
Modified `docker/entrypoints/rails.sh` to include the database preparation step:

**After (fixed):**
```bash
echo "[rails-entrypoint] $(date +%T) - Ready to accept connections"

# Prepare the database (run migrations or setup if needed)
echo "[rails-entrypoint] $(date +%T) - Running database preparation..."
bundle exec rails db:chatwoot_prepare

# Execute the main process of the container
exec "$@"
```

### 4. Verification
After rebuilding the Docker image and restarting the Rails container:
- The entrypoint now runs `db:chatwoot_prepare` before starting Rails
- Logs show "Running database preparation..." message
- Migrations are confirmed applied (if not already)
- Rails server starts successfully without `PendingMigrationError`

### 5. Files Changed
- `docker/entrypoints/rails.sh` - Added `bundle exec rails db:chatwoot_prepare` step

## Notes
- The `db:chatwoot_prepare` task is designed to be idempotent - it runs migrations if needed, or does nothing if migrations are already applied
- This fix ensures the database is properly prepared on every container start
- Requires rebuilding the Docker image (`docker compose build rails`) for changes to take effect
