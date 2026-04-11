---
phase: "04-frontend-infrastructure"
plan: "01"
subsystem: "api-clients"
tags: [api, vuex, frontend, infrastructure]
dependency_graph:
  requires: []
  provides:
    - path: "app/javascript/dashboard/api/pipelineStages.js"
      exports: "PipelineStagesAPI singleton"
    - path: "app/javascript/dashboard/api/pipelineStats.js"
      exports: "PipelineStatsAPI singleton"
    - path: "app/javascript/dashboard/store/modules/contacts/actions.js"
      exports: "fetchByStage action"
    - path: "app/javascript/dashboard/store/modules/contacts/mutations.js"
      exports: "SET_CONTACTS_BY_STAGE mutation"
  affects:
    - path: "app/javascript/dashboard/store/modules/contacts/actions.js"
    - path: "app/javascript/dashboard/store/modules/contacts/mutations.js"
    - path: "app/javascript/dashboard/store/mutation-types.js"
tech_stack:
  added:
    - "pipelineStages.js - API client"
    - "pipelineStats.js - API client"
  patterns:
    - "ApiClient singleton pattern"
    - "Vuex action with filter API + SET_CONTACTS_BY_STAGE mutation"
key_files:
  created:
    - "app/javascript/dashboard/api/pipelineStages.js"
    - "app/javascript/dashboard/api/pipelineStats.js"
  modified:
    - "app/javascript/dashboard/store/mutation-types.js"
    - "app/javascript/dashboard/store/modules/contacts/mutations.js"
    - "app/javascript/dashboard/store/modules/contacts/actions.js"
decisions:
  - "ApiClient singleton pattern reused from companies.js/contacts.js"
  - "fetchByStage uses SET_CONTACTS_BY_STAGE (merge) rather than SET_CONTACTS (clear) to preserve existing contacts"
  - "move(id, direction) uses axios.patch directly since no base CRUD method covers it"
metrics:
  duration: "~2 minutes"
  tasks_completed: 2
  files_created: 2
  files_modified: 3
  commits: 2
completed_date: "2026-04-11"
---

# Phase 04 Plan 01 Summary: Frontend Infrastructure - API Clients and Vuex Store

## One-liner

PipelineStagesAPI and PipelineStatsAPI singletons with a fetchByStage Vuex action that merges stage-filtered contacts into the existing store.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | API clients | 45a08348a | pipelineStages.js, pipelineStats.js |
| 2 | Contacts store extension | c8c854720 | mutation-types.js, mutations.js, actions.js |

## What Was Built

### Task 1: API Clients

**`app/javascript/dashboard/api/pipelineStages.js`**
- Extends `ApiClient` with `super('pipeline_stages', { accountScoped: true })`
- Adds `move(id, direction)` method that patches `${this.url}/${id}/move` with `{ direction }`
- Base CRUD (get, show, create, update, delete) inherited from ApiClient
- Exported as singleton

**`app/javascript/dashboard/api/pipelineStats.js`**
- Extends `ApiClient` with `super('pipeline_stats', { accountScoped: true })`
- Read-only client (no custom methods beyond inherited CRUD)
- Exported as singleton

### Task 2: Contacts Vuex Module Extension

**`app/javascript/dashboard/store/mutation-types.js`**
- Added `SET_CONTACTS_BY_STAGE: 'SET_CONTACTS_BY_STAGE'` in the Contacts section (between CLEAR_CONTACTS and EDIT_CONTACT)

**`app/javascript/dashboard/store/modules/contacts/mutations.js`**
- Added `[types.SET_CONTACTS_BY_STAGE]` mutation that merges contacts into `$state.records` without clearing existing records, and appends new IDs to `$state.sortOrder` if not already present

**`app/javascript/dashboard/store/modules/contacts/actions.js`**
- Added `fetchByStage: async ({ commit }, { stageId, page = 1, sortAttr = 'name' })`
- Calls `ContactAPI.filter(page, sortAttr, { pipeline_stage_id: stageId })`
- Commits `SET_CONTACTS_BY_STAGE` (merge, not clear) so other contacts in the store are preserved
- Sets `isFetching` UI flag correctly

## Deviations from Plan

None - plan executed exactly as written.

## Threat Surface

No new threat surface introduced. All API calls are account-scoped via the `accountScoped: true` pattern. Input (stageId) flows through Rails parameterized queries.

## Commits

- `c8c854720` feat(phase-04-01): add PipelineStagesAPI and PipelineStatsAPI clients
- `45a08348a` feat(phase-04-01): add fetchByStage action to contacts Vuex store

## Self-Check

- [x] pipelineStages.js exists with class PipelineStagesAPI and export singleton
- [x] pipelineStats.js exists with class PipelineStatsAPI and export singleton
- [x] PipelineStagesAPI has move(id, direction) patching `${this.url}/${id}/move`
- [x] Both classes use accountScoped: true
- [x] mutation-types.js has SET_CONTACTS_BY_STAGE
- [x] mutations.js has SET_CONTACTS_BY_STAGE handler merging into records
- [x] actions.js has fetchByStage action with ContactAPI.filter({ pipeline_stage_id: stageId })
- [x] fetchByStage commits SET_CONTACTS_BY_STAGE (not SET_CONTACTS)
- [x] fetchByStage commits SET_CONTACT_UI_FLAG with isFetching true/false
- [x] Both tasks committed individually
- [x] Commits verified in git log

## Self-Check: PASSED
