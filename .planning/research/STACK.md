# Stack Research: CRM Pipeline Extension on Chatwoot

**Domain:** CRM pipeline / Kanban board / stats dashboard for a Rails 7.1 + Vue 3 SPA
**Researched:** 2026-04-10
**Confidence:** HIGH (library versions verified from active package.json, patterns confirmed from codebase)

## Executive Summary

Chatwoot's existing Vue 3 SPA already has all the UI primitives needed for a CRM pipeline -- drag-and-drop (vuedraggable), charts (Chart.js via vue-chartjs), virtual scrolling (virtua), and a proven Vuex store module pattern. No new frontend dependencies are required. The new tech needed is minimal: one optional state-management pattern for server-side cache, and one Rails concern for sortable ordering. The rest is new Rails models and Vue components following established Chatwoot conventions.

---

## Recommended Stack

### Core Technologies (new for CRM layer)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **@tanstack/vue-query** | ^5.62.16 | Server-state caching for pipeline stage data | Handles loading/error states declaratively without duplicating Vuex; pairs naturally with Pinia for UI state; works alongside existing Vuex modules without conflict |
| **acts_as_list** | ^2.0.0 | Stage position management in PostgreSQL | Standard Rails gem for ordered collections; uses a single `position` integer column with efficient database swaps; works with any model including existing `Contact` |
| **wisper** | ^2.0.0 | In-process event bus for stage transitions | Already in Chatwoot's Gemfile; allows decoupled logic (audit logging, automation triggers, WebSocket broadcasts) on stage changes without tight coupling in models |

### Already Present (existing Chatwoot stack)

| Library | Version | CRM Use Case | Notes |
|---------|---------|--------------|-------|
| **vuedraggable** | ^4.1.0 | Kanban drag-and-drop | SortableJS wrapper for Vue 3; handles cross-column dragging, animation, events |
| **Chart.js** | ~4.4.4 | Volume-per-stage bar charts | Stable; vue-chartjs wraps it for Vue 3 |
| **vue-chartjs** | ^5.3.1 | Stats dashboard charts | Already in package.json |
| **virtua** | ^0.48.6 | Kanban column virtual scrolling | Handles large contact lists without DOM bloat |
| **@tanstack/vue-table** | ^8.20.5 | List view data grid | Already in package.json; handles sorting, filtering, pagination |
| **Tailwind CSS** | ^3.4.19 | UI layout and styling | Already in use; consistent with existing components |

### Rails Backend (no new gems needed)

| Pattern | Purpose | Chatwoot Precedent |
|---------|---------|-------------------|
| **ActiveRecord models** with `belongs_to :account` | Account-scoped pipeline stages | Matches `Label`, `Team`, `Inbox` |
| **Position integer column + acts_as_list** | Ordered stages | Used by `Label`, `Inbox` |
| **Optional `pipeline_stage_id` on Contact** | Contact-stage association | Nullable FK on existing `Contact` model |
| **Jbuilder templates** | JSON API responses | Standard Chatwoot API pattern |
| **Pundit policies** | Authorization | Already in use across Chatwoot |

---

## Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@tanstack/vue-query` | ^5.62.16 | Declarative server state | For pipeline data fetching, stage counts, stats -- any data that changes without full page reload |
| `acts_as_list` | ^2.0.0 | Stage reordering | Only if doing drag-drop reorder in admin UI; can skip for v1 if stages are created/deleted only |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Kanban-specific Vue libraries** (e.g., vue-kanban, vuetify kanban) | Overly opinionated; poor SSR/SSG support; maintenance risk | **vuedraggable** (already in package.json) + custom Vue components |
| **DHTMLX Gantt / ag-Grid** | Enterprise pricing, heavy weight, not needed for simple pipeline | **@tanstack/vue-table** + vuedraggable |
| **State machine gems** (aasm, state_machines) | Overkill for v1 manual stage changes | Plain ActiveRecord with `acts_as_list` position; add state machine in v2 if automation is added |
| **Separate service per stage** | Microservice sprawl; Chatwoot is a monolith | Single `PipelineStage` model with `position` column |
| **PostgreSQL advisory locks** | Premature optimization for simple reordering | `acts_as_list` with transaction-based swaps |
| **Rails new framework for CRM** | Adds unnecessary surface area | Extend existing `Contact` model with nullable FK |
| **Separate Redis cache for pipeline stats** | Overhead; can query directly with count/group | SQL aggregation via ActiveRecord with proper indexes |

