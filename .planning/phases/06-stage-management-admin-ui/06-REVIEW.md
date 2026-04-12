---
phase: 06-stage-management-admin-ui
reviewed: 2026-04-11T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - app/javascript/dashboard/components/pipeline/StageManagementModal.vue
  - app/javascript/dashboard/components/pipeline/StageFormDialog.vue
  - app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue
findings:
  critical: 1
  warning: 3
  info: 1
  total: 5
status: issues_found
---

# Phase 06: Code Review Report

**Reviewed:** 2026-04-11
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three Vue 3 SFC files were reviewed: `StageManagementModal.vue`, `StageFormDialog.vue`, and the modified `LeadsIndex.vue`. The code correctly integrates with `usePipelineStore`, follows the planned optimistic-update-with-revert pattern, and gates the admin button via `useAdmin().isAdmin`. However, one critical bug and three warnings were identified.

---

## Critical Issues

### CR-01: Optimistic state mutation leaks across all open StageManagementModal instances

**File:** `app/javascript/dashboard/components/pipeline/StageManagementModal.vue:53-60`

**Issue:** All CRUD operations in `handleSave` mutate `pipelineStore.stages` directly by array index assignment (`pipelineStore.stages[index] = updated`) or array push/filter. Because `pipelineStore` is a Pinia store with shared reactive state, these mutations persist in the global store even after the user closes the modal. If the API call fails and the revert also mutates `pipelineStore.stages`, the store state is left corrupted with a stale snapshot of `[...pipelineStore.stages]`.

**Impact:** On API failure during create/update, the revert uses the captured `previousStages` snapshot, but all other open copies of the modal see the mutated (corrupt) store state. Concurrent open modals will show incorrect stage lists.

**Fix:**
```javascript
const handleSave = async ({ name, color }) => {
  if (editingStage.value) {
    // Use a deep clone to avoid mutating the store's reactive array
    const previousStages = pipelineStore.stages.map(s => ({ ...s }));
    const index = pipelineStore.stages.findIndex(s => s.id === editingStage.value.id);
    if (index === -1) { closeFormDialog(); return; }
    pipelineStore.stages[index] = { ...editingStage.value, name, color };
    try {
      const updated = await pipelineStore.updateStage({ id: editingStage.value.id, name, color });
      // Sync with authoritative server response
      pipelineStore.stages[index] = updated;
    } catch {
      pipelineStore.stages = previousStages;
      useAlert('Failed to update stage. Please try again.');
    }
  } else {
    const tempId = `temp-${Date.now()}`;
    const tempStage = { id: tempId, name, color, position: sortedStages.value.length };
    pipelineStore.stages.push(tempStage);
    try {
      const newStage = await pipelineStore.createStage({ name, color });
      pipelineStore.stages = pipelineStore.stages.filter(s => s.id !== tempId);
      pipelineStore.stages.push(newStage);
    } catch {
      pipelineStore.stages = pipelineStore.stages.filter(s => s.id !== tempId);
      useAlert('Failed to create stage. Please try again.');
    }
  }
  closeFormDialog();
};
```

Same fix applies to `moveStage` (line 90) and `executeDelete` (line 122) -- replace `pipelineStore.stages` mutations with `pipelineStore.stages = pipelineStore.stages.map(...)` to trigger proper reactivity and avoid aliasing issues.

---

## Warnings

### WR-01: `moveStage` swap logic is asymmetric on position values

**File:** `app/javascript/dashboard/components/pipeline/StageManagementModal.vue:90-94`

**Issue:** When swapping two stages, the moving stage gets `swapWith.position` but the swapWith stage gets `s.position` (its own, which is unchanged). After the map, both stages will have the same position value -- the moving stage has the swap target's old position, and the swap target still has its original position. After `fetchStages()` refreshes from the server, this is resolved, but the local optimistic state is internally inconsistent.

```javascript
// Line 91: stage.id gets swapWith.position — correct
if (s.id === stage.id) return { ...s, position: swapWith.position };
// Line 92: swapWith.id keeps its own original position — both stages end up same
if (s.id === swapWith.id) return { ...s, position: s.position };
```

**Fix:**
```javascript
const updated = pipelineStore.stages.map(s => {
  if (s.id === stage.id) return { ...s, position: swapWith.position };
  if (s.id === swapWith.id) return { ...s, position: stage.position }; // swap to stage's position
  return s;
});
```

### WR-02: `isFirstStage` and `isLastStage` return true for empty list

**File:** `app/javascript/dashboard/components/pipeline/StageManagementModal.vue:134-142`

**Issue:** Both functions check `sorted.length === 0 || ...`. In an empty list, `isFirstStage` returns `true` and `isLastStage` returns `true` simultaneously. Since the stage list section is hidden by `v-if="sortedStages.length === 0"`, the buttons are not rendered in the empty state, so this is not exploitable today. However, it is dead code that indicates a logic error and will surface if the list-rendering condition ever changes.

**Fix:**
```javascript
const isFirstStage = stage => {
  const sorted = getSortedStages();
  return sorted.length > 0 && sorted[0].id === stage.id;
};

const isLastStage = stage => {
  const sorted = getSortedStages();
  return sorted.length > 0 && sorted[sorted.length - 1].id === stage.id;
};
```

### WR-03: `useAlert` called in catch blocks without `await` is misleading

**File:** `app/javascript/dashboard/components/pipeline/StageManagementModal.vue:61,75,101,130` and `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue:53,130`

**Issue:** `useAlert` is a synchronous fire-and-forget function (it emits via an emitter), so `await` is not needed -- but this is not obvious from the code. More critically, in `LeadsIndex.vue`, the `catch` blocks call `useAlert` and then re-throw or suppress an error. In `handleDrop` (line 184-188), the catch does not call `useAlert` at all -- it relies on `pipelineStore.moveContactToStage` to handle the toast internally, but if the store action swallowed the error, no user feedback is given.

**Fix in LeadsIndex.vue line 184:**
```javascript
} catch (error) {
  useAlert('Failed to move contact. Please try again.');
  await fetchContactsForAllStages();
  await fetchUnassignedContacts();
}
```

---

## Info

### IN-01: `StageFormDialog` uses `emit('close')` directly in template, bypassing `localShow` computed

**File:** `app/javascript/dashboard/components/pipeline/StageFormDialog.vue:47,48,86`

**Issue:** Lines 47-48 declare `:on-close="() => emit('close')"` and `@close="emit('close')"` simultaneously on the same Modal. This is redundant but harmless -- `localShow` already handles the close event via its computed setter. Line 86 calls `emit('close')` directly rather than through `localShow.value = false`, which also works but is inconsistent.

**Fix:** Remove `:on-close` from the Modal tag (already listed as auto-fixed in 06-01-SUMMARY.md) and ensure all close paths go through `localShow.value = false`:
```vue
<!-- In template -->
<Button type="button" variant="ghost" slate label="Cancel" @click="localShow = false" />
```
And simplify the Modal tag to:
```vue
<Modal v-model:show="localShow" modal-type="centered" :show-close-button="true" />
```

---

_Reviewed: 2026-04-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
