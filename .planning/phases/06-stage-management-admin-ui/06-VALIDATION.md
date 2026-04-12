---
phase: 6
slug: stage-management-admin-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 3.0.5 + @vue/test-utils |
| **Config file** | `vitest.config.ts` (root) |
| **Quick run command** | `pnpm test:unit -- --run` |
| **Full suite command** | `pnpm test:unit` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `pnpm test:unit -- --run`
- **After every plan wave:** Run `pnpm test:unit`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | CRM-10 | T-01 / — | Admin button visible to admins only via useAdmin() | unit | `pnpm test:unit -- --run` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | CRM-10 | T-02 / — | Form validation, no XSS via stage name | unit | `pnpm test:unit -- --run` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | CRM-10 | T-03 / — | Button only visible to administrators | unit | `pnpm test:unit -- --run` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/pipeline/stageManagementModal.spec.js` — covers CRM-10 admin button visibility, CRUD form, reorder buttons
- [ ] Framework install: Vitest already in dependencies per CLAUDE.md (Vitest 3.0.5)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual layout of right-aligned modal | CRM-10 | Visual confirmation requires browser | Open LeadsIndex, click Manage Stages, verify modal renders at right side, 30rem wide |
| Stage color swatch rendering | CRM-10 | Color display verification | Verify each stage shows colored swatch matching stage.color value |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
