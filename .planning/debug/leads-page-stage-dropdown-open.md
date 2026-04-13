---
status: resolved
trigger: "leads page stage dropdown open by default"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
resolution_date: 2026-04-12
---

## Current Focus
fix applied, awaiting human verification

## Resolution
root_cause: DropdownMenu in LeadsIndex.vue had no v-if control and no open state. It rendered unconditionally. The #trigger slot was ignored because DropdownMenu.vue doesn't use slots for trigger - it only renders the menu body.
fix: Added isStageFilterOpen ref, wrapped button+DropdownMenu with OnClickOutside, added v-if="isStageFilterOpen" to DropdownMenu, toggle on button click, close dropdown on selection
verification: Navigate to leads page, stage dropdown should be closed by default
files_changed: [app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue]
