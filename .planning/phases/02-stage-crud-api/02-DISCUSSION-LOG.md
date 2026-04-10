# Phase 2: Stage CRUD API - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-10
**Phase:** 02-stage-crud-api
**Areas discussed:** Authorization, Move endpoint, Delete behavior, Response format, Position management

---

## Authorization

| Option | Description | Selected |
|--------|-------------|----------|
| Admin-only | Pundit policy restricting to admins | ✓ |
| Agents + Admins | Any account member can manage stages | |

**User's choice:** Admin-only (per ROADMAP.md specification)
**Notes:** ROADMAP.md success criteria explicitly states "restricted to admins via existing authorization pattern"

---

## Move Endpoint

| Option | Description | Selected |
|--------|-------------|----------|
| Up/Down swap | `{ direction: "up" | "down" }` — swaps with neighbor | ✓ |
| Position array | `stage_ids: [...]` full reorder | |

**User's choice:** Up/Down swap (per ROADMAP.md note)
**Notes:** ROADMAP.md note: "simple up/down move rather than full stage_ids array — avoids drag-to-sort dependency"

---

## Delete Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Nullify contacts | Set `pipeline_stage_id = NULL` on affected contacts, then destroy | ✓ |
| Cascade delete | Delete contacts when stage deleted | |
| Reassign to default | Move contacts to a default "Unassigned" stage | |

**User's choice:** Nullify contacts (per ROADMAP.md specification)
**Notes:** Per ROADMAP.md success criteria: "nullifies pipeline_stage_id on affected contacts, then destroys the stage"

---

## Response Format

| Option | Description | Selected |
|--------|-------------|----------|
| Full objects | Standard Rails `render json: @stage` | ✓ |
| Custom serializer | Dedicated PipelineStageSerializer | |

**User's choice:** Full objects (standard Rails pattern)
**Notes:** Aligns with existing controllers (labels_controller, teams_controller) — no custom serialization needed

---

## Position Management

| Option | Description | Selected |
|--------|-------------|----------|
| acts_as_list methods | `move_higher`/`move_lower` from acts_as_list gem | ✓ |
| Manual position swap | Explicit SQL UPDATE to swap positions | |

**User's choice:** acts_as_list methods (per Phase 1 decision)
**Notes:** Phase 1 already chose acts_as_list for position management — using provided methods

---

## Claude's Discretion

The following were determined by alignment with ROADMAP.md specifications rather than user discussion:
- Controller location: `Api::V1::Accounts::PipelineStagesController`
- Validation rules: Name required, color optional hex format (already in model from Phase 1)

---

## Deferred Ideas

None — all discussion stayed within phase scope as defined in ROADMAP.md
