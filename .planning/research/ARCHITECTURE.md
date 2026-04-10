# Architecture Research: CRM Pipeline

**Domain:** CRM Pipeline / Kanban-based lead management
**Project:** Chatwoot CRM Extension
**Researched:** 2026-04-10
**Confidence:** HIGH

## Executive Summary

The CRM pipeline is a layer on top of Chatwoot's existing `Contact` model. Pipeline stages are an ordered, account-scoped resource; contacts carry a nullable `pipeline_stage_id` foreign key. The Kanban UI is a new route under `accounts/:accountId/dashboard/leads`, built with Pinia (the new standard) and using the existing contacts API extended with pipeline-aware endpoints. The key architectural decision is that **pipeline state lives in a dedicated Pinia store, while contacts remain in the existing Vuex contacts module**, with cross-store coordination via a shared `pipelineStageId` field on contact records.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Vue Router                              │
│  /accounts/:accountId/dashboard/leads                        │
│  /accounts/:accountId/dashboard/leads/:contactId            │
└──────────┬──────────────────┬──────────────────────────────┘
           │                  │
┌──────────▼──────────────────▼──────────────────────────────┐
│               Pinia: usePipelineStore                        │
│  pipelines[], stages[], uiFlags, stageStats                 │
│  actions: getStages, createStage, reorderStages, updateStage │
└──────────┬──────────────────┬──────────────────────────────┘
           │                  │
┌──────────▼──────────────────▼──────────────────────────────┐
│               Vuex: contacts (existing)                     │
│  records[id].pipeline_stage_id (added field)                 │
│  actions: search, filter, update (update extends to stage)  │
│  getters: getContactsByStage(stageId)                        │
└──────────┬──────────────────┬──────────────────────────────┘
           │
┌──────────▼──────────────────────────────────────────────────┐
│        Pinia: useContactsStore (new, if needed)             │
│  Optimized CRM view: getContactsByStage(stageId)             │
│  Pagination per stage column                                  │
└──────────┬──────────────────────────────────────────────────┘
           │
┌──────────▼──────────────────────────────────────────────────┐
│                    Rails API                                 │
│  Api::V1::Accounts::PipelineStagesController                  │
│  Api::V1::Accounts::PipelineStages::ContactsController       │
│  (extends existing contacts_controller with pipeline params)  │
└──────────┬──────────────────────────────────────────────────┘
           │
┌──────────▼──────────────────────────────────────────────────┐
│              PostgreSQL Schema                                │
│  pipelines(id, account_id, name, created_at)                 │
│  pipeline_stages(id, pipeline_id, name, position, color)     │
│  contacts(pipeline_stage_id FK -> pipeline_stages)           │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Responsibility | Where it lives |
|-----------|----------------|----------------|
| `Pipeline` model | Account-scoped container for stages | `app/models/pipeline.rb` |
| `PipelineStage` model | Ordered stage with color, name, position | `app/models/pipeline_stage.rb` |
| `Contact` model | Existing model, gains `pipeline_stage_id` FK | `app/models/contact.rb` |
| `PipelineStagesController` | CRUD for stages, reorder via PATCH | `app/controllers/api/v1/accounts/pipeline_stages_controller.rb` |
| Pipeline API client | CRUD + reorder endpoints | `app/javascript/dashboard/api/pipelineStages.js` |
| `usePipelineStore` | Stage CRUD, stage stats, drag state | `app/javascript/dashboard/stores/pipeline.js` |
| `useContactsStore` | Contact list per stage, contact update (stage change) | `app/javascript/dashboard/stores/contacts.js` (Pinia) |
| `PipelineStagesPanel` | Stage management UI (admin) | `app/javascript/dashboard/components/crm/PipelineStagesPanel.vue` |
| `KanbanBoard` | Main kanban view container | `app/javascript/dashboard/components/crm/KanbanBoard.vue` |
| `KanbanColumn` | Single stage column with contact cards | `app/javascript/dashboard/components/crm/KanbanColumn.vue` |
| `ContactCard` | Draggable contact card in Kanban | `app/javascript/dashboard/components/crm/ContactCard.vue` |
| `ContactsListView` | Table view with stage filter | `app/javascript/dashboard/components/crm/ContactsListView.vue` |
| `PipelineStats` | Volume-per-stage cards/chart | `app/javascript/dashboard/components/crm/PipelineStats.vue` |

