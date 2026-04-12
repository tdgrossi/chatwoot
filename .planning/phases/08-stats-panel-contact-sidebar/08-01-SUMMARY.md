---
phase: 08-stats-panel-contact-sidebar
plan: '01'
subsystem: ui
tags: [vue3, pipeline, stats, kanban, sidebar, drag-drop, optimistic-update]

# Dependency graph
requires:
  - phase: 05-kanban-board-drag-drop
    provides: KanbanBoard with drag-drop, contactsByStage local state, handleDrop with optimistic update
  - phase: 07-list-view-view-toggle
    provides: LeadsIndex with view toggle, list table, stage filter, handleRowClick stub
provides:
  - PipelineStatsPanel: horizontal stats cards row with per-stage counts, Total, Added Today
  - ContactSidebar: overlay sidebar with contact details and stage dropdown
  - LeadIndex wiring: stats panel above Kanban/list, sidebar open on card/row click, state sync after stage change
affects:
  - phase: 09-future-phases (any feature needing pipeline contact context)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Optimistic local state sync: pipelineStore updates its own state; LeadsIndex local refs must be synced after every moveContactToStage call
    - Custom inline dropdown: DropdownMenu slot not used; custom-styled inline dropdown list with color dots for sidebar stage selector
    - Teleport-to-body sidebar: renders via Teleport to body with fixed overlay, avoids z-index stacking context issues

key-files:
  created:
    - app/javascript/dashboard/components/pipeline/PipelineStatsPanel.vue
    - app/javascript/dashboard/components/pipeline/ContactSidebar.vue
  modified:
    - app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue

key-decisions:
  - "PipelineStatsPanel calls pipelineStore.fetchStats() in onMounted with length guard to avoid double-fetch"
  - "ContactSidebar uses custom inline dropdown list (not DropdownMenu component slot) for color dot + stage name rendering"
  - "syncContactsAfterStageChange() called after both handleSidebarStageChange and handleDrop moveContactToStage success paths"
  - "Sidebar stage dropdown includes 'Unassigned' (value: null) as first option per D-05"
  - "Sidebar decoupled from store: emits stage-change event; parent (LeadsIndex) calls pipelineStore.moveContactToStage()"

patterns-established:
  - "Pattern: Stats card row above Kanban/list — stats panel positioned between header and Kanban/list, full width, horizontal flex row"
  - "Pattern: Sidebar overlay via Teleport — fixed right panel with backdrop overlay, click-outside-to-close"
  - "Pattern: Critical sync fix (Pitfall #2) — pipelineStore and LeadsIndex local state diverge after moveContactToStage; syncContactsAfterStageChange bridges them"

requirements-completed: [CRM-11, CRM-12]

# Metrics
duration: 96min
completed: 2026-04-12
---

# Phase 08 Plan 01: Stats Panel and Contact Sidebar Summary

**Stats panel cards row above Kanban/list + contact sidebar overlay with stage dropdown and critical state sync fix.**

## Performance

- **Duration:** 96 min
- **Started:** 2026-04-12T00:00:00Z
- **Completed:** 2026-04-12T01:36:50Z
- **Tasks:** 3 completed
- **Files modified:** 3

## Accomplishments

### Task 1: PipelineStatsPanel.vue (commit: d5ed9fc22)
- Horizontal stats cards row between header and Kanban/list
- Per-stage cards with color dot, name, count (clickable, filters activeFilter)
- Total and Added Today summary cards (non-clickable)
- Skeleton cards with `bg-n-slate-3 animate-pulse` while loading
- Empty state with bar chart icon when no stats
- `pipelineStore.fetchStats()` called in onMounted with `stats.length` guard

### Task 2: ContactSidebar.vue (commit: ae4575ae1)
- Fixed right panel via Teleport to body with backdrop overlay
- Contact header with Avatar + name, email/phone/last activity fields
- Pipeline Stage dropdown with all stages + Unassigned option
- Custom inline dropdown list (custom-styled, not DropdownMenu slot) with color dots
- Emits `stage-change({ toStageId })` and `close` events
- Sidebar decoupled: does NOT call pipelineStore directly; parent handles store call

### Task 3: LeadsIndex.vue wiring + sync fix (commit: bcf0bfac5)
- PipelineStatsPanel rendered above Kanban/list with `@filter-change="handleStatsFilterChange"`
- ContactSidebar rendered with `v-if="isSidebarOpen && selectedContact"`, receives contact, @close, @stage-change
- handleCardClick and handleRowClick open sidebar (replaced console.log stubs)
- handleStatsFilterChange updates activeFilter from stats panel card clicks
- handleSidebarStageChange: optimistic local update + pipelineStore.moveContactToStage() + syncContactsAfterStageChange()
- handleDrop also calls syncContactsAfterStageChange after moveContactToStage succeeds
- Critical sync fix: syncContactsAfterStageChange bridges pipelineStore state and LeadsIndex local refs (contactsMap, contactsByStage)

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None - all new surface (stat cards, sidebar overlay, stage dropdown) operates within existing Chatwoot authorization model; no new network endpoints, no new auth paths, no schema changes.

## Known Stubs

None.

## Self-Check: PASSED

Files exist:
- `app/javascript/dashboard/components/pipeline/PipelineStatsPanel.vue` - FOUND
- `app/javascript/dashboard/components/pipeline/ContactSidebar.vue` - FOUND
- `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue` - FOUND

Commits exist:
- `d5ed9fc22` (PipelineStatsPanel) - FOUND
- `ae4575ae1` (ContactSidebar) - FOUND
- `bcf0bfac5` (LeadsIndex wiring) - FOUND
