---
status: resolved
trigger: "CRM Pipeline features (Kanban board, Leads menu item) are not visible in the dashboard — the left sidebar has no Leads/Pipeline navigation item. The code was built but never wired into the routes/navigation."
created: 2026-04-12T00:00:00Z
updated: 2026-04-12T00:00:00Z
resolved: 2026-04-13T07:20:00.000Z
---

## Current Focus
next_action: "Await user verification — navigate to dashboard and confirm Leads item appears in sidebar"
hypothesis: ""
test: ""
expecting: ""
root_cause_confirmed: true

## Symptoms
expected: Kanban board and Leads menu item visible in dashboard sidebar
actual: Left sidebar has standard Chatwoot menu only (conversations, contacts, reports, etc.) — no Leads/Pipeline item
errors: No JavaScript errors, no 404s — the routes simply don't exist
reproduction: Navigate to dashboard at localhost:3000 — no pipeline/kanban/leads anywhere
started: Never worked — new pipeline code was built but never integrated into navigation/routes

## Eliminated
- hypothesis: "Routes not defined"
  evidence: "dashboard.routes.js already imports and spreads leadsRoutes (line 6, 29) — routes were already wired"
  timestamp: 2026-04-12

## Evidence
- timestamp: 2026-04-12
  checked: "app/javascript/dashboard/routes/dashboard/dashboard.routes.js"
  found: "leadsRoutes is imported (line 6) and spread in AppContainer children (line 29) — routes ARE wired"
  implication: "Route registration was never the problem"
- timestamp: 2026-04-12
  checked: "app/javascript/dashboard/routes/dashboard/leads/leads.routes.js"
  found: "Route defined at frontendURL('accounts/:accountId/leads'), name 'leads_dashboard_index', meta includes FEATURE_FLAGS.CRM"
  implication: "Route definition is complete and correct"
- timestamp: 2026-04-12
  checked: "app/javascript/dashboard/components-next/sidebar/Sidebar.vue menuItems computed"
  found: "menuItems array has Inbox, Conversation, Captain, Contacts, Companies, Reports, Campaigns, Portals, Settings — no Leads/Pipeline item"
  implication: "Sidebar navigation is the missing integration point"
- timestamp: 2026-04-12
  checked: "app/javascript/dashboard/i18n/locale/en/settings.json SIDEBAR section"
  found: "No SIDEBAR.LEADS translation key exists"
  implication: "Translation key must be added alongside sidebar nav item"

## Resolution
root_cause: "Sidebar.vue menuItems computed property did not include a Leads/Pipeline navigation entry. Routes and i18n key were both missing."
fix: |
  1. Added "LEADS": "Leads" translation key to SIDEBAR section in settings.json
  2. Added Leads menu item to Sidebar.vue menuItems (after Companies, before Reports):
     - name: 'Leads'
     - label: t('SIDEBAR.LEADS')
     - icon: 'i-lucide-layout-grid'
     - to: accountScopedRoute('leads_dashboard_index')
     - activeOn: ['leads_dashboard_index']
verification: "Navigate to http://localhost:3000/app/login — sign in — confirm 'Leads' item appears in sidebar between Companies and Reports, and clicking it opens the Kanban board at /accounts/:id/leads"
files_changed:
  - app/javascript/dashboard/i18n/locale/en/settings.json
  - app/javascript/dashboard/components-next/sidebar/Sidebar.vue
