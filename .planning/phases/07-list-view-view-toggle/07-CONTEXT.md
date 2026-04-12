# Phase 7: List View & View Toggle - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a contact list as a filterable table alongside the Kanban view (Phase 5), with a toggle to switch between both views. The selected view is persisted in localStorage per user.

</domain>

<decisions>
## Implementation Decisions

### View toggle — D-01
- **Decision:** Icon button group (Kanban | List) in the header, replacing or augmenting the Manage Stages button area
- **Rationale:** Standard Chatwoot pattern — icon toggle in header toolbar; compact and discoverable; matches how other Chatwoot views switch modes

### Table component — D-02
- **Decision:** Use `dashboard/components-next/table/BaseTable.vue` as the foundation
- **Rationale:** Already in codebase (components-next); scoped slot pattern for rows and cells; consistent with Chatwoot's modern component direction

### List columns — D-03
- **Decision:** Columns: Name (contact name), Email, Phone, Stage (stage name), Last Activity, Created At
- **Rationale:** Per ROADMAP.md Phase 7 success criteria item 3

### Stage filter — D-04
- **Decision:** Dropdown filter in the header — options: "All stages", "Unassigned", then each stage name
- **Rationale:** Standard filter UX; dropdown is compact; follows existing Chatwoot filter patterns; naturally handles the "across all stages / specific stage / unassigned only" requirement

### View persistence — D-05
- **Decision:** localStorage key `crm_pipeline_view` per user for view preference
- **Rationale:** Per ROADMAP.md Phase 7 success criteria item 2; simple and sufficient

### Contact row click — D-06
- **Decision:** Clicking a contact row opens the existing contact detail sidebar
- **Rationale:** Per ROADMAP.md Phase 7 success criteria item 5; Phase 8 (contact detail sidebar) already has the stage selector

### Sort behavior — D-07
- **Decision:** Default sort by name ascending; column header click toggles sort asc/desc per column
- **Rationale:** Standard table behavior; no explicit spec so defaulting to alphabetical sort is safe and expected

### Empty state — D-08
- **Decision:** Show "No contacts match your filters" when stage filter returns empty, distinct from "No contacts yet" initial state
- **Rationale:** Distinguishing filtered-empty from truly-empty helps users understand their filter

### Claude's Discretion
The specific loading skeleton design for the list view (column vs. row skeletons) is delegated to the planner — use the same skeleton style as the Kanban board loading state for consistency.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 5 Context (Kanban Board)
- `.planning/phases/05-kanban-board-drag-drop/05-02-SUMMARY.md` — Kanban board implementation, data loading, optimistic updates
- `.planning/phases/05-kanban-board-drag-drop/05-CONTEXT.md` — Kanban UI patterns

### Phase 6 Context (Stage Management)
- `.planning/phases/06-stage-management-admin-ui/06-CONTEXT.md` — All decisions D-01 through D-09
- `.planning/phases/06-stage-management-admin-ui/06-UI-SPEC.md` — UI design contract

### Chatwoot Frontend Patterns
- `app/javascript/dashboard/components-next/table/BaseTable.vue` — Table component to use for list view
- `app/javascript/dashboard/components-next/button/Button.vue` — Icon buttons for view toggle
- `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue` — Where toggle and list view get added
- `app/javascript/dashboard/stores/pipeline.js` — usePipelineStore with stages, stats, CRUD actions
- `app/javascript/dashboard/composables/useAdmin.js` — isAdmin check for any admin-gated features
- `app/javascript/dashboard/components/kanban/KanbanBoard.vue` — Existing Kanban board to coexist with list view

### Phase 2 Backend
- `app/controllers/api/v1/accounts/pipeline_stages_controller.rb` — Stage CRUD API
- `app/models/pipeline_stage.rb` — Stage model with position, color, name

### No external specs — requirements fully captured in decisions above

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BaseTable.vue` (components-next/table/): Scoped slot table — headers, items, named slots for row/cell rendering
- `Button.vue` (components-next): Icon-only button variant for toggle
- `KanbanBoard.vue` (dashboard/components/kanban/): Phase 5 Kanban board — currently the only view in LeadsIndex
- `usePipelineStore`: Already has `stages`, `fetchStages()`, and contact-grouped data

### Established Patterns (from prior phases)
- Optimistic updates with revert + `useAlert` toast on failure (Phase 5, Phase 6)
- Dialog-based forms (Phase 6)
- `useAdmin()` for admin-only features (Phase 6)
- Card component for contact display (Phase 5)

### Integration Points
- LeadsIndex.vue: Add view toggle + list view alongside existing Kanban board
- usePipelineStore: Existing stages state; list view needs filtered contact fetch
- Contact detail: Phase 8 sidebar will add stage selector — list view row click opens same sidebar
- localStorage: View preference persistence

</code_context>

<specifics>
## Specific Ideas

No specific user references beyond ROADMAP.md success criteria. Standard table-with-filter patterns apply.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-list-view-view-toggle*
*Context gathered: 2026-04-12*
*[auto] All gray areas auto-resolved with recommended defaults per codebase patterns and ROADMAP.md specifications*
