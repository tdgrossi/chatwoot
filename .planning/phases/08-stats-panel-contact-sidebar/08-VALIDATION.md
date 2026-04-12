---
phase: 8
slug: stats-panel-contact-sidebar
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-12
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (JS/Vue) + RSpec (Rails) |
| **Config file** | `vitest.config.ts`, `spec/rails_helper.rb` |
| **Quick run command** | `pnpm vitest run`, `bundle exec rspec` |
| **Full suite command** | `pnpm vitest run && bundle exec rspec` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run relevant test file only (`vitest run path/to/file.spec.js`)
- **After every plan wave:** Run full suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | CRM-11 | — | N/A | unit | `vitest run contacts/usePipelineStore.spec.js` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 1 | CRM-11 | — | N/A | unit | `vitest run contacts/ContactsSidebar.spec.jsx` | ❌ W0 | ⬜ pending |
| 08-01-03 | 01 | 1 | CRM-12 | — | N/A | unit | `vitest run pipeline/pipelineStore.spec.js` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spec/javascripts/dashboard/components/contacts/ContactsSidebar.spec.jsx` — Vitest stubs for sidebar component
- [ ] `spec/javascripts/dashboard/stores/pipeline.spec.js` — Vitest stubs for store actions
- [ ] Vitest configured in `vitest.config.ts` with `@vue/test-utils` and `jsdom`

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stats panel renders correctly in browser | CRM-11 | Visual layout requires human verification | 1. Navigate to /accounts/:id/leads 2. Verify stats cards appear between header and Kanban 3. Verify stage count matches actual contacts |
| Sidebar opens on contact click | CRM-12 | Interaction test requires browser | 1. Click a contact card/row 2. Verify sidebar opens with correct contact info |
| Stage dropdown updates stage | CRM-12 | API + UI integration | 1. Open sidebar 2. Select different stage 3. Verify contact moves in Kanban/list |
| Clickable stats cards filter view | CRM-11 | UX behavior | 1. Click a stage stat card 2. Verify view filters to that stage |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
