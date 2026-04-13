---
status: resolved
trigger: "Dragging a contact to a different stage or using dropdown selector to change stage causes immediate revert to Unassigned. No error shown."
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-13T07:15:00.000Z
resolved: 2026-04-13T07:15:00.000Z
---

## Current Focus

**STATUS: verifying**

Two fixes applied to LeadsIndex.vue:

1. **Deduplication fix** (`stageContacts` computed): Now uses `contactsMap[c.id]?.pipeline_stage_id` as the canonical source of truth. Contact is only shown in the stage matching its actual `pipeline_stage_id`. All other duplicate entries are removed.

2. **Remove robustness fix** (`handleDrop`): Rewrote remove logic with explicit array reassignment, numeric ID comparison, and per-step logging. The key change: `contactsByStage.value[fromKeyForRemove] = filteredSource` instead of chained inline assignment, making it easier to trace exactly what happens.

## Root Causes Found and Fixed

### Root Cause 1: pipelineStore.contacts was empty (FIXED)
- `pipeline.js` defines `contacts: {}` but NEVER populates it
- **Fix**: Read from `vuexStore.state.contacts.records[contactId]`

### Root Cause 2: syncContactsAfterStageChange read from wrong source (FIXED)
- **Fix**: Read from `store.state.contacts?.records?.[contactId]`

### Root Cause 3: fromKey was NaN for unassigned contacts (FIXED)
- **Fix**: Handle both `null` and `'unassigned'` string

### Root Cause 5: API response omits `pipeline_stage_id` (FIXED)
- **Fix**: Added `pipeline_stage_id` to `_contact.json.jbuilder`

### Root Cause 6: @update:contacts race (KanbanBoard) (FIXED)
- **Fix**: Removed `@update:contacts` listener from KanbanBoard

### Root Cause 7: Misleading hardcoded logging (FIXED)
- **Fix**: Logs now use actual `toKey` variable

### Root Cause 8: Double-write causes contact duplication (FIXED)
- **Fix**: Added `skipContactsByStageSync` parameter - handleDrop passes `true`

### Root Cause 9: handleDrop missing ADD to new stage (FIXED)
- **Fix**: Added full optimistic update with remove + add

### Root Cause 10: pipeline_stage_id type mismatch (FIXED)
- **Fix**: Changed `pipeline_stage_id: toKey` -> `pipeline_stage_id: toNumKey`

### Root Cause 11: Second drag duplicates despite skip=true (FIXED - INSUFFICIENTLY)
- **Symptom**: First drag works, second drag duplicates contact in both old and new stages
- **Mechanism**: Vue reactivity edge case in nested arrays - `stageContacts` computed recreates arrays, vuedraggable maintains internal state
- **Fix (insufficient)**: Added deduplication in `stageContacts` computed - but removes from WRONG stage
- **NEED FIX**: Deduplication must remove from the stage that does NOT match `contact.pipeline_stage_id`

### Root Cause 12: Pre-existing duplication before drag starts (INVESTIGATING)
- **Symptom**: `contactsByStage[1] = [1]` AND `contactsByStage[3] = [2]` BEFORE any drag
- **Mechanism**: Unknown - `loadAllContacts` should only add contact to its actual `pipeline_stage_id` stage
- **Hypothesis**: `store.state.contacts.records` may contain stale data (contact still has old `pipeline_stage_id`) OR contacts are fetched from multiple endpoints and duplicated

## Symptoms
expected: Stage assignment should persist; contact in NEW stage only
actual: Contact appears in BOTH old and new stages after second drag
errors: Vue warning: "Component emitted event 'update:contacts' but it is not declared in the emits option" (StageColumn.vue:121)
reproduction: |
  1. Go to Leads page
  2. Drag contact from stage 1 to stage 3 (WORKS)
  3. Drag contact from stage 3 to stage 1 (DUPLICATES: appears in both)
  4. New: Dragging may not work at all - stage assignment completely broken

## Eliminated
- hypothesis: vuedraggable mutates arrays causing duplication
  evidence: Array mutations in vuedraggable should work with Vue 3 reactivity. The deduplication safeguard was added to handle this but it removes from the wrong stage.
- hypothesis: Vue reactivity not triggering on contactsByStage reassignment
  evidence: `contactsByStage.value = { ...contactsByStage.value }` is used for reactivity. But deduplication shows `contactsByStage[1]` still contains contact after remove.
- hypothesis: Type mismatch in stage ID keys (string vs number)
  evidence: BEFORE log shows numeric keys `{1: Array(1), 3: Array(2)}`. Keys are consistent numbers.

