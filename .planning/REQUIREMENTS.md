# CRM Pipeline — v1 Requirements

**Project:** CRM Pipeline for Chatwoot
**Version:** v1.0
**Last Updated:** 2026-04-10

## Requirement Traceability

| REQ-ID | Requirement | Phase | Status |
|--------|-------------|-------|--------|
| CRM-01 | Contact has optional pipeline_stage_id | 1 | — |
| CRM-02 | PipelineStagesController CRUD API | 1 | — |
| CRM-03 | Pipeline stats API endpoint | 1 | — |
| CRM-04 | Wisper event on stage change | 1 | — |
| CRM-05 | Account auto-creates pipeline on creation | 1 | — |
| CRM-06 | Kanban view grouped by stage | 3 | — |
| CRM-07 | Drag-drop contact between stages | 3 | — |
| CRM-08 | List view with stage filter | 3 | — |
| CRM-09 | View toggle (Kanban/List) | 3 | — |
| CRM-10 | Stage management admin UI | 3 | — |
| CRM-11 | Volume-per-stage statistics | 3 | — |
| CRM-12 | Contact detail stage selector | 3 | — |
| CRM-13 | Unassigned column for NULL stage | 3 | — |

---

## v1 Requirements

### CRM-01: Pipeline Stage Field on Contact
**Category:** Data Model
**Phase:** 1

Contact has an optional `pipeline_stage_id` foreign key linking to `pipeline_stages`. Null means unassigned. This field is nullable to avoid breaking existing Chatwoot flows.

**Acceptance criteria:**
- [ ] `contacts` table has `pipeline_stage_id` column (bigint, FK, nullable, indexed)
- [ ] `Contact` model has `belongs_to :pipeline_stage, optional: true`
- [ ] Existing contacts retain null stage (no data migration required)
- [ ] `ContactsController#update` accepts `pipeline_stage_id` in permitted params

---

### CRM-02: PipelineStagesController CRUD API
**Category:** API
**Phase:** 1

RESTful API for pipeline stage management scoped to accounts.

**Acceptance criteria:**
- [ ] `GET /api/v1/accounts/:account_id/pipeline_stages` — list all stages (ordered by position)
- [ ] `POST /api/v1/accounts/:account_id/pipeline_stages` — create stage (name, color)
- [ ] `PATCH /api/v1/accounts/:account_id/pipeline_stages/:id` — update stage (name, color)
- [ ] `DELETE /api/v1/accounts/:account_id/pipeline_stages/:id` — delete stage (moves contacts to NULL/unassigned)
- [ ] `PATCH /api/v1/accounts/:account_id/pipeline_stages/reorder` — reorder stages (`{ stage_ids: [...] }`)
- [ ] All endpoints authenticated via existing account scoping
- [ ] Jbuilder templates follow existing Chatwoot API conventions
- [ ] Pundit policy gates stage management (admin only)

---

### CRM-03: Pipeline Stats API
**Category:** API
**Phase:** 1

Read-only endpoint returning volume-per-stage counts.

**Acceptance criteria:**
- [ ] `GET /api/v1/accounts/:account_id/pipeline_stats` — returns `[{ stage_id, count, added_today, added_this_week }]`
- [ ] Uses SQL aggregation with index on `pipeline_stage_id`
- [ ] Response time < 200ms for accounts with up to 10k contacts

---

### CRM-04: Stage Change Event
**Category:** Events
**Phase:** 1

Publish a Wisper event when a contact's stage changes. This wires the automation engine for v2 without any automation logic in v1.

**Acceptance criteria:**
- [ ] `pipeline_stage_changed` event published via Wisper when contact stage transitions
- [ ] Event payload: `{ contact_id, from_stage_id, to_stage_id, changed_at, changed_by_user_id }`
- [ ] Event is fire-and-forget (no subscribers required for v1)

---

### CRM-05: Auto-Create Pipeline on Account Creation
**Category:** Data Model
**Phase:** 1

Every Chatwoot account automatically gets a default empty pipeline on creation.

**Acceptance criteria:**
- [ ] `Account` model has `after_create` callback that creates a `Pipeline`
- [ ] Default pipeline has one stage named "New" with default color
- [ ] Existing accounts without a pipeline get one created via a data migration
- [ ] Admin can delete or rename the default stage

---

### CRM-06: Kanban View
**Category:** UI
**Phase:** 3

Main CRM dashboard view showing contacts as cards in stage columns.

**Acceptance criteria:**
- [ ] Route: `/dashboard/leads` (or `/dashboard/crm`)
- [ ] Columns represent pipeline stages, ordered by position
- [ ] Contact cards show: name, avatar, last conversation time (if any)
- [ ] Unassigned contacts (NULL stage) appear in leftmost "Unassigned" column
- [ ] Column header shows stage name and contact count
- [ ] Columns are horizontally scrollable if stages exceed viewport

---

### CRM-07: Drag-Drop Stage Change
**Category:** UI
**Phase:** 3

