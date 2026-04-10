# Phase 2: Stage CRUD API - Research

**Researched:** 2026-04-10
**Domain:** Rails REST API controller, Pundit authorization, acts_as_list integration
**Confidence:** HIGH (code patterns verified in codebase)

## Summary

Phase 2 exposes CRUD operations on `PipelineStage` via REST under `/api/v1/accounts/:account_id/pipeline_stages`. The implementation mirrors the established `LabelsController` pattern exactly: Chatwoot uses implicit rendering with instance variables, Pundit for authorization, and `Current.account` for scoping. The only non-obvious complexity is the missing `acts_as_list` gem in the Gemfile and the move endpoint's member-route structure. All controller actions are thin wrappers over ActiveRecord; no serializers are needed.

**Primary recommendation:** Copy `labels_controller.rb` as the scaffold, swap the resource name, add a `move` member action, and add `gem 'acts_as_list'` to the Gemfile before anything else.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Follow existing Chatwoot API patterns (`Api::V1::Accounts::BaseController`, `Current.account`, `pundit_policy_scope`)
- **D-02:** Controller at `Api::V1::Accounts::PipelineStagesController`
- **D-03:** Admin-only via Pundit policy (same pattern as `labels_controller.rb`)
- **D-04:** `PATCH .../:id/move` with `{ direction: "up" | "down" }` — swaps with neighboring stage
- **D-05:** On destroy: nullify `pipeline_stage_id` on all affected contacts, then destroy stage
- **D-06:** Full stage objects returned; no custom serializer needed
- **D-07:** Use `acts_as_list` methods (`move_higher`, `move_lower`) for move endpoint
- **D-08:** Name required, color optional (hex format validated)

### Deferred Ideas (OUT OF SCOPE)
None.

---

## Standard Stack

All libraries are already in the project. No new gems required except `acts_as_list` (already used in model, not in Gemfile).

### Core (Existing Gems)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `acts_as_list` | **MISSING** | Position management for ordered stages | Phase 1 decision; `move_higher`/`move_lower` methods |
| `pundit` | in Gemfile | Authorization policy enforcement | Used by every account-scoped controller |
| `rspec-rails` | in Gemfile | Controller and request specs | Chatwoot testing standard |

**Installation:**
```bash
# Add to Gemfile (CRITICAL — not currently present)
echo "gem 'acts_as_list'" >> Gemfile
bundle install
```

---

## Architecture Patterns

### Recommended Project Structure

```
app/
├── controllers/api/v1/accounts/
│   └── pipeline_stages_controller.rb   # NEW
├── policies/
│   └── pipeline_stage_policy.rb        # NEW
spec/
├── controllers/api/v1/accounts/
│   └── pipeline_stages_controller_spec.rb  # NEW
└── factories/
    └── pipeline_stages.rb              # NEW
```

### Pattern 1: Account-Scoped CRUD Controller

**Source:** `app/controllers/api/v1/accounts/labels_controller.rb` (lines 1-34)

This is the canonical CRUD template for account-scoped resources. Every action is a thin wrapper.

```ruby
class Api::V1::Accounts::LabelsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_label, except: [:index, :create]
  before_action :check_authorization

  def index
    @labels = policy_scope(Current.account.labels)
  end

  def show; end

  def create
    @label = Current.account.labels.create!(permitted_params)
  end

  def update
    @label.update!(permitted_params)
  end

  def destroy
    @label.destroy!
    head :ok
  end

  private

  def fetch_label
    @label = Current.account.labels.find(params[:id])
  end

  def permitted_params
    params.require(:label).permit(:title, :description, :color, :show_on_sidebar)
  end
end
```

**Key observations:**
- `render` is never called explicitly — Rails uses implicit rendering via the view layer (Jbuilder templates at `app/views/api/v1/accounts/labels/`). If no view exists, Rails renders the model as JSON automatically. No serializer is needed.
- `check_authorization` without args uses `controller_name.classify.constantize` (resolves to `Label`). For PipelineStages, explicitly pass `PipelineStage`: `check_authorization(PipelineStage)`.
- `policy_scope(Current.account.labels)` filters via `LabelPolicy::Scope#resolve`.
- Destroy returns `head :ok` (no body).

**PipelineStagesController adaptions:**
- `fetch_pipeline_stage` instead of `fetch_label`
- `permitted_params` permits `name` and `color`
- Add `move` member action between `update` and `destroy`
- Add contact nullification before destroy

### Pattern 2: Admin-Only Pundit Policy

**Source:** `app/policies/label_policy.rb` (lines 1-21)

