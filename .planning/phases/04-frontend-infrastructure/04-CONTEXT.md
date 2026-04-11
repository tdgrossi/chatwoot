# Phase 4: Frontend Infrastructure - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Pinia stores and routing infrastructure ready for the CRM dashboard UI. No user-facing functionality — this phase creates the data layer and route registration that Phase 5 (Kanban) and Phase 8 (Stats Panel) will consume.

</domain>

<decisions>
## Implementation Decisions

### Store pattern — D-01
- **Decision:** Follow existing `companies.js` Pinia store pattern — `createStore` factory with `type: 'pinia'`
- **Rationale:** Chatwoot is mid-migration from Vuex to Pinia; `companies.js` is the established Pinia pattern; `storeFactory.js` provides both Vuex and Pinia via the same factory

### Store location — D-02
- **Decision:** `usePipelineStore` goes in `app/javascript/dashboard/stores/pipeline.js`
- **Rationale:** Parallel to `companies.js` which also lives in `dashboard/stores/` not in `store/modules/`

### API client pattern — D-03
- **Decision:** `PipelineStagesAPI` and `PipelineStatsAPI` extend `ApiClient` base class, registered as singletons
- **Rationale:** Phase 2 established the API endpoint structure; existing `ApiClient` handles `accountScoped: true` URL construction automatically

### Contacts store extension — D-04
- **Decision:** Add `fetchByStage(stageId)` as a Vuex action in existing `store/modules/contacts/` — do NOT create a separate Pinia store for contacts
- **Rationale:** Contacts are already Vuex; adding a stage filter action keeps contacts data in one place; Phase 4 success criteria explicitly says "useContactsStore gains a fetchByStage action"

### Route component — D-05
- **Decision:** Create a minimal `leadsIndex.vue` stub component that imports and uses the pipeline stores; actual Kanban UI is Phase 5
- **Rationale:** Route must point somewhere; a stub with store integration prepares Phase 5's slot

### Route registration — D-06
- **Decision:** New `leads/leads.routes.js` file registered in `dashboard.routes.js` children array, alongside `contactRoutes` and `companyRoutes`
- **Rationale:** Follows existing pattern for account-scoped routes; `frontendURL('accounts/:accountId/leads')` path

### Store state shape — D-07
- **Decision:** `usePipelineStore` state: `{ stages: [], stats: [], uiFlags: {...} }` with CRUD actions + `fetchStats`
- **Rationale:** Matches Phase 2 CRUD API + Phase 3 stats endpoint; stores aggregate both for Phase 5 consumption

### Loading/error states — D-08
- **Decision:** Use `setUIFlag()` pattern from `storeFactory.js` — `fetchingList`, `creatingItem`, `updatingItem`, `deletingItem` flags
- **Rationale:** Established pattern in `companies.js` and all Vuex modules; consistent with Chatwoot UI state handling

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 2 & 3 Context (API foundation)
- `.planning/phases/02-stage-crud-api/02-CONTEXT.md` — PipelineStagesController CRUD + move endpoint
- `.planning/phases/03-stats-api/03-CONTEXT.md` — `pipeline_stats` endpoint, cache key format, response shape

### Chatwoot Frontend Patterns
- `app/javascript/dashboard/stores/companies.js` — Pinia store pattern with `createStore` factory, `type: 'pinia'`
- `app/javascript/dashboard/api/ApiClient.js` — Base API client with `accountScoped` URL construction
- `app/javascript/dashboard/api/companies.js` — API client extending ApiClient with custom methods
- `app/javascript/dashboard/store/storeFactory.js` — Universal store factory supporting both Vuex and Pinia
- `app/javascript/dashboard/store/modules/contacts/index.js` — Existing Vuex contacts store (to be extended)
- `app/javascript/dashboard/store/modules/contacts/actions.js` — Existing Vuex contacts actions (to add `fetchByStage`)
- `app/javascript/dashboard/routes/dashboard/contacts/routes.js` — Route registration pattern with `frontendURL` helper
- `app/javascript/dashboard/routes/dashboard/dashboard.routes.js` — Where to register new leads route

### No external specs — requirements fully captured in decisions above

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `createStore({ type: 'pinia' })`: Creates Pinia store with standard CRUD actions, state shape, and `setUIFlag`/`setMeta` helpers
- `ApiClient` base class: Handles `accountScoped: true` URL prefixing automatically
- `throwErrorMessage(error)`: Utility for API error handling in stores
- `frontendURL()` helper: Constructs proper Chatwoot URLs with account context

### Established Patterns
- Pinia stores: `useXXXStore` naming, `API` injection, `camelcaseKeys` for API response normalization
- API clients: Singleton export, extend `ApiClient`, custom methods for non-CRUD endpoints
- Vuex module extension: Add actions to existing modules without breaking existing functionality
- Route files: `routes.js` exporting array, registered in `dashboard.routes.js`

### Integration Points
- Route: `/accounts/:accountId/leads` registered in `dashboard.routes.js` children
- API: `pipeline_stages` and `pipeline_stats` endpoints from Phases 2 and 3
- Components: Phase 5 Kanban will import `usePipelineStore` and `useContactsStore.fetchByStage`

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches following Chatwoot frontend patterns

</specifics>

<deferred>
## Deferred Ideas

None — Phase 4 is an infrastructure phase; all work stays within the infrastructure scope

---

*Phase: 04-frontend-infrastructure*
*Context gathered: 2026-04-11*
*[auto] All gray areas auto-resolved with recommended defaults per established Chatwoot frontend patterns*