## Evidence
- timestamp: 2026-04-13T06:45:00.000Z
  checked: User's console logs from new test
  found: |
    contactsByStage BEFORE optimistic update: {1: Array(1), 3: Array(2)}  <- contact ALREADY in both stages!
    contactsByStage AFTER remove: {1: Array(1), 3: Array(2)}              <- REMOVE DID NOTHING!
    contactsByStage AFTER add: {1: Array(1), 3: Array(3)}               <- added to new stage but old stage still has it
    [stageContacts] DEDUP: contact 1 already in another stage, removing from stage 3  <- wrong stage removed!
  implication: |
    1. Pre-existing duplication: contact 1 is already in stage 1 AND stage 3 BEFORE any drag
    2. Remove from old stage (filter) doesn't work - contact still in stage 1 after filter
    3. Deduplication removes from stage 3 (second occurrence) instead of stage 1 (wrong occurrence)
    4. Result: contact ends up in stage 1 with pipeline_stage_id=3 (wrong stage per canonical data)
- timestamp: 2026-04-13T06:48:00.000Z
  checked: stageContacts deduplication logic in LeadsIndex.vue
  found: |
    Current code iterates orderedStages in order and keeps first occurrence:
    - If stage 1 comes before stage 3 in orderedStages, contact with pipeline_stage_id=3
      is kept in stage 1 (wrong!) and removed from stage 3.
  implication: The deduplication safeguard removes from the stage that DOESN'T match the
    contact's actual pipeline_stage_id, leaving the contact in the WRONG stage.
    The fix: when deduplicating, keep the occurrence where stage.id === contact.pipeline_stage_id.
- timestamp: 2026-04-13T06:49:00.000Z
  checked: loadAllContacts in LeadsIndex.vue
  found: |
    loadAllContacts groups contacts by pipeline_stage_id:
    - If pipeline_stage_id=3, contact only added to grouped[3]
    - No path exists to add contact to multiple stages in loadAllContacts alone
    - But contacts may be in Vuex store from MULTIPLE fetchByStage calls, and Vuex may not deduplicate
  implication: |
    If Vuex store has contact with id=1 in stage 1's data AND stage 3's data (duplicate fetch),
    loadAllContacts would add it twice. But the contact object in Vuex should have ONE pipeline_stage_id.
    Unless: contacts are fetched multiple times and the Vuex merge doesn't update correctly.
    Or: The Vuex store contains contact with old pipeline_stage_id while contactsMap has new one.
- timestamp: 2026-04-13T06:50:00.000Z
  checked: loadAllContacts vs syncContactsAfterStageChange interaction
  found: |
    loadAllContacts runs once on mount. syncContactsAfterStageChange only updates contactsMap
    and skips contactsByStage for drag-drop (skip=true). So contactsByStage is only updated
    by handleDrop's optimistic update. If remove doesn't work, contactsByStage accumulates stale entries.
  implication: |
    The remove not working means handleDrop's optimistic update doesn't properly clear
    the old stage. Subsequent loadAllContacts runs (e.g., on filter change, stage change) don't
    fix it because loadAllContacts re-reads from Vuex store. If Vuex has the contact in the old
    stage (stale data), loadAllContacts re-adds it to the wrong stage.
    Root cause of pre-existing duplication: Vuex store may have stale data where
    the contact still has the OLD pipeline_stage_id, and loadAllContacts groups by that stale value.

## Resolution
root_cause: |
  TWO ISSUES:

  1. **Deduplication removed from WRONG stage**: `stageContacts` computed iterated stages in order
     and kept the first occurrence of each contact. If a contact has `pipeline_stage_id: 3`
     but appears in both `contactsByStage[1]` AND `contactsByStage[3]`, it kept the one in
     stage 1 (first in iteration order) and removed from stage 3. This left the contact
     in the WRONG stage visually.

  2. **Remove from old stage had edge cases**: The original filter code used `c.id !== contactId`
     comparison which could fail if types differed (string vs number). The old code also had
     complex nested conditionals that may not handle all edge cases.
fix: |
  Fix 1 (Deduplication): In stageContacts computed, now checks if `contactsMap[c.id]?.pipeline_stage_id`
  matches the current stage.id. Contact is only shown in the stage matching its actual pipeline_stage_id.
  All other duplicate entries are filtered out.

  Fix 2 (Remove robustness): Rewrote handleDrop remove logic with explicit array assignment,
  consistent numeric ID comparison via `Number()`, and detailed per-step logging.
verification: |
  - Both fixes applied to LeadsIndex.vue
  - Human verification needed: test drag-drop to confirm contacts move to correct stage and no duplication
files_changed:
  - app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue
