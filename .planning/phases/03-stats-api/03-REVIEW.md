---
phase: 03-stats-api
reviewed: 2026-04-11T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - app/controllers/api/v1/accounts/pipeline_stats_controller.rb
  - config/routes.rb
findings:
  critical: 1
  warning: 0
  info: 1
  total: 2
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-11T00:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The `PipelineStatsController` implements a read-only stats endpoint with Redis caching as specified in the phase design decisions. One critical bug was found: the arguments to `Redis::Alfred.setex` are reversed, causing the cache to store an integer `60` instead of the JSON stats payload, and the expiry will be set to the JSON string (which Redis will reject or handle incorrectly).

## Critical Issues

### CR-01: Reversed arguments in Redis::Alfred.setex call

**File:** `app/controllers/api/v1/accounts/pipeline_stats_controller.rb:19`
**Issue:** The `setex` method signature is `setex(key, value, expiry)`, but the call on line 19 passes arguments in the wrong order:

```ruby
Redis::Alfred.setex(cache_key, 60, stats.to_json)
```

This stores `60` (the count integer) as the cached value and `stats.to_json` as the expiry. Redis will either reject the string-based expiry or set it to an invalid value. The cache becomes non-functional and the stats data is never cached.

**Fix:**
```ruby
Redis::Alfred.setex(cache_key, stats.to_json, 60)
```

## Info

### IN-01: N+1 query pattern in build_stats

**File:** `app/controllers/api/v1/accounts/pipeline_stats_controller.rb:23-28`
**Issue:** The `build_stats` method executes 2N+1 database queries (1 for stages, then 2 per stage for count and added_today). This is a performance concern but is out of v1 scope per the review mandate.

---

_Reviewed: 2026-04-11T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
