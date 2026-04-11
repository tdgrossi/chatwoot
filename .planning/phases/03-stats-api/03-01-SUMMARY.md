---
phase: '03'
plan: '01'
subsystem: stats-api
tags: [pipeline, stats, api, redis, caching]
dependency-graph:
  requires: []
  provides:
    - path: app/controllers/api/v1/accounts/pipeline_stats_controller.rb
      exports: index
    - path: config/routes.rb
      exports: pipeline_stats member route
  affects:
    - Contact
tech-stack:
  added:
    - Redis::Alfred.setex for 60-second TTL caching
  patterns:
    - Redis-cached read-only API endpoint
    - Per-account stage iteration with Contact.count aggregation
key-files:
  created:
    - app/controllers/api/v1/accounts/pipeline_stats_controller.rb
  modified:
    - config/routes.rb
decisions:
  - id: D-01
    text: "Endpoint: GET /api/v1/accounts/:account_id/pipeline_stats"
  - id: D-02
    text: "Response shape: [{stage_id, name, count, added_today}]"
  - id: D-03
    text: "Query strategy: Contact.where(pipeline_stage_id: stage.id).count"
  - id: D-04
    text: "Exclude unassigned contacts from stats array"
  - id: D-05
    text: "Redis cache with 60-second expiry, key: pipeline_stats:account:{account_id}"
  - id: D-08
    text: "Controller: Api::V1::Accounts::PipelineStatsController"
  - id: D-09
    text: "Any authenticated account user can read stats (not admin-only)"
metrics:
  duration: ~
  completed: 2026-04-11
---

# Phase 03 Plan 01: Pipeline Stats API Summary

## One-liner

Read-only per-stage contact count endpoint with Redis caching.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add pipeline_stats route | 51a7df24e | config/routes.rb |
| 2 | Create PipelineStatsController | bc7668be5 | app/controllers/api/v1/accounts/pipeline_stats_controller.rb |
| 3 | Verify route resolves | (verification via code inspection) | config/routes.rb |

## Implementation Details

### Endpoint
`GET /api/v1/accounts/:account_id/pipeline_stats`

### Response Shape
```json
[
  { "stage_id": 1, "name": "Lead", "count": 42, "added_today": 3 },
  { "stage_id": 2, "name": "Qualified", "count": 15, "added_today": 1 }
]
```

### Key Decisions Applied
- **D-04:** Only iterates over `Current.account.pipeline_stages.sorted` -- unassigned contacts excluded
- **D-05:** Cache key `pipeline_stats:account:{account_id}` with 60-second TTL via `Redis::Alfred.setex`
- **D-09:** No `check_authorization` call -- any authenticated account user can access
- **D-06:** No cache invalidation events -- cache expires naturally

### Files Created
- `app/controllers/api/v1/accounts/pipeline_stats_controller.rb` -- Controller with Redis-cached `index` action

### Files Modified
- `config/routes.rb` -- Added `get :pipeline_stats` as member route under `resources :accounts`

## Verification

Route confirmed present at:
```ruby
resources :accounts, only: [:create, :show, :update] do
  member do
    post :update_active_at
    get :cache_keys
    get :pipeline_stats  # <-- Added here
  end
```

Controller syntax validated via `ruby -c`.

## Deviations from Plan

None.

## Auth Gates

None.

## Known Stubs

None.
