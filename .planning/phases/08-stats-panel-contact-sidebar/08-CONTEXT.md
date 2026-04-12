# Phase 8: Stats Panel & Contact Sidebar - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a stats panel at the top of the CRM dashboard and a pipeline stage selector in the contact detail sidebar. The stats panel shows per-stage contact counts, total contacts, and contacts added today (from `pipeline_stats` API). The sidebar shows contact details with a stage dropdown that lets users reassign contacts without drag-drop.

</domain>

<decisions>
## Implementation Decisions

### Stats panel layout — D-01
- **Decision:** Stat cards in a horizontal row — one card per stage (showing count), plus "Total" and "Added Today" summary cards
- **Rationale:** Per ROADMAP.md Phase 8 item 1; card-based stats match Chatwoot's existing dashboard widget patterns; each stage gets its own card showing name, color dot, and count; summary cards show aggregate metrics; cards are clickable to filter the Kanban/list to that stage
- **[auto] Selected: Card-per-stage + Total + Added Today summary cards in horizontal row**

### Stats panel position — D-02
- **Decision:** Stats panel sits between the header row and the Kanban/list view, full width
- **Rationale:** Standard dashboard pattern — summary at top, detail below; doesn't compete with the Kanban header controls
- **[auto] Selected: Between header and Kanban/list view**

### Sidebar scope — D-03
- **Decision:** Minimal sidebar — shows contact name, email/phone, current stage dropdown, and last activity; NOT a full contact edit form
- **Rationale:** Phase 8's goal is stage reassignment, not full contact editing; keep sidebar focused and fast; full contact editing stays in the main Contacts section
- **[auto] Selected: Minimal sidebar with stage dropdown + basic contact info**

### Sidebar open trigger — D-04
- **Decision:** Clicking a contact card (Kanban) or row (list) opens the sidebar; clicking overlay or close button closes it
- **Rationale:** Phase 7 row click is wired to `handleRowClick`; Phase 8 wires this to open sidebar; consistent with Chatwoot conversation sidebar patterns
- **[auto] Selected: Click contact opens sidebar, overlay/close dismisses**

### Sidebar stage selector presentation — D-05
- **Decision:** Dropdown at the top of the sidebar listing all stages + "Unassigned" option; current stage shown with color indicator
- **Rationale:** Phase 8 ROADMAP.md item 2 — "dropdown listing all available stages (plus an unassigned option)"; compact and discoverable; standard Chatwoot dropdown pattern
- **[auto] Selected: Dropdown with stage options + Unassigned, current stage highlighted**

### Stage update behavior — D-06
- **Decision:** Dropdown change is optimistic — sidebar shows new stage immediately, API call persists the change; on failure, revert dropdown + show toast error
- **Rationale:** Consistent with Phase 5 drag-drop optimistic update pattern; immediate feedback feels responsive
- **[auto] Selected: Optimistic update with revert + toast on failure**

### Sidebar data loading — D-07
- **Decision:** Sidebar renders basic contact info (name, email, phone) immediately from the in-memory contact object already loaded in LeadsIndex; stage dropdown populates from `pipelineStore.stages`
- **Rationale:** Contacts are already loaded in memory (LeadsIndex fetches all contacts on mount); no additional API call needed just to show sidebar; avoids latency for a quick stage change
- **[auto] Selected: No extra API call — use in-memory contact + pipelineStore stages**

### Kanban/list sync after stage change — D-08
- **Decision:** After sidebar stage update, the `pipelineStore.moveContactToStage` action updates local state, causing Kanban/list to re-render immediately
- **Rationale:** Consistent with Phase 5 Kanban drag-drop sync mechanism; no manual refresh needed
- **[auto] Selected: Store-level reactive update, no page reload**

### Loading skeleton for stats — D-09
- **Decision:** Stats panel shows skeleton cards (matching the stat card shape) while `pipelineStore.fetchStats()` is in progress
- **Rationale:** Consistent with Kanban board loading skeleton pattern established in Phase 5
- **[auto] Selected: Skeleton cards while loading**

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 7 Context (List View)
- `.planning/phases/07-list-view-view-toggle/07-CONTEXT.md` — LeadsIndex.vue with view toggle, list table, stage filter, and `handleRowClick` stub for Phase 8 sidebar
- `.planning/phases/07-list-view-view-toggle/07-UI-SPEC.md` — UI design contract (if exists)

### Phase 6 Context (Stage Management)
- `.planning/phases/06-stage-management-admin-ui/06-CONTEXT.md` — StageManagementModal.vue, Dialog pattern

### Phase 5 Context (Kanban Board)
- `.planning/phases/05-kanban-board-drag-drop/05-CONTEXT.md` — KanbanCard, StageColumn, KanbanBoard, optimistic update pattern, `handleCardClick` stub for Phase 8
- `.planning/phases/05-kanban-board-drag-drop/05-02-SUMMARY.md` — Kanban implementation details

### Phase 4 Context (Frontend Infrastructure)
- `.planning/phases/04-frontend-infrastructure/04-CONTEXT.md` — usePipelineStore with `fetchStats()`, stats state, leadsIndex.vue stub

### Phase 3 Context (Stats API)
- `.planning/phases/03-stats-api/03-CONTEXT.md` — Stats response shape: `[{stage_id, name, count, added_today}]`

### Chatwoot Frontend Patterns
- `app/javascript/dashboard/stores/pipeline.js` — `usePipelineStore` with `fetchStats()`, `stages`, `stats`, `moveContactToStage()`
- `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue` — Phase 5/7 leads page; `handleCardClick` and `handleRowClick` stubs for Phase 8
- `app/javascript/dashboard/components/kanban/KanbanBoard.vue` — Phase 5 Kanban board; emits `card-click` event
- `app/javascript/dashboard/components-next/dropdown-menu/DropdownMenu.vue` — Existing dropdown for stage filter
- `app/javascript/dashboard/components-next/Contacts/ContactsDetailsLayout.vue` — Sidebar slot pattern for contact details
- `app/javascript/dashboard/composables/useAlert.js` — Toast notifications for optimistic update failures
- `app/javascript/dashboard/composables/store.js` — Vuex store access for contacts

### Backend
- `app/controllers/api/v1/accounts/pipeline_stages_controller.rb` — Stage CRUD API
- `app/models/contact.rb` — Contact with `pipeline_stage_id` and update action

### No external specs — requirements fully captured in decisions above

</canonical_refs>

<codebase_context>
## Existing Code Insights

### Reusable Assets
- `usePipelineStore.fetchStats()`: Already returns `[{stage_id, name, count, added_today}]` — stats panel consumes this directly
- `usePipelineStore.stages`: Already has all stages — sidebar dropdown populates from this
- `usePipelineStore.moveContactToStage()`: Already handles optimistic update + revert + toast — sidebar stage change reuses this
- `DropdownMenu.vue`: Existing component for dropdown menus — reused for stage filter (Phase 7) and can be reused for sidebar dropdown
- `ContactsDetailsLayout.vue` sidebar slot: Desktop sidebar slot pattern with mobile overlay transition

### Established Patterns (from prior phases)
- Optimistic updates with revert + `useAlert` toast on failure (Phase 5 Kanban drag-drop, Phase 6 stage management)
- Skeleton loaders matching component shape during data fetch (Phase 5 Kanban)
- Dialog-based forms (Phase 6 stage management)
- localStorage view preference persistence (Phase 7)

### Integration Points
- LeadsIndex.vue: Add stats panel above Kanban/list view; wire `handleCardClick` and `handleRowClick` to open sidebar
- usePipelineStore: Already has all data needed — `fetchStats()` for panel, `stages` for dropdown, `moveContactToStage()` for sidebar
- KanbanBoard: Emits `card-click` event with contact — Phase 8 wires this to open sidebar
- Contacts in memory: `contactsMap` in LeadsIndex already has all loaded contacts — sidebar reads from this, no extra API call

</codebase_context>

<specifics>
## Specific Ideas

No specific user references beyond ROADMAP.md Phase 8 success criteria.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 08-stats-panel-contact-sidebar*
*Context gathered: 2026-04-12*
*[auto] All gray areas auto-resolved with recommended defaults per ROADMAP.md specifications and established Chatwoot frontend patterns*