---

## Data Model

### Rails Models

**`Pipeline`** — one per account
```ruby
class Pipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, -> { order(position: :asc) }, class_name: 'PipelineStage', inverse_of: :pipeline
  has_many :contacts, through: :stages

  validates :account_id, uniqueness: true  # one pipeline per account
end
```

**`PipelineStage`** — ordered stages within a pipeline
```ruby
class PipelineStage < ApplicationRecord
  belongs_to :pipeline
  has_many :contacts, foreign_key: :pipeline_stage_id

  validates :name, presence: true
  validates :position, uniqueness: { scope: :pipeline_id }

  # ActsAsList for reordering: acts_as_list scope: :pipeline
  acts_as_list scope: :pipeline
end
```

**Contact extension** (in `app/models/contact.rb`)
```ruby
# Add to existing Contact model:
belongs_to :pipeline_stage, optional: true
has_one :pipeline, through: :pipeline_stage
```

### Schema

```ruby
create_table :pipelines do |t|
  t.references :account, null: false, foreign_key: true
  t.string :name, default: "Pipeline"
  t.timestamps
end
add_index :pipelines, :account_id, unique: true

create_table :pipeline_stages do |t|
  t.references :pipeline, null: false, foreign_key: true
  t.string :name, null: false
  t.integer :position, null: false
  t.string :color, default: "#1f93ff"
  t.timestamps
end
add_index :pipeline_stages, [:pipeline_id, :position], unique: true

# Add to existing contacts table:
add_reference :contacts, :pipeline_stage, foreign_key: true, index: true, null: true
```

---

## API Design

### Design Principles

- **Account-scoped:** All endpoints live under `/api/v1/accounts/:account_id/`
- **RESTful:** Standard GET/POST/PATCH/DELETE patterns
- **Stage operations batched:** Drag-drop reorder sends a single PATCH with ordered IDs
- **Contact stage change:** `PATCH /contacts/:id` with `pipeline_stage_id` — extends existing update endpoint

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/accounts/:account_id/pipelines` | Get pipeline with stages |
| POST | `/api/v1/accounts/:account_id/pipelines` | Create pipeline (usually auto on account creation) |
| GET | `/api/v1/accounts/:account_id/pipeline_stages` | List stages for pipeline |
| POST | `/api/v1/accounts/:account_id/pipeline_stages` | Create stage |
| PATCH | `/api/v1/accounts/:account_id/pipeline_stages/:id` | Update stage (name, color) |
| DELETE | `/api/v1/accounts/:account_id/pipeline_stages/:id` | Delete stage |
| PATCH | `/api/v1/accounts/:account_id/pipeline_stages/reorder` | Reorder stages (`{ stage_ids: [3, 1, 2] }`) |
| GET | `/api/v1/accounts/:account_id/pipeline_stages/:id/contacts` | Contacts in stage (paginated, for kanban columns) |
| GET | `/api/v1/accounts/:account_id/contacts?pipeline_stage_id=` | Filter contacts by stage (extends existing) |
| PATCH | `/api/v1/accounts/:account_id/contacts/:id` | Update contact including `pipeline_stage_id` |
| GET | `/api/v1/accounts/:account_id/pipeline_stats` | Volume per stage |

### Reorder Endpoint

```
PATCH /api/v1/accounts/:account_id/pipeline_stages/reorder
Body: { stage_ids: [4, 2, 1, 3] }   # ordered IDs after drag-drop
```

The backend uses `acts_as_list` to update positions atomically:
```ruby
def reorder
  stage_ids = params.require(:stage_ids)
  PipelineStage.reorder_list(stage_ids)
  render json: { message: 'ok' }
end
```

### Contact Stage Change

The existing `ContactsController#update` already handles `pipeline_stage_id`. Extend `permitted_params`:
```ruby
def permitted_params
  params.permit(:name, :email, ..., pipeline_stage_id: [])
  # Note: if nullable, pass pipeline_stage_id as scalar, not array
end
```

---

## Frontend Architecture

### File Structure

