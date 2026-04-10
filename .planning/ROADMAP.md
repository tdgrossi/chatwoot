# Roadmap: CRM Pipeline for Chatwoot

## Overview

This roadmap extends Chatwoot with a pipeline-first CRM layer. Contacts gain a nullable `pipeline_stage_id`, and users get a Kanban/list CRM dashboard at `/dashboard/leads`. The journey runs backend-first (models, API) through frontend infrastructure (stores, routing) to a complete shippable UI (Kanban, list, stats, stage management).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 1: Database & Models** - Contact pipeline_stage FK, Pipeline & PipelineStage models, account auto-creation
- [ ] **Phase 2: Stage CRUD API** - RESTful API for stage management (list, create, update, delete, reorder)
- [ ] **Phase 3: Stats API & Events** - Volume-per-stage stats endpoint, Wisper event on stage change
- [ ] **Phase 4: Frontend Infrastructure** - Pinia stores, API clients, `/dashboard/leads` route
- [ ] **Phase 5: Kanban Board & Drag-Drop** - Kanban view with stage columns and draggable contact cards
- [ ] **Phase 6: List View & View Toggle** - Table view with stage filter and view toggle
- [ ] **Phase 7: Stage Management Admin UI** - Create, edit, delete, reorder, and color stages
- [ ] **Phase 8: Stats Display, Contact Detail & Unassigned Column** - Stats panel, contact sidebar selector, unassigned column

## Phase Details

### Phase 1: Database & Models
**Goal**: Contacts gain an optional pipeline stage field; accounts auto-create a default pipeline on creation
**Depends on**: Nothing (first phase)
**Requirements**: CRM-01, CRM-05
**Success Criteria** (what must be TRUE):
  1. `contacts` table has a `pipeline_stage_id` column (bigint, FK, nullable, indexed) created via migration
  2. `Contact` model has `belongs_to :pipeline_stage, optional: true` association
  3. `Contact.update` action accepts `pipeline_stage_id` in permitted params
  4. New Chatwoot accounts automatically get a `Pipeline` with one "New" stage created in `after_create` callback
  5. A data migration exists to create pipelines for existing accounts without one
**Plans**: TBD

### Phase 2: Stage CRUD API
**Goal**: RESTful API for managing pipeline stages within an account
**Depends on**: Phase 1
**Requirements**: CRM-02
**Success Criteria** (what must be TRUE):
  1. `GET /api/v1/accounts/:account_id/pipeline_stages` returns all stages ordered by position
  2. `POST /api/v1/accounts/:account_id/pipeline_stages` creates a stage with name and color
  3. `PATCH /api/v1/accounts/:account_id/pipeline_stages/:id` updates a stage name and color
  4. `DELETE /api/v1/accounts/:account_id/pipeline_stages/:id` deletes a stage and moves its contacts to NULL (unassigned)
  5. `PATCH /api/v1/accounts/:account_id/pipeline_stages/reorder` accepts `{ stage_ids: [...] }` and reorders stages
  6. All endpoints are authenticated via existing account scoping and gated by Pundit policy (admin only)
**Plans**: TBD

### Phase 3: Stats API & Events
**Goal**: Read-only stats endpoint and event bus for future automation hooks
**Depends on**: Phase 1
**Requirements**: CRM-03, CRM-04
**Success Criteria** (what must be TRUE):
  1. `GET /api/v1/accounts/:account_id/pipeline_stats` returns per-stage counts with `stage_id`, `count`, `added_today`, and `added_this_week`
  2. The stats response is readable in under 200ms for accounts with up to 10,000 contacts
  3. A `pipeline_stage_changed` Wisper event is published whenever a contact's stage transitions
  4. The event payload includes `contact_id`, `from_stage_id`, `to_stage_id`, `changed_at`, and `changed_by_user_id`
**Plans**: TBD

