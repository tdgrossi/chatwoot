# Phase 3: Stats API - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 03-stats-api
**Areas discussed:** Endpoint design, Response shape, Query strategy, Caching, Unassigned handling, Performance

---

## Auto-resolution log

[auto] **Endpoint design** — Q: "Which endpoint pattern?" → Selected: `GET /api/v1/accounts/:account_id/pipeline_stats` (single endpoint returns all stage stats)

[auto] **Response shape** — Q: "What fields per stage?" → Selected: `{ stage_id, name, count, added_today }` per ROADMAP.md

[auto] **Query strategy** — Q: "How to count contacts per stage?" → Selected: `Contact.by_pipeline_stage(stage).count` with index (optimize with counter cache only if profiling shows it's needed)

[auto] **Unassigned bucket** — Q: "Include NULL stage in stats?" → Selected: Exclude unassigned (handled separately in Phase 5/8 UI)

[auto] **Caching** — Q: "Cache strategy?" → Selected: Redis cache with 60-second expiry (invalidates naturally; no Wisper event needed)

[auto] **Authorization** — Q: "Admin-only or all users?" → Selected: Any authenticated account user (stats are read-only aggregate)

[auto] **Performance SLA** — Q: "How to meet 200ms SLA?" → Selected: Indexed queries + short-lived Redis cache

---

## Claude's Discretion

All gray areas resolved via auto-selection with recommended defaults per ROADMAP.md specifications and Chatwoot codebase patterns.

