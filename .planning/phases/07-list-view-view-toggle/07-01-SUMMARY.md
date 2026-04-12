---
phase: "07"
plan: "01"
subsystem: leads-index
tags:
  - list-view
  - view-toggle
  - kanban
  - filter
  - vue3
dependency_graph:
  requires:
    - phase-06-01
  provides:
    - "07-02"
  affects:
    - "app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue"
tech_stack:
  added:
    - DropdownMenu component (existing in-repo)
  patterns:
    - View toggle with localStorage persistence
    - Sortable table with null/asc/desc cycle
    - Filtered empty vs. truly-empty empty states
    - Sticky table header with scrollable body
key_files:
  created: []
  modified:
    - "app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue"
decisions:
  - "D-01: Icon button group (Kanban | List) in header toolbar"
  - "D-02: Plain HTML table, not BaseTable component (scoped slot pattern insufficient for row-click and sticky header)"
  - "D-03: Columns: Name, Email, Phone, Stage, Last Activity, Created At"
  - "D-04: Dropdown filter with All stages, Unassigned, then each stage"
  - "D-05: localStorage key crm_pipeline_view for view persistence"
  - "D-06: handleRowClick logs to console (Phase 8 wires to sidebar)"
  - "D-07: Default sort name asc; column click cycles null->asc->desc->null per column"
  - "D-08: Two distinct empty states: truly-empty vs. filtered-empty"
metrics:
  duration_minutes: 2
  completed_date: "2026-04-12T00:56:00Z"
  tasks_completed: 1
  files_modified: 1
  insertions: 362
  deletions: 43
---

# Phase 07 Plan 01: List View with View Toggle Summary

View toggle between Kanban and List views, with a stage filter dropdown, sortable columns, and localStorage persistence.

## Completed Tasks

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add view state, toggle buttons, and stage filter to LeadsIndex header | `8d409d850` | LeadsIndex.vue |

## What Was Built

**View Toggle:** Two adjacent icon buttons (`i-lucide-columns` / `i-lucide-list`) in a bordered group. Active button gets `bg-n-brand text-white` fill. Toggle writes `crm_pipeline_view` to localStorage on every click; value is read on mount to restore last preference. Defaults to `kanban`.

**Stage Filter Dropdown:** `DropdownMenu` trigger with `i-lucide-filter` icon and dynamic label showing current filter. Menu options: `All stages`, `Unassigned`, then each stage from `orderedStages`. Selection updates `activeFilter` ref.

**List View Table:** Full-width `<table>` with sticky `<thead>`. Columns: Name (sortable), Email (sortable), Phone (not sortable), Stage (sortable), Last Activity (sortable), Created At (sortable). Sort icon updates per direction. Stage cells render a pill badge with stage color dot.

**Empty States:**
- `contactsMap.length === 0` shows inbox icon + "No contacts yet"
- `sortedContacts.length === 0` (filtered) shows filter icon + "No contacts match your filters"

**Sorting:** `toggleSort(key)` cycles per column: `null -> 'asc' -> 'desc' -> null`. Default sort is `name` ascending on mount.

**Row Click:** `handleRowClick(contact)` logs to console. Phase 8 will open the contact detail sidebar.

**Kanban board:** Unchanged, wrapped in `v-if="activeView === 'kanban'"`. Loading skeleton shown while `isLoading`.

## Deviations from Plan

None - plan executed exactly as written.

## Deviations Auto-Applied

None.

## Auth Gates

None.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- `crm_pipeline_view` localStorage read/write: FOUND (lines 200, 211)
- `activeView` ref and toggle buttons: FOUND (lines 201, 340-356)
- `stageFilterOptions` computed: FOUND (line 215)
- `filteredContacts` computed: FOUND (line 244)
- `sortedContacts` computed: FOUND (line 253)
- `toggleSort` function: FOUND (line 264)
- `handleRowClick` function: FOUND (line 277)
- `formatDate`, `getStageName`, `getStageColor` helpers: FOUND (lines 283-304)
- `DropdownMenu` import: FOUND (line 10)
- Commit `8d409d850` exists: FOUND