```
app/javascript/dashboard/
  api/
    pipelineStages.js          # ApiClient subclass for pipeline stages
    pipelineStats.js           # API for stats endpoint
  stores/
    pipeline.js               # Pinia store: usePipelineStore
  components/crm/
    PipelineDashboard.vue      # Main page component (route view)
    KanbanBoard.vue            # Kanban container
    KanbanColumn.vue           # Single column
    ContactCard.vue            # Draggable card
    ContactsListView.vue       # Table view
    StageFilter.vue            # Tabs / stage filter bar
    PipelineStats.vue          # Stats cards / chart
    PipelineStagesPanel.vue    # Admin stage editor (drawer/modal)
    StageEditor.vue            # Single stage edit form
    ContactDetailSidebar.vue   # Updated to show stage selector
  routes/dashboard/
    crm/
      crm.routes.js           # Route definitions
      PipelineDashboard.vue    # Route-mounted component
```

### State Management

**Two stores — clear separation of concerns:**

```
usePipelineStore (Pinia)
  state:
    currentPipeline: { id, name }
    stages: PipelineStage[]   # ordered
    uiFlags: { fetchingStages, updatingStage, reordering }
    stageStats: { [stageId]: { count, addedToday, addedThisWeek } }
  getters:
    stageById: id -> PipelineStage
    stageByPosition: idx -> PipelineStage
    stagesOrdered: PipelineStage[]  (sorted by position)
  actions:
    getPipeline()             GET /pipelines
    getStages()               GET /pipeline_stages
    createStage(data)         POST /pipeline_stages
    updateStage(id, data)     PATCH /pipeline_stages/:id
    deleteStage(id)           DELETE /pipeline_stages/:id
    reorderStages(stageIds)   PATCH /pipeline_stages/reorder
    getStageStats()           GET /pipeline_stats
```

```
useContactsStore (Pinia, new — extends contacts for CRM)
  state:
    contactsByStage: { [stageId]: Contact[] }
    unassignedContacts: Contact[]
    activeView: 'kanban' | 'list'
    dragState: { dragging: boolean, sourceStageId: string|null }
  getters:
    contactsForStage(stageId): Contact[]
    unassignedContacts: Contact[]
  actions:
    getContactsForStage(stageId, page)   GET /pipeline_stages/:id/contacts
    getUnassignedContacts(page)          GET /contacts?pipeline_stage_id=null
    changeContactStage(contactId, stageId)  PATCH /contacts/:id with { pipeline_stage_id }
    moveContactInStore(contactId, fromStageId, toStageId)  # optimistic update
```

**Cross-store coordination:** When a contact's stage changes, both stores update. The Kanban board subscribes to both `usePipelineStore` (for stage list) and `useContactsStore` (for contact cards). Stage deletion moves contacts to unassigned.

### Existing Contacts Store Integration

The existing Vuex contacts module (`store/modules/contacts/`) stores contacts by ID as `records[id]`. Do NOT duplicate contacts. Instead:
- The Kanban board reads from Vuex `contacts` module filtered by `pipeline_stage_id` in a getter
- OR use the new Pinia `useContactsStore` for CRM-specific optimized queries

**Decision:** Use new Pinia `useContactsStore` for CRM views. It maintains its own filtered view. The existing Vuex contacts module is left untouched — other parts of Chatwoot already depend on it.

### Pinia Store Example (builds on existing factory)

```javascript
// app/javascript/dashboard/api/pipelineStages.js
import ApiClient from './ApiClient';

class PipelineStagesAPI extends ApiClient {
  constructor() {
    super('pipeline_stages', { accountScoped: true });
  }

  reorder(accountId, stageIds) {
    return axios.patch(
      `/api/v1/accounts/${accountId}/pipeline_stages/reorder`,
      { stage_ids: stageIds }
    );
  }

  getStats(accountId) {
    return axios.get(`/api/v1/accounts/${accountId}/pipeline_stats`);
  }
}

export default new PipelineStagesAPI();
```