---

## Stack Patterns by Variant

**If you need to handle very large contact lists (1000+ contacts in a single pipeline):**
- Use `virtua` for Kanban column virtual scrolling (already in package.json)
- Add `account_id + pipeline_stage_id` composite index on contacts
- Consider paginating Kanban columns instead of loading all contacts

**If you want to animate stage transitions reactively:**
- vuedraggable handles this natively with SortableJS animation
- Use Pinia store for optimistic UI updates on drag-drop

**If automation triggers are added in v2:**
- Wire `wisper` (already in Gemfile) to publish events on stage change
- Subscribe Sidekiq jobs to those events
- This is the pattern Chatwoot uses internally for contact events

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `vuedraggable@4.1.0` | Vue 3.5.12, Pinia 3.0.4 | Works with both Vuex and Pinia; SortableJS underlying |
| `vue-chartjs@5.3.1` | Chart.js~4.4.4 | Vue 3 native |
| `@tanstack/vue-table@8.20.5` | Vue 3, Pinia | Headless; no UI opinion |
| `@tanstack/vue-query@5.x` | Vue 3.5.12 | Works alongside Vuex; no conflict |
| `acts_as_list@2.0.0` | Rails 7.1 | Standard gem |
| `wisper@2.0.0` | Rails 7.1 | Already in Gemfile |

---

## Installation

No new npm packages are required for v1 -- everything needed is already in `package.json`. For the optional items:

```bash
# Optional: if adding @tanstack/vue-query for server-state management
npm install @tanstack/vue-query@5.62.16

# No new Ruby gems needed in Gemfile -- existing gems cover all needs
```

---

## Rails Model Pattern (Pipeline Stage)

Based on Chatwoot conventions:

```
Pipeline (account-scoped)
  id, name, account_id, created_at, updated_at

PipelineStage (account-scoped, ordered)
  id, name, position, color, pipeline_id, account_id, created_at, updated_at

Contact (existing -- add nullable FK)
  add: pipeline_stage_id (bigint, FK, nullable, indexed)
```

**Critical pattern:** The `pipeline_stage_id` on `Contact` is nullable. Untyped contacts continue to work in all existing Chatwoot flows. This avoids a breaking change.

**Index recommendation:**
```ruby
add_index :contacts, [:account_id, :pipeline_stage_id]
```

---

## API Design Pattern

Following Chatwoot's established JSON API pattern:

```
GET  /api/v1/accounts/:account_id/pipelines           -- list pipelines
GET  /api/v1/accounts/:account_id/pipelines/:id/stages -- list stages
GET  /api/v1/contacts?q[pipeline_stage_id_eq]=:stage   -- contacts by stage (reuse existing filter API)
PATCH /api/v1/contacts/:id  -- { contact: { pipeline_stage_id: :stage_id } }
POST /api/v1/accounts/:account_id/pipelines           -- create pipeline
POST /api/v1/accounts/:account_id/pipelines/:id/stages -- create stage
PATCH /api/v1/accounts/:account_id/stages/:id           -- update stage (name, color, position)
DELETE /api/v1/accounts/:account_id/stages/:id           -- delete stage
```

All responses via Jbuilder templates matching existing Chatwoot API conventions.

---

## Sources

- `package.json` (chatwoot@4.12.1) -- confirmed vuedraggable, chart.js, vue-chartjs, virtua, @tanstack/vue-table versions
- `Gemfile` -- confirmed wisper, acts_as_list compatibility
- `app/models/contact.rb` -- confirmed `belongs_to :account` pattern, multi-tenant approach
- `app/javascript/dashboard/store/index.js` -- confirmed Vuex module pattern for state management
- `app/javascript/dashboard/components-next/Contacts/ContactsListLayout.vue` -- confirmed Vue 3 Composition API component pattern
- `app/javascript/dashboard/routes/dashboard/contacts/routes.js` -- confirmed routing conventions
- Chatwoot schema conventions: account-scoped models, jsonb attributes, nullable FKs
- **LOW confidence**: @tanstack/vue-query version -- latest stable as of April 2026, not verified against Context7 (Context7 unavailable in this environment); recommend verifying before adding to package.json

---

*Stack research for: CRM pipeline / Kanban / stats dashboard*
*Researched: 2026-04-10*