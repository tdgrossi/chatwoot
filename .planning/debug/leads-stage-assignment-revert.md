---
status: investigating
trigger: "Dragging a contact to a different stage or using dropdown selector to change stage causes immediate revert to Unassigned. No error shown."
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T18:00:00.000Z
---

## Current Focus
hypothesis: "Previous fix (read from vuexStore) was applied but something else is still wrong. Adding console.log tracing to find exactly where the failure occurs."
test: "User triggers stage change, we see full console log trace"
expecting: "Console output will show exactly which step fails"
next_action: "User to test with browser console open and report the log output"

## Symptoms
expected: Stage assignment should persist after drag or dropdown selection
actual: |
  - Drag: Visual shows move but immediately reverts to Unassigned
  - Dropdown: Selecting different stage shows briefly then reverts to Unassigned
  - No visible error message to user
errors: Unknown - check network/Sidekiq logs
reproduction: |
  1. Go to Leads page
  2. Drag contact card to different stage column
  OR
  1. Click on contact to open detail panel
  2. Use stage dropdown to select different stage
started: Unknown

## Eliminated
<!-- APPEND only -->
- hypothesis: "API endpoint doesn't accept pipeline_stage_id"
  evidence: "Controller's permitted_params includes :pipeline_stage_id. ContactAPI.update sends PATCH with pipeline_stage_id."
- hypothesis: "Backend sets pipeline_stage_id to null"
  evidence: "Contact model has belongs_to :pipeline_stage, optional: true. Permitted params accepts pipeline_stage_id."
- hypothesis: "Optimistic update not reverted"
  evidence: "handleDrop/handleSidebarStageChange catch blocks DO reload contacts. Revert IS triggered."
- hypothesis: "Sidebar contact object is wrong"
  evidence: "selectedContact is set from contactsMap which is populated from Vuex state. This is correct."
- hypothesis: "pipelineStore.contacts was wrong source"
  evidence: "Previous fix changed to vuexStore.state.contacts.records[contactId]. Still failing."

## Evidence
<!-- APPEND only -->
- timestamp: 2026-04-12T00:00
  checked: "app/javascript/dashboard/stores/pipeline.js"
  found: "`contacts: {}` is initialized but NEVER populated. moveContactToStage() does `const contact = this.contacts[contactId]` and returns early if undefined."
  implication: "The API call is never made because contact lookup fails silently."
- timestamp: 2026-04-12T00:00
  checked: "LeadsIndex.vue"
  found: "loadAllContacts() only populates Vuex store and LeadsIndex local refs (contactsMap, contactsByStage). pipelineStore.contacts is never updated."
  implication: "pipelineStore.contacts stays empty {} throughout the app lifecycle."
- timestamp: 2026-04-12T00:00
  checked: "docker compose logs --tail=50 rails"
  found: "Only POST filter requests visible. NO PATCH requests for stage changes."
  implication: "Confirms the PATCH API call is never made."
- timestamp: 2026-04-12T00:00
  checked: "LeadsIndex.vue handleDrop and handleSidebarStageChange catch blocks"
  found: "After reload, Vuex has contacts but pipelineStore.contacts still empty. Future moves also fail silently."
  implication: "Stale UI refresh triggers the catch block even on unrelated re-renders."
- timestamp: 2026-04-12T18:00
  checked: "All trace files (pipeline.js, StageColumn.vue, KanbanBoard.vue, ContactSidebar.vue, LeadsIndex.vue)"
  found: "Added console.log at every critical step: handleDragEnd -> KanbanBoard.handleDrop -> LeadsIndex.handleDrop -> pipeline.moveContactToStage -> vuexStore lookup -> API call -> catch blocks -> reload."
  implication: "Console trace will show exactly where the flow breaks or catches an error."

## Resolution
root_cause: (unknown - investigating with console.log)
fix: (unknown - investigating with console.log)
verification: (unknown - investigating with console.log)
files_changed: []
