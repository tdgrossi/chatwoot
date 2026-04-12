# Phase 8: Stats Panel & Contact Sidebar - Research

**Researched:** 2026-04-12
**Domain:** Vue 3 SPA frontend — stats panel + contact sidebar overlay
**Confidence:** HIGH

## Summary

Phase 8 adds two self-contained UI pieces to the LeadsIndex page: a stats panel showing per-stage contact counts, and a contact detail sidebar with a pipeline stage dropdown. All data is already available in the codebase — `usePipelineStore.fetchStats()` returns `[{stage_id, name, count, added_today}]`, `pipelineStore.stages` has all stages, `pipelineStore.moveContactToStage()` handles optimistic updates with revert + toast, and `contactsMap` in LeadsIndex holds all loaded contacts in memory. The only real work is composing existing pieces and wiring `handleCardClick`/`handleRowClick` to open a sidebar overlay.

**Primary recommendation:** Build a `PipelineStatsPanel.vue` component that calls `pipelineStore.fetchStats()` on mount and renders skeleton cards while loading, then add a `ContactSidebar.vue` component opened via a ref-controlled `isSidebarOpen` in LeadsIndex, using `DropdownMenu.vue` for the stage selector and `pipelineStore.moveContactToStage()` for optimistic stage reassignment.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions
All D-01 through D-09 decisions from 08-CONTEXT.md are locked:

- **D-01:** Card-per-stage + Total + Added Today summary cards in horizontal row
- **D-02:** Stats panel between header and Kanban/list view
- **D-03:** Minimal sidebar with stage dropdown + basic contact info
- **D-04:** Click contact opens sidebar, overlay/close dismisses
- **D-05:** Dropdown with stage options + Unassigned, current stage highlighted
- **D-06:** Optimistic update with revert + toast on failure
- **D-07:** No extra API call — use in-memory contact + pipelineStore stages
- **D-08:** Store-level reactive update, no page reload
- **D-09:** Skeleton cards while loading

### Claude's Discretion
None — all decisions were made during discuss-phase.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CRM-11 | Volume-per-stage statistics | `pipelineStore.fetchStats()` returns `[{stage_id, name, count, added_today}]` — consumed directly by stats panel |
| CRM-12 | Contact detail stage selector | `pipelineStore.moveContactToStage()` handles API call + optimistic update + revert + toast — reused in sidebar dropdown |
| CRM-13 | Unassigned column for NULL stage | Already implemented in KanbanBoard (Phase 5); not part of Phase 8 scope beyond showing in stats panel |
</phase_requirements>

---

## Standard Stack

No new packages required. All dependencies are already in the project.

| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| Vue 3 | 3.5.12 | Component framework | CLAUDE.md |
| Pinia | 3.0.4 | State management — `usePipelineStore` | CLAUDE.md |
| Vuex 4 | 4.1.0 | Legacy store — contacts data | CLAUDE.md |
| Tailwind CSS | 3.4.19 | Utility-first CSS | CLAUDE.md |
| DropdownMenu.vue | (components-next) | Reused for stage dropdown | CONTEXT.md canonical_refs |
| useAlert | (composables) | Toast notifications on optimistic failure | CONTEXT.md canonical_refs |
| usePipelineStore | (stores/pipeline.js) | Stats, stages, moveContactToStage | CONTEXT.md canonical_refs |
| ContactAPI.update | (api/contacts.js) | PATCH contact with pipeline_stage_id | Verified in codebase |

**Installation:** No new packages needed.

---

## Architecture Patterns

### Project Structure

```
app/javascript/dashboard/
├── routes/dashboard/leads/pages/
│   └── LeadsIndex.vue              # Phase 5/7: wire handleCardClick/handleRowClick to open sidebar
├── components/
│   ├── kanban/
│   │   └── KanbanBoard.vue         # Phase 5: emits 'card-click' with contact object
│   └── pipeline/
│       └── StageManagementModal.vue # Phase 6: modal pattern (reference only)
└── components-next/
    ├── dropdown-menu/
    │   └── DropdownMenu.vue        # Reused for sidebar stage selector
    └── Contacts/
        └── ContactsDetailsLayout.vue # Sidebar slot pattern (reference)
```

