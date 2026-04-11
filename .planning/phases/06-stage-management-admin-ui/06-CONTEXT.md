# Phase 6: Stage Management Admin UI - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

In-app admin interface for creating, editing, deleting, and reordering pipeline stages. Accessible only to admins, triggered from the CRM dashboard header. Phase 6 delivers the CRUD UI that Phase 2's API enables. Phase 7 (List View) and Phase 8 (Stats Panel) build on top.

</domain>

<decisions>
## Implementation Decisions

### Manage Stages entry point — D-01
- **Decision:** "Manage Stages" button in CRM dashboard header, visible to admins only
- **Rationale:** ROADMAP.md success criteria item 1 — "Manage Stages button in CRM dashboard header"; naturally admin-only via existing Chatwoot authorization pattern
- **[auto] Selected: Admin-only button in leads page header**

### Stage editor UI — D-02
- **Decision:** Dialog-based editing — click a stage row to open an edit dialog with name and color
- **Rationale:** Simpler implementation than inline editing; keeps UI predictable; modal pattern is established in Chatwoot; enables use of ColorPicker component-next
- **[auto] Selected: Dialog-based stage editor**

### Stage list display — D-03
- **Decision:** Vertical list (card-style rows) showing stage name, color indicator, and action buttons
- **Rationale:** Standard pattern for stage management UIs; up/down buttons per row per ROADMAP.md item 4; visually similar to existing Chatwoot settings lists
- **[auto] Selected: Vertical card-style list with action buttons**

### Create stage form — D-04
- **Decision:** "Add new stage" button at top of list opens create dialog with name field and color picker
- **Rationale:** Creates new stage via POST API (Phase 2); name + color picker are the only required fields; appended to end via position
- **[auto] Selected: Dialog form at top of list with name + color picker**

### Delete confirmation — D-05
- **Decision:** Confirmation dialog warns that contacts will be moved to unassigned; no type-to-confirm needed
- **Rationale:** Per ROADMAP.md item 4 — "Delete shows confirmation dialog; contacts are moved to unassigned on confirm"; simple confirmation is sufficient for this use case
- **[auto] Selected: Simple confirmation dialog (not type-to-confirm)**

### Color picker component — D-06
- **Decision:** Use `dashboard/components-next/colorpicker/ColorPicker.vue` with Chrome picker
- **Rationale:** Modern Vue 3 component already in codebase; `@lk77/vue3-color` dependency already present; Phase 2 stage model stores hex colors
- **[auto] Selected: components-next ColorPicker with Chrome picker**

### Reorder UX — D-07
- **Decision:** Up/Down buttons on each row (not drag-drop); uses the Phase 2 move API (`move` action)
- **Rationale:** Per ROADMAP.md item 5 — "Up/Down buttons on each row reorder stages via the move API endpoint"; Phase 2 plan note already specified this; keeps the admin UI simple and predictable
- **[auto] Selected: Up/Down buttons per row via move API**

### Optimistic UI updates — D-08
- **Decision:** Stage actions (create, edit, delete, reorder) update UI immediately via store; revert on API failure with toast
- **Rationale:** Consistent with Phase 5 optimistic update pattern; creates a responsive feel; follows same revert-on-failure approach
- **[auto] Selected: Optimistic updates with revert + toast on failure**

### Admin authorization — D-09
- **Decision:** Show/hide Manage Stages button based on Chatwoot's existing admin role check
- **Rationale:** Per ROADMAP.md item 1 — "visible to admins only"; use existing `useStore().vuexModules` authorization pattern or `role` from store state
- **[auto] Selected: Admin role check via useStore or existing auth pattern**

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 2 Context (Stage CRUD API)
- `.planning/phases/02-stage-crud-api/02-CONTEXT.md` — Stage model with `position`, color, CRUD API endpoints, move endpoint

### Phase 4 Context (Frontend Infrastructure)
- `.planning/phases/04-frontend-infrastructure/04-CONTEXT.md` — usePipelineStore, leadsIndex.vue, API client pattern

### Phase 5 Context (Kanban Board)
- `.planning/phases/05-kanban-board-drag-drop/05-CONTEXT.md` — Kanban UI patterns, optimistic update pattern, toast error handling

### Chatwoot Frontend Patterns
- `app/javascript/dashboard/components/Modal.vue` — Base modal component (Vue 3 Composition API)
- `app/javascript/dashboard/components/ModalHeader.vue` — Modal header component
- `app/javascript/dashboard/components/widgets/modal/ConfirmDeleteModal.vue` — Delete confirmation modal (legacy, for reference)
- `app/javascript/dashboard/components-next/colorpicker/ColorPicker.vue` — Modern ColorPicker with Chrome picker, `modelValue` prop, `update:modelValue` emit
- `app/javascript/dashboard/stores/pipeline.js` — usePipelineStore with stages state and CRUD actions
- `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue` — CRM dashboard page where "Manage Stages" button will be added

### Phase 2 Backend
- `app/controllers/api/v1/accounts/pipeline_stages_controller.rb` — CRUD + move endpoints
- `app/models/pipeline_stage.rb` — Stage model with position, color, name

### No external specs — requirements fully captured in decisions above

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Modal.vue` (components-next): Base modal with backdrop click, escape key, teleport-to-body pattern
- `ModalHeader.vue`: Header with title and close button for modals
- `ColorPicker.vue` (components-next): Chrome color picker with `modelValue`/`update:modelValue` v-model support
- `usePipelineStore`: Has `stages`, `fetchStages()`, `createStage()`, `updateStage()`, `deleteStage()`, `moveStage()` actions

### Established Patterns
- Dialog-based CRUD: Chatwoot settings typically use modal dialogs for create/edit forms
- Up/Down buttons: Phase 2 plan note explicitly uses "up/down buttons" — this is already decided
- Toast errors: `useAlert()` composable for error notifications
- Optimistic updates: Phase 5 established this pattern for stage moves

### Integration Points
- Leads page header: "Manage Stages" button added to `LeadsIndex.vue` header area
- Store actions: usePipelineStore CRUD actions for all stage operations
- Phase 2 API: All endpoints already exist — this phase is purely UI

</code_context>

<specifics>
## Specific Ideas

No specific user references beyond ROADMAP.md success criteria. Standard admin UI patterns apply.

</specifics>

<deferred>
## Deferred Ideas

### Drag-drop stage reorder
- **Idea:** Full drag-drop reorder for stages in admin UI
- **Status:** Not in Phase 6 scope per ROADMAP.md item 5 — "Up/Down buttons on each row"; if users request it, add as future enhancement

### Stage analytics in admin
- **Idea:** Show contact count per stage directly in the admin list
- **Status:** Not required in Phase 6; stats are shown in Phase 8 stats panel; could be added to admin list as enhancement

### Bulk stage creation
- **Idea:** Create multiple stages at once (e.g., template stages)
- **Status:** Out of scope for v1; manual creation is sufficient for initial pipeline setup

---

*Phase: 06-stage-management-admin-ui*
*Context gathered: 2026-04-11*
*[auto] All gray areas auto-resolved with recommended defaults per ROADMAP.md specifications, Phase 2 API structure, and established Chatwoot admin UI patterns*
