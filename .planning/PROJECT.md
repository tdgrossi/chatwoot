# CRM Pipeline — Chatwoot Extension

## What This Is

A pipeline-first CRM layer built on top of Chatwoot's existing contact system. Every Chatwoot contact gets a pipeline stage field, allowing contacts to be visualized in a Kanban board, filtered by stage, and tracked through a simple pipeline. The goal is lead management and basic automation hooks — not a full sales suite.

## Core Value

Contacts (leads) flow through customizable pipeline stages. Teams see their pipeline in Kanban or list view, get stats on volume and movement, and eventually trigger automations on stage transitions or inactivity.

## Context

- **Existing codebase:** Chatwoot — multi-tenant customer messaging platform (Rails 7.1 + Vue 3 SPA, PostgreSQL, Redis, Sidekiq)
- **Existing contacts:** `Contact` model at `app/models/contact.rb` — already multi-tenant, already used across Chatwoot
- **Existing users:** Chatwoot `User` model — agents and admins
- **UI entry point:** New dashboard page under the Conversations section (like Contacts, Reports)

## v1 Scope

### In Scope

- **Pipeline stage field** — new `pipeline_stage_id` column on contacts; nullable (untyped contacts still work)
- **Pipeline model** — account-scoped, with ordered stages (name, position, color)
- **CRM dashboard page** — new route `/dashboard/leads` with:
  - Kanban view (columns = pipeline stages)
  - List view (table with stage filter)
  - Stage filter / tabs
- **Stage management** — admin UI to add, reorder, rename, delete stages (within accounts)
- **Basic statistics:**
  - Volume per stage (bar chart or cards)
  - Contacts added per day/week
- **Contact detail sidebar** — shows current pipeline stage, allows one-click stage change

### Out of Scope (v1)

- Payments, contracts, deal values
- Custom fields on contacts beyond pipeline stage
- Automation triggers / actions (engine will be built, triggers deferred to v2)
- Email/phone call logging (Chatwoot message history is sufficient)
- Reporting beyond stage volume counts

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Reuse Chatwoot contacts | Avoids data duplication; CRM is a layer on existing contacts | `Contact` gets `pipeline_stage_id` |
| Pipeline stages are account-scoped | Chatwoot is already multi-tenant; each team needs own pipeline | `Pipeline` model belongs to `Account` |
| Kanban + List views | Different workflows prefer different views | Both built in v1 |
| Stage transitions are manual in v1 | Automation hooks deferred; human-driven pipeline for now | Stage change via drag-drop or dropdown |
| No deal values | Not requested; keeping scope tight | — |
| Stats: volume only | Conversion rate tracking needs baseline data; defer | — |

## Requirements

### Validated

(None yet — v1 is net new)

### Active

- [ ] **CRM-01**: Contact has optional `pipeline_stage_id` linking to a `PipelineStage`
- [ ] **CRM-02**: User can view contacts in Kanban board grouped by pipeline stage
- [ ] **CRM-03**: User can drag-drop a contact card to change its stage
- [ ] **CRM-04**: User can view contacts in List view with stage filter
- [ ] **CRM-05**: Admin can create, edit, reorder, and delete pipeline stages for their account
- [ ] **CRM-06**: Contact detail panel shows current stage and allows stage change
- [ ] **CRM-07**: Dashboard shows volume-per-stage statistics
- [ ] **CRM-08**: New leads (contacts with no stage) appear in a default "Unassigned" column

### Out of Scope

- Automation triggers and actions — pending v2
- Payment or contract tracking
- Custom contact fields beyond pipeline stage
- Email/call activity logging (Chatwoot conversations serve this)
- Conversion rate or funnel analytics

---
*Last updated: 2026-04-10 after initialization*
