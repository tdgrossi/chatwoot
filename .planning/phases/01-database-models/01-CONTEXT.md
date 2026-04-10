# Phase 1: Database & Models - Context

**Gathered:** 2026-04-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Contacts gain an optional `pipeline_stage_id` field; accounts auto-create one default "New" stage on creation via `after_create` callback. This is the foundation layer for the CRM pipeline — models, associations, and seed data.
</domain>

<decisions>
## Implementation Decisions

### Pipeline model — D-01
- **Decision:** No separate `Pipeline` model. `PipelineStage` has `account_id` directly.
- **Rationale:** V1 uses a single pipeline per account. Adding a Pipeline model adds indirection without benefit at this stage. If multi-pipeline support is needed in v2, the model can be extracted then.

### Stage position management — D-02
- **Decision:** Use `acts_as_list` gem for position management.
- **Rationale:** Standard Rails approach for ordered lists. Uses a `position` integer column with efficient DB swaps. Wisper is already in the Gemfile for event publishing when stages change.

### Color format — D-03
- **Decision:** Stage colors stored as hex strings (e.g., '#FF5733').
- **Rationale:** Simple and flexible. Works with existing color picker patterns in Chatwoot.

### Migrations — D-04
- **Decision:** No migration creation in this phase (user says not required).
- **Rationale:** User indicates migrations are not needed for Phase 1 scope.

### Data backfill — D-05
- **Decision:** Existing accounts without a pipeline will be handled separately.
- **Rationale:** Per ROADMAP.md success criteria item 5 — data migration for existing accounts.

### Contact association — D-06
- **Decision:** `Contact belongs_to :pipeline_stage, optional: true`
- **Rationale:** Nullable FK — untyped contacts continue working in all existing Chatwoot flows. No breaking change.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### CRM Pipeline Stack
- `.planning/research/STACK.md` — Full tech stack analysis; confirms acts_as_list, wisper, vuedraggable usage patterns; position integer column + acts_as_list for ordered stages; chatwoot model conventions (account-scoped, nullable FK)

### Chatwoot Model Conventions
- `app/models/contact.rb` — Confirmed `belongs_to :account` pattern; multi-tenant approach; after_create callback pattern used for ip_lookup
- `app/models/account.rb` — Confirmed after_create callback pattern

### No external specs — requirements fully captured in decisions above
</canonical_refs>

<codebase_context>
## Existing Code Insights

### Reusable Assets
- `Contact` model: Already has `belongs_to :account`, `after_create` callback pattern. Adding `belongs_to :pipeline_stage, optional: true` follows the same pattern.
- `Account` model: `after_create` callback already used for similar seed operations.

### Established Patterns
- Account-scoped models (e.g., `Label`, `Team`, `Inbox`): `belongs_to :account`, no separate tenant model
- Position integer + acts_as_list: Used by `Label`, `Inbox` for ordering
- Multi-tenant: All queries scoped to `account_id`

### Integration Points
- `Contact` model: New `belongs_to :pipeline_stage` association
- `Account` model: New `after_create` callback to seed default stage
- Database: New `pipeline_stages` table with FK on `contacts`

</codebase_context>

<specifics>
## Specific Ideas

- Default stage name: "New" (per ROADMAP.md "one 'New' stage")
- Stage position: Managed via acts_as_list (position integer column)
- Color: Hex string format for maximum flexibility

</specifics>

<deferred>
## Deferred Ideas

### Multi-pipeline support
- **Idea:** Multiple pipelines per account
- **Status:** Not in v1 scope; if needed, extract Pipeline model in v2

### Existing account data migration
- **Idea:** Data migration to create pipelines for existing accounts
- **Status:** Deferred; will be handled as a separate task after Phase 1 implementation

---

*Phase: 01-database-models*
*Context gathered: 2026-04-10*