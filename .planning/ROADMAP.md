# Roadmap: CRM Pipeline for Chatwoot

## Overview

This roadmap extends Chatwoot with a pipeline-first CRM layer. Contacts gain a nullable `pipeline_stage_id`, and users get a Kanban/list CRM dashboard at `/accounts/:accountId/leads`. The journey runs backend-first (models, API) through frontend infrastructure (stores, routing) to a complete shippable UI (Kanban, list, stats, stage management).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3...): Planned milestone work
- Decimal phases (e.g. 2.1): Urgent insertions (marked with INSERTED)

- [ ] **Phase 1: Database & Models** -- Contact `pipeline_stage_id` FK, Pipeline & PipelineStage models, account auto-creation
- [ ] **Phase 2: Stage CRUD API** -- RESTful API for stage management (list, create, update, delete, move up/down)
- [x] **Phase 3: Stats API** -- Per-stage contact counts endpoint (completed 2026-04-11)
- [ ] **Phase 4: Frontend Infrastructure** -- Pinia stores, API clients, `/accounts/:accountId/leads` route
- [ ] **Phase 5: Kanban Board & Drag-Drop** -- Kanban view with stage columns, draggable cards, and unassigned column
- [x] **Phase 6: Stage Management Admin UI** -- Create, edit, delete, and reorder stages in-app
- [ ] **Phase 7: List View & View Toggle** -- Table view with stage filter and toggle between views
- [ ] **Phase 8: Stats Panel & Contact Sidebar** -- Stats panel at top of dashboard, pipeline stage selector in contact sidebar

## Phase Details

### Phase 1: Database & Models
**Goal**: Contacts gain an optional pipeline stage field; accounts auto-create a default pipeline on creation
**Depends on**: Nothing (first phase)
**Requirements**: CRM-01, CRM-05
**Success Criteria** (what must be TRUE):
  1. `contacts` table has a `pipeline_stage_id` column (bigint, FK, nullable, indexed) created via migration
  2. `Contact` model has `belongs_to :pipeline_stage, optional: true` association
  3. `Contact` update action accepts `pipeline_stage_id` in permitted params
  4. New accounts auto-create a `Pipeline` with one "New" stage via `after_create` callback
  5. A data migration exists to create pipelines for existing accounts without one
**Plans**: 1 plan

Plans:
- [ ] .planning/phases/01-database-models/01-01-PLAN.md -- PipelineStage model, Contact association, Account callback, permitted params update

---

### Phase 2: Stage CRUD API
**Goal**: RESTful API for managing pipeline stages within an account
**Depends on**: Phase 1
**Requirements**: CRM-02
**Success Criteria** (what must be TRUE):
  1. `GET /api/v1/accounts/:account_id/pipeline_stages` returns all stages ordered by position
  2. `POST /api/v1/accounts/:account_id/pipeline_stages` creates a stage with name and color, appended to the end
  3. `PATCH /api/v1/accounts/:account_id/pipeline_stages/:id` updates a stage's name and color
  4. `DELETE /api/v1/accounts/:account_id/pipeline_stages/:id` nullifies `pipeline_stage_id` on affected contacts, then destroys the stage
  5. `PATCH /api/v1/accounts/:account_id/pipeline_stages/:id/move` accepts `{ direction: "up" | "down" }` and swaps position with the neighboring stage
  6. All endpoints are scoped to the account and restricted to admins via existing authorization pattern
**Plans**: 1 plan

Plans:
- [ ] .planning/phases/02-stage-crud-api/02-01-PLAN.md -- PipelineStagesController CRUD + move, PipelineStagePolicy, routes, migrations, factory, specs

> **Note**: Reorder uses a simple up/down move rather than a full `stage_ids: [...]` array endpoint. This avoids a drag-to-sort dependency in the admin UI while covering all practical reordering needs. Upgrade to full reorder if users request it.

---

### Phase 3: Stats API
**Goal**: Read-only endpoint for per-stage contact counts
**Depends on**: Phase 1
**Requirements**: CRM-03
**Success Criteria** (what must be TRUE):
  1. `GET /api/v1/accounts/:account_id/pipeline_stats` returns per-stage counts with `stage_id`, `name`, `count`, and `added_today`
  2. Response completes in under 200ms for accounts with up to 10,000 contacts
**Plans**: TBD



---

### Phase 4: Frontend Infrastructure
**Goal**: Pinia stores and routing ready for the CRM dashboard UI
**Depends on**: Phases 2 & 3
**Requirements**: (none -- infrastructure enabler)
**Success Criteria** (what must be TRUE):
  1. A `usePipelineStore` Pinia store exists with reactive state for stages, stats, and CRUD actions (fetch, create, update, delete, move)
  2. A `useContactsStore` gains a `fetchByStage(stageId)` action returning contacts filtered by pipeline stage
  3. Route `/accounts/:accountId/leads` is registered pointing to the CRM dashboard view
  4. Axios wrappers exist for all pipeline API endpoints used by the stores
  5. Stores handle loading and error states correctly
**Plans**: TBD

---

### Phase 5: Kanban Board & Drag-Drop
**Goal**: Contact pipeline visualized as a Kanban board with stage columns, draggable cards, and an unassigned column
**Depends on**: Phase 4
**Requirements**: CRM-06, CRM-07
**Success Criteria** (what must be TRUE):
  1. The CRM dashboard renders a Kanban board with one column per pipeline stage, ordered by position
  2. An "Unassigned" column appears left of the first stage column for contacts with `pipeline_stage_id = NULL`; it is visually distinct (muted styling) and shows a count badge
  3. Each column header shows the stage name and contact count
  4. Each contact card displays the contact name, avatar, and last conversation time (if any)
  5. Dragging a card to another column updates `pipeline_stage_id` via API; dragging from Unassigned assigns the contact to that stage
  6. Drag is optimistic: the card moves immediately; on API failure it reverts and shows a toast error
  7. Both mouse and touch drag inputs work
**Plans**: 2 plans

Plans:
- [ ] .planning/phases/05-kanban-board-drag-drop/05-01-PLAN.md -- Kanban UI components (KanbanCard, StageColumn, KanbanBoard)
- [ ] .planning/phases/05-kanban-board-drag-drop/05-02-PLAN.md -- Store integration, data loading, drag-drop wire-up


---

### Phase 6: Stage Management Admin UI
**Goal**: In-app admin interface for creating, editing, deleting, and reordering pipeline stages
**Depends on**: Phase 5
**Requirements**: CRM-10
**Success Criteria** (what must be TRUE):
  1. A "Manage Stages" button in the CRM dashboard header is visible to admins only
  2. Opening it shows an ordered list of all stages with inline edit capability for name and color
  3. A create form accepts a stage name and color picker, then appends the new stage via the API
  4. Delete shows a confirmation dialog; contacts are moved to unassigned on confirm
  5. Up/Down buttons on each row reorder stages via the move API endpoint
**Plans**: 1 plan

Plans:
- [ ] .planning/phases/06-stage-management-admin-ui/06-01-PLAN.md -- StageManagementModal.vue, StageFormDialog.vue, and LeadsIndex button wiring

---

### Phase 7: List View & View Toggle
**Goal**: Contact list as a filterable table alongside the Kanban view, with toggle between both views
**Depends on**: Phase 6
**Requirements**: CRM-08, CRM-09
**Success Criteria** (what must be TRUE):
  1. A toggle in the CRM dashboard header switches between Kanban and List views
  2. The selected view preference is persisted in localStorage per user
  3. The list view shows a table with columns: name, email, phone, stage, last activity, created at
  4. A stage filter dropdown allows showing contacts across all stages, a specific stage, or unassigned only
  5. Clicking a contact row opens the existing contact detail sidebar
**Plans**: TBD

---

### Phase 8: Stats Panel & Contact Sidebar
**Goal**: Stats panel at top of dashboard and pipeline stage selector in the contact detail sidebar
**Depends on**: Phase 7
**Requirements**: CRM-11, CRM-12
**Success Criteria** (what must be TRUE):
  1. A stats panel at the top of the CRM dashboard shows per-stage contact counts, total contacts, and contacts added today, using data from `pipeline_stats`
  2. The contact detail sidebar displays a "Pipeline Stage" dropdown listing all available stages (plus an unassigned option)
  3. Changing the stage dropdown updates `pipeline_stage_id` via API and reflects immediately in the Kanban board
**Plans**: TBD



---

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Database & Models | 1/1 | Complete | 2026-04-10 |
| 2. Stage CRUD API | 0/1 | Planned | - |
| 3. Stats API | 1/1 | Complete   | 2026-04-11 |
| 4. Frontend Infrastructure | 0/TBD | Not started | - |
| 5. Kanban Board & Drag-Drop | 0/2 | Planned | - |
| 6. Stage Management Admin UI | 1/1 | Complete | 2026-04-12 |
| 7. List View & View Toggle | 0/TBD | Not started | - |
| 8. Stats Panel & Contact Sidebar | 0/TBD | Not started | - |
