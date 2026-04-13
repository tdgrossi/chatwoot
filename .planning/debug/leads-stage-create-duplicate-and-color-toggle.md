---
status: resolved
trigger: "leads-stage-create-duplicate-and-color-toggle"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-13T00:00:00.000Z
resolved: 2026-04-13T07:20:00.000Z
---

## Current Focus

hypothesis: ColorPicker Button missing type="button" — defaults to type="submit" inside the form — triggers form submission on click
test: Add type="button" to the Button in ColorPicker.vue
expecting: Clicking the color picker button no longer submits the form in EDIT mode
next_action: User verifies EDIT mode color picker toggle no longer closes the dialog

---

## Evidence

- timestamp: 2026-04-13
  checked: Git diff of ColorPicker.vue
  found: |
    The refactored ColorPicker uses v-on-clickaway directive (from vueuse) and had:
    - @click.stop="toggleColorPicker"
    - @pointerdown.prevent
    But @pointerdown.prevent only prevents DEFAULT action on pointerdown, it does NOT stop propagation.
    The mousedown event still bubbled up to .modal-mask element.
  implication: The modal's handleMouseDown() still received the mousedown and set mousedDownOnBackdrop = true

- timestamp: 2026-04-13
  checked: Modal.vue mousedown handling
  found: |
    - .modal-mask has @mousedown="handleMouseDown"
    - .modal-container has @mousedown="event => event.stopPropagation()"
    - But Chrome color picker rendered OUTSIDE modal-container via absolute positioning with z-9999
    - So mousedown on Chrome component bypasses modal-container's stopPropagation
  implication: Mousedown event from color picker reaches modal mask directly, closing the modal

- timestamp: 2026-04-13
  checked: ColorPicker.vue after Teleport fix
  found: |
    Chrome component is now rendered via <Teleport to="body">.
    Position is computed with getBoundingClientRect() on the trigger button ref,
    then applied as fixed positioning (top/left in px, z-index 9999).
    The Chrome picker is entirely outside the Modal DOM tree.
    v-on-clickaway on Chrome closes only the picker, not the modal.
  implication: Modal's mousedown handler on .modal-mask is never triggered by picker interactions

- timestamp: 2026-04-13
  checked: ColorPicker.vue Button element — type attribute
  found: |
    The Button component had no type attribute. Inside StageFormDialog's <form>, an
    untyped <button> defaults to type="submit" per the HTML spec. Clicking it fires a
    submit event on the form (even with @click.stop, which only stops click propagation,
    not the browser's native submit mechanism).
    StageFormDialog.handleSave checks isSaving and name.trim(). In EDIT mode the name
    is pre-populated from the stage (non-empty), so both guards pass and emit('save')
    fires. StageManagementModal.handleSave then calls closeFormDialog(), which sets
    showFormDialog=false and editingStage=null — exactly matching the console sequence.
    In CREATE mode the name is empty, so the name guard returns early and the form does
    not close, which explains why CREATE mode was unaffected.
  implication: Adding type="button" prevents the browser from treating the ColorPicker
    trigger as a submit button, fixing the EDIT-mode closure.

---

## Eliminated

- hypothesis: Adding @mousedown.stop on Button would prevent modal close
  evidence: Mousedown from the picker itself (not just the button) could still reach the mask; root cause is DOM hierarchy, not a single event
  timestamp: 2026-04-13

---

## Resolution

root_cause: The ColorPicker Button inside StageFormDialog's <form> had no type attribute, defaulting to type="submit" per HTML spec. Clicking it fires the form's submit event. In EDIT mode the stage name is pre-populated (non-empty), so StageFormDialog.handleSave's name guard passes, emit('save') fires, and StageManagementModal.handleSave calls closeFormDialog(), closing the dialog. In CREATE mode the name is empty, so the guard returns early and the form stays open.

fix: Added type="button" to the ColorPicker trigger Button. The Teleport fix (previous attempt) is retained but was addressing a separate/partial issue. The form submit is the actual root cause of the EDIT-mode failure.

verification: Pending human verification in EDIT mode — clicking the color picker button should not close the dialog

files_changed:
  - app/javascript/dashboard/components-next/colorpicker/ColorPicker.vue
