# Feature Research

**Domain:** CRM Pipeline / Lead Management
**Researched:** 2026-04-10
**Confidence:** MEDIUM (based on established CRM patterns, Chatwoot codebase analysis, and product context; limited external web research due to API errors)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels broken or incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Pipeline stage field on contacts** | Core of the entire feature; without this, no pipeline exists | LOW | Extends existing Contact model with `pipeline_stage_id`; Chatwoot already has `custom_attributes` jsonb if more flexibility is needed later |
| **Kanban board view** | The defining visual for pipeline management; users expect drag-drop stage changes | MEDIUM | Columns = stages, cards = contacts; Chatwoot already has a rich contacts list UI to pattern from |
| **List/table view with stage filter** | Power users prefer tabular data; filter by stage is the minimum filter needed | LOW | Leverage existing Chatwoot contacts list layout and filter infrastructure |
| **Stage management (CRUD)** | Teams need to define their own pipeline stages (New, Contacted, Qualified, Lost, etc.) | LOW | Admin-only settings; account-scoped; CRUD on `pipeline_stages` table |
| **Stage statistics (volume per stage)** | Users want to know where leads are concentrated; the primary dashboard value | LOW | Count contacts grouped by stage; simple bar chart or stat cards |
| **Contact detail shows current stage** | Users need to see stage context when looking at a contact | LOW | Sidebar panel or contact detail view; single-click stage change from there |
| **Unassigned / unsorted column** | Contacts without a stage need a place; default state for all contacts before assignment | LOW | Virtual column "Unassigned" for contacts with `pipeline_stage_id = NULL` |
| **View toggle (Kanban / List)** | Different workflows prefer different views; both are standard | LOW | Toggle button in header; state persisted per user if feasible |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable for a messaging-first CRM.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Stale lead indicators** | Messaging-first CRM is about conversations; leads that have gone quiet are actionable | MEDIUM | Show "last activity" age on contact cards; highlight leads with no conversation in X days; this is where Chatwoot's messaging DNA creates unique value |
| **Conversation context on pipeline cards** | Display last message snippet or conversation count directly on Kanban cards | MEDIUM | Leverages Chatwoot's existing conversation data; helps agents prioritize without opening each contact |
| **Bulk stage assignment** | Users want to move multiple contacts at once (e.g., "mark all New leads from last week as Contacted") | MEDIUM | Multi-select in list view + bulk action dropdown; Chatwoot already has contacts bulk action bar to pattern from |
| **Pipeline stage segments** | Saved filters by stage (e.g., "Show me all New leads from this week") | LOW | Extend existing Chatwoot segments infrastructure; add stage as a filter dimension |
| **Drag-drop card reordering within stage** | Agents want to prioritize within a column; order matters | MEDIUM | Add `position` float field on contact for ordering within a stage; Chatwoot conversations have priority ordering already |
| **Quick-add contact to specific stage** | "New lead" action from Kanban header — fast inbound capture | LOW | "Add contact" button on each Kanban column header; defaults stage to that column |
| **Activity timeline sidebar** | Show stage history on contact detail (when did this lead move to each stage?) | MEDIUM | Extends existing Chatwoot contact history sidebar; creates audit trail without automation engine |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems for this scope.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Deal value / revenue tracking** | Natural for sales pipelines; seems analogous to stage | Shifts product from messaging CRM to sales CRM; requires financial data models, currency handling, reporting complexity not in scope | Keep pipeline volume-focused (count-based) for v1; add monetary value later if demand materializes |
| **Custom contact fields (beyond pipeline stage)** | Power users want phone stage, source stage, etc. | Bloats schema; requires field builder UI; complicates data model | Use Chatwoot's existing `custom_attributes` jsonb if truly needed; no dedicated field builder in v1 |
| **Automated stage transitions (rules engine)** | "When X, move to stage Y" sounds efficient | Requires automation engine investment; fragile without rich event data; early-stage teams benefit more from manual review | Keep v1 manual-only; automation hooks (CRM-ENGINE) are v2 |
| **Email / call activity logging** | "Log my calls so I remember what happened" | Duplicates Chatwoot conversation history; creates data inconsistency risk | Chatwoot conversations already serve as activity log; link conversations to stage in timeline sidebar instead |
| **Multiple pipelines per account** | Some teams want different pipelines for different use cases | Adds pipeline selector UI everywhere; doubles data model complexity; most teams need one pipeline | Single pipeline per account in v1; multi-pipeline is a feature-flag candidate for v1.x |
| **Funnel conversion rate analytics** | "What % of New leads become Qualified?" | Needs historical data baseline; early-stage teams have no meaningful conversion data; metric is misleading without volume | Stage volume stats are sufficient for v1; conversion funnels are v2 |
| **Drag-drop Kanban for large contact sets** | Users want to move 100+ contacts at once | Performance issues; UX breaks down with dense columns; requires virtualization | List view multi-select handles bulk operations better; add virtualized Kanban in v1.x if needed |

