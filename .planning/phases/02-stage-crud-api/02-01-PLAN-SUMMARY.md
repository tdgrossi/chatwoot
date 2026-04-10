---
phase: '02'
plan: '01'
subsystem: pipeline-stages
tags: [crm, api, rails, pundit, acts-as-list]
dependency_graph:
  requires:
    - phase-01-pipeline-stage-model
  provides:
    - Api::V1::Accounts::PipelineStagesController
    - PipelineStagePolicy
    - pipeline_stages CRUD API
    - pipeline_stage_id FK on contacts
  affects:
    - config/routes.rb
tech_stack:
  added: []
  patterns:
    - Api::V1::Accounts::BaseController (CRUD scaffold)
    - Pundit authorization via check_authorization
    - acts_as_list move_higher/move_lower
    - Contact.update_all nullification before destroy
key_files:
  created:
    - db/migrate/20260410000001_create_pipeline_stages.rb
    - db/migrate/20260410000002_add_pipeline_stage_to_contacts.rb
    - app/controllers/api/v1/accounts/pipeline_stages_controller.rb
    - app/policies/pipeline_stage_policy.rb
    - spec/factories/pipeline_stages.rb
    - spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb
  modified:
    - config/routes.rb
decisions:
  - "Admin-only authorization on all 6 actions (index, show, create, update, destroy, move) via @account_user.administrator?"
  - "move endpoint uses acts_as_list move_higher/move_lower with direction param"
  - "destroy nullifies contact FKs via Contact.where(...).update_all before stage destruction"
  - "permitted_params permits :name and :color only"
  - "implicit Rails JSON rendering (no Jbuilder templates needed)"
metrics:
  duration: "<5 min"
  tasks_completed: '6/6'
  files_created: 6
  files_modified: 1
---

# Phase 02 Plan 01 Summary: Pipeline Stages CRUD API

## One-liner

RESTful CRUD API for managing pipeline stages with admin-only authorization, acts_as_list reordering, and contact FK nullification on delete.

## What Was Built

Implemented the complete backend API contract for CRM pipeline stage management:

- **PipelineStagesController** — 6 actions: index (sorted), show, create, update, destroy, move
- **PipelineStagePolicy** — admin-only authorization on all 6 policy methods
- **Route registration** — `resources :pipeline_stages` with `patch :move` member action
- **Migrations** — `pipeline_stages` table + `pipeline_stage_id` FK on contacts
- **Factory** — `pipeline_stage` factory with account association, sequence name, default color #22C55E
- **Request specs** — full coverage: CRUD auth (unauthenticated 401, agent 403, admin 200), destroy contact nullification, move up/down/invalid

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Admin-only on all actions | Pipeline stage management is admin-only; agents cannot manage stages | `PipelineStagePolicy` with `@account_user.administrator?` on all 6 methods |
| `update_all` for contact nullification | Efficient bulk update avoiding N+1 and callbacks | `Contact.where(pipeline_stage_id: @pipeline_stage.id).update_all(pipeline_stage_id: nil)` |
| acts_as_list move_higher/move_lower | Handles boundary no-ops silently, scope-safe via `scope: :account` | `move` action case/when on direction param |
| Implicit JSON rendering | Chatwoot pattern — no Jbuilder templates needed | Rails renders `@pipeline_stage`/`@pipeline_stages` as JSON |

## Deviations from Plan

None — plan executed exactly as written.

## Acceptance Criteria Status

- [x] `db/migrate/20260410000001_create_pipeline_stages.rb` contains `create_table :pipeline_stages`, account FK, name, position, color, timestamps, and composite index
- [x] `db/migrate/20260410000002_add_pipeline_stage_to_contacts.rb` contains `add_reference :contacts, :pipeline_stage, foreign_key: true`
- [x] `spec/factories/pipeline_stages.rb` contains factory, account association, sequence(:name), default color
- [x] `spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb` covers all 7 endpoint/auth scenarios
- [x] `app/controllers/api/v1/accounts/pipeline_stages_controller.rb` contains all 6 actions + move
- [x] `app/policies/pipeline_stage_policy.rb` contains all 6 policy methods + move?
- [x] `config/routes.rb` contains `resources :pipeline_stages` with `member { patch :move }`
- [x] All Ruby syntax checks pass

## Commits

| Hash | Message |
|------|---------|
| `e072d07c3` | feat(phase-2): create pipeline_stages table and contacts FK migration |
| `23d6cb5a9` | test(phase-2): add PipelineStage factory |
| `c628be878` | test(phase-2): add request specs for PipelineStagesController |
| `f671a0464` | feat(phase-2): implement PipelineStagesController CRUD + move action |
| `bbd85eff2` | feat(phase-2): add PipelineStagePolicy admin-only authorization |
| `64bc06bf4` | feat(phase-2): add pipeline_stages route with move member action |

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| No new threats | all | All new endpoints are already covered by the plan's threat_model mitigations. Account scoping via `Current.account.pipeline_stages.find` prevents cross-account access. Admin-only via `PipelineStagePolicy` prevents privilege escalation. Invalid `direction` param returns 422. |

## Notes

- `bundle install` could not run in this environment (bundler resolution error, not related to `acts_as_list` which is already in Gemfile line 72). All syntax checks pass.
- Spec suite verification (`bundle exec rspec`) was attempted but blocked by the same bundler issue. Code is syntactically correct per `ruby -c` checks.
- The human-verify checkpoint (Task 7) was documented for audit but skipped in auto-mode per execution instructions.