**New files for Phase 8:**
```
app/javascript/dashboard/components/pipeline/
├── PipelineStatsPanel.vue          # Stats cards + skeleton loader
└── ContactSidebar.vue              # Sidebar overlay with stage dropdown
```

### Pattern 1: Stats Panel Composition

**What:** A component that fetches stats on mount and renders one card per stage plus summary cards.
**When to use:** Stats panel at top of LeadsIndex.
**Source:** `pipelineStore.fetchStats()` response shape — verified in `stores/pipeline.js` lines 75-85:
```javascript
// Source: app/javascript/dashboard/stores/pipeline.js (lines 75-85)
async fetchStats() {
  this.setUIFlag({ fetchingList: true });
  try {
    const response = await PipelineStatsAPI.get();
    this.stats = response.data || [];
    this.setUIFlag({ fetchingList: false });
  } catch (error) {
    throwErrorMessage(error);
    this.setUIFlag({ fetchingList: false });
  }
}
```
API response is `PipelineStatsAPI.get()` → `response.data` (array of `{stage_id, name, count, added_today}` from Phase 3 CONTEXT.md confirmed). Stats are camelCased via `getStats` getter (line 32):
```javascript
getStats: state => camelcaseKeys(state.stats, { deep: true }),
```
`uiFlags.fetchingList` is set during fetch — use this to drive skeleton state.

**Layout:** Horizontal flex row, full-width, between header div and Kanban/list template sections. Card styling per UI-SPEC: `bg-n-surface-2 border border-n-weak rounded-lg p-4`.

### Pattern 2: Sidebar Overlay via Ref (no router change)

**What:** A sidebar opened by setting a `ref(true/false)` — no route change, no `ContactsDetailsLayout` wrapper needed.
**When to use:** Phase 8 sidebar is an overlay on the LeadsIndex page, not a full page navigation.
**Why not router:** Sidebar should overlay the current view without navigation. Phase 7 spec says "Clicking a contact row opens the existing contact detail sidebar" — this means a slide-in panel on the same page.
**Source:** Derived from `ContactsDetailsLayout.vue` mobile sidebar pattern (lines 138-188 in that file), simplified for LeadsIndex:
```vue
<!-- Trigger in LeadsIndex -->
<ContactSidebar
  v-if="isSidebarOpen"
  :contact="selectedContact"
  @close="isSidebarOpen = false"
/>
```

### Pattern 3: Optimistic Stage Update (reused from Phase 5)

**What:** Dropdown selection immediately updates local state, then calls `pipelineStore.moveContactToStage()` which handles API + revert.
**When to use:** Sidebar stage dropdown change.
**Source:** `stores/pipeline.js` lines 140-213 — verified in codebase. Key contract:
```javascript
// Source: app/javascript/dashboard/stores/pipeline.js (lines 140-175)
async moveContactToStage({ contactId, fromStageId, toStageId }) {
  this.setUIFlag({ updatingContact: true });
  try {
    // Optimistic update: update local state immediately
    const contact = this.contacts[contactId];
    const previousStageId = contact.pipeline_stage_id;
    const updatedContact = {
      ...contact,
      pipeline_stage_id: toStageId === 'unassigned' ? null : toStageId,
    };
    this.contacts[contactId] = updatedContact;
    // ... update contactsByStage ...
    await ContactAPI.update(contactId, { pipeline_stage_id: ... });
    this.setUIFlag({ updatingContact: false });
  } catch (error) {
    // Revert + useAlert toast (lines 178-212)
  }
}
```

**Critical gap:** `pipelineStore.moveContactToStage()` updates `this.contacts[contactId]` and `this.contactsByStage`, but LeadsIndex maintains its own `contactsMap` and `contactsByStage` refs (lines 22-44 of LeadsIndex.vue). After sidebar stage change, the Kanban/list view may not re-render because LeadsIndex's local refs are not updated by the store action. See Pitfall #2 below.

### Pattern 4: Skeleton Loader

