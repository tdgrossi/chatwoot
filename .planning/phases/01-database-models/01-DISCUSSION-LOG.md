# Phase 1: Database & Models - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-10
**Phase:** 1-database-models
**Areas discussed:** Pipeline model decision, Stage position management, Migration approach, Color format

---

## Pipeline Model Decision

| Option | Description | Selected |
|--------|-------------|----------|
| Separate Pipeline model | Pipeline is a separate model. Stages belong_to pipeline. Cleaner for future multi-pipeline support but adds indirection. | |
| No Pipeline model (stages on account) | No Pipeline model. PipelineStage has account_id directly. Simpler for v1 since we only need one pipeline per account. | ✓ |

**User's choice:** No Pipeline model (stages on account)
**Notes:** User selected simpler approach for v1.

---

## Stage Position Management

| Option | Description | Selected |
|--------|-------------|----------|
| Use acts_as_list gem | Use acts_as_list gem. Standard approach for ordered lists. Uses a position integer column with efficient DB swaps. | ✓ |
| Manual position handling | Manual position management with custom logic. No new gem dependency. | |

**User's choice:** Use acts_as_list gem (Recommended)
**Notes:** Standard approach; Wisper already in Gemfile.

---

## Migration Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Rails generator + manual data migration | Use rails generate migration for schema migrations. Write raw SQL for data migrations (backfill existing accounts). | |
| Fully manual migrations | All migrations written manually. Full control over timing and implementation details. | |
| No migration required | No migration required | ✓ |

**User's choice:** No migration required
**Notes:** User indicated no migrations are needed for Phase 1 scope.

---

## Color Format

| Option | Description | Selected |
|--------|-------------|----------|
| Hex string (e.g., '#FF5733') | Store hex strings like '#FF5733'. Simple, flexible, works with existing color picker in Chatwoot. | ✓ |
| Named palette values | Store predefined color names/keys from a config. More constrained but ensures consistency. | |

**User's choice:** Hex string (e.g., '#FF5733') (Recommended)
**Notes:** Simple and flexible.

---

## Deferred Ideas

- **Multi-pipeline support** — deferred to v2 (if needed, extract Pipeline model)
- **Existing account data migration** — deferred as separate task after Phase 1