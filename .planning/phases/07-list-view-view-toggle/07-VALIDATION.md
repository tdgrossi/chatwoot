---
phase: "07"
slug: "list-view-view-toggle"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-04-12"
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 3.0.5 |
| **Config file** | `vite.config.ts` (vitest configured) |
| **Quick run command** | `npx vitest run --reporter=verbose` |
| **Full suite command** | `npx vitest run --coverage=false` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npx vitest run --reporter=verbose`
- **After every plan wave:** Run `npx vitest run`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | CRM-08, CRM-09 | T-07-01 | N/A | unit | `npx vitest run --reporter=verbose` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/dashboard/pipeline/viewToggle.spec.js` — stubs for view toggle, filter, sort, persistence
- [ ] `tests/unit/dashboard/pipeline/listView.spec.js` — stubs for list view rendering
- [ ] `tests/unit/dashboard/pipeline/stageFilter.spec.js` — stubs for stage filter dropdown

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| View toggle visually switches between Kanban and List | CRM-09 | Visual UI state | Toggle both buttons, verify KanbanBoard and List table appear/disappear |
| localStorage persistence across page reload | CRM-09 | Browser state | Toggle view, reload page, verify same view restored |
| Filtered-empty vs truly-empty distinction | CRM-08 | UI state | Set filter to stage with no contacts, verify "No contacts match your filters" appears |
| Sort indicator icons update correctly | CRM-08 | UI interaction | Click column headers, verify sort icons change |
| Row click handler fires | CRM-08 | UI event | Click a row, verify handleRowClick called (console.log check) |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** {pending / approved YYYY-MM-DD}
