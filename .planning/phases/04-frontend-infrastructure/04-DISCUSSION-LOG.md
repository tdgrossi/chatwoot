# Phase 4: Frontend Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-04-11
**Phase:** 04-frontend-infrastructure
**Mode:** auto (discuss-phase)
**Gray areas identified:** 4 areas

---

## Analysis: Phase 4 is an Infrastructure Phase

Phase 4 has NO explicit requirements (per ROADMAP.md: "Requirements: (none -- infrastructure enabler)").
All implementation decisions follow from established Chatwoot frontend patterns.

## Gray Areas & Auto-Selected Decisions

### Store pattern
| Option | Description | Selected |
|--------|-------------|----------|
| Follow `companies.js` Pinia pattern | `createStore` factory, `type: 'pinia'` | ✓ |
| Create custom Pinia store without factory | More flexibility, less consistency | |

**Decision:** Follow `companies.js` Pinia pattern
**Rationale:** Chatwoot mid-migration; `companies.js` is the established Pinia reference

### Store location
| Option | Description | Selected |
|--------|-------------|----------|
| `dashboard/stores/pipeline.js` | Alongside `companies.js` | ✓ |
| `store/modules/pipeline/` | Vuex-style module directory | |

**Decision:** `dashboard/stores/pipeline.js`
**Rationale:** Parallel placement with existing Pinia stores

### Contacts store extension
| Option | Description | Selected |
|--------|-------------|----------|
| Add `fetchByStage` to existing Vuex contacts store | Single source of truth for contacts | ✓ |
| Create separate Pinia contacts store | Clean separation, duplicated state | |

**Decision:** Extend existing Vuex contacts store
**Rationale:** Phase 4 success criteria explicitly says "useContactsStore gains a fetchByStage action"

### Route component
| Option | Description | Selected |
|--------|-------------|----------|
| Minimal stub component with store integration | Prepares Phase 5 slot | ✓ |
| Redirect to contacts | No visible functionality | |

**Decision:** Minimal stub with store integration
**Rationale:** Route must point somewhere; stub with store wiring prepares Phase 5

---

## Auto-Resolution Summary

All gray areas resolved with recommended defaults (first option) per established Chatwoot patterns.
No user interaction required — Phase 4 is a straightforward infrastructure phase.

## Deferred Ideas

None — discussion stayed within phase scope

---

*Phase: 04-frontend-infrastructure*
*Context gathered: 2026-04-11*
