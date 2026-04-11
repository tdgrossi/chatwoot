# Phase 5: Kanban Board & Drag-Drop - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Contact pipeline visualized as a Kanban board with stage columns, draggable cards, and an unassigned column. Phase 5 delivers the visual Kanban UI that Phase 4's infrastructure enables. Phase 6 (Stage Management Admin UI) adds in-app stage editing on top.

</domain>

<decisions>
## Implementation Decisions

### Card design — D-01
- **Decision:** Contact card shows name, avatar (initials fallback), and last conversation time (if exists)
- **Rationale:** Per ROADMAP.md success criteria item 4 — "contact name, avatar, and last conversation time (if any)"; keep minimal to start
- **[auto] Selected: Minimal card with name + avatar + last conversation time**

### Card avatar — D-02
- **Decision:** Use Chatwoot's existing avatar component pattern (`userAvatar` or similar)
- **Rationale:** Consistency with existing Chatwoot contact/agent avatar display
- **[auto] Selected: Existing avatar component with initials fallback**

### Column layout — D-03
- **Decision:** Fixed-width columns (~280px) in a horizontal scroll container
- **Rationale:** Standard Kanban pattern; columns don't shrink on smaller screens; horizontal scroll preserves readability
- **[auto] Selected: Fixed-width columns with horizontal scroll**

### Column header — D-04
- **Decision:** Stage name, color dot indicator, and contact count badge
- **Rationale:** Per ROADMAP.md item 3 — "stage name and contact count"; color dot follows existing stage color pattern from Phase 2
- **[auto] Selected: Name + color dot + count badge**

### Unassigned column — D-05
- **Decision:** Always visible left of first stage, muted/grayed styling, shows count badge
- **Rationale:** Per ROADMAP.md item 2 — "visually distinct (muted styling) and shows a count badge"; leftmost position per spec
- **[auto] Selected: Always visible, muted styling, leftmost position**

### Unassigned empty behavior — D-06
- **Decision:** Show "0" badge when no unassigned contacts exist
- **Rationale:** Consistent with count badge pattern; column still visible for context
- **[auto] Selected: Show count even when zero**

### Drag UX — D-07
- **Decision:** Ghost card (semi-transparent) while dragging, drop placeholder shown in target column
- **Rationale:** Standard drag-drop UX; gives visual feedback without fully committing until API confirms
- **[auto] Selected: Ghost card + drop placeholder**

### Drag input support — D-08
- **Decision:** Both mouse and touch drag inputs work
- **Rationale:** Per ROADMAP.md item 7 — "Both mouse and touch drag inputs work"; vuedraggable handles both
- **[auto] Selected: Mouse + touch via vuedraggable**

### Optimistic update — D-09
- **Decision:** Card moves immediately on drop; on API failure, card reverts to original column and toast error shows
- **Rationale:** Per ROADMAP.md item 6 — "optimistic: the card moves immediately; on API failure it reverts and shows a toast error"
- **[auto] Selected: Optimistic update with revert + toast on failure**

### API call on drop — D-10
- **Decision:** `PATCH /api/v1/accounts/:account_id/contacts/:id` with `pipeline_stage_id` in body
- **Rationale:** Standard Contact update endpoint; Phase 1 already added `pipeline_stage_id` to permitted params
- **[auto] Selected: Contact update API with pipeline_stage_id**

### Empty column state — D-11
- **Decision:** Muted placeholder text "No contacts in [stage name]"
- **Rationale:** Provides context without being blank; follows existing Chatwoot empty state patterns
- **[auto] Selected: Muted placeholder text**

### Column order — D-12
- **Decision:** Columns ordered by `position` ascending (same order as Phase 2/3 API returns)
- **Rationale:** Per ROADMAP.md item 1 — "ordered by position"; stores return stages in position order from Phase 2
- **[auto] Selected: Position ascending order**

### Loading state — D-13
- **Decision:** Skeleton loaders for columns and cards while data fetches
- **Rationale:** Phase 4 established `uiFlags` loading pattern; skeleton loaders match Chatwoot's loading UX
- **[auto] Selected: Skeleton loaders**

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 4 Context (Frontend Infrastructure)
- `.planning/phases/04-frontend-infrastructure/04-CONTEXT.md` — usePipelineStore, leadsIndex.vue stub, route registration

### Phase 2 Context (Stage CRUD API)
- `.planning/phases/02-stage-crud-api/02-CONTEXT.md` — Stage model with `position`, color, API endpoints

### Phase 3 Context (Stats API)
- `.planning/phases/03-stats-api/03-CONTEXT.md` — Stats response shape, cache key format

### Chatwoot Frontend Patterns
- `app/javascript/dashboard/stores/pipeline.js` — Phase 4 Pinia store with stages, stats, uiFlags
- `app/javascript/dashboard/store/modules/contacts/index.js` — Existing contacts Vuex store (to extend with fetchByStage)
- `app/javascript/dashboard/api/contacts.js` — Existing contact API client
- `app/javascript/dashboard/routes/dashboard/leads/pages/LeadsIndex.vue` — Phase 4 stub component to extend
- `app/javascript/dashboard/components/ui/Card.vue` — Existing Card component (reference for card design)
- `app/javascript/dashboard/routes/dashboard/dashboard.routes.js` — Where leads route is registered

### Drag-Drop Library
- `vuedraggable` — Available in package.json; handles both mouse and touch drag

### No external specs — requirements fully captured in decisions above

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `usePipelineStore`: Already has `stages`, `stats`, `fetchStages()`, `fetchStats()` from Phase 4
- `useContactsStore`: Phase 4 added `fetchByStage(stageId)` action
- `vuedraggable@next`: Available for Vue 3 drag-drop; handles both mouse and touch
- Existing contact API: `contacts.js` can PATCH contact with `pipeline_stage_id`

### Established Patterns
- Pinia + Vuex hybrid: Phase 4 established using Pinia for pipeline, Vuex for contacts
- Loading states: `uiFlags` pattern with `fetchingList`, etc.
- Toast errors: Chatwoot uses `alertMixin` for toast notifications

### Integration Points
- Route: `/accounts/:accountId/leads` → `LeadsIndex.vue` (stub ready for Kanban)
- Stores: `usePipelineStore.stages` (ordered by position), `useContactsStore.fetchByStage(stageId)`
- API: Contact update endpoint accepts `pipeline_stage_id`

</code_context>

<specifics>
## Specific Ideas

No specific user references beyond ROADMAP.md success criteria. Standard Kanban patterns apply.

</specifics>

<deferred>
## Deferred Ideas

### Card quick actions
- **Idea:** Hover actions on cards (view contact, send message)
- **Status:** Not in Phase 5 scope; belongs in Phase 7 (List View) or Phase 8 (Contact Sidebar)

### Stage color as column header background
- **Idea:** Use stage color as subtle column header background
- **Status:** Not explicitly required; consider for Phase 6 if visual design needs enhancement

### Keyboard shortcuts for card movement
- **Idea:** Arrow keys to move selected card between stages
- **Status:** Not in Phase 5 scope; could be a Phase 7 enhancement

### Multi-select and bulk move
- **Idea:** Select multiple cards and move as batch
- **Status:** Not in Phase 5 scope; deferred to future enhancement

---

*Phase: 05-kanban-board-drag-drop*
*Context gathered: 2026-04-11*
*[auto] All gray areas auto-resolved with recommended defaults per ROADMAP.md specifications and standard Kanban UX patterns*
