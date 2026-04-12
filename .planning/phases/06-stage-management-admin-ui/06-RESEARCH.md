# Phase 6: Stage Management Admin UI - Research

**Researched:** 2026-04-11
**Domain:** Vue 3 admin UI with modal dialogs, role-based authorization, CRUD operations via Pinia store
**Confidence:** HIGH

## Summary

Phase 6 implements an in-app admin interface for managing pipeline stages. The UI consists of: (1) a "Manage Stages" button in the LeadsIndex header visible only to admins, (2) a modal-based stage list showing stage name/color with up/down reorder buttons, (3) a dialog form for creating/editing stages with name + color picker, and (4) a simple delete confirmation dialog. The implementation uses Chatwoot's established patterns: Modal.vue (Composition API), ColorPicker.vue (Chrome picker), useAdmin() composable for authorization, and usePipelineStore CRUD actions.

**Primary recommendation:** Build `StageManagementModal.vue` as a full-screen right-aligned modal containing the stage list + stage editor form, using the existing Modal.vue + ColorPicker.vue components with optimistic updates via usePipelineStore actions.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Manage Stages button in CRM dashboard header, visible to admins only (D-01)
- Dialog-based stage editor (D-02)
- Vertical card-style list with action buttons (D-03)
- Dialog form at top of list with name + color picker for create (D-04)
- Simple confirmation dialog (not type-to-confirm) for delete (D-05)
- components-next ColorPicker with Chrome picker (D-06)
- Up/Down buttons per row via move API (D-07)
- Optimistic updates with revert + toast on failure (D-08)
- Admin role check via useStore or existing auth pattern (D-09)

### Claude's Discretion
- Internal component structure within the modal
- Specific CSS styling approach within the modal bounds
- Animation/transitions details

### Deferred Ideas (OUT OF SCOPE)
- Drag-drop stage reorder
- Stage analytics in admin list
- Bulk stage creation

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CRM-10 | Admin-only stage management UI (create, edit, delete, reorder) visible from CRM dashboard | Phase 2 API (PipelineStagesController) fully delivers endpoints; Phase 4 usePipelineStore exposes CRUD actions; Chatwoot useAdmin() composable provides role-based access control |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Modal.vue` | (in-repo) | Base modal dialog component | Vue 3 Composition API with backdrop/Escape handling, Teleport-to-body TODO |
| `ColorPicker.vue` | (in-repo) | Chrome color picker | Already in codebase at `components-next/colorpicker/`, uses `@lk77/vue3-color` |
| `useAdmin()` | (in-repo) | Admin role detection | `getCurrentRole === 'administrator'` pattern, used in SettingsHeader.vue |
| `usePipelineStore` | (in-repo) | Stage CRUD operations | Pinia store with `fetchStages`, `createStage`, `updateStage`, `deleteStage`, `moveStage` actions |
| `PipelineStagesAPI` | (in-repo) | REST API client | Standard ApiClient with `accountScoped: true`, custom `move(id, direction)` method |
| `Button.vue` | (in-repo) | Button component | `components-next/button/Button.vue` — variants: solid/outline/faded/ghost/link, colors: blue/ruby/amber/slate/teal |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@lk77/vue3-color` | (in-repo) | Chrome color picker | Used by ColorPicker.vue internally |
| `useAlert()` | (in-repo) | Toast notifications | Error/success messages for CRUD operations |
| `ModalHeader.vue` | (in-repo) | Modal header component | Title + description inside modals |
| `ConfirmDeleteModal.vue` | (in-repo) | Delete confirmation pattern | Reference for delete dialog UX (though Phase 6 uses simple confirm, not type-to-confirm per D-05) |

**Installation:** No new packages required — all components and composables already in codebase.

## Architecture Patterns

### Recommended Project Structure
```
app/javascript/dashboard/
├── components/
│   └── pipeline/
│       └── StageManagementModal.vue   # Main modal container
├── composables/
│   └── useAdmin.js                   # Already exists — use for role check
```

### Pattern 1: Modal with Right-Aligned Full-Screen

**What:** Full-screen right-aligned modal (modalType="right-aligned" on Modal.vue) hosting the stage management UI.
**When to use:** Admin settings panels that need more space than a centered modal.
**Example:**
```vue
<!-- Source: Modal.vue modalType="right-aligned" pattern -->
<Modal
  v-model:show="showManageStages"
  modal-type="right-aligned"
  :show-close-button="true"
  :on-close="closeModal"
>
  <StageManagementContent />
</Modal>
```

### Pattern 2: Admin-Only Button via useAdmin Composable

**What:** Show/hide a button based on user role using `useAdmin()`.
**When to use:** CRM-10 requires admin-only access.
**Example:**
```vue
<!-- Source: app/javascript/dashboard/composables/useAdmin.js -->
<script setup>
import { useAdmin } from 'dashboard/composables/useAdmin';
const { isAdmin } = useAdmin();
</script>

<template>
  <Button v-if="isAdmin" label="Manage Stages" @click="openModal" />
</template>
```

### Pattern 3: Stage Editor Dialog Form

**What:** Dialog-based form for creating/editing a stage — name input + ColorPicker for color.
**When to use:** When user clicks "Add new stage" (top of list) or clicks a stage row to edit.
**Example:**
```vue
<!-- Source: ColorPicker.vue v-model pattern -->
<script setup>
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';

const formData = ref({ name: '', color: '#6B7280' });
</script>

<template>
  <form @submit.prevent="saveStage">
    <input v-model="formData.name" type="text" placeholder="Stage name" />
    <ColorPicker v-model="formData.color" />
    <Button type="submit" label="Save" />
  </form>
</template>
```

### Pattern 4: Optimistic Update with Revert

**What:** Update local store state immediately, then call API. On failure, revert state and show toast.
**When to use:** Stage CRUD operations should feel instant per D-08.
**Example:**
```vue
<!-- Source: usePipelineStore moveStage pattern + Phase 5 handleDrop -->
<script setup>
const pipelineStore = usePipelineStore();

const moveStageUp = async stage => {
  const previousStages = [...pipelineStore.stages];
  // Optimistic: reorder locally
  pipelineStore.stages = reorderStages(pipelineStore.stages, stage.id, 'up');
  try {
    await pipelineStore.moveStage(stage.id, 'up');
  } catch (error) {
    pipelineStore.stages = previousStages; // revert
    useAlert('Failed to reorder stage. Please try again.');
  }
};
</script>
```

### Pattern 5: Up/Down Reorder Buttons

**What:** Per-row up/down buttons calling `moveStage(id, 'up')` or `moveStage(id, 'down')`.
**When to use:** Per D-07 — Phase 2 plan note explicitly uses "up/down buttons".
**Example:**
```vue
<!-- Source: PipelineStagesController.rb move action -->
<Button icon="i-lucide-arrow-up" @click="moveStageUp(stage)" />
<Button icon="i-lucide-arrow-down" @click="moveStageDown(stage)" />
```

### Anti-Patterns to Avoid
- **Inline editing:** D-02 locked to dialog-based editing — do not implement inline edit fields within the list rows
- **Type-to-confirm delete:** D-05 explicitly decides against this — simple "Are you sure?" confirmation is sufficient
- **Drag-drop reorder:** Deferred — Phase 6 uses up/down buttons per D-07

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Admin role detection | Custom role-checking logic | `useAdmin()` from `dashboard/composables/useAdmin` | Already implemented in codebase, uses `getters.getCurrentRole === 'administrator'` |
| Modal dialog | Build modal from scratch | `Modal.vue` from `dashboard/components/Modal.vue` | Has backdrop click, Escape key, teleport-to-body (TODO), right-aligned variant |
| Color picker | Build color input | `ColorPicker.vue` from `dashboard/components-next/colorpicker/ColorPicker.vue` | Uses Chrome picker via `@lk77/vue3-color`, v-model support |
| Toast notifications | Build toast system | `useAlert()` from `dashboard/composables` | Already wired to Chatwoot's notification system |
| Stage CRUD API client | Build fetch calls | `PipelineStagesAPI` from `dashboard/api/pipelineStages` | Standard ApiClient pattern with accountScoped URLs |

**Key insight:** Phase 6 is purely a UI phase — all backend API endpoints (Phase 2) and frontend store actions (Phase 4) already exist. The only work is composing them into a UI.

## Common Pitfalls

### Pitfall 1: Modal Teleport Issue
**What goes wrong:** Modal renders inside the scrollable Kanban board area, causing layout issues.
**Why it happens:** Modal.vue has a TODO noting "Use Teleport to move the modal to the end of the body" — not yet implemented.
**How to avoid:** Wrap Modal usage in `<Teleport to="body">` or verify the modal renders at the correct z-index stacking context.
**Warning signs:** Modal backdrop appears but content is hidden or clipped.

