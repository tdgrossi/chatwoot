---
status: resolved
trigger: "Slow Docker Compose dev environment: login and page loads take minutes"
created: 2026-04-10T00:00:00Z
updated: 2026-04-10T12:10:00Z
---

## Current Focus
hypothesis: "Rack::MiniProfiler and database misconfiguration were causing multi-second delays"
test: "Measured requests before and after DISABLE_MINI_PROFILER and POSTGRES_DATABASE fixes"
expecting: "Request times should drop from 7+ seconds to under 1 second"
next_action: "Verification complete - root cause found and fixed"

## Symptoms
expected: "Page loads and logins should complete in 2-5 seconds"
actual: "Requests taking 7+ seconds initially, now under 0.5 seconds after fixes"
errors: "Rack::MiniProfiler overhead, database name mismatch (chatwoot_dev vs chatwoot)"
reproduction: "docker compose up -d then access localhost:3000"
started: "Recent changes to docker entrypoints"

## Eliminated
- hypothesis: "Bundle install running on every start"
  evidence: "Bundle check correctly skips installation when dependencies are satisfied"
  timestamp: 2026-04-10T09:58:00

## Evidence
- timestamp: 2026-04-10T09:59:00
  checked: "Rails middleware list"
  found: "Rack::MiniProfiler active in development without DISABLE_MINI_PROFILER env var"
  implication: "Profiler adds overhead to every request"

- timestamp: 2026-04-10T10:00:00
  checked: "Request timing before fix"
  found: "Requests taking 1.3-7.7 seconds, HTTP 500 due to database mismatch"
  implication: "Multiple issues causing slowness"

- timestamp: 2026-04-10T10:01:00
  checked: "DISABLE_MINI_PROFILER env var"
  found: "Var not set in docker-compose.yaml rails environment"
  implication: "MiniProfiler running and adding overhead"

- timestamp: 2026-04-10T10:02:00
  checked: "Database configuration"
  found: "POSTGRES_DATABASE not set, Rails looking for chatwoot_dev, actual DB is chatwoot"
  implication: "ActiveRecord::NoDatabaseError causing failures"

- timestamp: 2026-04-10T10:05:00
  checked: "Request timing after fixes"
  found: "Login: 0.39s, Root: 0.31s, API: 0.34s - all under 0.5s"
  implication: "Fixes working correctly"

## Resolution
root_cause: "Rack::MiniProfiler was enabled without DISABLE_MINI_PROFILER env var, adding significant overhead to every request. Also, database name mismatch (chatwoot_dev vs chatwoot) caused connection failures."
fix: "Added DISABLE_MINI_PROFILER=true and POSTGRES_DATABASE=chatwoot to rails service environment in docker-compose.yaml"
verification: "Request times dropped from 7+ seconds to 0.3-0.4 seconds"
files_changed: [docker-compose.yaml]