```ruby
class LabelPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end
end
```

**Key observations:**
- All write actions (create/update/destroy) require `@account_user.administrator?`
- `index?` allows both admins and agents (per CONTEXT.md D-03: all actions restricted to admins)
- Per D-03, the phase requires admin-only for all 6 actions including index
- Must also add `move?` returning `@account_user.administrator?`
- Note: `ApplicationPolicy#initialize` sets `@account_user` from `user_context[:account_user]` (verified in `app/policies/application_policy.rb` lines 2-9)

### Pattern 3: Member Route for Move

**Source:** `config/routes.rb` line 260 (`resources :teams`)

```ruby
resources :teams do
  resources :team_members, only: [:index, :create] do
    collection do
      delete :destroy
      patch :update
    end
  end
end
```

**For pipeline_stages move endpoint:**

```ruby
resources :pipeline_stages, only: [:index, :show, :create, :update, :destroy] do
  member do
    patch :move
  end
end
```

The member block creates `PATCH /api/v1/accounts/:account_id/pipeline_stages/:id/move`.

### Pattern 4: acts_as_list Move Higher/Lower

**Source:** `app/models/pipeline_stage.rb` (line 21: `acts_as_list scope: :account`)

`acts_as_list` adds these methods automatically:
- `move_higher` — swaps position with the item directly above
- `move_lower` — swaps position with the item directly below

Both respect the `scope: :account`, so positions only swap within the same account's stages.

**In the controller:**
```ruby
def move
  case params[:direction]
  when 'up'   then @pipeline_stage.move_higher
  when 'down' then @pipeline_stage.move_lower
  else
    render json: { error: 'direction must be up or down' }, status: :unprocessable_entity
    return
  end
  head :ok
end
```

### Pattern 5: Destroy with Dependency Nullification

**Source:** `app/models/contact.rb` (line 59: `belongs_to :pipeline_stage, optional: true`)

Before destroying a stage, nullify the FK on all associated contacts:

```ruby
def destroy
  Contact.where(pipeline_stage_id: @pipeline_stage.id).update_all(pipeline_stage_id: nil)
  @pipeline_stage.destroy!
  head :ok
end
```

`update_all` is used instead of `update` on each contact to avoid callbacks and N+1 (verified as Chatwoot pattern via `audited` gem behavior).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Position ordering | Custom position integers with manual swaps | `acts_as_list` gem | Handles edge cases (boundary positions, concurrent edits) correctly |
| Authorization | Custom before_action checks | Pundit policy | Consistent with codebase, supports policy scopes |
| Account scoping | Manual `where(account_id: ...)` | `Current.account` | Consistent pattern, centralizes account context |

---

## Common Pitfalls

### Pitfall 1: Missing `acts_as_list` gem in Gemfile
**What goes wrong:** `bundle install` fails or `PipelineStage` model raises `NoMethodError` for `move_higher`.
**Why it happens:** Phase 1 code uses `acts_as_list` in the model but the gem was never added to `Gemfile`.
**How to avoid:** Add `gem 'acts_as_list'` to Gemfile before Phase 2 implementation. Run `bundle install`.
**Warning signs:** `NameError: undefined method 'move_higher'` on first test run.

### Pitfall 2: `check_authorization` without explicit model argument
**What goes wrong:** `check_authorization` (no args) resolves to `controller_name.classify` = `PipelineStage`, which Pundit maps to `PipelineStagePolicy`. This should work correctly IF the policy file is named exactly `pipeline_stage_policy.rb`.
**Why it happens:** `Api::BaseController#check_authorization` (line 14-18) calls `authorize(model)` where model defaults to `controller_name.classify.constantize`.
**How to avoid:** Either name the policy file `pipeline_stage_policy.rb` (Pundit convention) OR pass the model explicitly: `check_authorization(PipelineStage)`. Explicit is safer and clearer.

