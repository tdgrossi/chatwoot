---
status: resolved
trigger: "docker-migration-mismatch-verification"
created: 2026-04-12T00:00:00Z
updated: 2026-04-12T00:00:00Z
resolved: 2026-04-13T07:20:00.000Z
---

## Current Focus
verifying: Does pg_database_url.rb extract POSTGRES_DATABASE from DATABASE_URL? Is there a mismatch between docker compose run vs docker compose up?

## Key Question
- Does `pg_database_url.rb` extract and export `POSTGRES_DATABASE` from `DATABASE_URL`? (Look at line 7)
- If not, what database does Rails default to when `POSTGRES_DATABASE` is not set?
- Is there a mismatch between the database used by `docker compose run` vs `docker compose up`?

## Evidence

### Evidence 1: pg_database_url.rb (line 7)
- timestamp: 2026-04-12
- checked: docker/entrypoints/helpers/pg_database_url.rb line 7
- found: Line 7 is: `puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user}"`
- implication: ONLY extracts POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USERNAME. The database name (uri.path) is NOT extracted or exported. Line 7 completely ignores the database name portion of the URI.

### Evidence 2: .env file POSTGRES settings
- timestamp: 2026-04-12
- checked: .env lines 62-68
- found: POSTGRES_HOST=postgres, POSTGRES_USERNAME=postgres, POSTGRES_PASSWORD=postgres. POSTGRES_DATABASE is commented out (line 65 has # POSTGRES_DATABASE=)
- implication: POSTGRES_DATABASE is NOT set in .env

### Evidence 3: database.yml default fallback
- timestamp: 2026-04-12
- checked: config/database.yml development section line 17
- found: `database: "<%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_dev') %>"`
- implication: When POSTGRES_DATABASE is not set, Rails defaults to 'chatwoot_dev', NOT 'chatwoot'

### Evidence 4: docker-compose.yaml rails service environment
- timestamp: 2026-04-12
- checked: docker-compose.yaml lines 43-49 (rails service)
- found: The rails service has `environment:` block with explicit `POSTGRES_DATABASE=chatwoot` (line 49). This takes precedence over env_file values.
- implication: When using `docker compose up`, the rails service has POSTGRES_DATABASE=chatwoot set explicitly in its environment block.

### Evidence 5: pg_database_url.rb execution path
- timestamp: 2026-04-12
- checked: pg_database_url.rb lines 5-10
- found: The if condition on line 5 checks `!ENV['DATABASE_URL'].nil? && ENV['DATABASE_URL'] != ''`. If DATABASE_URL is NOT set (common for local dev), the script only exports POSTGRES_PORT as fallback (line 9).
- implication: When DATABASE_URL is not set, pg_database_url.rb does NOT export POSTGRES_HOST or POSTGRES_USERNAME. These remain set from .env via env_file directive.

### Evidence 6: postgres service initialization
- timestamp: 2026-04-12
- checked: docker-compose.yaml lines 93-103 (postgres service)
- found: The postgres service uses `POSTGRES_DB=chatwoot` (line 101) which initializes the database as 'chatwoot'
- implication: Docker postgres service creates database named 'chatwoot'

### Evidence 7: Entry script wait logic
- timestamp: 2026-04-12
- checked: docker/entrypoints/rails.sh lines 12-13
- found: Entry script runs `$(docker/entrypoints/helpers/pg_database_url.rb)` which may export POSTGRES_HOST, then uses those exported variables for `pg_isready` check.
- implication: The pg_isready check uses whatever POSTGRES_HOST is exported by pg_database_url.rb

## Resolution

root_cause: |
  **CONFIRMED: There is a mismatch, but it is the OPPOSITE of the stated hypothesis.**

  The hypothesis claimed `docker compose run --rm rails` uses POSTGRES_HOST=localhost from .env connecting to host's local PostgreSQL, while `docker compose up` uses Docker's postgres service.

  Reality:
  1. `pg_database_url.rb` line 7 does NOT extract POSTGRES_DATABASE from DATABASE_URL - it only exports POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USERNAME from the URI.

  2. When `docker compose up` runs the rails service:
     - The `environment:` block in docker-compose.yaml sets `POSTGRES_DATABASE=chatwoot` (line 49)
     - The postgres service was initialized with `POSTGRES_DB=chatwoot` (line 101)
     - **Correct: Rails connects to 'chatwoot' database**

  3. When `docker compose run --rm rails bundle exec rails db:chatwoot_prepare` runs:
     - The entrypoint script (`rails.sh`) runs `pg_database_url.rb` at line 12
     - Since .env does NOT have DATABASE_URL set, pg_database_url.rb only exports POSTGRES_PORT=5432 as fallback
     - The .env has POSTGRES_HOST=postgres, so pg_isready connects to Docker's postgres service correctly
     - **BUT:** POSTGRES_DATABASE is NOT set in .env (commented out), so Rails falls back to 'chatwoot_dev' per database.yml

  4. **The actual mismatch:** `docker compose run` (via entrypoint.sh) results in Rails connecting to 'chatwoot_dev' (the fallback default), while `docker compose up` (with explicit POSTGRES_DATABASE=chatwoot) connects to 'chatwoot'. Two different databases!

  5. Additional finding: Even if DATABASE_URL were set with a database name, `pg_database_url.rb` line 7 does NOT extract or export it - the database name portion of the URI would be silently ignored.

fix: |
  1. pg_database_url.rb should also extract and export the database name from DATABASE_URL:
     - Change line 7 from: `puts "export POSTGRES_HOST=#{uri.host}..."`
     - To: `puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user} POSTGRES_DATABASE=#{uri.path[1..]}"`

  2. Alternatively (or additionally): Set POSTGRES_DATABASE in .env explicitly to match the Docker postgres service initialization:
     - Add/change in .env: `POSTGRES_DATABASE=chatwoot`

verification: |
  - pg_database_url.rb line 7 confirmed: Only exports HOST, PORT, USERNAME - no DATABASE
  - database.yml line 17 confirmed: Falls back to 'chatwoot_dev' when POSTGRES_DATABASE unset
  - docker-compose.yaml line 49 confirmed: rails service has explicit POSTGRES_DATABASE=chatwoot
  - .env line 65 confirmed: POSTGRES_DATABASE is commented out
  - postgres service line 101 confirmed: Creates 'chatwoot' database

files_changed: []

## Summary Finding

**Root Cause:** `pg_database_url.rb` line 7 does NOT extract `POSTGRES_DATABASE` from `DATABASE_URL`. It only exports `POSTGRES_HOST`, `POSTGRES_PORT`, and `POSTGRES_USERNAME`. The database name portion of any DATABASE_URL would be silently ignored.

**Actual Mismatch:**
- `docker compose up` with explicit `POSTGRES_DATABASE=chatwoot` in rails service environment block -> connects to 'chatwoot'
- `docker compose run --rm rails bundle exec rails db:chatwoot_prepare` via entrypoint -> Rails falls back to 'chatwoot_dev' (per database.yml fallback since POSTGRES_DATABASE is unset in .env)

**Fix options:**
1. Modify pg_database_url.rb line 7 to also extract POSTGRES_DATABASE from uri.path
2. Set POSTGRES_DATABASE=chatwoot explicitly in .env