Drag a contact card from one Kanban column to another to change its stage.

**Acceptance criteria:**
- [ ] Drag card from column A to column B → contact stage updates to column B's stage
- [ ] Optimistic update: card moves immediately in UI
- [ ] On API error: card snaps back, error snackbar shown
- [ ] Uses vuedraggable (already in package.json)
- [ ] Works with both mouse and touch input

---

### CRM-08: List View with Stage Filter
**Category:** UI
**Phase:** 3

Table view of contacts with stage as a filter dimension.

**Acceptance criteria:**
- [ ] Same route as Kanban, toggle between views
- [ ] Table columns: name, email, phone, stage, last activity, created at
- [ ] Stage filter: dropdown to show only contacts in a specific stage, or "All", or "Unassigned"
- [ ] Clicking a contact row opens contact detail sidebar
- [ ] Uses @tanstack/vue-table (already in package.json)

---

### CRM-09: View Toggle
**Category:** UI
**Phase:** 3

Toggle button in the CRM dashboard header to switch between Kanban and List views.

**Acceptance criteria:**
- [ ] Toggle button in dashboard header (icon: kanban board / list)
- [ ] Selected view persisted in localStorage per user
- [ ] Both views share the same data (stages + contacts filtered by stage)

---

### CRM-10: Stage Management Admin UI
**Category:** UI
**Phase:** 3

Admin interface to create, edit, reorder, and delete pipeline stages.

**Acceptance criteria:**
- [ ] Accessible from CRM dashboard header (settings icon or "Manage Stages")
- [ ] Opens a drawer/modal with stage list (ordered)
- [ ] Create: name input + color picker, add button
- [ ] Edit: inline edit of name and color
- [ ] Delete: confirmation, contacts moved to unassigned
- [ ] Reorder: drag handle to reorder stages
- [ ] Admin-only (gated by existing account role check)

---

### CRM-11: Volume-Per-Stage Statistics
**Category:** UI
**Phase:** 3

Stat cards or bar chart showing contact count per stage.

**Acceptance criteria:**
- [ ] Displayed at top of CRM dashboard
- [ ] Shows: per-stage count, total contacts, added today, added this week
- [ ] Simple stat cards (number + stage color) — no complex charts in v1
- [ ] Data from `GET /api/v1/accounts/:account_id/pipeline_stats`

---

### CRM-12: Contact Detail Stage Selector
**Category:** UI
**Phase:** 3

Contact detail sidebar shows current stage and allows one-click stage change.

**Acceptance criteria:**
- [ ] Contact detail sidebar (existing Chatwoot pattern) gets a "Pipeline Stage" field
- [ ] Dropdown shows all available stages
- [ ] Changing selection updates contact's `pipeline_stage_id` via API
- [ ] Shows "Unassigned" if no stage set

---

### CRM-13: Unassigned Column
**Category:** UI
**Phase:** 3

Contacts without a stage appear in an "Unassigned" column in the Kanban view.

**Acceptance criteria:**
- [ ] Unassigned column renders left of first stage column
- [ ] Styled differently (muted, dashed border or different background)
- [ ] Shows count badge like other columns
- [ ] Contacts can be dragged out of Unassigned into any stage column

---

## v2 Requirements (Deferred)

| REQ-ID | Requirement | Reason Deferred |
|--------|-------------|----------------|
| CRM-14 | Automation triggers engine | Needs stable stage model first |
| CRM-15 | Activity timeline sidebar | Needs stage transition history table |
| CRM-16 | Bulk stage assignment | Extends existing bulk action pattern |
| CRM-17 | Drag-drop reorder within stage | Needs `position` on Contact |
| CRM-18 | Stale lead indicators | Needs conversation activity data |
| CRM-19 | Conversation context on cards | Needs last message preview |
| CRM-20 | Multiple pipelines | UI complexity not justified yet |
| CRM-21 | Funnel conversion analytics | Needs historical baseline data |

---

## Out of Scope

| Exclusion | Reason |
|-----------|--------|
| Deal value / revenue tracking | Explicitly not requested; shifts product from messaging CRM |
| Payment or contract features | Out of scope for v1 |
| Custom contact fields | Use existing `custom_attributes` jsonb if needed later |
| Email / call activity logging | Chatwoot conversations serve this already |
| Multiple pipelines per account | Most teams need one; add when demand is clear |

---

## Traceability Matrix

| Phase | REQ-IDs | Deliverable |
|-------|---------|-------------|
| Phase 1: Backend | CRM-01, CRM-02, CRM-03, CRM-04, CRM-05 | API, models, data migration |
| Phase 2: Stores & Routing | (none — infrastructure only) | Pinia stores, route, API clients |
| Phase 3: UI | CRM-06, CRM-07, CRM-08, CRM-09, CRM-10, CRM-11, CRM-12, CRM-13 | Kanban, List, Stats, Stage Mgmt |

---
*Requirements defined: 2026-04-10*