**What:** `bg-n-slate-3 animate-pulse` placeholder matching card shape during load.
**When to use:** Stats panel loading state.
**Source:** Phase 5 Kanban skeleton (LeadsIndex.vue lines 376-399) and UI-SPEC line 125-127.

### Pattern 5: DropdownMenu Reuse for Stage Selector

**What:** `DropdownMenu.vue` with `menuItems` array of `{action, value, label, isSelected}`.
**When to use:** Sidebar stage dropdown — `action='select-stage'`, `value=stageId`, `label=stage.name`, `isSelected=contact.pipeline_stage_id === stage.id`.
**Source:** Phase 7 stage filter uses this pattern (LeadsIndex.vue lines 316-330). DropdownMenu.vue (lines 14-16) validates items must have `action`, `value`, `label`.
**Sidebar dropdown needs "Unassigned" option:** Add `{action: 'select-stage', value: null, label: 'Unassigned', isSelected: !contact.pipeline_stage_id}`.

### Pattern 6: useAlert Composable

**What:** `useAlert(message)` emits a toast via mitt emitter.
**When to use:** Reverting sidebar dropdown change (though `moveContactToStage` handles its own alert).
**Source:** `composables/index.js` line 22-24 — verified in codebase:
```javascript
// Source: app/javascript/dashboard/composables/index.js (lines 22-24)
export const useAlert = (message, action = null) => {
  emitter.emit('newToastMessage', { message, action });
};
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Toast notifications | Custom toast component | `useAlert()` composable | Already integrated with Chatwoot's toast system via mitt emitter |
| Stage dropdown | Custom select component | `DropdownMenu.vue` | Already in components-next, handles sections, search, thumbnails |
| Contact API calls | Custom axios wrapper | `ContactAPI.update()` | Already handles `PATCH /accounts/:id/contacts/:id` with account scoping |
| Stats fetching | Custom fetch logic | `pipelineStore.fetchStats()` | Already camelCases response, handles loading state |
| Sidebar transitions | Custom CSS transitions | Vue `<Transition>` + Tailwind | Established in ContactsDetailsLayout.vue mobile sidebar |

---

## Common Pitfalls

### Pitfall 1: Sidebar reads from wrong contact source
**What goes wrong:** Sidebar shows stale or missing contact data after drag-drop or filter changes.
**Why it happens:** LeadsIndex maintains `contactsMap` as a local ref (line 22). `pipelineStore.contacts` is a separate object (store lines 18). The sidebar receives the contact from `handleCardClick(contact)` (the actual contact object from KanbanBoard), which is the Vuex store object — not necessarily the same reference as `contactsMap[contactId]` if the contact was updated elsewhere.
**How to avoid:** The sidebar receives the contact object as a prop from `handleCardClick`, which passes the contact directly from the Kanban board's props. The contact passed will always be the current object reference from the store. Do NOT look up from `contactsMap` by ID in the sidebar — use the prop directly.
**Warning signs:** Sidebar shows old stage after drag-drop even though Kanban moved the card correctly.

### Pitfall 2: Kanban/List doesn't re-render after sidebar stage update
**What goes wrong:** After sidebar stage change, the card disappears from the current view but doesn't appear in the new stage column.
**Why it happens:** `pipelineStore.moveContactToStage()` updates `store.contacts[contactId]` and `store.contactsByStage`, but LeadsIndex has its own reactive refs `contactsMap` and `contactsByStage` (lines 22-44) that are NOT connected to the store. The KanbanBoard renders from LeadsIndex's local `contactsByStage` ref, not from the store.
**How to avoid:** After `pipelineStore.moveContactToStage()` succeeds, sync the local LeadsIndex refs back from the store:
```javascript
// After store action in handleSidebarStageChange:
const updatedContact = pipelineStore.contacts[contactId];
contactsMap.value[contactId] = updatedContact;
// Update contactsByStage to match store
pipelineStore.contactsByStage; // read from store and sync to local
```
OR: Make LeadsIndex read from `pipelineStore.contactsByStage` directly instead of maintaining a local copy — but this requires refactoring the Phase 5 drag-drop logic that depends on local refs.
**Recommended approach:** After store action resolves, manually sync `contactsMap.value[contactId]` and update `contactsByStage.value` for both the source and destination stage keys. See code example below.

### Pitfall 3: Stats panel fetches on every mount without dedup
**What goes wrong:** Stats panel re-fetches every time LeadsIndex mounts, even if stats are already loaded.
**Why it happens:** `fetchStats()` is called in the stats panel component's `onMounted`. LeadsIndex also calls `fetchStages()` in its own `onMounted` — but does not call `fetchStats()`.
**How to avoid:** Call `pipelineStore.fetchStats()` in LeadsIndex `onMounted` alongside `loadStages()`, and have `PipelineStatsPanel` consume `pipelineStore.stats` reactively without its own fetch. OR have `PipelineStatsPanel` call `fetchStats()` but only if `pipelineStore.stats.length === 0` (guard against re-fetching on re-mount).
**Decision per D-07/D-08:** Stats panel consumes `pipelineStore.stats` — LeadsIndex should call `pipelineStore.fetchStats()` in its `onMounted`.

### Pitfall 4: DropdownMenu closes on outside click even during optimistic update
**What goes wrong:** Dropdown closes immediately on click, but the API call is still pending. If it fails, the revert happens silently and the dropdown reverts to old value, causing visual flicker.
**Why it happens:** DropdownMenu emits `action` on item click, which triggers the store action. The dropdown closes immediately because that's the default behavior.
**How to avoid:** Accept this — the optimistic update shows the new value immediately in the dropdown trigger (via local state), so the user sees the new stage. The revert on failure causes another render update. This is the same behavior as drag-drop in Phase 5.

### Pitfall 5: Sidebar stage dropdown doesn't include "Unassigned" as a selectable option
**What goes wrong:** Users cannot move a contact back to unassigned from the sidebar.
**Why it happens:** `pipelineStore.stages` only contains actual stage objects, not a null/unassigned entry.
**How to avoid:** Always add `{action: 'select-stage', value: null, label: 'Unassigned', isSelected: !contact.pipeline_stage_id}` as the first item in the sidebar dropdown's `menuItems` array. The store action handles `value: null` correctly (lines 154, 166, 174 in pipeline.js).

---

## Code Examples

### Stats Panel Skeleton + Reactive Cards
```vue
<!-- Source: PipelineStatsPanel.vue (new component) -->
<script setup>
import { onMounted, computed } from 'vue';
import { usePipelineStore } from '../../stores/pipeline';

