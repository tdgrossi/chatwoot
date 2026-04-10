# Testing Patterns

**Analysis Date:** 2026-04-10

## Test Frameworks

### Backend (Ruby/Rails)

- RSpec Rails 6.1.5+
- FactoryBot for test fixtures
- DatabaseCleaner for isolation
- WebMock for HTTP mocking
- test-prof for performance profiling
- SimpleCov for coverage
- Run: `bundle exec rspec`

### Frontend (JavaScript/Vue)

- Vitest 3.0.5 with jsdom environment
- @vue/test-utils for component testing
- fake-indexeddb for IndexedDB mocking
- Run: `pnpm run test`
- Run with coverage: `pnpm run test:coverage`

## Test File Organization

### Backend: `spec/` subdirectories

- `controllers/` - Controller specs
- `models/` - Model specs
- `jobs/` - Job specs
- `services/` - Service specs
- `factories/` - FactoryBot factories

### Frontend: Co-located with source

- Test files in `app/javascript/dashboard/**/` with `.spec.js` extension

## Key Config Files

- `vite.config.ts` - Test section with coverage settings
- `spec/rails_helper.rb` - RSpec configuration (FactoryBot, Shoulda Matchers, Skooma)
- `.github/workflows/run_foss_spec.yml` - 16-node parallel CI testing with round-robin spec distribution

## Code Quality Tools

- **ESLint** - `.eslintrc.js` with Vue 3, Prettier, Vitest globals
- **RuboCop** - `.rubocop.yml` with RSpec, Performance, Rails plugins
- **Prettier** - `.prettierrc` (80 character width, single quotes, es5 trailing commas)
- **Pre-push Hook** - `.husky/pre-push` runs lint-staged and RuboCop on staged files
