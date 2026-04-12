---
phase: "05-kanban-board-drag-drop"
plan: "02"
subsystem: ui
tags: [vue3, vuedraggable, kanban, drag-drop, optimistic-update, pinia, vuex]

# Dependency graph
requires:
  - phase: "04-frontend-infrastructure"
    provides: "usePipelineStore with fetchStages/fetchStats; KanbanBoard, StageColumn, KanbanCard components"
  - phase: "05-kanban-board-drag-drop"
    plan: "01"
    provides: "KanbanBoard.vue with drop/card-click event emission; StageColumn.vue with handleDragEnd emitting stage IDs"
provides:
  - "Full Kanban board wiring in LeadsIndex.vue with data loading, contact grouping by stage, and drag-drop handlers"
  - "moveContactToStage action with optimistic updates and revert + toast on API failure"
affects:
  - "06-stage-management"
  - "07-list-view"

# Tech tracking
tech-stack:
  added: [ContactAPI import, useAlert import]
  patterns:
    - "Optimistic update: immediate local state mutation + API call + revert on failure"
    - "Vuex + Pinia hybrid: Vuex handles contacts/fetchByStage, Pinia handles pipeline store"
    - "Contacts grouped by pipeline_stage_id (null = unassigned) in local refs"
    - "Draggable group='kanban' enables cross-column drag via StageColumn handleDragEnd"

key-files:
  created: []
  modified:
    - "app/javascript/dashboard/stores/pipeline.js"
    - "app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue"

key-decisions:
  - "LeadsIndex manages contactsByStage locally (refs) rather than via store — avoids Vuex mutation overhead during rapid drag events"
  - "Optimistic update is applied in both LeadsIndex refs AND pipeline store, keeping both in sync"
  - "handleDrop normalizes 'unassigned' string to null for pipeline_stage_id consistency"
  - "Pipeline store's moveContactToStage handles its own revert (via useAlert toast) — LeadsIndex re-fetches on error for consistency"

patterns-established:
  - "Kanban data flow: fetchStages → fetchByStage per stage → group by pipeline_stage_id → render KanbanBoard"
  - "Drag-drop flow: handleDrop (optimistic local) → pipelineStore.moveContactToStage (API + store revert) → LeadsIndex re-fetch on error"
  - "Contact map pattern: contactsMap ref for O(1) lookup by id, contactsByStage ref for grouped rendering"

requirements-completed: [CRM-02, CRM-03, CRM-08]

# Metrics
duration: ~3min
completed: 2026-04-11
---

# Phase 05 Plan 02: Kanban Board Wiring & Drag-Drop Summary

**Full Kanban board wired in LeadsIndex.vue: data loading, contact grouping by stage, and optimistic drag-drop with revert on failure**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-11T15:25:00Z
- **Completed:** 2026-04-11T15:28:00Z
- **Tasks:** 2 / 2
- **Files modified:** 2

## Accomplishments
- Extended `usePipelineStore` with `moveContactToStage({ contactId, fromStageId, toStageId })` action
  - Optimistic update: immediately updates local `contacts` and `contactsByStage` state before API call
  - Calls `ContactAPI.update(contactId, { pipeline_stage_id })` for persistence
  - On API failure: reverts local state to previous stage and shows toast error via `useAlert`
  - Handles `'unassigned'` as `pipeline_stage_id = null`
- Replaced `LeadsIndex.vue` placeholder with full Kanban board integration
  - `onMounted`: calls `pipelineStore.fetchStages()`, then fetches contacts for each stage via `store.dispatch('contacts/fetchByStage')` in parallel
  - Contacts grouped by `pipeline_stage_id` (null = unassigned) in local `contactsByStage` ref
  - `KanbanBoard` rendered with all required props: stages, contactsByStage, unassignedContacts, unassignedCount, isLoading
  - `handleDrop`: optimistic local update (immediate card move) + calls `pipelineStore.moveContactToStage`
  - On failure: contacts re-fetched to ensure consistency
  - Loading skeleton mirrors Kanban board structure

## Task Commits

1. **Task 1: Extend pipeline store with moveContactToStage action** - `fe52d083b` (feat)
2. **Task 2: Replace LeadsIndex placeholder with full Kanban board** - `1f2658a85` (feat)

## Decisions Made
None - plan executed exactly as written.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Type] Pinia store actions access state via `this`, not `state` parameter**
- **Found during:** Task 1 implementation
- **Issue:** Plan's action template referenced `state.contacts` and `state.contactsByStage` as a direct parameter, but `createPiniaStore` wraps actions so `this` refers to the store instance
- **Fix:** Used `this.contacts`, `this.contactsByStage`, `this.setUIFlag` throughout `moveContactToStage`
- **Files modified:** `app/javascript/dashboard/stores/pipeline.js`
- **Commit:** `fe52d083b`

**2. [Rule 3 - Blocking] Pinia store `createInitialState` uses array for `records`, not object**
- **Found during:** Task 1 implementation
- **Issue:** `createInitialState` in `storeFactory.js` defines `records: []` (array), but the contacts code assumes `records: {}` (object keyed by id). The pipeline store overrides state to use its own shape including `stages: []`
- **Fix:** The pipeline store correctly overrides its own state with `stages: []` and `contacts: {}`, `contactsByStage: {}`. No change needed — the store's own state definition takes precedence
- **Files modified:** None (no fix needed)
- **Commit:** N/A

## Issues Encountered
None.

## Threat Surface Scan
No new security surface introduced. Contact drag-drop uses existing Contact API endpoint with account-scoped authorization (per T-05-04). Contact data is already accessible via Chatwoot contacts API (per T-05-06).

## Next Phase Readiness
Phase 06 (Stage Management Admin UI) can build on top of this Kanban board to add in-app stage editing capabilities. The `pipelineStore.createStage`, `updateStage`, `deleteStage`, `moveStage` actions are already implemented and wired.

---
*Phase: 05-kanban-board-drag-drop plan 02*
*Completed: 2026-04-11*