const pipelineStore = usePipelineStore();

const isLoading = computed(() => pipelineStore.uiFlags.fetchingList);
const stats = computed(() => pipelineStore.getStats); // camelCased via getter

onMounted(async () => {
  if (!stats.value.length) {
    await pipelineStore.fetchStats();
  }
});
</script>

<template>
  <div class="flex gap-4 px-4 py-3 border-b border-n-weak overflow-x-auto">
    <!-- Skeleton state -->
    <template v-if="isLoading">
      <div v-for="i in 4" :key="i" class="flex-shrink-0 w-32 h-16 bg-n-slate-3 rounded-lg animate-pulse" />
    </template>
    <!-- Stats cards -->
    <template v-else>
      <div
        v-for="stat in stats"
        :key="stat.stageId"
        class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4 cursor-pointer hover:shadow-md transition-shadow"
      >
        <div class="flex items-center gap-1.5 mb-2">
          <span class="w-2 h-2 rounded-full" :style="{ backgroundColor: stat.color }" />
          <span class="text-xs font-medium text-n-slate-11 truncate">{{ stat.name }}</span>
        </div>
        <div class="text-2xl font-semibold text-n-slate-12">{{ stat.count }}</div>
      </div>
      <!-- Total card -->
      <div class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4">
        <div class="text-xs font-medium text-n-slate-11 mb-2">Total</div>
        <div class="text-2xl font-semibold text-n-slate-12">
          {{ stats.reduce((sum, s) => sum + (s.count || 0), 0) }}
        </div>
      </div>
      <!-- Added Today card -->
      <div class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4">
        <div class="text-xs font-medium text-n-slate-11 mb-2">Added Today</div>
        <div class="text-2xl font-semibold text-n-slate-12">
          {{ stats.reduce((sum, s) => sum + (s.addedToday || 0), 0) }}
        </div>
      </div>
    </template>
  </div>