```javascript
// app/javascript/dashboard/stores/pipeline.js
import PipelineStagesAPI from 'dashboard/api/pipelineStages';
import { defineStore } from 'pinia';

export const usePipelineStore = defineStore('pipeline', {
  state: () => ({
    currentPipeline: null,
    stages: [],
    uiFlags: { fetchingStages: false, updatingStage: false },
    stageStats: {},
  }),

  getters: {
    stagesOrdered: state => [...state.stages].sort((a, b) => a.position - b.position),
    stageById: state => id => state.stages.find(s => s.id === id),
    stageCount: state => state.stages.length,
  },

  actions: {
    async getPipeline() {
      // GET /pipelines — returns pipeline with nested stages
    },
    async createStage(data) { /* POST */ },
    async updateStage(id, data) { /* PATCH */ },
    async deleteStage(id) { /* DELETE */ },
    async reorderStages(stageIds) {
      // Optimistic: update positions locally first
      const updated = stageIds.map((id, idx) => {
        const stage = this.stages.find(s => s.id === id);
        return { ...stage, position: idx };
      });
      this.stages = updated;
      // Then PATCH reorder to persist
      await PipelineStagesAPI.reorder(this.accountId, stageIds);
    },
    async getStageStats() { /* GET /pipeline_stats */ },
  },
});
```

---

## Kanban Board Implementation

### Drag-and-Drop

Use `@formkit/drag-and-drop` or `vuedraggable` (both used in Vue ecosystem). Chatwoot already uses Vue 3. vuedraggable v4 (`@vueuse/integrations`) or `@formkit/drag-and-drop` works with Vue 3.

**Pattern for optimistic stage change:**
```
contactCard onDragEnd(contactId, fromStageId, toStageId)
  -> useContactsStore.moveContactInStore(contactId, fromStageId, toStageId)  // optimistic
  -> await ContactAPI.update(contactId, { pipeline_stage_id: toStageId })   // persist
  -> if error: rollback store state + show snackbar
```

### Column Virtualization

At scale (100+ contacts per stage), render only visible columns. Use `vue-virtual-scroller` or `@tanstack/vue-virtual`. At v1 scale, skip virtualization — render all cards, use pagination per column for 50+ contacts.

### Unassigned Column

Contacts with `pipeline_stage_id = null` render in an "Unassigned" column at the left of the Kanban. The column is styled differently (muted color, dashed border).

---

## Build Order

```
Phase 1: Backend foundation
  1. Generate Pipeline and PipelineStage migrations
  2. Create Pipeline and PipelineStage models with associations
  3. Create PipelineStagesController (CRUD + reorder)
  4. Seed default stages on existing Account creation (after_create)
  5. Add pipeline_stage_id to Contact model schema
  6. Extend ContactsController#update to accept pipeline_stage_id
  7. Add pipeline_stats endpoint
  8. Add pipeline index on contacts(pipeline_stage_id)

Phase 2: Frontend API + store
  1. Create pipelineStages.js API client
  2. Create usePipelineStore (Pinia)
  3. Create useContactsStore (Pinia, CRM-optimized)
  4. Create route: /accounts/:accountId/dashboard/leads

Phase 3: UI
  1. KanbanBoard + KanbanColumn + ContactCard (static, no drag)
  2. List view with stage filter
  3. Stage filter tabs bar
  4. Stage management panel (admin CRUD)
  5. Drag-and-drop stage change
  6. PipelineStats (volume cards)
  7. Contact detail sidebar: stage selector
```

**Dependencies:** Phase 2 requires Phase 1 (API must exist). Phase 3 requires Phase 2 (store must exist). Phases 1-2-3 map directly to the roadmap phases.

---

## Scaling Considerations

| Scale | Challenge | Solution |
|-------|-----------|----------|
| 0-1K contacts | N/A | Monolith fine, simple contacts query |
| 1K-10K contacts | Kanban loads all contacts per stage | Per-column pagination (20 per page), lazy-load columns |
| 10K-100K contacts | `pipeline_stage_id` index sufficient, but count queries expensive | Denormalized counts on PipelineStage model via counter cache |
| 100K+ contacts | Kanban full reload expensive | Cursor-based pagination per stage, infinite scroll per column |

**First bottleneck:** Full pipeline reload on mount. Mitigation: pipeline+stages load in parallel, contacts load lazily per column on mount.

---

## Anti-Patterns

