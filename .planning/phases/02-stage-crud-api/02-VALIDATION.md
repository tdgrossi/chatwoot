---
phase: 02
slug: stage-crud-api
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-10
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | RSpec (rspec-rails 6.x) |
| **Config file** | `spec/rails_helper.rb`, `spec/support/` |
| **Quick run command** | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -x` |
| **Full suite command** | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb` |
| **Estimated runtime** | ~10-30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb -x`
- **After every plan wave:** Run `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 0 | Gemfile acts_as_list | — | N/A | install | `bundle install && bundle exec rspec spec/models/pipeline_stage_spec.rb -e 'acts_as_list'` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 0 | FactoryBot factory | — | N/A | factory | `bundle exec rspec spec/factories/pipeline_stages_spec.rb` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 0 | PipelineStage model spec | — | N/A | model | `bundle exec rspec spec/models/pipeline_stage_spec.rb` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 1 | Controller CRUD + move | CRM-02 | Admin-only via Pundit | request | `bundle exec rspec spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Gemfile` — add `gem 'acts_as_list'` (CRITICAL - blocking for model)
- [ ] `spec/factories/pipeline_stages.rb` — FactoryBot factory for test data
- [ ] `spec/models/pipeline_stage_spec.rb` — model specs for `acts_as_list` methods and validations
- [ ] `spec/controllers/api/v1/accounts/pipeline_stages_controller_spec.rb` — stubs for all CRM-02 behaviors
- [ ] `bundle install` — after Gemfile edit

*Existing infrastructure: RSpec, FactoryBot, Pundit already in project.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Route registration | CRM-02 | Requires full Rails env | `bundle exec rails routes | grep pipeline_stages` |
| Pundit policy file naming | CRM-02 | Pundit auto-discovery | Inspect `PipelineStagePolicy` authorization in controller spec |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** {pending / approved YYYY-MM-DD}
