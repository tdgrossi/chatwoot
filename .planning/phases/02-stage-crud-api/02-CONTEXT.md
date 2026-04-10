# Phase 2: Stage CRUD API - Context

**Gathered:** 2026-04-10
**Status:** Ready for planning

<domain>
## Phase Boundary

RESTful API for managing pipeline stages within an account. Provides CRUD operations (list, create, update, delete) plus a move endpoint for reordering stages by swapping positions with neighboring stages.

</domain>

<decisions>
## Implementation Decisions

### API Structure — D-01
- **Decision:** Follow existing Chatwoot API patterns exactly (`Api::V1::Accounts::BaseController`, `Current.account`, `pundit_policy_scope`)
- **Rationale:** Consistency with codebase conventions established in Phase 1 research

### Controller location — D-02
- **Decision:** `Api::V1::Accounts::PipelineStagesController`
- **Rationale:** Matches existing nested controller structure under `api/v1/accounts/`

### Authorization — D-03
- **Decision:** Admin-only access via Pundit policy (same pattern as `labels_controller.rb`)
- **Rationale:** Per ROADMAP.md success criteria: "restricted to admins via existing authorization pattern"

### Move endpoint — D-04
- **Decision:** `PATCH /api/v1/accounts/:account_id/pipeline_stages/:id/move` with `{ direction: "up" | "down" }` — swaps position with neighboring stage
- **Rationale:** Per ROADMAP.md note: "simple up/down move rather than full stage_ids array" — covers practical reordering needs without drag-to-sort dependency

### Delete behavior — D-05
- **Decision:** Before destroying a stage, nullify `pipeline_stage_id` on all affected contacts (no cascade delete)
- **Rationale:** Per ROADMAP.md success criteria: "nullifies pipeline_stage_id on affected contacts, then destroys the stage"

### Response format — D-06
- **Decision:** Full stage objects returned in list/create/update — no custom serialization needed
- **Rationale:** Standard Rails `render @stage` or `render json: @stage` pattern from existing controllers

### Position management — D-07
- **Decision:** Use `acts_as_list` methods (`move_higher`, `move_lower`) for the move endpoint
- **Rationale:** Already using `acts_as_list` for position management (Phase 1 decision); `acts_as_list` provides these methods out of the box

### Validation — D-08
- **Decision:** Name required, color optional (hex format validated)
- **Rationale:** PipelineStage model already has these validations from Phase 1

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 1 Context (Foundation)
- `.planning/phases/01-database-models/01-CONTEXT.md` — PipelineStage model already exists with `account_id`, `name`, `color`, `position`, `acts_as_list scope: :account`

### Chatwoot API Patterns
- `app/controllers/api/v1/accounts/base_controller.rb` — Base controller pattern: `Current.account`, `switch_locale_using_account_locale`
- `app/controllers/api/v1/accounts/labels_controller.rb` — CRUD template: `fetch_label`, `permitted_params`, `policy_scope`, `check_authorization`
- `app/controllers/api/v1/accounts/teams_controller.rb` — Similar CRUD template with `teams/new`, `teams.find`
- `app/models/pipeline_stage.rb` — PipelineStage model with `acts_as_list`, validations, `sorted` scope
- `app/policies/label_policy.rb` — Pundit policy example for admin-only resources

### No external specs — requirements fully captured in decisions above
</canonical_refs>

<codebase_context>
## Existing Code Insights

### Reusable Assets
- `PipelineStage` model: Already complete with `account_id`, `name`, `color`, `position`, `acts_as_list scope: :account`
- `Api::V1::Accounts::BaseController`: Provides `Current.account` and locale switching
- `labels_controller.rb`: CRUD template with authorization, params, and response patterns

### Established Patterns
- CRUD actions: `index`, `show`, `create`, `update`, `destroy` in standard order
- Fetch pattern: `fetch_resource` private method using `Current.account.resource.find(params[:id])`
- Params pattern: `params.require(:resource).permit(:attr1, :attr2)`
- Authorization: `check_authorization` before_action + Pundit policy
- Response: `render json: @resource` or `head :ok` for destroy

### Integration Points
- Route: `resources :pipeline_stages` nested under `resources :accounts` in `config/routes.rb`
- Policy: Need `PipelineStagePolicy` (or reuse/adjust LabelPolicy pattern)
- Serializer: May need `PipelineStageSerializer` for consistent JSON output (check existing serializers)

</codebase_context>

<specifics>
## Specific Ideas

- API prefix: `/api/v1/accounts/:account_id/pipeline_stages`
- Move direction: `"up"` or `"down"` only — no arbitrary position numbers
- No separate Pipeline model — stages have `account_id` directly

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

---

*Phase: 02-stage-crud-api*
*Context gathered: 2026-04-10*
*[auto] All gray areas auto-selected with recommended defaults per ROADMAP.md specifications*