</template>
```

### Sidebar Stage Dropdown Menu Items
```javascript
// Source: ContactSidebar.vue (new component)
const stageOptions = computed(() => {
  const options = [
    {
      action: 'select-stage',
      value: null,  // Unassigned
      label: 'Unassigned',
      isSelected: !props.contact.pipeline_stage_id,
    },
    ...pipelineStore.stages.map(stage => ({
      action: 'select-stage',
      value: stage.id,
      label: stage.name,
      isSelected: props.contact.pipeline_stage_id === stage.id,
    })),
  ];
  return options;
});
```

### LeadsIndex Sidebar Integration
```javascript
// Source: LeadsIndex.vue additions (lines ~16, ~193, ~277)
const selectedContact = ref(null);
const isSidebarOpen = ref(false);

const handleCardClick = contact => {
  selectedContact.value = contact;
  isSidebarOpen.value = true;
};

const handleRowClick = contact => {
  selectedContact.value = contact;
  isSidebarOpen.value = true;
};

// In template, add after header div (before Kanban/list):
<PipelineStatsPanel />

<ContactSidebar
  v-if="isSidebarOpen"
  :contact="selectedContact"
  @close="isSidebarOpen = false"
/>
```

### Sync Local State After Store Action
```javascript
// Source: LeadsIndex.vue — after store moveContactToStage resolves
const handleSidebarStageChange = async ({ value: toStageId }) => {
  const contact = selectedContact.value;
  const fromStageId = contact.pipeline_stage_id;

  // Optimistic local update
  contactsMap.value[contact.id] = {
    ...contact,
    pipeline_stage_id: toStageId,
  };

  try {
    await pipelineStore.moveContactToStage({
      contactId: contact.id,
      fromStageId,
      toStageId,
    });
    // Sync back from store (Pitfall #2 mitigation)
    const updated = pipelineStore.contacts[contact.id];
    if (updated) {
      contactsMap.value[contact.id] = updated;
    }
    // Update local contactsByStage
    const fromKey = fromStageId;
    const toKey = toStageId;
    // Remove from source
    if (fromKey !== null && contactsByStage.value[fromKey]) {
      contactsByStage.value[fromKey] = contactsByStage.value[fromKey]
        .filter(c => c.id !== contact.id);
    }
    // Add to destination
    if (!contactsByStage.value[toKey]) {
      contactsByStage.value[toKey] = [];
    }
    if (!contactsByStage.value[toKey].find(c => c.id === contact.id)) {
      contactsByStage.value[toKey].push(updated || contactsMap.value[contact.id]);
    }
    contactsByStage.value = { ...contactsByStage.value }; // force reactivity
  } catch (error) {
    // revert local
    contactsMap.value[contact.id] = contact;
  }
};
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded pipeline UI | Phases 1-8 modular pipeline | Phase 1 (2026-04-10) | Contacts get pipeline_stage_id |
| Stats fetched per component | Centralized `pipelineStore.fetchStats()` | Phase 4 (planned) | Single source of truth for stats |
| Route-based contact detail | In-page sidebar overlay | Phase 8 (this phase) | No navigation, stays in Kanban/list context |
| DropdownMenu for filter only | DropdownMenu for filter + sidebar selector | Phase 7/8 | Reuse over duplication |

---

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `PipelineStatsAPI.get()` returns `response.data` as array `[{stage_id, name, count, added_today}]` | Standard Stack / Pattern 1 | Phase 3 confirmed API shape in CONTEXT.md; Phase 3 CONTEXT.md explicitly states the response shape. Verified by Phase 3 controller implementation (not read directly — planner should verify Phase 3 controller returns the documented shape). |
| A2 | `pipelineStore.contacts` (store) and `contactsMap` (LeadsIndex local) are separate objects that can diverge | Pitfall #2 | This is verified by reading LeadsIndex.vue — it creates local refs. Risk: if Phase 5 already wired the store to KanbanBoard via props, the KanbanBoard might read from store directly, making local ref divergence moot. Planner should verify KanbanBoard's data source before deciding sync strategy. |
| A3 | Stats panel calls `pipelineStore.fetchStats()` in `onMounted` — not deduplicated by existing call | Pitfall #3 | LeadsIndex.vue `onMounted` calls `loadStages()` but NOT `fetchStats()`. Risk: if stats are fetched elsewhere (e.g., a parent component), double-fetch occurs. Low risk — double-fetch is harmless. |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