## Feature Dependencies

```
[Pipeline Stage Field]
        │
        ├──requires──> [Stage Management (CRUD)]
        │                         │
        │                         └── Kanban View ←─requires─ [Stage Management]
        │                         │
        │                         └── List View ←─requires─ [Stage Management]
        │
        ├──enables──> [Stage Statistics]
        │
        ├──enables──> [Pipeline Stage Segments]
        │
        └──enables──> [Stage on Contact Detail]

[Kanban View]
        ├──requires──> [Unassigned Column] (handled as NULL / no stage)
        │
        └──optional──> [Drag-drop Reorder within Stage] (position field)

[List View]
        ├──requires──> [Stage Filter]
        │
        └──optional──> [Bulk Stage Assignment] (requires multi-select)

[Stale Lead Indicators] ──enhances──> [Kanban View]
    (context from Chatwoot conversations)
```

### Dependency Notes

- **Kanban/List views require Stage Management:** You cannot build the views until the stage data model and admin UI for creating/reordering stages exist. Stage management must be Phase 1.
- **Stage Statistics requires pipeline stage field:** Stats are a read-only aggregation, so it can be built in parallel with views once the field exists, but it depends on the data being populated.
- **Bulk Stage Assignment requires List View:** Multi-select and bulk actions are a natural extension of the list view's existing bulk action infrastructure (Chatwoot already has this pattern at `ContactsBulkActionBar.vue`).
- **Stale Lead Indicators do not conflict with automation:** This is purely a display-layer feature — it reads existing conversation data, adds no new data model, and creates no automation coupling.

## MVP Definition

### Launch With (v1)

Minimum viable product — what is needed to validate the pipeline concept.

- [ ] **Pipeline stage field on Contact** — nullable FK to pipeline_stages; untyped contacts still work
- [ ] **Stage management (admin CRUD)** — account-scoped; create, rename, reorder, delete stages; color assignment
- [ ] **Kanban view** — contacts as cards, columns as stages, virtual "Unassigned" column for NULL stage
- [ ] **List view with stage filter** — table with stage column; filter dropdown by stage
- [ ] **View toggle (Kanban / List)** — simple toggle in header; both views must be functional
- [ ] **Stage statistics (volume)** — count per stage; displayed as stat cards or simple bar chart in dashboard header
- [ ] **Stage on contact detail** — sidebar shows current stage; dropdown to change
- [ ] **Unassigned column** — contacts with NULL stage appear in "Unassigned" column in Kanban

### Add After Validation (v1.x)

Features to add once core pipeline is working and users demonstrate need.

