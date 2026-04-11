# Phase 6: Stage Management Admin UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 06-stage-management-admin-ui
**Areas discussed:** Manage Stages entry point, Stage editor UI, Stage list display, Create stage form, Delete confirmation, Color picker, Reorder UX, Optimistic UI updates, Admin authorization

---

## Areas Auto-Resolved (--auto mode)

All areas were auto-resolved with recommended defaults. The rationale for each follows:

### Manage Stages entry point — D-01
| Option | Description | Selected |
|--------|-------------|----------|
| Admin-only button in leads page header | Per ROADMAP.md item 1 | ✓ |
| Menu item in settings | More hidden, not per spec | |
| Context menu on Kanban board | Not mentioned in success criteria | |

**[auto] Selected: Admin-only button in leads page header**

### Stage editor UI — D-02
| Option | Description | Selected |
|--------|-------------|----------|
| Dialog-based editing | Simpler implementation, modal pattern established | ✓ |
| Inline editing | More complex, harder to validate | |
| Slide-over panel | Not standard for Chatwoot settings | |

**[auto] Selected: Dialog-based stage editor**

### Stage list display — D-03
| Option | Description | Selected |
|--------|-------------|----------|
| Vertical card-style list with action buttons | Standard pattern, matches spec item 2-3 | ✓ |
| Table with inline edit | Less common in Chatwoot | |
| Kanban-style columns | Wrong metaphor for admin UI | |

**[auto] Selected: Vertical card-style list with action buttons**

### Create stage form — D-04
| Option | Description | Selected |
|--------|-------------|----------|
| Dialog form at top of list with name + color picker | Standard create pattern, matches Phase 2 fields | ✓ |
| Inline "add row" at bottom | Less discoverable | |
| Separate settings page | More complex routing | |

**[auto] Selected: Dialog form at top of list with name + color picker**

### Delete confirmation — D-05
| Option | Description | Selected |
|--------|-------------|----------|
| Simple confirmation dialog | Sufficient warning per spec | ✓ |
| Type-to-confirm | Overkill for stage management | |
| No confirmation (revert only) | Too risky | |

**[auto] Selected: Simple confirmation dialog (not type-to-confirm)**

### Color picker component — D-06
| Option | Description | Selected |
|--------|-------------|----------|
| components-next ColorPicker with Chrome picker | Modern, already in codebase | ✓ |
| Legacy ColorPicker | Older pattern | |
| HTML color input | Less polished UX | |

**[auto] Selected: components-next ColorPicker with Chrome picker**

### Reorder UX — D-07
| Option | Description | Selected |
|--------|-------------|----------|
| Up/Down buttons per row via move API | Per ROADMAP.md item 5, Phase 2 plan note | ✓ |
| Drag-drop reorder | Not per spec, adds complexity | |
| Stage ids array endpoint | Not needed for simple reorder | |

**[auto] Selected: Up/Down buttons per row via move API**

### Optimistic UI updates — D-08
| Option | Description | Selected |
|--------|-------------|----------|
| Optimistic updates with revert + toast on failure | Consistent with Phase 5 pattern | ✓ |
| Wait for API response | Less responsive | |
| Silent update with polling | Not necessary | |

**[auto] Selected: Optimistic updates with revert + toast on failure**

### Admin authorization — D-09
| Option | Description | Selected |
|--------|-------------|----------|
| Admin role check via useStore or existing auth pattern | Per ROADMAP.md item 1 | ✓ |
| Custom role check | Over-engineered | |
| No authorization | Security risk | |

**[auto] Selected: Admin role check via useStore or existing auth pattern**

---

## Auto-Resolved Items

All 9 decisions were auto-resolved via `--auto` flag with recommended defaults.

---

*Phase: 06-stage-management-admin-ui*
*Context gathered: 2026-04-11*
*[auto] All gray areas auto-resolved with recommended defaults per ROADMAP.md specifications and established Chatwoot admin UI patterns*