### Phase 4: Frontend Infrastructure
**Goal**: Pinia stores and routing ready for the CRM dashboard UI
**Depends on**: Phase 3
**Requirements**: (none — infrastructure enabler)
**Success Criteria** (what must be TRUE):
  1. A `usePipelineStore` Pinia store exists with reactive state for stages, stats, and CRUD actions (fetch, create, update, delete, reorder)
  2. A `useContactsStore` Pinia store exists with a `fetchContacts(stageId)` action that returns contacts filtered by pipeline stage
  3. A new route `/accounts/:accountId/dashboard/leads` is registered pointing to the CRM dashboard view
  4. API client functions (or axios wrappers) exist for all pipeline API endpoints used by the stores
  5. The stores handle loading and error states correctly
**Plans**: TBD

### Phase 5: Kanban Board & Drag-Drop
**Goal**: Contact pipeline visualized as a Kanban board with stage columns and draggable contact cards
**Depends on**: Phase 4
**Requirements**: CRM-06, CRM-07
**Success Criteria** (what must be TRUE):
  1. The CRM dashboard route renders a Kanban board with one column per pipeline stage, ordered by stage position
  2. Each column header shows the stage name and contact count
  3. Each contact card displays the contact name, avatar, and last conversation time (if any)
  4. Dragging a contact card from column A to column B updates the contact's `pipeline_stage_id` via the API
  5. Drag-and-drop uses optimistic updates: the card moves immediately in the UI; on API error it snaps back and an error snackbar appears
  6. Both mouse and touch drag inputs work
**Plans**: TBD

### Phase 6: List View & View Toggle
**Goal**: Contact list as a filterable table alongside the Kanban view, with toggle between both views
**Depends on**: Phase 5
**Requirements**: CRM-08, CRM-09
**Success Criteria** (what must be TRUE):
  1. A toggle button in the CRM dashboard header switches between Kanban and list views
  2. The selected view preference is persisted in localStorage per user
  3. The list view shows a table with columns: name, email, phone, stage, last activity, created at
  4. A stage filter dropdown allows showing contacts in a specific stage, all stages, or unassigned only
  5. Clicking a contact row in list view opens the contact detail sidebar
**Plans**: TBD

### Phase 7: Stage Management Admin UI
**Goal**: In-app admin interface for creating, editing, deleting, and reordering pipeline stages
**Depends on**: Phase 5
**Requirements**: CRM-10
**Success Criteria** (what must be TRUE):
  1. An accessible "Manage Stages" button or icon appears in the CRM dashboard header
  2. Opening it shows an ordered list of all stages with inline edit capability for name and color
  3. A create form accepts a stage name and color picker, then adds the new stage via the API
  4. Delete action shows a confirmation dialog; contacts are moved to unassigned on confirm
  5. A drag handle allows reordering stages; reorder is saved via the reorder API endpoint
  6. The stage management UI is only accessible to account admins
**Plans**: TBD

### Phase 8: Stats Display, Contact Detail & Unassigned Column
**Goal**: Stats panel, contact stage selector in sidebar, and dedicated unassigned column in Kanban
**Depends on**: Phase 6
**Requirements**: CRM-11, CRM-12, CRM-13
**Success Criteria** (what must be TRUE):
  1. A stats panel at the top of the CRM dashboard shows per-stage contact counts, total contacts, added today, and added this week using data from `pipeline_stats`
  2. The contact detail sidebar (existing Chatwoot pattern) displays a "Pipeline Stage" dropdown showing all available stages
  3. Changing the stage dropdown in the contact detail sidebar updates the contact's `pipeline_stage_id` via API
  4. The Kanban board shows an "Unassigned" column left of the first stage column for contacts with `pipeline_stage_id = NULL`
  5. The Unassigned column is visually distinct from stage columns (muted styling) and shows a count badge
  6. Contacts can be dragged from the Unassigned column into any stage column to assign them
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Database & Models | 0/TBD | Not started | - |
| 2. Stage CRUD API | 0/TBD | Not started | - |
| 3. Stats API & Events | 0/TBD | Not started | - |
| 4. Frontend Infrastructure | 0/TBD | Not started | - |
| 5. Kanban Board & Drag-Drop | 0/TBD | Not started | - |
| 6. List View & View Toggle | 0/TBD | Not started | - |
| 7. Stage Management Admin UI | 0/TBD | Not started | - |
| 8. Stats Display, Contact Detail & Unassigned Column | 0/TBD | Not started | - |