- [ ] **Bulk stage assignment** — multi-select in list view + bulk action; triggered after users have >50 contacts
- [ ] **Drag-drop reorder within stage** — `position` float on contact; only needed when users report "I need to prioritize within New leads"
- [ ] **Stale lead indicators** — last activity age badge on Kanban cards; flagged when no conversation in 7+ days
- [ ] **Conversation context on Kanban cards** — last message preview or conversation count; triggers from user feedback about "I have to open every contact"
- [ ] **Pipeline stage segments** — saved filters by stage; leverages existing segments infrastructure

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Activity timeline sidebar** — stage change history on contact detail; requires `pipeline_stage_transitions` table
- [ ] **Automation triggers engine** — "on stage change, do X"; this is the big v2 feature
- [ ] **Multiple pipelines per account** — feature-flag gated; only after clear user demand
- [ ] **Funnel conversion analytics** — requires 3+ months of historical baseline data
- [ ] **Deal value / monetary tracking** — revenue pipeline features; separate product direction decision

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Pipeline stage field on Contact | HIGH | LOW | P1 |
| Kanban view | HIGH | MEDIUM | P1 |
| List view with stage filter | HIGH | LOW | P1 |
| Stage management (admin CRUD) | HIGH | LOW | P1 |
| Stage statistics (volume) | HIGH | LOW | P1 |
| Stage on contact detail | MEDIUM | LOW | P1 |
| Unassigned column | MEDIUM | LOW | P1 |
| View toggle (Kanban/List) | MEDIUM | LOW | P1 |
| Bulk stage assignment | MEDIUM | MEDIUM | P2 |
| Drag-drop reorder within stage | MEDIUM | MEDIUM | P2 |
| Stale lead indicators | MEDIUM | MEDIUM | P2 |
| Conversation context on cards | MEDIUM | MEDIUM | P2 |
| Pipeline stage segments | MEDIUM | LOW | P2 |
| Activity timeline sidebar | LOW | HIGH | P3 |
| Multiple pipelines | LOW | HIGH | P3 |
| Funnel conversion analytics | LOW | HIGH | P3 |
| Automation triggers | LOW | HIGH | P3 |
| Deal value tracking | LOW | HIGH | P3 |
| Custom contact fields | LOW | MEDIUM | P3 |
| Email/call activity logging | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible (v1.x)
- P3: Nice to have, future consideration (v2+)

## Competitor Feature Analysis

| Feature | Kommo (Lite) | HubSpot (Free) | Pipedrive (Starter) | Our Approach |
|---------|--------------|-----------------|---------------------|--------------|
| Pipeline stages on contacts | YES | YES | YES | YES (v1) — core feature |
| Kanban board | YES | YES | YES | YES (v1) — core feature |
| List view with filters | YES | YES | YES | YES (v1) — leverage existing contacts list |
| Stage management UI | YES | YES | YES | YES (v1) — admin settings page |
| Volume statistics | Basic | Basic | YES | YES (v1) — count per stage |
| Drag-drop reorder within stage | YES | YES | YES | P2 — add `position` field |
| Bulk actions | YES | YES | YES | P2 — extend existing Chatwoot bulk actions |
| Stale lead indicators | Partial | YES | YES | P2 — unique value for messaging-first CRM |
| Conversation context on cards | NO | NO | NO | P2 differentiator — unique to Chatwoot |
| Automation triggers | YES | YES | YES | v2 — build engine, add triggers later |
| Deal value | YES | YES | YES | NOT in v1 — explicit anti-feature |
| Custom contact fields | YES | YES | YES | v1.x if needed — use existing jsonb |
| Activity timeline | YES | YES | YES | P3 — v2 sidebar feature |

## Sources

- **Chatwoot codebase analysis:**
  - `app/models/contact.rb` — existing Contact model with `custom_attributes`, `additional_attributes` jsonb columns; `contact_type` enum (visitor/lead/customer)
  - `app/javascript/dashboard/routes/dashboard/contacts/routes.js` — existing CRM feature flag; route structure
  - `app/javascript/dashboard/components-next/Contacts/ContactsListLayout.vue` — existing list UI pattern
  - `app/javascript/dashboard/components-next/Contacts/ContactsHeader/ContactHeader.vue` — header with filter/sort/search pattern
  - `app/javascript/dashboard/routes/dashboard/contacts/components/ContactsBulkActionBar.vue` — existing bulk action infrastructure (pattern to extend)
- **Product context:** `.planning/PROJECT.md` — v1 scope definition
- **Competitor product knowledge:** Kommo, HubSpot, Pipedrive feature inventories (established product patterns)
- **Note on research confidence:** WebSearch API errors prevented external web research. Findings are based on established CRM domain knowledge, codebase analysis, and product context. All claims marked MEDIUM confidence should be validated against user research or beta feedback before finalizing feature scope.

---
*Feature research for: CRM Pipeline / Lead Management*
*Researched: 2026-04-10*