---

## Open Questions

1. **How to sync LeadsIndex local state after `pipelineStore.moveContactToStage()`?**
   - What we know: `pipelineStore.moveContactToStage()` updates store state but LeadsIndex has its own local `contactsMap` and `contactsByStage` refs. KanbanBoard renders from local refs passed as props.
   - What's unclear: Whether KanbanBoard can be made to read from `pipelineStore.contactsByStage` directly (refactoring Phase 5's prop-passing pattern), or whether the manual sync approach (Pitfall #2 mitigation) is preferred.
   - Recommendation: Planner should evaluate both options. Option A (refactor KanbanBoard to read from store) is cleaner but touches Phase 5 code. Option B (manual sync in LeadsIndex) is more surgical. The plan should pick one and document the trade-off.

2. **Should PipelineStatsPanel fetch stats or consume existing store data?**
   - What we know: `pipelineStore.fetchStats()` exists and sets `state.stats`. `pipelineStore.uiFlags.fetchingList` tracks loading state.
   - What's unclear: Who calls `fetchStats()` — should it be in LeadsIndex `onMounted` alongside `loadStages()`, or in `PipelineStatsPanel` `onMounted`?
   - Recommendation: Call `pipelineStore.fetchStats()` in `PipelineStatsPanel` `onMounted` with guard `if (!stats.value.length)` to avoid redundant fetches on component re-mount.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — purely frontend code changes; no new npm packages, no new CLI tools, no database migrations).

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest 3.0.5 |
| Config file | `vite.config.ts` (`test` key, lines 92-120) |
| Quick run command | `pnpm vitest run app/javascript/dashboard/components/pipeline --reporter=verbose` |
| Full suite command | `pnpm vitest run --pool=threads` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CRM-11 | Stats panel shows per-stage counts from `pipelineStore.getStats` | unit | `pnpm vitest run app/javascript/dashboard/components/pipeline/PipelineStatsPanel.spec.js -x` | Wave 0 |
| CRM-11 | Stats panel skeleton cards shown while `uiFlags.fetchingList` is true | unit | `pnpm vitest run app/javascript/dashboard/components/pipeline/PipelineStatsPanel.spec.js -x` | Wave 0 |
| CRM-11 | Stats panel "Total" = sum of all stage counts | unit | `pnpm vitest run app/javascript/dashboard/components/pipeline/PipelineStatsPanel.spec.js -x` | Wave 0 |
| CRM-11 | Stats panel "Added Today" = sum of all `addedToday` values | unit | `pnpm vitest run app/javascript/dashboard/components/pipeline/PipelineStatsPanel.spec.js -x` | Wave 0 |
| CRM-12 | Sidebar renders contact name, email, phone | unit | `pnpm vitest run app/javascript/dashboard/components/pipeline/ContactSidebar.spec.js -x` | Wave 0 |
| CRM-12 | Sidebar stage dropdown shows all stages + Unassigned option | unit | `pnpm vitest run app/javascript/dashboard/components/pipeline/ContactSidebar.spec.js -x` | Wave 0 |
| CRM-12 | Sidebar stage dropdown change calls `pipelineStore.moveContactToStage()` | unit (mock store) | `pnpm vitest run app/javascript/dashboard/components/pipeline/ContactSidebar.spec.js -x` | Wave 0 |
| CRM-12 | Sidebar opens when contact card/row clicked in LeadsIndex | unit | `pnpm vitest run app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.spec.js -x` | Wave 0 |
| CRM-12 | Sidebar closes when close button clicked | unit | `pnpm vitest run app/javascript/dashboard/components/pipeline/ContactSidebar.spec.js -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `pnpm vitest run app/javascript/dashboard/components/pipeline/ --reporter=verbose`
- **Per wave merge:** `pnpm vitest run app/javascript/dashboard/routes/dashboard/leads/ --reporter=verbose`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `app/javascript/dashboard/components/pipeline/PipelineStatsPanel.spec.js` — covers CRM-11
- [ ] `app/javascript/dashboard/components/pipeline/ContactSidebar.spec.js` — covers CRM-12
- [ ] `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.spec.js` — covers sidebar integration
- [ ] `app/javascript/dashboard/components/pipeline/` — directory created
- Vitest already configured (`vite.config.ts` lines 92-120); `vitest.setup.js` confirmed via `setupFiles: ['fake-indexeddb/auto', 'vitest.setup.js']`

---

## Security Domain

> Required when `security_enforcement` is enabled (absent = enabled). Omit only if explicitly `false` in config.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | Account-scoped API (all endpoints use `accountScoped: true` on ApiClient); contacts scoped to current account via Chatwoot's existing authorization |
| V5 Input Validation | yes | Stage ID dropdown values come from `pipelineStore.stages` (server-authoritative); no user text input in stats panel or sidebar stage dropdown |
| V6 Cryptography | no | No sensitive data transmitted; contact info (name, email) already stored by Chatwoot |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| IDOR — viewing another account's pipeline stats | Information Disclosure | All API calls use `accountScoped: true` — Chatwoot authorization middleware enforces account membership |
| IDOR — updating another account's contact stage | Tampering | Contact update via `ContactAPI.update()` — server enforces contact belongs to authenticated user's account |
| XSS via contact name in sidebar | Injection | Vue 3 auto-escapes text content; contact names rendered as `{{ contact.name }}` (not `v-html`) |

---

## Sources

### Primary (HIGH confidence)
- `app/javascript/dashboard/stores/pipeline.js` — `fetchStats()`, `moveContactToStage()`, `getStats`, `getStagesById` getters (lines 1-216) — verified in codebase
- `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue` — `handleCardClick` (line 193), `handleRowClick` (line 277), `contactsMap`, `contactsByStage` refs (lines 22-44) — verified in codebase
- `app/javascript/dashboard/components/kanban/KanbanBoard.vue` — `card-click` emit with contact object (line 40) — verified in codebase
- `app/javascript/dashboard/components-next/dropdown-menu/DropdownMenu.vue` — menu item schema `{action, value, label}`, `isSelected` class (lines 14-16, 178-180, 222-224) — verified in codebase
- `app/javascript/dashboard/api/contacts.js` — `ContactAPI.update(id, data)` PATCH endpoint (lines 34-36) — verified in codebase
- `app/javascript/dashboard/composables/index.js` — `useAlert()` via mitt emitter (lines 22-24) — verified in codebase
- `.planning/phases/08-stats-panel-contact-sidebar/08-CONTEXT.md` — D-01 through D-09 locked decisions, canonical refs, codebase insights
- `.planning/phases/08-stats-panel-contact-sidebar/08-UI-SPEC.md` — Component inventory, stat card/stage badge/sidebar overlay styling

### Secondary (MEDIUM confidence)
- `.planning/phases/03-stats-api/03-CONTEXT.md` — Stats response shape `{stage_id, name, count, added_today}` confirmed
- Phase 5 Kanban skeleton pattern — `bg-n-slate-3 animate-pulse` in LeadsIndex.vue lines 376-399
- `ContactsDetailsLayout.vue` mobile sidebar Transition pattern — lines 172-188 for overlay transition reference

### Tertiary (LOW confidence)
- None — all critical claims verified in primary sources.

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — all libraries confirmed in project (CLAUDE.md) or existing codebase
- Architecture: HIGH — all patterns verified from existing code; only novel piece is combining them for Phase 8
- Pitfalls: HIGH — pitfalls identified by tracing data flow through actual code references

**Research date:** 2026-04-12
**Valid until:** 2026-05-12 (30 days — Vue 3 + Pinia patterns are stable)
