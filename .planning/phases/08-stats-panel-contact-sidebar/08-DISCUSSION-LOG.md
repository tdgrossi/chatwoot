# Phase 8: Stats Panel & Contact Sidebar - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 08-stats-panel-contact-sidebar
**Areas discussed:** Stats panel visualization, Sidebar scope, Sidebar open trigger

---

## Gray Area: Stats Panel Visualization

| Option | Description | Selected |
|--------|-------------|----------|
| Cards per stage + summary | One card per stage (name, color dot, count) + Total + Added Today summary cards in horizontal row | ✓ |
| Bar chart | Visual bar chart showing relative stage volumes | |
| Metric strip | Compact single-line strip with key numbers | |

**User's choice:** Cards per stage + summary (auto-selected, recommended default)
**Notes:** [auto] Stats panel visualization — Q: "How should the stats panel display data?" → Selected: Cards per stage + summary (recommended default)

---

## Gray Area: Sidebar Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal sidebar | Contact name, email/phone, current stage dropdown, last activity — focused on stage reassignment | ✓ |
| Full contact details | Expandable sections for all contact fields, tags, conversations, etc. | |

**User's choice:** Minimal sidebar (auto-selected, recommended default)
**Notes:** [auto] Sidebar scope — Q: "How much contact info should the sidebar show?" → Selected: Minimal sidebar with stage dropdown + basic contact info (recommended — keeps sidebar focused and fast)

---

## Gray Area: Sidebar Open Trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Click contact | Clicking a contact card (Kanban) or row (list) opens sidebar; overlay/close dismisses | ✓ |
| Dedicated button | Right-click context menu or explicit "View" button on hover | |

**User's choice:** Click contact opens sidebar (auto-selected, recommended default)
**Notes:** [auto] Sidebar open trigger — Q: "How should users open the contact sidebar?" → Selected: Click contact opens sidebar, overlay/close dismisses (recommended — most discoverable)

---

## Claude's Discretion

The following were delegated to Claude's judgment (auto-mode, recommended defaults applied):
- Stats card layout: horizontal row with per-stage cards + summary cards
- Stats panel position: between header and Kanban/list view
- Sidebar stage selector presentation: dropdown with stage options + Unassigned, current stage highlighted
- Stage update behavior: optimistic update with revert + toast on failure
- Sidebar data loading: no extra API call — use in-memory contact + pipelineStore stages
- Kanban/list sync after stage change: store-level reactive update
- Loading skeleton for stats: skeleton cards matching stat card shape

## Deferred Ideas

None — discussion stayed within phase scope.