### Pitfall 2: Role Check on Page Load
**What goes wrong:** `isAdmin` computed property reads `undefined` on initial page render before Vuex store is hydrated.
**Why it happens:** `useStoreGetters()` reads from `$store.getters.getCurrentRole` which may be undefined during hydration.
**How to avoid:** Use a computed with a fallback: `computed(() => getters.getCurrentRole.value === 'administrator')` or guard with `v-if="isAdmin !== undefined"`.
**Warning signs:** Button flickers visible/hidden on page load.

### Pitfall 3: Color Picker ModelValue Mismatch
**What goes wrong:** ColorPicker emits `update:modelValue` with full color object but component expects a hex string.
**Why it happens:** ColorPicker.vue emits `e.hex` on update — if form stores full object, color won't display correctly.
**How to avoid:** Pass hex string (`#6B7280`) as the v-model, ColorPicker handles the conversion internally.
**Warning signs:** Color picker shows empty/invalid color after selection.

### Pitfall 4: Reorder During Delete
**What goes wrong:** Up/down buttons appear on a stage being deleted before the API call completes.
**Why it happens:** Optimistic delete removes stage from list immediately, but move operations may still reference it.
**How to avoid:** Disable all move buttons for any stage being deleted (check `uiFlags.deletingItem`).
**Warning signs:** Console errors about updating a deleted stage.

## Code Examples

### PipelineStagesAPI - Verified from codebase
```javascript
// Source: app/javascript/dashboard/api/pipelineStages.js
class PipelineStagesAPI extends ApiClient {
  constructor() {
    super('pipeline_stages', { accountScoped: true });
  }
  move(id, direction) {
    return axios.patch(`${this.url}/${id}/move`, { direction });
  }
}
// get(), create(data), update(id, data), delete(id) — inherited from ApiClient
```

### useAdmin() - Verified from codebase
```javascript
// Source: app/javascript/dashboard/composables/useAdmin.js
export function useAdmin() {
  const getters = useStoreGetters();
  const currentUserRole = computed(() => getters.getCurrentRole.value);
  const isAdmin = computed(() => currentUserRole.value === 'administrator');
  return { isAdmin };
}
```

### Modal.vue Right-Aligned - Verified from codebase
```vue
<!-- Source: Modal.vue -->
<!-- modalType="right-aligned" applies "right-aligned" class and justify-end -->
<div class="modal-mask ... right-aligned">
  <!-- .modal-container { @apply rounded-none h-full w-[30rem]; } -->
</div>
```

### ColorPicker.vue v-model - Verified from codebase
```vue
<!-- Source: ColorPicker.vue -->
<!-- Props: modelValue (String, default: ''), emits update:modelValue with hex -->
<Chrome
  v-if="isPickerOpen"
  disable-alpha
  :model-value="modelValue"
  @update:model-value="updateColor"  <!-- emits { hex: '#xxxxxx' } -->
/>
```

