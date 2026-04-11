# Phase 5: Kanban Board & Drag-Drop - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 05-kanban-board-drag-drop
**Areas discussed:** Card design, Column layout, Drag UX, Unassigned column, Empty states, Loading states

---

## Card Design

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal card | Name + avatar + last conversation time only | ✓ |
| Rich card | Name + avatar + email + phone + last conversation + stage | |
| Compact card | Name + avatar only | |

**User's choice:** [auto] Minimal card with name + avatar + last conversation time
**Notes:** Per ROADMAP.md success criteria item 4; keep minimal to start

---

## Column Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed-width columns | ~280px columns with horizontal scroll | ✓ |
| Responsive columns | Columns shrink/flex to fill viewport | |
| Single column | Stack columns vertically on mobile | |

**User's choice:** [auto] Fixed-width columns with horizontal scroll
**Notes:** Standard Kanban pattern; preserves readability

---

## Drag UX

| Option | Description | Selected |
|--------|-------------|----------|
| Ghost card + placeholder | Semi-transparent ghost while dragging, drop placeholder shown | ✓ |
| Direct move | Card moves directly, no ghost/placeholder | |
| Card clone | Card clones while original stays | |

**User's choice:** [auto] Ghost card + drop placeholder
**Notes:** Standard drag-drop UX feedback pattern

---

## Unassigned Column

| Option | Description | Selected |
|--------|-------------|----------|
| Always visible, muted styling | Leftmost position, grayed out, count badge | ✓ |
| Only show when unassigned exist | Hide when count is 0 | |
| Prominent styling | Emphasized as special state | |

**User's choice:** [auto] Always visible with muted styling
**Notes:** Per ROADMAP.md item 2; leftmost position

---

## Empty Column States

| Option | Description | Selected |
|--------|-------------|----------|
| Muted placeholder text | "No contacts in [stage name]" | ✓ |
| Blank column | Just empty space | |
| Illustration | Empty state illustration | |

**User's choice:** [auto] Muted placeholder text
**Notes:** Follows Chatwoot empty state patterns

---

## Loading States

| Option | Description | Selected |
|--------|-------------|----------|
| Skeleton loaders | Column and card-shaped skeletons | ✓ |
| Spinner | Single loading spinner over board | |
| Progressive | Columns appear as data loads | |

**User's choice:** [auto] Skeleton loaders
**Notes:** Matches Chatwoot loading UX; Phase 4 established uiFlags pattern

---

## Claude's Discretion

[List areas where user said "you decide" or deferred to Claude]

- All gray areas auto-resolved with recommended defaults per ROADMAP.md specifications and standard Kanban UX patterns

## Deferred Ideas

- Card quick actions (hover actions for view/contact) — belongs in Phase 7/8
- Stage color as column header background — Phase 6 enhancement candidate
- Keyboard shortcuts for card movement — Phase 7 enhancement candidate
- Multi-select and bulk move — future enhancement