### Pitfall 3: Boundary positions in move endpoint
**What goes wrong:** Calling `move_higher` on the topmost stage or `move_lower` on the bottommost stage is a no-op — `acts_as_list` does not raise or signal this.
**Why it happens:** `acts_as_list` silently ignores moves beyond boundaries.
**How to avoid:** Check position boundaries before moving, or return success anyway (current spec doesn't require boundary feedback). If boundary feedback needed: check `first?`/`last?` before calling `move_higher`/`move_lower`.

### Pitfall 4: Destroying a stage that contacts are assigned to
**What goes wrong:** PostgreSQL FK constraint violation if `pipeline_stage_id` on `contacts` table is NOT NULL.
**Why it happens:** Contact model has `belongs_to :pipeline_stage, optional: true` (verified in `app/models/contact.rb` line 59), so FK is nullable. Safe to nullify.
**How to avoid:** Always nullify contacts before destroying. Use `update_all` for efficiency.

---

## Code Examples

### New file: `app/controllers/api/v1/accounts/pipeline_stages_controller.rb`

```ruby
class Api::V1::Accounts::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_pipeline_stage, except: [:index, :create]
  before_action :check_authorization

  def index
    @pipeline_stages = Current.account.pipeline_stages.sorted
  end

  def show; end

  def create
    @pipeline_stage = Current.account.pipeline_stages.new(permitted_params)
    @pipeline_stage.save!
  end

  def update
    @pipeline_stage.update!(permitted_params)
  end

  def destroy
    Contact.where(pipeline_stage_id: @pipeline_stage.id).update_all(pipeline_stage_id: nil)
    @pipeline_stage.destroy!
    head :ok
  end

  def move
    case params[:direction]
    when 'up'
      @pipeline_stage.move_higher
    when 'down'
      @pipeline_stage.move_lower
    else
      render json: { error: 'direction must be "up" or "down"' }, status: :unprocessable_entity
      return
    end
    head :ok
  end

  private

  def fetch_pipeline_stage
    @pipeline_stage = Current.account.pipeline_stages.find(params[:id])
  end

  def permitted_params
    params.require(:pipeline_stage).permit(:name, :color)
  end
end
```

### New file: `app/policies/pipeline_stage_policy.rb`

```ruby
class PipelineStagePolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def move?
    @account_user.administrator?
  end
end
```

### Route addition (insert after line 245 of `config/routes.rb`)

```ruby
resources :pipeline_stages, only: [:index, :show, :create, :update, :destroy] do
  member do
    patch :move
  end
end
```

### New factory: `spec/factories/pipeline_stages.rb`

```ruby
FactoryBot.define do
  factory :pipeline_stage do
    account
    sequence(:name) { |n| "Stage #{n}" }
    color { '#22C55E' }
  end
end
```

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CRM-02 | PipelineStagesController CRUD API | Controller pattern from `labels_controller.rb`; policy from `label_policy.rb`; routes from `teams` nested resources |

---

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `acts_as_list` gem is missing from Gemfile but Phase 1 code already uses it in the model | Standard Stack | **CRITICAL:** Model will fail at runtime without this gem. Verified Gemfile and Gemfile.lock — neither contains `acts_as_list`. Phase 1 commit exists but gem was not added. |
| A2 | No Jbuilder view templates are needed for PipelineStages | Architecture Pattern 1 | Chatwoot implicitly renders ActiveRecord models as JSON when no view exists. Verified `labels_controller.rb` has no explicit render calls. |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

---

## Open Questions

1. **Boundary handling on move endpoint**
   - What we know: `acts_as_list` `move_higher`/`move_lower` silently no-op at boundaries
   - What's unclear: Should the API return an error for out-of-bounds moves, or just return success?
   - Recommendation: Return success (no error) per KISS — boundary moves are harmless and the frontend can disable the move button at boundaries

2. **Does `Contact.where(...).update_all` skip ActiveRecord callbacks?**
   - What we know: Chatwoot uses `update_all` elsewhere; Contact has no `pipeline_stage_id` callbacks
   - What's unclear: None — safe to use `update_all` here
   - Recommendation: Use `update_all` for efficiency

---

## Environment Availability

Step 2.6: SKIPPED — Phase 2 is a code-only addition (controller, policy, routes, factory, specs). No external dependencies beyond what already exists in the project.

**Missing dependencies:**
- `acts_as_list` gem — not in Gemfile, **blocking**. Must be added before implementation begins.

---

## Validation Architecture

> Included because `nyquist_validation: true` in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | RSpec (rspec-rails 6.x) |
| Spec type | Request specs (`type: :request`) |
| Config file | `spec/rails_helper.rb`, `spec/support/` |
| Quick run command | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -x` |
| Full suite command | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CRM-02-1 | GET index returns all stages ordered by position | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -e 'GET index'` | NO |
| CRM-02-2 | POST create with name+color creates and appends stage | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -e 'POST create'` | NO |
| CRM-02-3 | PATCH update changes name and color | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -e 'PATCH update'` | NO |
| CRM-02-4 | DELETE destroys stage and nullifies contact FKs | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -e 'DELETE destroy'` | NO |
| CRM-02-5 | PATCH move with direction swaps position | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -e 'PATCH move'` | NO |
| CRM-02-6 | All endpoints restricted to administrators | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -e 'authenticated.*agent'` | NO |
| — | Unauthenticated requests return 401 | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -e 'unauthenticated'` | NO |

### Sampling Rate
- **Per task commit:** Full spec file (`pipeline_stages_controller_spec.rb`)
- **Per wave merge:** Full suite via `bundle exec rspec spec/`
- **Phase gate:** All specs green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `Gemfile` — add `gem 'acts_as_list'` (CRITICAL - blocking)
- [ ] `spec/factories/pipeline_stages.rb` — factory for test data
- [ ] `spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb` — all CRM-02 behaviors
- [ ] `spec/rails_helper.rb` — verify `include FactoryBot::Syntax::Methods` is present (should already be)
- [ ] Framework install: `bundle install` after Gemfile edit

*(No gaps beyond the critical gem addition)*

---

## Sources

### Primary (HIGH confidence — verified in codebase)

- `app/controllers/api/v1/accounts/labels_controller.rb` — CRUD template, before_action chain, permitted_params pattern
- `app/controllers/api/v1/accounts/base_controller.rb` — Current.account, switch_locale_using_account_locale
- `app/controllers/api/v1/accounts/teams_controller.rb` — fetch_resource pattern, destroy returns `head :ok`
- `app/policies/label_policy.rb` — admin-only policy pattern with `@account_user.administrator?`
- `app/policies/application_policy.rb` — initialize sets @account_user from user_context
- `app/controllers/api/base_controller.rb` — `check_authorization` uses `authorize(model)`, defaults to controller_name.classify
- `app/models/pipeline_stage.rb` — `acts_as_list scope: :account`, `sorted` scope, color validation
- `app/models/contact.rb` line 59 — `belongs_to :pipeline_stage, optional: true` (FK is nullable)
- `config/routes.rb` lines 245, 260 — nested `resources` declaration patterns
- `spec/controllers/api/v1/accounts/labels_controller_spec.rb` — request spec pattern with `create_new_auth_token`
- `Gemfile` — verified `acts_as_list` is ABSENT

### Secondary (MEDIUM confidence — inferred from patterns)

- `app/controllers/api/v1/accounts/categories_controller.rb` — `reorder` action pattern (not used directly, but confirms member vs collection route structure)

### Tertiary (LOW confidence — none)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified in codebase; `acts_as_list` gap confirmed in Gemfile/Gemfile.lock
- Architecture: HIGH — all patterns verified with exact file/line references
- Pitfalls: HIGH — gap between Phase 1 decision (use acts_as_list) and Gemfile confirmed; all other pitfalls from code analysis

**Research date:** 2026-04-10
**Valid until:** 2026-05-10 (30 days — stable Rails patterns)

---

## RESEARCH COMPLETE

**Phase:** 02 - Stage CRUD API
**Confidence:** HIGH

### Key Findings

1. **`acts_as_list` is missing from Gemfile** — Phase 1 code uses it in `PipelineStage` model but gem was never added. This is the single blocking issue for Phase 2.
2. **Controller scaffold** — Copy `labels_controller.rb` exactly, swap `label` for `pipeline_stage`, add `move` member action.
3. **Authorization** — `PipelineStagePolicy` mirrors `LabelPolicy` with all 5 standard actions + `move?`, all requiring `@account_user.administrator?`.
4. **Routes** — Add `resources :pipeline_stages` with `member { patch :move }` nested under accounts in `config/routes.rb` after line 245.
5. **Move endpoint** — `move_higher`/`move_lower` from `acts_as_list` handle the swap; boundary no-ops are safe (no error needed).
6. **Destroy** — Nullify contacts with `update_all` before destroy; FK is nullable per `optional: true`.
7. **No serializers** — Chatwoot uses implicit rendering; no `PipelineStageSerializer` needed.
8. **Factory needed** — `spec/factories/pipeline_stages.rb` does not exist.

### File Created

`C:\Users\max\Documents\GitHub\chatwoot\.planning\phases\02-stage-crud-api\02-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | All library patterns verified in codebase; `acts_as_list` gap confirmed |
| Architecture | HIGH | Exact file/line references for all 5 patterns |
| Pitfalls | HIGH | `acts_as_list` gap is the only novel finding; others are standard |

### Open Questions

1. Boundary handling on move endpoint (recommendation: silent success, no error)
2. No other open questions — all decisions documented in CONTEXT.md

### Ready for Planning

Research complete. Planner can now create `02-01-PLAN.md` files.
