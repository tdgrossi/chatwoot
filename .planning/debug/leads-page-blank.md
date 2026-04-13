---
status: resolved
trigger: "Leads page blank, chat page blank after visiting leads"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
resolved: 2026-04-13T07:15:00.000Z
---

# Leads Page Blank - Debug Findings

## Date: 2026-04-12

## Issue Summary
When navigating to the Leads page (`/app/accounts/1/leads`), the page shows blank. Also, clicking on chat after visiting Leads also shows blank.

## Root Causes Found

### 1. Vue Runtime Error in PipelineStatsPanel
**Error:** `TypeError: Cannot read properties of undefined (reading 'length')` at `PipelineStatsPanel`

**Location:** `app/javascript/dashboard/components/pipeline/PipelineStatsPanel.vue`

**Problem:** The `stats` computed property calls `.reduce()` on `stats.value` but `stats` can be undefined/null when the API hasn't returned data yet.

```javascript
// BROKEN - stats could be undefined
const totalCount = computed(() =>
  stats.value.reduce((sum, s) => sum + (s.count || 0), 0)
);
```

**Fix needed:** Add null/undefined guard:
```javascript
const totalCount = computed(() =>
  (stats.value || []).reduce((sum, s) => sum + (s.count || 0), 0)
);
```

### 2. 404 on Enterprise Limits API
**Error:** `GET /enterprise/api/v1/accounts/1/limits 404`

This is a non-blocking error from enterprise billing checks, not critical.

### 3. Conversation/Chat Page Blank After Visiting Leads
**Symptom:** After visiting Leads, chat page also goes blank.

**Likely cause:** The Vue error in PipelineStatsPanel causes the entire component tree to error out. Once Vue's error boundary is triggered, sibling components or the RouterView may not recover cleanly.

## Files Modified During This Session

1. `app/javascript/dashboard/components/kanban/StageColumn.vue` - Fixed v-model on prop
2. `app/javascript/dashboard/components/kanban/KanbanBoard.vue` - Added update:contacts handlers
3. `app/javascript/dashboard/components/pipeline/ContactSidebar.vue` - Fixed import path
4. `app/javascript/dashboard/components/pipeline/PipelineStatsPanel.vue` - Fixed import path
5. `app/javascript/dashboard/routes/dashboard/settings/customRoles/component/CustomRolePaywall.vue` - Fixed thead inside div
6. `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` - Added Leads nav item
7. `app/javascript/dashboard/i18n/locale/en/settings.json` - Added SIDEBAR.LEADS translation

## Next Steps

1. **Fix PipelineStatsPanel** - Add null guards to computed properties using `stats.value`
2. **Restart containers** - `docker compose restart rails vite`
3. **Test** - Navigate to Leads, verify Kanban board renders, then navigate to chat and verify it still works
