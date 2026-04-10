# Project Research Summary

**Project:** CRM Pipeline for Chatwoot
**Domain:** Messaging-first CRM / Pipeline lead management
**Researched:** 2026-04-10
**Confidence:** HIGH

## Executive Summary

The CRM pipeline extends Chatwoot's existing Contact model with a nullable `pipeline_stage_id` FK and adds a new Kanban-based CRM dashboard. All table-stakes features (Kanban, list view, stage CRUD, volume stats) are interdependent and must ship together — they form one coherent pipeline product. The key differentiator is Chatwoot's existing conversation data: stale lead indicators and conversation context on cards are unique to this messaging-first CRM. The backend is minimal: two new models (`Pipeline`, `PipelineStage`), a few API endpoints, and the existing Contact model gains one FK. The frontend uses Chatwoot's established Vue 3 + Pinia + Tailwind patterns. No new dependencies are required.

## Key Findings

### Stack

**No new dependencies needed.** Chatwoot already has vuedraggable (Kanban drag-drop), Chart.js + vue-chartjs (stats), @tanstack/vue-table (list view), and virtua (virtual scrolling). Rails side needs no new gems — wisper is already present, acts_as_list is recommended for stage reordering.

### Expected Features

**Must have (table stakes) — all P1:**
- Pipeline stage field on Contact (nullable FK)
- Kanban board view (columns = stages, cards = contacts)
- List view with stage filter (leveraging existing contacts list)
- Stage management admin UI (CRUD, reorder, color)
- Volume-per-stage statistics (bar chart or stat cards)
- Contact detail shows current stage with one-click change
- Unassigned column for contacts with no stage
- View toggle (Kanban/List)

**Should have (v1.x):**
- Bulk stage assignment (multi-select + dropdown)
- Drag-drop reorder within a stage column
- Stale lead indicators (conversation inactivity badge)
- Conversation context on Kanban cards (last message snippet)

**Defer (v2):**
- Automation triggers engine
- Activity timeline sidebar
- Multiple pipelines per account
- Funnel conversion analytics
- Deal value / monetary tracking

### Architecture

**Backend:** Two new models — `Pipeline` (account-scoped, one-per-account container) and `PipelineStage` (ordered, has position via acts_as_list, has color). Contact gains nullable `pipeline_stage_id` FK. API: RESTful under `/api/v1/accounts/:account_id/` plus stats endpoint. Wisper event published on stage change for future automation hooks.

**Frontend:** New Pinia store `usePipelineStore` for stages CRUD + stats. New Pinia store `useContactsStore` for CRM-optimized contact queries filtered by stage. Route: `/accounts/:accountId/dashboard/leads`. Components under `dashboard/components/crm/`: KanbanBoard, KanbanColumn, ContactCard, ContactsListView, PipelineStats, PipelineStagesPanel.

**Build order is strict:** Phase 1 (backend) → Phase 2 (stores + routes) → Phase 3 (UI). No parallelization across phases.

### Critical Pitfalls

1. **Duplicating contact state** — CRM reads from existing Contact model; stage changes flow through normal contact update API
2. **Blocking reorder on contact count recalculation** — acts_as_list reorder is O(n) on stage count only; counter cache via after_save callbacks
3. **Kanban rerenders on every drag** — optimistic store updates; only moved card re-renders
4. **Hardcoding default stages** — create one default stage ("New") on Account creation; expose management immediately

## Implications for Roadmap

### Suggested Phase Structure

**Phase 1: CRM Backend Foundation**
Pipeline and PipelineStage models, API endpoints (CRUD + reorder + stats), Contact FK, Wisper event on stage change.
**Delivers:** API is the hard gate — nothing frontend works without it.

**Phase 2: Frontend Store & Routing**
Pinia stores (pipeline + contacts), API clients, new `/dashboard/leads` route.
**Delivers:** Frontend can now build UI against real API.

**Phase 3: CRM UI — Kanban & List Views**
KanbanBoard + KanbanColumn + ContactCard (with drag-drop), ContactsListView (table + stage filter), PipelineStats, Stage management panel (admin), contact detail sidebar stage selector, view toggle.
**Delivers:** The shippable product.

### Phase Ordering Rationale

- Backend (Phase 1) is a hard prerequisite — API must exist before frontend fetches from it
- Stores (Phase 2) depend on Phase 1 API — cannot be parallelized
- UI (Phase 3) depends on stores — no parallelization possible within the three phases
- Phases 2 and 3 ARE parallelizable against each other only if we split frontend/backend, but that doesn't apply here — it's a clean 1→2→3 sequence

### Research Flags

- **Phase 3 (UI):** Kanban drag-drop UX — no drag-drop UI pattern currently exists in Chatwoot that maps to this use case; vuedraggable library choice is standard but needs validation with the specific component structure
- **acts_as_list:** Not confirmed in Chatwoot's Gemfile — verify before Phase 1 planning
- **@tanstack/vue-query:** LOW confidence on version — verify stable version before adding to package.json

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified from package.json; no new dependencies needed |
| Features | MEDIUM | CRM domain patterns well-established; Chatwoot-specific integration medium confidence |
| Architecture | HIGH | Follows established Chatwoot patterns exactly |
| Pitfalls | MEDIUM | Anti-patterns are generic Rails/JS wisdom; Chatwoot-specific pitfalls need Phase 1 validation |

**Overall confidence:** HIGH

### Gaps to Address

- **Drag-drop library validation:** Confirm vuedraggable is the right choice vs @formkit/drag-and-drop — both work with Vue 3
- **acts_as_list gem presence:** Check if already in Gemfile before planning Phase 1 migration generation
- **Large contact set performance:** v1 targets small-to-medium contact sets; virtual scrolling plan exists but not validated under load