### 1. Duplicating Contact State

**What people do:** Create a separate CRM contact table or duplicate contacts in a new store without linking back to the Vuex contacts module.
**Why it's wrong:** Contact data is authoritative in the existing `contacts` module. Edits from other Chatwoot features overwrite CRM data silently.
**Do this instead:** Contacts are the single source of truth. CRM views read from contacts (via Pinia or computed getters over Vuex state). Stage changes go through the normal contact update flow.

### 2. Blocking Reorder on Contact Count Recalculation

**What people do:** On stage reorder, recalculate all contact positions (or trigger background jobs) before responding.
**Why it's wrong:** `acts_as_list` reorder is O(n) on stage count, not on contact count. Blocking on contact recalculation adds latency proportional to pipeline size.
**Do this instead:** Reorder responds immediately. Contact count cache uses a counter cache column on `pipeline_stages` updated via after_save callbacks on Contact.

### 3. Kanban Rerenders on Every Stage Drag

**What people do:** Stage position change re-renders the entire Kanban board from scratch.
**Why it's wrong:** Vue re-rendering of all columns drops FPS during drag-and-drop.
**Do this instead:** Drag only moves a single card. Store updates are optimistic — contacts move locally, column counts update in-place.

### 4. Hardcoding Default Stages

**What people do:** Creating default stages ("New", "Qualified", "Proposal", "Closed Won/Lost") as seed data.
**Why it's wrong:** Teams have different workflows. Hardcoded stages mean teams can't start clean.
**Do this instead:** On `Account` creation, create a Pipeline with at least one default stage (e.g., "New Lead"). Expose stage management immediately in admin UI.

### 5. Stage ID as Integer in Client State

**What people do:** Store `pipeline_stage_id` as a plain integer in component state without a null guard.
**Why it's wrong:** Contacts without a stage have `pipeline_stage_id = null`. Comparisons like `stageId === contact.pipelineStageId` silently fail.
**Do this instead:** Treat null as a valid value. Filter with `!stageId ? isUnassigned : hasStage`.

---

## Integration Points

### With Existing Chatwoot Components

| Boundary | Integration | Notes |
|----------|-------------|-------|
| Contact model | `pipeline_stage_id` FK | Extend existing model, do not fork |
| Contacts Vuex store | Read contact records by stage | Computed getter or new Pinia store |
| Contact detail sidebar | Stage selector widget | Shared across contacts and CRM dashboard |
| Wisper event system | Publish `CONTACT_PIPELINE_STAGE_CHANGED` | Allows automation engine to subscribe later |
| Feature flags | `FEATURE_FLAGS.CRM` gate | Routes and UI gated by feature flag |

### With Automation Engine (v2)

The stage transition event (`CONTACT_PIPELINE_STAGE_CHANGED`) should be emitted via the existing Wisper system during Phase 1:
```ruby
# In PipelineStage transition handler
Rails.configuration.dispatcher.dispatch(
  'pipeline_stage_changed',
  Time.zone.now,
  contact: contact,
  from_stage: from_stage,
  to_stage: to_stage
)
```
This ensures v2 automation triggers can subscribe without schema changes.

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Backend model design | HIGH | Follows Chatwoot's existing patterns; acts_as_list is established |
| API design | HIGH | RESTful conventions match existing controllers |
| Frontend store architecture | HIGH | Based on existing Pinia store in `stores/companies.js` |
| Kanban drag-drop | MEDIUM | Pattern is standard; specific library choice needs validation |
| Counter cache | MEDIUM | Chatwoot doesn't currently use counter_cache on this model |

---

## Sources

- Chatwoot codebase: `app/models/contact.rb`, `app/controllers/api/v1/accounts/contacts_controller.rb`
- Chatwoot frontend: `app/javascript/dashboard/stores/companies.js`, `app/javascript/dashboard/store/storeFactory.js`
- ActsAsList gem: https://github.com/brendon/acts_as_list
- Vue Kanban patterns: Community-adopted vuedraggable + Vue 3 composition API patterns
- Pinia + Vuex coexistence: Chatwoot `storeFactory.js` documentation in source

---

*Architecture research for: CRM Pipeline*
*Researched: 2026-04-10*