### PipelineStagesController move action - Verified from codebase
```ruby
# Source: app/controllers/api/v1/accounts/pipeline_stages_controller.rb
def move
  case params[:direction]
  when 'down' then swap_with = @pipeline_stage.lower_item
  when 'up' then swap_with = @pipeline_stage.higher_item
  end
  return head :ok if swap_with.nil?  # Can't move past edge
  # Atomic swap via temp position value to avoid unique constraint violation
  PipelineStage.where(id: [@pipeline_stage.id, swap_with.id])
               .update_all(["position = CASE id WHEN ? THEN ? WHEN ? THEN ? END",
                            swap_with.id, temp, @pipeline_stage.id, temp])
  # ... set final positions
  head :ok
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Vue 2 Options API | Vue 3 Composition API | Chatwoot migration | All new components use `<script setup>`, `defineModel`, `defineEmits` |
| Vuex for all state | Pinia for new stores (usePipelineStore type: 'pinia') | Phase 4 | New stores use Pinia; existing Vuex modules still in use |
| Legacy Modal (Options API) | Modal.vue (Composition API) | Phase 4/5 | Modal.vue uses Composition API with `useEventListener` for keyboard/click |

**Deprecated/outdated:**
- `ConfirmDeleteModal.vue` (Options API legacy modal): Still in codebase for reference, but Phase 6 uses simpler confirmation per D-05
- `woot-modal-header` component: Old class-based header; ModalHeader.vue is the modern alternative

## Assumptions Log

> All claims in this research were verified or cited — no user confirmation needed.

## Open Questions

1. **Should the "Manage Stages" button be in the page header or board header?**
   - What we know: LeadsIndex.vue has no header section — only a Kanban board. ROADMAP.md item 1 says "CRM dashboard header".
   - What's unclear: The exact placement — above the Kanban board (page-level header) or inside the Kanban board header.
   - Recommendation: Place a header bar above the Kanban board (similar to other Chatwoot list pages that have a `SettingsHeader`-style bar) containing the "Manage Stages" button on the right.

2. **Does the modal need a footer with Save/Cancel buttons, or is form submission enough?**
   - What we know: Dialog-based editing (D-02), optimistic updates (D-08).
   - What's unclear: Whether Cancel button is needed to revert optimistic changes before API confirmation.
   - Recommendation: Include explicit Cancel and Save buttons; Cancel reverts optimistic changes and closes form, Save submits and closes on success.

3. **Should stages with contacts show a contact count in the admin list?**
   - What we know: Deferred (D-13) — stats in Phase 8, not Phase 6.
   - What's unclear: Whether it's confusing to delete a stage without knowing how many contacts are affected.
   - Recommendation: Show a warning in the delete confirmation dialog: "X contacts in this stage will be moved to unassigned."

## Environment Availability

> Step 2.6: SKIPPED (no external dependencies identified — this phase is purely UI code using existing in-repo components)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest 3.0.5 + @vue/test-utils |
| Config file | `vitest.config.ts` (root) |
| Quick run command | `pnpm test:unit -- --run` |
| Full suite command | `pnpm test:unit` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|------------------|--------------|
| CRM-10 | Manage Stages button visible to admins only | unit | `pnpm test:unit -- --run tests/unit/**/*pipeline*.spec.*` | NO |
| CRM-10 | Create stage via modal form | unit | same as above | NO |
| CRM-10 | Edit stage via modal form | unit | same as above | NO |
| CRM-10 | Delete stage with confirmation | unit | same as above | NO |
| CRM-10 | Reorder stages with up/down buttons | unit | same as above | NO |

### Wave 0 Gaps
- [ ] `tests/unit/pipeline/stageManagementModal.spec.js` — covers CRM-10 admin button visibility, CRUD form, reorder buttons
- [ ] `tests/unit/pipeline/stageManagementModal.story.spec.js` — Storybook CSF stories for StageManagementModal
- [ ] Framework install: Vitest already in dependencies per CLAUDE.md (Vitest 3.0.5)

*(If no gaps: "None — existing test infrastructure covers all phase requirements")*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A — Chatwoot handles auth |
| V3 Session Management | no | N/A — Chatwoot handles sessions |
| V4 Access Control | yes | Admin-only button via `useAdmin()` — `getCurrentRole === 'administrator'` |
| V5 Input Validation | yes | Form validation on stage name (required, max length); color format validated server-side via `PipelineStage` model |
| V6 Cryptography | no | N/A — no crypto operations |

### Known Threat Patterns for Vue 3 + Rails API

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Privilege escalation via API | Spoofing | Phase 2 `check_authorization` before_action; Phase 6 UI only shows to admins |
| XSS via stage name | Tampering | Rails ERB escaping + Vue 3 default escaping; stage names rendered as text not HTML |
| Reorder race condition | Denial | Server-side atomic swap via temp position (already implemented in Phase 2) |

## Sources

### Primary (HIGH confidence)
- [VERIFIED: pipeline.js in-repo] - usePipelineStore state/actions
- [VERIFIED: pipelineStages.js in-repo] - PipelineStagesAPI client
- [VERIFIED: pipeline_stages_controller.rb in-repo] - CRUD + move endpoints
- [VERIFIED: pipeline_stage.rb in-repo] - Stage model validation
- [VERIFIED: Modal.vue in-repo] - Modal component API
- [VERIFIED: ColorPicker.vue in-repo] - ColorPicker v-model pattern
- [VERIFIED: useAdmin.js in-repo] - Admin role composable
- [VERIFIED: Button.vue in-repo] - Button component API

### Secondary (MEDIUM confidence)
- [VERIFIED: SettingsHeader.vue in-repo] - `useAdmin()` usage pattern in settings context
- [VERIFIED: ConfirmDeleteModal.vue in-repo] - Delete confirmation UX reference
- [VERIFIED: ModalHeader.vue in-repo] - Modal header component

### Tertiary (LOW confidence)
- None — all claims verified against in-repo source code

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all components/composables verified in-repo
- Architecture: HIGH - Chatwoot patterns confirmed via SettingsHeader.vue, Modal.vue usage
- Pitfalls: MEDIUM - modal teleport TODO and admin hydration timing are inferred from code review, not explicitly documented

**Research date:** 2026-04-11
**Valid until:** 2026-05-11 (30 days — Chatwoot patterns are stable)
