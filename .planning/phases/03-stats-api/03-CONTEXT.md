# Phase 3: Stats API - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Read-only API endpoint returning per-stage contact counts (`stage_id`, `name`, `count`, `added_today`) for the CRM dashboard. Downstream consumer is Phase 8 Stats Panel.

</domain>

<decisions>
## Implementation Decisions

### Endpoint — D-01
- **Decision:** `GET /api/v1/accounts/:account_id/pipeline_stats` — one endpoint returns all stage stats
- **Rationale:** Single round-trip; dashboard needs all counts at once

### Response shape — D-02
- **Decision:** Array of objects: `[{ stage_id, name, count, added_today }]`
- **Rationale:** Per ROADMAP.md success criteria — `stage_id`, `name`, `count`, `added_today`

### Query strategy — D-03
- **Decision:** `Contact.by_pipeline_stage(stage).count` with index on `pipeline_stage_id` — simple and correct; optimize with counter cache if profiling shows it's needed
- **Rationale:** No premature optimization; `pipeline_stage_id` has an index from Phase 1; counter cache adds complexity

### Unassigned bucket — D-04
- **Decision:** Exclude unassigned from the stats array (handled separately in Phase 8/5 UI)
- **Rationale:** ROADMAP.md success criteria lists specific fields — `added_today` doesn't apply to NULL stage; unassigned shown as distinct UI element in Phase 5

### Caching — D-05
- **Decision:** Redis cache with 60-second expiry; invalidate on stage CRUD operations
- **Rationale:** Dashboard polls stats; Chatwoot already uses Redis heavily; 200ms SLA is achievable with short-lived cache

### Wisper / Event integration — D-06
- **Decision:** No Wisper event for stats invalidation — cache expires naturally at 60s
- **Rationale:** Avoids extra complexity; Phase 8 Stats Panel can poll at reasonable intervals

### Performance SLA — D-07
- **Decision:** Target 200ms for up to 10,000 contacts — achieved via indexed queries + short-lived Redis cache
- **Rationale:** Per ROADMAP.md success criteria; Chatwoot's existing `contacts` table will have the index

### Controller location — D-08
- **Decision:** `Api::V1::Accounts::PipelineStatsController` — follows existing Chatwoot controller pattern
- **Rationale:** Consistent with `PipelineStagesController` from Phase 2

### Authorization — D-09
- **Decision:** Any authenticated account user can read stats (not admin-only)
- **Rationale:** Stats are read-only aggregate data; all team members need pipeline visibility

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 1 & 2 Context (Foundation)
- `.planning/phases/01-database-models/01-CONTEXT.md` — PipelineStage model with `account_id`, `name`, `color`, `position`, `acts_as_list`
- `.planning/phases/02-stage-crud-api/02-CONTEXT.md` — API patterns, controller location, authorization pattern

### Chatwoot API Patterns
- `app/controllers/api/v1/accounts/base_controller.rb` — Base controller: `Current.account`, `switch_locale_using_account_locale`
- `app/controllers/api/v1/accounts/labels_controller.rb` — CRUD template (Phase 2 reference)
- `app/models/contact.rb` — Contact model with existing scopes and associations
- `app/models/pipeline_stage.rb` — PipelineStage model with `sorted` scope

### No external specs — requirements fully captured in decisions above

</canonical_refs>

<codebase_context>
## Existing Code Insights

### Reusable Assets
- `PipelineStage` model: `sorted` scope orders by position
- `Contact` model: `belongs_to :pipeline_stage` from Phase 1; already has index on `pipeline_stage_id`
- Chatwoot Redis infrastructure: Already configured for caching

### Established Patterns
- API controller: Standard pattern with `Current.account` scoping
- Caching: Chatwoot uses Redis with short-lived expiry for similar endpoints
- Stats-style endpoints: Look for existing stats controllers in Chatwoot for response format

### Integration Points
- Route: `get :pipeline_stats` nested under `resources :accounts`
- Downstream: Phase 8 Stats Panel will consume this endpoint; Phase 4 store will call it

</codebase_context>

<specifics>
## Specific Ideas

- Cache key format: `pipeline_stats:account:{account_id}`
- Cache TTL: 60 seconds
- No separate serializer needed — render directly as JSON array

</specifics>

<deferred>
## Deferred Ideas

### Counter cache on PipelineStage
- **Idea:** Add `contacts_count` column to `pipeline_stages` table for O(1) lookups
- **Status:** Deferred; implement if profiling shows count queries are slow

### Wisper event for cache invalidation
- **Idea:** Publish `stage_contact_count_changed` event on Contact stage update for immediate cache bust
- **Status:** Deferred; 60s cache expiry is sufficient for v1

---

*Phase: 03-stats-api*
*Context gathered: 2026-04-11*
*[auto] All gray areas auto-selected with recommended defaults per codebase patterns and ROADMAP.md specifications*
